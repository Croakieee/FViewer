import AppKit
import Foundation

enum PlaceholderTextures {
    private static func noise(_ size: Int, seed: UInt32) -> [Float] {
        var state = seed
        func next() -> Float {
            state = state &* 1664525 &+ 1013904223
            return Float(state) / 4294967296
        }
        var out = [Float](repeating: 0, count: size * size)
        var total: Float = 0
        for (cells, weight) in [(4, Float(0.5)), (8, 0.3), (16, 0.2)] {
            total += weight
            let grid = (0..<(cells * cells)).map { _ in next() }
            func at(_ i: Int, _ j: Int) -> Float { grid[(j % cells) * cells + (i % cells)] }
            for y in 0..<size {
                for x in 0..<size {
                    let gx = Float(x) / Float(size) * Float(cells), gy = Float(y) / Float(size) * Float(cells)
                    let i = Int(gx), j = Int(gy)
                    var fx = gx - Float(i), fy = gy - Float(j)
                    fx = fx * fx * (3 - 2 * fx)
                    fy = fy * fy * (3 - 2 * fy)
                    let top = at(i, j) + (at(i + 1, j) - at(i, j)) * fx, bottom = at(i, j + 1) + (at(i + 1, j + 1) - at(i, j + 1)) * fx
                    out[y * size + x] += (top + (bottom - top) * fy) * weight
                }
            }
        }
        return out.map { $0 / total }
    }

    private static func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    private static func pixel(_ name: String) -> ((Float, Float, [Float], Int) -> SIMD4<Float>)? {
        switch name {
        case "white": return { _, _, _, _ in SIMD4(1, 1, 1, 1) }
        case "glow", "icon_glow":
            return { u, v, _, _ in
                let d = hypot(u - 0.5, v - 0.5) * 2
                return SIMD4(1, 1, 1, pow(max(0, 1 - d), 2))
            }
        case "smoke", "icon_smoke", "blobs", "clouds":
            return { u, v, n, size in
                let d = hypot(u - 0.5, v - 0.5) * 2
                let value = n[min(size - 1, Int(v * Float(size))) * size + min(size - 1, Int(u * Float(size)))]
                let edge = name == "smoke" || name == "icon_smoke" ? max(0, 1 - d) : 1
                return SIMD4(1, 1, 1, smooth(0.25, 0.8, value) * edge)
            }
        case "noise", "water", "caustics", "drops", "strands":
            return { u, v, n, size in
                let value = n[min(size - 1, Int(v * Float(size))) * size + min(size - 1, Int(u * Float(size)))]
                return name == "noise" ? SIMD4(value, 1 - value, 0.5, 1) : SIMD4(0.75 + value * 0.25, 0.9, 1, smooth(0.35, 0.75, value))
            }
        case "fire", "fire_pink":
            return { u, v, n, size in
                let value = n[min(size - 1, Int(v * Float(size))) * size + min(size - 1, Int(u * Float(size)))]
                let heat = smooth(0.3, 0.8, value)
                return name == "fire" ? SIMD4(1, 0.35 + heat * 0.6, heat * 0.4, heat) : SIMD4(1, 0.3 + heat * 0.4, 0.6 + heat * 0.4, heat)
            }
        case "ring", "quarter_ring":
            return { u, v, _, _ in
                let d = name == "ring" ? hypot(u - 0.5, v - 0.5) * 2 : hypot(u, v)
                return SIMD4(1, 1, 1, smooth(0.62, 0.72, d) * (1 - smooth(0.88, 0.98, d)))
            }
        case "disc", "quarter_disc", "disc_mask":
            return { u, v, _, _ in
                let d = name == "quarter_disc" ? hypot(u, v) : hypot(u - 0.5, v - 0.5) * 2
                return SIMD4(1, 1, 1, 1 - smooth(0.9, 1, d))
            }
        case "star":
            return { u, v, _, _ in
                let x = abs(u - 0.5) * 2, y = abs(v - 0.5) * 2
                let ray = max(0, 1 - x * 12 * (y + 0.05)) * max(0, 1 - max(x, y))
                return SIMD4(1, 1, 1, min(1, ray + pow(max(0, 1 - hypot(x, y) * 3), 2)))
            }
        case "line", "grad_line":
            return { _, v, _, _ in SIMD4(1, 1, 1, pow(max(0, 1 - abs(v - 0.5) * 2), name == "line" ? 3 : 1)) }
        case "wipe": return { _, v, _, _ in SIMD4(1, 1, 1, v) }
        case "arrow":
            return { u, v, _, _ in SIMD4(1, 1, 1, abs(v - 0.5) * 2 < (1 - u) ? 1 : 0) }
        case "tilt_grid":
            return { u, v, _, _ in
                let line = (u * 8).truncatingRemainder(dividingBy: 1) < 0.06 || (v * 8).truncatingRemainder(dividingBy: 1) < 0.06
                return SIMD4(1, 1, 1, line ? 1 : 0.15)
            }
        case "rect_fill_q": return { _, _, _, _ in SIMD4(1, 1, 1, 1) }
        case "rect_frame_q": return { u, v, _, _ in SIMD4(1, 1, 1, max(u, v) > 0.88 ? 1 : 0) }
        default: return nil
        }
    }

    static func isMirrored(_ name: String) -> Bool { name.hasPrefix("quarter_") || name.hasSuffix("_q") }

    static func has(_ name: String) -> Bool { pixel(name.lowercased()) != nil }

    static func url(for name: String) -> URL? {
        let key = name.lowercased()
        guard let generator = pixel(key), let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let folder = base.appendingPathComponent("FViewer/Placeholders", isDirectory: true)
        let url = folder.appendingPathComponent(key + ".png")
        if FileManager.default.fileExists(atPath: url.path) { return url }
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let size = 128
        let values = noise(size, seed: UInt32(truncatingIfNeeded: key.utf8.reduce(11) { $0 &* 31 &+ Int($1) }))
        var bytes = [UInt8](repeating: 0, count: size * size * 4)
        for y in 0..<size {
            for x in 0..<size {
                let c = generator((Float(x) + 0.5) / Float(size), (Float(y) + 0.5) / Float(size), values, size)
                let o = (y * size + x) * 4
                bytes[o] = UInt8(min(max(c.x, 0), 1) * 255)
                bytes[o + 1] = UInt8(min(max(c.y, 0), 1) * 255)
                bytes[o + 2] = UInt8(min(max(c.z, 0), 1) * 255)
                bytes[o + 3] = UInt8(min(max(c.w, 0), 1) * 255)
            }
        }
        guard let image = DecodedTexture(width: size, height: size, formatName: "", mipLevels: 1, alphaOnly: false, rgba: bytes).makeImage(),
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return nil }
        try? data.write(to: url, options: .atomic)
        return url
    }
}
