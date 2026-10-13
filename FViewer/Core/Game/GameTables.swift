import Foundation
import simd

struct AtchState {
    var bone: String
    var scale: Float
    var offset: SIMD3<Float>
    var rotation: SIMD3<Float>
}

struct AtchEntry: Identifiable {
    let id: Int
    var name: String
    var accessory: Bool
    var states: [AtchState]
}

struct AtchTable {
    var stateCount: Int
    var entries: [AtchEntry]
    var order: [String] = []

    static let weaponNames: [String: String] = {
        guard let url = Bundle.main.url(forResource: "atch_names", withExtension: "txt"), let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var result: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "\t", maxSplits: 1)
            if parts.count == 2 { result[String(parts[0])] = String(parts[1]) }
        }
        return result
    }()

    static func parse(_ b: [UInt8]) -> AtchTable? {
        guard b.count >= 36 else { return nil }
        let count = Int(b.u16(0)), states = Int(b.u16(2))
        let bits = 4 + count * 4, body = bits + 32
        guard count > 0, count <= 256, states > 0, states < 64, body + count * states * 32 <= b.count else { return nil }
        var entries: [AtchEntry] = []
        for index in 0..<count {
            let name = String(GameFiles.string(b, 4 + index * 4, max: 4).reversed())
            var list: [AtchState] = []
            for state in 0..<states {
                let at = body + (index * states + state) * 32
                func f(_ slot: Int) -> Float { Float(bitPattern: b.u32(at + slot * 4)) }
                list.append(AtchState(bone: GameFiles.string(b, Int(b.u32(at)), max: 64), scale: f(1), offset: SIMD3(f(2), f(3), f(4)), rotation: SIMD3(f(5), f(6), f(7))))
            }
            entries.append(AtchEntry(id: index, name: name, accessory: b[bits + index / 8] >> UInt8(index % 8) & 1 == 1, states: list))
        }
        var order: [String] = []
        var at = body + count * states * 32
        while at < b.count {
            let text = GameFiles.string(b, at, max: 64)
            order.append(text)
            at += text.utf8.count + 1
        }
        return AtchTable(stateCount: states, entries: entries, order: order)
    }

    mutating func addEntry(after index: Int) {
        let source = index < entries.count ? entries[index] : nil
        let states = source?.states ?? (0..<stateCount).map { _ in AtchState(bone: "n_root", scale: 1, offset: .zero, rotation: .zero) }
        entries.insert(AtchEntry(id: 0, name: "new", accessory: source?.accessory ?? false, states: states), at: min(index + 1, entries.count))
        entries = entries.enumerated().map { AtchEntry(id: $0, name: $1.name, accessory: $1.accessory, states: $1.states) }
    }

    mutating func removeEntry(_ index: Int) {
        guard entries.count > 1, index < entries.count else { return }
        entries.remove(at: index)
        entries = entries.enumerated().map { AtchEntry(id: $0, name: $1.name, accessory: $1.accessory, states: $1.states) }
    }

    func serialized() -> [UInt8] {
        var out: [UInt8] = []
        out.appendU16(UInt16(entries.count))
        out.appendU16(UInt16(stateCount))
        for entry in entries {
            var name = Array(String(entry.name.reversed()).utf8.prefix(3))
            while name.count < 4 { name.append(0) }
            out.append(contentsOf: name)
        }
        var bits = [UInt8](repeating: 0, count: 32)
        for (index, entry) in entries.enumerated() where entry.accessory && index < 256 { bits[index / 8] |= 1 << UInt8(index % 8) }
        out.append(contentsOf: bits)
        let stringStart = out.count + entries.count * stateCount * 32
        var strings: [UInt8] = []
        var positions: [String: Int] = [:]
        let used = Set(entries.flatMap { $0.states.map(\.bone) })
        for name in order where used.contains(name) && positions[name] == nil {
            positions[name] = stringStart + strings.count
            strings.append(contentsOf: Array(name.utf8) + [0])
        }
        for entry in entries {
            for slot in 0..<stateCount {
                let state = slot < entry.states.count ? entry.states[slot] : AtchState(bone: "", scale: 1, offset: .zero, rotation: .zero)
                if positions[state.bone] == nil {
                    positions[state.bone] = stringStart + strings.count
                    strings.append(contentsOf: Array(state.bone.utf8) + [0])
                }
                out.appendU32(UInt32(positions[state.bone] ?? stringStart))
                for value in [state.scale, state.offset.x, state.offset.y, state.offset.z, state.rotation.x, state.rotation.y, state.rotation.z] { out.appendU32(value.bitPattern) }
            }
        }
        out.append(contentsOf: strings)
        return out
    }
}

struct MtrlLayout {
    var flagsAt: Int?
    var tableAt: Int
    var rows: Int
    var rowWidth: Int
    var shaderFlagsAt: Int
    var keys: [Int]
    var constants: [(at: Int, valuesAt: Int, count: Int)]
    var samplers: [Int]

    static func parse(_ b: [UInt8]) -> MtrlLayout? {
        guard b.count >= 16 else { return nil }
        let dataSize = Int(b.u16(6)), stringSize = Int(b.u16(8))
        let names = Int(b[12]) + Int(b[13]) + Int(b[14]), extra = Int(b[15])
        let extraAt = 16 + names * 4 + stringSize
        let tableAt = extraAt + extra
        let shader = tableAt + dataSize
        guard shader + 12 <= b.count else { return nil }
        let hasTable = extra > 0 && b[extraAt] & 0x4 != 0
        var rows = 0, width = 0
        if hasTable, dataSize >= 2048 {
            rows = 32
            width = 32
        } else if hasTable, dataSize >= 512 {
            rows = 16
            width = 16
        }
        let valueSize = Int(b.u16(shader)), keyCount = Int(b.u16(shader + 2)), constantCount = Int(b.u16(shader + 4)), samplerCount = Int(b.u16(shader + 6))
        let keysAt = shader + 12, constantsAt = keysAt + keyCount * 8, samplersAt = constantsAt + constantCount * 8, valuesAt = samplersAt + samplerCount * 12
        guard valuesAt + valueSize <= b.count else { return nil }
        var constants: [(Int, Int, Int)] = []
        for index in 0..<constantCount {
            let at = constantsAt + index * 8
            let offset = Int(b.u16(at + 4)), size = Int(b.u16(at + 6))
            guard offset + size <= valueSize else { continue }
            constants.append((at, valuesAt + offset, size / 4))
        }
        return MtrlLayout(flagsAt: extra > 0 ? extraAt : nil, tableAt: tableAt, rows: rows, rowWidth: width, shaderFlagsAt: shader + 8,
                          keys: (0..<keyCount).map { keysAt + $0 * 8 }, constants: constants, samplers: (0..<samplerCount).map { samplersAt + $0 * 12 })
    }
}

extension GameFiles {
    static func half(_ raw: UInt16) -> Float { CurveMath.halfToFloat(raw) }

    static func halfBits(_ value: Float) -> UInt16 {
        if value == 0 || !value.isFinite { return value.sign == .minus && value == 0 ? 0x8000 : 0 }
        let sign: UInt16 = value < 0 ? 0x8000 : 0
        let magnitude = abs(value)
        var exponent = Int(floor(log2(magnitude)))
        if exponent > 15 { return sign | 0x7BFF }
        if exponent < -14 {
            let mantissa = Int(safe: (magnitude / powf(2, -14) * 1024).rounded())
            return sign | UInt16(min(mantissa, 1023))
        }
        var mantissa = Int(safe: ((magnitude / powf(2, Float(exponent)) - 1) * 1024).rounded())
        if mantissa == 1024 {
            mantissa = 0
            exponent += 1
            if exponent > 15 { return sign | 0x7BFF }
        }
        return sign | UInt16(exponent + 15) << 10 | UInt16(mantissa)
    }
}
