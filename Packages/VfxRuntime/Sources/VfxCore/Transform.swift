import Foundation
import simd

public struct Vec3 {
    public var x: Double
    public var y: Double
    public var z: Double
    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    public static let zero = Vec3(x: 0, y: 0, z: 0)
    public static let one = Vec3(x: 1, y: 1, z: 1)
}

private func rad(_ deg: Double) -> Double { deg * .pi / 180 }

public struct Affine3 {
    public var linear = matrix_identity_double3x3
    public var translation = SIMD3<Double>(0, 0, 0)

    public init() {}

    public static let identity = Affine3()

    public func appending(_ o: Affine3) -> Affine3 {
        var r = Affine3()
        r.linear = linear * o.linear
        r.translation = linear * o.translation + translation
        return r
    }

    public static func local(position p: Vec3, rotation r: Vec3, order: RotationOrder, scale s: Vec3) -> Affine3 {
        var a = Affine3()
        a.translation = SIMD3(p.x, p.y, p.z)
        let axes = Array(order.rawValue)
        for i in stride(from: 2, through: 0, by: -1) {
            switch axes[i] {
            case "x": a.turn(1, 2, r.x)
            case "y": a.turn(2, 0, r.y)
            default: a.turn(0, 1, r.z)
            }
        }
        a.linear.columns.0 *= s.x
        a.linear.columns.1 *= s.y
        a.linear.columns.2 *= s.z
        return a
    }

    public static func rotation(_ r: Vec3, _ order: RotationOrder) -> Affine3 {
        local(position: .zero, rotation: r, order: order, scale: .one)
    }

    private mutating func turn(_ i: Int, _ j: Int, _ degrees: Double) {
        if degrees == 0 { return }
        let c = cos(rad(degrees)), s = sin(rad(degrees))
        let a = linear[i], b = linear[j]
        linear[i] = c * a + s * b
        linear[j] = -s * a + c * b
    }

    public func apply(_ x: Double, _ y: Double, _ z: Double) -> Vec3 {
        let v = linear * SIMD3(x, y, z) + translation
        return Vec3(x: v.x, y: v.y, z: v.z)
    }

    public var float4x4: simd_float4x4 {
        let l = linear
        return simd_float4x4(columns: (
            SIMD4<Float>(Float(l[0][0]), Float(l[0][1]), Float(l[0][2]), 0),
            SIMD4<Float>(Float(l[1][0]), Float(l[1][1]), Float(l[1][2]), 0),
            SIMD4<Float>(Float(l[2][0]), Float(l[2][1]), Float(l[2][2]), 0),
            SIMD4<Float>(Float(translation.x), Float(translation.y), Float(translation.z), 1)))
    }
}
