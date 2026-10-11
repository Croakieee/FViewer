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
}
