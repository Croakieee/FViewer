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
    @Published var viewportBackground = 0
    @Published var highlightSelection = true

    static let backgrounds: [(name: String, value: Double)] = [("Dark Grey", 0.24), ("Black", 0.02), ("Mid Grey", 0.5), ("Light", 0.82)]

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
    private var avfxMeshes: (document: UUID, revision: Int, meshes: [(id: String, mesh: MeshData)])?
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
            default:
                let name = url.lastPathComponent.lowercased()
                if name.hasPrefix("~"), name.count >= 9, textureFiles[name] == nil { textureFiles[name] = url }
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

    @Published var notice: String?
    @Published var modExport = false

    func isCustomTexture(_ path: String) -> Bool {
        guard let url = textureURL(path) else { return false }
        let lower = path.lowercased()
        let parts = lower.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return true }
        let tail = parts.suffix(2).joined(separator: "/")
        return !url.path.lowercased().hasSuffix("/" + tail)
    }

    func modArchive(_ mod: ModDescription, effectPath: String, textures: [String]) throws -> Data {
        guard let document, document.format == .avfx else { throw AvfxError.malformed("Only .avfx effects can be exported as a mod") }
        if let problem = PenumbraExport.problem(in: effectPath) { throw AvfxError.malformed(problem) }
        var files: [(gamePath: String, data: [UInt8])] = [(effectPath, [UInt8](document.serializedData()))]
        for path in textures.sorted() {
            guard let url = textureURL(path) else { throw AvfxError.malformed("\(path) was not found in the open folder") }
            if url.pathExtension.lowercased() == "png" { throw AvfxError.malformed("\(path) resolves to a PNG; convert it with Replace Image first") }
            files.append((path, [UInt8](try Data(contentsOf: url))))
        }
        return Data(PenumbraExport.archive(mod, files: files))
    }

    func exportMod(_ mod: ModDescription, effectPath: String, textures: [String]) {
        do {
            let data = try modArchive(mod, effectPath: effectPath, textures: textures)
            let panel = NSSavePanel()
            panel.title = "Export Penumbra Mod"
            panel.nameFieldStringValue = mod.name + ".pmp"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            notice = "Mod written to \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importNodesPanel() {
        guard let document, document.format == .avfx else { return }
        let panel = NSOpenPanel()
        panel.title = "Import Nodes"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Import"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let count = try document.importNodes(Data(contentsOf: url), legacy: url.pathExtension.lowercased() == "vfxedit")
            notice = "Imported \(count) node\(count == 1 ? "" : "s") from \(url.lastPathComponent)"
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func exportNodes(_ ids: Set<String>, withDependencies: Bool) {
        guard let document, !ids.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export Nodes"
        panel.nameFieldStringValue = "ExportedVfx.vfxedit2"
        panel.directoryURL = document.url.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try document.exportNodes(ids, withDependencies: withDependencies).write(to: url, options: .atomic)
            notice = "Exported to \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cleanUp() {
        guard let document else { return }
        let count = document.cleanUp()
        notice = count == 0 ? "Nothing to clean up: every node is in use" : "Removed \(count) unused node\(count == 1 ? "" : "s")"
    }

    private func freeURL(_ directory: URL, _ name: String, _ ext: String) -> URL {
        var base = name
        var candidate = directory.appendingPathComponent(base).appendingPathExtension(ext)
        while FileManager.default.fileExists(atPath: candidate.path) {
            base += EffectDocument.editSuffix
            candidate = directory.appendingPathComponent(base).appendingPathExtension(ext)
        }
        return candidate
    }

    func textureData(from source: URL) throws -> (data: Data, ext: String) {
        let ext = source.pathExtension.lowercased()
        if ext == "atex" || ext == "tex" {
            let data = try Data(contentsOf: source)
            _ = try Atex.decode([UInt8](data))
            return (data, ext)
        }
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              let pixels = AtexWriter.rgba(from: image) else {
            throw AvfxError.malformed("\(source.lastPathComponent) is not an image this app can read")
        }
        return (Data(AtexWriter.encode(width: pixels.width, height: pixels.height, rgba: pixels.pixels)), "atex")
    }

    func installTexture(from source: URL, for block: AvfxBlock, in document: EffectDocument) throws -> URL {
        guard block.tag == "Tex", block.children == nil else { throw AvfxError.malformed("Select a texture node first") }
        let converted = try textureData(from: source)
        let directory = document.url.deletingLastPathComponent()
        let destination = freeURL(directory, source.deletingPathExtension().lastPathComponent, converted.ext)
        try converted.data.write(to: destination, options: .atomic)
        let old = block.stringValue
        let folder = (old as NSString).deletingLastPathComponent
        let path = folder.isEmpty ? destination.lastPathComponent : folder + "/" + destination.lastPathComponent
        document.perform("Replace Texture", { block.stringValue = path }, revert: { block.stringValue = old })
        textureFiles[destination.lastPathComponent.lowercased()] = destination
        imageCache = [:]
        decodedCache = [:]
        libraryToken += 1
        objectWillChange.send()
        return destination
    }

    func replaceTexture(_ block: AvfxBlock) {
        guard let document else { return }
        let panel = NSOpenPanel()
        panel.title = "Replace Texture"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Replace"
        panel.message = "Choose a PNG, JPEG, TIFF, .atex or .tex file. A new texture file is written next to the effect; game files are never changed."
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let written = try installTexture(from: url, for: block, in: document)
            notice = "Texture written to \(written.lastPathComponent)"
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func pngData(for path: String) -> Data? {
        guard let image = image(for: path) else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }

    func exportTexture(_ path: String) {
        guard let data = pngData(for: path) else {
            errorMessage = "\((path as NSString).lastPathComponent) was not found in the open folder, so there is nothing to export"
            return
        }
        let panel = NSSavePanel()
        panel.title = "Export Texture"
        panel.nameFieldStringValue = ((path as NSString).lastPathComponent as NSString).deletingPathExtension + ".png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url, options: .atomic)
            notice = "Exported \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportModel(_ block: AvfxBlock, name: String) {
        let mesh = Gltf.mesh(from: block)
        guard !mesh.positions.isEmpty else {
            errorMessage = "This model has no vertices to export"
            return
        }
        let panel = NSSavePanel()
        panel.title = "Export Model"
        panel.nameFieldStringValue = name + ".glb"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try Data(Gltf.glb(mesh, name: name)).write(to: url, options: .atomic)
            notice = "Exported \(mesh.positions.count) vertices to \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importModel(_ block: AvfxBlock, emitPoints: Bool) {
        guard let document else { return }
        let panel = NSOpenPanel()
        panel.title = emitPoints ? "Import Emit Points" : "Import Model"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Import"
        panel.message = "Choose a .glb or .gltf file"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let mesh = try Gltf.load(url)
            try document.applyMesh(mesh, to: block, emitPoints: emitPoints)
            var text = emitPoints ? "Imported \(mesh.positions.count) emit points" : "Imported \(mesh.positions.count) vertices, \(mesh.indices.count / 3) triangles"
            if !mesh.notes.isEmpty { text += " · " + mesh.notes.joined(separator: " · ") }
            notice = text
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func isDirty(_ url: URL) -> Bool { documents[url]?.isDirty ?? false }

    func save() {
        guard let document else { return }
        let old = document.url
        do {
            try document.save()
            moved(document, from: old)
        } catch {
            saveAs()
        }
    }

    private func moved(_ document: EffectDocument, from old: URL) {
        guard document.url != old else { return }
        documents[old] = nil
        documents[document.url] = document
        notice = "Saved as \(document.url.lastPathComponent). The original \(old.lastPathComponent) is untouched"
        if let root = libraryRoot, document.url.path.hasPrefix(root.path) { setLibrary(root) }
    }

    func saveAs() {
        guard let document else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = document.saveDestination.lastPathComponent
        panel.directoryURL = document.url.deletingLastPathComponent()
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let old = document.url
            try document.save(to: url)
            moved(document, from: old)
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
        let file = (lower as NSString).lastPathComponent
        if let hit = textureFiles[file] { return hit }
        let hashed = String(format: "~%08x", ~ZipWriter.crc32(Array(file.utf8)))
        return textureFiles[hashed] ?? textureFiles.first { ($0.key as NSString).deletingPathExtension == hashed }?.value
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
            if let cached = avfxMeshes, cached.document == document.id, cached.revision == document.revision { return cached.meshes }
            let meshes = root.childrenNamed("Modl").enumerated().map { (id: "avfx/Modl/\($0.offset)", mesh: MeshData.fromAvfx($0.element)) }
            avfxMeshes = (document.id, document.revision, meshes)
            return meshes
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
