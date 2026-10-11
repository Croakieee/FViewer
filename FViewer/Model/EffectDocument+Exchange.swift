import Foundation

struct NodeReference {
    let target: String
    let get: () -> Int
    let set: (Int) -> Void
}

struct ExportableNode: Identifiable {
    let id: String
    let tag: String
    let index: Int
    let title: String
    let block: AvfxBlock
}

extension EffectDocument {
    static let exchangeTags = ["TmLn", "Emit", "Ptcl", "Efct", "Bind", "Tex", "Modl"]
    static let importOrder = ["Modl", "Tex", "Bind", "Efct", "Ptcl", "Emit", "TmLn"]
    static let exportOrder = ["TmLn", "Emit", "Efct", "Bind", "Ptcl", "Tex", "Modl"]
    static let kindTitles = ["TmLn": "Timeline", "Emit": "Emitter", "Ptcl": "Particle", "Efct": "Effector", "Bind": "Binder", "Tex": "Texture",
                             "Modl": "Model", "Schd": "Scheduler"]

    static func nodeReferences(_ node: AvfxBlock) -> [NodeReference] {
        var result: [NodeReference] = []
        func add(_ target: String, _ field: AvfxBlock?) {
            guard let field, field.children == nil, field.data.count >= 4 else { return }
            result.append(NodeReference(target: target, get: { field.intValue }, set: { field.intValue = $0 }))
        }
        for (target, entries) in referenceTable {
            for entry in entries where entry.owner == node.tag {
                if let list = entry.list {
                    for record in node.ownRecords(list) { add(target, record.first { $0.tag == entry.field }) }
                } else {
                    let holder = entry.part.map { node.child($0) } ?? node
                    if node.tag == "Ptcl", entry.part == "Data", entry.field == "MdNo" { continue }
                    add(target, holder?.child(entry.field))
                }
            }
        }
        guard node.tag == "Ptcl" else { return result }
        let lists: [(String, AvfxBlock?)] = [("Tex", node.child("TC1")?.child("TLst")), ("Modl", node.child("Data")?.child("MdNo"))]
        for (target, list) in lists {
            guard let list, list.children == nil else { continue }
            for position in list.data.indices {
                result.append(NodeReference(target: target,
                                            get: { position < list.data.count && list.data[position] != 255 ? Int(list.data[position]) : -1 },
                                            set: { if position < list.data.count { list.data[position] = $0 < 0 ? 255 : UInt8(truncatingIfNeeded: $0) } }))
            }
        }
        return result
    }

    var exportableNodes: [ExportableNode] {
        guard let root = avfxRoot else { return [] }
        var result: [ExportableNode] = []
        for tag in EffectDocument.exchangeTags {
            for (index, block) in root.childrenNamed(tag).enumerated() {
                let id = "avfx/\(tag)/\(index)"
                var title = node(id)?.title ?? "\(EffectDocument.kindTitles[tag] ?? tag) \(index)"
                if tag == "Tex" { title = "\(index) · " + (block.stringValue as NSString).lastPathComponent }
                result.append(ExportableNode(id: id, tag: tag, index: index, title: title, block: block))
            }
        }
        return result
    }

    private func dependencyClosure(_ start: [AvfxBlock], in root: AvfxBlock) -> [AvfxBlock] {
        var visited: [ObjectIdentifier] = []
        var output: [AvfxBlock] = []
        func visit(_ node: AvfxBlock) {
            let key = ObjectIdentifier(node)
            if visited.contains(key) { return }
            visited.append(key)
            for reference in EffectDocument.nodeReferences(node) {
                let index = reference.get()
                let targets = root.childrenNamed(reference.target)
                if index >= 0, index < targets.count { visit(targets[index]) }
            }
            output.append(node)
        }
        start.forEach(visit)
        return output
    }

    func dependencies(of ids: Set<String>) -> Set<String> {
        guard let root = avfxRoot else { return [] }
        let all = exportableNodes
        let closure = dependencyClosure(all.filter { ids.contains($0.id) }.map(\.block), in: root)
        return Set(all.filter { node in closure.contains { $0 === node.block } }.map(\.id))
    }

    func exportNodes(_ ids: Set<String>, withDependencies: Bool) -> Data {
        guard let root = avfxRoot else { return Data() }
        root.syncCumulativeLists()
        let all = exportableNodes
        let selected = all.filter { ids.contains($0.id) }.map(\.block)
        var nodes = selected
        var copies: [AvfxBlock] = []
        if withDependencies {
            nodes = dependencyClosure(selected, in: root)
            var mapping: [String: [Int: Int]] = [:]
            for tag in EffectDocument.exportOrder {
                let originals = root.childrenNamed(tag)
                var next = 0
                for node in nodes where node.tag == tag {
                    if let old = originals.firstIndex(where: { $0 === node }) { mapping[tag, default: [:]][old] = next }
                    next += 1
                }
            }
            for node in nodes {
                let copy = node.deepCopy()
                for reference in EffectDocument.nodeReferences(copy) {
                    let old = reference.get()
                    if old >= 0 { reference.set(mapping[reference.target]?[old] ?? -1) }
                }
                copy.syncCumulativeLists()
                copies.append(copy)
            }
        } else {
            copies = nodes.map { $0.deepCopy() }
        }
        var body: [UInt8] = []
        copies.forEach { $0.serialize(into: &body) }
        var out: [UInt8] = []
        out.appendU32(2)
        out.append(withDependencies ? 1 : 0)
        out.appendU32(UInt32(copies.count))
        out.appendU32(UInt32(body.count))
        out.appendU32(UInt32(17 + body.count))
        out.append(contentsOf: body)
        for node in nodes {
            let id = all.first { $0.block === node }?.id ?? ""
            out.append(contentsOf: Array((names[id] ?? "").utf8))
            out.append(0)
        }
        return Data(out)
    }

    func importNodes(_ data: Data, legacy: Bool) throws -> Int {
        guard let root = avfxRoot else { throw AvfxError.malformed("Nodes can only be imported into an .avfx effect") }
        let bytes = [UInt8](data)
        var start = 0, end = bytes.count
        var hasDependencies = true
        if legacy {
            guard bytes.count >= 8 else { throw AvfxError.malformed("The file is too small to hold a node") }
            hasDependencies = bytes.count > Int(bytes.u32(4)) + 12
        } else {
            guard bytes.count >= 17, bytes.u32(0) == 2 else { throw AvfxError.malformed("Not a .vfxedit2 file") }
            hasDependencies = bytes[4] != 0
            start = 17
            end = 17 + Int(bytes.u32(9))
            guard end <= bytes.count else { throw AvfxError.malformed("The node data is truncated") }
        }
        let parsed = try AvfxBlock.parse(bytes, start, end)
        var renames: [ObjectIdentifier: String] = [:]
        if !legacy {
            var at = Int(bytes.u32(13))
            for block in parsed where at < bytes.count {
                var text: [UInt8] = []
                while at < bytes.count, bytes[at] != 0 {
                    text.append(bytes[at])
                    at += 1
                }
                at += 1
                if !text.isEmpty { renames[ObjectIdentifier(block)] = String(decoding: text, as: UTF8.self) }
            }
        }
        let blocks = parsed.filter { EffectDocument.exchangeTags.contains($0.tag) }
        guard !blocks.isEmpty else { throw AvfxError.malformed("The file contains no nodes") }
        var offsets: [String: Int] = [:]
        for tag in EffectDocument.exchangeTags { offsets[tag] = root.childrenNamed(tag).count }
        if hasDependencies {
            for block in blocks {
                for reference in EffectDocument.nodeReferences(block) {
                    let value = reference.get()
                    if value >= 0 { reference.set(value + (offsets[reference.target] ?? 0)) }
                }
            }
        }
        performStructural(blocks.count == 1 ? "Import Node" : "Import \(blocks.count) Nodes") {
            for tag in EffectDocument.importOrder {
                for block in blocks where block.tag == tag { root.insertTopLevel(block) }
            }
            for block in blocks {
                for reference in EffectDocument.nodeReferences(block) where reference.get() >= root.childrenNamed(reference.target).count {
                    reference.set(-1)
                }
            }
            root.syncCumulativeLists()
        }
        var fresh: [String: String] = [:]
        for block in blocks {
            guard let name = renames[ObjectIdentifier(block)], let index = root.childrenNamed(block.tag).firstIndex(where: { $0 === block }) else { continue }
            fresh["avfx/\(block.tag)/\(index)"] = name
        }
        if !fresh.isEmpty { assignNames(fresh) }
        if let last = EffectDocument.exportOrder.first(where: { tag in blocks.contains { $0.tag == tag } }) {
            selectionID = "avfx/\(last)/\(root.childrenNamed(last).count - 1)"
        }
        return blocks.count
    }

    var unusedNodes: [ExportableNode] {
        guard let root = avfxRoot else { return [] }
        var used: [String: Set<Int>] = [:]
        for tag in ["Schd"] + EffectDocument.exchangeTags {
            for node in root.childrenNamed(tag) {
                for reference in EffectDocument.nodeReferences(node) {
                    let value = reference.get()
                    if value >= 0 { used[reference.target, default: []].insert(value) }
                }
            }
        }
        return exportableNodes.filter { !(used[$0.tag]?.contains($0.index) ?? false) }
    }

    func cleanUp() -> Int {
        guard avfxRoot != nil, !unusedNodes.isEmpty else { return 0 }
        var removed = 0
        performStructural("Clean Up") {
            while let node = unusedNodes.first, let root = avfxRoot, removed < 4096 {
                root.remove(node.block)
                remapReferences(root, tag: node.tag, removed: node.index)
                removed += 1
            }
        }
        return removed
    }
}
