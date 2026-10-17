import CoreGraphics
import Foundation

nonisolated enum TexFormat: UInt32, Sendable {
    case l8 = 0x1130, a8 = 0x1131, b4g4r4a4 = 0x1440, b5g5r5a1 = 0x1441, b8g8r8a8 = 0x1450, b8g8r8x8 = 0x1451
    case bc1 = 0x3420, bc2 = 0x3430, bc3 = 0x3431, bc4 = 0x6120, bc5 = 0x6230, bc7 = 0x6432

    var name: String {
        switch self {
        case .l8: return "L8"
        case .a8: return "A8"
        case .b4g4r4a4: return "B4G4R4A4"
        case .b5g5r5a1: return "B5G5R5A1"
        case .b8g8r8a8: return "B8G8R8A8"
        case .b8g8r8x8: return "B8G8R8X8"
        case .bc1: return "BC1"
        case .bc2: return "BC2"
        case .bc3: return "BC3"
        case .bc4: return "BC4"
        case .bc5: return "BC5"
        case .bc7: return "BC7"
        }
    }
}

nonisolated struct DecodedTexture: Sendable {
    var width: Int
    var height: Int
    var formatName: String
    var mipLevels: Int
    var alphaOnly: Bool
    var rgba: [UInt8]
    var faces: [[UInt8]] = []

    func makeImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}

nonisolated enum TexError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        }
    }
}

nonisolated enum Atex {
    private static let header = 80

    static func decode(_ data: [UInt8], mip: Int = 0) throws -> DecodedTexture {
        guard data.count >= header else { throw TexError.invalid("Texture file is too small (\(data.count) bytes)") }
        let rawFormat = data.u32(4)
        let mips = Int(data[14] & 0x7f)
        let level = min(max(mip, 0), max(mips - 1, 0), 12)
        let width = max(1, Int(data.u16(8)) >> level)
        let height = max(1, Int(data.u16(10)) >> level)
        let surface = Int(data.u32(28 + level * 4))
        guard width > 0, height > 0 else { throw TexError.invalid("Texture has zero size") }
        guard surface >= header, surface <= data.count else { throw TexError.invalid("Invalid surface offset") }
        guard let format = TexFormat(rawValue: rawFormat) else {
            throw TexError.invalid(String(format: "Unknown texture format 0x%04x", rawFormat))
        }
        let bw = (width + 3) / 4, bh = (height + 3) / 4, px = width * height
        let need: Int
        switch format {
        case .bc1, .bc4: need = bw * bh * 8
        case .bc2, .bc3, .bc5, .bc7: need = bw * bh * 16
        case .l8, .a8: need = px
        case .b4g4r4a4, .b5g5r5a1: need = px * 2
        case .b8g8r8a8, .b8g8r8x8: need = px * 4
        }
        guard data.count - surface >= need else {
            throw TexError.invalid("\(format.name) \(width)×\(height): needs \(need) bytes, has \(data.count - surface)")
        }
        let cube = data.u32(0) & 0x2000000 != 0 && data.count - surface >= need * 6
        var faces: [[UInt8]] = []
        for face in 0..<(cube ? 6 : 1) {
            faces.append(surfacePixels(format, width, height, data, surface + face * need))
        }
        var decoded = DecodedTexture(width: width, height: height, formatName: format.name, mipLevels: mips, alphaOnly: format == .a8, rgba: faces[0])
        if cube { decoded.faces = faces }
        return decoded
    }

    private static func surfacePixels(_ format: TexFormat, _ width: Int, _ height: Int, _ data: [UInt8], _ surface: Int) -> [UInt8] {
        let px = width * height
        var rgba = [UInt8](repeating: 0, count: px * 4)
        switch format {
        case .bc1: blocks(&rgba, width, height, data, surface, 8) { b, o, out in color(b, o, out, bc1: true) }
        case .bc2:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                color(b, o + 8, out, bc1: false)
                for i in 0..<16 {
                    let nibble = (b[o + i / 2] >> UInt8((i % 2) * 4)) & 0xf
                    out[i * 4 + 3] = nibble * 17
                }
            }
        case .bc3:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                color(b, o + 8, out, bc1: false)
                channel(b, o, out, 3)
            }
        case .bc4:
            blocks(&rgba, width, height, data, surface, 8) { b, o, out in
                channel(b, o, out, 0)
                for i in 0..<16 {
                    out[i * 4 + 1] = out[i * 4]
                    out[i * 4 + 2] = out[i * 4]
                    out[i * 4 + 3] = 255
                }
            }
        case .bc5:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                channel(b, o, out, 0)
                channel(b, o + 8, out, 1)
                for i in 0..<16 {
                    out[i * 4 + 2] = 255
                    out[i * 4 + 3] = 255
                }
            }
        case .bc7:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in Bc7.decode(b, o, out) }
        default:
            uncompressed(&rgba, format, px, data, surface)
        }
        return rgba
    }

    private static func blocks(_ target: inout [UInt8], _ w: Int, _ h: Int, _ source: [UInt8], _ base: Int, _ blockBytes: Int,
                               _ decode: (UnsafeBufferPointer<UInt8>, Int, UnsafeMutablePointer<UInt8>) -> Void) {
        let bw = (w + 3) / 4, bh = (h + 3) / 4
        source.withUnsafeBufferPointer { src in
            target.withUnsafeMutableBufferPointer { dst in
                withUnsafeTemporaryAllocation(of: UInt8.self, capacity: 64) { block in
                    guard let out = block.baseAddress else { return }
                    out.initialize(repeating: 0, count: 64)
                    copyBlocks(dst, w, h, bw, bh, src, base, blockBytes, out, decode)
                }
            }
        }
    }

    private static func copyBlocks(_ dst: UnsafeMutableBufferPointer<UInt8>, _ w: Int, _ h: Int, _ bw: Int, _ bh: Int, _ src: UnsafeBufferPointer<UInt8>,
                                   _ base: Int, _ blockBytes: Int, _ out: UnsafeMutablePointer<UInt8>,
                                   _ decode: (UnsafeBufferPointer<UInt8>, Int, UnsafeMutablePointer<UInt8>) -> Void) {
        for by in 0..<bh {
            for bx in 0..<bw {
                decode(src, base + (by * bw + bx) * blockBytes, out)
                for py in 0..<4 {
                    let y = by * 4 + py
                    if y >= h { break }
                    for px in 0..<4 {
                        let x = bx * 4 + px
                        if x >= w { break }
                        let s = (py * 4 + px) * 4, d = (y * w + x) * 4
                        dst[d] = out[s]
                        dst[d + 1] = out[s + 1]
                        dst[d + 2] = out[s + 2]
                        dst[d + 3] = out[s + 3]
                    }
                }
            }
        }
    }

    private static func expand5(_ v: Int) -> UInt8 { UInt8((v << 3) | (v >> 2)) }
    private static func expand6(_ v: Int) -> UInt8 { UInt8((v << 2) | (v >> 4)) }

    private static func color(_ b: UnsafeBufferPointer<UInt8>, _ o: Int, _ out: UnsafeMutablePointer<UInt8>, bc1: Bool) {
        let c0 = Int(b[o]) | Int(b[o + 1]) << 8, c1 = Int(b[o + 2]) | Int(b[o + 3]) << 8
        let p0 = SIMD4<Int>(Int(expand5(c0 >> 11)), Int(expand6((c0 >> 5) & 0x3f)), Int(expand5(c0 & 0x1f)), 255)
        let p1 = SIMD4<Int>(Int(expand5(c1 >> 11)), Int(expand6((c1 >> 5) & 0x3f)), Int(expand5(c1 & 0x1f)), 255)
        let p2: SIMD4<Int>, p3: SIMD4<Int>
        if c0 > c1 || !bc1 {
            p2 = SIMD4((2 * p0.x + p1.x) / 3, (2 * p0.y + p1.y) / 3, (2 * p0.z + p1.z) / 3, 255)
            p3 = SIMD4((p0.x + 2 * p1.x) / 3, (p0.y + 2 * p1.y) / 3, (p0.z + 2 * p1.z) / 3, 255)
        } else {
            p2 = SIMD4((p0.x + p1.x) / 2, (p0.y + p1.y) / 2, (p0.z + p1.z) / 2, 255)
            p3 = .zero
        }
        let bits = UInt32(b[o + 4]) | UInt32(b[o + 5]) << 8 | UInt32(b[o + 6]) << 16 | UInt32(b[o + 7]) << 24
        for i in 0..<16 {
            let k = Int((bits >> UInt32(i * 2)) & 3)
            let p = k == 0 ? p0 : k == 1 ? p1 : k == 2 ? p2 : p3
            out[i * 4] = UInt8(p.x)
            out[i * 4 + 1] = UInt8(p.y)
            out[i * 4 + 2] = UInt8(p.z)
            out[i * 4 + 3] = UInt8(p.w)
        }
    }

    private static func channel(_ b: UnsafeBufferPointer<UInt8>, _ o: Int, _ out: UnsafeMutablePointer<UInt8>, _ component: Int) {
        let a0 = Int(b[o]), a1 = Int(b[o + 1])
        func value(_ k: Int) -> Int {
            if k == 0 { return a0 }
            if k == 1 { return a1 }
            if a0 > a1 { return ((8 - k) * a0 + (k - 1) * a1) / 7 }
            if k == 6 { return 0 }
            if k == 7 { return 255 }
            return ((6 - k) * a0 + (k - 1) * a1) / 5
        }
        var bits: UInt64 = 0
        for i in 0..<6 { bits |= UInt64(b[o + 2 + i]) << UInt64(8 * i) }
        for i in 0..<16 {
            out[i * 4 + component] = UInt8(value(Int((bits >> UInt64(i * 3)) & 7)))
        }
    }

    private static func uncompressed(_ dst: inout [UInt8], _ format: TexFormat, _ n: Int, _ src: [UInt8], _ base: Int) {
        for i in 0..<n {
            var r = 0, g = 0, bl = 0, a = 255
            switch format {
            case .l8:
                r = Int(src[base + i]); g = r; bl = r
            case .a8:
                r = 255; g = 255; bl = 255
                a = Int(src[base + i])
            case .b4g4r4a4:
                let v = Int(src.u16(base + i * 2))
                bl = (v & 0xf) * 17
                g = ((v >> 4) & 0xf) * 17
                r = ((v >> 8) & 0xf) * 17
                a = ((v >> 12) & 0xf) * 17
            case .b5g5r5a1:
                let v = Int(src.u16(base + i * 2))
                bl = Int(expand5(v & 0x1f))
                g = Int(expand5((v >> 5) & 0x1f))
                r = Int(expand5((v >> 10) & 0x1f))
                a = (v >> 15) != 0 ? 255 : 0
            default:
                bl = Int(src[base + i * 4])
                g = Int(src[base + i * 4 + 1])
                r = Int(src[base + i * 4 + 2])
                a = format == .b8g8r8x8 ? 255 : Int(src[base + i * 4 + 3])
            }
            dst[i * 4] = UInt8(r)
            dst[i * 4 + 1] = UInt8(g)
            dst[i * 4 + 2] = UInt8(bl)
            dst[i * 4 + 3] = UInt8(a)
        }
    }
}
