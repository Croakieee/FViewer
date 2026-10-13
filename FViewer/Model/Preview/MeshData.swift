import Foundation
import simd

struct MeshVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
    var uv: SIMD2<Float>
}

struct MeshData {
    var vertices: [MeshVertex] = []
    var indices: [UInt32] = []
    var emitPoints: [MeshVertex] = []

    var bounds: (min: SIMD3<Float>, max: SIMD3<Float>)? {
        let points = vertices.map(\.position) + emitPoints.map(\.position)
        guard var lo = points.first else { return nil }
        var hi = lo
        for p in points {
            lo = simd_min(lo, p)
            hi = simd_max(hi, p)
        }
        return (lo, hi)
    }

    static func fromAvfx(_ model: AvfxBlock) -> MeshData {
        var mesh = MeshData()
        if let v = model.child("VDrw")?.data {
            for o in stride(from: 0, to: v.count - 35, by: 36) {
                func half(_ at: Int) -> Float { CurveMath.halfToFloat(v.u16(o + at)) }
                func signed(_ at: Int) -> Float { (Float(v[o + at]) - 128) / 127 }
                func unit(_ at: Int) -> Float { Float(v[o + at]) / 255 }
                mesh.vertices.append(MeshVertex(
                    position: SIMD3(half(0), half(2), half(4)),
                    normal: SIMD3(signed(8), signed(9), signed(10)),
                    color: SIMD4(unit(16), unit(17), unit(18), unit(19)),
                    uv: SIMD2(half(20), half(22))))
            }
        }
        if let i = model.child("VIdx")?.data {
            for o in stride(from: 0, to: i.count - 1, by: 2) { mesh.indices.append(UInt32(i.u16(o))) }
        }
        if let e = model.child("VEmt")?.data {
            for o in stride(from: 0, to: e.count - 27, by: 28) {
                mesh.emitPoints.append(MeshVertex(
                    position: SIMD3(e.f32(o), e.f32(o + 4), e.f32(o + 8)),
                    normal: SIMD3(e.f32(o + 12), e.f32(o + 16), e.f32(o + 20)),
                    color: SIMD4(Float(e[o + 24]) / 255, Float(e[o + 25]) / 255, Float(e[o + 26]) / 255, Float(e[o + 27]) / 255),
                    uv: .zero))
            }
        }
        return mesh
    }

    static func fromPixiModel(_ json: JSONNode) -> MeshData {
        var mesh = MeshData()
        let positions = json["positions"]?.elements?.compactMap(\.number) ?? []
        let depth = json["z"]?.elements?.compactMap(\.number) ?? []
        let alpha = json["alpha"]?.elements?.compactMap(\.number) ?? []
        let color = json["color"]?.elements?.compactMap(\.number) ?? []
        let uv = json["uvs"]?.elements?.first?.elements?.compactMap(\.number) ?? []
        for i in 0..<positions.count / 2 {
            let z = i < depth.count ? Float(depth[i]) : 0
            var c = SIMD4<Float>(1, 1, 1, i < alpha.count ? Float(alpha[i]) : 1)
            if color.count >= (i + 1) * 3 { c = SIMD4(Float(color[i * 3]), Float(color[i * 3 + 1]), Float(color[i * 3 + 2]), c.w) }
            let t = uv.count >= (i + 1) * 2 ? SIMD2(Float(uv[i * 2]), Float(uv[i * 2 + 1])) : SIMD2<Float>(0, 0)
            mesh.vertices.append(MeshVertex(position: SIMD3(Float(positions[i * 2]), z, Float(positions[i * 2 + 1])),
                                            normal: SIMD3(0, 1, 0), color: c, uv: t))
        }
        mesh.indices = (json["indices"]?.elements?.compactMap(\.number) ?? []).map { UInt32($0) }
        return mesh
    }
}
