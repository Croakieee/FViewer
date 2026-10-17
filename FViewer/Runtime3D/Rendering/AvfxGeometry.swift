import Foundation
import simd

struct EmitPoint {
    var position: Vec3
    var normal: Vec3
}

final class RenderGeometry {
    static let stride = 18
    var vertices: [Float] = []
    var indices: [UInt32] = []
    var version = 0
    var cacheKey = ""

    var vertexCount: Int { vertices.count / RenderGeometry.stride }

    func add(_ position: Vec3, normal: Vec3 = Vec3(0, 0, 1), color: Vec4 = Vec4(1, 1, 1, 1), uv: SIMD2<Float>, uv2: SIMD2<Float>? = nil,
             uv3: SIMD2<Float>? = nil, uv4: SIMD2<Float>? = nil) {
        let b = uv2 ?? uv, c = uv3 ?? uv, d = uv4 ?? uv
        vertices.append(contentsOf: [position.x, position.y, position.z, normal.x, normal.y, normal.z, color.x, color.y, color.z, color.w,
                                     uv.x, uv.y, b.x, b.y, c.x, c.y, d.x, d.y])
    }

    func setPosition(_ i: Int, _ p: Vec3) {
        let o = i * RenderGeometry.stride
        vertices[o] = p.x
        vertices[o + 1] = p.y
        vertices[o + 2] = p.z
    }

    func setColor(_ i: Int, _ c: Vec4) {
        let o = i * RenderGeometry.stride + 6
        vertices[o] = c.x
        vertices[o + 1] = c.y
        vertices[o + 2] = c.z
        vertices[o + 3] = c.w
    }
}

struct DiscShape: Equatable {
    var angle: Float
    var radiusBegin: Float
    var radiusEnd: Float
    var widthBegin: Float
    var widthEnd: Float
    var heightBeginInner: Float
    var heightEndInner: Float
    var heightBeginOuter: Float
    var heightEndOuter: Float
}

enum GeometryBuilder {
    static let ringSegments = 128
    static let ringRows = 16

    static let quad: RenderGeometry = {
        let g = RenderGeometry()
        for (x, y) in [(Float(-0.5), Float(0.5)), (0.5, 0.5), (-0.5, -0.5), (0.5, -0.5)] {
            g.add(Vec3(x, y, 0), uv: SIMD2(x, -y))
        }
        g.indices = [0, 2, 1, 2, 3, 1]
        return g
    }()

    static let decal: RenderGeometry = {
        let g = RenderGeometry()
        for (x, y) in [(Float(-0.5), Float(0.5)), (0.5, 0.5), (-0.5, -0.5), (0.5, -0.5)] {
            g.add(Vec3(x, 0.01, -y), normal: Vec3(0, 1, 0), uv: SIMD2(-x, y))
        }
        g.indices = [0, 2, 1, 2, 3, 1]
        return g
    }()

    static let box: RenderGeometry = {
        let g = RenderGeometry()
        for i in 0..<8 {
            g.add(Vec3(i & 1 == 0 ? -0.5 : 0.5, i & 2 == 0 ? -0.5 : 0.5, i & 4 == 0 ? -0.5 : 0.5), normal: Vec3(0, 1, 0), uv: .zero)
        }
        g.indices = [0, 2, 1, 1, 2, 3, 4, 5, 6, 5, 7, 6, 0, 1, 4, 1, 5, 4, 2, 6, 3, 3, 6, 7, 0, 4, 2, 2, 4, 6, 1, 3, 5, 3, 7, 5]
        return g
    }()

    static let laser: RenderGeometry = {
        let g = RenderGeometry()
        let positions = [Vec3(-0.5, 0, 0), Vec3(0.5, 0, 0), Vec3(-0.5, 0, 1), Vec3(0.5, 0, 1)]
        let uvs = [SIMD2<Float>(-0.5, 0.5), SIMD2(0.5, 0.5), SIMD2(-0.5, -0.5), SIMD2(0.5, -0.5)]
        for i in 0..<4 { g.add(positions[i], normal: Vec3(0, 1, 0), uv: uvs[i]) }
        g.indices = [0, 2, 1, 1, 2, 3]
        return g
    }()

    private static var windmills: [RenderGeometry?] = [nil, nil]

    static func windmill(mirror: Bool) -> RenderGeometry {
        let slot = mirror ? 1 : 0
        if let cached = windmills[slot] { return cached }
        let g = RenderGeometry()
        let h: Float = 0.5
        let signs: [(Float, Float)] = [(1, 1), (-1, 1), (-1, -1), (1, -1)]
        for k in 0..<4 {
            let c = cos(Float(k) * .pi / 2), s = sin(Float(k) * .pi / 2)
            let (sx, sy) = signs[k]
            let base = UInt32(g.vertexCount)
            for (a, b) in [(Float(0), Float(0)), (h, 0), (h, h), (0, h)] {
                let position = mirror ? Vec3(sx * a, sy * b, 0) : Vec3(a * c - b * s, a * s + b * c, 0)
                g.add(position, uv: SIMD2(0.5 - 2 * a, 0.5 - 2 * b))
            }
            if mirror && sx * sy < 0 {
                g.indices.append(contentsOf: [base, base + 2, base + 1, base, base + 3, base + 2])
            } else {
                g.indices.append(contentsOf: [base, base + 1, base + 2, base, base + 2, base + 3])
            }
        }
        windmills[slot] = g
        return g
    }

    static func ringAngle(fan: Float) -> Float {
        2 * acos(1 - 2 * min(max(fan, 0), 1))
    }

    static func decalRing(fan: Float) -> RenderGeometry {
        let g = RenderGeometry()
        let n = ringSegments, m = ringRows
        let share = ringAngle(fan: fan) / (2 * .pi)
        for i in 0...n {
            let v = 0.5 + (Float(i) / Float(n) - 0.5) * share
            for j in 0...m {
                g.add(.zero, normal: Vec3(0, 1, 0), uv: SIMD2(Float(j) / Float(m) - 0.5, v - 0.5))
            }
            if i < n {
                for j in 0..<m {
                    let a = UInt32(i * (m + 1) + j), b = a + UInt32(m + 1)
                    g.indices.append(contentsOf: [a, a + 1, b, a + 1, b + 1, b])
                }
            }
        }
        g.cacheKey = ""
        return g
    }

    private static var rings: [String: RenderGeometry] = [:]
    private static var ringOrder: [String] = []

    static func ring(fan: Float, inner: Float, outer: Float) -> RenderGeometry {
        func step(_ value: Float) -> Float { (value * 1024).rounded() / 1024 }
        let a = step(inner), b = step(outer)
        let key = "\(fan)|\(a)|\(b)"
        if let known = rings[key] { return known }
        let g = decalRing(fan: fan)
        setRingRadii(g, fan: fan, inner: a, outer: b)
        rings[key] = g
        ringOrder.append(key)
        while ringOrder.count > 64 { rings[ringOrder.removeFirst()] = nil }
        return g
    }

    static func setRingRadii(_ g: RenderGeometry, fan: Float, inner innerRadius: Float, outer outerRadius: Float) {
        let outer = max(0, outerRadius)
        let inner = max(0, min(outer, innerRadius))
        let key = "\(inner),\(outer)"
        if g.cacheKey == key { return }
        g.cacheKey = key
        let angle = ringAngle(fan: fan)
        let n = ringSegments, m = ringRows
        for i in 0...n {
            let t = (Float(i) / Float(n) - 0.5) * angle
            let c = sin(t), s = cos(t)
            for j in 0...m {
                let r = outer + (inner - outer) * Float(j) / Float(m)
                g.setPosition(i * (m + 1) + j, Vec3(c * r, 0.01, s * r))
            }
        }
        g.version += 1
    }

    static func disc(countU: Int, countV: Int, intervalFactorV: Float = 0) -> RenderGeometry {
        let nu = max(2, countU), nv = max(2, countV)
        let g = RenderGeometry()
        let factor = min(max(intervalFactorV, -0.5), 0.5)
        for j in 0..<nv {
            let f = Float(j) / Float(nv - 1)
            let v = f + 2 * factor * f * (1 - f)
            for i in 0..<nu {
                let k = Float(i) / Float(nu - 1)
                g.add(.zero, normal: Vec3(0, 1, 0), uv: SIMD2((1 - k) - 0.5, v - 0.5))
                if i < nu - 1 && j < nv - 1 {
                    let a = UInt32(i + j * nu), b = a + UInt32(nu)
                    g.indices.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
                }
            }
        }
        return g
    }

    static func setDisc(_ g: RenderGeometry, countU: Int, countV: Int, shape s: DiscShape, inner: Vec4, outer: Vec4) {
        let nu = max(2, countU), nv = max(2, countV)
        let key = "\(s)|\(inner)|\(outer)"
        if g.cacheKey == key { return }
        g.cacheKey = key
        for j in 0..<nv {
            let f = Float(j) / Float(nv - 1)
            let a = f * s.angle
            let c = cos(a), sn = -sin(a)
            let r = s.radiusBegin + (s.radiusEnd - s.radiusBegin) * f
            let w = s.widthBegin + (s.widthEnd - s.widthBegin) * f
            let hi = s.heightBeginInner + (s.heightEndInner - s.heightBeginInner) * f
            let ho = s.heightBeginOuter + (s.heightEndOuter - s.heightBeginOuter) * f
            for i in 0..<nu {
                let k = Float(i) / Float(nu - 1)
                let rr = r + w - 2 * w * k
                g.setPosition(i + j * nu, Vec3(c * rr, ho + (hi - ho) * k, sn * rr))
                g.setColor(i + j * nu, outer + (inner - outer) * k)
            }
        }
        g.version += 1
    }

    static func model(_ block: AvfxBlock) -> RenderGeometry? {
        guard let v = block.child("VDrw")?.data, let idx = block.child("VIdx")?.data, v.count >= 36 else { return nil }
        let g = RenderGeometry()
        for o in stride(from: 0, to: v.count - 35, by: 36) {
            func half(_ at: Int) -> Float { CurveMath.halfToFloat(v.u16(o + at)) }
            func signed(_ at: Int) -> Float { (Float(v[o + at]) - 128) / 127 }
            func unit(_ at: Int) -> Float { Float(v[o + at]) / 255 }
            g.add(Vec3(half(0), half(2), half(4)), normal: Vec3(signed(8), signed(9), signed(10)),
                  color: Vec4(unit(16), unit(17), unit(18), unit(19)), uv: SIMD2(half(20), half(22)), uv2: SIMD2(half(24), half(26)),
                  uv3: SIMD2(half(28), half(30)), uv4: SIMD2(half(32), half(34)))
        }
        let total = UInt16(min(g.vertexCount, 65535))
        for o in stride(from: 0, to: idx.count - 5, by: 6) {
            let a = idx.u16(o), b = idx.u16(o + 2), c = idx.u16(o + 4)
            if a < total, b < total, c < total { g.indices.append(contentsOf: [UInt32(a), UInt32(b), UInt32(c)]) }
        }
        return g
    }

    static func emitPoints(_ block: AvfxBlock?) -> [EmitPoint] {
        guard let e = block?.child("VEmt")?.data else { return [] }
        let all = stride(from: 0, to: e.count - 27, by: 28).map { o in
            EmitPoint(position: Vec3(e.f32(o), e.f32(o + 4), e.f32(o + 8)), normal: Vec3(e.f32(o + 12), e.f32(o + 16), e.f32(o + 20)))
        }
        guard let order = block?.child("VNum")?.data, order.count >= 2, PreviewRules.isOn("vertexOrder") else { return all }
        let picked = stride(from: 0, to: order.count - 1, by: 2).compactMap { o -> EmitPoint? in
            let index = Int(order.u16(o))
            return index < all.count ? all[index] : nil
        }
        return picked.isEmpty ? all : picked
    }
}
