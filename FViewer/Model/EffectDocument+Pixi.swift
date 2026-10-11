import SwiftUI

extension EffectDocument {
    private static func keyArray(_ node: JSONNode) -> JSONNode? {
        if let elements = node.elements {
            guard !elements.isEmpty, elements.allSatisfy({ $0["time"]?.number != nil && $0["value"]?.number != nil }) else { return nil }
            return node
        }
        if let keys = node["keys"], keys.elements != nil { return keyArray(keys) ?? (keys.elements?.isEmpty == true ? keys : nil) }
        return nil
    }

    private static func isScalarArray(_ node: JSONNode) -> Bool {
        guard let elements = node.elements else { return false }
        return elements.allSatisfy(\.isScalar)
    }

    private static func tint(forKey key: String, inherited: NodeTint) -> (NodeTint, String) {
        switch key {
        case "timelines": return (.timeline, "film")
        case "emitters": return (.emitter, "dot.radiowaves.left.and.right")
        case "particles": return (.particle, "circle.hexagongrid")
        case "items": return (.item, "arrow.turn.down.right")
        case "layers", "distortion", "uv": return (.texture, "photo.on.rectangle")
        case "shape": return (.model, "cube")
        case "params": return (.data, "slider.horizontal.3")
        default: return (inherited == .effect ? .data : inherited, "square.stack.3d.up")
        }
    }

    private static func elementTitle(_ node: JSONNode, _ index: Int) -> (String, String) {
        if let id = node["id"]?.string { return (id, "") }
        if let emitter = node["emitter"]?.string { return (emitter, "emitter") }
        if let particle = node["particle"]?.string { return (particle, "particle") }
        if let clip = node["clip"]?.string { return ("clip " + clip, "") }
        if let texture = node["texture"]?.string { return (texture, "") }
        if let time = node["time"]?.number { return ("кадр " + JSONNode.format(time), node["value"]?.string ?? "") }
        return ("\(index)", "")
    }

    func buildPixiOutline(_ root: JSONNode) -> [OutlineNode] {
        let effect = OutlineNode(id: "json", title: title, symbol: "sparkles", tint: .effect, payload: .json(root))
        return [effect] + pixiChildNodes(root, id: "json", tint: .effect)
    }

    private func pixiChildNodes(_ node: JSONNode, id: String, tint: NodeTint) -> [OutlineNode] {
        var result: [OutlineNode] = []
        for member in node.members ?? [] {
            let child = member.node
            if child.isScalar || EffectDocument.keyArray(child) != nil || EffectDocument.isScalarArray(child) { continue }
            let (childTint, symbol) = EffectDocument.tint(forKey: member.key, inherited: tint)
            let childID = "\(id)/\(member.key)"
            if let elements = child.elements {
                let group = OutlineNode(id: childID, title: member.key, detail: "\(elements.count)", symbol: "folder", tint: childTint, payload: .group)
                for (i, element) in elements.enumerated() where !element.isScalar {
                    let (title, detail) = EffectDocument.elementTitle(element, i)
                    let item = OutlineNode(id: "\(childID)/\(i)", title: title, detail: detail, symbol: symbol, tint: childTint, payload: .json(element))
                    item.children = pixiChildNodes(element, id: item.id, tint: childTint)
                    group.children.append(item)
                }
                result.append(group)
            } else {
                let item = OutlineNode(id: childID, title: member.key, symbol: symbol, tint: childTint, payload: .json(child))
                item.children = pixiChildNodes(child, id: childID, tint: childTint)
                result.append(item)
            }
        }
        return result
    }

    func pixiSections(_ node: OutlineNode, _ json: JSONNode) -> [PropSection] {
        var fields: [PropField] = []
        for member in json.members ?? [] {
            let value = member.node
            let id = "\(node.id)#\(member.key)"
            switch value.value {
            case .number:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .double, read: { .double(value.number ?? 0) },
                                        write: { value.value = .number($0.number) }))
            case .bool:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .bool, read: { .bool(value.bool ?? false) },
                                        write: { if case .bool(let v) = $0 { value.value = .bool(v) } }))
            case .string:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .text, read: { .text(value.string ?? "") },
                                        write: { if case .text(let v) = $0 { value.value = .string(v) } }))
            case .array where EffectDocument.isScalarArray(value) && EffectDocument.keyArray(value) == nil:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .text,
                                        read: { .text(value.serialized().trimmingCharacters(in: .whitespacesAndNewlines)) },
                                        write: {
                                            guard case .text(let v) = $0, let parsed = try? JSONParser.parse(Data(v.utf8)), parsed.elements != nil else { return }
                                            value.value = parsed.value
                                        }))
            default: break
            }
        }
        return fields.isEmpty ? [] : [PropSection(id: node.id + "/main", title: node.title, fields: fields)]
    }

    func pixiCurveGroups(_ node: OutlineNode, _ json: JSONNode) -> [CurveGroup] {
        var groups: [CurveGroup] = []
        for (i, member) in (json.members ?? []).enumerated() {
            guard let keys = EffectDocument.keyArray(member.node) else { continue }
            let id = "\(node.id)~\(member.key)"
            let channel = CurveChannel(
                id: id + "/v", name: member.key, color: EffectDocument.channelColors[i % EffectDocument.channelColors.count],
                read: {
                    (keys.elements ?? []).map { key in
                        let spline = key["spline"]
                        return CurveKeyPoint(time: key["time"]?.number ?? 0, value: key["value"]?.number ?? 0,
                                             interpolation: spline == nil ? CurveKeyPoint.linear : CurveKeyPoint.spline,
                                             tangentOut: spline?["out"]?.number ?? 1, tangentIn: spline?["in"]?.number ?? 1)
                    }
                },
                write: { points in
                    keys.value = .array(points.sorted { $0.time < $1.time }.map { point in
                        var members = [JSONMember(key: "time", node: JSONNode(.number(point.time.rounded()))),
                                       JSONMember(key: "value", node: JSONNode(.number((point.value * 10000).rounded() / 10000)))]
                        if point.interpolation == CurveKeyPoint.spline {
                            members.append(JSONMember(key: "spline", node: JSONNode(.object([
                                JSONMember(key: "in", node: JSONNode(.number(point.tangentIn))),
                                JSONMember(key: "out", node: JSONNode(.number(point.tangentOut))),
                            ]))))
                        }
                        return JSONNode(.object(members))
                    })
                },
                snapshot: {
                    let saved = keys.deepCopy().value
                    return { keys.value = saved }
                })
            var settings: [PropField] = []
            if let after = member.node["after"] {
                settings.append(PropField(id: id + "#after", label: "after", tag: "after", kind: .text, read: { .text(after.string ?? "hold") },
                                          write: { if case .text(let v) = $0 { after.value = .string(v) } }))
            }
            groups.append(CurveGroup(id: id, title: member.key, tag: member.key, isAngle: false, channels: [channel], settings: settings))
        }
        return groups
    }

    func pixiSequencerRows(_ root: JSONNode) -> [SequencerRow] {
        var lives: [String: Double] = [:]
        for emitter in root["emitters"]?.elements ?? [] {
            if let id = emitter["id"]?.string { lives[id] = emitter["life"]?.number ?? -1 }
        }
        var rows: [SequencerRow] = []
        for (t, timeline) in (root["timelines"]?.elements ?? []).enumerated() {
            let base = timeline["start"]?.number ?? 0
            let id = "json/timelines/\(t)"
            var children: [SequencerRow] = []
            for (i, item) in (timeline["items"]?.elements ?? []).enumerated() {
                let start = base + (item["start"]?.number ?? 0)
                let nodeID = "\(id)/items/\(i)"
                if let emitter = item["emitter"]?.string {
                    let life = lives[emitter] ?? -1
                    let explicitEnd = item["end"]?.number
                    let end = explicitEnd.map { base + $0 } ?? start + (life > 0 ? life : 30)
                    children.append(SequencerRow(id: nodeID, label: emitter, start: start, end: end, openEnded: explicitEnd == nil && life < 0,
                                                 tint: .emitter, depth: 1, nodeID: nodeID))
                } else if let clip = item["clip"]?.string {
                    children.append(SequencerRow(id: nodeID, label: "clip " + clip, start: start, end: start + max(1, item["fade"]?.number ?? 1),
                                                 openEnded: false, tint: .item, depth: 1, nodeID: nodeID))
                }
            }
            let trigger = timeline["trigger"]?.number
            let label = "Timeline \(t)" + (trigger.map { " (триггер \(JSONNode.format($0)))" } ?? "")
            rows.append(SequencerRow(id: id, label: label, start: base, end: children.map(\.end).max() ?? base + 30, openEnded: false,
                                     tint: .timeline, depth: 0, nodeID: id))
            rows.append(contentsOf: children)
        }
        return rows
    }
}
