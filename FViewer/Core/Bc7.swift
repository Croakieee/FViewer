import Foundation

enum Bc7 {
    private static let modes: [[Int]] = [
        [3, 4, 0, 0, 4, 0, 1, 0, 3, 0], [2, 6, 0, 0, 6, 0, 0, 1, 3, 0], [3, 6, 0, 0, 5, 0, 0, 0, 2, 0], [2, 6, 0, 0, 7, 0, 1, 0, 2, 0],
        [1, 0, 2, 1, 5, 6, 0, 0, 2, 3], [1, 0, 2, 0, 7, 8, 0, 0, 2, 2], [1, 0, 0, 0, 7, 7, 1, 0, 4, 0], [2, 6, 0, 0, 5, 5, 1, 0, 2, 0],
    ]
    private static let partitions2: [UInt32] = [0xcccc, 0x8888, 0xeeee, 0xecc8, 0xc880, 0xfeec, 0xfec8, 0xec80, 0xc800, 0xffec, 0xfe80, 0xe800, 0xffe8, 0xff00, 0xfff0, 0xf000, 0xf710, 0x008e, 0x7100, 0x08ce, 0x008c, 0x7310, 0x3100, 0x8cce, 0x088c, 0x3110, 0x6666, 0x366c, 0x17e8, 0x0ff0, 0x718e, 0x399c, 0xaaaa, 0xf0f0, 0x5a5a, 0x33cc, 0x3c3c, 0x55aa, 0x9696, 0xa55a, 0x73ce, 0x13c8, 0x324c, 0x3bdc, 0x6996, 0xc33c, 0x9966, 0x0660, 0x0272, 0x04e4, 0x4e40, 0x2720, 0xc936, 0x936c, 0x39c6, 0x639c, 0x9336, 0x9cc6, 0x817e, 0xe718, 0xccf0, 0x0fcc, 0x7744, 0xee22,]
    private static let partitions3: [UInt32] = [0xaa685050, 0x6a5a5040, 0x5a5a4200, 0x5450a0a8, 0xa5a50000, 0xa0a05050, 0x5555a0a0, 0x5a5a5050, 0xaa550000, 0xaa555500, 0xaaaa5500, 0x90909090, 0x94949494, 0xa4a4a4a4, 0xa9a59450, 0x2a0a4250, 0xa5945040, 0x0a425054, 0xa5a5a500, 0x55a0a0a0, 0xa8a85454, 0x6a6a4040, 0xa4a45000, 0x1a1a0500, 0x0050a4a4, 0xaaa59090, 0x14696914, 0x69691400, 0xa08585a0, 0xaa821414, 0x50a4a450, 0x6a5a0200, 0xa9a58000, 0x5090a0a8, 0xa8a09050, 0x24242424, 0x00aa5500, 0x24924924, 0x24499224, 0x50a50a50, 0x500aa550, 0xaaaa4444, 0x66660000, 0xa5a0a5a0, 0x50a050a0, 0x69286928, 0x44aaaa44, 0x66666600, 0xaa444444, 0x54a854a8, 0x95809580, 0x96969600, 0xa85454a8, 0x80959580, 0xaa141414, 0x96960000, 0xaaaa1414, 0xa05050a0, 0xa0a5a5a0, 0x96000000, 0x40804080, 0xa9a8a9a8, 0xaaaaaa44, 0x2a4a5254,]
    private static let anchors2: [Int] = [15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 2, 8, 2, 2, 8, 8, 15, 2, 8, 2, 2, 8, 8, 2, 2, 15, 15, 6, 8, 2, 8, 15, 15, 2, 8, 2, 2, 2, 15, 15, 6, 6, 2, 6, 8, 15, 15, 2, 2, 15, 15, 15, 15, 15, 2, 2, 15,]
    private static let anchors3a: [Int] = [3, 3, 15, 15, 8, 3, 15, 15, 8, 8, 6, 6, 6, 5, 3, 3, 3, 3, 8, 15, 3, 3, 6, 10, 5, 8, 8, 6, 8, 5, 15, 15, 8, 15, 3, 5, 6, 10, 8, 15, 15, 3, 15, 5, 15, 15, 15, 15, 3, 15, 5, 5, 5, 8, 5, 10, 5, 10, 8, 13, 15, 12, 3, 3,]
    private static let anchors3b: [Int] = [15, 8, 8, 3, 15, 15, 3, 8, 15, 15, 15, 15, 15, 15, 15, 8, 15, 8, 15, 3, 15, 8, 15, 8, 3, 15, 6, 10, 15, 15, 10, 8, 15, 3, 15, 10, 10, 8, 9, 10, 6, 15, 8, 15, 3, 6, 6, 8, 15, 3, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 3, 15, 15, 8,]
    private static let weights2 = [0, 21, 43, 64]
    private static let weights3 = [0, 9, 18, 27, 37, 46, 55, 64]
    private static let weights4 = [0, 4, 9, 13, 17, 21, 26, 30, 34, 38, 43, 47, 51, 55, 60, 64]

    private static func weights(_ bits: Int) -> [Int] { bits == 2 ? weights2 : bits == 3 ? weights3 : weights4 }

    static func decode(_ b: [UInt8], _ o: Int, _ out: inout [UInt8]) {
        var pos = 0
        func read(_ n: Int) -> Int {
            var v = 0
            for i in 0..<n {
                let byte = o + (pos >> 3)
                if byte < b.count { v |= Int((b[byte] >> UInt8(pos & 7)) & 1) << i }
                pos += 1
            }
            return v
        }
        var mode = -1
        for i in 0..<8 where mode < 0 {
            if read(1) != 0 { mode = i }
        }
        guard mode >= 0 else {
            for i in 0..<64 { out[i] = 0 }
            return
        }
        let m = modes[mode]
        let subsets = m[0], indexBits = m[8], index2Bits = m[9]
        let partition = read(m[1])
        let rotation = read(m[2])
        let indexSelection = read(m[3])
        let count = subsets * 2
        var endpoints = [[Int]](repeating: [0, 0, 0, 0], count: count)
        for c in 0..<3 {
            for e in 0..<count { endpoints[e][c] = read(m[4]) }
        }
        if m[5] > 0 {
            for e in 0..<count { endpoints[e][3] = read(m[5]) }
        }
        var colorBits = m[4], alphaBits = m[5]
        if m[6] > 0 {
            for e in 0..<count {
                let p = read(1)
                for c in 0..<4 { endpoints[e][c] = (endpoints[e][c] << 1) | p }
            }
            colorBits += 1
            if alphaBits > 0 { alphaBits += 1 }
        } else if m[7] > 0 {
            for s in 0..<subsets {
                let p = read(1)
                for e in [s * 2, s * 2 + 1] {
                    for c in 0..<4 { endpoints[e][c] = (endpoints[e][c] << 1) | p }
                }
            }
            colorBits += 1
        }
        func expand(_ value: Int, _ bits: Int) -> Int {
            let v = value << (8 - bits)
            return (v | (v >> bits)) & 255
        }
        let full = endpoints.map { e in
            [expand(e[0], colorBits), expand(e[1], colorBits), expand(e[2], colorBits), alphaBits > 0 ? expand(e[3], alphaBits) : 255]
        }
        func subset(_ i: Int) -> Int {
            if subsets == 2 { return Int((partitions2[partition] >> UInt32(i)) & 1) }
            if subsets == 3 { return Int((partitions3[partition] >> UInt32(2 * i)) & 3) }
            return 0
        }
        func anchor(_ i: Int) -> Bool {
            i == 0 || (subsets == 2 && i == anchors2[partition]) || (subsets == 3 && (i == anchors3a[partition] || i == anchors3b[partition]))
        }
        var first = [Int](repeating: 0, count: 16)
        for i in 0..<16 { first[i] = read(anchor(i) ? indexBits - 1 : indexBits) }
        var second = [Int](repeating: 0, count: 16)
        if index2Bits > 0 {
            for i in 0..<16 { second[i] = read(i == 0 ? index2Bits - 1 : index2Bits) }
        }
        let firstWeights = weights(indexBits), secondWeights = weights(index2Bits)
        for i in 0..<16 {
            let s = subset(i)
            let e0 = full[s * 2], e1 = full[s * 2 + 1]
            var colorWeight = firstWeights[first[i]]
            var alphaWeight = colorWeight
            if index2Bits > 0 {
                if indexSelection == 0 { alphaWeight = secondWeights[second[i]] } else { colorWeight = secondWeights[second[i]] }
            }
            var px = [0, 0, 0, 0]
            for c in 0..<3 { px[c] = ((64 - colorWeight) * e0[c] + colorWeight * e1[c] + 32) >> 6 }
            px[3] = ((64 - alphaWeight) * e0[3] + alphaWeight * e1[3] + 32) >> 6
            if rotation >= 1 && rotation <= 3 { px.swapAt(rotation - 1, 3) }
            for c in 0..<4 { out[i * 4 + c] = UInt8(truncatingIfNeeded: px[c]) }
        }
    }
}
