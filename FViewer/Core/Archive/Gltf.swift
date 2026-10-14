import Foundation
import simd

struct GltfMesh {
    var positions: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var tangents: [SIMD4<Float>] = []
    var colors: [SIMD4<Float>] = []
    var uvs: [[SIMD2<Float>]] = [[], [], [], []]
    var indices: [UInt32] = []
    var notes: [String] = []
}

enum Gltf {
    static func floatToHalf(_ value: Float) -> UInt16 {
        let bits = value.bitPattern
        let sign = UInt16((bits >> 16) & 0x8000)
        let exponent = Int((bits >> 23) & 0xff) - 127 + 15
        let mantissa = bits & 0x7f_ffff
        if value.isNaN { return sign | 0x7e00 }
        if exponent >= 31 { return sign | 0x7c00 }
        if exponent <= 0 {
            if exponent < -10 { return sign }
            let shifted = (mantissa | 0x80_0000) >> UInt32(1 - exponent)
            return sign | UInt16((shifted + 0x1000) >> 13)
        }
        let rounded = UInt32(exponent) << 10 + (mantissa + 0x1000) >> 13
        return sign | UInt16(min(rounded, 0x7bff + 1))
    }

    static func mesh(from model: AvfxBlock) -> GltfMesh {
        var mesh = GltfMesh()
        if let v = model.child("VDrw")?.data {
            for o in stride(from: 0, to: v.count - 35, by: 36) {
                func half(_ at: Int) -> Float { CurveMath.halfToFloat(v.u16(o + at)) }
                func signed(_ at: Int) -> Float { Float(Int(v[o + at]) - 128) }
                mesh.positions.append(SIMD3(half(0), half(2), half(4)))
                let n = SIMD3(signed(8), signed(9), signed(10)), t = SIMD3(signed(12), signed(13), signed(14))
                mesh.normals.append(simd_length(n) > 0 ? simd_normalize(n) : SIMD3(0, 1, 0))
                let tangent = simd_length(t) > 0 ? simd_normalize(t) : SIMD3<Float>(1, 0, 0)
                mesh.tangents.append(SIMD4(tangent.x, tangent.y, tangent.z, 1))
                mesh.colors.append(SIMD4(Float(v[o + 16]), Float(v[o + 17]), Float(v[o + 18]), Float(v[o + 19])) / 255)
                for set in 0..<4 { mesh.uvs[set].append(SIMD2(half(20 + set * 4), half(22 + set * 4))) }
            }
        }
        if let i = model.child("VIdx")?.data {
            for o in stride(from: 0, to: i.count - 1, by: 2) { mesh.indices.append(UInt32(i.u16(o))) }
        }
        return mesh
    }

    static func vertexData(_ mesh: GltfMesh) -> (vertices: [UInt8], indices: [UInt8]) {
        var vertices: [UInt8] = []
        vertices.reserveCapacity(mesh.positions.count * 36)
        func signedByte(_ value: Float) -> UInt8 { UInt8(max(0, min(255, Int(value * 127) + 128))) }
        for i in mesh.positions.indices {
            let p = mesh.positions[i]
            for value in [p.x, p.y, p.z, 1] { vertices.appendU16(floatToHalf(value)) }
            let n = i < mesh.normals.count ? mesh.normals[i] : SIMD3<Float>(0, 1, 0)
            vertices.append(contentsOf: [signedByte(n.x), signedByte(n.y), signedByte(n.z), 127])
            let t = i < mesh.tangents.count ? mesh.tangents[i] : SIMD4<Float>(1, 0, 0, 1)
            vertices.append(contentsOf: [signedByte(t.x), signedByte(t.y), signedByte(t.z), 127])
            let c = i < mesh.colors.count ? mesh.colors[i] : SIMD4<Float>(1, 1, 1, 1)
            for value in [c.x, c.y, c.z, c.w] { vertices.append(UInt8(max(0, min(255, (value * 255).rounded())))) }
            for set in 0..<4 {
                let source = i < mesh.uvs[set].count ? mesh.uvs[set][i] : (i < mesh.uvs[0].count ? mesh.uvs[0][i] : .zero)
                vertices.appendU16(floatToHalf(source.x))
                vertices.appendU16(floatToHalf(source.y))
            }
        }
        var indices: [UInt8] = []
        for index in mesh.indices { indices.appendU16(UInt16(truncatingIfNeeded: index)) }
        return (vertices, indices)
    }

    static func glb(_ mesh: GltfMesh, name: String) -> [UInt8] {
        var bin: [UInt8] = []
        var views: [String] = []
        var accessors: [String] = []
        func pad() { while bin.count % 4 != 0 { bin.append(0) } }
        func add(_ floats: [Float], components: Int, type: String, bounds: Bool) -> Int {
            pad()
            let offset = bin.count
            for value in floats { bin.appendU32(value.bitPattern) }
            views.append("{\"buffer\":0,\"byteOffset\":\(offset),\"byteLength\":\(floats.count * 4),\"target\":34962}")
            var extra = ""
            if bounds, !floats.isEmpty {
                var low = [Float](repeating: .infinity, count: components), high = [Float](repeating: -.infinity, count: components)
                for i in floats.indices {
                    guard floats[i].isFinite else { continue }
                    low[i % components] = min(low[i % components], floats[i])
                    high[i % components] = max(high[i % components], floats[i])
                }
                extra = ",\"min\":[\(low.map { "\($0.isFinite ? $0 : 0)" }.joined(separator: ","))],\"max\":[\(high.map { "\($0.isFinite ? $0 : 0)" }.joined(separator: ","))]"
            }
            accessors.append("{\"bufferView\":\(views.count - 1),\"componentType\":5126,\"count\":\(floats.count / components),\"type\":\"\(type)\"\(extra)}")
            return accessors.count - 1
        }
        var attributes: [String] = []
        attributes.append("\"POSITION\":\(add(mesh.positions.flatMap { [$0.x, $0.y, $0.z] }, components: 3, type: "VEC3", bounds: true))")
        attributes.append("\"NORMAL\":\(add(mesh.normals.flatMap { [$0.x, $0.y, $0.z] }, components: 3, type: "VEC3", bounds: false))")
        attributes.append("\"TANGENT\":\(add(mesh.tangents.flatMap { [$0.x, $0.y, $0.z, $0.w] }, components: 4, type: "VEC4", bounds: false))")
        attributes.append("\"COLOR_0\":\(add(mesh.colors.flatMap { [$0.x, $0.y, $0.z, $0.w] }, components: 4, type: "VEC4", bounds: false))")
        for set in 0..<4 {
            attributes.append("\"TEXCOORD_\(set)\":\(add(mesh.uvs[set].flatMap { [$0.x, $0.y] }, components: 2, type: "VEC2", bounds: false))")
        }
        pad()
        let indexOffset = bin.count
        for index in mesh.indices { bin.appendU32(index) }
        views.append("{\"buffer\":0,\"byteOffset\":\(indexOffset),\"byteLength\":\(mesh.indices.count * 4),\"target\":34963}")
        accessors.append("{\"bufferView\":\(views.count - 1),\"componentType\":5125,\"count\":\(mesh.indices.count),\"type\":\"SCALAR\"}")
        pad()
        let safeName = name.replacingOccurrences(of: "\"", with: "'")
        let json = "{\"asset\":{\"version\":\"2.0\",\"generator\":\"FViewer\"},\"scene\":0,\"scenes\":[{\"nodes\":[0]}],\"nodes\":[{\"mesh\":0,\"name\":\"\(safeName)\"}],"
            + "\"meshes\":[{\"name\":\"\(safeName)\",\"primitives\":[{\"attributes\":{\(attributes.joined(separator: ","))},\"indices\":\(accessors.count - 1),\"mode\":4}]}],"
            + "\"accessors\":[\(accessors.joined(separator: ","))],\"bufferViews\":[\(views.joined(separator: ","))],\"buffers\":[{\"byteLength\":\(bin.count)}]}"
        var text = Array(json.utf8)
        while text.count % 4 != 0 { text.append(0x20) }
        var out: [UInt8] = []
        out.appendU32(0x4654_6C67)
        out.appendU32(2)
        out.appendU32(UInt32(12 + 8 + text.count + 8 + bin.count))
        out.appendU32(UInt32(text.count))
        out.appendU32(0x4E4F_534A)
        out.append(contentsOf: text)
        out.appendU32(UInt32(bin.count))
        out.appendU32(0x004E_4942)
        out.append(contentsOf: bin)
        return out
    }

    static func load(_ url: URL) throws -> GltfMesh {
        let file = [UInt8](try Data(contentsOf: url))
        var jsonBytes = file
        var embedded: [UInt8]?
        if file.count >= 20, file.u32(0) == 0x4654_6C67 {
            let length = Int(file.u32(12))
            guard 20 + length <= file.count else { throw AvfxError.malformed("The .glb file is truncated") }
            jsonBytes = Array(file[20..<20 + length])
            let next = 20 + length
            if next + 8 <= file.count, file.u32(next + 4) == 0x004E_4942 {
                let size = Int(file.u32(next))
                guard next + 8 + size <= file.count else { throw AvfxError.malformed("The .glb binary chunk is truncated") }
                embedded = Array(file[next + 8..<next + 8 + size])
            }
        }
        let root = try JSONParser.parse(Data(jsonBytes))
        var buffers: [[UInt8]] = []
        for (i, buffer) in (root["buffers"]?.elements ?? []).enumerated() {
            if let uri = buffer["uri"]?.string {
                if uri.hasPrefix("data:"), let comma = uri.firstIndex(of: ","), let data = Data(base64Encoded: String(uri[uri.index(after: comma)...])) {
                    buffers.append([UInt8](data))
                } else {
                    let name = uri.removingPercentEncoding ?? uri
                    buffers.append([UInt8](try Data(contentsOf: url.deletingLastPathComponent().appendingPathComponent(name))))
                }
            } else if i == 0, let embedded {
                buffers.append(embedded)
            } else {
                throw AvfxError.malformed("Buffer \(i) has no data")
            }
        }
        let views = root["bufferViews"]?.elements ?? []
        let accessors = root["accessors"]?.elements ?? []
        func read(_ index: Int) throws -> (values: [Float], components: Int) {
            guard index >= 0, index < accessors.count else { throw AvfxError.malformed("Accessor \(index) does not exist") }
            let accessor = accessors[index]
            if accessor["sparse"] != nil { throw AvfxError.malformed("Sparse accessors are not supported; re-export without them") }
            let components = ["SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4][accessor["type"]?.string ?? ""] ?? 1
            let count = Int(safe: accessor["count"]?.number ?? 0)
            let type = Int(safe: accessor["componentType"]?.number ?? 5126)
            let normalized = accessor["normalized"]?.bool ?? false
            guard count >= 0, count <= 4_000_000 else { throw AvfxError.malformed("Accessor \(index) has an invalid count") }
            guard let viewIndex = accessor["bufferView"]?.number.map({ Int(safe: $0) }), viewIndex >= 0, viewIndex < views.count else {
                return ([Float](repeating: 0, count: count * components), components)
            }
            let view = views[viewIndex]
            let bufferIndex = Int(safe: view["buffer"]?.number ?? 0)
            guard bufferIndex >= 0, bufferIndex < buffers.count else { throw AvfxError.malformed("Buffer \(bufferIndex) does not exist") }
            let buffer = buffers[bufferIndex]
            let size = [5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4][type] ?? 4
            let start = Int(safe: view["byteOffset"]?.number ?? 0) + Int(safe: accessor["byteOffset"]?.number ?? 0)
            let stride = Int(safe: view["byteStride"]?.number ?? 0)
            let step = stride > 0 ? stride : size * components
            guard count == 0 || (start >= 0 && step > 0 && start + (count - 1) * step + size * components <= buffer.count) else {
                throw AvfxError.malformed("Accessor \(index) reads past the end of its buffer")
            }
            var values: [Float] = []
            values.reserveCapacity(count * components)
            for i in 0..<count {
                for c in 0..<components {
                    let at = start + i * step + c * size
                    switch type {
                    case 5126: values.append(buffer.f32(at))
                    case 5125: values.append(Float(buffer.u32(at)))
                    case 5123: values.append(normalized ? Float(buffer.u16(at)) / 65535 : Float(buffer.u16(at)))
                    case 5122:
                        let raw = Float(Int16(bitPattern: buffer.u16(at)))
                        values.append(normalized ? max(raw / 32767, -1) : raw)
                    case 5121: values.append(normalized ? Float(buffer[at]) / 255 : Float(buffer[at]))
                    default:
                        let raw = Float(Int8(bitPattern: buffer[at]))
                        values.append(normalized ? max(raw / 127, -1) : raw)
                    }
                }
            }
            return (values, components)
        }
        var mesh = GltfMesh()
        var missingNormals = false, missingTangents = false, skipped = 0
        for item in root["meshes"]?.elements ?? [] {
            for primitive in item["primitives"]?.elements ?? [] {
                if let mode = primitive["mode"]?.number, Int(safe: mode) != 4, Int(safe: mode) != 0 {
                    skipped += 1
                    continue
                }
                guard let attributes = primitive["attributes"], let positionIndex = attributes["POSITION"]?.number.map({ Int(safe: $0) }) else { continue }
                let base = UInt32(mesh.positions.count)
                let positions = try read(positionIndex).values
                let count = positions.count / 3
                for i in 0..<count { mesh.positions.append(SIMD3(positions[i * 3], positions[i * 3 + 1], positions[i * 3 + 2])) }
                func vectors(_ key: String) throws -> (values: [Float], components: Int)? {
                    guard let index = attributes[key]?.number.map({ Int(safe: $0) }) else { return nil }
                    let data = try read(index)
                    return data.values.count / max(data.components, 1) == count ? data : nil
                }
                if let n = try vectors("NORMAL"), n.components >= 3 {
                    for i in 0..<count { mesh.normals.append(SIMD3(n.values[i * 3], n.values[i * 3 + 1], n.values[i * 3 + 2])) }
                } else {
                    missingNormals = true
                    mesh.normals.append(contentsOf: [SIMD3<Float>](repeating: .zero, count: count))
                }
                if let t = try vectors("TANGENT"), t.components >= 3 {
                    for i in 0..<count {
                        let o = i * t.components
                        mesh.tangents.append(SIMD4(t.values[o], t.values[o + 1], t.values[o + 2], t.components > 3 ? t.values[o + 3] : 1))
                    }
                } else {
                    missingTangents = true
                    mesh.tangents.append(contentsOf: [SIMD4<Float>](repeating: .zero, count: count))
                }
                if let c = try vectors("COLOR_0"), c.components >= 3 {
                    for i in 0..<count {
                        let o = i * c.components
                        mesh.colors.append(SIMD4(c.values[o], c.values[o + 1], c.values[o + 2], c.components > 3 ? c.values[o + 3] : 1))
                    }
                } else {
                    mesh.colors.append(contentsOf: [SIMD4<Float>](repeating: SIMD4(1, 1, 1, 1), count: count))
                }
                var first: [SIMD2<Float>] = []
                if let uv = try vectors("TEXCOORD_0"), uv.components >= 2 {
                    for i in 0..<count { first.append(SIMD2(uv.values[i * uv.components], uv.values[i * uv.components + 1])) }
                } else {
                    first = [SIMD2<Float>](repeating: .zero, count: count)
                }
                mesh.uvs[0].append(contentsOf: first)
                for set in 1..<4 {
                    if let uv = try vectors("TEXCOORD_\(set)"), uv.components >= 2 {
                        for i in 0..<count { mesh.uvs[set].append(SIMD2(uv.values[i * uv.components], uv.values[i * uv.components + 1])) }
                    } else {
                        mesh.uvs[set].append(contentsOf: first)
                    }
                }
                if Int(safe: primitive["mode"]?.number ?? 4) == 4 {
                    var own: [UInt32] = []
                    if let indexAccessor = primitive["indices"]?.number.map({ Int(safe: $0) }) {
                        own = try read(indexAccessor).values.map { UInt32(Int(safe: $0, in: 0...4_000_000)) }
                    } else {
                        own = Array(0..<UInt32(count))
                    }
                    own.removeLast(own.count % 3)
                    for t in stride(from: 0, to: own.count, by: 3) where own[t] < count && own[t + 1] < count && own[t + 2] < count {
                        mesh.indices.append(contentsOf: [base + own[t], base + own[t + 1], base + own[t + 2]])
                    }
                }
            }
        }
        mesh.indices.removeLast(mesh.indices.count % 3)
        if skipped > 0 { mesh.notes.append("\(skipped) primitive(s) were not triangles and were skipped") }
        if missingNormals {
            computeNormals(&mesh)
            mesh.notes.append("Normals were missing and were computed from the faces")
        }
        if missingTangents {
            computeTangents(&mesh)
            mesh.notes.append("Tangents were missing and were computed from the first UV set")
        }
        return mesh
    }

    private static func computeNormals(_ mesh: inout GltfMesh) {
        var sums = [SIMD3<Float>](repeating: .zero, count: mesh.positions.count)
        for t in stride(from: 0, to: mesh.indices.count - 2, by: 3) {
            let a = Int(mesh.indices[t]), b = Int(mesh.indices[t + 1]), c = Int(mesh.indices[t + 2])
            guard a < sums.count, b < sums.count, c < sums.count else { continue }
            let face = simd_cross(mesh.positions[b] - mesh.positions[a], mesh.positions[c] - mesh.positions[a])
            sums[a] += face
            sums[b] += face
            sums[c] += face
        }
        for i in sums.indices where i < mesh.normals.count && simd_length(mesh.normals[i]) < 1e-6 {
            mesh.normals[i] = simd_length(sums[i]) > 1e-12 ? simd_normalize(sums[i]) : SIMD3(0, 1, 0)
        }
    }

    private static func computeTangents(_ mesh: inout GltfMesh) {
        var sums = [SIMD3<Float>](repeating: .zero, count: mesh.positions.count)
        for t in stride(from: 0, to: mesh.indices.count - 2, by: 3) {
            let a = Int(mesh.indices[t]), b = Int(mesh.indices[t + 1]), c = Int(mesh.indices[t + 2])
            guard a < sums.count, b < sums.count, c < sums.count, c < mesh.uvs[0].count else { continue }
            let e1 = mesh.positions[b] - mesh.positions[a], e2 = mesh.positions[c] - mesh.positions[a]
            let d1 = mesh.uvs[0][b] - mesh.uvs[0][a], d2 = mesh.uvs[0][c] - mesh.uvs[0][a]
            let det = d1.x * d2.y - d2.x * d1.y
            guard abs(det) > 1e-12 else { continue }
            let tangent = (e1 * d2.y - e2 * d1.y) / det
            sums[a] += tangent
            sums[b] += tangent
            sums[c] += tangent
        }
        for i in sums.indices where i < mesh.tangents.count && simd_length(SIMD3(mesh.tangents[i].x, mesh.tangents[i].y, mesh.tangents[i].z)) < 1e-6 {
            let normal = i < mesh.normals.count ? mesh.normals[i] : SIMD3<Float>(0, 1, 0)
            var tangent = sums[i] - normal * simd_dot(normal, sums[i])
            if simd_length(tangent) < 1e-9 { tangent = abs(normal.x) < 0.9 ? simd_cross(normal, SIMD3(1, 0, 0)) : simd_cross(normal, SIMD3(0, 0, 1)) }
            tangent = simd_normalize(tangent)
            mesh.tangents[i] = SIMD4(tangent.x, tangent.y, tangent.z, 1)
        }
    }

    static func emitData(_ mesh: GltfMesh) -> (points: [UInt8], order: [UInt8]) {
        var points: [UInt8] = []
        var order: [UInt8] = []
        for i in mesh.positions.indices {
            let p = mesh.positions[i]
            var n = i < mesh.normals.count ? mesh.normals[i] : SIMD3<Float>(0, 1, 0)
            n = simd_length(n) > 1e-9 ? simd_normalize(n) : SIMD3(0, 1, 0)
            for value in [p.x, p.y, p.z, n.x, n.y, n.z] { points.appendU32(value.bitPattern) }
            let c = i < mesh.colors.count ? mesh.colors[i] : SIMD4<Float>(1, 1, 1, 1)
            for value in [c.x, c.y, c.z, c.w] { points.append(UInt8(max(0, min(255, (value * 255).rounded())))) }
            order.appendU16(UInt16(truncatingIfNeeded: i))
        }
        return (points, order)
    }
}
