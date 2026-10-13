import Foundation
import simd

enum GameModel {
    private static func half(_ raw: UInt16) -> Float {
        let sign: Float = raw & 0x8000 != 0 ? -1 : 1
        let exponent = Int(raw >> 10 & 0x1F), mantissa = Float(raw & 0x3FF)
        if exponent == 0 { return sign * mantissa / 1024 * powf(2, -14) }
        if exponent == 31 { return 0 }
        return sign * (1 + mantissa / 1024) * powf(2, Float(exponent - 15))
    }

    private static func vector(_ b: [UInt8], _ at: Int, type: Int) -> SIMD4<Float>? {
        func f(_ index: Int) -> Float { Float(bitPattern: b.u32(at + index * 4)) }
        func h(_ index: Int) -> Float { half(b.u16(at + index * 2)) }
        switch type {
        case 1: return at + 8 <= b.count ? SIMD4(f(0), f(1), 0, 0) : nil
        case 2: return at + 12 <= b.count ? SIMD4(f(0), f(1), f(2), 1) : nil
        case 3: return at + 16 <= b.count ? SIMD4(f(0), f(1), f(2), f(3)) : nil
        case 8: return at + 4 <= b.count ? SIMD4(Float(b[at]), Float(b[at + 1]), Float(b[at + 2]), Float(b[at + 3])) / 255 : nil
        case 13: return at + 4 <= b.count ? SIMD4(h(0), h(1), 0, 0) : nil
        case 14: return at + 8 <= b.count ? SIMD4(h(0), h(1), h(2), h(3)) : nil
        default: return nil
        }
    }

    struct Part {
        var start: Int
        var count: Int
        var material: Int
    }

    static func materials(_ b: [UInt8]) -> [String] {
        guard b.count >= 0x48 else { return [] }
        let stringsAt = 0x44 + Int(b.u16(12)) * 136
        guard stringsAt + 8 <= b.count else { return [] }
        let size = Int(b.u32(stringsAt + 4))
        guard stringsAt + 8 + size <= b.count else { return [] }
        var names: [String] = []
        var at = stringsAt + 8
        while at < stringsAt + 8 + size {
            let text = GameFiles.string(b, at, max: 260)
            if text.hasSuffix(".mtrl") { names.append(text) }
            at += text.utf8.count + 1
        }
        return names
    }

    static func parse(_ b: [UInt8]) -> (mesh: MeshData, meshes: Int, parts: [Part])? {
        guard b.count >= 0x48 else { return nil }
        let declarations = Int(b.u16(12))
        let vertexStart = Int(b.u32(16)), indexStart = Int(b.u32(28))
        let stringsAt = 0x44 + declarations * 136
        guard declarations > 0, declarations < 4096, stringsAt + 8 <= b.count else { return nil }
        let header = stringsAt + 8 + Int(b.u32(stringsAt + 4))
        guard header + 56 <= b.count else { return nil }
        let meshCount = Int(b.u16(header + 4)), elementIds = Int(b.u16(header + 24))
        let extraLods = b[header + 27] & 0x10 != 0
        let lods = header + 56 + elementIds * 32
        let meshesAt = lods + 180 + (extraLods ? 120 : 0)
        guard lods + 60 <= b.count, meshCount > 0, meshesAt + meshCount * 36 <= b.count else { return nil }
        let first = Int(b.u16(lods)), count = Int(b.u16(lods + 2))
        var result = MeshData()
        var used = 0
        var parts: [Part] = []
        let last = min(first + count, meshCount, declarations)
        guard first < last else { return nil }
        for index in first..<last {
            let at = meshesAt + index * 36
            let vertexCount = Int(b.u16(at)), indexCount = Int(b.u32(at + 4)), startIndex = Int(b.u32(at + 16))
            let offsets = (0..<3).map { Int(b.u32(at + 20 + $0 * 4)) }, strides = (0..<3).map { Int(b[at + 36 - 4 + $0]) }
            var position: (stream: Int, offset: Int, type: Int)?, normal: (stream: Int, offset: Int, type: Int)?, uv: (stream: Int, offset: Int, type: Int)?
            for slot in 0..<17 {
                let element = 0x44 + index * 136 + slot * 8
                let stream = Int(b[element])
                if stream == 255 { break }
                guard stream < 3 else { continue }
                let entry = (stream, Int(b[element + 1]), Int(b[element + 2]))
                switch (b[element + 3], b[element + 4]) {
                case (0, 0): position = entry
                case (3, 0): normal = entry
                case (4, 0): uv = entry
                default: break
                }
            }
            guard let position, strides[position.stream] > 0 else { continue }
            let base = UInt32(result.vertices.count)
            var complete = true
            for vertex in 0..<vertexCount {
                func read(_ element: (stream: Int, offset: Int, type: Int)?) -> SIMD4<Float>? {
                    guard let element, strides[element.stream] > 0 else { return nil }
                    return vector(b, vertexStart + offsets[element.stream] + vertex * strides[element.stream] + element.offset, type: element.type)
                }
                guard let p = read(position) else {
                    complete = false
                    break
                }
                let n = read(normal) ?? SIMD4(0, 1, 0, 0), t = read(uv) ?? .zero
                let length = simd_length(SIMD3(n.x, n.y, n.z))
                result.vertices.append(MeshVertex(position: SIMD3(p.x, p.y, p.z), normal: length > 1e-5 ? SIMD3(n.x, n.y, n.z) / length : SIMD3(0, 1, 0),
                                                  color: SIMD4(1, 1, 1, 1), uv: SIMD2(t.x, t.y)))
            }
            let indexAt = indexStart + startIndex * 2
            guard complete, indexAt + indexCount * 2 <= b.count else {
                result.vertices.removeSubrange(Int(base)...)
                continue
            }
            var valid = true
            var list: [UInt32] = []
            list.reserveCapacity(indexCount)
            for slot in 0..<indexCount {
                let value = Int(b.u16(indexAt + slot * 2))
                if value >= vertexCount { valid = false }
                list.append(base + UInt32(value))
            }
            if valid {
                parts.append(Part(start: result.indices.count, count: list.count, material: Int(b.u16(at + 8))))
                result.indices.append(contentsOf: list)
                used += 1
            } else {
                result.vertices.removeSubrange(Int(base)...)
            }
        }
        return result.vertices.isEmpty || result.indices.isEmpty ? nil : (result, used, parts)
    }
}
