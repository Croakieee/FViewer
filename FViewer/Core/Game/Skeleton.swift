import Foundation
import simd

struct GameSkeleton {
    var names: [String]
    var parents: [Int]
    var world: [simd_float4x4]

    func position(_ index: Int) -> SIMD3<Float> {
        let c = world[index].columns.3
        return SIMD3(c.x, c.y, c.z)
    }

    static func parse(_ bytes: [UInt8]) -> GameSkeleton? {
        guard bytes.count > 0x40, bytes[0] == 0x62, bytes[1] == 0x6C, bytes[2] == 0x6B, bytes[3] == 0x73 else { return nil }
        let start = bytes.u16(6) == 0x3133 ? Int(bytes.u32(12)) : Int(bytes.u16(10))
        guard start > 0, start < bytes.count - 48 else { return nil }
        let hk = Array(bytes[start...])
        let n = hk.count
        func float(_ at: Int) -> Float { Float(bitPattern: hk.u32(at)) }
        func isPose(_ o: Int) -> Bool {
            guard o + 48 <= n else { return false }
            var norm: Float = 0
            for k in 4..<8 { norm += float(o + k * 4) * float(o + k * 4) }
            guard abs(norm - 1) < 2e-3 else { return false }
            for k in 0..<3 where !(abs(float(o + k * 4)) < 1e4) { return false }
            for k in 8..<11 {
                let s = abs(float(o + k * 4))
                if !(s > 1e-3 && s < 1e3) { return false }
            }
            return true
        }
        var runs: [(offset: Int, count: Int)] = []
        var o = 0
        while o < n - 48 {
            if isPose(o) {
                var k = 0
                while isPose(o + 48 * k) { k += 1 }
                runs.append((o, k))
                o += k > 1 ? 48 * k : 1
            } else {
                o += 1
            }
        }
        guard let longest = runs.map(\.count).max(), longest > 0 else { return nil }
        func varint(_ at: inout Int) -> Int? {
            var value = 0, shift = 0
            while at < n, shift < 35 {
                let b = Int(hk[at])
                at += 1
                value |= (b & 0x7F) << shift
                shift += 7
                if b & 0x80 == 0 { return value }
            }
            return nil
        }
        func signed(_ v: Int) -> Int { v & 1 != 0 ? -(v >> 1) : v >> 1 }
        var best: GameSkeleton?
        var from = 0
        while from < n - 2 {
            defer { from += 1 }
            var at = from
            guard let c = varint(&at), c >= 2, c % 2 == 0, c / 2 <= longest, c / 2 > (best?.names.count ?? 0), at < n, hk[at] == 8 else { continue }
            let count = c / 2
            at += 1
            var parents: [Int] = []
            var good = true
            for i in 0..<count {
                guard let v = varint(&at) else { good = false; break }
                let p = signed(v)
                if p < -1 || p >= i { good = false; break }
                parents.append(p)
            }
            guard good, parents.first == -1, let c2 = varint(&at), c2 == count * 2 else { continue }
            at += 1
            var names: [String] = []
            for _ in 0..<count {
                guard let raw = varint(&at) else { good = false; break }
                let length = signed(raw)
                guard length > 0, length <= 64, at + length <= n else { good = false; break }
                names.append(String(decoding: hk[at..<at + length], as: UTF8.self))
                at += length
            }
            guard good, names.count == count else { continue }
            guard let pose = runs.first(where: { $0.offset > from && $0.count == count })?.offset
                ?? runs.first(where: { $0.offset > from && $0.count >= count })?.offset
                ?? runs.first(where: { $0.count == count })?.offset else { continue }
            var world: [simd_float4x4] = []
            for i in 0..<count {
                let b = pose + i * 48
                let t = SIMD3(float(b), float(b + 4), float(b + 8))
                let q = simd_quatf(ix: float(b + 16), iy: float(b + 20), iz: float(b + 24), r: float(b + 28))
                let s = SIMD3(float(b + 32), float(b + 36), float(b + 40))
                var local = simd_float4x4(q) * simd_float4x4(diagonal: SIMD4(s.x, s.y, s.z, 1))
                local.columns.3 = SIMD4(t.x, t.y, t.z, 1)
                world.append(parents[i] >= 0 ? world[parents[i]] * local : local)
            }
            best = GameSkeleton(names: names, parents: parents, world: world)
        }
        return best
    }

}
