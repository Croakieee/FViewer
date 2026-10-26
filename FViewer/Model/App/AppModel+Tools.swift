import UniformTypeIdentifiers
import AppKit
import Combine
import Foundation

struct EffectList: Identifiable {
    let id = UUID()
    let title: String
    let paths: [String]
}

enum ImageTarget: Int, CaseIterable {
    case png, dds, atex, tex

    var ext: String {
        switch self {
        case .png: "png"
        case .dds: "dds"
        case .atex: "atex"
        case .tex: "tex"
        }
    }

    var title: String { "." + ext }
}

struct NodeLibraryEntry: Identifiable {
    let id: String
    let name: String
    let folder: String
    let url: URL
    var color: Int
    var note: String
}

struct NodeLibraryMeta: Codable {
    var color = 0
    var note = ""
}

extension AppModel {
    static let imageSourceTypes = ["png", "jpg", "jpeg", "tga", "bmp", "tif", "tiff", "dds", "atex", "tex"]

    func convertImage(_ source: URL, to target: ImageTarget, into folder: URL, reencode: Bool) throws -> URL {
        let ext = source.pathExtension.lowercased()
        let packed = ext == "dds" || ext == "atex" || ext == "tex"
        var output: Data
        switch target {
        case .png:
            let image: CGImage?
            if packed {
                image = try Atex.decode([UInt8](try textureData(from: source).data)).makeImage()
            } else {
                image = CGImageSourceCreateWithURL(source as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) }
            }
            guard let image, let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
                throw AvfxError.malformed("\(source.lastPathComponent) is not an image this app can read")
            }
            output = data
        case .dds, .atex, .tex:
            var texture = try textureData(from: source).data
            if packed, reencode {
                let decoded = try Atex.decode([UInt8](texture))
                texture = Data(encodeTexture(TextureImage(width: decoded.width, height: decoded.height, rgba: decoded.rgba)))
            }
            output = target == .dds ? Data(try TextureCodec.dds(fromAtex: [UInt8](texture))) : texture
        }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = freeURL(folder, source.deletingPathExtension().lastPathComponent, target.ext)
        try output.write(to: destination, options: .atomic)
        return destination
    }

    func convertImages(_ sources: [URL], to target: ImageTarget, into folder: URL, reencode: Bool) -> (written: [URL], failures: [String]) {
        var written: [URL] = []
        var failures: [String] = []
        for source in sources {
            do {
                written.append(try convertImage(source, to: target, into: folder, reencode: reencode))
            } catch {
                failures.append("\(source.lastPathComponent): \(error.localizedDescription)")
            }
        }
        if let root = libraryRoot, folder.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path), !written.isEmpty { setLibrary(root) }
        notice = "Converted \(written.count) of \(sources.count) image\(sources.count == 1 ? "" : "s") to \(target.title)"
        if !failures.isEmpty { errorMessage = failures.joined(separator: "\n") }
        return (written, failures)
    }

    func chooseImages() -> [URL] {
        let panel = NSOpenPanel()
        panel.title = "Images to Convert"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Add"
        guard panel.runModal() == .OK else { return [] }
        return panel.urls.filter { AppModel.imageSourceTypes.contains($0.pathExtension.lowercased()) }
    }

    func chooseFolder(_ title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        return panel.runModal() == .OK ? panel.url : nil
    }

    static func effectPaths(in data: Data) -> [String] {
        var result: [String] = []
        var seen: Set<String> = []
        var run: [UInt8] = []
        func flush() {
            defer { run.removeAll(keepingCapacity: true) }
            guard run.count >= 10 else { return }
            let text = String(decoding: run, as: UTF8.self).lowercased()
            guard text.hasSuffix(".avfx"), let start = text.range(of: "vfx/") ?? text.range(of: "bgcommon/") ?? text.range(of: "bg/") else { return }
            let path = String(text[start.lowerBound...])
            if seen.insert(path).inserted { result.append(path) }
        }
        for byte in data {
            if byte >= 0x21, byte < 0x7F { run.append(byte) } else { flush() }
        }
        flush()
        return result
    }

    func listEffects(of data: Data, title: String) {
        let paths = AppModel.effectPaths(in: data)
        guard !paths.isEmpty else {
            notice = "\(title) starts no effects"
            return
        }
        effectList = EffectList(title: title, paths: paths)
    }

    func listEffectsOfFile() {
        let panel = NSOpenPanel()
        panel.title = "Animation Timeline"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Read"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            listEffects(of: try Data(contentsOf: url), title: url.lastPathComponent)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func listEffectsOfGamePath() {
        guard let game, let entered = prompt("Effects Started by a Timeline", placeholder: "chara/action/…/name.tmb") else { return }
        let path = PenumbraExport.normalized(entered)
        do {
            listEffects(of: try game.read(path), title: path)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var libraryMetaURL: URL? { nodeLibraryFolder?.appendingPathComponent("library.json") }

    var nodeLibraryMeta: [String: NodeLibraryMeta] {
        guard let url = libraryMetaURL, let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: NodeLibraryMeta].self, from: data)) ?? [:]
    }

    private func writeLibraryMeta(_ meta: [String: NodeLibraryMeta]) {
        guard let url = libraryMetaURL else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            try encoder.encode(meta.filter { $0.value.color != 0 || !$0.value.note.isEmpty }).write(to: url, options: .atomic)
        } catch {
            notice = "Library colours and notes could not be saved: \(error.localizedDescription)"
        }
        objectWillChange.send()
    }

    var nodeLibraryEntries: [NodeLibraryEntry] {
        let meta = nodeLibraryMeta
        return nodeLibraryItems.map { item in
            let folder = (item.name as NSString).deletingLastPathComponent
            return NodeLibraryEntry(id: item.name, name: (item.name as NSString).lastPathComponent, folder: folder, url: item.url,
                                    color: meta[item.name]?.color ?? 0, note: meta[item.name]?.note ?? "")
        }
    }

    var nodeLibraryFolders: [String] {
        guard let root = nodeLibraryFolder, let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else { return [] }
        let base = root.standardizedFileURL.path
        var folders: [String] = []
        for case let url as URL in walker where (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            folders.append(String(url.standardizedFileURL.path.dropFirst(base.count + 1)))
        }
        return folders.sorted()
    }

    func libraryEntry(for url: URL) -> NodeLibraryEntry? {
        let path = url.standardizedFileURL.path
        return nodeLibraryEntries.first { $0.url.standardizedFileURL.path == path }
    }

    func setLibraryColor(_ entry: NodeLibraryEntry, _ color: Int) {
        var meta = nodeLibraryMeta
        meta[entry.id, default: NodeLibraryMeta()].color = color
        writeLibraryMeta(meta)
    }

    func setLibraryNote(_ entry: NodeLibraryEntry, _ note: String) {
        var meta = nodeLibraryMeta
        meta[entry.id, default: NodeLibraryMeta()].note = note
        writeLibraryMeta(meta)
    }

    func editLibraryNote(_ entry: NodeLibraryEntry) {
        let alert = NSAlert()
        alert.messageText = "Description of \(entry.name)"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = entry.note
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        setLibraryNote(entry, field.stringValue.trimmingCharacters(in: .whitespaces))
    }

    @discardableResult func moveLibraryEntry(_ entry: NodeLibraryEntry, to target: String) throws -> String {
        guard let root = nodeLibraryFolder else { throw AvfxError.malformed("The node library folder is not available") }
        let parts = target.split(separator: "/").map { String($0).replacingOccurrences(of: ":", with: "-") }.filter { !$0.isEmpty && $0 != ".." }
        guard !parts.isEmpty else { throw AvfxError.malformed("Give the library entry a name") }
        let fresh = parts.joined(separator: "/")
        guard fresh != entry.id else { return fresh }
        let destination = parts.reduce(root) { $0.appendingPathComponent($1) }.appendingPathExtension(entry.url.pathExtension)
        guard !FileManager.default.fileExists(atPath: destination.path) else { throw AvfxError.malformed("\(fresh) is already in the library") }
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: entry.url, to: destination)
        var meta = nodeLibraryMeta
        if let old = meta.removeValue(forKey: entry.id) { meta[fresh] = old }
        writeLibraryMeta(meta)
        return fresh
    }

    func moveLibraryEntry(_ entry: NodeLibraryEntry, toFolder folder: String) {
        do {
            try moveLibraryEntry(entry, to: folder.isEmpty ? entry.name : folder + "/" + entry.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameLibraryEntry(_ entry: NodeLibraryEntry) {
        guard let name = prompt("Rename \(entry.name)", placeholder: "Folder/Name", value: entry.id) else { return }
        do {
            try moveLibraryEntry(entry, to: name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func newLibraryFolder() {
        guard let root = nodeLibraryFolder, let name = prompt("New Library Folder", placeholder: "Name") else { return }
        let parts = name.split(separator: "/").map { String($0).replacingOccurrences(of: ":", with: "-") }.filter { !$0.isEmpty && $0 != ".." }
        guard !parts.isEmpty else { return }
        try? FileManager.default.createDirectory(at: parts.reduce(root) { $0.appendingPathComponent($1) }, withIntermediateDirectories: true)
        objectWillChange.send()
    }

    func removeLibraryEntry(_ entry: NodeLibraryEntry) throws {
        try FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
        var meta = nodeLibraryMeta
        meta.removeValue(forKey: entry.id)
        writeLibraryMeta(meta)
    }

    func deleteLibraryEntry(_ entry: NodeLibraryEntry) {
        let alert = NSAlert()
        alert.messageText = "Move \(entry.name) to the Trash?"
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try removeLibraryEntry(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeLibraryFolder(_ folder: String) {
        guard let root = nodeLibraryFolder, !folder.isEmpty else { return }
        let url = folder.split(separator: "/").reduce(root) { $0.appendingPathComponent(String($1)) }
        let contents = (try? FileManager.default.contentsOfDirectory(atPath: url.path))?.filter { !$0.hasPrefix(".") } ?? []
        guard contents.isEmpty else {
            errorMessage = "\(folder) is not empty"
            return
        }
        try? FileManager.default.removeItem(at: url)
        objectWillChange.send()
    }

    func repeatTimelineItems(_ timeline: AvfxBlock, in document: EffectDocument?) {
        guard let document else { return }
        let span = document.timelineSpan(timeline)
        let alert = NSAlert()
        alert.messageText = "Repeat Timeline Items"
        let copies = NSTextField(frame: NSRect(x: 70, y: 30, width: 90, height: 22))
        copies.stringValue = "1"
        let period = NSTextField(frame: NSRect(x: 70, y: 0, width: 90, height: 22))
        period.stringValue = "\(max(span, 1))"
        let box = NSView(frame: NSRect(x: 0, y: 0, width: 170, height: 54))
        for (text, y) in [("Copies", 32.0), ("Every", 2.0)] {
            let label = NSTextField(labelWithString: text)
            label.frame = NSRect(x: 0, y: y, width: 64, height: 18)
            label.alignment = .right
            box.addSubview(label)
        }
        box.addSubview(copies)
        box.addSubview(period)
        alert.accessoryView = box
        alert.addButton(withTitle: "Repeat")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = copies
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let added = document.repeatItems(timeline, copies: min(max(copies.integerValue, 0), 64), period: max(period.integerValue, 0))
        notice = added == 0 ? "Nothing to repeat" : "Added \(added) timeline item\(added == 1 ? "" : "s")"
    }

    @discardableResult func exportAllTextures(of document: EffectDocument, into folder: URL) -> (written: Int, missing: [String]) {
        var written = 0
        var missing: [String] = []
        var seen: Set<String> = []
        for slot in document.textureSlots where seen.insert(slot.path).inserted {
            guard let data = pngData(for: slot.path) else {
                missing.append(slot.path)
                continue
            }
            let name = ((slot.path as NSString).lastPathComponent as NSString).deletingPathExtension
            do {
                try data.write(to: freeURL(folder, name.isEmpty ? "texture" : name, "png"), options: .atomic)
                written += 1
            } catch {
                missing.append(slot.path)
            }
        }
        return (written, missing)
    }

    func exportAllTextures() {
        guard let document, let folder = chooseFolder("Export All Textures as PNG") else { return }
        let result = exportAllTextures(of: document, into: folder)
        notice = "Exported \(result.written) texture\(result.written == 1 ? "" : "s") as PNG" + (result.missing.isEmpty ? "" : " · \(result.missing.count) skipped")
    }

    var effectFolder: URL? { document?.url.deletingLastPathComponent() ?? libraryRoot }

    func revealEffectFolder() {
        if let document {
            NSWorkspace.shared.activateFileViewerSelecting([document.url])
        } else if let libraryRoot {
            NSWorkspace.shared.open(libraryRoot)
        }
    }

    func copyEffectFolder() {
        guard let folder = effectFolder else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(folder.path, forType: .string)
        notice = "Copied \(folder.path)"
    }

    func openDropped(_ urls: [URL]) -> Bool {
        var handled = false
        for url in urls {
            var isFolder: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder) else { continue }
            let ext = url.pathExtension.lowercased()
            if isFolder.boolValue {
                setLibrary(url)
                if let bookmark = try? url.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: "libraryBookmark") }
                handled = true
            } else if ext == "avfx" || ext == "json" {
                open(url)
                handled = true
            } else if ext == "vfxedit" || ext == "vfxedit2" {
                importFromNodeLibrary(url)
                handled = true
            } else if ["tmb", "pap", "eid", "scd", "mdl", "mtrl", "sklb", "skp", "phyb", "kdb", "pbd", "atch", "shpk", "shcd", "uld"].contains(ext) {
                inspectGameFile(url)
                handled = true
            } else if ext == "fvworkspace", libraryRoot != nil {
                openWorkspace(url)
                handled = true
            }
        }
        return handled
    }

    func mergeEffectPanel() {
        guard let document, document.format == .avfx else { return }
        let panel = NSOpenPanel()
        panel.title = "Merge Effect"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Merge"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let result = try document.mergeEffect(try EffectDocument(url: url))
            notice = "Merged \(url.lastPathComponent): \(result.nodes) node\(result.nodes == 1 ? "" : "s"), \(result.timelines) timeline\(result.timelines == 1 ? "" : "s") scheduled"
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    var thumbnailFolder: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func thumbnailURL(for file: URL) -> URL? {
        let key = String(format: "%08x", ZipWriter.crc32(Array(file.standardizedFileURL.path.utf8)))
        return thumbnailFolder?.appendingPathComponent(key + ".png")
    }

    private static var thumbnailCache: [URL: NSImage?] = [:]

    func thumbnail(for file: URL) -> NSImage? {
        if let known = AppModel.thumbnailCache[file] { return known }
        var image: NSImage?
        if let url = thumbnailURL(for: file), FileManager.default.fileExists(atPath: url.path) { image = NSImage(contentsOf: url) }
        if AppModel.thumbnailCache.count >= 800 { AppModel.thumbnailCache.removeAll() }
        AppModel.thumbnailCache[file] = .some(image)
        return image
    }

    func saveThumbnail(_ image: CGImage, for file: URL) {
        guard let url = thumbnailURL(for: file) else { return }
        let width = 240, height = max(1, image.height * 240 / max(image.width, 1))
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaled = context.makeImage(), let data = NSBitmapImageRep(cgImage: scaled).representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url, options: .atomic)
        AppModel.thumbnailCache[file] = nil
        objectWillChange.send()
    }

    func scheduleThumbnail(for file: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.document?.url == file else { return }
            guard let bridge = PlayerBridge.main, bridge.webView?.window != nil else { return }
            bridge.snapshot { [weak self] image in if let image { self?.saveThumbnail(image, for: file) } }
        }
    }

    private static var notesCache: [String: String]?

    func note(for file: URL) -> String {
        if AppModel.notesCache == nil { AppModel.notesCache = UserDefaults.standard.dictionary(forKey: "file.notes") as? [String: String] ?? [:] }
        return AppModel.notesCache?[file.standardizedFileURL.path] ?? ""
    }

    func setNote(_ text: String, for file: URL) {
        var notes = UserDefaults.standard.dictionary(forKey: "file.notes") as? [String: String] ?? [:]
        let key = file.standardizedFileURL.path
        if text.isEmpty { notes.removeValue(forKey: key) } else { notes[key] = text }
        UserDefaults.standard.set(notes, forKey: "file.notes")
        AppModel.notesCache = notes
        objectWillChange.send()
    }

    func editNote(for file: URL) {
        let alert = NSAlert()
        alert.messageText = "Note for \(file.lastPathComponent)"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        field.stringValue = note(for: file)
        alert.accessoryView = field
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        setNote(field.stringValue.trimmingCharacters(in: .whitespaces), for: file)
    }

    func forgetRecent(_ file: URL) {
        let list = (UserDefaults.standard.array(forKey: "recent.bookmarks") as? [Data] ?? []).filter { data in
            var stale = false
            return (try? URL(resolvingBookmarkData: data, options: [.withSecurityScope], bookmarkDataIsStale: &stale))?.standardizedFileURL != file.standardizedFileURL
        }
        UserDefaults.standard.set(list, forKey: "recent.bookmarks")
        recentCache = nil
        if let url = thumbnailURL(for: file) { try? FileManager.default.removeItem(at: url) }
        objectWillChange.send()
    }

    func captureThumbnail() {
        guard let file = document?.url else {
            notice = "Save the effect first: the snapshot is kept with its file"
            return
        }
        guard let bridge = PlayerBridge.main, bridge.webView?.window != nil else {
            notice = "Open the 3D viewport first: the snapshot is taken from it"
            return
        }
        bridge.snapshot { [weak self] image in
            guard let self, let image else {
                self?.notice = "The preview could not be captured"
                return
            }
            self.saveThumbnail(image, for: file)
            self.notice = "Snapshot saved as the thumbnail of \(file.lastPathComponent)"
        }
    }

    func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear the history?"
        alert.informativeText = "The recent files list and its snapshots are removed. Favourites and notes stay."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        for file in recentFiles where !favorites.contains(file.path) {
            if let url = thumbnailURL(for: file) { try? FileManager.default.removeItem(at: url) }
        }
        UserDefaults.standard.set([Data](), forKey: "recent.bookmarks")
        recentCache = nil
        AppModel.thumbnailCache.removeAll()
        objectWillChange.send()
    }

    func flatModelJSON(_ block: AvfxBlock) -> Data {
        let mesh = MeshData.fromAvfx(block)
        func round(_ value: Float) -> Double { (Double(value) * 100000).rounded() / 100000 }
        var positions: [Double] = [], depth: [Double] = [], uvs: [Double] = [], color: [Double] = [], alpha: [Double] = []
        for vertex in mesh.vertices {
            positions.append(contentsOf: [round(vertex.position.x), round(vertex.position.z)])
            depth.append(round(vertex.position.y))
            uvs.append(contentsOf: [round(vertex.uv.x), round(vertex.uv.y)])
            color.append(contentsOf: [round(vertex.color.x), round(vertex.color.y), round(vertex.color.z)])
            alpha.append(round(vertex.color.w))
        }
        let object: [String: Any] = ["positions": positions, "z": depth, "indices": mesh.indices.map { Int($0) }, "uvs": [uvs], "color": color, "alpha": alpha]
        return (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
    }

    func exportFlatModel(_ block: AvfxBlock, name: String) {
        let panel = NSSavePanel()
        panel.title = "Export Flat JSON Model"
        panel.nameFieldStringValue = name + ".json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try flatModelJSON(block).write(to: url, options: .atomic)
            notice = "Model written to \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadPreviewSettings() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("rule.") || key.hasPrefix("preview.bloom.") || key == "preview.scene" {
            defaults.removeObject(forKey: key)
        }
        if let parts = defaults.string(forKey: "preview.color")?.split(separator: ",").compactMap({ Double($0) }), parts.count == 3 {
            PreviewSettings.backgroundColor = SIMD3(parts[0], parts[1], parts[2])
        }
        if let data = defaults.data(forKey: "preview.look"), let look = try? JSONDecoder().decode(PreviewLook.self, from: data) {
            PreviewSettings.look = look
        }
        if let data = defaults.data(forKey: "preview.stage"), let stage = try? JSONDecoder().decode(PreviewStage.self, from: data) {
            PreviewSettings.stage = stage
        }
        if let data = defaults.data(forKey: "preview.render"), let render = try? JSONDecoder().decode(PreviewRender.self, from: data) {
            PreviewSettings.render = render
        }
    }

    func setRender(_ change: (inout PreviewRender) -> Void) {
        var render = PreviewSettings.render
        change(&render)
        render.fogDensity = min(max(render.fogDensity, 0), 1)
        render.fogStart = min(max(render.fogStart, 0), 1000)
        guard render != PreviewSettings.render else { return }
        PreviewSettings.render = render
        PreviewSettings.token += 1
        if let data = try? JSONEncoder().encode(render) { UserDefaults.standard.set(data, forKey: "preview.render") }
        objectWillChange.send()
    }

    func setPreviewColor(_ color: SIMD3<Double>?) {
        PreviewSettings.backgroundColor = color
        PreviewSettings.token += 1
        if let color {
            UserDefaults.standard.set("\(color.x),\(color.y),\(color.z)", forKey: "preview.color")
        } else {
            UserDefaults.standard.removeObject(forKey: "preview.color")
        }
        objectWillChange.send()
    }

    func setLook(_ change: (inout PreviewLook) -> Void) {
        var look = PreviewSettings.look
        change(&look)
        look.exposure = min(max(look.exposure, -4), 4)
        look.lightIntensity = min(max(look.lightIntensity, 0), 100)
        PreviewSettings.look = look
        PreviewSettings.token += 1
        if let data = try? JSONEncoder().encode(look) { UserDefaults.standard.set(data, forKey: "preview.look") }
        objectWillChange.send()
    }

    func setStage(_ change: (inout PreviewStage) -> Void) {
        var stage = PreviewSettings.stage
        change(&stage)
        stage.distance = min(max(stage.distance, 0), 60)
        stage.side = min(max(stage.side, -30), 30)
        for keyPath in [\PreviewStage.caster, \PreviewStage.target] {
            stage[keyPath: keyPath].amplitude = min(max(stage[keyPath: keyPath].amplitude, 0), 30)
            stage[keyPath: keyPath].period = min(max(stage[keyPath: keyPath].period, 0.2), 60)
            stage[keyPath: keyPath].jumpHeight = min(max(stage[keyPath: keyPath].jumpHeight, 0), 10)
            stage[keyPath: keyPath].jumpPeriod = min(max(stage[keyPath: keyPath].jumpPeriod, 0.2), 60)
        }
        PreviewSettings.stage = stage
        PreviewSettings.token += 1
        if let data = try? JSONEncoder().encode(stage) { UserDefaults.standard.set(data, forKey: "preview.stage") }
        objectWillChange.send()
    }
}
