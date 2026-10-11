import AppKit
import Combine
import SwiftUI

struct LibraryFile: Identifiable, Hashable {
    let url: URL
    let folder: String
    var id: URL { url }
    var name: String { url.lastPathComponent }
    var isAvfx: Bool { url.pathExtension.lowercased() == "avfx" }
}

final class AppModel: ObservableObject {
    @Published var document: EffectDocument?
    @Published var libraryRoot: URL?
    @Published var files: [LibraryFile] = []
    @Published var errorMessage: String?
    @Published var bottomTab = 0
    @Published var viewportMode = 0
    @Published var bottomExpanded = false
    @Published var effectShading = 0
    @Published var showEmitters = false
    @Published var showBindPoints = true

    private var documents: [URL: EffectDocument] = [:]
    private var textureFiles: [String: URL] = [:]
    private var texturePaths: [String: URL] = [:]
    private var modelFiles: [String: URL] = [:]
    private var imageCache: [URL: CGImage] = [:]
    private var textureInfo: [URL: String] = [:]
    private var meshCache: [URL: MeshData] = [:]
    private var decodedCache: [URL: DecodedTexture] = [:]
    private var textureAddress: [String: (u: String, v: String)] = [:]
    private(set) var libraryToken = 0
    private var documentSink: AnyCancellable?
    private static let bookmarkKey = "libraryBookmark"

    init() {
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--library"), flag + 1 < arguments.count {
            setLibrary(URL(fileURLWithPath: arguments[flag + 1]))
        } else {
            restoreLibrary()
        }
        if let flag = arguments.firstIndex(of: "--open"), flag + 1 < arguments.count {
            open(URL(fileURLWithPath: arguments[flag + 1]))
        }
        AppDelegate.model = self
    }

    func chooseLibrary() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Folder"
        panel.message = "Folder with effects and textures"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let bookmark = try? url.bookmarkData(options: .withSecurityScope) {
            UserDefaults.standard.set(bookmark, forKey: AppModel.bookmarkKey)
        }
        setLibrary(url)
    }

    private func restoreLibrary() {
        guard let bookmark = UserDefaults.standard.data(forKey: AppModel.bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) else { return }
        _ = url.startAccessingSecurityScopedResource()
        setLibrary(url)
    }

    private func setLibrary(_ root: URL) {
        libraryRoot = root
        textureFiles = [:]
        texturePaths = [:]
        modelFiles = [:]
        textureAddress = [:]
        var found: [LibraryFile] = []
        let skipped: Set<String> = ["node_modules", ".git", ".idea", "reference", "Dalamud-VFXEditor-main"]
        let rootPath = root.standardizedFileURL.path
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return }
        for case let url as URL in walker {
            if skipped.contains(url.lastPathComponent) {
                walker.skipDescendants()
                continue
            }
            let ext = url.pathExtension.lowercased()
            let relative = String(url.standardizedFileURL.path.dropFirst(rootPath.count + 1))
            let folder = (relative as NSString).deletingLastPathComponent
            let base = url.deletingPathExtension().lastPathComponent.lowercased()
            switch ext {
            case "avfx":
                found.append(LibraryFile(url: url, folder: folder))
            case "atex", "tex":
                textureFiles[url.lastPathComponent.lowercased()] = url
                texturePaths[relative.lowercased()] = url
            case "png":
                if textureFiles[base] == nil { textureFiles[base] = url }
            case "json":
                if url.lastPathComponent == "game-textures.json" {
                    readTextureManifest(url)
                } else if url.deletingLastPathComponent().lastPathComponent == "models" {
                    modelFiles[base] = url
                } else if let data = try? Data(contentsOf: url), data.count < 2_000_000,
                          let text = String(data: data, encoding: .utf8), text.contains("\"emitters\""), text.contains("\"particles\"") {
                    found.append(LibraryFile(url: url, folder: folder))
                }
            default: break
            }
        }
        files = found.sorted { ($0.folder, $0.name) < ($1.folder, $1.name) }
        imageCache = [:]
        meshCache = [:]
        decodedCache = [:]
        libraryToken += 1
        objectWillChange.send()
    }

    private func readTextureManifest(_ url: URL) {
        guard let data = try? Data(contentsOf: url), let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else { return }
        for (name, entry) in manifest {
            if let mode = entry["address"] as? String {
                textureAddress[name.lowercased()] = (mode, mode)
            } else if let modes = entry["address"] as? [String: String] {
                textureAddress[name.lowercased()] = (modes["u"] ?? "repeat", modes["v"] ?? "repeat")
            }
        }
    }

    func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Open"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url)
    }

    func open(_ url: URL) {
        do {
            let opened = try documents[url] ?? EffectDocument(url: url)
            documents[url] = opened
            document = opened
            documentSink = opened.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    var dirtyDocuments: [EffectDocument] { documents.values.filter(\.isDirty).sorted { $0.title < $1.title } }

    func confirmDiscardingChanges() -> Bool {
        let dirty = dirtyDocuments
        guard !dirty.isEmpty else { return true }
        let alert = NSAlert()
        alert.messageText = dirty.count == 1 ? "Save changes to \(dirty[0].title)?" : "Save changes to \(dirty.count) effects?"
        alert.informativeText = dirty.count == 1 ? "Your changes will be lost if you don't save them."
            : dirty.map(\.title).joined(separator: "\n") + "\n\nYour changes will be lost if you don't save them."
        alert.addButton(withTitle: dirty.count == 1 ? "Save" : "Save All")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            for document in dirty {
                do {
                    try document.save()
                } catch {
                    errorMessage = "\(document.title): \(error.localizedDescription)"
                    return false
                }
            }
            return true
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }

    func newEffect(template: String) {
        guard let source = Bundle.main.url(forResource: "template_" + template, withExtension: "avfx") else {
            errorMessage = "The \(template) template is missing from the app bundle"
            return
        }
        let panel = NSSavePanel()
        panel.title = "New Effect"
        panel.nameFieldStringValue = "new_effect.avfx"
        panel.directoryURL = libraryRoot ?? document?.url.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try Data(contentsOf: source).write(to: url, options: .atomic)
            documents[url] = nil
            open(url)
            if let root = libraryRoot, url.path.hasPrefix(root.path) { setLibrary(root) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isDirty(_ url: URL) -> Bool { documents[url]?.isDirty ?? false }

    func save() {
        guard let document else { return }
        do {
            try document.save()
        } catch {
            saveAs()
        }
    }

    func saveAs() {
        guard let document else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = document.url.lastPathComponent
        panel.directoryURL = document.url.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let old = document.url
            try document.save(to: url)
            documents[old] = nil
            documents[url] = document
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func textureURL(_ path: String) -> URL? {
        let lower = path.lowercased()
        let parts = lower.split(separator: "/").map(String.init)
        for start in 0..<max(parts.count, 1) {
            let suffix = parts[start...].joined(separator: "/")
            if let hit = texturePaths.first(where: { $0.key == suffix || $0.key.hasSuffix("/" + suffix) })?.value { return hit }
        }
        return textureFiles[(lower as NSString).lastPathComponent]
    }

    func image(for path: String) -> CGImage? {
        guard let url = textureURL(path) else { return nil }
        if let cached = imageCache[url] { return cached }
        var image: CGImage?
        if url.pathExtension.lowercased() == "png" {
            if let source = CGImageSourceCreateWithURL(url as CFURL, nil) {
                image = CGImageSourceCreateImageAtIndex(source, 0, nil)
                if let image { textureInfo[url] = "PNG · \(image.width)×\(image.height)" }
            }
        } else if let data = try? Data(contentsOf: url) {
            do {
                let decoded = try Atex.decode([UInt8](data))
                image = decoded.makeImage()
                textureInfo[url] = "\(decoded.formatName) · \(decoded.width)×\(decoded.height) · mip \(decoded.mipLevels)"
            } catch {
                textureInfo[url] = error.localizedDescription
            }
        }
        if let image { imageCache[url] = image }
        return image
    }

    func decodedTexture(for path: String) -> DecodedTexture? {
        guard let url = textureURL(path) else { return nil }
        if let cached = decodedCache[url] { return cached }
        guard url.pathExtension.lowercased() != "png", let data = try? Data(contentsOf: url), let decoded = try? Atex.decode([UInt8](data)) else {
            return nil
        }
        decodedCache[url] = decoded
        return decoded
    }

    func addressModes(for name: String) -> (u: String, v: String) {
        textureAddress[name.lowercased()] ?? ("repeat", "repeat")
    }

    func pixiModelURL(_ name: String) -> URL? { modelFiles[name.lowercased()] }

    func textureDescription(_ path: String) -> String {
        guard let url = textureURL(path) else {
            return libraryRoot == nil ? "Open the folder that holds the textures (⇧⌘O)" : "Not found in the open folder"
        }
        _ = image(for: path)
        return textureInfo[url] ?? ""
    }

    func meshes(for document: EffectDocument) -> [(id: String, mesh: MeshData)] {
        if let root = document.avfxRoot {
            return root.childrenNamed("Modl").enumerated().map { ("avfx/Modl/\($0.offset)", MeshData.fromAvfx($0.element)) }
        }
        return document.modelNames.compactMap { name in
            guard let url = modelFiles[name.lowercased()] else { return nil }
            if let cached = meshCache[url] { return (name, cached) }
            guard let data = try? Data(contentsOf: url), let json = try? JSONParser.parse(data) else { return nil }
            let mesh = MeshData.fromPixiModel(json)
            meshCache[url] = mesh
            return (name, mesh)
        }
    }
}
