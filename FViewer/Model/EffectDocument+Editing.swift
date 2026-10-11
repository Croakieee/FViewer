import Foundation
import SwiftUI

extension EffectDocument {
    func performStructural(_ title: String, _ mutate: () -> Void) {
        let before = snapshot()
        mutate()
        avfxRoot?.updateCounts()
        registerUndo(title, since: before)
    }

    static let addableKinds: [(tag: String, title: String, template: String)] = [
        ("TmLn", "Timeline", "timeline"), ("Emit", "Emitter", "emitter"), ("Ptcl", "Particle", "particle"), ("Efct", "Effector", "effector"),
        ("Bind", "Binder", "binder"), ("Tex", "Texture", ""),
    ]

    func addTopLevel(_ tag: String) {
        guard let root = avfxRoot, let kind = EffectDocument.addableKinds.first(where: { $0.tag == tag }) else { return }
        let block: AvfxBlock?
        if tag == "Tex" {
            block = AvfxBlock(tag: "Tex", data: Array("vfx/common/texture/new_texture.atex".utf8) + [0])
        } else {
            block = AvfxBlock.template(kind.template)
        }
        guard let block else { return }
        performStructural("Add " + kind.title) { root.insertTopLevel(block) }
        selectionID = "avfx/\(tag)/\(root.childrenNamed(tag).count - 1)"
    }

    private static let references: [String: [(owner: String, list: String?, part: String?, field: String)]] = [
        "Emit": [("TmLn", "Item", nil, "EmNo"), ("Emit", "ItEm", nil, "TgtB")],
        "Ptcl": [("Emit", "ItPr", nil, "TgtB")],
        "TmLn": [("Schd", "Item", nil, "TlNo"), ("Schd", "Trgr", nil, "TlNo")],
        "Bind": [("TmLn", nil, nil, "BnNo"), ("TmLn", "Item", nil, "BdNo")],
        "Efct": [("Emit", nil, nil, "EfNo"), ("TmLn", "Item", nil, "EfNo")],
        "Tex": [("Ptcl", nil, "TC1", "TxNo"), ("Ptcl", nil, "TC2", "TxNo"), ("Ptcl", nil, "TC3", "TxNo"), ("Ptcl", nil, "TC4", "TxNo"),
                ("Ptcl", nil, "TD", "TxNo"), ("Ptcl", nil, "TN", "TxNo"), ("Ptcl", nil, "TR", "TxNo"), ("Ptcl", nil, "TP", "TxNo")],
        "Modl": [("Emit", nil, "Data", "MdNo"), ("Ptcl", nil, "Data", "MNO"), ("Ptcl", nil, "Smpl", "IJMN"), ("Ptcl", nil, "Smpl", "VBMN")],
    ]

    private func remapReferences(_ root: AvfxBlock, tag: String, removed: Int) {
        for reference in EffectDocument.references[tag] ?? [] {
            for owner in root.childrenNamed(reference.owner) {
                if let list = reference.list {
                    for record in owner.ownRecords(list) {
                        record.first { $0.tag == reference.field }?.remapReference(reference.field, removed: removed)
                    }
                } else {
                    let holder = reference.part.map { owner.child($0) } ?? owner
                    holder?.child(reference.field)?.remapReference(reference.field, removed: removed)
                }
            }
        }
        guard tag == "Tex" || tag == "Modl" else { return }
        for particle in root.childrenNamed("Ptcl") {
            let lists = tag == "Tex" ? [particle.child("TC1")?.child("TLst")] : [particle.child("Data")?.child("MdNo")]
            for list in lists.compactMap({ $0 }) where list.data.count < 4 || tag == "Tex" {
                list.data = list.data.map { $0 == 255 ? 255 : Int($0) == removed ? 255 : Int($0) > removed ? $0 - 1 : $0 }
            }
        }
    }

    func deleteTopLevel(_ block: AvfxBlock) {
        guard let root = avfxRoot, let index = root.childrenNamed(block.tag).firstIndex(where: { $0 === block }) else { return }
        performStructural("Delete") {
            root.remove(block)
            remapReferences(root, tag: block.tag, removed: index)
        }
    }

    func duplicateTopLevel(_ block: AvfxBlock) {
        guard let root = avfxRoot else { return }
        performStructural("Duplicate") { root.insertTopLevel(block.deepCopy()) }
        selectionID = "avfx/\(block.tag)/\(root.childrenNamed(block.tag).count - 1)"
    }

    private static let recordDefaults: [String: [String: Double]] = [
        "AvfxSchedulerItem": ["bEna": 1, "StTm": 0, "TlNo": -1],
        "AvfxTimelineItem": ["bEna": 1, "StTm": 0, "EdTm": 30, "BdNo": -1, "EfNo": -1, "EmNo": -1, "Plfm": 0, "ClNo": -1],
        "AvfxEmitterItem": ["bEnb": 1, "TgtB": -1, "CrTm": 1, "CrCn": 1, "CrPr": 100, "PICd": 1, "PICo": 1, "ICbP": 1, "OvrV": 60, "PrLk": -1],
    ]

    func defaultRecord(_ cls: String) -> [AvfxBlock] {
        let defaults = EffectDocument.recordDefaults[cls] ?? [:]
        return (catalog.classes[cls] ?? []).map { field in
            let value = defaults[field.tag] ?? 0
            return field.baseType == "AvfxFloat" || field.baseType == "AvfxRadians" ? AvfxBlock.leaf(field.tag, float: Float(value))
                : AvfxBlock.leaf(field.tag, int: Int(value))
        }
    }

    func addRecord(_ owner: AvfxBlock, list: String, cls: String, id: String) {
        var records = owner.ownRecords(list)
        records.append(defaultRecord(cls))
        performStructural("Add Item") { owner.setOwnRecords(list, records) }
        selectionID = "\(id)/\(list)/\(records.count - 1)"
    }

    func changeRecords(_ owner: AvfxBlock, list: String, title: String, _ change: (inout [[AvfxBlock]]) -> Void) {
        var records = owner.ownRecords(list)
        change(&records)
        performStructural(title) { owner.setOwnRecords(list, records) }
    }

    func addUvSet(_ particle: AvfxBlock) {
        let set = AvfxBlock(tag: "UvSt", children: [
            AvfxBlock.leaf("CUvT", int: 0), AvfxBlock.curveAxes(tag: "Scl", axes: ["X", "Y"], value: 1),
            AvfxBlock.curveAxes(tag: "Scr", axes: ["X", "Y"], value: 0), AvfxBlock.curveData(tag: "Rot", value: 0),
        ])
        performStructural("Add UV Set") {
            let list = particle.children ?? []
            let position = (list.lastIndex { $0.tag == "UvSt" }).map { $0 + 1 } ?? list.firstIndex { $0.tag == "Data" } ?? list.count
            particle.insert(set, at: position)
        }
    }

    func addClip(_ timeline: AvfxBlock) {
        var bytes = Array("KILL".utf8.reversed())
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 160))
        bytes.setU32(20, Float(-1).bitPattern)
        bytes.setU32(24, Float(-1).bitPattern)
        let clip = AvfxBlock(tag: "Clip", data: bytes)
        performStructural("Add Clip") {
            let list = timeline.children ?? []
            timeline.insert(clip, at: (list.lastIndex { $0.tag == "Clip" }).map { $0 + 1 } ?? list.count)
        }
    }

    func deleteClip(_ clip: AvfxBlock, from timeline: AvfxBlock) {
        guard let index = timeline.childrenNamed("Clip").firstIndex(where: { $0 === clip }) else { return }
        performStructural("Delete Clip") {
            timeline.remove(clip)
            let records = timeline.ownRecords("Item")
            for record in records {
                for field in record where field.tag == "ClNo" { field.remapReference("ClNo", removed: index) }
            }
            timeline.setOwnRecords("Item", records)
        }
    }

    func removeChild(_ block: AvfxBlock, from parent: AvfxBlock, title: String) {
        performStructural(title) { parent.remove(block) }
    }

    func avfxMissingFields(_ node: OutlineNode, _ block: AvfxBlock, _ cls: String?) -> [MissingCurve] {
        guard let cls, let fields = catalog.classes[cls] else { return [] }
        var result: [MissingCurve] = []
        for (position, field) in fields.enumerated() where block.child(field.tag) == nil {
            guard !AvfxCatalog.countTags.contains(field.tag), !AvfxCatalog.typeTags.contains(field.tag) else { continue }
            let created: () -> AvfxBlock
            switch field.baseType {
            case "AvfxInt", "AvfxBool", "AvfxEnum", "AvfxFlag": created = { AvfxBlock.leaf(field.tag, int: 0) }
            case "AvfxFloat", "AvfxRadians": created = { AvfxBlock.leaf(field.tag, float: 0) }
            default: continue
            }
            let earlier = Set(fields.prefix(position).map(\.tag))
            result.append(MissingCurve(id: node.id + "+f" + field.tag, title: field.name) { [weak self] in
                self?.performStructural("Add " + field.name) {
                    let list = block.children ?? []
                    let position = (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? 0
                    block.insert(created(), at: position)
                }
            })
        }
        return result
    }

    func avfxMissingCurves(_ node: OutlineNode, _ block: AvfxBlock, _ cls: String?) -> [MissingCurve] {
        guard let cls, let fields = catalog.classes[cls] else { return [] }
        var result: [MissingCurve] = []
        var entries = fields.map { ($0.tag, $0.name, $0.baseType) }
        if ["AvfxEmitter", "AvfxParticle"].contains(cls) { entries.append(("Col", "Color", "AvfxCurveColor")) }
        if cls.hasPrefix("AvfxParticleData") || cls.hasPrefix("AvfxEffectorData") {
            for (tag, title) in [("ColB", "Color Begin"), ("ColE", "Color End")] where cls.contains("Model") || cls.contains("Line") {
                entries.append((tag, title, "AvfxCurveColor"))
            }
        }
        for (position, entry) in entries.enumerated() where block.child(entry.0) == nil {
            let created: () -> AvfxBlock
            let fallback: Float = ["Scl", "ARs", "CrC", "A", "Bri"].contains(entry.0) ? 1 : 0
            switch entry.2 {
            case "AvfxCurve1Axis", "AvfxCurveData": created = { AvfxBlock.curveData(tag: entry.0, value: fallback) }
            case "AvfxCurve3Axis": created = { AvfxBlock.curveAxes(tag: entry.0, axes: ["X", "Y", "Z"], value: fallback) }
            case "AvfxCurve2Axis": created = { AvfxBlock.curveAxes(tag: entry.0, axes: ["X", "Y"], value: fallback) }
            case "AvfxCurveColor": created = { AvfxBlock.curveColor(tag: entry.0) }
            default: continue
            }
            let earlier = Set(entries.prefix(position).map(\.0))
            result.append(MissingCurve(id: node.id + "+" + entry.0, title: entry.1) { [weak self] in
                self?.performStructural("Add " + entry.1) {
                    let list = block.children ?? []
                    let position = (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? list.count
                    block.insert(created(), at: position)
                }
                self?.activeCurveID = "\(node.id)~\(entry.0)0"
            })
        }
        return result
    }

    func referenceChoices(tag: String, cls: String?, list: String?) -> [FieldChoice]? {
        guard let root = avfxRoot else { return nil }
        var target: String?
        switch (cls, tag) {
        case ("AvfxTimelineItem", "EmNo"): target = "Emit"
        case ("AvfxEmitterItem", "TgtB"): target = list == "ItEm" ? "Emit" : "Ptcl"
        case ("AvfxSchedulerItem", "TlNo"): target = "TmLn"
        case ("AvfxTimelineItem", "BdNo"), ("AvfxTimeline", "BnNo"): target = "Bind"
        case ("AvfxTimelineItem", "EfNo"), ("AvfxEmitter", "EfNo"): target = "Efct"
        case (_, "TxNo"): target = "Tex"
        case ("AvfxEmitterDataModel", "MdNo"), ("AvfxParticleDataLightModel", "MNO"), ("AvfxParticleSimple", "IJMN"), ("AvfxParticleSimple", "VBMN"):
            target = "Modl"
        default: break
        }
        guard let target else { return nil }
        var choices = [FieldChoice(name: "None", value: -1)]
        for (i, block) in root.childrenNamed(target).enumerated() {
            var name: String
            switch target {
            case "Emit": name = "Emitter \(i) · " + (catalog.enumCaseName("EmitterType", block.int("EVT")) ?? "")
            case "Ptcl": name = "Particle \(i) · " + (catalog.enumCaseName("ParticleType", block.int("PrVT")) ?? "")
            case "TmLn": name = "Timeline \(i)"
            case "Bind": name = "Binder \(i)"
            case "Efct": name = "Effector \(i)"
            case "Tex": name = "\(i) · " + (block.stringValue as NSString).lastPathComponent
            default: name = "Model \(i)"
            }
            if name.hasSuffix(" · ") { name.removeLast(3) }
            choices.append(FieldChoice(name: name, value: i))
        }
        return choices
    }

    func avfxActions(_ node: OutlineNode, _ block: AvfxBlock, parent: AvfxBlock?, cls: String?) -> [NodeAction] {
        var actions: [NodeAction] = []
        if parent === avfxRoot, AvfxBlock.topOrder.contains(block.tag), block.tag != "Schd" {
            if block.tag != "Modl" {
                actions.append(NodeAction(id: node.id + "!dup", title: "Duplicate", symbol: "plus.square.on.square") { [weak self] in self?.duplicateTopLevel(block) })
            }
            actions.append(NodeAction(id: node.id + "!del", title: "Delete", symbol: "trash", destructive: true) { [weak self] in self?.deleteTopLevel(block) })
        }
        if block.tag == "Ptcl" {
            actions.insert(NodeAction(id: node.id + "!uv", title: "Add UV Set", symbol: "square.grid.2x2") { [weak self] in self?.addUvSet(block) }, at: 0)
        }
        if block.tag == "TmLn" {
            actions.insert(NodeAction(id: node.id + "!clip", title: "Add Clip", symbol: "scissors") { [weak self] in self?.addClip(block) }, at: 0)
        }
        if block.tag == "Clip", let parent {
            actions.append(NodeAction(id: node.id + "!del", title: "Delete Clip", symbol: "trash", destructive: true) { [weak self] in
                self?.deleteClip(block, from: parent)
            })
        }
        if block.tag == "UvSt", let parent {
            actions.append(NodeAction(id: node.id + "!del", title: "Delete UV Set", symbol: "trash", destructive: true) { [weak self] in
                self?.removeChild(block, from: parent, title: "Delete UV Set")
            })
        }
        return actions
    }

    func recordActions(_ node: OutlineNode, owner: AvfxBlock, list: String, index: Int) -> [NodeAction] {
        [
            NodeAction(id: node.id + "!dup", title: "Duplicate", symbol: "plus.square.on.square") { [weak self] in
                self?.changeRecords(owner, list: list, title: "Duplicate Item") { records in
                    if index < records.count { records.insert(records[index].map { $0.deepCopy() }, at: index + 1) }
                }
            },
            NodeAction(id: node.id + "!up", title: "Move Up", symbol: "arrow.up") { [weak self] in
                self?.changeRecords(owner, list: list, title: "Move Item") { records in
                    if index > 0, index < records.count { records.swapAt(index, index - 1) }
                }
            },
            NodeAction(id: node.id + "!down", title: "Move Down", symbol: "arrow.down") { [weak self] in
                self?.changeRecords(owner, list: list, title: "Move Item") { records in
                    if index + 1 < records.count { records.swapAt(index, index + 1) }
                }
            },
            NodeAction(id: node.id + "!del", title: "Delete", symbol: "trash", destructive: true) { [weak self] in
                self?.changeRecords(owner, list: list, title: "Delete Item") { records in
                    if index < records.count { records.remove(at: index) }
                }
            },
        ]
    }

    func jsonArrayActions(_ node: OutlineNode, array: JSONNode, index: Int) -> [NodeAction] {
        [
            NodeAction(id: node.id + "!dup", title: "Duplicate", symbol: "plus.square.on.square") { [weak self] in
                self?.performStructural("Duplicate") {
                    guard var items = array.elements, index < items.count else { return }
                    let copy = items[index].deepCopy()
                    if let id = copy["id"]?.string { copy["id"]?.value = .string(id + "_copy") }
                    items.insert(copy, at: index + 1)
                    array.value = .array(items)
                }
            },
            NodeAction(id: node.id + "!del", title: "Delete", symbol: "trash", destructive: true) { [weak self] in
                self?.performStructural("Delete") {
                    guard var items = array.elements, index < items.count else { return }
                    items.remove(at: index)
                    array.value = .array(items)
                }
            },
        ]
    }

    var report: [(title: String, lines: [String])] {
        var sections: [(String, [String])] = []
        if let root = avfxRoot {
            let version = root.int("Ver")
            var summary = [String(format: "Version %08X", version)]
            for (tag, title) in [("TmLn", "Timelines"), ("Emit", "Emitters"), ("Ptcl", "Particles"), ("Efct", "Effectors"), ("Bind", "Binders"),
                                 ("Tex", "Textures"), ("Modl", "Models")] {
                summary.append("\(title): \(root.childrenNamed(tag).count)")
            }
            sections.append(("Summary", summary))
            var types: [String: Int] = [:]
            for particle in root.childrenNamed("Ptcl") {
                var name = catalog.enumCaseName("ParticleType", particle.int("PrVT")) ?? "?"
                if particle.int("bSCt") != 0 { name += " + Simple Animation" }
                types[name, default: 0] += 1
            }
            sections.append(("Particle Types", types.sorted { $0.key < $1.key }.map { "\($0.key) × \($0.value)" }))
            var notes: [String] = []
            let unsupported: Set<Int> = [6, 9, 14, 15]
            for (i, particle) in root.childrenNamed("Ptcl").enumerated() {
                let type = particle.int("PrVT")
                if unsupported.contains(type) || (type == 3 && particle.int("bSCt") == 0) {
                    notes.append("Particle \(i): \(catalog.enumCaseName("ParticleType", type) ?? "?") is not drawn in the preview")
                }
                if particle.int("DsSp") != 0 { notes.append("Particle \(i): soft particle fade is not drawn") }
                if particle.child("TC1")?.int("bUSC") == 1 { notes.append("Particle \(i): screen copy is not drawn") }
            }
            for (i, emitter) in root.childrenNamed("Emit").enumerated() where [1, 2].contains(emitter.int("EVT")) {
                notes.append("Emitter \(i): \(catalog.enumCaseName("EmitterType", emitter.int("EVT")) ?? "?") shape is treated as a point")
            }
            if !root.childrenNamed("Efct").isEmpty { notes.append("Effectors (lights, blurs, camera quake) are not previewed") }
            sections.append(("Preview Notes", notes.isEmpty ? ["Everything in this effect is covered by the preview"] : notes))
        } else if let root = jsonRoot {
            sections.append(("Summary", [
                "Timelines: \(root["timelines"]?.elements?.count ?? 0)", "Emitters: \(root["emitters"]?.elements?.count ?? 0)",
                "Particles: \(root["particles"]?.elements?.count ?? 0)", "Textures: \(textureSlots.count)", "Models: \(modelNames.count)",
            ]))
        }
        return sections
    }
}
