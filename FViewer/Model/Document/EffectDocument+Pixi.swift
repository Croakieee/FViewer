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
        if let time = node["time"]?.number { return ("frame " + JSONNode.format(time), node["value"]?.string ?? "") }
        return ("\(index)", "")
    }

    static let animatable: Set<String> = ["alpha", "scale", "rotation", "rotationX", "rotationY", "x", "y", "z", "brightness", "power", "count",
                                          "inner", "outer", "width", "length", "angle"]

    static func hexColor(_ text: String) -> (Double, Double, Double)? {
        guard text.count == 7, text.hasPrefix("#"), let value = Int(text.dropFirst(), radix: 16) else { return nil }
        return (Double((value >> 16) & 255) / 255, Double((value >> 8) & 255) / 255, Double(value & 255) / 255)
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
                group.actions = [NodeAction(id: childID + "!add", title: "Add", symbol: "plus") { [weak self] in
                    self?.appendElement(to: child, key: member.key, groupID: childID)
                }]
                for (i, element) in elements.enumerated() where !element.isScalar {
                    let (title, detail) = EffectDocument.elementTitle(element, i)
                    let item = OutlineNode(id: "\(childID)/\(i)", title: title, detail: detail, symbol: symbol, tint: childTint, payload: .json(element))
                    item.actions = jsonArrayActions(item, array: child, index: i)
                    if id == "json" {
                        switch member.key {
                        case "timelines": item.visibility = .timeline(i)
                        case "emitters": item.visibility = .emitter(i)
                        case "particles": item.visibility = .particle(i)
                        default: break
                        }
                    }
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

    func appendElement(to array: JSONNode, key: String, groupID: String) {
        guard var items = array.elements else { return }
        let fresh: JSONNode
        if let last = items.last(where: { !$0.isScalar }) {
            fresh = last.deepCopy()
            if let id = fresh["id"]?.string {
                var candidate = id + "_new"
                let taken = Set(items.compactMap { $0["id"]?.string })
                var counter = 2
                while taken.contains(candidate) {
                    candidate = id + "_new\(counter)"
                    counter += 1
                }
                fresh["id"]?.value = .string(candidate)
            }
        } else {
            let firstParticle = jsonRoot?["particles"]?.elements?.first?["id"]?.string ?? ""
            let firstEmitter = jsonRoot?["emitters"]?.elements?.first?["id"]?.string ?? ""
            let firstTexture = textureSlots.first?.name ?? ""
            switch key {
            case "layers": fresh = JSONNode(.object([JSONMember(key: "texture", node: JSONNode(.string(firstTexture)))]))
            case "items" where groupID.contains("/timelines/"):
                fresh = JSONNode(.object([JSONMember(key: "emitter", node: JSONNode(.string(firstEmitter))), JSONMember(key: "start", node: JSONNode(.number(0)))]))
            case "items": fresh = JSONNode(.object([JSONMember(key: "particle", node: JSONNode(.string(firstParticle)))]))
            default: fresh = JSONNode(.object([JSONMember(key: "id", node: JSONNode(.string("new")))]))
            }
        }
        performStructural("Add") {
            items.append(fresh)
            array.value = .array(items)
        }
        selectionID = "\(groupID)/\(items.count - 1)"
    }

    func pixiSections(_ node: OutlineNode, _ json: JSONNode) -> [PropSection] {
        var sections: [PropSection] = []
        let own = pixiFields(json, id: node.id)
        if !own.isEmpty { sections.append(PropSection(id: node.id + "/main", title: node.title, fields: own)) }
        func nested(_ object: JSONNode, id: String, title: String, depth: Int) {
            for member in object.members ?? [] where member.node.members != nil && member.node["keys"] == nil && depth < 4 {
                let childID = "\(id)/\(member.key)"
                let childTitle = title.isEmpty ? member.key : title + " › " + member.key
                let fields = pixiFields(member.node, id: childID)
                if !fields.isEmpty { sections.append(PropSection(id: childID + "/nested", title: childTitle, fields: fields)) }
                nested(member.node, id: childID, title: childTitle, depth: depth + 1)
            }
        }
        nested(json, id: node.id, title: "", depth: 0)
        return sections
    }

    private func pixiFields(_ json: JSONNode, id nodeID: String) -> [PropField] {
        var fields: [PropField] = []
        for member in json.members ?? [] {
            let value = member.node
            let id = "\(nodeID)#\(member.key)"
            switch value.value {
            case .number:
                var field = PropField(id: id, label: member.key, tag: member.key, kind: .double, read: { .double(value.number ?? 0) },
                                      write: { value.value = .number($0.number) })
                if EffectDocument.animatable.contains(member.key) {
                    field.animate = { [weak self] in
                        self?.performStructural("Animate " + member.key) {
                            let v = value.number ?? 0
                            value.value = .array([0, 30].map { time in
                                JSONNode(.object([JSONMember(key: "time", node: JSONNode(.number(Double(time)))),
                                                  JSONMember(key: "value", node: JSONNode(.number(v)))]))
                            })
                        }
                        self?.activeCurveID = "\(nodeID)~\(member.key)"
                    }
                }
                fields.append(field)
            case .bool:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .bool, read: { .bool(value.bool ?? false) },
                                        write: { if case .bool(let v) = $0 { value.value = .bool(v) } }))
            case .string where EffectDocument.hexColor(value.string ?? "") != nil:
                fields.append(PropField(id: id, label: member.key, tag: member.key, kind: .color(alpha: false),
                                        read: {
                                            let c = EffectDocument.hexColor(value.string ?? "") ?? (1, 1, 1)
                                            return .color(c.0, c.1, c.2, 1)
                                        },
                                        write: {
                                            guard case .color(let r, let g, let b, _) = $0 else { return }
                                            value.value = .string(String(format: "#%02x%02x%02x", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded())))
                                        }))
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
        return fields
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
                },
                extrapolation: {
                    switch member.node["after"]?.string {
                    case "repeat": return (0, 1)
                    case "add": return (0, 2)
                    default: return (0, 0)
                    }
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

    func pixiData(filter: VisibilityFilter) -> Data {
        guard let root = jsonRoot else { return Data() }
        if filter.isEmpty { return Data(root.serialized().utf8) }
        let copy = root.deepCopy()
        let emitters = copy["emitters"]?.elements ?? []
        let particles = copy["particles"]?.elements ?? []
        let timelines = copy["timelines"]?.elements ?? []
        func emitterID(_ i: Int) -> String? { i < emitters.count ? emitters[i]["id"]?.string : nil }
        func particleID(_ i: Int) -> String? { i < particles.count ? particles[i]["id"]?.string : nil }
        var hiddenEmitters: Set<String> = []
        var hiddenParticles: Set<String> = []
        var hiddenTimelines: Set<Int> = []
        for key in filter.hidden {
            switch key {
            case .emitter(let i): if let id = emitterID(i) { hiddenEmitters.insert(id) }
            case .particle(let i): if let id = particleID(i) { hiddenParticles.insert(id) }
            case .timeline(let i): hiddenTimelines.insert(i)
            }
        }
        var onlyParticle: String?
        var particleSources: Set<String>?
        switch filter.isolated {
        case .particle(let i): onlyParticle = particleID(i)
        case .emitter(let i):
            var reach: Set<String> = []
            var queue = [emitterID(i)].compactMap { $0 }
            while let id = queue.popLast() {
                if !reach.insert(id).inserted { continue }
                guard let emitter = emitters.first(where: { $0["id"]?.string == id }) else { continue }
                queue.append(contentsOf: (emitter["items"]?.elements ?? []).compactMap { $0["emitter"]?.string })
            }
            particleSources = reach
        case .timeline(let i):
            for index in timelines.indices where index != i { hiddenTimelines.insert(index) }
        case nil: break
        }
        for (i, timeline) in timelines.enumerated() {
            guard let items = timeline["items"] else { continue }
            if hiddenTimelines.contains(i) {
                items.value = .array([])
            } else {
                items.value = .array((items.elements ?? []).filter { item in
                    guard let target = item["emitter"]?.string else { return true }
                    return !hiddenEmitters.contains(target)
                })
            }
        }
        for emitter in emitters {
            guard let items = emitter["items"] else { continue }
            let owner = emitter["id"]?.string ?? ""
            items.value = .array((items.elements ?? []).filter { item in
                if let target = item["emitter"]?.string { return !hiddenEmitters.contains(target) }
                guard let target = item["particle"]?.string else { return true }
                if hiddenParticles.contains(target) { return false }
                if let onlyParticle, target != onlyParticle { return false }
                if let particleSources, !particleSources.contains(owner) { return false }
                return true
            })
        }
        return Data(copy.serialized().utf8)
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
                    var row = SequencerRow(id: nodeID, label: emitter, start: start, end: end, openEnded: explicitEnd == nil && life < 0,
                                           tint: .emitter, depth: 1, nodeID: nodeID)
                    row.base = base
                    row.densityKey = emitter
                    if let startNode = item["start"] {
                        row.startField = PropField(id: nodeID + "#start", label: "start", tag: "start", kind: .double, read: { .double(startNode.number ?? 0) },
                                                   write: { startNode.value = .number($0.number) })
                    }
                    if let endNode = item["end"] {
                        row.endField = PropField(id: nodeID + "#end", label: "end", tag: "end", kind: .double, read: { .double(endNode.number ?? 0) },
                                                 write: { endNode.value = .number($0.number) })
                    }
                    children.append(row)
                } else if let clip = item["clip"]?.string {
                    children.append(SequencerRow(id: nodeID, label: "clip " + clip, start: start, end: start + max(1, item["fade"]?.number ?? 1),
                                                 openEnded: false, tint: .item, depth: 1, nodeID: nodeID))
                }
            }
            let trigger = timeline["trigger"]?.number
            let label = "Timeline \(t)" + (trigger.map { " (trigger \(JSONNode.format($0)))" } ?? "")
            rows.append(SequencerRow(id: id, label: label, start: base, end: children.map(\.end).max() ?? base + 30, openEnded: false,
                                     tint: .timeline, depth: 0, nodeID: id))
            rows.append(contentsOf: children)
        }
        return rows
    }

    var effectParams: [(name: String, value: Double)] {
        (jsonRoot?["params"]?.members ?? []).compactMap { member in
            if let number = member.node.number { return (member.key, number) }
            if let number = member.node["default"]?.number ?? member.node["value"]?.number { return (member.key, number) }
            return nil
        }
    }

    func jsonText(of node: OutlineNode) -> String? {
        guard case .json(let json) = node.payload else { return nil }
        return json.serialized()
    }

    func applyJSON(_ text: String, to node: OutlineNode) throws {
        guard case .json(let json) = node.payload else { return }
        let parsed = try JSONParser.parse(Data(text.utf8))
        performStructural("Edit JSON") { json.value = parsed.value }
    }

    static let shapeTemplates: [(name: String, symbol: String, json: String)] = [
        ("Quad", "square", "{ \"type\": \"quad\" }"),
        ("Ring", "circle", "{ \"type\": \"ring\", \"innerRadius\": 0.6, \"outerRadius\": 1, \"segments\": 48 }"),
        ("Disc", "circle.fill", "{ \"type\": \"ring\", \"innerRadius\": 0, \"outerRadius\": 1, \"segments\": 48 }"),
        ("Rounded Rectangle", "rectangle.roundedtop", "{ \"type\": \"roundRect\", \"width\": 2, \"height\": 1, \"thickness\": 0.2, \"radius\": 0.2 }"),
        ("Windmill", "fanblades", "{ \"type\": \"windmill\" }"),
        ("Decal", "square.dashed", "{ \"type\": \"decal\" }"),
        ("Trail", "scribble", "{ \"type\": \"trail\", \"frames\": 20, \"points\": 16, \"center\": 0.5, \"width\": 0.2 }"),
    ]

    @discardableResult func addShapeParticle(_ template: Int) -> String? {
        guard let root = jsonRoot, template >= 0, template < EffectDocument.shapeTemplates.count, let particles = root["particles"],
              var items = particles.elements, let shape = try? JSONParser.parse(Data(EffectDocument.shapeTemplates[template].json.utf8)) else { return nil }
        let base = EffectDocument.shapeTemplates[template].name.lowercased().replacingOccurrences(of: " ", with: "_")
        let taken = Set(items.compactMap { $0["id"]?.string })
        var id = base
        var counter = 2
        while taken.contains(id) {
            id = "\(base)_\(counter)"
            counter += 1
        }
        let particle = JSONNode(.object([
            JSONMember(key: "id", node: JSONNode(.string(id))), JSONMember(key: "texture", node: JSONNode(.string(textureSlots.first?.name ?? "white"))),
            JSONMember(key: "life", node: JSONNode(.number(30))), JSONMember(key: "shape", node: shape),
        ]))
        items.append(particle)
        performStructural("Add \(EffectDocument.shapeTemplates[template].name)") { particles.value = .array(items) }
        selectionID = "json/particles/\(items.count - 1)"
        return id
    }
}
