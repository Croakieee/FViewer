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

    private var documents: [URL: EffectDocument] = [:]
    private var textureFiles: [String: URL] = [:]
    private var texturePaths: [String: URL] = [:]
    private var modelFiles: [String: URL] = [:]
    private var imageCache: [URL: CGImage] = [:]
    private var textureInfo: [URL: String] = [:]
    private var meshCache: [URL: MeshData] = [:]
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
    }

    func chooseLibrary() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Открыть папку"
        panel.message = "Папка с эффектами и текстурами"
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
                if url.deletingLastPathComponent().lastPathComponent == "models" {
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
        objectWillChange.send()
    }

    func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Открыть"
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

    func textureDescription(_ path: String) -> String {
        guard let url = textureURL(path) else {
            return libraryRoot == nil ? "Откройте папку с текстурами (⇧⌘O)" : "Файл не найден в открытой папке"
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
