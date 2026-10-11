import Foundation
import SwiftUI

struct GraphNode: Identifiable {
    let id: String
    var title: String
    var lines: [String]
    var tint: NodeTint
    var symbol: String
    var column: Int
    var selectable = true
    var visibility: VisibilityKey?
    var texturePath: String?
    var hasOutput = true
}

struct GraphEdge: Identifiable {
    let id: String
    let from: String
    let to: String
    var label = ""
    var dashed = false
    var remove: (() -> Void)?
    var accepts: [String] = []
    var retarget: ((Int, String) -> Void)?
}

struct LinkOption {
    let title: String
    let perform: () -> Void
}

struct EffectGraph {
    var nodes: [GraphNode] = []
    var edges: [GraphEdge] = []
}

extension EffectDocument {
    var graph: EffectGraph {
        if let root = avfxRoot { return avfxGraph(root) }
        if let root = jsonRoot { return pixiGraph(root) }
        return EffectGraph()
    }

    private func lifeText(_ block: AvfxBlock) -> String {
        guard let life = block.child("Life") else { return "Life —" }
        if life.children == nil { return "Life ∞" }
        let value = life.float("Val", -1)
        return value < 0 ? "Life ∞" : "Life \(JSONNode.format(Double(value)))"
    }

    private func avfxGraph(_ root: AvfxBlock) -> EffectGraph {
        var graph = EffectGraph()
        let emitters = root.childrenNamed("Emit")
        let particles = root.childrenNamed("Ptcl")
        let timelines = root.childrenNamed("TmLn")
        var depth = [Int](repeating: 0, count: emitters.count)
        var changed = true
        var guardCount = 0
        while changed && guardCount < emitters.count + 2 {
            changed = false
            guardCount += 1
            for (i, emitter) in emitters.enumerated() {
                for record in emitter.ownRecords("ItEm") {
                    let target = record.first { $0.tag == "TgtB" }?.intValue ?? -1
                    if target >= 0, target < emitters.count, target != i, depth[target] < depth[i] + 1, depth[i] + 1 <= emitters.count {
                        depth[target] = depth[i] + 1
                        changed = true
                    }
                }
            }
        }
        let particleColumn = 3 + (depth.max() ?? 0)
        if let scheduler = root.child("Schd") {
            let id = "avfx/Schd/0"
            graph.nodes.append(GraphNode(id: id, title: "Scheduler", lines: ["\(scheduler.ownRecords("Item").count) items · \(scheduler.ownRecords("Trgr").count) triggers"],
                                         tint: .scheduler, symbol: "calendar", column: 0))
            for (i, record) in scheduler.ownRecords("Item").enumerated() {
                let target = record.first { $0.tag == "TlNo" }?.intValue ?? -1
                guard target >= 0, target < timelines.count else { continue }
                var edge = GraphEdge(id: "\(id)>item\(i)", from: id, to: "avfx/TmLn/\(target)",
                                     label: "frame \(record.first { $0.tag == "StTm" }?.intValue ?? 0)") { [weak self] in
                    self?.changeRecords(scheduler, list: "Item", title: "Remove Link") { if i < $0.count { $0.remove(at: i) } }
                }
                edge.accepts = ["avfx/TmLn/"]
                edge.retarget = recordRetarget(scheduler, "Item", i, "TlNo")
                graph.edges.append(edge)
            }
            var seen: Set<Int> = []
            for (i, record) in scheduler.ownRecords("Trgr").enumerated() {
                let target = record.first { $0.tag == "TlNo" }?.intValue ?? -1
                guard target >= 0, target < timelines.count, seen.insert(target).inserted else { continue }
                var edge = GraphEdge(id: "\(id)>trigger\(i)", from: id, to: "avfx/TmLn/\(target)", label: "trigger \(i)", dashed: true)
                edge.accepts = ["avfx/TmLn/"]
                edge.retarget = recordRetarget(scheduler, "Trgr", i, "TlNo")
                graph.edges.append(edge)
            }
        }
        for (t, timeline) in timelines.enumerated() {
            let id = "avfx/TmLn/\(t)"
            let records = timeline.ownRecords("Item")
            graph.nodes.append(GraphNode(id: id, title: "Timeline \(t)", lines: ["\(records.count) items · \(timeline.childrenNamed("Clip").count) clips"],
                                         tint: .timeline, symbol: "film", column: 1, visibility: .timeline(t)))
            for (i, record) in records.enumerated() {
                let target = record.first { $0.tag == "EmNo" }?.intValue ?? -1
                guard target >= 0, target < emitters.count else { continue }
                let start = record.first { $0.tag == "StTm" }?.intValue ?? 0
                let end = record.first { $0.tag == "EdTm" }?.intValue ?? 0
                var edge = GraphEdge(id: "\(id)>item\(i)", from: id, to: "avfx/Emit/\(target)", label: "\(start)–\(end)") { [weak self] in
                    self?.changeRecords(timeline, list: "Item", title: "Remove Link") { if i < $0.count { $0.remove(at: i) } }
                }
                edge.accepts = ["avfx/Emit/"]
                edge.retarget = recordRetarget(timeline, "Item", i, "EmNo")
                graph.edges.append(edge)
            }
            let binder = timeline.int("BnNo", -1)
            if binder >= 0, binder < root.childrenNamed("Bind").count {
                graph.edges.append(fieldEdge(id: "\(id)>binder", from: id, to: "avfx/Bind/\(binder)", label: "", field: timeline.child("BnNo"), accepts: "avfx/Bind/"))
            }
        }
        for (e, emitter) in emitters.enumerated() {
            let id = "avfx/Emit/\(e)"
            let particleRecords = emitter.ownRecords("ItPr")
            let emitterRecords = emitter.ownRecords("ItEm")
            graph.nodes.append(GraphNode(id: id, title: "Emitter \(e)",
                                         lines: [catalog.enumCaseName("EmitterType", emitter.int("EVT")) ?? "", lifeText(emitter),
                                                 "\(particleRecords.count) particles · \(emitterRecords.count) emitters"],
                                         tint: .emitter, symbol: "dot.radiowaves.left.and.right", column: 2 + depth[e], visibility: .emitter(e)))
            for (i, record) in particleRecords.enumerated() {
                let target = record.first { $0.tag == "TgtB" }?.intValue ?? -1
                guard target >= 0, target < particles.count else { continue }
                let count = record.first { $0.tag == "CrCn" }?.intValue ?? 1
                var edge = GraphEdge(id: "\(id)>particle\(i)", from: id, to: "avfx/Ptcl/\(target)", label: count > 1 ? "×\(count)" : "") { [weak self] in
                    self?.changeRecords(emitter, list: "ItPr", title: "Remove Link") { if i < $0.count { $0.remove(at: i) } }
                }
                edge.accepts = ["avfx/Ptcl/"]
                edge.retarget = recordRetarget(emitter, "ItPr", i, "TgtB")
                graph.edges.append(edge)
            }
            for (i, record) in emitterRecords.enumerated() {
                let target = record.first { $0.tag == "TgtB" }?.intValue ?? -1
                guard target >= 0, target < emitters.count else { continue }
                let count = record.first { $0.tag == "CrCn" }?.intValue ?? 1
                var edge = GraphEdge(id: "\(id)>emitter\(i)", from: id, to: "avfx/Emit/\(target)", label: count > 1 ? "×\(count)" : "") { [weak self] in
                    self?.changeRecords(emitter, list: "ItEm", title: "Remove Link") { if i < $0.count { $0.remove(at: i) } }
                }
                edge.accepts = ["avfx/Emit/"]
                edge.retarget = recordRetarget(emitter, "ItEm", i, "TgtB")
                graph.edges.append(edge)
            }
            let effector = emitter.int("EfNo", -1)
            if effector >= 0, effector < root.childrenNamed("Efct").count {
                graph.edges.append(fieldEdge(id: "\(id)>effector", from: id, to: "avfx/Efct/\(effector)", label: "", field: emitter.child("EfNo"), accepts: "avfx/Efct/"))
            }
            if emitter.int("EVT") == 5, let model = emitter.child("Data")?.int("MdNo", -1), model >= 0 {
                graph.edges.append(fieldEdge(id: "\(id)>model", from: id, to: "avfx/Modl/\(model)", label: "emit points", field: emitter.child("Data")?.child("MdNo"),
                                             accepts: "avfx/Modl/"))
            }
        }
        let texturePaths = root.childrenNamed("Tex").map(\.stringValue)
        for (p, particle) in particles.enumerated() {
            let id = "avfx/Ptcl/\(p)"
            var type = catalog.enumCaseName("ParticleType", particle.int("PrVT")) ?? ""
            if particle.int("bSCt") != 0 { type += " · Simple" }
            graph.nodes.append(GraphNode(id: id, title: "Particle \(p)",
                                         lines: [type, (catalog.enumCaseName("DrawMode", particle.int("RMT")) ?? "") + " · " + lifeText(particle)],
                                         tint: .particle, symbol: "circle.hexagongrid", column: particleColumn, visibility: .particle(p)))
            for layer in ["TC1", "TC2", "TC3", "TC4", "TD", "TP", "TN", "TR"] {
                guard let block = particle.child(layer), block.int("bEna") != 0, let index = block.child("TxNo") else { continue }
                let texture = index.intValue
                guard texture >= 0, texture < texturePaths.count else { continue }
                var edge = fieldEdge(id: "\(id)>\(layer)", from: id, to: "avfx/Tex/\(texture)", label: layer, field: index, accepts: "avfx/Tex/")
                edge.dashed = false
                graph.edges.append(edge)
            }
            if let data = particle.child("Data") {
                var model = data.int("MNO", -1)
                if let list = data.child("MdNo"), let first = list.data.first { model = first == 255 ? -1 : Int(first) }
                if model >= 0, [5, 13].contains(particle.int("PrVT")) {
                    var edge = GraphEdge(id: "\(id)>model", from: id, to: "avfx/Modl/\(model)", label: "mesh", dashed: true)
                    edge.accepts = ["avfx/Modl/"]
                    edge.retarget = { [weak self] target, _ in
                        self?.performStructural("Relink Model") {
                            if let list = data.child("MdNo"), list.children == nil, !list.data.isEmpty { list.data[0] = UInt8(truncatingIfNeeded: target) }
                            data.child("MNO")?.intValue = target
                        }
                    }
                    graph.edges.append(edge)
                }
            }
        }
        for (i, path) in texturePaths.enumerated() {
            graph.nodes.append(GraphNode(id: "avfx/Tex/\(i)", title: (path as NSString).lastPathComponent, lines: [], tint: .texture, symbol: "photo",
                                         column: particleColumn + 1, texturePath: path, hasOutput: false))
        }
        for (i, model) in root.childrenNamed("Modl").enumerated() {
            let vertices = (model.child("VDrw")?.data.count ?? 0) / 36, emit = (model.child("VEmt")?.data.count ?? 0) / 28
            graph.nodes.append(GraphNode(id: "avfx/Modl/\(i)", title: "Model \(i)", lines: ["\(vertices) verts · \(emit) emit points"], tint: .model,
                                         symbol: "cube", column: particleColumn + 1, hasOutput: false))
        }
        for (i, binder) in root.childrenNamed("Bind").enumerated() {
            let props = binder.child("PrpS")
            graph.nodes.append(GraphNode(id: "avfx/Bind/\(i)", title: "Binder \(i)",
                                         lines: [(catalog.enumCaseName("BinderType", binder.int("BnVr")) ?? "") + " · point \(props?.int("BPID", -1) ?? -1)"],
                                         tint: .binder, symbol: "link", column: 2, hasOutput: false))
        }
        for (i, effector) in root.childrenNamed("Efct").enumerated() {
            graph.nodes.append(GraphNode(id: "avfx/Efct/\(i)", title: "Effector \(i)", lines: [catalog.enumCaseName("EffectorType", effector.int("EfVT")) ?? ""],
                                         tint: .effector, symbol: "lightbulb", column: particleColumn, hasOutput: false))
        }
        return graph
    }

    private func recordRetarget(_ owner: AvfxBlock, _ list: String, _ index: Int, _ field: String) -> (Int, String) -> Void {
        { [weak self] target, _ in
            self?.changeRecords(owner, list: list, title: "Relink") { records in
                guard index < records.count else { return }
                let copy = records[index].map { $0.deepCopy() }
                copy.first { $0.tag == field }?.intValue = target
                records[index] = copy
            }
        }
    }

    private func fieldEdge(id: String, from: String, to: String, label: String, field: AvfxBlock?, accepts: String) -> GraphEdge {
        var edge = GraphEdge(id: id, from: from, to: to, label: label, dashed: true)
        guard let field, field.children == nil, field.data.count >= 4 else { return edge }
        edge.remove = { [weak self] in self?.performStructural("Remove Link") { field.intValue = -1 } }
        edge.accepts = [accepts]
        edge.retarget = { [weak self] target, _ in self?.performStructural("Relink") { field.intValue = target } }
        return edge
    }

    private func pixiGraph(_ root: JSONNode) -> EffectGraph {
        var graph = EffectGraph()
        let emitters = root["emitters"]?.elements ?? []
        let particles = root["particles"]?.elements ?? []
        var emitterIndex: [String: Int] = [:]
        var particleIndex: [String: Int] = [:]
        for (i, e) in emitters.enumerated() { if let id = e["id"]?.string { emitterIndex[id] = i } }
        for (i, p) in particles.enumerated() { if let id = p["id"]?.string { particleIndex[id] = i } }
        var depth = [Int](repeating: 0, count: emitters.count)
        var changed = true
        var guardCount = 0
        while changed && guardCount < emitters.count + 2 {
            changed = false
            guardCount += 1
            for (i, emitter) in emitters.enumerated() {
                for item in emitter["items"]?.elements ?? [] {
                    if let target = item["emitter"]?.string.flatMap({ emitterIndex[$0] }), target != i, depth[target] < depth[i] + 1, depth[i] + 1 <= emitters.count {
                        depth[target] = depth[i] + 1
                        changed = true
                    }
                }
            }
        }
        let particleColumn = 2 + (depth.max() ?? 0)
        func removal(_ array: JSONNode?, _ index: Int) -> (() -> Void)? {
            guard let array else { return nil }
            return { [weak self] in
                self?.performStructural("Remove Link") {
                    guard var items = array.elements, index < items.count else { return }
                    items.remove(at: index)
                    array.value = .array(items)
                }
            }
        }
        for (t, timeline) in (root["timelines"]?.elements ?? []).enumerated() {
            let id = "json/timelines/\(t)"
            let items = timeline["items"]?.elements ?? []
            var lines = ["\(items.count) items · start \(JSONNode.format(timeline["start"]?.number ?? 0))"]
            if let trigger = timeline["trigger"]?.number { lines.append("trigger \(JSONNode.format(trigger))") }
            graph.nodes.append(GraphNode(id: id, title: "Timeline \(t)", lines: lines, tint: .timeline, symbol: "film", column: 0, visibility: .timeline(t)))
            for (i, item) in items.enumerated() {
                guard let target = item["emitter"]?.string.flatMap({ emitterIndex[$0] }) else { continue }
                var edge = GraphEdge(id: "\(id)>\(i)", from: id, to: "json/emitters/\(target)",
                                     label: item["start"]?.number.map { "frame " + JSONNode.format($0) } ?? "", remove: removal(timeline["items"], i))
                edge.accepts = ["json/emitters/"]
                edge.retarget = { [weak self] index, _ in
                    guard index < emitters.count, let name = emitters[index]["id"]?.string else { return }
                    self?.performStructural("Relink") { item.set("emitter", JSONNode(.string(name))) }
                }
                graph.edges.append(edge)
            }
        }
        for (e, emitter) in emitters.enumerated() {
            let id = "json/emitters/\(e)"
            let items = emitter["items"]?.elements ?? []
            let life = emitter["life"]?.number ?? -1
            graph.nodes.append(GraphNode(id: id, title: emitter["id"]?.string ?? "Emitter \(e)",
                                         lines: [life < 0 ? "Life ∞" : "Life " + JSONNode.format(life), "\(items.count) items"], tint: .emitter,
                                         symbol: "dot.radiowaves.left.and.right", column: 1 + depth[e], visibility: .emitter(e)))
            for (i, item) in items.enumerated() {
                var target: String?
                if let name = item["emitter"]?.string, let index = emitterIndex[name] { target = "json/emitters/\(index)" }
                if let name = item["particle"]?.string, let index = particleIndex[name] { target = "json/particles/\(index)" }
                guard let target else { continue }
                let label = item["repeat"]?.bool == true ? "every " + JSONNode.format(item["interval"]?.number ?? 1) : ""
                var edge = GraphEdge(id: "\(id)>\(i)", from: id, to: target, label: label, remove: removal(emitter["items"], i))
                let key = item["emitter"] != nil ? "emitter" : "particle"
                edge.accepts = [key == "emitter" ? "json/emitters/" : "json/particles/"]
                edge.retarget = { [weak self] index, _ in
                    let list = key == "emitter" ? emitters : particles
                    guard index < list.count, let name = list[index]["id"]?.string else { return }
                    self?.performStructural("Relink") { item.set(key, JSONNode(.string(name))) }
                }
                graph.edges.append(edge)
            }
        }
        var textures: [String] = []
        for (p, particle) in particles.enumerated() {
            let id = "json/particles/\(p)"
            let shape = particle["shape"]?["type"]?.string ?? "quad"
            let life = particle["life"]?.number
            graph.nodes.append(GraphNode(id: id, title: particle["id"]?.string ?? "Particle \(p)",
                                         lines: [shape + " · " + (particle["blend"]?.string ?? "normal"), life.map { "Life " + JSONNode.format($0) } ?? "Life —"],
                                         tint: .particle, symbol: "circle.hexagongrid", column: particleColumn, visibility: .particle(p)))
            var used: [(String, String, JSONNode)] = []
            if let texture = particle["texture"]?.string { used.append((texture, "base", particle)) }
            for (i, layer) in (particle["layers"]?.elements ?? []).enumerated() {
                if let texture = layer["texture"]?.string { used.append((texture, "layer \(i + 1)", layer)) }
            }
            if let holder = particle["distortion"], let texture = holder["texture"]?.string { used.append((texture, "distortion", holder)) }
            for (i, entry) in used.enumerated() {
                if !textures.contains(entry.0) { textures.append(entry.0) }
                var edge = GraphEdge(id: "\(id)>tex\(i)", from: id, to: "tex:" + entry.0, label: entry.1)
                let holder = entry.2
                edge.accepts = ["tex:"]
                edge.retarget = { [weak self] _, target in
                    self?.performStructural("Relink Texture") { holder.set("texture", JSONNode(.string(String(target.dropFirst(4))))) }
                }
                graph.edges.append(edge)
            }
        }
        for name in textures {
            graph.nodes.append(GraphNode(id: "tex:" + name, title: name, lines: [], tint: .texture, symbol: "photo", column: particleColumn + 1,
                                         selectable: false, texturePath: name, hasOutput: false))
        }
        return graph
    }

    private func index(_ id: String, _ prefix: String) -> Int? {
        id.hasPrefix(prefix) ? Int(id.dropFirst(prefix.count)) : nil
    }

    func canRetarget(_ edge: GraphEdge, to target: String) -> Bool {
        edge.retarget != nil && target != edge.to && target != edge.from && edge.accepts.contains { target.hasPrefix($0) }
    }

    func retarget(_ edge: GraphEdge, to target: String) {
        guard canRetarget(edge, to: target), let retarget = edge.retarget else { return }
        let index = Int(target.split(separator: "/").last ?? "") ?? 0
        retarget(index, target)
    }

    static let linkKinds: [(prefix: String, name: String)] = [
        ("avfx/Schd", "Scheduler"), ("avfx/TmLn/", "Timeline"), ("avfx/Emit/", "Emitter"), ("avfx/Ptcl/", "Particle"), ("avfx/Efct/", "Effector"),
        ("avfx/Bind/", "Binder"), ("avfx/Tex/", "Texture"), ("avfx/Modl/", "Model"), ("json/timelines/", "Timeline"), ("json/emitters/", "Emitter"),
        ("json/particles/", "Particle"), ("tex:", "Texture"),
    ]

    static func linkKind(_ id: String) -> String { linkKinds.first { id.hasPrefix($0.prefix) }?.name ?? "Node" }

    private func linkPairAllowed(_ from: String, _ to: String) -> Bool {
        let pairs: [(String, [String])] = [
            ("avfx/Schd", ["avfx/TmLn/"]), ("avfx/TmLn/", ["avfx/Emit/", "avfx/Bind/"]),
            ("avfx/Emit/", ["avfx/Emit/", "avfx/Ptcl/", "avfx/Efct/", "avfx/Modl/"]), ("avfx/Ptcl/", ["avfx/Tex/", "avfx/Modl/"]),
            ("json/timelines/", ["json/emitters/"]), ("json/emitters/", ["json/emitters/", "json/particles/"]), ("json/particles/", ["tex:"]),
        ]
        return from != to && pairs.contains { from.hasPrefix($0.0) && $0.1.contains { to.hasPrefix($0) } }
    }

    func linkDirection(_ a: String, _ b: String) -> (from: String, to: String)? {
        if linkPairAllowed(a, b) { return (a, b) }
        if linkPairAllowed(b, a) { return (b, a) }
        return nil
    }

    func canConnect(from: String, to: String) -> Bool { linkDirection(from, to) != nil }

    func linkOptions(_ a: String, _ b: String) -> (options: [LinkOption], problem: String?) {
        guard a != b else { return ([], nil) }
        guard let pair = linkDirection(a, b) else {
            return ([], "\(EffectDocument.linkKind(a)) and \(EffectDocument.linkKind(b)) cannot be linked")
        }
        if let root = avfxRoot { return avfxLinkOptions(root, from: pair.from, to: pair.to) }
        return ([LinkOption(title: "Link") { [weak self] in
            guard let self, let root = self.jsonRoot else { return }
            self.connectPixi(root, from: pair.from, to: pair.to)
        }], nil)
    }

    @discardableResult func connect(from: String, to: String, option: Int = 0) -> String? {
        let result = linkOptions(from, to)
        guard option >= 0, option < result.options.count else { return result.problem ?? "Nothing to link" }
        result.options[option].perform()
        return nil
    }

    private func ensureChild(_ owner: AvfxBlock, _ tag: String, cls: String?) -> AvfxBlock? {
        if let existing = owner.child(tag) { return existing }
        guard let cls, let fields = catalog.classes[cls], let position = fields.firstIndex(where: { $0.tag == tag }),
              let created = catalog.freshBlock(fields[position], in: cls) else { return nil }
        let earlier = Set(fields.prefix(position).map(\.tag))
        let list = owner.children ?? []
        owner.insert(created, at: (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? 0)
        return created
    }

    private func ownerClass(_ id: String) -> String? {
        if case .avfx(_, let cls, _)? = node(id)?.payload { return cls }
        return nil
    }

    private func avfxLinkOptions(_ root: AvfxBlock, from: String, to: String) -> (options: [LinkOption], problem: String?) {
        func one(_ title: String, _ action: @escaping () -> Void) -> (options: [LinkOption], problem: String?) { ([LinkOption(title: title, perform: action)], nil) }
        if from.hasPrefix("avfx/Schd"), let timeline = index(to, "avfx/TmLn/"), let scheduler = root.child("Schd") {
            return one("Schedule Timeline \(timeline)") { [weak self] in
                guard let self else { return }
                self.changeRecords(scheduler, list: "Item", title: "Link Timeline") { $0.append(self.record("AvfxSchedulerItem", ["TlNo": timeline])) }
            }
        }
        if let t = index(from, "avfx/TmLn/"), t < root.childrenNamed("TmLn").count {
            let timeline = root.childrenNamed("TmLn")[t]
            if let emitter = index(to, "avfx/Emit/") {
                return one("Add Emitter \(emitter) to Timeline \(t)") { [weak self] in
                    guard let self else { return }
                    self.changeRecords(timeline, list: "Item", title: "Link Emitter") { $0.append(self.record("AvfxTimelineItem", ["EmNo": emitter])) }
                }
            }
            if let binder = index(to, "avfx/Bind/") {
                let cls = ownerClass(from)
                var options = [LinkOption(title: "Bind the whole timeline") { [weak self] in
                    self?.performStructural("Link Binder") { self?.ensureChild(timeline, "BnNo", cls: cls)?.intValue = binder }
                }]
                for (i, record) in timeline.ownRecords("Item").enumerated() where record.contains(where: { $0.tag == "BdNo" }) {
                    let emitter = record.first { $0.tag == "EmNo" }?.intValue ?? -1
                    options.append(LinkOption(title: "Bind item \(i)" + (emitter >= 0 ? " (Emitter \(emitter))" : "")) { [weak self] in
                        self?.changeRecords(timeline, list: "Item", title: "Link Binder") { records in
                            if i < records.count { records[i].first { $0.tag == "BdNo" }?.intValue = binder }
                        }
                    })
                }
                return (options, nil)
            }
        }
        if let e = index(from, "avfx/Emit/"), e < root.childrenNamed("Emit").count {
            let emitter = root.childrenNamed("Emit")[e]
            if let particle = index(to, "avfx/Ptcl/") {
                return one("Emit Particle \(particle)") { [weak self] in
                    guard let self else { return }
                    self.changeRecords(emitter, list: "ItPr", title: "Link Particle") { $0.append(self.record("AvfxEmitterItem", ["TgtB": particle])) }
                }
            }
            if let child = index(to, "avfx/Emit/") {
                return one("Emit Emitter \(child)") { [weak self] in
                    guard let self else { return }
                    self.changeRecords(emitter, list: "ItEm", title: "Link Emitter") { $0.append(self.record("AvfxEmitterItem", ["TgtB": child])) }
                }
            }
            if let effector = index(to, "avfx/Efct/") {
                let cls = ownerClass(from)
                return one("Use Effector \(effector)") { [weak self] in
                    self?.performStructural("Link Effector") { self?.ensureChild(emitter, "EfNo", cls: cls)?.intValue = effector }
                }
            }
            if let model = index(to, "avfx/Modl/") {
                guard let field = emitter.child("Data")?.child("MdNo"), field.children == nil, field.data.count >= 4 else {
                    return ([], "Emitter \(e) does not emit from a model. Set its type to Model first")
                }
                return one("Emit from Model \(model)") { [weak self] in self?.performStructural("Link Model") { field.intValue = model } }
            }
        }
        if let p = index(from, "avfx/Ptcl/"), p < root.childrenNamed("Ptcl").count {
            let particle = root.childrenNamed("Ptcl")[p]
            if let texture = index(to, "avfx/Tex/") {
                let cls = ownerClass(from)
                let layers = [("TC1", "Color 1"), ("TC2", "Color 2"), ("TC3", "Color 3"), ("TC4", "Color 4"), ("TN", "Normal"), ("TR", "Reflection"),
                              ("TD", "Distortion"), ("TP", "Palette")]
                var options: [LinkOption] = []
                for (tag, name) in layers {
                    let layer = particle.child(tag)
                    let current = layer?.child("TxNo")?.intValue ?? -1
                    let used = layer?.children != nil && current >= 0 && layer?.int("bEna") != 0
                    if used && current == texture { continue }
                    let entry = LinkOption(title: name + (used ? " (now Texture \(current))" : "")) { [weak self] in
                        self?.performStructural("Link Texture") {
                            guard let self, let layerClass = AvfxCatalog.particleParts[tag] else { return }
                            var existing = particle.child(tag)
                            if existing == nil || existing?.children == nil {
                                if let empty = existing { particle.remove(empty) }
                                let fresh = AvfxBlock(tag: tag, children: (self.catalog.classes[layerClass] ?? []).compactMap {
                                    self.catalog.freshBlock($0, in: layerClass)
                                })
                                let order = ["TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP"]
                                let earlier = Set(order.prefix { $0 != tag } + ["Data", "UvSt"])
                                let list = particle.children ?? []
                                particle.insert(fresh, at: (list.lastIndex { earlier.contains($0.tag) }).map { $0 + 1 } ?? list.count)
                                existing = fresh
                            }
                            guard let block = existing else { return }
                            self.ensureChild(block, "TxNo", cls: layerClass)?.intValue = texture
                            self.ensureChild(block, "bEna", cls: layerClass)?.intValue = 1
                        }
                    }
                    if used { options.append(entry) } else { options.insert(entry, at: options.prefix { !$0.title.contains("(now") }.count) }
                }
                return (options, options.isEmpty ? "Particle \(p) already uses this texture on every layer" : nil)
            }
            if let model = index(to, "avfx/Modl/") {
                guard let data = particle.child("Data"), data.child("MdNo") != nil || data.child("MNO") != nil else {
                    return ([], "Particle \(p) is not a model particle. Set its type to Model or Light Model first")
                }
                return one("Use Model \(model)") { [weak self] in
                    self?.performStructural("Link Model") {
                        if let list = data.child("MdNo"), list.data.count < 4 { list.data = [UInt8(truncatingIfNeeded: model)] }
                        data.child("MNO")?.intValue = model
                    }
                }
            }
        }
        return ([], "\(EffectDocument.linkKind(from)) and \(EffectDocument.linkKind(to)) cannot be linked")
    }

    private func record(_ cls: String, _ values: [String: Int]) -> [AvfxBlock] {
        let fields = defaultRecord(cls)
        for field in fields { if let value = values[field.tag] { field.intValue = value } }
        for field in fields where field.tag == "bEna" || field.tag == "bEnb" { field.data = [1] + [UInt8](repeating: 0, count: max(field.data.count - 1, 0)) }
        if cls == "AvfxTimelineItem" { fields.first { $0.tag == "EdTm" }?.intValue = 30 }
        return fields
    }

    private func connectPixi(_ root: JSONNode, from: String, to: String) {
        func append(_ owner: JSONNode?, _ key: String, _ value: String) {
            guard let owner else { return }
            performStructural("Add Link") {
                let item = JSONNode(.object([JSONMember(key: key, node: JSONNode(.string(value)))]))
                if let items = owner["items"], var list = items.elements {
                    list.append(item)
                    items.value = .array(list)
                } else {
                    owner.set("items", JSONNode(.array([item])))
                }
            }
        }
        let emitters = root["emitters"]?.elements ?? []
        let particles = root["particles"]?.elements ?? []
        if let t = index(from, "json/timelines/"), let e = index(to, "json/emitters/"), e < emitters.count, let id = emitters[e]["id"]?.string {
            let timelines = root["timelines"]?.elements ?? []
            append(t < timelines.count ? timelines[t] : nil, "emitter", id)
        } else if let e = index(from, "json/emitters/"), e < emitters.count {
            if let child = index(to, "json/emitters/"), child < emitters.count, let id = emitters[child]["id"]?.string {
                append(emitters[e], "emitter", id)
            } else if let p = index(to, "json/particles/"), p < particles.count, let id = particles[p]["id"]?.string {
                append(emitters[e], "particle", id)
            }
        } else if let p = index(from, "json/particles/"), p < particles.count, to.hasPrefix("tex:") {
            let name = String(to.dropFirst(4))
            performStructural("Set Texture") { particles[p].set("texture", JSONNode(.string(name))) }
        }
    }

    func transformFields(_ block: AvfxBlock, id: String) -> [PropField] {
        let groups: [(tag: String, title: String, fallback: Float, angle: Bool)] = [
            ("Pos", "Position", 0, false), ("Rot", "Rotation", 0, true), ("Scl", "Scale", 1, false),
        ]
        var fields: [PropField] = []
        for group in groups {
            for axis in ["X", "Y", "Z"] {
                let scale: Double = group.angle ? 180 / .pi : 1
                fields.append(PropField(
                    id: "\(id)#transform\(group.tag)\(axis)", label: "\(group.title) \(axis)", tag: group.tag, kind: group.angle ? .angle : .double,
                    read: {
                        let keys = block.child(group.tag)?.child(axis)?.curveKeys ?? []
                        return .double(Double(keys.first?.z ?? group.fallback) * scale)
                    },
                    write: { value in
                        let target = Float(value.number / scale)
                        let current = block.child(group.tag)?.child(axis)?.curveKeys.first?.z ?? group.fallback
                        if abs(Double(current) * scale - value.number) < 1e-9 || target == current { return }
                        var holder = block.child(group.tag)
                        if holder == nil {
                            let created = AvfxBlock.curveAxes(tag: group.tag, axes: ["X", "Y", "Z"], value: group.fallback)
                            let list = block.children ?? []
                            let position = (list.lastIndex { ["Col", "Pos", "Rot", "Scl", "Life"].contains($0.tag) }).map { $0 + 1 } ?? list.count
                            block.insert(created, at: position)
                            holder = created
                        }
                        guard let holder else { return }
                        var curve = holder.child(axis)
                        if curve == nil {
                            let created = AvfxBlock.curveData(tag: axis, value: group.fallback)
                            let list = holder.children ?? []
                            let position = (list.lastIndex { ["ACT", "ACTR", "X", "Y", "Z"].contains($0.tag) && $0.tag <= axis }).map { $0 + 1 } ?? list.count
                            holder.insert(created, at: position)
                            curve = created
                        }
                        guard let curve else { return }
                        var keys = curve.curveKeys
                        if keys.isEmpty {
                            keys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: target)]
                        } else {
                            let delta = target - keys[0].z
                            for i in keys.indices { keys[i].z += delta }
                        }
                        curve.curveKeys = keys
                    }))
            }
        }
        return fields
    }
}
