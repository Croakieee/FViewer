import Foundation
import VfxCore

extension EffectDocument {
    var materialParticleID: String? {
        guard format == .pixi, let selected = selectionID, selected.hasPrefix("json/particles/") else { return nil }
        let id = selected.split(separator: "/").prefix(3).joined(separator: "/")
        return node(id) != nil ? id : nil
    }

    func materialParticle(_ particleID: String) -> JSONNode? {
        if case .json(let json)? = node(particleID)?.payload { return json }
        return nil
    }

    static func parseMaterial(_ material: JSONNode) -> MaterialGraph {
        var nodes: [MaterialNode] = []
        for entry in material["nodes"]?.elements ?? [] {
            guard let id = entry["id"]?.string, let type = entry["type"]?.string else { continue }
            var params: [String: Double] = [:]
            for member in entry["params"]?.members ?? [] { if let value = member.node.number { params[member.key] = value } }
            nodes.append(MaterialNode(id: id, type: type, x: entry["x"]?.number, y: entry["y"]?.number, texture: entry["texture"]?.string,
                                      name: entry["name"]?.string, graph: entry["graph"]?.string, params: params.isEmpty ? nil : params))
        }
        var links: [MaterialLink] = []
        for entry in material["links"]?.elements ?? [] {
            guard let from = entry["from"]?.string, let out = entry["out"]?.string, let to = entry["to"]?.string, let input = entry["in"]?.string else { continue }
            links.append(MaterialLink(from: from, out: out, to: to, input: input))
        }
        return MaterialGraph(nodes: nodes, links: links)
    }

    func materialUse(_ particleID: String) -> String? { materialParticle(particleID)?["material"]?["use"]?.string }

    var sharedMaterialNames: [String] { (jsonRoot?["materials"]?.members ?? []).map(\.key) }

    var sharedMaterials: [String: MaterialGraph] {
        var result: [String: MaterialGraph] = [:]
        for member in jsonRoot?["materials"]?.members ?? [] { result[member.key] = EffectDocument.parseMaterial(member.node) }
        return result
    }

    func materialUsers(_ name: String) -> [String] {
        (0..<(jsonRoot?["particles"]?.elements?.count ?? 0)).map { "json/particles/\($0)" }.filter { materialUse($0) == name }
    }

    func materialGraph(_ particleID: String) -> MaterialGraph? {
        guard let material = materialParticle(particleID)?["material"], material.members != nil else { return nil }
        if let name = material["use"]?.string { return jsonRoot?["materials"]?[name].map(EffectDocument.parseMaterial) }
        return EffectDocument.parseMaterial(material)
    }

    func materialOverrides(_ particleID: String) -> [String: MaterialOverride] {
        var result: [String: MaterialOverride] = [:]
        for member in materialParticle(particleID)?["material"]?["overrides"]?.members ?? [] {
            if let number = member.node.number {
                result[member.key] = .number(number)
            } else if let parts = member.node.elements?.compactMap(\.number), parts.count >= 3 {
                result[member.key] = .color(parts)
            } else if let texture = member.node["texture"]?.string {
                result[member.key] = .texture(texture)
            }
        }
        return result
    }

    func resolvedMaterial(_ particleID: String) -> MaterialGraph? {
        guard let graph = materialGraph(particleID) else { return nil }
        var resolved = graph.applying(materialUse(particleID) == nil ? [:] : materialOverrides(particleID)).expanded(sharedMaterials)
        resolved.light = materialLight
        return resolved
    }

    private func nodeJSON(_ node: MaterialNode) -> JSONNode {
        var members = [JSONMember(key: "id", node: JSONNode(.string(node.id))), JSONMember(key: "type", node: JSONNode(.string(node.type))),
                       JSONMember(key: "x", node: JSONNode(.number((node.x ?? 0).rounded()))), JSONMember(key: "y", node: JSONNode(.number((node.y ?? 0).rounded())))]
        if let texture = node.texture { members.append(JSONMember(key: "texture", node: JSONNode(.string(texture)))) }
        if let name = node.name, !name.isEmpty { members.append(JSONMember(key: "name", node: JSONNode(.string(name)))) }
        if let graph = node.graph, !graph.isEmpty { members.append(JSONMember(key: "graph", node: JSONNode(.string(graph)))) }
        if let params = node.params, !params.isEmpty {
            let order = MaterialGraph.kind(of: node.type)?.params.map(\.name) ?? params.keys.sorted()
            let list = order.compactMap { name in params[name].map { JSONMember(key: name, node: JSONNode(.number($0))) } }
            members.append(JSONMember(key: "params", node: JSONNode(.object(list))))
        }
        return JSONNode(.object(members))
    }

    private func graphJSON(_ graph: MaterialGraph) -> JSONNode {
        let links = graph.links.map { link in
            JSONNode(.object([JSONMember(key: "from", node: JSONNode(.string(link.from))), JSONMember(key: "out", node: JSONNode(.string(link.out))),
                              JSONMember(key: "to", node: JSONNode(.string(link.to))), JSONMember(key: "in", node: JSONNode(.string(link.input)))]))
        }
        return JSONNode(.object([JSONMember(key: "nodes", node: JSONNode(.array(graph.nodes.map(nodeJSON)))), JSONMember(key: "links", node: JSONNode(.array(links)))]))
    }

    private func setSharedMaterial(_ name: String, _ graph: MaterialGraph?) {
        guard let root = jsonRoot else { return }
        var members = root["materials"]?.members ?? []
        members.removeAll { $0.key == name }
        if let graph { members.append(JSONMember(key: name, node: graphJSON(graph))) }
        if members.isEmpty {
            if var all = root.members {
                all.removeAll { $0.key == "materials" }
                root.value = .object(all)
            }
        } else {
            root.set("materials", JSONNode(.object(members)))
        }
    }

    func writeMaterial(_ graph: MaterialGraph, to particleID: String) {
        guard let particle = materialParticle(particleID) else { return }
        if let name = materialUse(particleID) {
            setSharedMaterial(name, graph)
        } else {
            particle.set("material", graphJSON(graph))
        }
    }

    func setMaterialOverride(_ name: String, _ value: JSONNode?, in particleID: String) {
        guard let particle = materialParticle(particleID), let use = materialUse(particleID) else { return }
        let before = snapshot()
        var members = particle["material"]?["overrides"]?.members ?? []
        members.removeAll { $0.key == name }
        if let value { members.append(JSONMember(key: name, node: value)) }
        var material = [JSONMember(key: "use", node: JSONNode(.string(use)))]
        if !members.isEmpty { material.append(JSONMember(key: "overrides", node: JSONNode(.object(members)))) }
        particle.set("material", JSONNode(.object(material)))
        registerUndo(value == nil ? "Reset " + name : "Set " + name, since: before)
    }

    func shareMaterial(_ rawName: String, in particleID: String) {
        let name = rawName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, materialUse(particleID) == nil, let graph = materialGraph(particleID), let particle = materialParticle(particleID),
              !sharedMaterialNames.contains(name) else { return }
        let before = snapshot()
        setSharedMaterial(name, graph)
        particle.set("material", JSONNode(.object([JSONMember(key: "use", node: JSONNode(.string(name)))])))
        registerUndo("Share Material", since: before)
    }

    func useSharedMaterial(_ name: String, in particleID: String) {
        guard let particle = materialParticle(particleID), sharedMaterialNames.contains(name), materialUse(particleID) != name else { return }
        let before = snapshot()
        particle.set("material", JSONNode(.object([JSONMember(key: "use", node: JSONNode(.string(name)))])))
        registerUndo("Use Material " + name, since: before)
    }

    func makeMaterialUnique(in particleID: String) {
        guard let particle = materialParticle(particleID), let name = materialUse(particleID), let graph = materialGraph(particleID) else { return }
        let before = snapshot()
        particle.set("material", graphJSON(graph.applying(materialOverrides(particleID))))
        if materialUsers(name).isEmpty { setSharedMaterial(name, nil) }
        registerUndo("Make Material Unique", since: before)
    }

    func editMaterial(_ title: String, in particleID: String, _ edit: (inout MaterialGraph) -> Void) {
        guard var graph = materialGraph(particleID) else { return }
        let before = snapshot()
        edit(&graph)
        writeMaterial(graph, to: particleID)
        registerUndo(title, since: before)
    }

    func createMaterial(in particleID: String) {
        guard let particle = materialParticle(particleID), particle["material"] == nil else { return }
        let before = snapshot()
        let graph = MaterialGraph(nodes: [MaterialNode(id: "layers", type: "layers", x: 60, y: 80), MaterialNode(id: "output", type: "output", x: 420, y: 80)],
                                  links: [MaterialLink(from: "layers", out: "rgb", to: "output", input: "color"),
                                          MaterialLink(from: "layers", out: "a", to: "output", input: "alpha")])
        writeMaterial(graph, to: particleID)
        registerUndo("New Material", since: before)
    }

    func removeMaterial(in particleID: String) {
        guard let particle = materialParticle(particleID), var members = particle.members, members.contains(where: { $0.key == "material" }) else { return }
        let before = snapshot()
        members.removeAll { $0.key == "material" }
        particle.value = .object(members)
        registerUndo("Remove Material", since: before)
    }

    @discardableResult func addMaterialNode(_ type: String, at point: CGPoint, in particleID: String) -> String? {
        guard let kind = MaterialGraph.kind(of: type), let graph = materialGraph(particleID) else { return nil }
        if type == "output", graph.nodes.contains(where: { $0.type == "output" }) { return nil }
        var index = graph.nodes.count + 1
        while graph.nodes.contains(where: { $0.id == "\(type)\(index)" }) { index += 1 }
        let id = "\(type)\(index)"
        var params: [String: Double] = [:]
        for entry in kind.params { params[entry.name] = entry.value }
        let texture = kind.texture ? textureSlots.first?.name : nil
        editMaterial("Add " + kind.title, in: particleID) { graph in
            graph.nodes.append(MaterialNode(id: id, type: type, x: Double(point.x), y: Double(point.y), texture: texture, params: params.isEmpty ? nil : params))
        }
        return id
    }

    func removeMaterialNode(_ id: String, in particleID: String) {
        guard let graph = materialGraph(particleID), let node = graph.nodes.first(where: { $0.id == id }), node.type != "output" else { return }
        editMaterial("Delete " + (MaterialGraph.kind(of: node.type)?.title ?? "Node"), in: particleID) { graph in
            graph.nodes.removeAll { $0.id == id }
            graph.links.removeAll { $0.from == id || $0.to == id }
        }
    }

    func connectMaterial(from: String, out: String, to: String, input: String, in particleID: String) {
        guard from != to else { return }
        editMaterial("Connect", in: particleID) { graph in
            graph.links.removeAll { $0.to == to && $0.input == input }
            graph.links.append(MaterialLink(from: from, out: out, to: to, input: input))
        }
    }

    func disconnectMaterial(to: String, input: String, in particleID: String) {
        guard materialGraph(particleID)?.links.contains(where: { $0.to == to && $0.input == input }) == true else { return }
        editMaterial("Disconnect", in: particleID) { graph in graph.links.removeAll { $0.to == to && $0.input == input } }
    }

    func freshMaterialID(_ type: String, in graph: MaterialGraph) -> String {
        var index = graph.nodes.count + 1
        while graph.nodes.contains(where: { $0.id == "\(type)\(index)" }) { index += 1 }
        return "\(type)\(index)"
    }

    @discardableResult func insertMaterialNodes(_ source: MaterialGraph, offset: CGSize, title: String, in particleID: String) -> [String] {
        guard materialGraph(particleID) != nil else { return [] }
        var fresh: [String] = []
        editMaterial(title, in: particleID) { graph in
            var renamed: [String: String] = [:]
            for node in source.nodes where node.type != "output" {
                var copy = node
                copy.id = freshMaterialID(node.type, in: graph)
                copy.x = (node.x ?? 0) + Double(offset.width)
                copy.y = (node.y ?? 0) + Double(offset.height)
                renamed[node.id] = copy.id
                graph.nodes.append(copy)
                fresh.append(copy.id)
            }
            for link in source.links {
                guard let from = renamed[link.from], let to = renamed[link.to] else { continue }
                graph.links.append(MaterialLink(from: from, out: link.out, to: to, input: link.input))
            }
        }
        return fresh
    }

    func materialSubgraph(_ ids: Set<String>, in particleID: String) -> MaterialGraph? {
        guard let graph = materialGraph(particleID) else { return nil }
        let nodes = graph.nodes.filter { ids.contains($0.id) && $0.type != "output" }
        guard !nodes.isEmpty else { return nil }
        let kept = Set(nodes.map(\.id))
        return MaterialGraph(nodes: nodes, links: graph.links.filter { kept.contains($0.from) && kept.contains($0.to) })
    }

    func removeMaterialNodes(_ ids: Set<String>, in particleID: String) {
        guard let graph = materialGraph(particleID) else { return }
        let doomed = Set(graph.nodes.filter { ids.contains($0.id) && $0.type != "output" }.map(\.id))
        guard !doomed.isEmpty else { return }
        editMaterial(doomed.count == 1 ? "Delete Node" : "Delete Nodes", in: particleID) { graph in
            graph.nodes.removeAll { doomed.contains($0.id) }
            graph.links.removeAll { doomed.contains($0.from) || doomed.contains($0.to) }
        }
    }

    func materialBlend(_ particleID: String) -> String { materialParticle(particleID)?["blend"]?.string ?? "normal" }

    func setMaterialBlend(_ blend: String, in particleID: String) {
        guard let particle = materialParticle(particleID), materialBlend(particleID) != blend else { return }
        let before = snapshot()
        particle.set("blend", JSONNode(.string(blend)))
        registerUndo("Set Blend", since: before)
    }

    var materialLight: MaterialLight {
        func triple(_ key: String) -> [Double]? {
            guard let parts = jsonRoot?["light"]?[key]?.elements?.compactMap(\.number), parts.count == 3 else { return nil }
            return parts
        }
        return MaterialLight(direction: triple("direction"), color: triple("color"), ambient: triple("ambient"))
    }

    func setMaterialLight(_ key: String, _ value: [Double], title: String) {
        guard let root = jsonRoot else { return }
        let before = snapshot()
        var members = root["light"]?.members ?? []
        members.removeAll { $0.key == key }
        members.append(JSONMember(key: key, node: JSONNode(.array(value.map { JSONNode(.number(($0 * 1000).rounded() / 1000)) }))))
        root.set("light", JSONNode(.object(members)))
        registerUndo(title, since: before)
    }

    func materialBaseTexture(_ particleID: String) -> String? { materialParticle(particleID)?["texture"]?.string }

    func materialLayers(_ particleID: String) -> [(texture: String, combine: String, keepAlpha: Bool)] {
        (materialParticle(particleID)?["layers"]?.elements ?? []).compactMap { layer in
            guard let texture = layer["texture"]?.string else { return nil }
            return (texture, layer["combine"]?.string ?? "multiply", layer["alpha"]?.string == "keep")
        }
    }

    func setMaterial(_ graph: MaterialGraph, title: String, in particleID: String) {
        guard let particle = materialParticle(particleID) else { return }
        let before = snapshot()
        particle.set("material", graphJSON(graph))
        registerUndo(title, since: before)
    }
}

enum MaterialLibrary {
    static var clipboard: MaterialGraph?
    static var copiedMaterial: MaterialGraph?

    static var folder: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/Materials", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    static var saved: [(name: String, url: URL)] {
        guard let folder else { return [] }
        return ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "material" }.map { ($0.deletingPathExtension().lastPathComponent, $0) }.sorted { $0.0 < $1.0 }
    }

    static func save(_ graph: MaterialGraph, name: String) {
        let clean = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, let folder else { return }
        let nodes: [[String: Any]] = graph.nodes.map { node in
            var entry: [String: Any] = ["id": node.id, "type": node.type, "x": node.x ?? 0, "y": node.y ?? 0]
            if let texture = node.texture { entry["texture"] = texture }
            if let name = node.name { entry["name"] = name }
            if let params = node.params { entry["params"] = params }
            return entry
        }
        let links = graph.links.map { ["from": $0.from, "out": $0.out, "to": $0.to, "in": $0.input] }
        guard let data = try? JSONSerialization.data(withJSONObject: ["nodes": nodes, "links": links], options: [.prettyPrinted, .sortedKeys]) else { return }
        try? data.write(to: folder.appendingPathComponent(clean + ".material"), options: .atomic)
    }

    static func load(_ url: URL) -> MaterialGraph? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MaterialGraph.self, from: data)
    }
}
