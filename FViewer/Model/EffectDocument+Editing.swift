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
        ("Bind", "Binder", "binder"), ("Tex", "Texture", ""), ("Modl", "Model", ""),
    ]

    func addTopLevel(_ tag: String) {
        guard let root = avfxRoot, let kind = EffectDocument.addableKinds.first(where: { $0.tag == tag }) else { return }
        let block: AvfxBlock?
        if tag == "Tex" {
            block = AvfxBlock(tag: "Tex", data: Array("vfx/common/texture/new_texture.atex".utf8) + [0])
        } else if tag == "Modl" {
            block = AvfxBlock(tag: "Modl", children: [])
        } else {
            block = AvfxBlock.template(kind.template)
        }
        guard let block else { return }
        performStructural("Add " + kind.title) {
            root.insertTopLevel(block)
            for reference in EffectDocument.nodeReferences(block) where reference.get() >= root.childrenNamed(reference.target).count {
                reference.set(-1)
            }
        }
        selectionID = "avfx/\(tag)/\(root.childrenNamed(tag).count - 1)"
    }

    static let referenceTable: [String: [(owner: String, list: String?, part: String?, field: String)]] = [
        "Emit": [("TmLn", "Item", nil, "EmNo"), ("Emit", "ItEm", nil, "TgtB")],
        "Ptcl": [("Emit", "ItPr", nil, "TgtB")],
        "TmLn": [("Schd", "Item", nil, "TlNo"), ("Schd", "Trgr", nil, "TlNo")],
        "Bind": [("TmLn", nil, nil, "BnNo"), ("TmLn", "Item", nil, "BdNo")],
        "Efct": [("Emit", nil, nil, "EfNo"), ("TmLn", "Item", nil, "EfNo")],
        "Tex": [("Ptcl", nil, "TC1", "TxNo"), ("Ptcl", nil, "TC2", "TxNo"), ("Ptcl", nil, "TC3", "TxNo"), ("Ptcl", nil, "TC4", "TxNo"),
                ("Ptcl", nil, "TD", "TxNo"), ("Ptcl", nil, "TN", "TxNo"), ("Ptcl", nil, "TR", "TxNo"), ("Ptcl", nil, "TP", "TxNo")],
        "Modl": [("Emit", nil, "Data", "MdNo"), ("Ptcl", nil, "Data", "MNO"), ("Ptcl", nil, "Smpl", "IJMN"), ("Ptcl", nil, "Smpl", "VBMN")],
    ]

    func remapReferences(_ root: AvfxBlock, tag: String, removed: Int) {
        for reference in EffectDocument.referenceTable[tag] ?? [] {
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

    func defaultRecord(_ cls: String) -> [AvfxBlock] {
        var fields = (catalog.classes[cls] ?? []).compactMap { catalog.freshLeaf($0, in: cls) }
        if cls == "AvfxTimelineItem" {
            fields.removeAll { $0.tag == "ClNo" }
            fields.first { $0.tag == "bEna" }?.data = [0, 0, 0, 0]
            fields.first { $0.tag == "EdTm" }?.intValue = 1
        }
        return fields
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

    func dataBlock(forClass cls: String) -> AvfxBlock? {
        catalog.isOptionalData(cls) ? nil : catalog.freshData(cls)
    }

    func applyType(_ typeField: AvfxBlock, ownerClass: String?, value: Int) {
        guard let owner = typeField.parent, let ownerClass, let info = AvfxCatalog.dataTypes[ownerClass] else {
            typeField.intValue = value
            return
        }
        guard typeField.intValue != value else { return }
        typeField.intValue = value
        var list = owner.children ?? []
        var position = list.firstIndex { $0.tag == "Data" }
        list.removeAll { $0.tag == "Data" }
        owner.children = list
        let name = catalog.enumCaseName(info.enumName, value)?.replacingOccurrences(of: "_Variable", with: "") ?? ""
        guard let data = dataBlock(forClass: info.prefix + name) else { return }
        if position == nil, owner.tag == "Ptcl" {
            position = (list.lastIndex { $0.tag == "UvSt" }).map { $0 + 1 } ?? list.firstIndex { ["TC1", "TC2", "TC3", "TC4", "TD", "TN", "TR", "TP"].contains($0.tag) }
        }
        owner.insert(data, at: position ?? list.count)
    }

    func applyMesh(_ mesh: GltfMesh, to model: AvfxBlock, emitPoints: Bool) throws {
        guard !mesh.positions.isEmpty else { throw AvfxError.malformed("The file has no vertices") }
        guard mesh.positions.count <= 65535 else {
            throw AvfxError.malformed("\(mesh.positions.count) vertices: an effect model can hold at most 65535")
        }
        let order = ["VNum", "VEmt", "VDrw", "VIdx"]
        func set(_ tag: String, _ data: [UInt8]) {
            if let existing = model.child(tag) {
                existing.data = data
                return
            }
            let list = model.children ?? []
            let rank = order.firstIndex(of: tag) ?? order.count
            let position = list.firstIndex { (order.firstIndex(of: $0.tag) ?? -1) > rank } ?? list.count
            model.insert(AvfxBlock(tag: tag, data: data), at: position)
        }
        if emitPoints {
            let data = Gltf.emitData(mesh)
            performStructural("Import Emit Points") {
                set("VNum", data.order)
                set("VEmt", data.points)
            }
        } else {
            guard mesh.indices.count >= 3 else { throw AvfxError.malformed("The file has no triangles") }
            let data = Gltf.vertexData(mesh)
            performStructural("Import Model") {
                set("VDrw", data.vertices)
                set("VIdx", data.indices)
            }
        }
    }

    func makeLifeFinite(_ life: AvfxBlock, in owner: AvfxBlock) {
        guard var list = owner.children, let index = list.firstIndex(where: { $0 === life }) else { return }
        let fresh = AvfxBlock(tag: "Life", children: [AvfxBlock.leaf("Val", float: 60), AvfxBlock.leaf("ValR", float: 0), AvfxBlock.leaf("Type", int: 0)])
        fresh.parent = owner
        list[index] = fresh
        owner.children = list
    }

    func makeLifeInfinite(_ life: AvfxBlock, in owner: AvfxBlock) {
        guard var list = owner.children, let index = list.firstIndex(where: { $0 === life }) else { return }
        let fresh = AvfxBlock.leaf("Life", int: -1)
        fresh.parent = owner
        list[index] = fresh
        owner.children = list
    }

    func addClip(_ timeline: AvfxBlock) {
        var bytes = Array("KILL".utf8.reversed())
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 160))
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
            if AvfxCatalog.curveClasses.contains(field.baseType) || field.baseType == "AvfxCurve1Axis" { continue }
            guard catalog.freshBlock(field, in: cls) != nil else { continue }
            let created: () -> AvfxBlock = { [catalog] in catalog.freshBlock(field, in: cls) ?? AvfxBlock.leaf(field.tag, int: 0) }
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
        var seenTags: Set<String> = []
        entries = entries.filter { seenTags.insert($0.0).inserted }
        for (position, entry) in entries.enumerated() where block.child(entry.0) == nil {
            let field = AvfxField(tag: entry.0, name: entry.1, type: entry.2)
            guard AvfxCatalog.curveClasses.contains(entry.2 == "AvfxCurve1Axis" ? "AvfxCurveData" : entry.2) else { continue }
            let created: () -> AvfxBlock = { [catalog] in catalog.freshBlock(field, in: cls) ?? AvfxCatalog.freshCurve(entry.0) }
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
        if parent === avfxRoot, EffectDocument.exchangeTags.contains(block.tag) {
            actions.append(NodeAction(id: node.id + "!export", title: "Export…", symbol: "square.and.arrow.up") { [weak self] in
                self?.exportRequest = [node.id]
            })
        }
        if let life = block.children?.first(where: { $0.tag == "Life" }), life.children != nil, ["Emit", "Ptcl", "Bind", "Efct"].contains(block.tag) {
            actions.append(NodeAction(id: node.id + "!life", title: "Make Life Infinite", symbol: "infinity") { [weak self] in
                self?.performStructural("Make Life Infinite") { self?.makeLifeInfinite(life, in: block) }
            })
        }
        if let cls, let info = AvfxCatalog.dataTypes[cls], block.child("Data") == nil,
           let name = catalog.enumCaseName(info.enumName, block.int(info.field))?.replacingOccurrences(of: "_Variable", with: ""),
           catalog.classes[info.prefix + name] != nil {
            actions.append(NodeAction(id: node.id + "!data", title: "Add Data Block", symbol: "plus.rectangle") { [weak self] in
                guard let self, let data = self.catalog.freshData(info.prefix + name) else { return }
                self.performStructural("Add Data Block") {
                    let list = block.children ?? []
                    var position = list.count
                    if block.tag == "Ptcl" {
                        position = (list.lastIndex { $0.tag == "UvSt" }).map { $0 + 1 }
                            ?? list.firstIndex { ["TC1", "TC2", "TC3", "TC4", "TD", "TN", "TR", "TP"].contains($0.tag) } ?? list.count
                    }
                    block.insert(data, at: position)
                }
            })
        }
        if block.tag == "Modl" {
            actions.insert(NodeAction(id: node.id + "!editor", title: "Open Model Editor…", symbol: "macwindow") { AppDelegate.model?.requestModelEditor(node.id) }, at: 0)
            actions.insert(NodeAction(id: node.id + "!gltfout", title: "Export glTF…", symbol: "square.and.arrow.up") {
                AppDelegate.model?.exportModel(block, name: node.title.replacingOccurrences(of: " ", with: "_"))
            }, at: 0)
            actions.insert(NodeAction(id: node.id + "!emitin", title: "Import Emit Points…", symbol: "dot.squareshape") {
                AppDelegate.model?.importModel(block, emitPoints: true)
            }, at: 0)
            actions.insert(NodeAction(id: node.id + "!gltfin", title: "Import glTF…", symbol: "square.and.arrow.down") {
                AppDelegate.model?.importModel(block, emitPoints: false)
            }, at: 0)
        }
        if block.tag == "Tex", block.children == nil {
            actions.insert(NodeAction(id: node.id + "!png", title: "Export PNG…", symbol: "photo") { AppDelegate.model?.exportTexture(block.stringValue) }, at: 0)
            actions.insert(NodeAction(id: node.id + "!replace", title: "Replace Image…", symbol: "arrow.triangle.2.circlepath") {
                AppDelegate.model?.replaceTexture(block)
            }, at: 0)
        }
        if block.tag == "Ptcl", block.childrenNamed("UvSt").count < 4 {
            actions.insert(NodeAction(id: node.id + "!uv", title: "Add UV Set", symbol: "square.grid.2x2") { [weak self] in self?.addUvSet(block) }, at: 0)
        }
        let structural: Set<String> = ["Item", "Trgr", "ItPr", "ItEm", "Life", "Clip", "UvSt", "Keys", "KeyC"]
        if let parent, parent !== avfxRoot, block !== avfxRoot, !structural.contains(block.tag), block.children != nil,
           !AvfxCatalog.curveClasses.contains(cls ?? "") {
            let title = node.title
            actions.append(NodeAction(id: node.id + "!remove", title: "Remove from File", symbol: "minus.circle", destructive: true) { [weak self] in
                self?.removeChild(block, from: parent, title: "Remove " + title)
            })
        }
        for child in block.children ?? [] {
            guard let target = EffectDocument.indexListTarget(child, cls: cls), child.data.count < 255 else { continue }
            let title = target == "Tex" ? "Add Mask Texture" : "Add Model Slot"
            actions.append(NodeAction(id: node.id + "!list" + child.tag, title: title, symbol: "plus") { [weak self] in
                self?.performStructural(title) { child.data.append(255) }
            })
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
            for (t, timeline) in root.childrenNamed("TmLn").enumerated() {
                let effectors = root.childrenNamed("Efct").count
                let missing = timeline.ownRecords("Item").contains { record in
                    func value(_ tag: String) -> Int? { record.first { $0.tag == tag }?.intValue }
                    let effector = value("EfNo") ?? -1
                    return (value("EmNo") ?? -1) < 0 && (value("ClNo") ?? -1) < 0 && !(effector >= 0 && effector < effectors)
                }
                if missing { notes.append("Timeline \(t) is missing a value: one of its items has no emitter, clip or effector") }
            }
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
