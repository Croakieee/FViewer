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
        try? encoder.encode(meta.filter { $0.value.color != 0 || !$0.value.note.isEmpty }).write(to: url, options: .atomic)
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
}
