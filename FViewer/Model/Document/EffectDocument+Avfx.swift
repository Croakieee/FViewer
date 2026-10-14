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
                                               symbol: folder.symbol, tint: folder.tint, owner: root))
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
                          tint: NodeTint, owner: AvfxBlock? = nil) -> OutlineNode {
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
            detail = emit > 0 && vertices == 0 ? "\(emit) points" : "\(vertices) verts"
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
            if block.int("bEna") == 0 { detail = "off" }
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
        if parentClass == "AvfxMain" {
            switch block.tag {
            case "TmLn": node.visibility = .timeline(index)
            case "Emit": node.visibility = .emitter(index)
            case "Ptcl": node.visibility = .particle(index)
            default: break
            }
        }
        node.actions = avfxActions(node, block, parent: owner, cls: cls)
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
            let last = children.last(where: { $0.tag == listTag && $0.children != nil }) ?? AvfxBlock(tag: listTag, children: [])
            let itemClass = catalog.classOf(last, in: cls, parentBlock: block)
            let records = block.ownRecords(listTag)
            let group = OutlineNode(id: "\(id)/\(listTag)", title: EffectDocument.listTitles["\(block.tag)/\(listTag)"] ?? listTag,
                                    detail: "\(records.count)", symbol: "list.bullet", tint: .item, payload: .group)
            if listTag != "Trgr", let itemClass {
                group.actions = [NodeAction(id: group.id + "!add", title: "Add Item", symbol: "plus") { [weak self] in
                    self?.addRecord(block, list: listTag, cls: itemClass, id: id)
                }]
            }
            for (i, record) in records.enumerated() {
                let item = recordNode(record, list: last, cls: itemClass, id: "\(id)/\(listTag)/\(i)", index: i, owner: block.tag, listTag: listTag)
                if listTag != "Trgr" { item.actions = recordActions(item, owner: block, list: listTag, index: i) }
                switch (block.tag, listTag) {
                case ("TmLn", "Item"):
                    let emitter = recordInt(record, "EmNo")
                    if emitter >= 0 { item.focus = .emitter(emitter) }
                case ("Emit", "ItPr"):
                    let target = recordInt(record, "TgtB")
                    if target >= 0 { item.focus = .particle(target) }
                case ("Emit", "ItEm"):
                    let target = recordInt(record, "TgtB")
                    if target >= 0 { item.focus = .emitter(target) }
                case ("Schd", "Item"), ("Schd", "Trgr"):
                    let timeline = recordInt(record, "TlNo")
                    if timeline >= 0 { item.focus = .timeline(timeline) }
                default: break
                }
                group.children.append(item)
            }
            result.append(group)
        }
        for child in children {
            if child.tag == "Clip" {
                let n = counters["Clip", default: 0]
                counters["Clip"] = n + 1
                result.append(avfxNode(child, "AvfxTimelineClip", id: "\(id)/Clip\(n)", index: n, parentClass: cls,
                                       symbol: "scissors", tint: .item, owner: block))
                continue
            }
            guard child.children != nil, !listTags.contains(child.tag) else { continue }
            let childClass = catalog.classOf(child, in: cls, parentBlock: block)
            if let childClass, AvfxCatalog.curveClasses.contains(childClass) || childClass == "AvfxLife" { continue }
            let n = counters[child.tag, default: 0]
            counters[child.tag] = n + 1
            result.append(avfxNode(child, childClass, id: "\(id)/\(child.tag)\(n)", index: n, parentClass: cls,
                                   symbol: "square.stack.3d.up", tint: .data, owner: block))
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
            detail = "frame \(recordInt(record, "StTm", 0))"
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
            let last = recordInt(record, "EdTm", 0)
            detail = last < 0 ? "\(recordInt(record, "StTm", 0))–∞" : "\(recordInt(record, "StTm", 0))–\(last)"
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
        if recordInt(record, "bEnb", recordInt(record, "bEna", 1)) == 0 { detail += detail.isEmpty ? "off" : " · off" }
        return OutlineNode(id: id, title: title, detail: detail, symbol: symbol, tint: tint,
                           payload: .avfx(block: list, cls: cls, record: record))
    }

    func avfxField(_ block: AvfxBlock, cls: String?, id: String, list: String? = nil) -> PropField? {
        if block.tag == "Name", block.children == nil {
            return PropField(id: id, label: "Bind Point Name", tag: block.tag, kind: .text, read: { .text(block.stringValue) },
                             write: {
                                 guard case .text(let v) = $0 else { return }
                                 var bytes = Array(v.utf8) + [0]
                                 while bytes.count % 4 != 0 { bytes.append(0) }
                                 block.data = bytes
                             })
        }
        if block.tag == "Tex", cls == "AvfxMain" { return nil }
        if block.tag == "UvSN", cls?.hasPrefix("AvfxParticleTexture") == true, block.data.count >= 4 {
            let count = block.parent?.parent?.childrenNamed("UvSt").count ?? 0
            var choices = (0..<count).map { FieldChoice(name: "UV Set \($0)", value: $0) }
            let current = block.intValue
            if !choices.contains(where: { $0.value == current }) { choices.append(FieldChoice(name: "\(current) · missing", value: current)) }
            return PropField(id: id, label: "UV Set", tag: block.tag, kind: .choice(choices), read: { .int(block.intValue) },
                             write: { if case .int(let v) = $0 { block.intValue = v } })
        }
        if block.tag == "ClNo", cls == "AvfxTimelineItem", block.data.count >= 4 {
            var choices = [FieldChoice(name: "None", value: -1)]
            let clips = block.parent?.parent?.childrenNamed("Clip") ?? []
            for (i, clip) in clips.enumerated() { choices.append(FieldChoice(name: "Clip \(i) · \(clipTypeName(clip))", value: i)) }
            let current = block.intValue
            if !choices.contains(where: { $0.value == current }) { choices.append(FieldChoice(name: "\(current) · missing", value: current)) }
            return PropField(id: id, label: "Clip", tag: block.tag, kind: .choice(choices), read: { .int(block.intValue) },
                             write: { if case .int(let v) = $0 { block.intValue = v } })
        }
        if AvfxBlock.binaryLeafTags.contains(block.tag) || block.children != nil { return nil }
        if block.data.count >= 4, let choices = referenceChoices(tag: block.tag, cls: cls, list: list) {
            let label = catalog.field(cls, block.tag)?.name ?? block.tag
            return PropField(id: id, label: label.replacingOccurrences(of: " Index", with: ""), tag: block.tag, kind: .choice(choices),
                             read: { .int(block.intValue) }, write: { if case .int(let v) = $0 { block.intValue = v } })
        }
        if AvfxCatalog.countTags.contains(block.tag) { return nil }
        if cls == "AvfxParticle" && block.tag == "UvSN" { return nil }
        if block.tag == "BPID", block.data.count >= 4 {
            var choices = EffectDocument.bindPointNames.map { FieldChoice(name: "\($0.id) · \($0.name)", value: $0.id) }
            let current = block.intValue
            if !choices.contains(where: { $0.value == current }) { choices.insert(FieldChoice(name: "\(current) · unnamed", value: current), at: 0) }
            return PropField(id: id, label: "Bind Point", tag: block.tag, kind: .choice(choices), read: { .int(block.intValue) },
                             write: { if case .int(let v) = $0 { block.intValue = v } })
        }
        let def = catalog.field(cls, block.tag)
        let label = def?.name ?? block.tag
        let base = def?.baseType ?? (block.data.count == 4 ? "AvfxInt" : "")
        if AvfxCatalog.typeTags.contains(block.tag), let enumName = def?.enumName {
            let choices = (catalog.enums[enumName] ?? []).map { FieldChoice(name: $0.name, value: $0.value) }
            return PropField(id: id, label: label, tag: block.tag, kind: .choice(choices), read: { .int(block.intValue) },
                             write: { [weak self] in if case .int(let v) = $0 { self?.applyType(block, ownerClass: cls, value: v) } })
        }
        switch base {
        case "AvfxBool":
            var field = PropField(id: id, label: label, tag: block.tag, kind: .bool,
                             read: {
                                 guard let first = block.data.first else { return .bool(false) }
                                 return first == 1 ? .bool(true) : first == 0 ? .bool(false) : .int(Int(first))
                             },
                             write: { value in
                                 guard !block.data.isEmpty else { return }
                                 let byte: UInt8
                                 switch value {
                                 case .bool(let on): byte = on ? 1 : 0
                                 case .int(let raw): byte = UInt8(truncatingIfNeeded: raw)
                                 default: return
                                 }
                                 if block.data[0] == byte { return }
                                 block.data[0] = byte
                                 for i in 1..<block.data.count { block.data[i] = 0 }
                             })
            field.triState = true
            return field
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
                             write: { block.intValue = Int(safe: $0.number.rounded()) })
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
                             read: { .text(size == 4 && block.intValue == -1 ? "−1" : "\(size) bytes") }, write: nil)
        }
    }

    private func avfxFields(_ blocks: [AvfxBlock], cls: String?, id: String, list: String? = nil) -> [PropField] {
        var seen: [String: Int] = [:]
        return blocks.flatMap { block -> [PropField] in
            let n = seen[block.tag, default: 0]
            seen[block.tag] = n + 1
            if list == nil, let target = EffectDocument.indexListTarget(block, cls: cls) { return indexListFields(block, target: target, id: id) }
            guard var field = avfxField(block, cls: cls, id: "\(id)#\(block.tag)\(n)", list: list) else { return [] }
            if list == nil, field.write != nil, let parent = block.parent, !AvfxCatalog.typeTags.contains(block.tag) {
                let label = field.label
                field.unassign = { [weak self] in self?.removeChild(block, from: parent, title: "Remove " + label) }
            }
            field.unseen = PreviewCoverage.ignores(cls, block.tag)
            return [field]
        }
    }

    static func indexListTarget(_ block: AvfxBlock, cls: String?) -> String? {
        guard block.children == nil else { return nil }
        if block.tag == "TLst" { return "Tex" }
        if block.tag == "MdNo", cls?.hasPrefix("AvfxParticleData") == true { return "Modl" }
        return nil
    }

    private func indexListFields(_ block: AvfxBlock, target: String, id: String) -> [PropField] {
        let choices = referenceChoices(tag: target == "Tex" ? "TxNo" : "MdNo", cls: target == "Tex" ? nil : "AvfxEmitterDataModel", list: nil) ?? []
        let title = target == "Tex" ? "Mask Texture" : "Model"
        return block.data.indices.map { position in
            var field = PropField(id: "\(id)#\(block.tag)@\(position)", label: "\(title) \(position + 1)", tag: block.tag, kind: .choice(choices),
                                  read: { position < block.data.count && block.data[position] != 255 ? .int(Int(block.data[position])) : .int(-1) },
                                  write: {
                                      guard case .int(let v) = $0, position < block.data.count else { return }
                                      block.data[position] = v < 0 ? 255 : UInt8(truncatingIfNeeded: v)
                                  })
            if block.data.count > 1 {
                field.unassign = { [weak self] in
                    self?.performStructural("Remove \(title) \(position + 1)") { if position < block.data.count { block.data.remove(at: position) } }
                }
            }
            return field
        }
    }

    private func simpleColorFields(_ block: AvfxBlock, id: String) -> [PropField] {
        var fields: [PropField] = []
        guard let colors = block.child("Cols"), let frames = block.child("Frms") else { return fields }
        for i in 0..<4 where colors.data.count >= (i + 1) * 4 && frames.data.count >= (i + 1) * 2 {
            fields.append(PropField(id: "\(id)#frame\(i)", label: "Frame \(i + 1)", tag: "Frms", kind: .int,
                                    read: { .int(Int(Int16(bitPattern: frames.data.u16(i * 2)))) },
                                    write: {
                                        let v = UInt16(bitPattern: Int16(truncatingIfNeeded: Int(safe: $0.number.rounded())))
                                        frames.data[i * 2] = UInt8(v & 0xff)
                                        frames.data[i * 2 + 1] = UInt8(v >> 8)
                                    }))
            fields.append(PropField(id: "\(id)#color\(i)", label: "Color \(i + 1)", tag: "Cols", kind: .color(alpha: true),
                                    read: {
                                        let d = colors.data
                                        return .color(Double(d[i * 4]) / 255, Double(d[i * 4 + 1]) / 255, Double(d[i * 4 + 2]) / 255, Double(d[i * 4 + 3]) / 255)
                                    },
                                    write: {
                                        guard case .color(let r, let g, let b, let a) = $0 else { return }
                                        for (k, v) in [r, g, b, a].enumerated() { colors.data[i * 4 + k] = UInt8(max(0, min(255, (v * 255).rounded()))) }
                                    }))
        }
        return fields
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
        let list = record != nil ? block.tag : nil
        var sections = [PropSection(id: node.id + "/main", title: node.title, fields: avfxFields(source, cls: cls, id: node.id, list: list))]
        if block === avfxRoot, let x = block.child("RvSx"), let y = block.child("RvSy"), let z = block.child("RvSz") {
            let combined = PropField(id: node.id + "#RvSc", label: "Revised Scale (Combined)", tag: "RvSx", kind: .double,
                                     read: { .double(Double(x.floatValue)) },
                                     write: { value in for target in [x, y, z] { target.floatValue = Float(value.number) } })
            sections.insert(PropSection(id: node.id + "/revised", title: "Revised Scale", fields: [combined]), at: 0)
        }
        if record == nil, block.tag == "Emit" || block.tag == "Ptcl" {
            sections.insert(PropSection(id: node.id + "/transform", title: "Transform", fields: transformFields(block, id: node.id)), at: 0)
        }
        if block.tag == "Smpl" {
            sections.append(PropSection(id: node.id + "/colors", title: "Sprite Colors", fields: simpleColorFields(block, id: node.id)))
        }
        let livesByBlock = block.tag == "Emit" || block.tag == "Ptcl" || block.tag == "Efct"
        if record == nil, livesByBlock {
            for child in block.children ?? [] where child.tag == "Life" {
                if let fields = child.children {
                    sections.append(PropSection(id: node.id + "/life", title: "Life",
                                                fields: avfxFields(fields, cls: "AvfxLife", id: node.id + "/life")))
                } else {
                    let infinite = PropField(id: node.id + "#Life", label: "Infinite", tag: "Life", kind: .bool, read: { .bool(true) },
                                             write: { [weak self] in if case .bool(false) = $0 { self?.makeLifeFinite(child, in: block) } })
                    sections.append(PropSection(id: node.id + "/life", title: "Life", fields: [infinite]))
                }
            }
        }
        if livesByBlock { for i in sections.indices where sections[i].id.hasSuffix("/main") { sections[i].fields.removeAll { $0.tag == "Life" } } }
        return sections.filter { !$0.fields.isEmpty }
    }

    static let bindPointNames: [(id: Int, name: String)] = [
        (0, "None"), (1, "Face (j_kao)"), (3, "Base of weapon (relative)"), (4, "Center of weapon"), (5, "Tip of weapon (relative)"),
        (6, "Right shoulder"), (7, "Left shoulder"), (8, "Right forearm"), (9, "Left forearm"), (10, "Right calves"), (11, "Left calves"),
        (16, "Front of character"), (25, "Top of head"), (26, "Middle of head"), (27, "Front of head"), (28, "Chest (j_sebo_c)"),
        (29, "Center of character (n_root)"), (30, "Center of character (n_hara)"), (31, "Waist (j_kosi)"), (32, "Right hand (j_te_r)"),
        (33, "Left hand (j_te_l)"), (34, "Right foot"), (35, "Left foot"), (42, "Above character (n_root)"), (43, "Head (near right eye)"),
        (44, "Head (near left eye)"), (71, "Character origin (n_root)"), (77, "Right hand (n_buki_r)"), (78, "Left hand (n_buki_l)"),
        (107, "n_throw"), (108, "SGE noulith 3 front / RPR avatar neck"), (109, "SGE noulith 3 back / RPR avatar spine"),
        (110, "SGE noulith 2 front / RPR avatar left hand"), (111, "SGE noulith 2 back / RPR avatar face"),
        (112, "SGE noulith 4 front / RPR avatar origin"), (113, "SGE noulith 4 back"),
    ]

    static let clipTypes: [(code: String, name: String)] = [
        ("KILL", "Kill"), ("REST", "Reset"), ("END ", "End"), ("FADI", "Fade In"), ("ULLP", "Unlock Loop Point"), ("TRG ", "Trigger"),
        ("RTRG", "Random Trigger"),
    ]

    private func clipFields(_ block: AvfxBlock, id: String) -> [PropField] {
        guard block.data.count >= 36 else { return [] }
        func code() -> String { String(decoding: block.data.prefix(4).reversed(), as: UTF8.self) }
        func intField(_ label: String, _ i: Int, suffix: String) -> PropField {
            let at = 4 + i * 4
            return PropField(id: id + "#" + suffix, label: label, tag: "Clip", kind: .int,
                             read: { .int(Int(Int32(bitPattern: block.data.u32(at)))) },
                             write: { block.data.setU32(at, UInt32(bitPattern: Int32(truncatingIfNeeded: Int(safe: $0.number.rounded())))) })
        }
        func flagField(_ label: String, at: Int, suffix: String, isOn: @escaping () -> Bool, set: @escaping (Bool) -> UInt32) -> PropField {
            PropField(id: id + "#" + suffix, label: label, tag: "Clip", kind: .bool, read: { .bool(isOn()) },
                      write: { if case .bool(let v) = $0 { block.data.setU32(at, set(v)) } })
        }
        let choices = EffectDocument.clipTypes.enumerated().map { FieldChoice(name: $0.element.name, value: $0.offset) }
        var fields = [PropField(id: id + "#type", label: "Type", tag: "Clip", kind: .choice(choices),
                                read: { .int(EffectDocument.clipTypes.firstIndex { $0.code == code() } ?? -1) },
                                write: {
                                    guard case .int(let v) = $0, v >= 0, v < EffectDocument.clipTypes.count else { return }
                                    let bytes = Array(EffectDocument.clipTypes[v].code.utf8.reversed())
                                    for k in 0..<4 { block.data[k] = bytes[k] }
                                })]
        switch code() {
        case "KILL":
            fields.append(intField("Fade Out Duration", 0, suffix: "fade"))
            fields.append(flagField("Hide", at: 16, suffix: "hide", isOn: { block.data.u32(16) == 1 }, set: { $0 ? 1 : 0 }))
            fields.append(flagField("Allow Show", at: 20, suffix: "allow", isOn: { block.data.f32(20) != -1 },
                                    set: { $0 ? Float(0).bitPattern : Float(-1).bitPattern }))
            fields.append(flagField("Start Hidden", at: 24, suffix: "hidden", isOn: { block.data.f32(24) != -1 },
                                    set: { $0 ? Float(0).bitPattern : Float(-1).bitPattern }))
        case "RTRG":
            fields.append(intField("Minimum Trigger", 0, suffix: "min"))
            fields.append(intField("Maximum Trigger", 1, suffix: "max"))
        default: break
        }
        for i in 0..<4 { fields.append(intField("Raw Integer \(i + 1)", i, suffix: "i\(i)")) }
        for i in 0..<4 {
            let at = 20 + i * 4
            fields.append(PropField(id: id + "#f\(i)", label: "Raw Float \(i + 1)", tag: "Clip", kind: .double,
                                    read: { .double(Double(block.data.f32(at))) },
                                    write: { block.data.setU32(at, Float($0.number).bitPattern) }))
        }
        return fields
    }

    private func modelFields(_ block: AvfxBlock, id: String) -> [PropField] {
        let counts: [(String, Int)] = [
            ("Vertices", (block.child("VDrw")?.data.count ?? 0) / 36), ("Triangles", (block.child("VIdx")?.data.count ?? 0) / 6),
            ("Emit Vertices", (block.child("VEmt")?.data.count ?? 0) / 28), ("Emit Order", (block.child("VNum")?.data.count ?? 0) / 2),
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
                        AvfxKey(time: Int(safe: $0.time.rounded()), type: $0.interpolation, x: Float($0.tangentOut), y: Float($0.tangentIn),
                                z: Float($0.value / scale))
                    }
                    return
                }
                let old = block.curveKeys
                func channelPoints(_ c: Int) -> [CurveKeyPoint] {
                    old.map { CurveKeyPoint(time: Double($0.time), value: Double([$0.x, $0.y, $0.z][c]), interpolation: 1, tangentOut: 0, tangentIn: 0) }
                }
                let others = (0..<3).map(channelPoints)
                var sources: [AvfxKey?]
                var ordered = points
                if points.count == old.count {
                    let paired = zip(points, old).sorted { $0.0.time < $1.0.time }
                    ordered = paired.map(\.0)
                    sources = paired.map { Optional($0.1) }
                } else {
                    ordered = sorted
                    sources = sorted.map { point in old.first { $0.time == Int(safe: point.time.rounded()) } }
                }
                block.curveKeys = ordered.enumerated().map { i, point in
                    var values = (0..<3).map { c in
                        sources[i].map { Double([$0.x, $0.y, $0.z][c]) } ?? CurveMath.sample(others[c], at: point.time)
                    }
                    values[component] = min(max(point.value, 0), 1)
                    return AvfxKey(time: Int(safe: point.time.rounded()), type: sources[i]?.type ?? 1,
                                   x: Float(values[0]), y: Float(values[1]), z: Float(values[2]))
                }
            },
            snapshot: {
                let saved = block.curveKeys
                return { block.curveKeys = saved }
            },
            settings: settings,
            extrapolation: { (block.int("BvPr"), block.int("BvPo")) },
            colorComponent: component,
            clampUnit: component != nil)
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
            let isAngle = EffectDocument.angleTags.contains(child.tag) || catalog.isAngle(cls, child.tag)
            let scale = isAngle ? 180 / Double.pi : 1
            var channels: [CurveChannel] = []
            var settings: [PropField] = []
            var missing: [MissingCurve] = []
            var unassign: [String: () -> Void] = [:]
            func slot(_ tag: String, _ name: String, order: [String], channelID: String) {
                if let sub = child.child(tag), sub.children != nil {
                    unassign[channelID] = { [weak self] in self?.removeChild(sub, from: child, title: "Remove " + title + " " + name) }
                } else {
                    let earlier = Set(order.prefix { $0 != tag })
                    missing.append(MissingCurve(id: id + "+" + tag, title: name) { [weak self] in
                        self?.performStructural("Add " + title + " " + name) {
                            let list = child.children ?? []
                            let position = (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? 0
                            let random = ["XR", "YR", "ZR"].contains(tag) || tag.hasPrefix("Ran") || tag == "RBri"
                            let unit = curveClass == "AvfxCurveColor" || child.tag.hasPrefix("Scl") || child.tag == "Scale"
                            child.insert(AvfxBlock.curveData(tag: tag, value: !random && unit ? 1 : 0), at: position)
                        }
                    })
                }
            }
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
                let colorOrder = ["RGB"] + EffectDocument.colorChannels.map(\.tag)
                for entry in EffectDocument.colorChannels { slot(entry.tag, entry.name, order: colorOrder, channelID: id + "/" + entry.tag) }
            default:
                let axes: [(String, String, Int)] = [("X", "X", 0), ("Y", "Y", 1), ("Z", "Z", 2), ("XR", "Random X", 3), ("YR", "Random Y", 4), ("ZR", "Random Z", 5)]
                for axis in axes {
                    guard let sub = child.child(axis.0), sub.children != nil else { continue }
                    channels.append(avfxChannel(sub, id: id + "/" + axis.0, name: axis.1, color: EffectDocument.channelColors[axis.2],
                                                component: nil, scale: scale))
                }
                settings = avfxFields((child.children ?? []).filter { $0.children == nil }, cls: curveClass, id: id)
                let offered = curveClass == "AvfxCurve2Axis" ? axes.filter { !$0.0.hasPrefix("Z") } : axes
                let axisOrder = ["ACT", "ACTR"] + axes.map(\.0)
                for axis in offered { slot(axis.0, axis.1, order: axisOrder, channelID: id + "/" + axis.0) }
            }
            groups.append(CurveGroup(id: id, title: title, tag: child.tag, isAngle: isAngle, channels: channels, settings: settings,
                                     remove: { [weak self] in self?.removeChild(child, from: block, title: "Remove " + title) },
                                     missing: missing, unassign: unassign))
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
                let effector = recordInt(record, "EfNo")
                let effectorCount = root.childrenNamed("Efct").count
                var label = "[NONE]"
                if emitter >= 0 {
                    label = names["avfx/Emit/\(emitter)"] ?? "Emitter \(emitter)"
                } else if clip >= 0 {
                    label = names["\(id)/Clip\(clip)"] ?? "Clip \(clip)"
                } else if effector >= 0, effector < effectorCount {
                    label = names["avfx/Efct/\(effector)"] ?? "Effector \(effector)"
                }
                var row = SequencerRow(id: "\(id)/Item/\(i)", label: label, start: start, end: end, openEnded: open && life <= 0 && emitter >= 0,
                                       tint: emitter >= 0 ? .emitter : .item, depth: 1, nodeID: "\(id)/Item/\(i)")
                row.base = base
                row.densityKey = emitter >= 0 ? "e\(emitter)" : "-"
                if emitter >= 0, emitter < emitters.count {
                    let from = Double(emitters[emitter].int("LpSt")), to = Double(emitters[emitter].int("LpEd"))
                    if to > from, from >= 0 { row.loop = (start + from, start + to) }
                }
                row.startField = record.first { $0.tag == "StTm" }.flatMap { avfxField($0, cls: "AvfxTimelineItem", id: row.id + "#StTm") }
                row.endField = record.first { $0.tag == "EdTm" }.flatMap { avfxField($0, cls: "AvfxTimelineItem", id: row.id + "#EdTm") }
                row.enabledField = record.first { $0.tag == "bEna" }.flatMap { avfxField($0, cls: "AvfxTimelineItem", id: row.id + "#bEna") }
                children.append(row)
            }
            let end = children.map(\.end).max() ?? base + 30
            let suffix = triggered.contains(t) ? " (trigger)" : ""
            rows.append(SequencerRow(id: id, label: "Timeline \(t)" + suffix, start: base, end: end, openEnded: false, tint: .timeline,
                                     depth: 0, nodeID: id))
            rows.append(contentsOf: children)
        }
        return rows
    }
}
