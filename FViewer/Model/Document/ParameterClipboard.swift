import Foundation
import QuartzCore

enum ParameterClipboard {
    static var kind = ""
    static var fields: [String: FieldValue] = [:]
    static var curves: [String: [CurveKeyPoint]] = [:]
    static var setFields: Set<String> = []
    static var unsetFields: Set<String> = []
    static var setCurves: Set<String> = []
    static var unsetCurves: Set<String> = []

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
        setFields = Set(document.sections(for: node).flatMap(\.fields).map(\.label))
        unsetFields = Set(document.missingFields(for: node).map(\.title))
        setCurves = Set(document.curveGroups(for: node).map(\.title))
        unsetCurves = Set(document.missingCurves(for: node).map(\.title))
    }

    private static func current(_ node: OutlineNode, in document: EffectDocument) -> OutlineNode { document.node(node.id) ?? node }

    private static func matchAssignment(_ node: OutlineNode, in document: EffectDocument) -> Bool {
        var changed = false
        func plain(_ label: String) -> String { label.hasSuffix(" Index") ? String(label.dropLast(6)) : label }
        let wanted = Set(setFields.map(plain))
        for item in document.missingFields(for: current(node, in: document)) where wanted.contains(plain(item.title)) {
            item.create()
            changed = true
        }
        for item in document.missingCurves(for: current(node, in: document)) where setCurves.contains(item.title) {
            item.create()
            changed = true
        }
        var guardCount = 0
        while guardCount < 256, let field = document.sections(for: current(node, in: document)).flatMap(\.fields)
            .first(where: { unsetFields.contains($0.label) && $0.unassign != nil }), let unassign = field.unassign {
            unassign()
            changed = true
            guardCount += 1
        }
        while guardCount < 512, let group = document.curveGroups(for: current(node, in: document))
            .first(where: { unsetCurves.contains($0.title) && $0.remove != nil }), let remove = group.remove {
            remove()
            changed = true
            guardCount += 1
        }
        return changed
    }

    static func paste(into target: OutlineNode, in document: EffectDocument) {
        guard !fields.isEmpty || !curves.isEmpty else { return }
        guard kind == kind(of: target) else {
            AppDelegate.model?.notice = "The copied parameters belong to a different kind of node"
            return
        }
        document.batch("Paste Parameters") {
            _ = matchAssignment(target, in: document)
            let node = current(target, in: document)
            for field in document.sections(for: node).flatMap(\.fields) {
                guard let write = field.write, let value = fields[relative(field.id, node)], value != field.read() else { continue }
                if case .choice(let choices) = field.kind, case .int(let raw) = value, !choices.contains(where: { $0.value == raw }) { continue }
                write(value)
            }
            for group in document.curveGroups(for: node) {
                for channel in group.channels {
                    guard let keys = curves[relative(channel.id, node)], keys != channel.read() else { continue }
                    channel.write(keys)
                }
            }
        }
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

    private static var presetCache: (at: Double, prefix: String, value: [(name: String, url: URL)])?

    static func presets(for node: OutlineNode) -> [(name: String, url: URL)] {
        guard let folder = presetFolder else { return [] }
        let prefix = presetKind(node) + "~"
        if let cached = presetCache, cached.prefix == prefix, CACurrentMediaTime() - cached.at < 1.5 { return cached.value }
        let fresh = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "json" && $0.lastPathComponent.hasPrefix(prefix) }
            .map { (String($0.deletingPathExtension().lastPathComponent.dropFirst(prefix.count)), $0) }.sorted { $0.0 < $1.0 }
        presetCache = (CACurrentMediaTime(), prefix, fresh)
        return fresh
    }

    @discardableResult static func savePreset(_ name: String, from node: OutlineNode, in document: EffectDocument) -> URL? {
        guard let folder = presetFolder else { return nil }
        let clean = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { return nil }
        let keep = (kind, fields, curves)
        let keepAssigned = (setFields, unsetFields, setCurves, unsetCurves)
        copy(node, in: document)
        (setFields, unsetFields, setCurves, unsetCurves) = keepAssigned
        var fieldMap: [String: Any] = [:]
        for (key, value) in fields { fieldMap[key] = encode(value) }
        var curveMap: [String: Any] = [:]
        for (key, keys) in curves { curveMap[key] = keys.map { [$0.time, $0.value, Double($0.interpolation), $0.tangentOut, $0.tangentIn] } }
        (kind, fields, curves) = keep
        let url = folder.appendingPathComponent(presetKind(node) + "~" + clean + ".json")
        guard let data = try? JSONSerialization.data(withJSONObject: ["fields": fieldMap, "curves": curveMap], options: [.prettyPrinted, .sortedKeys]) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            presetCache = nil
        } catch {
            AppDelegate.model?.errorMessage = "Preset \(clean): \(error.localizedDescription)"
            return nil
        }
        return url
    }

    @discardableResult static func applyPreset(_ url: URL, to node: OutlineNode, in document: EffectDocument) -> Bool {
        guard let data = try? Data(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
        let keep = (kind, fields, curves)
        let keepAssigned = (setFields, unsetFields, setCurves, unsetCurves)
        (setFields, unsetFields, setCurves, unsetCurves) = ([], [], [], [])
        defer { (setFields, unsetFields, setCurves, unsetCurves) = keepAssigned }
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
