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

    func materialGraph(_ particleID: String) -> MaterialGraph? {
        guard let material = materialParticle(particleID)?["material"], material.members != nil else { return nil }
        var nodes: [MaterialNode] = []
        for entry in material["nodes"]?.elements ?? [] {
            guard let id = entry["id"]?.string, let type = entry["type"]?.string else { continue }
            var params: [String: Double] = [:]
            for member in entry["params"]?.members ?? [] { if let value = member.node.number { params[member.key] = value } }
            nodes.append(MaterialNode(id: id, type: type, x: entry["x"]?.number, y: entry["y"]?.number, texture: entry["texture"]?.string,
                                      params: params.isEmpty ? nil : params))
        }
        var links: [MaterialLink] = []
        for entry in material["links"]?.elements ?? [] {
            guard let from = entry["from"]?.string, let out = entry["out"]?.string, let to = entry["to"]?.string, let input = entry["in"]?.string else { continue }
            links.append(MaterialLink(from: from, out: out, to: to, input: input))
        }
        return MaterialGraph(nodes: nodes, links: links)
    }

    private func nodeJSON(_ node: MaterialNode) -> JSONNode {
        var members = [JSONMember(key: "id", node: JSONNode(.string(node.id))), JSONMember(key: "type", node: JSONNode(.string(node.type))),
                       JSONMember(key: "x", node: JSONNode(.number((node.x ?? 0).rounded()))), JSONMember(key: "y", node: JSONNode(.number((node.y ?? 0).rounded())))]
        if let texture = node.texture { members.append(JSONMember(key: "texture", node: JSONNode(.string(texture)))) }
        if let params = node.params, !params.isEmpty {
            let order = MaterialGraph.kind(of: node.type)?.params.map(\.name) ?? params.keys.sorted()
            let list = order.compactMap { name in params[name].map { JSONMember(key: name, node: JSONNode(.number($0))) } }
            members.append(JSONMember(key: "params", node: JSONNode(.object(list))))
        }
        return JSONNode(.object(members))
    }

    func writeMaterial(_ graph: MaterialGraph, to particleID: String) {
        guard let particle = materialParticle(particleID) else { return }
        let links = graph.links.map { link in
            JSONNode(.object([JSONMember(key: "from", node: JSONNode(.string(link.from))), JSONMember(key: "out", node: JSONNode(.string(link.out))),
                              JSONMember(key: "to", node: JSONNode(.string(link.to))), JSONMember(key: "in", node: JSONNode(.string(link.input)))]))
        }
        particle.set("material", JSONNode(.object([JSONMember(key: "nodes", node: JSONNode(.array(graph.nodes.map(nodeJSON)))),
                                                   JSONMember(key: "links", node: JSONNode(.array(links)))])))
    }

    func editMaterial(_ title: String, in particleID: String, _ edit: (inout MaterialGraph) -> Void) {
        guard var graph = materialGraph(particleID) else { return }
        let before = snapshot()
        edit(&graph)
        writeMaterial(graph, to: particleID)
        registerUndo(title, since: before)
    }

    func createMaterial(in particleID: String) {
        guard materialParticle(particleID) != nil, materialGraph(particleID) == nil else { return }
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
}
