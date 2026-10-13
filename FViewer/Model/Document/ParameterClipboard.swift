import Foundation

enum ParameterClipboard {
    static var kind = ""
    static var fields: [String: FieldValue] = [:]
    static var curves: [String: [CurveKeyPoint]] = [:]

    private static func relative(_ id: String, _ node: OutlineNode) -> String {
        id.hasPrefix(node.id) ? String(id.dropFirst(node.id.count)) : id
    }

    static func kind(of node: OutlineNode) -> String {
        node.id.split(separator: "/").map { Int($0) == nil ? String($0) : "#" }.joined(separator: "/")
    }

    static func copy(_ node: OutlineNode, in document: EffectDocument) {
        kind = kind(of: node)
        fields = [:]
        curves = [:]
        for field in document.sections(for: node).flatMap(\.fields) where field.write != nil { fields[relative(field.id, node)] = field.read() }
        for group in document.curveGroups(for: node) {
            for channel in group.channels { curves[relative(channel.id, node)] = channel.read() }
        }
    }

    static func paste(into node: OutlineNode, in document: EffectDocument) {
        guard !fields.isEmpty || !curves.isEmpty else { return }
        let before = document.snapshot()
        var changed = false
        for field in document.sections(for: node).flatMap(\.fields) {
            guard let write = field.write, let value = fields[relative(field.id, node)], value != field.read() else { continue }
            if case .choice(let choices) = field.kind, case .int(let raw) = value, !choices.contains(where: { $0.value == raw }) { continue }
            write(value)
            changed = true
        }
        for group in document.curveGroups(for: node) {
            for channel in group.channels {
                guard let keys = curves[relative(channel.id, node)], keys != channel.read() else { continue }
                channel.write(keys)
                changed = true
            }
        }
        if changed { document.registerUndo("Paste Parameters", since: before) }
    }

    private static func encode(_ value: FieldValue) -> [String: Any] {
        switch value {
        case .int(let v): return ["t": "i", "v": v]
        case .double(let v): return ["t": "d", "v": v]
        case .bool(let v): return ["t": "b", "v": v]
        case .text(let v): return ["t": "s", "v": v]
        case .color(let r, let g, let b, let a): return ["t": "c", "v": [r, g, b, a]]
        }
    }

    private static func decode(_ entry: [String: Any]) -> FieldValue? {
        switch entry["t"] as? String {
        case "i": return (entry["v"] as? Int).map { .int($0) }
        case "d": return (entry["v"] as? Double).map { .double($0) }
        case "b": return (entry["v"] as? Bool).map { .bool($0) }
        case "s": return (entry["v"] as? String).map { .text($0) }
        case "c":
            guard let v = entry["v"] as? [Double], v.count == 4 else { return nil }
            return .color(v[0], v[1], v[2], v[3])
        default: return nil
        }
    }

    static var presetFolder: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/Presets", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func presetKind(_ node: OutlineNode) -> String {
        kind(of: node).replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "#", with: "n")
    }

    static func presets(for node: OutlineNode) -> [(name: String, url: URL)] {
        guard let folder = presetFolder else { return [] }
        let prefix = presetKind(node) + "~"
        return ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix(prefix) }
            .map { (String($0.deletingPathExtension().lastPathComponent.dropFirst(prefix.count)), $0) }.sorted { $0.0 < $1.0 }
    }

    @discardableResult static func savePreset(_ name: String, from node: OutlineNode, in document: EffectDocument) -> URL? {
        guard let folder = presetFolder else { return nil }
        let clean = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }
        let keep = (kind, fields, curves)
        copy(node, in: document)
        var fieldMap: [String: Any] = [:]
        for (key, value) in fields { fieldMap[key] = encode(value) }
        var curveMap: [String: Any] = [:]
        for (key, keys) in curves { curveMap[key] = keys.map { [$0.time, $0.value, Double($0.interpolation), $0.tangentOut, $0.tangentIn] } }
        (kind, fields, curves) = keep
        let url = folder.appendingPathComponent(presetKind(node) + "~" + clean + ".json")
        guard let data = try? JSONSerialization.data(withJSONObject: ["fields": fieldMap, "curves": curveMap], options: [.prettyPrinted, .sortedKeys]) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }

    @discardableResult static func applyPreset(_ url: URL, to node: OutlineNode, in document: EffectDocument) -> Bool {
        guard let data = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        let keep = (kind, fields, curves)
        fields = [:]
        curves = [:]
        for (key, entry) in json["fields"] as? [String: [String: Any]] ?? [:] { if let value = decode(entry) { fields[key] = value } }
        for (key, list) in json["curves"] as? [String: [[Double]]] ?? [:] {
            curves[key] = list.filter { $0.count == 5 }.map { CurveKeyPoint(time: $0[0], value: $0[1], interpolation: Int($0[2]), tangentOut: $0[3], tangentIn: $0[4]) }
        }
        let before = document.serializedData()
        paste(into: node, in: document)
        (kind, fields, curves) = keep
        return document.serializedData() != before
    }
}
