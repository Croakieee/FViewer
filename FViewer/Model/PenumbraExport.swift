import Foundation

struct ModDescription {
    var name = ""
    var author = ""
    var version = "1.0.0"
    var description = "Exported from FViewer"
    var website = ""
}

enum PenumbraExport {
    static func normalized(_ gamePath: String) -> String {
        gamePath.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "/").lowercased()
    }

    static func problem(in gamePath: String) -> String? {
        let path = normalized(gamePath)
        if path.isEmpty { return "The game path is empty" }
        if path.hasPrefix("/") || path.contains("//") || path.contains("..") || path.contains(":") { return "\(path) is not a game path" }
        if !path.contains("/") || (path as NSString).pathExtension.isEmpty { return "\(path) must look like vfx/…/eff/name.avfx" }
        return nil
    }

    static func guessEffectPath(_ document: EffectDocument) -> String {
        var name = document.url.deletingPathExtension().lastPathComponent
        if document.isEditedCopy { name.removeLast(EffectDocument.editSuffix.count) }
        let file = name + "." + document.url.pathExtension
        for slot in document.textureSlots {
            let parts = slot.path.lowercased().split(separator: "/").map(String.init)
            if let at = parts.lastIndex(of: "texture"), at >= 1 { return (parts[..<at] + ["eff", file]).joined(separator: "/") }
        }
        return "vfx/" + file
    }

    static func archive(_ mod: ModDescription, files: [(gamePath: String, data: [UInt8])]) -> [UInt8] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var redirects: [JSONMember] = []
        var entries: [(path: String, data: [UInt8])] = []
        for file in files {
            let path = normalized(file.gamePath)
            redirects.append(JSONMember(key: path, node: JSONNode(.string(path.replacingOccurrences(of: "/", with: "\\")))))
            entries.append((path, file.data))
        }
        func text(_ value: String) -> JSONNode { JSONNode(.string(value)) }
        let container = JSONNode(.object([
            JSONMember(key: "Files", node: JSONNode(.object(redirects))),
            JSONMember(key: "FileSwaps", node: JSONNode(.object([]))),
            JSONMember(key: "Manipulations", node: JSONNode(.array([]))),
        ]))
        let meta = JSONNode(.object([
            JSONMember(key: "FileVersion", node: JSONNode(.number(4))),
            JSONMember(key: "Identifier", node: text(UUID().uuidString.lowercased())),
            JSONMember(key: "LastWrite", node: text(formatter.string(from: Date()))),
            JSONMember(key: "Name", node: text(mod.name)),
            JSONMember(key: "Author", node: text(mod.author)),
            JSONMember(key: "Description", node: text(mod.description)),
            JSONMember(key: "Version", node: text(mod.version)),
            JSONMember(key: "Website", node: text(mod.website)),
            JSONMember(key: "ModTags", node: JSONNode(.array([]))),
            JSONMember(key: "DefaultData", node: container),
            JSONMember(key: "Groups", node: JSONNode(.array([]))),
        ]))
        entries.insert(("meta.json", Array(meta.serialized().utf8)), at: 0)
        return ZipWriter.archive(entries)
    }
}
