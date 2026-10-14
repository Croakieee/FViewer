import Foundation

struct TextureImage {
    var width: Int
    var height: Int
    var rgba: [UInt8]

    func pixel(_ x: Int, _ y: Int) -> Int { (min(max(y, 0), height - 1) * width + min(max(x, 0), width - 1)) * 4 }

    func rotated(clockwise: Bool) -> TextureImage {
        var out = [UInt8](repeating: 0, count: rgba.count)
        for y in 0..<height {
            for x in 0..<width {
                let nx = clockwise ? height - 1 - y : y, ny = clockwise ? x : width - 1 - x
                let from = (y * width + x) * 4, to = (ny * height + nx) * 4
                for k in 0..<4 { out[to + k] = rgba[from + k] }
            }
        }
        return TextureImage(width: height, height: width, rgba: out)
    }

    func flipped(horizontal: Bool) -> TextureImage {
        var out = rgba
        for y in 0..<height {
            for x in 0..<width {
                let from = (y * width + x) * 4
                let to = horizontal ? (y * width + (width - 1 - x)) * 4 : ((height - 1 - y) * width + x) * 4
                for k in 0..<4 { out[to + k] = rgba[from + k] }
            }
        }
        return TextureImage(width: width, height: height, rgba: out)
    }

    func grayscale() -> TextureImage {
        var out = rgba
        for i in stride(from: 0, to: out.count, by: 4) {
            let value = UInt8((Int(out[i]) * 299 + Int(out[i + 1]) * 587 + Int(out[i + 2]) * 114 + 500) / 1000)
            out[i] = value
            out[i + 1] = value
            out[i + 2] = value
        }
        return TextureImage(width: width, height: height, rgba: out)
    }

    func resized(width newWidth: Int, height newHeight: Int) -> TextureImage {
        let w = max(newWidth, 1), h = max(newHeight, 1)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            let fy = (Double(y) + 0.5) * Double(height) / Double(h) - 0.5
            let y0 = Int(safe: fy.rounded(.down)), ty = fy - Double(y0)
            for x in 0..<w {
                let fx = (Double(x) + 0.5) * Double(width) / Double(w) - 0.5
                let x0 = Int(safe: fx.rounded(.down)), tx = fx - Double(x0)
                let a = pixel(x0, y0), b = pixel(x0 + 1, y0), c = pixel(x0, y0 + 1), d = pixel(x0 + 1, y0 + 1)
                let to = (y * w + x) * 4
                for k in 0..<4 {
                    let top = Double(rgba[a + k]) * (1 - tx) + Double(rgba[b + k]) * tx
                    let bottom = Double(rgba[c + k]) * (1 - tx) + Double(rgba[d + k]) * tx
                    out[to + k] = UInt8(max(0, min(255, (top * (1 - ty) + bottom * ty).rounded())))
                }
            }
        }
        return TextureImage(width: w, height: h, rgba: out)
    }

    func halved() -> TextureImage {
        let w = max(width / 2, 1), h = max(height / 2, 1)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            let y0 = y * height / h, y1 = max(y0 + 1, (y + 1) * height / h)
            for x in 0..<w {
                let x0 = x * width / w, x1 = max(x0 + 1, (x + 1) * width / w)
                var sums = [0, 0, 0, 0], weighted = [0, 0, 0], count = 0
                for sy in y0..<min(y1, height) {
                    for sx in x0..<min(x1, width) {
                        let at = (sy * width + sx) * 4
                        let a = Int(rgba[at + 3])
                        for k in 0..<3 {
                            sums[k] += Int(rgba[at + k])
                            weighted[k] += Int(rgba[at + k]) * a
                        }
                        sums[3] += a
                        count += 1
                    }
                }
                let to = (y * w + x) * 4
                guard count > 0 else { continue }
                for k in 0..<3 {
                    out[to + k] = sums[3] > 0 ? UInt8(min(255, (weighted[k] + sums[3] / 2) / sums[3])) : UInt8((sums[k] + count / 2) / count)
                }
                out[to + 3] = UInt8((sums[3] + count / 2) / count)
            }
        }
        return TextureImage(width: w, height: h, rgba: out)
    }
}

enum TextureCodec {
    static let importFormats: [(format: TexFormat, name: String)] = [
        (.bc3, "DXT5 (colour + smooth alpha)"), (.bc1, "DXT1 (colour, 1-bit alpha)"), (.b8g8r8a8, "B8G8R8A8 (uncompressed)"), (.a8, "A8 (alpha only)"),
    ]

    private static func pack565(_ r: Int, _ g: Int, _ b: Int) -> UInt16 {
        UInt16((r * 31 + 127) / 255) << 11 | UInt16((g * 63 + 127) / 255) << 5 | UInt16((b * 31 + 127) / 255)
    }

    private static func unpack565(_ c: UInt16) -> (Int, Int, Int) {
        let r = Int(c >> 11) & 31, g = Int(c >> 5) & 63, b = Int(c) & 31
        return ((r * 255 + 15) / 31, (g * 255 + 31) / 63, (b * 255 + 15) / 31)
    }

    private static func colorBlock(_ block: [UInt8], punchThrough: Bool) -> [UInt8] {
        var low = (255, 255, 255), high = (0, 0, 0)
        var transparent = false
        for i in 0..<16 {
            if punchThrough && block[i * 4 + 3] < 128 {
                transparent = true
                continue
            }
            low = (min(low.0, Int(block[i * 4])), min(low.1, Int(block[i * 4 + 1])), min(low.2, Int(block[i * 4 + 2])))
            high = (max(high.0, Int(block[i * 4])), max(high.1, Int(block[i * 4 + 1])), max(high.2, Int(block[i * 4 + 2])))
        }
        if low.0 > high.0 { low = (0, 0, 0) }
        var mean = SIMD3<Double>(0, 0, 0), used = 0.0
        var points: [SIMD3<Double>] = []
        for i in 0..<16 where !(punchThrough && block[i * 4 + 3] < 128) {
            let point = SIMD3(Double(block[i * 4]), Double(block[i * 4 + 1]), Double(block[i * 4 + 2]))
            points.append(point)
            mean += point
            used += 1
        }
        if used > 1 {
            mean /= used
            var axis = SIMD3<Double>(0, 0, 0), reach = -1.0
            for point in points {
                let d = point - mean
                let far = d.x * d.x + d.y * d.y + d.z * d.z
                if far > reach {
                    reach = far
                    axis = d
                }
            }
            for _ in 0..<4 {
                var next = SIMD3<Double>(0, 0, 0)
                for point in points {
                    let d = point - mean
                    next += d * (d.x * axis.x + d.y * axis.y + d.z * axis.z)
                }
                let length = (next.x * next.x + next.y * next.y + next.z * next.z).squareRoot()
                if length < 1e-6 { break }
                axis = next / length
            }
            let size = (axis.x * axis.x + axis.y * axis.y + axis.z * axis.z).squareRoot()
            if size > 1e-6 {
                axis /= size
                var least = Double.infinity, most = -Double.infinity
                for point in points {
                    let d = point - mean
                    let along = d.x * axis.x + d.y * axis.y + d.z * axis.z
                    least = min(least, along)
                    most = max(most, along)
                }
                let a = mean + axis * least, b = mean + axis * most
                func byte(_ v: Double) -> Int { Int(min(max(v.rounded(), 0), 255)) }
                low = (byte(a.x), byte(a.y), byte(a.z))
                high = (byte(b.x), byte(b.y), byte(b.z))
            }
        }
        var c0 = pack565(high.0, high.1, high.2), c1 = pack565(low.0, low.1, low.2)
        let threeColor = punchThrough && transparent
        if threeColor {
            if c0 > c1 { swap(&c0, &c1) }
        } else if c0 < c1 {
            swap(&c0, &c1)
        } else if c0 == c1 {
            if c0 < 0xffff { c0 += 1 } else { c1 -= 1 }
            if c0 < c1 { swap(&c0, &c1) }
        }
        let a = unpack565(c0), b = unpack565(c1)
        var palette: [(Int, Int, Int)] = [a, b]
        if threeColor {
            palette.append(((a.0 + b.0) / 2, (a.1 + b.1) / 2, (a.2 + b.2) / 2))
        } else {
            palette.append(((2 * a.0 + b.0) / 3, (2 * a.1 + b.1) / 3, (2 * a.2 + b.2) / 3))
            palette.append(((a.0 + 2 * b.0) / 3, (a.1 + 2 * b.1) / 3, (a.2 + 2 * b.2) / 3))
        }
        var bits: UInt32 = 0
        for i in 0..<16 {
            var best = 0
            if threeColor && block[i * 4 + 3] < 128 {
                best = 3
            } else {
                var bestDistance = Int.max
                for (index, entry) in palette.enumerated() {
                    let dr = Int(block[i * 4]) - entry.0, dg = Int(block[i * 4 + 1]) - entry.1, db = Int(block[i * 4 + 2]) - entry.2
                    let distance = dr * dr + dg * dg + db * db
                    if distance < bestDistance {
                        bestDistance = distance
                        best = index
                    }
                }
            }
            bits |= UInt32(best) << UInt32(i * 2)
        }
        var out: [UInt8] = []
        out.appendU16(c0)
        out.appendU16(c1)
        out.appendU32(bits)
        return out
    }

    private static func alphaBlock(_ block: [UInt8]) -> [UInt8] {
        var low = 255, high = 0
        for i in 0..<16 {
            low = min(low, Int(block[i * 4 + 3]))
            high = max(high, Int(block[i * 4 + 3]))
        }
        var out: [UInt8] = [UInt8(high), UInt8(low)]
        var palette = [high, low]
        if high > low {
            for k in 1...6 { palette.append(((7 - k) * high + k * low) / 7) }
        } else {
            palette.append(contentsOf: [Int](repeating: high, count: 6))
        }
        var bits: UInt64 = 0
        for i in 0..<16 {
            let value = Int(block[i * 4 + 3])
            var best = 0, bestDistance = Int.max
            for (index, entry) in palette.enumerated() where abs(entry - value) < bestDistance {
                bestDistance = abs(entry - value)
                best = index
            }
            bits |= UInt64(best) << UInt64(i * 3)
        }
        for k in 0..<6 { out.append(UInt8((bits >> UInt64(k * 8)) & 0xff)) }
        return out
    }

    static func surface(_ image: TextureImage, _ format: TexFormat) -> [UInt8] {
        switch format {
        case .a8:
            let opaque = !stride(from: 3, to: image.rgba.count, by: 4).contains { image.rgba[$0] != 255 }
            if opaque {
                var gray: [UInt8] = []
                gray.reserveCapacity(image.rgba.count / 4)
                for at in stride(from: 0, to: image.rgba.count - 3, by: 4) {
                    let red = Int(image.rgba[at]) * 77, green = Int(image.rgba[at + 1]) * 150, blue = Int(image.rgba[at + 2]) * 29
                    gray.append(UInt8((red + green + blue) >> 8))
                }
                return gray
            }
            return stride(from: 3, to: image.rgba.count, by: 4).map { image.rgba[$0] }
        case .bc1, .bc3:
            var out: [UInt8] = []
            let bw = (image.width + 3) / 4, bh = (image.height + 3) / 4
            out.reserveCapacity(bw * bh * (format == .bc1 ? 8 : 16))
            var block = [UInt8](repeating: 0, count: 64)
            for by in 0..<bh {
                for bx in 0..<bw {
                    for py in 0..<4 {
                        for px in 0..<4 {
                            let from = image.pixel(bx * 4 + px, by * 4 + py), to = (py * 4 + px) * 4
                            for k in 0..<4 { block[to + k] = image.rgba[from + k] }
                        }
                    }
                    if format == .bc3 { out.append(contentsOf: alphaBlock(block)) }
                    out.append(contentsOf: colorBlock(block, punchThrough: format == .bc1))
                }
            }
            return out
        default:
            var out = image.rgba
            for i in stride(from: 0, to: out.count, by: 4) { out.swapAt(i, i + 2) }
            return out
        }
    }

    static func header(_ format: TexFormat, width: Int, height: Int, sizes: [Int]) -> [UInt8] {
        var out: [UInt8] = []
        out.appendU32(0x0080_0000)
        out.appendU32(format.rawValue)
        out.appendU16(UInt16(min(max(width, 0), 65535)))
        out.appendU16(UInt16(min(max(height, 0), 65535)))
        out.appendU16(1)
        out.append(UInt8(min(sizes.count, 255)))
        out.append(0)
        out.appendU32(0)
        out.appendU32(UInt32(min(1, sizes.count - 1)))
        out.appendU32(UInt32(min(2, sizes.count - 1)))
        var offset = 80
        for i in 0..<13 {
            if i < sizes.count {
                out.appendU32(UInt32(offset))
                offset += sizes[i]
            } else {
                out.appendU32(0)
            }
        }
        return out
    }

    static func encode(_ image: TextureImage, format requested: TexFormat, mips: Int) -> [UInt8] {
        let format: TexFormat = [.bc1, .bc3, .a8, .b8g8r8a8].contains(requested) ? requested : .b8g8r8a8
        var levels = [image]
        while levels.count < min(max(mips, 1), 13), let last = levels.last, last.width > 1 || last.height > 1 { levels.append(last.halved()) }
        let surfaces = levels.map { surface($0, format) }
        return header(format, width: image.width, height: image.height, sizes: surfaces.map(\.count)) + surfaces.flatMap { $0 }
    }

    static func levelSize(_ format: TexFormat, _ width: Int, _ height: Int) -> Int {
        let bw = max((width + 3) / 4, 1), bh = max((height + 3) / 4, 1)
        switch format {
        case .bc1, .bc4: return bw * bh * 8
        case .bc2, .bc3, .bc5, .bc7: return bw * bh * 16
        case .l8, .a8: return width * height
        case .b4g4r4a4, .b5g5r5a1: return width * height * 2
        case .b8g8r8a8, .b8g8r8x8: return width * height * 4
        }
    }

    static func atex(fromDDS bytes: [UInt8]) throws -> [UInt8] {
        guard bytes.count >= 128, bytes.u32(0) == 0x2053_4444 else { throw TexError.invalid("Not a DDS file") }
        let height = Int(bytes.u32(12)), width = Int(bytes.u32(16))
        let mipCount = min(max(Int(bytes.u32(28)), 1), 16)
        guard width >= 1, height >= 1, width <= 16384, height <= 16384 else { throw TexError.invalid("DDS size \(width)×\(height) is not supported") }
        let flags = bytes.u32(80), fourCC = bytes.u32(84), bitCount = bytes.u32(88), redMask = bytes.u32(92), alphaMask = bytes.u32(104)
        var start = 128
        var format: TexFormat?
        var swapRedBlue = false
        func code(_ text: String) -> UInt32 { Array(text.utf8).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << UInt32($1.offset * 8) } }
        if flags & 0x4 != 0 {
            switch fourCC {
            case code("DXT1"): format = .bc1
            case code("DXT2"), code("DXT3"): format = .bc2
            case code("DXT4"), code("DXT5"): format = .bc3
            case code("ATI1"), code("BC4U"): format = .bc4
            case code("ATI2"), code("BC5U"): format = .bc5
            case code("DX10"):
                guard bytes.count >= 148 else { throw TexError.invalid("The DDS header is truncated") }
                start = 148
                switch bytes.u32(128) {
                case 70, 71, 72: format = .bc1
                case 73, 74, 75: format = .bc2
                case 76, 77, 78: format = .bc3
                case 79, 80: format = .bc4
                case 82, 83: format = .bc5
                case 97, 98, 99: format = .bc7
                case 87, 91: format = .b8g8r8a8
                case 88, 93: format = .b8g8r8x8
                case 28, 29:
                    format = .b8g8r8a8
                    swapRedBlue = true
                case 65: format = .a8
                case 61: format = .l8
                default: break
                }
            default: break
            }
        } else if bitCount == 32 {
            format = alphaMask == 0 ? .b8g8r8x8 : .b8g8r8a8
            swapRedBlue = redMask == 0x0000_00ff
        } else if bitCount == 8 {
            format = flags & 0x2 != 0 ? .a8 : .l8
        } else if bitCount == 16 {
            let greenMask = bytes.u32(96)
            if redMask == 0x0f00, greenMask == 0x00f0, alphaMask == 0xf000 {
                format = .b4g4r4a4
            } else if redMask == 0x7c00, greenMask == 0x03e0, alphaMask == 0x8000 {
                format = .b5g5r5a1
            } else {
                throw TexError.invalid("This 16-bit DDS layout (R5G6B5, A8L8 or X1R5G5B5) is not supported. Save it as DXT or 32-bit")
            }
        }
        guard let format, width > 0, height > 0 else { throw TexError.invalid("This DDS pixel format is not supported") }
        var sizes: [Int] = []
        var w = width, h = height, used = 0
        for _ in 0..<min(mipCount, 13) {
            let size = levelSize(format, w, h)
            guard start + used + size <= bytes.count else { break }
            sizes.append(size)
            used += size
            w = max(w / 2, 1)
            h = max(h / 2, 1)
        }
        guard !sizes.isEmpty else { throw TexError.invalid("The DDS file holds no complete image") }
        var data = Array(bytes[start..<start + used])
        if swapRedBlue {
            for i in stride(from: 0, to: data.count - 3, by: 4) { data.swapAt(i, i + 2) }
        }
        return header(format, width: width, height: height, sizes: sizes) + data
    }

    static func dds(fromAtex bytes: [UInt8]) throws -> [UInt8] {
        guard bytes.count >= 80, let format = TexFormat(rawValue: bytes.u32(4)) else { throw TexError.invalid("Not a texture this app can export") }
        let width = Int(bytes.u16(8)), height = Int(bytes.u16(10)), mips = max(Int(bytes[14] & 0x7f), 1)
        let start = Int(bytes.u32(28))
        guard start >= 80, start <= bytes.count else { throw TexError.invalid("Invalid surface offset") }
        var out: [UInt8] = []
        func code(_ text: String) -> UInt32 { Array(text.utf8).enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << UInt32($1.offset * 8) } }
        var pixelFlags: UInt32 = 0x4, fourCC: UInt32 = 0, bitCount: UInt32 = 0
        var masks: (UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0)
        var dxgi: UInt32?
        switch format {
        case .bc1: fourCC = code("DXT1")
        case .bc2: fourCC = code("DXT3")
        case .bc3: fourCC = code("DXT5")
        case .bc4: fourCC = code("ATI1")
        case .bc5: fourCC = code("ATI2")
        case .bc7:
            fourCC = code("DX10")
            dxgi = 98
        case .b8g8r8a8:
            pixelFlags = 0x41
            bitCount = 32
            masks = (0x00ff_0000, 0x0000_ff00, 0x0000_00ff, 0xff00_0000)
        case .b8g8r8x8:
            pixelFlags = 0x40
            bitCount = 32
            masks = (0x00ff_0000, 0x0000_ff00, 0x0000_00ff, 0)
        case .a8:
            pixelFlags = 0x2
            bitCount = 8
            masks = (0, 0, 0, 0xff)
        case .l8:
            pixelFlags = 0x20000
            bitCount = 8
            masks = (0xff, 0, 0, 0)
        case .b4g4r4a4:
            pixelFlags = 0x41
            bitCount = 16
            masks = (0x0f00, 0x00f0, 0x000f, 0xf000)
        case .b5g5r5a1:
            pixelFlags = 0x41
            bitCount = 16
            masks = (0x7c00, 0x03e0, 0x001f, 0x8000)
        }
        out.appendU32(0x2053_4444)
        out.appendU32(124)
        out.appendU32(0x1 | 0x2 | 0x4 | 0x1000 | (mips > 1 ? 0x20000 : 0) | (bitCount == 0 ? 0x80000 : 0x8))
        out.appendU32(UInt32(height))
        out.appendU32(UInt32(width))
        out.appendU32(UInt32(bitCount == 0 ? levelSize(format, width, height) : width * Int(bitCount) / 8))
        out.appendU32(0)
        out.appendU32(UInt32(mips))
        for _ in 0..<11 { out.appendU32(0) }
        out.appendU32(32)
        out.appendU32(pixelFlags)
        out.appendU32(fourCC)
        out.appendU32(bitCount)
        out.appendU32(masks.0)
        out.appendU32(masks.1)
        out.appendU32(masks.2)
        out.appendU32(masks.3)
        out.appendU32(0x1000 | (mips > 1 ? 0x400008 : 0))
        for _ in 0..<4 { out.appendU32(0) }
        if let dxgi {
            out.appendU32(dxgi)
            out.appendU32(3)
            out.appendU32(0)
            out.appendU32(1)
            out.appendU32(0)
        }
        out.append(contentsOf: bytes[start...])
        return out
    }
}
