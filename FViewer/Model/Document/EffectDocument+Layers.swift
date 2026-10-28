import AppKit

extension EffectDocument {
    func freshTopLevel(_ tag: String) -> AvfxBlock? {
        guard let kind = EffectDocument.addableKinds.first(where: { $0.tag == tag }) else { return nil }
        if tag == "Tex" { return AvfxBlock(tag: "Tex", data: Array("vfx/common/texture/new_texture.atex".utf8) + [0]) }
        if tag == "Modl" { return AvfxBlock(tag: "Modl", children: []) }
        guard let block = AvfxBlock.template(kind.template) else { return nil }
        if let color = block.child("Col"), color.children == nil, color.data.isEmpty, let at = block.children?.firstIndex(where: { $0 === color }) {
            block.remove(color)
            block.insert(AvfxBlock.curveColor(tag: "Col"), at: at)
        }
        return block
    }

    @discardableResult func insertFresh(_ block: AvfxBlock, into root: AvfxBlock) -> Int {
        root.insertTopLevel(block)
        for reference in EffectDocument.nodeReferences(block) where reference.get() >= root.childrenNamed(reference.target).count {
            reference.set(-1)
        }
        return root.childrenNamed(block.tag).count - 1
    }

    func addLayer(to timeline: Int? = nil) {
        guard let root = avfxRoot, let schedule = root.child("Schd"), let particle = freshTopLevel("Ptcl"), let emitter = freshTopLevel("Emit") else { return }
        let target = timeline ?? layerTimelineIndex(root, schedule)
        var particleIndex = 0
        batch("Add Layer") {
            particleIndex = insertFresh(particle, into: root)
            shapeLayerParticle(particle)
            let emitterIndex = insertFresh(emitter, into: root)
            var item = defaultRecord("AvfxEmitterItem")
            setRecordField(&item, "bEnb", 1)
            setRecordField(&item, "TgtB", particleIndex)
            emitter.setOwnRecords("ItPr", [item])
            appendRunningItem(root, timeline: target ?? startNewTimeline(root, schedule), emitter: emitterIndex)
        }
        selectionID = "avfx/Ptcl/\(particleIndex)"
    }

    func addEmitterItem(to timeline: Int, emitter: Int) {
        guard let root = avfxRoot else { return }
        batch("Add Item") { appendRunningItem(root, timeline: timeline, emitter: emitter) }
    }

    private func appendRunningItem(_ root: AvfxBlock, timeline index: Int, emitter: Int) {
        let timelines = root.childrenNamed("TmLn"), emitters = root.childrenNamed("Emit")
        guard timelines.indices.contains(index), emitters.indices.contains(emitter) else { return }
        let timeline = timelines[index]
        let life = emitters[emitter].child("Life").map { $0.children == nil ? $0.intValue : Int($0.float("Val")) } ?? 60
        var record = defaultRecord("AvfxTimelineItem")
        setRecordField(&record, "bEna", 1)
        setRecordField(&record, "StTm", 0)
        setRecordField(&record, "EdTm", life > 0 ? life : 60)
        setRecordField(&record, "EmNo", emitter)
        setRecordField(&record, "BdNo", layerBinderIndex(root))
        timeline.setOwnRecords("Item", timeline.ownRecords("Item") + [record])
    }

    func referencedIndices(_ root: AvfxBlock) -> [String: Set<Int>] {
        var used: [String: Set<Int>] = ["Ptcl": [], "Emit": [], "TmLn": [], "Tex": []]
        for block in root.children ?? [] where AvfxBlock.topOrder.contains(block.tag) {
            for reference in EffectDocument.nodeReferences(block) where used[reference.target] != nil {
                let value = reference.get()
                if value >= 0 { used[reference.target]?.insert(value) }
            }
        }
        return used
    }

    func users(of tag: String, index: Int) -> [String] {
        guard let root = avfxRoot else { return [] }
        var result: [String] = []
        for owner in AvfxBlock.topOrder {
            for (position, block) in root.childrenNamed(owner).enumerated()
            where EffectDocument.nodeReferences(block).contains(where: { $0.target == tag && $0.get() == index }) {
                result.append(owner == "Schd" ? "the Scheduler" : "\(EffectDocument.kindTitles[owner] ?? owner) \(position)")
            }
        }
        return result
    }

    func confirmDelete(_ block: AvfxBlock, title: String) {
        guard let index = avfxRoot?.childrenNamed(block.tag).firstIndex(where: { $0 === block }) else { return }
        let users = users(of: block.tag, index: index)
        if !users.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Delete \(title)?"
            alert.informativeText = "Used by " + users.joined(separator: ", ") + ". Their links to it become None, and links to the items after it move down by one."
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }
        deleteTopLevel(block)
    }

    static let gameLimits: [String: Int] = ["Emit": 68, "Ptcl": 96]
    static let timelineItemLimit = 32
    static let polylinePointLimit = 64
    static let curveKeyLimit = 120

    func chainWarnings(_ root: AvfxBlock) -> [String: [String]] {
        var notes: [String: [String]] = [:]
        func note(_ id: String, _ text: String) { notes[id, default: []].append(text) }
        func on(_ record: [AvfxBlock], _ tag: String) -> Bool { record.first { $0.tag == tag }?.data.first.map { $0 != 0 } ?? false }
        func int(_ record: [AvfxBlock], _ tag: String) -> Int { record.first { $0.tag == tag }?.intValue ?? -1 }
        for (index, emitter) in root.childrenNamed("Emit").enumerated() {
            let id = "avfx/Emit/\(index)"
            let particles = emitter.ownRecords("ItPr"), children = emitter.ownRecords("ItEm")
            if particles.isEmpty && children.isEmpty && emitter.int("EfNo", -1) < 0 && emitter.int("SdNo", -1) < 0 {
                note(id, "Creates nothing: add a particle to Create Particles")
            }
            let rate = emitter.child("CrC")?.curveKeys ?? []
            let rateZero = !rate.isEmpty && rate.allSatisfy { $0.z == 0 }
            for (list, records, kind) in [("ItPr", particles, "particle"), ("ItEm", children, "emitter")] {
                for (k, record) in records.enumerated() {
                    let item = "\(id)/\(list)/\(k)"
                    let mode = int(record, "CrTm")
                    if int(record, "TgtB") < 0 { note(item, "Creates no \(kind): pick its target") }
                    if !on(record, "bEnb") { note(item, "Off, but the game creates it anyway") }
                    if mode != 0, int(record, "CrCn") == 0 { note(item, "Create Count 0: creates nothing") }
                    if mode == 0, rateZero { note(item, "The emitter's Create Count is 0 all the time: creates nothing") }
                    if int(record, "PrLk") >= 0, int(record, "GenD") > 0, mode != 0 { note(item, "Parameter Link is ignored with Generate Delay above 0") }
                }
            }
        }
        for (index, timeline) in root.childrenNamed("TmLn").enumerated() {
            let id = "avfx/TmLn/\(index)"
            let items = timeline.ownRecords("Item")
            if items.count > EffectDocument.timelineItemLimit {
                note(id, "\(items.count) items: the game runs only the first \(EffectDocument.timelineItemLimit)")
            }
            let running = items.filter { on($0, "bEna") && int($0, "EmNo") >= 0 }
            if running.contains(where: { int($0, "BdNo") < 0 }), running.contains(where: { int($0, "BdNo") >= 0 }) {
                note(id, "Some items have a binder and some do not: spawned on a character the ones without are not drawn, on the ground the others")
            }
            let clips = timeline.childrenNamed("Clip").count
            for (k, item) in items.enumerated() where on(item, "bEna") && int(item, "EmNo") < 0 && int(item, "EfNo") < 0 && !(0..<clips).contains(int(item, "ClNo")) {
                note("\(id)/Item/\(k)", "Enabled, but runs no emitter or effector")
            }
            if items.isEmpty { note(id, "Has no items: add a layer with the + on its timeline row") }
        }
        for (index, particle) in root.childrenNamed("Ptcl").enumerated() where particle.int("PrVT") == 6 {
            let points = particle.child("Data")?.int("PnC") ?? 0
            if points > EffectDocument.polylinePointLimit {
                note("avfx/Ptcl/\(index)", "Point Count \(points): more than \(EffectDocument.polylinePointLimit) crashed the game (\(EffectDocument.polylinePointLimit) is the largest in game files)")
            }
        }
        let models = root.childrenNamed("Modl")
        let ownLight = root.childrenNamed("Efct").contains { $0.int("EfVT") == 1 }
        for (index, particle) in root.childrenNamed("Ptcl").enumerated() {
            let id = "avfx/Ptcl/\(index)", data = particle.child("Data")
            switch particle.int("PrVT") {
            case 5:
                if let data, data.child("bLgt")?.data.first.map({ $0 != 0 }) == true, root.int("DLST") == 1, !ownLight {
                    note(id, "Lit, but the effect has no Directional Light effector of its own (Directional Light Source InLocal): the model is drawn black")
                }
                if let model = data?.child("MdNo")?.data.first, model != 255, Int(model) < models.count, (models[Int(model)].child("VDrw")?.data.isEmpty ?? true) {
                    note(id, "Its model has emit points only, no mesh: it is not drawn")
                }
            case 3:
                if particle.child("bSCt")?.data.first.map({ $0 == 0 }) ?? true { note(id, "A Line without Simple Animation is never drawn") }
            default:
                break
            }
        }
        for (index, binder) in root.childrenNamed("Bind").enumerated() where binder.int("BnVr") == 2 {
            if let life = binder.child("Life"), life.children == nil, life.intValue < 0 { note("avfx/Bind/\(index)", "A Spline binder with Life −1 builds no path: give it a Life above 0") }
        }
        for tag in ["TmLn", "Emit", "Ptcl", "Efct", "Bind"] {
            for (index, block) in root.childrenNamed(tag).enumerated() {
                var most = 0
                func scan(_ node: AvfxBlock) {
                    if node.tag == "Keys" { most = max(most, node.data.count / 16) }
                    node.children?.forEach(scan)
                }
                scan(block)
                if most > EffectDocument.curveKeyLimit { note("avfx/\(tag)/\(index)", "A curve has \(most) keys: game files have up to ~\(EffectDocument.curveKeyLimit)") }
            }
        }
        for (k, item) in (root.child("Schd")?.ownRecords("Item") ?? []).enumerated() where on(item, "bEna") && int(item, "TlNo") < 0 {
            note("avfx/Schd/0/Item/\(k)", "Enabled, but starts no timeline")
        }
        return notes
    }

    func applyChainWarnings(_ nodes: [OutlineNode], _ root: AvfxBlock) {
        let notes = chainWarnings(root)
        guard !notes.isEmpty else { return }
        func visit(_ node: OutlineNode) {
            if let texts = notes[node.id] { node.warning = ([node.warning].compactMap { $0 } + texts).joined(separator: "\n") }
            node.children.forEach(visit)
        }
        nodes.forEach(visit)
    }

    func markUnused(_ node: OutlineNode, tag: String, index: Int) {
        switch tag {
        case "Ptcl":
            node.warning = "No emitter creates this particle, so it never appears"
            node.actions.insert(NodeAction(id: node.id + "!run", title: "Create with New Emitter", symbol: "play") { [weak self] in self?.runParticle(index) }, at: 0)
        case "Emit":
            node.warning = "No timeline item or emitter runs this emitter, so it never starts"
            node.actions.insert(NodeAction(id: node.id + "!run", title: "Run on a Timeline", symbol: "play") { [weak self] in self?.runEmitter(index) }, at: 0)
        case "TmLn":
            node.warning = "No scheduler item or trigger starts this timeline"
            node.actions.insert(NodeAction(id: node.id + "!run", title: "Start with the Effect", symbol: "play") { [weak self] in self?.startTimeline(index) }, at: 0)
        case "Tex":
            node.warning = "No particle layer uses this texture"
        default:
            break
        }
    }

    func runParticle(_ index: Int) {
        guard let root = avfxRoot, let schedule = root.child("Schd"), let emitter = freshTopLevel("Emit") else { return }
        let target = layerTimelineIndex(root, schedule)
        batch("Create with New Emitter") {
            let emitterIndex = insertFresh(emitter, into: root)
            var item = defaultRecord("AvfxEmitterItem")
            setRecordField(&item, "bEnb", 1)
            setRecordField(&item, "TgtB", index)
            emitter.setOwnRecords("ItPr", [item])
            appendRunningItem(root, timeline: target ?? startNewTimeline(root, schedule), emitter: emitterIndex)
        }
    }

    func runEmitter(_ index: Int) {
        guard let root = avfxRoot, let schedule = root.child("Schd") else { return }
        let target = layerTimelineIndex(root, schedule)
        batch("Run on a Timeline") { appendRunningItem(root, timeline: target ?? startNewTimeline(root, schedule), emitter: index) }
    }

    func startTimeline(_ index: Int) {
        guard let schedule = avfxRoot?.child("Schd") else { return }
        batch("Start with the Effect") {
            var item = defaultRecord("AvfxSchedulerItem")
            setRecordField(&item, "bEna", 1)
            setRecordField(&item, "StTm", 0)
            setRecordField(&item, "TlNo", index)
            schedule.setOwnRecords("Item", schedule.ownRecords("Item") + [item])
        }
    }

    func linkedAddActions(_ owner: AvfxBlock, list: String, groupID: String) -> [NodeAction] {
        switch (owner.tag, list) {
        case ("Emit", "ItPr"):
            return [NodeAction(id: groupID + "!newptcl", title: "New Particle", symbol: "sparkle") { [weak self] in self?.addParticleItem(to: owner) }]
        case ("Emit", "ItEm"):
            return [NodeAction(id: groupID + "!newemit", title: "New Child Emitter", symbol: "dot.radiowaves.left.and.right") { [weak self] in self?.addChildEmitter(to: owner) }]
        case ("Schd", "Item"):
            return [NodeAction(id: groupID + "!newtl", title: "New Timeline", symbol: "film") { [weak self] in self?.addScheduledTimeline() }]
        default:
            return []
        }
    }

    func addParticleItem(to emitter: AvfxBlock) {
        guard let root = avfxRoot, let particle = freshTopLevel("Ptcl") else { return }
        var particleIndex = 0
        batch("New Particle") {
            particleIndex = insertFresh(particle, into: root)
            shapeLayerParticle(particle)
            var item = defaultRecord("AvfxEmitterItem")
            setRecordField(&item, "bEnb", 1)
            setRecordField(&item, "TgtB", particleIndex)
            emitter.setOwnRecords("ItPr", emitter.ownRecords("ItPr") + [item])
        }
        selectionID = "avfx/Ptcl/\(particleIndex)"
    }

    func addChildEmitter(to parent: AvfxBlock) {
        guard let root = avfxRoot, let particle = freshTopLevel("Ptcl"), let emitter = freshTopLevel("Emit") else { return }
        var emitterIndex = 0
        batch("New Child Emitter") {
            let particleIndex = insertFresh(particle, into: root)
            shapeLayerParticle(particle)
            emitterIndex = insertFresh(emitter, into: root)
            var item = defaultRecord("AvfxEmitterItem")
            setRecordField(&item, "bEnb", 1)
            setRecordField(&item, "TgtB", particleIndex)
            emitter.setOwnRecords("ItPr", [item])
            var child = defaultRecord("AvfxEmitterItem")
            setRecordField(&child, "bEnb", 1)
            setRecordField(&child, "TgtB", emitterIndex)
            parent.setOwnRecords("ItEm", parent.ownRecords("ItEm") + [child])
        }
        selectionID = "avfx/Emit/\(emitterIndex)"
    }

    func addScheduledTimeline() {
        guard let root = avfxRoot, let schedule = root.child("Schd") else { return }
        var index = 0
        batch("New Timeline") { index = startNewTimeline(root, schedule) }
        selectionID = "avfx/TmLn/\(index)"
    }

    private func setRecordField(_ record: inout [AvfxBlock], _ tag: String, _ value: Int) {
        guard let field = record.first(where: { $0.tag == tag }) else { return }
        if field.data.count >= 4 { field.intValue = value } else { field.referenceValue = value }
    }

    private func layerTimelineIndex(_ root: AvfxBlock, _ schedule: AvfxBlock) -> Int? {
        let timelines = root.childrenNamed("TmLn").count
        if let selected = selectionID, selected.hasPrefix("avfx/TmLn/"),
           let index = Int(selected.dropFirst("avfx/TmLn/".count).prefix { $0.isNumber }), index < timelines { return index }
        for record in schedule.ownRecords("Item") {
            let enabled = record.first { $0.tag == "bEna" }.map { $0.data.first != 0 } ?? true
            if enabled, let index = record.first(where: { $0.tag == "TlNo" })?.intValue, index >= 0, index < timelines { return index }
        }
        return nil
    }

    private func startNewTimeline(_ root: AvfxBlock, _ schedule: AvfxBlock) -> Int {
        guard let timeline = freshTopLevel("TmLn") else { return -1 }
        let index = insertFresh(timeline, into: root)
        var item = defaultRecord("AvfxSchedulerItem")
        setRecordField(&item, "bEna", 1)
        setRecordField(&item, "StTm", 0)
        setRecordField(&item, "TlNo", index)
        schedule.setOwnRecords("Item", schedule.ownRecords("Item") + [item])
        return index
    }

    private func layerBinderIndex(_ root: AvfxBlock) -> Int {
        if !root.childrenNamed("Bind").isEmpty { return 0 }
        guard let binder = freshTopLevel("Bind") else { return -1 }
        return insertFresh(binder, into: root)
    }

    private func shapeLayerParticle(_ particle: AvfxBlock) {
        if let typeField = particle.child("PrVT") { applyType(typeField, ownerClass: "AvfxParticle", value: 8) }
        particle.child("RBDT")?.intValue = 6
        particle.child("CulT")?.intValue = 0
        putCurve(AvfxBlock.curveAxes(tag: "Scl", axes: ["X", "Y", "Z"], value: 1), into: particle, cls: "AvfxParticle")
        let life = max(1, Int(particle.child("Life")?.float("Val") ?? 40))
        if let alpha = particle.child("Col")?.child("A") {
            alpha.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: 1), AvfxKey(time: life, type: 1, x: 1, y: 1, z: 0)]
        }
    }

    func putCurve(_ curve: AvfxBlock, into owner: AvfxBlock, cls: String) {
        var list = owner.children ?? []
        if let at = list.firstIndex(where: { $0.tag == curve.tag }) {
            curve.parent = owner
            list[at] = curve
            owner.children = list
            return
        }
        let order = (catalog.classes[cls] ?? []).map(\.tag)
        let rank = order.firstIndex(of: curve.tag) ?? order.count
        let earlier = Set(order.prefix(rank))
        let position = (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? list.count
        owner.insert(curve, at: position)
    }
}

extension EffectDocument {
    static let textureLayerTags: Set<String> = ["TC1", "TC2", "TC3", "TC4", "TD", "TN", "TR", "TP"]

    static func isTextureLayer(_ block: AvfxBlock) -> Bool {
        block.children != nil && textureLayerTags.contains(block.tag) && block.parent?.tag == "Ptcl"
    }

    func layerTexture(_ layer: AvfxBlock) -> Int {
        if layer.tag == "TC1" {
            guard let list = layer.child("TLst"), let first = list.data.first else { return -1 }
            return first == 255 ? -1 : Int(first)
        }
        return layer.child("TxNo")?.intValue ?? -1
    }

    func setLayerTexture(_ layer: AvfxBlock, index: Int) {
        guard index != layerTexture(layer) else { return }
        batch("Set Texture") { writeLayerTexture(layer, index: index) }
    }

    func setLayerTexture(_ layer: AvfxBlock, path: String) {
        guard let root = avfxRoot else { return }
        batch("Set Texture") {
            let lower = path.lowercased()
            var index = root.childrenNamed("Tex").firstIndex { $0.stringValue.lowercased() == lower }
            if index == nil {
                index = insertFresh(AvfxBlock(tag: "Tex", data: Array(path.utf8) + [0]), into: root)
            }
            if let index { writeLayerTexture(layer, index: index) }
        }
    }

    func writeLayerTexture(_ layer: AvfxBlock, index: Int) {
        let byte: UInt8 = index < 0 ? 255 : UInt8(truncatingIfNeeded: index)
        if layer.tag == "TC1" {
            if let list = layer.child("TLst"), !list.data.isEmpty {
                list.data[0] = byte
            } else {
                putLeaf(AvfxBlock(tag: "TLst", data: [byte]), into: layer, cls: "AvfxParticleTextureColor1")
            }
            return
        }
        if let field = layer.child("TxNo") {
            field.referenceValue = index
        } else if let cls = AvfxCatalog.particleParts[layer.tag], let field = catalog.field(cls, "TxNo"),
                  let fresh = catalog.freshLeaf(field, in: cls) {
            fresh.referenceValue = index
            putLeaf(fresh, into: layer, cls: cls)
        }
    }

    private func putLeaf(_ leaf: AvfxBlock, into owner: AvfxBlock, cls: String) {
        let order = (catalog.classes[cls] ?? []).map(\.tag)
        let rank = order.firstIndex(of: leaf.tag) ?? order.count
        let earlier = Set(order.prefix(rank))
        let list = owner.children ?? []
        owner.insert(leaf, at: (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? list.count)
    }
}
