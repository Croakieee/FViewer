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

enum Math3D {
    private static let orders: [[Int]] = [[0, 1, 2], [1, 2, 0], [2, 0, 1], [0, 2, 1], [1, 0, 2], [2, 1, 0]]
    private static let axes: [Vec3] = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)]

    static func euler(_ rotation: Vec3, order: Int) -> simd_quatf {
        let letters = orders[order >= 0 && order < orders.count ? order : 0]
        var q = simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
        for axis in letters {
            q = simd_quatf(angle: rotation[axis], axis: axes[axis]) * q
        }
        return q
    }

    static func translation(_ t: Vec3) -> Mat4 {
        var m = matrix_identity_float4x4
        m.columns.3 = Vec4(t.x, t.y, t.z, 1)
        return m
    }

    static func rotationY(_ angle: Float) -> Mat4 { Mat4(simd_quatf(angle: angle, axis: Vec3(0, 1, 0))) }
    static func rotationX(_ angle: Float) -> Mat4 { Mat4(simd_quatf(angle: angle, axis: Vec3(1, 0, 0))) }

    static func compose(_ position: Vec3, _ rotation: simd_quatf, _ scale: Vec3) -> Mat4 {
        var m = Mat4(rotation)
        m.columns.0 *= scale.x
        m.columns.1 *= scale.y
        m.columns.2 *= scale.z
        m.columns.3 = Vec4(position.x, position.y, position.z, 1)
        return m
    }

    static func compose(_ position: Vec3, _ rotation: simd_quatf, _ scale: Vec3, order: Int) -> Mat4 {
        guard order >= 1, order <= 5 else { return compose(position, rotation, scale) }
        var t = matrix_identity_float4x4
        t.columns.3 = Vec4(position.x, position.y, position.z, 1)
        let r = Mat4(rotation)
        let s = Mat4(diagonal: Vec4(scale.x, scale.y, scale.z, 1))
        switch order {
        case 1: return r * s * t
        case 2: return s * t * r
        case 3: return s * r * t
        case 4: return r * t * s
        default: return t * s * r
        }
    }

    static func decompose(_ m: Mat4) -> (position: Vec3, rotation: simd_quatf, scale: Vec3) {
        let c0 = Vec3(m.columns.0.x, m.columns.0.y, m.columns.0.z)
        let c1 = Vec3(m.columns.1.x, m.columns.1.y, m.columns.1.z)
        let c2 = Vec3(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        var sx = simd_length(c0)
        let sy = simd_length(c1), sz = simd_length(c2)
        if simd_dot(simd_cross(c0, c1), c2) < 0 { sx = -sx }
        let position = Vec3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        guard abs(sx) > 1e-12, sy > 1e-12, sz > 1e-12 else {
            return (position, simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), Vec3(sx, sy, sz))
        }
        let rotation = simd_quatf(simd_float3x3(columns: (c0 / sx, c1 / sy, c2 / sz)))
        return (position, simd_normalize(rotation), Vec3(sx, sy, sz))
    }

    static func position(_ m: Mat4) -> Vec3 { Vec3(m.columns.3.x, m.columns.3.y, m.columns.3.z) }

    static func point(_ m: Mat4, _ p: Vec3) -> Vec3 {
        let r = m * Vec4(p.x, p.y, p.z, 1)
        return Vec3(r.x, r.y, r.z)
    }

    static func vector(_ m: Mat4, _ v: Vec3) -> Vec3 {
        let r = m * Vec4(v.x, v.y, v.z, 0)
        return Vec3(r.x, r.y, r.z)
    }

    static func direction(_ m: Mat4, _ v: Vec3) -> Vec3 {
        let r = vector(m, v)
        let length = simd_length(r)
        return length > 1e-12 ? r / length : r
    }

    static func basis(_ x: Vec3, _ y: Vec3, _ z: Vec3, origin: Vec3 = .zero) -> Mat4 {
        Mat4(columns: (Vec4(x.x, x.y, x.z, 0), Vec4(y.x, y.y, y.z, 0), Vec4(z.x, z.y, z.z, 0), Vec4(origin.x, origin.y, origin.z, 1)))
    }

    static func quaternion(x: Vec3, y: Vec3, z: Vec3) -> simd_quatf {
        simd_normalize(simd_quatf(simd_float3x3(columns: (x, y, z))))
    }
}
