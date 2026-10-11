import CoreGraphics
import Foundation

enum TexFormat: UInt32 {
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

struct DecodedTexture {
    var width: Int
    var height: Int
    var formatName: String
    var mipLevels: Int
    var alphaOnly: Bool
    var rgba: [UInt8]

    func makeImage() -> CGImage? {
        guard let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}

enum TexError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        }
    }
}

enum Atex {
    private static let header = 80

    static func decode(_ data: [UInt8]) throws -> DecodedTexture {
        guard data.count >= header else { throw TexError.invalid("Texture file is too small (\(data.count) bytes)") }
        let rawFormat = data.u32(4)
        let width = Int(data.u16(8))
        let height = Int(data.u16(10))
        let mips = Int(data[14] & 0x7f)
        let surface = Int(data.u32(28))
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
        var rgba = [UInt8](repeating: 0, count: px * 4)
        switch format {
        case .bc1: blocks(&rgba, width, height, data, surface, 8) { b, o, out in color(b, o, &out, bc1: true) }
        case .bc2:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                color(b, o + 8, &out, bc1: false)
                for i in 0..<16 {
                    let nibble = (b[o + i / 2] >> UInt8((i % 2) * 4)) & 0xf
                    out[i * 4 + 3] = nibble * 17
                }
            }
        case .bc3:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                color(b, o + 8, &out, bc1: false)
                channel(b, o, &out, 3)
            }
        case .bc4:
            blocks(&rgba, width, height, data, surface, 8) { b, o, out in
                channel(b, o, &out, 0)
                for i in 0..<16 {
                    out[i * 4 + 1] = out[i * 4]
                    out[i * 4 + 2] = out[i * 4]
                    out[i * 4 + 3] = 255
                }
            }
        case .bc5:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in
                channel(b, o, &out, 0)
                channel(b, o + 8, &out, 1)
                for i in 0..<16 {
                    out[i * 4 + 2] = 255
                    out[i * 4 + 3] = 255
                }
            }
        case .bc7:
            blocks(&rgba, width, height, data, surface, 16) { b, o, out in Bc7.decode(b, o, &out) }
        default:
            uncompressed(&rgba, format, px, data, surface)
        }
        return DecodedTexture(width: width, height: height, formatName: format.name, mipLevels: mips,
                              alphaOnly: format == .a8, rgba: rgba)
    }

    private static func blocks(_ dst: inout [UInt8], _ w: Int, _ h: Int, _ src: [UInt8], _ base: Int, _ blockBytes: Int,
                               _ decode: ([UInt8], Int, inout [UInt8]) -> Void) {
        let bw = (w + 3) / 4, bh = (h + 3) / 4
        var out = [UInt8](repeating: 0, count: 64)
        for by in 0..<bh {
            for bx in 0..<bw {
                decode(src, base + (by * bw + bx) * blockBytes, &out)
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

    private static func color(_ b: [UInt8], _ o: Int, _ out: inout [UInt8], bc1: Bool) {
        let c0 = Int(b.u16(o)), c1 = Int(b.u16(o + 2))
        var pal = [[Int]](repeating: [0, 0, 0, 255], count: 4)
        pal[0] = [Int(expand5(c0 >> 11)), Int(expand6((c0 >> 5) & 0x3f)), Int(expand5(c0 & 0x1f)), 255]
        pal[1] = [Int(expand5(c1 >> 11)), Int(expand6((c1 >> 5) & 0x3f)), Int(expand5(c1 & 0x1f)), 255]
        if c0 > c1 || !bc1 {
            for k in 0..<3 {
                pal[2][k] = (2 * pal[0][k] + pal[1][k]) / 3
                pal[3][k] = (pal[0][k] + 2 * pal[1][k]) / 3
            }
        } else {
            for k in 0..<3 { pal[2][k] = (pal[0][k] + pal[1][k]) / 2 }
            pal[3] = [0, 0, 0, 0]
        }
        let bits = b.u32(o + 4)
        for i in 0..<16 {
            let p = pal[Int((bits >> UInt32(i * 2)) & 3)]
            out[i * 4] = UInt8(p[0])
            out[i * 4 + 1] = UInt8(p[1])
            out[i * 4 + 2] = UInt8(p[2])
            out[i * 4 + 3] = UInt8(p[3])
        }
    }

    private static func channel(_ b: [UInt8], _ o: Int, _ out: inout [UInt8], _ component: Int) {
        let a0 = Int(b[o]), a1 = Int(b[o + 1])
        var pal = [Int](repeating: 0, count: 8)
        pal[0] = a0
        pal[1] = a1
        if a0 > a1 {
            for i in 1..<7 { pal[i + 1] = ((7 - i) * a0 + i * a1) / 7 }
        } else {
            for i in 1..<5 { pal[i + 1] = ((5 - i) * a0 + i * a1) / 5 }
            pal[6] = 0
            pal[7] = 255
        }
        var bits: UInt64 = 0
        for i in 0..<6 { bits |= UInt64(b[o + 2 + i]) << UInt64(8 * i) }
        for i in 0..<16 {
            out[i * 4 + component] = UInt8(pal[Int((bits >> UInt64(i * 3)) & 7)])
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
