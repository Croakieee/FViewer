import Foundation
import simd

typealias Vec3 = SIMD3<Float>
typealias Vec4 = SIMD4<Float>
typealias Mat4 = simd_float4x4

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> Float {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Float(z >> 40) / Float(1 << 24)
    }

    mutating func range(_ a: Float, _ b: Float) -> Float { a + (b - a) * next() }
}

struct RandomSeed {
    private let values: [Float]

    init(_ random: inout SeededRandom, count: Int = 16) {
        values = (0..<count).map { _ in random.next() }
    }

    func get(_ slot: Int) -> Float { values[slot % values.count] }
}
