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
            for kind in 0..<5 { for blob in shapes[kind] { out.append(contentsOf: blob) } }
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
    static func phybRemove(_ b: [UInt8], _ slot: RecordSlot) -> [UInt8]? {
        guard var model = PhybModel.parse(b) else { return nil }
        switch slot {
        case .shape(let kind, let index): model.shapes[kind].remove(at: index)
        case .parameters(let simulator): model.simulators.remove(at: simulator)
        case .item(let simulator, let list, let index): model.simulators[simulator].lists[list].remove(at: index)
        case .chain(let simulator, let index): model.simulators[simulator].chains.remove(at: index)
        case .chainCollision(let simulator, let chain, let index): model.simulators[simulator].chains[chain].collisions.remove(at: index)
        case .node(let simulator, let chain, let index): model.simulators[simulator].chains[chain].nodes.remove(at: index)
        case .variant: return nil
        }
        return model.serialized()
    }

    static func phybDuplicate(_ b: [UInt8], _ slot: RecordSlot) -> [UInt8]? {
        guard var model = PhybModel.parse(b) else { return nil }
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
        guard variant >= 1, variant <= count, 4 + (count + 1) * size <= b.count else { return nil }
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
        out.append(contentsOf: [UInt8(textures.count), UInt8(uvSets.count), UInt8(colorSets.count), UInt8(extra.count)])
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
            guard slope == end, slope + 32 <= b.count else { return nil }
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
            for group in groups { out.append(UInt8(min(group.elements.count, 255))) }
            for item in parameters { out.append(contentsOf: item) }
            for group in groups {
                out.append(contentsOf: group.id)
                out.append(UInt8(min(group.elements.count, 255)))
                for element in group.elements { out.append(contentsOf: element) }
            }
        }
        if hasSlope {
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
            if remove { model.parameters.remove(at: index) } else { model.parameters.insert(model.parameters[index], at: index + 1) }
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

    static func skpAddElement(_ b: [UInt8], group: Int) -> [UInt8]? {
        guard var model = SkpModel.parse(b), group < model.groups.count else { return nil }
        model.groups[group].elements.append([UInt8](repeating: 0, count: 66))
        return model.serialized()
    }

    static func physicsLines(_ b: [UInt8], skeleton: GameSkeleton) -> [(SIMD3<Float>, SIMD3<Float>)] {
        guard let model = PhybModel.parse(b) else { return [] }
        var lines: [(SIMD3<Float>, SIMD3<Float>)] = []
        func bone(_ blob: [UInt8], _ at: Int) -> simd_float4x4? {
            let name = GameFiles.string(blob, at, max: 32)
            guard let index = skeleton.names.firstIndex(of: name), index < skeleton.world.count else { return nil }
            return skeleton.world[index]
        }
        func point(_ matrix: simd_float4x4, _ blob: [UInt8], _ at: Int) -> SIMD3<Float> {
            let v = matrix * SIMD4(GameFiles.f32(blob, at), GameFiles.f32(blob, at + 4), GameFiles.f32(blob, at + 8), 1)
            return SIMD3(v.x, v.y, v.z)
        }
        func ball(_ center: SIMD3<Float>, _ radius: Float) {
            guard radius > 0 else { return }
            for axis in 0..<3 {
                var last: SIMD3<Float>?
                for step in 0...20 {
                    let turn = Float(step) / 20 * 2 * .pi
                    var offset = SIMD3<Float>(0, 0, 0)
                    offset[(axis + 1) % 3] = cos(turn) * radius
                    offset[(axis + 2) % 3] = sin(turn) * radius
                    if let last { lines.append((last, center + offset)) }
                    last = center + offset
                }
            }
        }
        for blob in model.shapes[0] {
            guard let start = bone(blob, 32), let end = bone(blob, 64) else { continue }
            let a = point(start, blob, 96), c = point(end, blob, 108), radius = GameFiles.f32(blob, 120)
            lines.append((a, c))
            ball(a, radius)
            ball(c, radius)
        }
        for blob in model.shapes[4] {
            guard let matrix = bone(blob, 32) else { continue }
            ball(point(matrix, blob, 64), GameFiles.f32(blob, 76) / 2)
        }
        for simulator in model.simulators {
            for chain in simulator.chains {
                var last: SIMD3<Float>?
                for node in chain.nodes {
                    guard let matrix = bone(node, 0) else {
                        last = nil
                        continue
                    }
                    let c = matrix.columns.3
                    let here = SIMD3(c.x, c.y, c.z)
                    if let last { lines.append((last, here)) }
                    ball(here, GameFiles.f32(node, 32))
                    last = here
                }
            }
        }
        return lines
    }
}
