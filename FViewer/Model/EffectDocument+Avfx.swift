import SwiftUI

extension EffectDocument {
    private static let folders: [(tag: String, title: String, symbol: String, tint: NodeTint)] = [
        ("Schd", "Scheduler", "calendar", .scheduler),
        ("TmLn", "Timelines", "film", .timeline),
        ("Emit", "Emitters", "dot.radiowaves.left.and.right", .emitter),
        ("Ptcl", "Particles", "circle.hexagongrid", .particle),
        ("Efct", "Effectors", "lightbulb", .effector),
        ("Bind", "Binders", "link", .binder),
        ("Tex", "Textures", "photo", .texture),
        ("Modl", "Models", "cube", .model),
    ]

    private static let partTitles: [String: String] = [
        "TC1": "Texture Color 1", "TC2": "Texture Color 2", "TC3": "Texture Color 3", "TC4": "Texture Color 4",
        "TN": "Texture Normal", "TR": "Texture Reflection", "TD": "Texture Distortion", "TP": "Texture Palette",
        "Smpl": "Simple Animation", "PrpS": "Properties Start", "Prp1": "Properties 1", "Prp2": "Properties 2",
        "PrpG": "Properties Goal", "Data": "Data",
    ]

    private static let colorTitles: [String: String] = [
        "Col": "Color", "ColB": "Color Begin", "ColE": "Color End", "ColC": "Color Center", "CoEB": "Color Edge Begin",
        "CoEC": "Color Edge Center", "CoEE": "Color Edge End", "CEI": "Color Edge Inner", "CEO": "Color Edge Outer",
        "StrC": "Start Color", "MidC": "Mid Color", "EndC": "End Color",
    ]

    private static let colorChannels: [(tag: String, name: String)] = [
        ("A", "Alpha"), ("Bri", "Brightness"), ("SclR", "Scale R"), ("SclG", "Scale G"), ("SclB", "Scale B"), ("SclA", "Scale A"),
        ("RanR", "Random R"), ("RanG", "Random G"), ("RanB", "Random B"), ("RanA", "Random A"), ("RBri", "Random Bright"),
    ]

    private static let angleTags: Set<String> = ["Rot", "RotR", "IAX", "IAXR", "IAY", "IAYR", "IAZ", "IAZR", "Ang", "AngR", "FrRt"]

    private static let listTitles: [String: String] = [
        "Schd/Item": "Items", "Schd/Trgr": "Triggers", "TmLn/Item": "Items", "Emit/ItPr": "Create Particles",
        "Emit/ItEm": "Create Emitters",
    ]

    func buildAvfxOutline(_ root: AvfxBlock) -> [OutlineNode] {
        let effect = OutlineNode(id: "avfx", title: title, symbol: "sparkles", tint: .effect,
                                 payload: .avfx(block: root, cls: "AvfxMain", record: nil))
        var result = [effect]
        for folder in EffectDocument.folders {
            let blocks = root.childrenNamed(folder.tag)
            if blocks.isEmpty { continue }
            let group = OutlineNode(id: "avfx/\(folder.tag)", title: folder.title, detail: "\(blocks.count)",
                                    symbol: "folder", tint: folder.tint, payload: .group)
            for (i, block) in blocks.enumerated() {
                let cls = catalog.classOf(block, in: "AvfxMain", parentBlock: root)
                group.children.append(avfxNode(block, cls, id: "avfx/\(folder.tag)/\(i)", index: i, parentClass: "AvfxMain",
                                               symbol: folder.symbol, tint: folder.tint))
            }
            if blocks.count == 1 && folder.tag == "Schd" {
                result.append(group.children[0])
            } else {
                result.append(group)
            }
        }
        return result
    }

    private func enumText(_ enumName: String, _ value: Int) -> String {
        catalog.enumCaseName(enumName, value) ?? "\(value)"
    }

    private func avfxNode(_ block: AvfxBlock, _ cls: String?, id: String, index: Int, parentClass: String?, symbol: String,
                          tint: NodeTint) -> OutlineNode {
        var title = EffectDocument.partTitles[block.tag] ?? catalog.field(parentClass, block.tag)?.name ?? block.tag
        var detail = ""
        var symbol = symbol
        var tint = tint
        switch block.tag {
        case "Schd": title = "Scheduler"
        case "TmLn": title = "Timeline \(index)"
        case "Emit":
            title = "Emitter \(index)"
            detail = enumText("EmitterType", block.int("EVT"))
        case "Ptcl":
            title = "Particle \(index)"
            detail = enumText("ParticleType", block.int("PrVT"))
        case "Efct":
            title = "Effector \(index)"
            detail = enumText("EffectorType", block.int("EfVT"))
        case "Bind":
            title = "Binder \(index)"
            detail = enumText("BinderType", block.int("BnVr"))
        case "Tex":
            title = (block.stringValue as NSString).lastPathComponent
            detail = "\(index)"
        case "Modl":
            title = "Model \(index)"
            let vertices = (block.child("VDrw")?.data.count ?? 0) / 36
            let emit = (block.child("VEmt")?.data.count ?? 0) / 28
            detail = emit > 0 && vertices == 0 ? "\(emit) точек" : "\(vertices) вершин"
        case "UvSt":
            title = "UV Set \(index)"
            symbol = "square.grid.2x2"
            tint = .data
        case "Data":
            symbol = "slider.horizontal.3"
            tint = .data
            if let cls { detail = cls.replacingOccurrences(of: "Avfx", with: "").replacingOccurrences(of: "Data", with: " ") }
        case "Smpl":
            symbol = "sparkle"
            tint = .data
        case "TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP":
            symbol = "photo.on.rectangle"
            tint = .texture
            if block.int("bEna") == 0 { detail = "выкл." }
        case "Clip":
            title = "Clip \(index)"
            detail = clipTypeName(block)
            symbol = "scissors"
            tint = .item
        default:
            if block.tag.hasPrefix("Prp") {
                symbol = "scope"
                tint = .data
            }
        }
        let node = OutlineNode(id: id, title: title, detail: detail, symbol: symbol, tint: tint,
                               payload: .avfx(block: block, cls: cls, record: nil))
        node.children = avfxChildNodes(block, cls, id: id, tint: tint)
        return node
    }

    private func clipTypeName(_ block: AvfxBlock) -> String {
        guard block.data.count >= 4 else { return "" }
        return String(decoding: block.data.prefix(4).reversed(), as: UTF8.self).trimmingCharacters(in: .whitespaces)
    }

    private func avfxChildNodes(_ block: AvfxBlock, _ cls: String?, id: String, tint: NodeTint) -> [OutlineNode] {
        guard let children = block.children else { return [] }
        var result: [OutlineNode] = []
        var counters: [String: Int] = [:]
        let listTags = AvfxBlock.cumulativeTags[block.tag] ?? []
        for listTag in listTags {
            guard let last = children.last(where: { $0.tag == listTag && $0.children != nil }) else { continue }
            let itemClass = catalog.classOf(last, in: cls, parentBlock: block)
            var records = last.records()
            if let source = AvfxBlock.cumulativePrefixSource[listTag],
               let origin = children.last(where: { $0.tag == source && $0.children != nil }) {
                records = Array(records.dropFirst(origin.records().count))
            }
            if records.isEmpty { continue }
            let group = OutlineNode(id: "\(id)/\(listTag)", title: EffectDocument.listTitles["\(block.tag)/\(listTag)"] ?? listTag,
                                    detail: "\(records.count)", symbol: "list.bullet", tint: .item, payload: .group)
            for (i, record) in records.enumerated() {
                group.children.append(recordNode(record, list: last, cls: itemClass, id: "\(id)/\(listTag)/\(i)", index: i,
                                                 owner: block.tag, listTag: listTag))
            }
            result.append(group)
        }
        for child in children {
            if child.tag == "Clip" {
                let n = counters["Clip", default: 0]
                counters["Clip"] = n + 1
                result.append(avfxNode(child, "AvfxTimelineClip", id: "\(id)/Clip\(n)", index: n, parentClass: cls,
                                       symbol: "scissors", tint: .item))
                continue
            }
            guard child.children != nil, !listTags.contains(child.tag) else { continue }
            let childClass = catalog.classOf(child, in: cls, parentBlock: block)
            if let childClass, AvfxCatalog.curveClasses.contains(childClass) || childClass == "AvfxLife" { continue }
            let n = counters[child.tag, default: 0]
            counters[child.tag] = n + 1
            result.append(avfxNode(child, childClass, id: "\(id)/\(child.tag)\(n)", index: n, parentClass: cls,
                                   symbol: "square.stack.3d.up", tint: .data))
        }
        return result
    }

    private func recordInt(_ record: [AvfxBlock], _ tag: String, _ fallback: Int = -1) -> Int {
        record.first { $0.tag == tag }?.intValue ?? fallback
    }

    private func recordNode(_ record: [AvfxBlock], list: AvfxBlock, cls: String?, id: String, index: Int, owner: String,
                            listTag: String) -> OutlineNode {
        var title = "Item \(index)"
        var detail = ""
        var tint = NodeTint.item
        var symbol = "arrow.turn.down.right"
        switch (owner, listTag) {
        case ("Schd", _):
            title = "Timeline \(recordInt(record, "TlNo"))"
            detail = "кадр \(recordInt(record, "StTm", 0))"
            tint = .timeline
            if listTag == "Trgr" {
                title = "Trigger \(index) → " + title
                symbol = "bolt"
            }
        case ("TmLn", _):
            let emitter = recordInt(record, "EmNo")
            let clip = recordInt(record, "ClNo")
            if emitter >= 0 {
                title = "Emitter \(emitter)"
                tint = .emitter
            } else if clip >= 0 {
                title = "Clip \(clip)"
                symbol = "scissors"
            } else {
                title = "—"
            }
            detail = "\(recordInt(record, "StTm", 0))–\(recordInt(record, "EdTm", 0))"
        case ("Emit", "ItPr"):
            let target = recordInt(record, "TgtB")
            title = "Particle \(target)"
            tint = .particle
            if let particles = avfxRoot?.childrenNamed("Ptcl"), target >= 0, target < particles.count {
                detail = enumText("ParticleType", particles[target].int("PrVT"))
            }
        case ("Emit", "ItEm"):
            title = "Emitter \(recordInt(record, "TgtB"))"
            tint = .emitter
        default: break
        }
        if recordInt(record, "bEnb", recordInt(record, "bEna", 1)) == 0 { detail += detail.isEmpty ? "выкл." : " · выкл." }
        return OutlineNode(id: id, title: title, detail: detail, symbol: symbol, tint: tint,
                           payload: .avfx(block: list, cls: cls, record: record))
    }

    func avfxField(_ block: AvfxBlock, cls: String?, id: String) -> PropField? {
        if AvfxBlock.binaryLeafTags.contains(block.tag) || block.children != nil { return nil }
        if AvfxCatalog.countTags.contains(block.tag) { return nil }
        if cls == "AvfxParticle" && block.tag == "UvSN" { return nil }
        let def = catalog.field(cls, block.tag)
        let label = def?.name ?? block.tag
        let base = def?.baseType ?? (block.data.count == 4 ? "AvfxInt" : "")
        if AvfxCatalog.typeTags.contains(block.tag), let enumName = def?.enumName {
            return PropField(id: id, label: label, tag: block.tag, kind: .info,
                             read: { [catalog] in .text(catalog.enumCaseName(enumName, block.intValue) ?? "\(block.intValue)") }, write: nil)
        }
        switch base {
        case "AvfxBool":
            return PropField(id: id, label: label, tag: block.tag, kind: .bool, read: { .bool(block.intValue == 1) },
                             write: { if case .bool(let v) = $0 { block.intValue = v ? 1 : 0 } })
        case "AvfxEnum":
            let choices = (catalog.enums[def?.enumName ?? ""] ?? []).map { FieldChoice(name: $0.name, value: $0.value) }
            return PropField(id: id, label: label, tag: block.tag, kind: .choice(choices), read: { .int(block.intValue) },
                             write: { if case .int(let v) = $0 { block.intValue = v } })
        case "AvfxFloat":
            return PropField(id: id, label: label, tag: block.tag, kind: .double, read: { .double(Double(block.floatValue)) },
                             write: { block.floatValue = Float($0.number) })
        case "AvfxRadians":
            return PropField(id: id, label: label, tag: block.tag, kind: .angle,
                             read: { .double(Double(block.floatValue) * 180 / .pi) },
                             write: { block.floatValue = Float($0.number * .pi / 180) })
        case "AvfxInt", "AvfxFlag":
            return PropField(id: id, label: label, tag: block.tag, kind: .int, read: { .int(block.intValue) },
                             write: { block.intValue = Int($0.number.rounded()) })
        case "AvfxString":
            return PropField(id: id, label: label, tag: block.tag, kind: .text, read: { .text(block.stringValue) },
                             write: { if case .text(let v) = $0 { block.stringValue = v } })
        case "AvfxIntList":
            return PropField(id: id, label: label, tag: block.tag, kind: .text,
                             read: { .text(block.data.map { $0 == 255 ? "-1" : String($0) }.joined(separator: ", ")) },
                             write: {
                                 guard case .text(let v) = $0 else { return }
                                 let values = v.split(whereSeparator: { ", ".contains($0) }).compactMap { Int($0) }
                                 if !values.isEmpty { block.data = values.map { UInt8(truncatingIfNeeded: $0) } }
                             })
        default:
            let size = block.data.count
            return PropField(id: id, label: label, tag: block.tag, kind: .info,
                             read: { .text(size == 4 && block.intValue == -1 ? "−1" : "\(size) байт") }, write: nil)
        }
    }

    private func avfxFields(_ blocks: [AvfxBlock], cls: String?, id: String) -> [PropField] {
        var seen: [String: Int] = [:]
        return blocks.compactMap { block in
            let n = seen[block.tag, default: 0]
            seen[block.tag] = n + 1
            return avfxField(block, cls: cls, id: "\(id)#\(block.tag)\(n)")
        }
    }

    func avfxSections(_ node: OutlineNode, _ block: AvfxBlock, _ cls: String?, _ record: [AvfxBlock]?) -> [PropSection] {
        if block.tag == "Tex", block.children == nil {
            let field = PropField(id: node.id + "#Path", label: "Path", tag: "Path", kind: .text, read: { .text(block.stringValue) },
                                  write: { if case .text(let v) = $0 { block.stringValue = v } })
            return [PropSection(id: node.id + "/main", title: "Texture", fields: [field])]
        }
        if block.tag == "Clip" { return [PropSection(id: node.id + "/main", title: node.title, fields: clipFields(block, id: node.id))] }
        if block.tag == "Modl" { return [PropSection(id: node.id + "/main", title: node.title, fields: modelFields(block, id: node.id))] }
        let source = record ?? block.children ?? []
        var sections = [PropSection(id: node.id + "/main", title: node.title, fields: avfxFields(source, cls: cls, id: node.id))]
        if record == nil {
            for child in block.children ?? [] where child.tag == "Life" {
                if let fields = child.children {
                    sections.append(PropSection(id: node.id + "/life", title: "Life",
                                                fields: avfxFields(fields, cls: "AvfxLife", id: node.id + "/life")))
                } else {
                    let info = PropField(id: node.id + "#Life", label: "Value", tag: "Life", kind: .info, read: { .text("∞ (−1)") }, write: nil)
                    sections.append(PropSection(id: node.id + "/life", title: "Life", fields: [info]))
                }
            }
        }
        sections[0].fields.removeAll { $0.tag == "Life" }
        return sections.filter { !$0.fields.isEmpty }
    }

    private func clipFields(_ block: AvfxBlock, id: String) -> [PropField] {
        guard block.data.count >= 36 else { return [] }
        var fields = [PropField(id: id + "#type", label: "Type", tag: "Clip", kind: .info, read: { [self] in .text(clipTypeName(block)) }, write: nil)]
        for i in 0..<4 {
            let at = 4 + i * 4
            fields.append(PropField(id: id + "#i\(i)", label: "Int \(i)", tag: "Clip", kind: .int,
                                    read: { .int(Int(Int32(bitPattern: block.data.u32(at)))) },
                                    write: { block.data.setU32(at, UInt32(bitPattern: Int32(truncatingIfNeeded: Int($0.number.rounded())))) }))
        }
        for i in 0..<4 {
            let at = 20 + i * 4
            fields.append(PropField(id: id + "#f\(i)", label: "Float \(i)", tag: "Clip", kind: .double,
                                    read: { .double(Double(block.data.f32(at))) },
                                    write: { block.data.setU32(at, Float($0.number).bitPattern) }))
        }
        return fields
    }

    private func modelFields(_ block: AvfxBlock, id: String) -> [PropField] {
        let counts: [(String, Int)] = [
            ("Вершины", (block.child("VDrw")?.data.count ?? 0) / 36), ("Треугольники", (block.child("VIdx")?.data.count ?? 0) / 6),
            ("Точки эмиссии", (block.child("VEmt")?.data.count ?? 0) / 28), ("Порядок точек", (block.child("VNum")?.data.count ?? 0) / 2),
        ]
        return counts.enumerated().map { i, entry in
            PropField(id: id + "#m\(i)", label: entry.0, tag: "Modl", kind: .info, read: { .text("\(entry.1)") }, write: nil)
        }
    }

    private func avfxChannel(_ block: AvfxBlock, id: String, name: String, color: Color, component: Int?, scale: Double) -> CurveChannel {
        let settings = avfxFields((block.children ?? []).filter { ["BvPr", "BvPo", "RanT"].contains($0.tag) }, cls: "AvfxCurveData", id: id)
        return CurveChannel(
            id: id, name: name, color: color,
            read: {
                block.curveKeys.map { key in
                    let raw = component == nil ? key.z : [key.x, key.y, key.z][component ?? 0]
                    return CurveKeyPoint(time: Double(key.time), value: Double(raw) * scale, interpolation: component == nil ? key.type : 1,
                                         tangentOut: Double(key.x), tangentIn: Double(key.y))
                }
            },
            write: { points in
                let sorted = points.sorted { $0.time < $1.time }
                guard let component else {
                    block.curveKeys = sorted.map {
                        AvfxKey(time: Int($0.time.rounded()), type: $0.interpolation, x: Float($0.tangentOut), y: Float($0.tangentIn),
                                z: Float($0.value / scale))
                    }
                    return
                }
                let old = block.curveKeys
                func channelPoints(_ c: Int) -> [CurveKeyPoint] {
                    old.map { CurveKeyPoint(time: Double($0.time), value: Double([$0.x, $0.y, $0.z][c]), interpolation: 1, tangentOut: 0, tangentIn: 0) }
                }
                let others = (0..<3).map(channelPoints)
                block.curveKeys = sorted.enumerated().map { i, point in
                    var values = (0..<3).map { c in
                        old.count == sorted.count ? Double([old[i].x, old[i].y, old[i].z][c]) : CurveMath.sample(others[c], at: point.time)
                    }
                    values[component] = min(max(point.value, 0), 1)
                    return AvfxKey(time: Int(point.time.rounded()), type: old.count == sorted.count ? old[i].type : 1,
                                   x: Float(values[0]), y: Float(values[1]), z: Float(values[2]))
                }
            },
            snapshot: {
                let saved = block.curveKeys
                return { block.curveKeys = saved }
            },
            settings: settings)
    }

    func avfxCurveGroups(_ node: OutlineNode, _ block: AvfxBlock, _ cls: String?) -> [CurveGroup] {
        var groups: [CurveGroup] = []
        var seen: [String: Int] = [:]
        for child in block.children ?? [] where child.children != nil {
            guard let curveClass = catalog.classOf(child, in: cls, parentBlock: block), AvfxCatalog.curveClasses.contains(curveClass) else { continue }
            let n = seen[child.tag, default: 0]
            seen[child.tag] = n + 1
            let id = "\(node.id)~\(child.tag)\(n)"
            let title = catalog.field(cls, child.tag)?.name ?? EffectDocument.colorTitles[child.tag] ?? child.tag
            let isAngle = EffectDocument.angleTags.contains(child.tag)
            let scale = isAngle ? 180 / Double.pi : 1
            var channels: [CurveChannel] = []
            var settings: [PropField] = []
            switch curveClass {
            case "AvfxCurveData":
                channels = [avfxChannel(child, id: id + "/v", name: title, color: EffectDocument.channelColors[2], component: nil, scale: scale)]
            case "AvfxCurveColor":
                if let rgb = child.child("RGB") {
                    for (c, name) in ["R", "G", "B"].enumerated() {
                        channels.append(avfxChannel(rgb, id: id + "/rgb\(c)", name: name, color: EffectDocument.channelColors[c], component: c, scale: 1))
                    }
                }
                for (i, entry) in EffectDocument.colorChannels.enumerated() {
                    guard let sub = child.child(entry.tag), sub.children != nil else { continue }
                    channels.append(avfxChannel(sub, id: id + "/" + entry.tag, name: entry.name,
                                                color: EffectDocument.channelColors[(i + 3) % EffectDocument.channelColors.count], component: nil, scale: 1))
                }
            default:
                let axes: [(String, String, Int)] = [("X", "X", 0), ("Y", "Y", 1), ("Z", "Z", 2), ("XR", "Random X", 3), ("YR", "Random Y", 4), ("ZR", "Random Z", 5)]
                for axis in axes {
                    guard let sub = child.child(axis.0), sub.children != nil else { continue }
                    channels.append(avfxChannel(sub, id: id + "/" + axis.0, name: axis.1, color: EffectDocument.channelColors[axis.2],
                                                component: nil, scale: scale))
                }
                settings = avfxFields((child.children ?? []).filter { $0.children == nil }, cls: curveClass, id: id)
            }
            groups.append(CurveGroup(id: id, title: title, tag: child.tag, isAngle: isAngle, channels: channels, settings: settings))
        }
        return groups
    }

    func avfxSequencerRows(_ root: AvfxBlock) -> [SequencerRow] {
        var starts: [Int: Double] = [:]
        var triggered: Set<Int> = []
        if let scheduler = root.child("Schd") {
            let items = scheduler.children?.last { $0.tag == "Item" && $0.children != nil }?.records() ?? []
            for record in items where recordInt(record, "bEna", 1) != 0 {
                starts[recordInt(record, "TlNo")] = Double(recordInt(record, "StTm", 0))
            }
            let triggers = scheduler.children?.last { $0.tag == "Trgr" && $0.children != nil }?.records().dropFirst(items.count) ?? []
            for record in triggers {
                let timeline = recordInt(record, "TlNo")
                if timeline >= 0 && starts[timeline] == nil { triggered.insert(timeline) }
            }
        }
        let emitters = root.childrenNamed("Emit")
        var rows: [SequencerRow] = []
        for (t, timeline) in root.childrenNamed("TmLn").enumerated() {
            let base = starts[t] ?? 0
            let id = "avfx/TmLn/\(t)"
            var children: [SequencerRow] = []
            let records = timeline.children?.last { $0.tag == "Item" && $0.children != nil }?.records() ?? []
            for (i, record) in records.enumerated() {
                let start = base + Double(recordInt(record, "StTm", 0))
                let endTime = recordInt(record, "EdTm", 0)
                let emitter = recordInt(record, "EmNo")
                let clip = recordInt(record, "ClNo")
                var life: Double = 0
                if emitter >= 0, emitter < emitters.count, let value = emitters[emitter].child("Life")?.child("Val") {
                    life = Double(value.floatValue)
                }
                let open = Double(endTime) + base <= start
                let end = open ? start + (life > 0 ? life : (clip >= 0 && emitter < 0 ? 1 : 30)) : base + Double(endTime)
                let label = emitter >= 0 ? "Emitter \(emitter)" : clip >= 0 ? "Clip \(clip)" : "—"
                children.append(SequencerRow(id: "\(id)/Item/\(i)", label: label, start: start, end: end, openEnded: open && life <= 0 && emitter >= 0,
                                             tint: emitter >= 0 ? .emitter : .item, depth: 1, nodeID: "\(id)/Item/\(i)"))
            }
            let end = children.map(\.end).max() ?? base + 30
            let suffix = triggered.contains(t) ? " (триггер)" : ""
            rows.append(SequencerRow(id: id, label: "Timeline \(t)" + suffix, start: base, end: end, openEnded: false, tint: .timeline,
                                     depth: 0, nodeID: id))
            rows.append(contentsOf: children)
        }
        return rows
    }
}
