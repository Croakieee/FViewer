import Foundation

struct ModDescription {
    var name = ""
    var author = ""
    var version = "1.0.0"
    var description = "Exported from FViewer"
    var website = ""
}

struct ModGroup {
    var name = ""
    var multi = false
    var options: [String] = []
    var effects: [UUID: Int] = [:]
    var textures: [String: Int] = [:]

    var problem: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "Give the option group a name" }
        if options.isEmpty { return "Add at least one option" }
        if options.contains(where: { $0.contains("/") || $0.contains("\\") }) { return "Option names cannot contain slashes" }
        if Set(options.map { $0.lowercased() }).count != options.count { return "Option names must differ" }
        return nil
    }
}

enum PenumbraExport {
    static func folderName(_ name: String) -> String {
        let cleaned = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: "\\", with: "-").replacingOccurrences(of: "..", with: "-")
            .trimmingCharacters(in: .whitespaces)
        return cleaned.isEmpty ? "option" : cleaned
    }

    nonisolated static func normalized(_ gamePath: String) -> String {
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
        if document.isEditedCopy, name.hasSuffix(EffectDocument.editSuffix) { name.removeLast(EffectDocument.editSuffix.count) }
        let file = name + "." + document.url.pathExtension
        for slot in document.textureSlots {
            let parts = slot.path.lowercased().split(separator: "/").map(String.init)
            if let at = parts.lastIndex(of: "texture"), at >= 1 { return (parts[..<at] + ["eff", file]).joined(separator: "/") }
        }
        return "vfx/" + file
    }

    static func archive(_ mod: ModDescription, files: [(gamePath: String, data: [UInt8], option: Int)], group: ModGroup? = nil) -> [UInt8] {
        var entries: [(path: String, data: [UInt8])] = []
        func text(_ value: String) -> JSONNode { JSONNode(.string(value)) }
        func redirects(_ option: Int, folder: String) -> [JSONMember] {
            var list: [JSONMember] = []
            for file in files where file.option == option {
                let path = normalized(file.gamePath)
                let stored = folder.isEmpty ? path : folder + "/" + path
                list.append(JSONMember(key: path, node: text(stored.replacingOccurrences(of: "/", with: "\\"))))
                entries.append((stored, file.data))
            }
            return [
                JSONMember(key: "Files", node: JSONNode(.object(list))),
                JSONMember(key: "FileSwaps", node: JSONNode(.object([]))),
                JSONMember(key: "Manipulations", node: JSONNode(.array([]))),
            ]
        }
        func id() -> JSONNode { text(UUID().uuidString.lowercased()) }
        var groups: [JSONNode] = []
        if let group {
            let options = group.options.enumerated().map { index, name in
                JSONNode(.object([
                    JSONMember(key: "Name", node: text(name)),
                    JSONMember(key: "Description", node: text("")),
                    JSONMember(key: "Priority", node: JSONNode(.number(0))),
                    JSONMember(key: "Id", node: id()),
                    JSONMember(key: "Layout", node: JSONNode(.array([]))),
                ] + redirects(index + 1, folder: "\(PenumbraExport.folderName(group.name))/\(PenumbraExport.folderName(name))".lowercased())))
            }
            groups.append(JSONNode(.object([
                JSONMember(key: "Name", node: text(group.name)),
                JSONMember(key: "Description", node: text("")),
                JSONMember(key: "Priority", node: JSONNode(.number(0))),
                JSONMember(key: "Id", node: id()),
                JSONMember(key: "Type", node: text(group.multi ? "Multi" : "Single")),
                JSONMember(key: "DefaultSettings", node: JSONNode(.number(group.multi ? 1 : 0))),
                JSONMember(key: "Layout", node: JSONNode(.array([]))),
                JSONMember(key: "Options", node: JSONNode(.array(options))),
                JSONMember(key: "Containers", node: JSONNode(.array([]))),
            ])))
        }
        let meta = JSONNode(.object([
            JSONMember(key: "FileVersion", node: JSONNode(.number(4))),
            JSONMember(key: "Identifier", node: id()),
            JSONMember(key: "LastWrite", node: text(ISO8601DateFormatter().string(from: Date()))),
            JSONMember(key: "Name", node: text(mod.name)),
            JSONMember(key: "Author", node: text(mod.author)),
            JSONMember(key: "Description", node: text(mod.description)),
            JSONMember(key: "Version", node: text(mod.version)),
            JSONMember(key: "Website", node: text(mod.website)),
            JSONMember(key: "ModTags", node: JSONNode(.array([]))),
            JSONMember(key: "DefaultData", node: JSONNode(.object(redirects(0, folder: "")))),
            JSONMember(key: "Groups", node: JSONNode(.array(groups))),
        ]))
        entries.insert(("meta.json", Array(meta.serialized().utf8)), at: 0)
        return ZipWriter.archive(entries)
    }
}
