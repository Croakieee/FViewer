import SwiftUI

extension Theme {
    static let changed = Color(red: 1.0, green: 0.72, blue: 0.28)
}

struct ChangeDot: View {
    var added = false

    var body: some View {
        Circle().fill(Theme.changed).frame(width: 5, height: 5)
            .help(added ? "Added since the file was opened" : "Changed since the file was opened")
    }
}

extension AvfxBlock {
    func matches(_ other: AvfxBlock) -> Bool {
        guard rawTag == other.rawTag else { return false }
        switch (children, other.children) {
        case (nil, nil): return data == other.data
        case (let a?, let b?):
            guard a.count == b.count else { return false }
            for i in a.indices where !a[i].matches(b[i]) { return false }
            return true
        default: return false
        }
    }
}

struct ChangeSet {
    var modified: Set<String> = []
    var added: Set<String> = []

    func contains(_ id: String) -> Bool { modified.contains(id) || added.contains(id) }
}

extension EffectDocument {
    func computeChanges() -> ChangeSet {
        guard let original else { return ChangeSet() }
        var result = ChangeSet()
        func same(_ a: OutlineNode, _ b: OutlineNode) -> Bool {
            switch (a.payload, b.payload) {
            case (.group, .group): return true
            case (.avfx(let x, _, let rx), .avfx(let y, _, let ry)):
                if let rx, let ry {
                    guard rx.count == ry.count else { return false }
                    for i in rx.indices where !rx[i].matches(ry[i]) { return false }
                    return true
                }
                if rx != nil || ry != nil { return false }
                return x.matches(y)
            case (.json(let x), .json(let y)): return x.serialized() == y.serialized()
            default: return false
            }
        }
        @discardableResult func visit(_ node: OutlineNode) -> Bool {
            guard let before = original.node(node.id) else {
                result.added.insert(node.id)
                node.children.forEach { visit($0) }
                return true
            }
            var isGroup = false
            if case .group = node.payload { isGroup = true }
            if !isGroup, same(node, before), node.children.count == before.children.count { return false }
            var any = false
            for child in node.children where visit(child) { any = true }
            if isGroup, !any, node.children.count == before.children.count { return false }
            result.modified.insert(node.id)
            return true
        }
        outline.forEach { visit($0) }
        return result
    }

    func originalValue(of field: PropField, in nodeID: String) -> FieldValue? {
        guard let original else { return nil }
        if originalFields[nodeID] == nil {
            var values: [String: FieldValue] = [:]
            if let node = original.node(nodeID) {
                for item in original.sections(for: node).flatMap(\.fields) { values[item.id] = item.read() }
            }
            originalFields[nodeID] = values
        }
        return originalFields[nodeID]?[field.id]
    }

    func isChanged(_ field: PropField, in nodeID: String) -> Bool {
        guard original != nil, field.write != nil, changes.contains(nodeID) else { return false }
        guard let before = originalValue(of: field, in: nodeID) else { return true }
        return before != field.read()
    }

    func originalKeys(group: String, channel: String, in nodeID: String) -> [CurveKeyPoint]? {
        guard let original, let node = original.node(nodeID) else { return nil }
        return original.curveGroups(for: node).first { $0.id == group }?.channels.first { $0.id == channel }?.read()
    }

    func describe(_ value: FieldValue) -> String {
        switch value {
        case .int(let v): return "\(v)"
        case .double(let v): return JSONNode.format((v * 10000).rounded() / 10000)
        case .bool(let v): return v ? "on" : "off"
        case .text(let v): return v
        case .color(let r, let g, let b, _): return String(format: "#%02X%02X%02X", Int(safe: (r * 255).rounded()), Int(safe: (g * 255).rounded()), Int(safe: (b * 255).rounded()))
        }
    }
}
