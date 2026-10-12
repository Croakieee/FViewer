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
    @Published var showFloor = false
    @Published var showGizmo = true
    @Published var themeToken = 0
    @Published var showCatalog = false
    @Published var catalogNote: String?
    @Published var viewportBackground = 0
    @Published var highlightSelection = true
    @Published var gameRoot: URL?
    @Published var convertImages = false
    @Published var effectList: EffectList?
    @Published var modList: [PenumbraMod]?
    @Published var gameFile: GameFileDocument?
    @Published var skeletonName: String?
    @Published var timelineHits: [URL]?
    var openGameFileWindow: (() -> Void)?
    var game: GameArchive?

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
        restoreGameFolder()
        restoreSkeleton()
        startAutosave()
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

    func setLibrary(_ root: URL) {
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
            remember(url)
            document = opened
            scheduleThumbnail(for: url)
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
    @Published var modelEditorTarget: String?
    var openModelWindow: (() -> Void)?
    @Published var textureEditorTarget: String?
    var openTextureWindow: (() -> Void)?

    @Published var itemEditorTarget: String?
    var openItemWindow: (() -> Void)?
    var openSettingsWindow: (() -> Void)?

    static func itemEditorRoot(_ id: String) -> String? {
        let parts = id.split(separator: "/").map(String.init)
        guard parts.count >= 3 else { return nil }
        let kinds = parts[0] == "avfx" ? ["Schd", "TmLn", "Emit", "Ptcl", "Efct", "Bind"] : parts[0] == "json" ? ["timelines", "emitters", "particles"] : []
        return kinds.contains(parts[1]) ? parts.prefix(3).joined(separator: "/") : nil
    }

    func canOpenEditor(_ nodeID: String) -> Bool {
        nodeID.hasPrefix("avfx/Tex/") || nodeID.hasPrefix("avfx/Modl/") || AppModel.itemEditorRoot(nodeID).flatMap { document?.node($0) } != nil
    }

    func openEditor(for nodeID: String) {
        guard let document else { return }
        if nodeID.hasPrefix("avfx/Tex/") {
            requestTextureEditor(nodeID.split(separator: "/").prefix(3).joined(separator: "/"))
        } else if nodeID.hasPrefix("avfx/Modl/") {
            requestModelEditor(nodeID.split(separator: "/").prefix(3).joined(separator: "/"))
        } else if let root = AppModel.itemEditorRoot(nodeID), document.node(root) != nil {
            if !UserDefaults.standard.bool(forKey: "itemEditor.skipQuestion") {
                let alert = NSAlert()
                alert.messageText = "Open the \(EffectDocument.linkKind(root)) Editor in a separate window?"
                alert.informativeText = "It shows every parameter, list, texture layer and curve of this item next to a preview."
                alert.addButton(withTitle: "Open Window")
                alert.addButton(withTitle: "Cancel")
                alert.showsSuppressionButton = true
                let answer = alert.runModal()
                if alert.suppressionButton?.state == .on { UserDefaults.standard.set(true, forKey: "itemEditor.skipQuestion") }
                guard answer == .alertFirstButtonReturn else { return }
            }
            itemEditorTarget = root
            document.selectionID = document.node(nodeID) != nil ? nodeID : root
            openItemWindow?()
        }
    }

    func requestTextureEditor(_ nodeID: String) {
        let alert = NSAlert()
        alert.messageText = "Open the Texture Editor in a separate window?"
        alert.addButton(withTitle: "Open Window")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        textureEditorTarget = nodeID
        openTextureWindow?()
    }

    func requestModelEditor(_ nodeID: String) {
        let alert = NSAlert()
        alert.messageText = "Open the Model Editor in a separate window?"
        alert.informativeText = "It shows the UV layout and the vertex and emit point tables of this model."
        alert.addButton(withTitle: "Open Window")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        modelEditorTarget = nodeID
        openModelWindow?()
    }

    func isCustomTexture(_ path: String) -> Bool {
        guard let url = textureURL(path) else { return false }
        if path.hasPrefix(customPrefix) { return true }
        let lower = path.lowercased()
        let parts = lower.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return true }
        let tail = parts.suffix(2).joined(separator: "/")
        return !url.path.lowercased().hasSuffix("/" + tail)
    }

    func modArchive(_ mod: ModDescription, effectPath: String, textures: [String]) throws -> Data {
        guard let document else { throw AvfxError.malformed("No effect is open") }
        return try modArchive(mod, effects: [(document, effectPath)], textures: textures)
    }

    func exportMod(_ mod: ModDescription, effects: [(document: EffectDocument, path: String)], textures: [String], texTools: Bool = false, group: ModGroup? = nil) {
        do {
            let data = try texTools ? texToolsArchive(mod, effects: effects, textures: textures) : modArchive(mod, effects: effects, textures: textures, group: group)
            let panel = NSSavePanel()
            panel.title = texTools ? "Export TexTools Mod" : "Export Penumbra Mod"
            panel.nameFieldStringValue = mod.name + (texTools ? ".ttmp2" : ".pmp")
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            notice = "Mod written to \(url.lastPathComponent): \(effects.count) effect\(effects.count == 1 ? "" : "s"), \(Set(textures).count) texture\(Set(textures).count == 1 ? "" : "s")"
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

    func freeURL(_ directory: URL, _ name: String, _ ext: String) -> URL {
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
        if ext == "dds" {
            return (Data(try TextureCodec.atex(fromDDS: [UInt8](try Data(contentsOf: source)))), "atex")
        }
        if ext == "atex" || ext == "tex" {
            let data = try Data(contentsOf: source)
            _ = try Atex.decode([UInt8](data))
            return (data, ext)
        }
        guard let imageSource = CGImageSourceCreateWithURL(source as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              let pixels = AtexWriter.rgba(from: image) else {
            throw AvfxError.malformed("\(source.lastPathComponent) is not an image this app can read")
        }
        return (Data(encodeTexture(TextureImage(width: pixels.width, height: pixels.height, rgba: pixels.pixels))), "atex")
    }

    var importFormat: TexFormat {
        TexFormat(rawValue: UInt32(UserDefaults.standard.integer(forKey: "texture.format"))) ?? .bc3
    }

    var importMips: Int {
        let stored = UserDefaults.standard.integer(forKey: "texture.mips")
        return stored > 0 ? stored : 9
    }

    func encodeTexture(_ image: TextureImage) -> [UInt8] {
        TextureCodec.encode(image, format: importFormat, mips: importMips)
    }

    func writeTexture(_ data: Data, name: String, ext: String, for block: AvfxBlock, in document: EffectDocument, title: String) throws -> URL {
        guard block.tag == "Tex", block.children == nil else { throw AvfxError.malformed("Select a texture node first") }
        let destination = freeURL(document.url.deletingLastPathComponent(), name, ext)
        try data.write(to: destination, options: .atomic)
        let old = block.stringValue
        let folder = (old as NSString).deletingLastPathComponent
        let path = folder.isEmpty ? destination.lastPathComponent : folder + "/" + destination.lastPathComponent
        document.perform(title, { block.stringValue = path }, revert: { block.stringValue = old })
        textureFiles[destination.lastPathComponent.lowercased()] = destination
        imageCache = [:]
        decodedCache = [:]
        libraryToken += 1
        objectWillChange.send()
        return destination
    }

    enum TextureOperation: String, CaseIterable {
        case rotateLeft = "Rotate Left", rotateRight = "Rotate Right", flipHorizontal = "Flip Horizontally", flipVertical = "Flip Vertically"
        case grayscale = "Grayscale", halve = "Halve Size", double = "Double Size"

        var symbol: String {
            switch self {
            case .rotateLeft: return "rotate.left"
            case .rotateRight: return "rotate.right"
            case .flipHorizontal: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
            case .flipVertical: return "arrow.up.and.down.righttriangle.up.righttriangle.down"
            case .grayscale: return "circle.lefthalf.filled"
            case .halve: return "arrow.down.right.and.arrow.up.left"
            case .double: return "arrow.up.left.and.arrow.down.right"
            }
        }
    }

    func transformedTexture(_ block: AvfxBlock, _ operation: TextureOperation) throws -> TextureImage {
        let path = block.stringValue
        var source: TextureImage?
        if let decoded = decodedTexture(for: path) {
            var rgba = decoded.rgba
            if decoded.alphaOnly {
                for i in stride(from: 0, to: rgba.count, by: 4) {
                    rgba[i] = 255
                    rgba[i + 1] = 255
                    rgba[i + 2] = 255
                }
            }
            source = TextureImage(width: decoded.width, height: decoded.height, rgba: rgba)
        } else if let image = image(for: path), let pixels = AtexWriter.rgba(from: image) {
            source = TextureImage(width: pixels.width, height: pixels.height, rgba: pixels.pixels)
        }
        guard let source else { throw AvfxError.malformed("\((path as NSString).lastPathComponent) was not found in the open folder") }
        switch operation {
        case .rotateLeft: return source.rotated(clockwise: false)
        case .rotateRight: return source.rotated(clockwise: true)
        case .flipHorizontal: return source.flipped(horizontal: true)
        case .flipVertical: return source.flipped(horizontal: false)
        case .grayscale: return source.grayscale()
        case .halve: return source.resized(width: max(source.width / 2, 1), height: max(source.height / 2, 1))
        case .double:
            guard source.width <= 4096, source.height <= 4096 else { throw AvfxError.malformed("The texture is already as large as it can get") }
            return source.resized(width: source.width * 2, height: source.height * 2)
        }
    }

    func transformTexture(_ block: AvfxBlock, _ operation: TextureOperation) {
        guard let document else { return }
        do {
            let image = try transformedTexture(block, operation)
            let name = ((block.stringValue as NSString).lastPathComponent as NSString).deletingPathExtension
            let written = try writeTexture(Data(encodeTexture(image)), name: name, ext: "atex", for: block, in: document, title: operation.rawValue)
            notice = "\(operation.rawValue): \(image.width)×\(image.height) written to \(written.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportTextureFile(_ path: String, dds: Bool) {
        guard let url = textureURL(path), url.pathExtension.lowercased() != "png", let data = try? Data(contentsOf: url) else {
            errorMessage = "\((path as NSString).lastPathComponent) was not found as a game texture in the open folder"
            return
        }
        do {
            let payload = dds ? Data(try TextureCodec.dds(fromAtex: [UInt8](data))) : data
            let panel = NSSavePanel()
            panel.title = "Export Texture"
            let base = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
            panel.nameFieldStringValue = dds ? base + ".dds" : (path as NSString).lastPathComponent
            guard panel.runModal() == .OK, let target = panel.url else { return }
            try payload.write(to: target, options: .atomic)
            notice = "Exported \(target.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    static let usefulTextures: [(path: String, name: String)] = {
        guard let url = Bundle.main.url(forResource: "useful_textures", withExtension: "txt"), let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            guard let path = parts.first, path.contains("/") else { return nil }
            return (path, parts.count > 1 ? parts[1] : (path as NSString).lastPathComponent)
        }
    }()

    var recentFiles: [URL] {
        (UserDefaults.standard.array(forKey: "recent.bookmarks") as? [Data] ?? []).compactMap { data in
            var stale = false
            return try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale)
        }
    }

    private func remember(_ url: URL) {
        guard !CommandLine.arguments.contains("--script"), let bookmark = try? url.bookmarkData(options: [.withSecurityScope]) else { return }
        var list = (UserDefaults.standard.array(forKey: "recent.bookmarks") as? [Data] ?? []).filter { data in
            var stale = false
            return (try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale))?.standardizedFileURL != url.standardizedFileURL
        }
        list.insert(bookmark, at: 0)
        UserDefaults.standard.set(Array(list.prefix(12)), forKey: "recent.bookmarks")
    }

    func openRecent(_ url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        open(url)
    }

    func installTexture(from source: URL, for block: AvfxBlock, in document: EffectDocument) throws -> URL {
        let converted = try textureData(from: source)
        return try writeTexture(converted.data, name: source.deletingPathExtension().lastPathComponent, ext: converted.ext, for: block, in: document,
                                title: "Replace Texture")
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
        panel.message = "PNG, JPEG, TIFF, DDS, .atex or .tex"
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

    var customPrefix: String {
        let stored = UserDefaults.standard.string(forKey: "texture.prefix") ?? ""
        return stored.isEmpty ? "vfx/custom/" : stored
    }

    func convertTextures() {
        guard let document, let root = document.avfxRoot else { return }
        let prefix = customPrefix.hasSuffix("/") ? customPrefix : customPrefix + "/"
        let textures = root.childrenNamed("Tex").filter { !$0.stringValue.hasPrefix(prefix) && !$0.stringValue.isEmpty }
        guard !textures.isEmpty else {
            notice = "Every texture already uses a custom path"
            return
        }
        document.performStructural("Convert Textures") {
            for texture in textures {
                var path = texture.stringValue
                if path.hasPrefix("vfx/") { path.removeFirst(4) }
                texture.stringValue = prefix + path
            }
        }
        notice = "\(textures.count) texture path\(textures.count == 1 ? "" : "s") moved under \(prefix)"
    }

    func reloadDocument() {
        guard let document else { return }
        if document.isDirty {
            let alert = NSAlert()
            alert.messageText = "Reload \(document.title) from disk?"
            alert.informativeText = "Unsaved changes to this effect will be lost."
            alert.addButton(withTitle: "Reload")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        let url = document.url
        documents[url] = nil
        open(url)
        notice = "Reloaded \(url.lastPathComponent)"
    }

    func importPenumbraMod() {
        let panel = NSOpenPanel()
        panel.title = "Import Penumbra Mod"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Choose .pmp"
        guard panel.runModal() == .OK, let archive = panel.url else { return }
        let target = NSOpenPanel()
        target.title = "Extract Into"
        target.canChooseDirectories = true
        target.canChooseFiles = false
        target.canCreateDirectories = true
        target.prompt = "Extract Here"
        guard target.runModal() == .OK, let folder = target.url else { return }
        do {
            let count = try extractMod(archive, into: folder)
            if let bookmark = try? folder.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: AppModel.bookmarkKey) }
            setLibrary(folder)
            notice = "Extracted \(count) file\(count == 1 ? "" : "s") from \(archive.lastPathComponent)"
        } catch {
            errorMessage = "\(archive.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func extractMod(_ archive: URL, into folder: URL) throws -> Int {
        let bytes = [UInt8](try Data(contentsOf: archive))
        let wanted: Set<String> = ["avfx", "atex", "tex", "json"]
        var count = 0
        for entry in try ZipReader.entries(bytes) where !entry.path.hasSuffix("/") {
            let parts = entry.path.split(separator: "/").map(String.init)
            guard !parts.contains(".."), !entry.path.hasPrefix("/"), wanted.contains((entry.path as NSString).pathExtension.lowercased()) else { continue }
            let destination = parts.reduce(folder) { $0.appendingPathComponent($1) }
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) { continue }
            try Data(try ZipReader.data(entry, in: bytes)).write(to: destination, options: .atomic)
            count += 1
        }
        guard count > 0 else { throw AvfxError.malformed("The archive holds no new effect or texture files") }
        return count
    }

    private var autosaveTimer: Timer?

    var autosaveMinutes: Int {
        let stored = UserDefaults.standard.integer(forKey: "autosave.minutes")
        return stored == 0 ? 5 : stored
    }

    var autosaveFolder: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/Autosave", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func startAutosave() {
        autosaveTimer?.invalidate()
        guard autosaveMinutes > 0 else { return }
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Double(autosaveMinutes) * 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.autosaveNow() }
        }
    }

    @discardableResult func autosaveNow() -> Int {
        guard let folder = autosaveFolder else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        var written = 0
        for document in dirtyDocuments {
            let base = document.url.deletingPathExtension().lastPathComponent
            let name = "\(base)-\(formatter.string(from: Date())).\(document.url.pathExtension)"
            if (try? document.serializedData().write(to: folder.appendingPathComponent(name), options: .atomic)) != nil { written += 1 }
            let older = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
                .filter { $0.lastPathComponent.hasPrefix(base + "-") }.sorted { $0.lastPathComponent > $1.lastPathComponent }
            for url in older.dropFirst(5) { try? FileManager.default.removeItem(at: url) }
        }
        return written
    }

    func revealAutosaves() {
        if let folder = autosaveFolder { NSWorkspace.shared.activateFileViewerSelecting([folder]) }
    }

    func renameNode(_ nodeID: String) {
        guard let document, let node = document.node(nodeID) else { return }
        let alert = NSAlert()
        alert.messageText = "Rename \(node.title)"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = document.names[nodeID] ?? ""
        field.placeholderString = node.title
        alert.accessoryView = field
        alert.addButton(withTitle: "Rename")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        document.setName(field.stringValue.trimmingCharacters(in: .whitespaces), for: nodeID)
    }

    func prompt(_ title: String, placeholder: String, value: String = "") -> String? {
        let alert = NSAlert()
        alert.messageText = title
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 280, height: 24))
        field.stringValue = value
        field.placeholderString = placeholder
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let text = field.stringValue.trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    var nodeLibraryFolder: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/NodeLibrary", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    var nodeLibraryItems: [(name: String, url: URL)] {
        guard let folder = nodeLibraryFolder, let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else { return [] }
        var items: [(String, URL)] = []
        let base = folder.standardizedFileURL.path
        for case let url as URL in walker where ["vfxedit2", "vfxedit"].contains(url.pathExtension.lowercased()) {
            let relative = String(url.standardizedFileURL.path.dropFirst(base.count + 1))
            items.append(((relative as NSString).deletingPathExtension, url))
        }
        return items.sorted { $0.0 < $1.0 }
    }

    func saveToNodeLibrary(_ nodeID: String, name: String) throws -> URL {
        guard let document, let folder = nodeLibraryFolder else { throw AvfxError.malformed("The node library folder is not available") }
        let parts = name.split(separator: "/").map { String($0).replacingOccurrences(of: ":", with: "-") }.filter { !$0.isEmpty && $0 != ".." }
        guard !parts.isEmpty else { throw AvfxError.malformed("Give the library entry a name") }
        let target = parts.reduce(folder) { $0.appendingPathComponent($1) }.appendingPathExtension("vfxedit2")
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try document.exportNodes([nodeID], withDependencies: true).write(to: target, options: .atomic)
        objectWillChange.send()
        return target
    }

    func saveToNodeLibrary(_ nodeID: String) {
        guard let document, let node = document.node(nodeID),
              let name = prompt("Save \(node.title) to the Node Library", placeholder: "Folder/Name", value: node.title) else { return }
        do {
            _ = try saveToNodeLibrary(nodeID, name: name)
            notice = "Saved \(name) to the node library with its dependencies"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importFromNodeLibrary(_ url: URL) {
        guard let document else { return }
        do {
            let count = try document.importNodes(Data(contentsOf: url), legacy: url.pathExtension.lowercased() == "vfxedit")
            notice = "Imported \(count) node\(count == 1 ? "" : "s") from the library"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func revealNodeLibrary() {
        if let folder = nodeLibraryFolder { NSWorkspace.shared.activateFileViewerSelecting([folder]) }
    }

    var textureLibrary: [(path: String, name: String)] {
        (UserDefaults.standard.stringArray(forKey: "texture.library") ?? []).map { entry in
            let parts = entry.split(separator: "|", maxSplits: 1).map(String.init)
            return (parts[0], parts.count > 1 ? parts[1] : (parts[0] as NSString).lastPathComponent)
        }
    }

    func addToTextureLibrary(_ path: String) {
        var list = UserDefaults.standard.stringArray(forKey: "texture.library") ?? []
        guard !path.isEmpty, !list.contains(where: { $0.hasPrefix(path + "|") || $0 == path }) else { return }
        let name = prompt("Name for \((path as NSString).lastPathComponent)", placeholder: "Name", value: ((path as NSString).lastPathComponent as NSString).deletingPathExtension) ?? ""
        list.append(name.isEmpty ? path : path + "|" + name)
        UserDefaults.standard.set(list, forKey: "texture.library")
        objectWillChange.send()
    }

    func removeFromTextureLibrary(_ path: String) {
        let list = (UserDefaults.standard.stringArray(forKey: "texture.library") ?? []).filter { !($0.hasPrefix(path + "|") || $0 == path) }
        UserDefaults.standard.set(list, forKey: "texture.library")
        objectWillChange.send()
    }

    var favorites: Set<String> { Set(UserDefaults.standard.stringArray(forKey: "favorites") ?? []) }

    func toggleFavorite(_ url: URL) {
        var list = UserDefaults.standard.stringArray(forKey: "favorites") ?? []
        if let index = list.firstIndex(of: url.path) { list.remove(at: index) } else { list.append(url.path) }
        UserDefaults.standard.set(list, forKey: "favorites")
        objectWillChange.send()
    }

    var openDocuments: [EffectDocument] { documents.values.sorted { $0.title < $1.title } }

    struct Workspace: Codable {
        var files: [String] = []
        var current: String = ""
        var modName = ""
        var modAuthor = ""
        var modVersion = "1.0.0"
        var modDescription = ""
    }

    var workspaceFiles: [URL] {
        guard let root = libraryRoot else { return [] }
        return ((try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "fvworkspace" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func workspaceData() -> Workspace? {
        guard let root = libraryRoot else { return nil }
        let base = root.standardizedFileURL.path
        func relative(_ url: URL) -> String? {
            let path = url.standardizedFileURL.path
            return path.hasPrefix(base + "/") ? String(path.dropFirst(base.count + 1)) : nil
        }
        var workspace = Workspace()
        workspace.files = openDocuments.compactMap { relative($0.url) }
        workspace.current = document.flatMap { relative($0.url) } ?? ""
        let defaults = UserDefaults.standard
        workspace.modName = defaults.string(forKey: "mod.name") ?? ""
        workspace.modAuthor = defaults.string(forKey: "mod.author") ?? ""
        return workspace
    }

    func saveWorkspace(named name: String) throws -> URL {
        guard let root = libraryRoot, let workspace = workspaceData() else { throw AvfxError.malformed("Open a folder first: a workspace is stored inside it") }
        let unsaved = openDocuments.filter(\.isDirty)
        for document in unsaved {
            let old = document.url
            try document.save()
            moved(document, from: old)
        }
        guard let refreshed = workspaceData() else { return root }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let target = root.appendingPathComponent(name).appendingPathExtension("fvworkspace")
        try encoder.encode(unsaved.isEmpty ? workspace : refreshed).write(to: target, options: .atomic)
        return target
    }

    func saveWorkspace() {
        guard libraryRoot != nil else {
            errorMessage = "Open a folder first: a workspace is stored inside it"
            return
        }
        guard let name = prompt("Save Workspace", placeholder: "Name", value: workspaceFiles.first?.deletingPathExtension().lastPathComponent ?? "workspace") else { return }
        do {
            let url = try saveWorkspace(named: name)
            notice = "Workspace saved to \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openWorkspace(_ url: URL, append: Bool = false) {
        guard let root = libraryRoot, let data = try? Data(contentsOf: url), let workspace = try? JSONDecoder().decode(Workspace.self, from: data) else {
            errorMessage = "\(url.lastPathComponent) could not be read"
            return
        }
        if !append {
            guard confirmDiscardingChanges() else { return }
            documents = [:]
            document = nil
        }
        let previous = document?.url
        var missing = 0
        for file in workspace.files {
            let target = file.split(separator: "/").reduce(root) { $0.appendingPathComponent(String($1)) }
            if FileManager.default.fileExists(atPath: target.path) { open(target) } else { missing += 1 }
        }
        if append, let previous {
            open(previous)
        } else if !workspace.current.isEmpty {
            let target = workspace.current.split(separator: "/").reduce(root) { $0.appendingPathComponent(String($1)) }
            if FileManager.default.fileExists(atPath: target.path) { open(target) }
        }
        if !append, !workspace.modName.isEmpty { UserDefaults.standard.set(workspace.modName, forKey: "mod.name") }
        notice = "Opened \(workspace.files.count - missing) effect\(workspace.files.count - missing == 1 ? "" : "s")" + (missing > 0 ? " · \(missing) missing" : "")
    }

    func modFiles(effects: [(document: EffectDocument, path: String)], textures: [String], group: ModGroup? = nil) throws -> [(gamePath: String, data: [UInt8], option: Int)] {
        var files: [(gamePath: String, data: [UInt8], option: Int)] = []
        var seen: Set<String> = []
        if let group, let problem = group.problem { throw AvfxError.malformed(problem) }
        for effect in effects {
            if let problem = PenumbraExport.problem(in: effect.path) { throw AvfxError.malformed("\(effect.document.title): \(problem)") }
            guard effect.document.format == .avfx else { throw AvfxError.malformed("\(effect.document.title) is not an .avfx effect") }
            let option = min(group?.effects[effect.document.id] ?? 0, group?.options.count ?? 0)
            guard seen.insert("\(option)|" + PenumbraExport.normalized(effect.path)).inserted else { throw AvfxError.malformed("\(effect.path) is used by two effects") }
            files.append((effect.path, [UInt8](effect.document.serializedData()), option))
        }
        for path in Set(textures).sorted() {
            guard let url = textureURL(path) else { throw AvfxError.malformed("\(path) was not found in the open folder") }
            if url.pathExtension.lowercased() == "png" { throw AvfxError.malformed("\(path) resolves to a PNG; convert it with Replace Image first") }
            files.append((path, [UInt8](try Data(contentsOf: url)), min(group?.textures[path] ?? 0, group?.options.count ?? 0)))
        }
        return files
    }

    func modArchive(_ mod: ModDescription, effects: [(document: EffectDocument, path: String)], textures: [String], group: ModGroup? = nil) throws -> Data {
        Data(PenumbraExport.archive(mod, files: try modFiles(effects: effects, textures: textures, group: group), group: group))
    }

    func texToolsArchive(_ mod: ModDescription, effects: [(document: EffectDocument, path: String)], textures: [String]) throws -> Data {
        Data(try TexToolsExport.archive(mod, files: try modFiles(effects: effects, textures: textures).map { ($0.gamePath, $0.data) }))
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

    var textureAssets: [(name: String, relative: String, url: URL)] {
        texturePaths.map { (($0.key as NSString).lastPathComponent, $0.key, $0.value) }.sorted { $0.1 < $1.1 }
    }

    var modelAssets: [(name: String, url: URL)] { modelFiles.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 } }

    func assetImage(_ url: URL) -> CGImage? {
        if let cached = imageCache[url] { return cached }
        var image: CGImage?
        if url.pathExtension.lowercased() == "png" {
            image = CGImageSourceCreateWithURL(url as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
        } else if let data = try? Data(contentsOf: url), let decoded = try? Atex.decode([UInt8](data), mip: 1) {
            image = decoded.makeImage()
        }
        if let image { imageCache[url] = image }
        return image
    }

    func gamePath(forAsset url: URL) -> String? {
        let parts = url.standardizedFileURL.path.lowercased().split(separator: "/").map(String.init)
        guard let start = parts.lastIndex(where: { ["vfx", "chara", "bg", "bgcommon"].contains($0) }) else { return nil }
        return parts[start...].joined(separator: "/")
    }

    @discardableResult func addTextureAsset(_ url: URL, to document: EffectDocument) -> Int? {
        guard let root = document.avfxRoot else { return nil }
        let ext = url.pathExtension.lowercased()
        if (ext == "atex" || ext == "tex"), let path = gamePath(forAsset: url) {
            if let existing = root.childrenNamed("Tex").firstIndex(where: { $0.stringValue.lowercased() == path }) { return existing }
            document.addTexture(path: path)
            return root.childrenNamed("Tex").count - 1
        }
        guard AppModel.imageSourceTypes.contains(ext) else { return nil }
        document.undoManager.beginUndoGrouping()
        defer { document.undoManager.endUndoGrouping() }
        document.addTexture(path: customPrefix + url.deletingPathExtension().lastPathComponent.lowercased() + ".atex")
        guard let block = root.childrenNamed("Tex").last else { return nil }
        do {
            _ = try installTexture(from: url, for: block, in: document)
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
        return root.childrenNamed("Tex").count - 1
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
