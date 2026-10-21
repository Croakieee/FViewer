import Foundation
import simd

struct PhybChain {
    var head: [UInt8]
    var collisions: [[UInt8]]
    var nodes: [[UInt8]]
}

struct PhybSimulator {
    var parameters: [UInt8]
    var lists: [[[UInt8]]]
    var chains: [PhybChain]
}

struct PhybModel {
    static let shapeSizes = [124, 116, 92, 168, 80]

    var withinLimits: Bool {
        shapes.allSatisfy { $0.count <= 255 } && simulators.allSatisfy { simulator in
            simulator.lists.allSatisfy { $0.count <= 255 } && simulator.chains.count <= 255
                && simulator.chains.allSatisfy { $0.collisions.count <= 65535 && $0.nodes.count <= 65535 }
        }
    }
    static let listSizes = [36, 36, 48, 32, 52, 48, 16, 36]
    static let shapeNames = ["Capsule", "Ellipsoid", "Normal Plane", "Three-Point Plane", "Sphere"]
    static let listNames = ["Collision Object", "Collision Connector", "Chain", "Connector", "Attract", "Pin", "Spring", "Post Alignment"]

    var header: [UInt8]
    var hasCollision: Bool
    var shapes: [[[UInt8]]]
    var hasSimulation: Bool
    var simulators: [PhybSimulator]
    var tail: [UInt8]

    static func parse(_ b: [UInt8]) -> PhybModel? {
        guard b.count >= 16, b.u32(0) != 0, b.u32(4) != 0 else { return nil }
        let collision = Int(b.u32(8)), simulation = Int(b.u32(12))
        guard collision == 16, simulation >= collision, simulation <= b.count else { return nil }
        var model = PhybModel(header: Array(b[0..<8]), hasCollision: collision != simulation, shapes: [[], [], [], [], []], hasSimulation: false, simulators: [], tail: [])
        func slice(_ at: Int, _ size: Int) -> [UInt8]? { at >= 0 && at + size <= b.count ? Array(b[at..<at + size]) : nil }
        if model.hasCollision {
            guard collision + 8 <= b.count else { return nil }
            var at = collision + 8
            for kind in 0..<5 {
                for _ in 0..<Int(b[collision + kind]) {
                    guard let blob = slice(at, shapeSizes[kind]) else { return nil }
                    model.shapes[kind].append(blob)
                    at += shapeSizes[kind]
                }
            }
            guard at == simulation else { return nil }
        }
        var end = simulation
        if simulation + 4 <= b.count, b.u32(simulation) > 0, b.u32(simulation) <= 64, simulation + 4 + Int(b.u32(simulation)) * 72 <= b.count {
            model.hasSimulation = true
            let count = Int(b.u32(simulation))
            end = simulation + 4 + count * 72
            for index in 0..<count {
                let head = simulation + 4 + index * 72
                guard let parameters = slice(head + 8, 32) else { return nil }
                var simulator = PhybSimulator(parameters: parameters, lists: Array(repeating: [], count: 8), chains: [])
                for list in 0..<8 {
                    let items = Int(b[head + list]), offset = b.u32(head + 40 + list * 4)
                    guard items == 0 || offset != 0xCCCC_CCCC else { return nil }
                    var at = simulation + Int(offset == 0xCCCC_CCCC ? 0 : offset) + 4
                    for _ in 0..<items {
                        guard let blob = slice(at, listSizes[list]) else { return nil }
                        if list == 2 {
                            let collisions = Int(blob.u16(0)), nodes = Int(blob.u16(2))
                            var chain = PhybChain(head: Array(blob[4..<40]), collisions: [], nodes: [])
                            var inner = simulation + Int(blob.u32(40)) + 4
                            for _ in 0..<collisions {
                                guard let item = slice(inner, 36) else { return nil }
                                chain.collisions.append(item)
                                inner += 36
                            }
                            if collisions > 0 { end = max(end, inner) }
                            inner = simulation + Int(blob.u32(44)) + 4
                            for _ in 0..<nodes {
                                guard let item = slice(inner, 84) else { return nil }
                                chain.nodes.append(item)
                                inner += 84
                            }
                            if nodes > 0 { end = max(end, inner) }
                            simulator.chains.append(chain)
                        } else {
                            simulator.lists[list].append(blob)
                        }
                        at += listSizes[list]
                    }
                    if items > 0 { end = max(end, at) }
                }
                model.simulators.append(simulator)
            }
        } else if simulation + 4 <= b.count, b.u32(simulation) == 0 {
            let rest = b[(simulation + 4)...]
            if rest.isEmpty || rest.allSatisfy({ $0 == 0 }) || !rest.prefix(12).allSatisfy({ $0 == 0 }) {
                model.hasSimulation = true
                end = simulation + 4
            }
        }
        model.tail = Array(b[end...])
        while let first = model.tail.first, first == 0, end % 8 != 0 {
            model.tail.removeFirst()
            end += 1
        }
        return model
    }

    func serialized() -> [UInt8] {
        var out = header
        out.appendU32(0)
        out.appendU32(0)
        let collision = out.count
        if shapes.contains(where: { !$0.isEmpty }) || hasCollision {
            for kind in 0..<5 { out.append(UInt8(min(shapes[kind].count, 255))) }
            out.append(contentsOf: [0xCC, 0xCC, 0xCC])
            for kind in 0..<5 { for blob in shapes[kind].prefix(255) { out.append(contentsOf: blob) } }
        }
        let simulation = out.count
        GameFiles.put32(&out, 8, UInt32(collision))
        GameFiles.put32(&out, 12, UInt32(simulation))
        if hasSimulation || !simulators.isEmpty {
            var main: [UInt8] = []
            var extra: [UInt8] = []
            main.appendU32(UInt32(simulators.count))
            var heads: [Int] = []
            for simulator in simulators {
                for list in 0..<8 { main.append(UInt8(min(list == 2 ? simulator.chains.count : simulator.lists[list].count, 255))) }
                main.append(contentsOf: simulator.parameters)
                heads.append(main.count)
                main.append(contentsOf: [UInt8](repeating: 0, count: 32))
            }
            var offsets = Array(repeating: [UInt32](repeating: 0, count: 8), count: simulators.count)
            var chainCollisions: [[Int]] = simulators.map { _ in [] }
            var nodePlaces: [(at: Int, extra: Int)] = []
            func write(_ list: Int) {
                for (index, simulator) in simulators.enumerated() {
                    let start = main.count
                    if list == 2 {
                        for (slot, chain) in simulator.chains.enumerated() {
                            main.appendU16(UInt16(chain.collisions.count))
                            main.appendU16(UInt16(chain.nodes.count))
                            main.append(contentsOf: chain.head)
                            main.appendU32(chain.collisions.isEmpty ? 0 : UInt32(chainCollisions[index][slot] - 4))
                            if chain.nodes.isEmpty {
                                main.appendU32(0)
                            } else {
                                nodePlaces.append((main.count, extra.count - 4))
                                main.appendU32(0)
                            }
                            for node in chain.nodes { extra.append(contentsOf: node) }
                        }
                        offsets[index][list] = simulator.chains.isEmpty ? 0 : UInt32(start - 4)
                    } else {
                        for blob in simulator.lists[list] { main.append(contentsOf: blob) }
                        offsets[index][list] = simulator.lists[list].isEmpty ? (list == 7 ? 0xCCCC_CCCC : 0) : UInt32(start - 4)
                    }
                }
            }
            write(0)
            for (index, simulator) in simulators.enumerated() {
                for chain in simulator.chains {
                    chainCollisions[index].append(main.count)
                    for blob in chain.collisions { main.append(contentsOf: blob) }
                }
            }
            for list in 1..<8 { write(list) }
            for (index, head) in heads.enumerated() { for list in 0..<8 { GameFiles.put32(&main, head + list * 4, offsets[index][list]) } }
            for place in nodePlaces { GameFiles.put32(&main, place.at, UInt32(main.count + place.extra)) }
            out.append(contentsOf: main)
            out.append(contentsOf: extra)
        }
        if !tail.isEmpty {
            while out.count % 8 != 0 { out.append(0) }
            out.append(contentsOf: tail)
        }
        return out
    }

    static func blank(size: Int, texts: [Int], named: Bool) -> [UInt8] {
        var blob = [UInt8](repeating: 0, count: size)
        for (index, at) in texts.enumerated() {
            let text = Array((index == 0 && named ? "replace_me" : "").utf8)
            for slot in 0..<32 { blob[at + slot] = slot < text.count ? text[slot] : slot == text.count ? 0 : 0xFE }
        }
        return blob
    }
}

enum RecordSlot: Equatable {
    case shape(kind: Int, index: Int)
    case parameters(simulator: Int)
    case item(simulator: Int, list: Int, index: Int)
    case chain(simulator: Int, index: Int)
    case chainCollision(simulator: Int, chain: Int, index: Int)
    case node(simulator: Int, chain: Int, index: Int)
    case variant(Int)
}

enum PhybAddition: Hashable {
    case shape(Int)
    case simulator
    case item(Int)
    case chainCollision
    case node
}

extension GameRecords {
    private static let phybLinks: [Int: [(chain: Int, node: Int)]] = [3: [(0, 4), (2, 6)], 4: [(44, 46)], 5: [(44, 46)], 6: [(0, 4), (2, 6)], 7: [(32, 34)]]

    private static func phybRelink(_ simulator: inout PhybSimulator, chain: Int, node: Int?, removed: Bool) {
        for (list, pairs) in phybLinks where list < simulator.lists.count {
            var kept: [[UInt8]] = []
            for var item in simulator.lists[list] {
                var dangling = false
                for pair in pairs where pair.node + 1 < item.count {
                    let c = Int(item.u16(pair.chain)), n = Int(item.u16(pair.node))
                    func put(_ at: Int, _ value: Int) {
                        item[at] = UInt8(value & 0xff)
                        item[at + 1] = UInt8((value >> 8) & 0xff)
                    }
                    if let node {
                        guard c == chain else { continue }
                        if removed, n == node { dangling = true } else if n > node { put(pair.node, removed ? n - 1 : n + 1) }
                    } else if removed, c == chain {
                        dangling = true
                    } else if c > chain {
                        put(pair.chain, removed ? c - 1 : c + 1)
                    }
                }
                if !dangling { kept.append(item) }
            }
            simulator.lists[list] = kept
        }
    }

    static func phybRemove(_ b: [UInt8], _ slot: RecordSlot) -> [UInt8]? {
        guard var model = PhybModel.parse(b) else { return nil }
        if case .chain(let simulator, let index) = slot { phybRelink(&model.simulators[simulator], chain: index, node: nil, removed: true) }
        if case .node(let simulator, let chain, let index) = slot { phybRelink(&model.simulators[simulator], chain: chain, node: index, removed: true) }
        switch slot {
        case .shape(let kind, let index): model.shapes[kind].remove(at: index)
        case .parameters(let simulator): model.simulators.remove(at: simulator)
        case .item(let simulator, let list, let index): model.simulators[simulator].lists[list].remove(at: index)
        case .chain(let simulator, let index): model.simulators[simulator].chains.remove(at: index)
        case .chainCollision(let simulator, let chain, let index): model.simulators[simulator].chains[chain].collisions.remove(at: index)
        case .node(let simulator, let chain, let index): model.simulators[simulator].chains[chain].nodes.remove(at: index)
        case .variant: return nil
        }
        guard model.withinLimits else { return nil }
        return model.serialized()
    }

    static func phybDuplicate(_ b: [UInt8], _ slot: RecordSlot) -> [UInt8]? {
        guard var model = PhybModel.parse(b) else { return nil }
        if case .chain(let simulator, let index) = slot { phybRelink(&model.simulators[simulator], chain: index, node: nil, removed: false) }
        if case .node(let simulator, let chain, let index) = slot { phybRelink(&model.simulators[simulator], chain: chain, node: index, removed: false) }
        switch slot {
        case .shape(let kind, let index): model.shapes[kind].insert(model.shapes[kind][index], at: index + 1)
        case .parameters(let simulator): model.simulators.insert(model.simulators[simulator], at: simulator + 1)
        case .item(let simulator, let list, let index): model.simulators[simulator].lists[list].insert(model.simulators[simulator].lists[list][index], at: index + 1)
        case .chain(let simulator, let index): model.simulators[simulator].chains.insert(model.simulators[simulator].chains[index], at: index + 1)
        case .chainCollision(let simulator, let chain, let index):
            model.simulators[simulator].chains[chain].collisions.insert(model.simulators[simulator].chains[chain].collisions[index], at: index + 1)
        case .node(let simulator, let chain, let index):
            model.simulators[simulator].chains[chain].nodes.insert(model.simulators[simulator].chains[chain].nodes[index], at: index + 1)
        case .variant: return nil
        }
        guard model.withinLimits else { return nil }
        return model.serialized()
    }

    static func phybAdd(_ b: [UInt8], _ addition: PhybAddition, near slot: RecordSlot?) -> [UInt8]? {
        guard var model = PhybModel.parse(b) else { return nil }
        var simulator = 0, chain = 0
        switch slot {
        case .parameters(let s): simulator = s
        case .item(let s, _, _): simulator = s
        case .chain(let s, let c): (simulator, chain) = (s, c)
        case .chainCollision(let s, let c, _), .node(let s, let c, _): (simulator, chain) = (s, c)
        default: break
        }
        switch addition {
        case .shape(let kind):
            let texts = kind == 0 ? [0, 32, 64] : [0, 32]
            model.shapes[kind].append(PhybModel.blank(size: PhybModel.shapeSizes[kind], texts: texts, named: true))
        case .simulator:
            var parameters = model.simulators.first?.parameters ?? [UInt8](repeating: 0, count: 32)
            if model.simulators.isEmpty {
                GameFiles.put32(&parameters, 4, Float(-9.8).bitPattern)
                parameters[30] = 0xCC
                parameters[31] = 0xCC
            }
            model.simulators.append(PhybSimulator(parameters: parameters, lists: Array(repeating: [], count: 8), chains: []))
        case .item(let list):
            guard simulator < model.simulators.count else { return nil }
            if list == 2 {
                model.simulators[simulator].chains.append(PhybChain(head: [UInt8](repeating: 0, count: 36), collisions: [], nodes: []))
            } else {
                let texts = [0, 1, 4, 5, 7].contains(list) ? [0] : []
                model.simulators[simulator].lists[list].append(PhybModel.blank(size: PhybModel.listSizes[list], texts: texts, named: list != 4 && list != 5))
            }
        case .chainCollision:
            guard simulator < model.simulators.count, chain < model.simulators[simulator].chains.count else { return nil }
            model.simulators[simulator].chains[chain].collisions.append(PhybModel.blank(size: 36, texts: [0], named: true))
        case .node:
            guard simulator < model.simulators.count, chain < model.simulators[simulator].chains.count else { return nil }
            model.simulators[simulator].chains[chain].nodes.append(PhybModel.blank(size: 84, texts: [0], named: false))
        }
        guard model.withinLimits else { return nil }
        return model.serialized()
    }

    static func imcParts(_ b: [UInt8]) -> Int { b.count >= 4 ? max(1, b.u16(2).nonzeroBitCount) : 1 }

    static func imcAdd(_ b: [UInt8], after variant: Int) -> [UInt8]? {
        guard b.count >= 4 else { return nil }
        let parts = imcParts(b), count = Int(b.u16(0)), size = parts * 6
        guard variant >= 0, variant <= count, 4 + (count + 1) * size <= b.count, count < 0xFFFF else { return nil }
        var out = b
        let source = Array(b[(4 + variant * size)..<(4 + (variant + 1) * size)])
        out.insert(contentsOf: source, at: 4 + (count + 1) * size)
        GameFiles.put16(&out, 0, count + 1)
        return out
    }

    static func imcRemove(_ b: [UInt8], variant: Int) -> [UInt8]? {
        guard b.count >= 4 else { return nil }
        let parts = imcParts(b), count = Int(b.u16(0)), size = parts * 6
        guard variant >= 1, variant == count, 4 + (count + 1) * size <= b.count else { return nil }
        var out = b
        out.removeSubrange((4 + variant * size)..<(4 + (variant + 1) * size))
        GameFiles.put16(&out, 0, count - 1)
        return out
    }
}

struct MtrlModel {
    var version: UInt32
    var textures: [(path: String, flags: UInt16)]
    var uvSets: [(name: String, index: UInt16)]
    var colorSets: [(name: String, index: UInt16)]
    var shader: String
    var remainder: Int
    var extra: [UInt8]
    var data: [UInt8]
    var shaderFlags: UInt32
    var keys: [(category: UInt32, value: UInt32)]
    var constants: [(id: UInt32, values: [UInt32])]
    var samplers: [[UInt8]]

    static func parse(_ b: [UInt8]) -> MtrlModel? {
        guard b.count >= 16 else { return nil }
        let dataSize = Int(b.u16(6)), stringSize = Int(b.u16(8)), shaderOffset = Int(b.u16(10))
        let textures = Int(b[12]), uvSets = Int(b[13]), colorSets = Int(b[14]), extraSize = Int(b[15])
        let strings = 16 + (textures + uvSets + colorSets) * 4
        let extraAt = strings + stringSize, dataAt = extraAt + extraSize, shaderAt = dataAt + dataSize
        guard shaderAt + 12 <= b.count else { return nil }
        func entry(_ slot: Int) -> (String, UInt16) { (GameFiles.string(b, strings + Int(b.u16(16 + slot * 4)), max: 300), b.u16(16 + slot * 4 + 2)) }
        let valueSize = Int(b.u16(shaderAt)), keyCount = Int(b.u16(shaderAt + 2)), constantCount = Int(b.u16(shaderAt + 4)), samplerCount = Int(b.u16(shaderAt + 6))
        let keysAt = shaderAt + 12, constantsAt = keysAt + keyCount * 8, samplersAt = constantsAt + constantCount * 8, valuesAt = samplersAt + samplerCount * 12
        guard valuesAt + valueSize <= b.count else { return nil }
        var constants: [(UInt32, [UInt32])] = []
        for index in 0..<constantCount {
            let at = constantsAt + index * 8
            let offset = Int(b.u16(at + 4)), size = Int(b.u16(at + 6))
            guard offset + size <= valueSize else { return nil }
            constants.append((b.u32(at), (0..<(size / 4)).map { b.u32(valuesAt + offset + $0 * 4) }))
        }
        return MtrlModel(version: b.u32(0), textures: (0..<textures).map { let e = entry($0); return (e.0, e.1) },
                         uvSets: (textures..<(textures + uvSets)).map { let e = entry($0); return (e.0, e.1) },
                         colorSets: ((textures + uvSets)..<(textures + uvSets + colorSets)).map { let e = entry($0); return (e.0, e.1) },
                         shader: GameFiles.string(b, strings + shaderOffset, max: 64), remainder: extraAt % 4, extra: Array(b[extraAt..<dataAt]),
                         data: Array(b[dataAt..<shaderAt]), shaderFlags: b.u32(shaderAt + 8), keys: (0..<keyCount).map { (b.u32(keysAt + $0 * 8), b.u32(keysAt + $0 * 8 + 4)) },
                         constants: constants.map { (id: $0.0, values: $0.1) }, samplers: (0..<samplerCount).map { Array(b[(samplersAt + $0 * 12)..<(samplersAt + $0 * 12 + 12)]) })
    }

    func serialized() -> [UInt8] {
        var out: [UInt8] = []
        out.appendU32(version)
        out.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0])
        out.append(contentsOf: [UInt8(min(textures.count, 255)), UInt8(min(uvSets.count, 255)), UInt8(min(colorSets.count, 255)), UInt8(min(extra.count, 255))])
        var names: [(at: Int, text: String)] = []
        for item in textures {
            names.append((out.count, item.path))
            out.appendU16(0)
            out.appendU16(item.flags)
        }
        for item in uvSets + colorSets {
            names.append((out.count, item.name))
            out.appendU16(0)
            out.appendU16(item.index)
        }
        let strings = out.count
        var placed: [String: Int] = [:]
        for name in names {
            if placed[name.text] == nil {
                placed[name.text] = out.count - strings
                out.append(contentsOf: Array(name.text.utf8) + [0])
            }
            GameFiles.put16(&out, name.at, placed[name.text] ?? 0)
        }
        let shaderOffset = out.count - strings
        out.append(contentsOf: Array(shader.utf8) + [0])
        while out.count % 4 != remainder { out.append(0) }
        let stringEnd = out.count
        out.append(contentsOf: extra)
        out.append(contentsOf: data)
        out.appendU16(UInt16(constants.reduce(0) { $0 + $1.values.count * 4 }))
        out.appendU16(UInt16(keys.count))
        out.appendU16(UInt16(constants.count))
        out.appendU16(UInt16(samplers.count))
        out.appendU32(shaderFlags)
        for key in keys {
            out.appendU32(key.category)
            out.appendU32(key.value)
        }
        var offset = 0
        for constant in constants {
            out.appendU32(constant.id)
            out.appendU16(UInt16(offset))
            out.appendU16(UInt16(constant.values.count * 4))
            offset += constant.values.count * 4
        }
        for sampler in samplers { out.append(contentsOf: sampler) }
        for constant in constants { for value in constant.values { out.appendU32(value) } }
        GameFiles.put16(&out, 4, out.count)
        GameFiles.put16(&out, 6, data.count)
        GameFiles.put16(&out, 8, stringEnd - strings)
        GameFiles.put16(&out, 10, shaderOffset)
        return out
    }
}

struct SkpModel {
    var head: [UInt8]
    var modern: Bool
    var hasLookAt: Bool
    var parameters: [[UInt8]]
    var groups: [(id: [UInt8], elements: [[UInt8]])]
    var hasSlope: Bool
    var slopeHead: [UInt8]
    var points: [[UInt8]]

    static func parse(_ b: [UInt8]) -> SkpModel? {
        guard b.count >= 0x1C, b[0] == 0x70, b[1] == 0x6C, b[2] == 0x6B, b[3] == 0x73 else { return nil }
        let version = Int(String(String(decoding: b[4..<8], as: UTF8.self).reversed())) ?? 0
        let modern = version > 1000
        let headerSize = modern ? 0x20 : 0x1C
        guard b.count >= headerSize, b[8] & 0x08 == 0 else { return nil }
        let lookAt = Int(b.u32(16)), slope = modern ? Int(b.u32(28)) : 0
        let hasLookAt = b[8] & 0x02 != 0 && lookAt > 0, hasSlope = modern && b[8] & 0x10 != 0 && slope > 0
        var model = SkpModel(head: [], modern: modern, hasLookAt: hasLookAt, parameters: [], groups: [], hasSlope: hasSlope, slopeHead: [], points: [])
        var end = hasLookAt ? lookAt : hasSlope ? slope : b.count
        guard end >= headerSize, end <= b.count else { return nil }
        model.head = Array(b[0..<end])
        if hasLookAt {
            guard lookAt + 2 <= b.count else { return nil }
            let parameters = Int(b[lookAt]), groups = Int(b[lookAt + 1])
            var at = lookAt + 2 + groups
            for _ in 0..<parameters {
                guard at + 56 <= b.count else { return nil }
                model.parameters.append(Array(b[at..<at + 56]))
                at += 56
            }
            for index in 0..<groups {
                guard at + 33 <= b.count, Int(b[at + 32]) == Int(b[lookAt + 2 + index]) else { return nil }
                let count = Int(b[at + 32])
                var group = (id: Array(b[at..<at + 32]), elements: [[UInt8]]())
                at += 33
                for _ in 0..<count {
                    guard at + 66 <= b.count else { return nil }
                    group.elements.append(Array(b[at..<at + 66]))
                    at += 66
                }
                model.groups.append(group)
            }
            end = at
        }
        if hasSlope {
            guard slope >= end, slope - end < 4, slope % 4 == 0, b[end..<slope].allSatisfy({ $0 == 0 }), slope + 32 <= b.count else { return nil }
            let count = Int(b.u32(slope + 28))
            guard count >= 0, slope + 32 + count * 12 <= b.count else { return nil }
            model.slopeHead = Array(b[slope..<slope + 28])
            model.points = (0..<count).map { Array(b[(slope + 32 + $0 * 12)..<(slope + 44 + $0 * 12)]) }
            end = slope + 32 + count * 12
        }
        guard end == b.count else { return nil }
        return model
    }

    func serialized() -> [UInt8] {
        var out = head
        var lookAt = 0, slope = 0
        if hasLookAt {
            lookAt = out.count
            out.append(UInt8(min(parameters.count, 255)))
            out.append(UInt8(min(groups.count, 255)))
            for group in groups.prefix(255) { out.append(UInt8(min(group.elements.count, 255))) }
            for item in parameters.prefix(255) { out.append(contentsOf: item) }
            for group in groups.prefix(255) {
                out.append(contentsOf: group.id)
                out.append(UInt8(min(group.elements.count, 255)))
                for element in group.elements.prefix(255) { out.append(contentsOf: element) }
            }
        }
        if hasSlope {
            while out.count % 4 != 0 { out.append(0) }
            slope = out.count
            out.append(contentsOf: slopeHead)
            out.appendU32(UInt32(points.count))
            for point in points { out.append(contentsOf: point) }
        }
        GameFiles.put32(&out, 16, UInt32(lookAt))
        if out[8] & 0x04 != 0 { GameFiles.put32(&out, 20, UInt32(out.count)) }
        if modern { GameFiles.put32(&out, 28, UInt32(slope)) }
        return out
    }
}

enum SkpSlot: Equatable {
    case parameter(Int)
    case group(Int)
    case element(group: Int, index: Int)
    case point(Int)
}

extension GameRecords {
    static func skpEdit(_ b: [UInt8], _ slot: SkpSlot, remove: Bool) -> [UInt8]? {
        guard var model = SkpModel.parse(b) else { return nil }
        switch slot {
        case .parameter(let index):
            guard index < model.parameters.count else { return nil }
            if remove {
                model.parameters.remove(at: index)
            } else {
                var copy = model.parameters[index]
                if copy.count > 52 {
                    let taken = Set(model.parameters.compactMap { $0.count > 52 ? Int($0[52]) : nil })
                    if let free = (0...255).first(where: { !taken.contains($0) }) { copy[52] = UInt8(free) }
                }
                model.parameters.insert(copy, at: index + 1)
            }
        case .group(let index):
            guard index < model.groups.count else { return nil }
            if remove { model.groups.remove(at: index) } else { model.groups.insert(model.groups[index], at: index + 1) }
        case .element(let group, let index):
            guard group < model.groups.count, index < model.groups[group].elements.count else { return nil }
            if remove { model.groups[group].elements.remove(at: index) } else { model.groups[group].elements.insert(model.groups[group].elements[index], at: index + 1) }
        case .point(let index):
            guard index < model.points.count else { return nil }
            if remove { model.points.remove(at: index) } else { model.points.insert(model.points[index], at: index + 1) }
        }
        return model.serialized()
    }

    static func skpParameterUsers(_ b: [UInt8], parameter: Int) -> (index: Int, users: Int)? {
        guard let model = SkpModel.parse(b), parameter < model.parameters.count, model.parameters[parameter].count > 52 else { return nil }
        let value = model.parameters[parameter][52]
        guard !model.parameters.enumerated().contains(where: { $0.offset != parameter && $0.element.count > 52 && $0.element[52] == value }) else { return (Int(value), 0) }
        let users = model.groups.reduce(0) { total, group in total + group.elements.filter { $0.count > 1 && $0[1] == value }.count }
        return (Int(value), users)
    }

    static func skpAddElement(_ b: [UInt8], group: Int) -> [UInt8]? {
        guard var model = SkpModel.parse(b), group < model.groups.count else { return nil }
        model.groups[group].elements.append([UInt8](repeating: 0, count: 66))
        return model.serialized()
    }

}

struct KdbModel {
    var prefix: [UInt8]
    var operations: Int
    var tableB: Int
    var tableE: Int
    var tableF: Int
    var nodes: [(head: [UInt8], body: [UInt8])]
    var itemsB: [UInt8]
    var itemsE: [UInt8]
    var itemsF: [UInt8]
    var aligned = true
    var gap: [UInt8] = []

    static func parse(_ b: [UInt8]) -> KdbModel? {
        guard b.count >= 0x70, b.u32(28) == 5 else { return nil }
        let arrays = 32 + Int(b.u32(32))
        guard arrays + 48 <= b.count else { return nil }
        var places: [Int: Int] = [:]
        for slot in 0..<5 {
            let entry = arrays + slot * 8
            places[Int(b.u16(entry))] = entry + 4 + Int(b.u32(entry + 4))
        }
        guard let operations = places[0], let tableB = places[1], let tableE = places[4], let tableF = places[5], operations + 8 <= b.count, tableB + 16 <= b.count,
              tableE + 8 <= b.count, tableF + 8 <= b.count else { return nil }
        let count = Int(b.u32(operations)), start = operations + 4 + Int(b.u32(operations + 4))
        guard count > 0, count < 100_000, start + count * 28 <= b.count else { return nil }
        let countB = Int(b.u32(tableB + 8)), startB = countB > 0 ? tableB + 12 + Int(b.u32(tableB + 12)) : -1
        let countE = Int(b.u32(tableE)), startE = countE > 0 ? tableE + 4 + Int(b.u32(tableE + 4)) : -1
        let countF = Int(b.u32(tableF)), startF = countF > 0 ? tableF + 4 + Int(b.u32(tableF + 4)) : -1
        let tails = [startB, startE, startF].filter { $0 >= 0 }
        let bodiesEnd = tails.min() ?? b.count
        guard bodiesEnd <= b.count, tails.allSatisfy({ $0 <= b.count }) else { return nil }
        var bodies: [Int] = []
        for index in 0..<count {
            let at = start + index * 28
            guard Int(b.u32(at)) == index else { return nil }
            bodies.append(at + 24 + Int(b.u32(at + 24)))
        }
        let raw = start + count * 28
        var first = raw
        while first % 8 != 0 { first += 1 }
        guard bodies.first == first || bodies.first == raw else { return nil }
        var model = KdbModel(prefix: Array(b[0..<start]), operations: operations, tableB: tableB, tableE: tableE, tableF: tableF, nodes: [], itemsB: [], itemsE: [], itemsF: [])
        model.aligned = bodies.first == first
        guard let opening = bodies.first, opening >= raw, opening <= b.count, raw <= b.count else { return nil }
        model.gap = Array(b[raw..<(bodies.first ?? raw)])
        for index in 0..<count {
            let from = bodies[index], to = index + 1 < count ? bodies[index + 1] : bodiesEnd
            guard from < to, to <= b.count else { return nil }
            let at = start + index * 28
            model.nodes.append((Array(b[(at + 4)..<(at + 24)]), Array(b[from..<to])))
        }
        func block(_ from: Int, _ size: Int) -> [UInt8]? { from >= 0 && from + size <= b.count ? Array(b[from..<from + size]) : nil }
        if countB > 0 {
            guard let items = block(startB, countB * 112), startB == bodiesEnd else { return nil }
            model.itemsB = items
        }
        if countE > 0 {
            guard let items = block(startE, countE * 20) else { return nil }
            model.itemsE = items
        }
        if countF > 0 {
            guard let items = block(startF, countF * 8) else { return nil }
            model.itemsF = items
        }
        return model
    }

    func serialized() -> [UInt8] {
        var out = prefix
        GameFiles.put32(&out, operations, UInt32(nodes.count))
        var places: [Int] = []
        for (index, node) in nodes.enumerated() {
            out.appendU32(UInt32(index))
            out.append(contentsOf: node.head)
            places.append(out.count)
            out.appendU32(0)
        }
        if aligned {
            let needed = (8 - out.count % 8) % 8
            out.append(contentsOf: needed == gap.count ? gap : [UInt8](repeating: 0, count: needed))
        }
        for (index, node) in nodes.enumerated() {
            GameFiles.put32(&out, places[index], UInt32(out.count - places[index]))
            out.append(contentsOf: node.body)
        }
        func table(_ items: [UInt8], count: Int, countAt: Int, offsetAt: Int) {
            GameFiles.put32(&out, countAt, UInt32(count))
            GameFiles.put32(&out, offsetAt, count > 0 ? UInt32(out.count - offsetAt) : 0)
            out.append(contentsOf: items)
        }
        table(itemsB, count: itemsB.count / 112, countAt: tableB + 8, offsetAt: tableB + 12)
        table(itemsE, count: itemsE.count / 20, countAt: tableE, offsetAt: tableE + 4)
        table(itemsF, count: itemsF.count / 8, countAt: tableF, offsetAt: tableF + 4)
        GameFiles.put32(&out, 16, UInt32(out.count))
        return out
    }

    func isConnection(_ index: Int) -> Bool { nodes[index].head[0] == 22 }

    mutating func remap(_ map: (Int) -> Int?) {
        var kept: [(head: [UInt8], body: [UInt8])] = []
        for index in nodes.indices {
            var node = nodes[index]
            if isConnection(index), node.body.count >= 32 {
                guard let from = map(Int(node.body.u32(8))), let to = map(Int(node.body.u32(28))) else { continue }
                GameFiles.put32(&node.body, 8, UInt32(from))
                GameFiles.put32(&node.body, 28, UInt32(to))
            }
            kept.append(node)
        }
        nodes = kept
    }
}

extension GameRecords {
    static func kdbRemove(_ b: [UInt8], node index: Int) -> [UInt8]? {
        guard var model = KdbModel.parse(b), index < model.nodes.count, model.nodes.count > 1 else { return nil }
        let connection = model.isConnection(index)
        var dropped: Set<Int> = [index]
        if !connection {
            for other in model.nodes.indices where model.isConnection(other) && model.nodes[other].body.count >= 32 {
                if Int(model.nodes[other].body.u32(8)) == index || Int(model.nodes[other].body.u32(28)) == index { dropped.insert(other) }
            }
        }
        var position: [Int: Int] = [:]
        var next = 0
        for old in model.nodes.indices where !dropped.contains(old) {
            position[old] = next
            next += 1
        }
        var kept: [(head: [UInt8], body: [UInt8])] = []
        for old in model.nodes.indices where !dropped.contains(old) { kept.append(model.nodes[old]) }
        let wasConnection = model.nodes.indices.filter { !dropped.contains($0) }.map { model.isConnection($0) }
        model.nodes = kept
        for slot in model.nodes.indices where wasConnection[slot] && model.nodes[slot].body.count >= 32 {
            guard let from = position[Int(model.nodes[slot].body.u32(8))], let to = position[Int(model.nodes[slot].body.u32(28))] else { return nil }
            GameFiles.put32(&model.nodes[slot].body, 8, UInt32(from))
            GameFiles.put32(&model.nodes[slot].body, 28, UInt32(to))
        }
        return model.serialized()
    }

    static func kdbDuplicate(_ b: [UInt8], node index: Int) -> [UInt8]? {
        guard var model = KdbModel.parse(b), index < model.nodes.count else { return nil }
        let place = model.isConnection(index) ? index + 1 : model.nodes.count
        model.nodes.insert(model.nodes[index], at: place)
        if place < model.nodes.count - 1 {
            for slot in model.nodes.indices where model.isConnection(slot) && model.nodes[slot].body.count >= 32 {
                for field in [8, 28] {
                    let value = Int(model.nodes[slot].body.u32(field))
                    if value >= place { GameFiles.put32(&model.nodes[slot].body, field, UInt32(value + 1)) }
                }
            }
        }
        return model.serialized()
    }
}
