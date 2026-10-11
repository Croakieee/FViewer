import CoreGraphics
import Foundation

enum AtexWriter {
    static func rgba(from image: CGImage) -> (width: Int, height: Int, pixels: [UInt8])? {
        let width = image.width, height = image.height
        guard width > 0, height > 0, width <= 8192, height <= 8192 else { return nil }
        if let direct = straightPixels(image) { return (width, height, direct) }
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let a = Int(pixels[i + 3])
            guard a > 0, a < 255 else { continue }
            for c in 0..<3 { pixels[i + c] = UInt8(min(255, (Int(pixels[i + c]) * 255 + a / 2) / a)) }
        }
        return (width, height, pixels)
    }

    private static func straightPixels(_ image: CGImage) -> [UInt8]? {
        guard image.bitsPerComponent == 8, image.bitsPerPixel == 32 || image.bitsPerPixel == 24,
              image.bitmapInfo.intersection(.byteOrderMask).rawValue == 0 || image.bitmapInfo.contains(.byteOrder32Big) || image.bitsPerPixel == 24,
              let data = image.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return nil }
        let width = image.width, height = image.height, row = image.bytesPerRow, step = image.bitsPerPixel / 8
        guard CFDataGetLength(data) >= row * (height - 1) + width * step else { return nil }
        let alpha = image.alphaInfo
        let offsets: (r: Int, g: Int, b: Int, a: Int?)
        switch (step, alpha) {
        case (3, .none): offsets = (0, 1, 2, nil)
        case (4, .last): offsets = (0, 1, 2, 3)
        case (4, .noneSkipLast): offsets = (0, 1, 2, nil)
        case (4, .first): offsets = (1, 2, 3, 0)
        case (4, .noneSkipFirst): offsets = (1, 2, 3, nil)
        default: return nil
        }
        var out = [UInt8](repeating: 255, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let from = y * row + x * step, to = (y * width + x) * 4
                out[to] = bytes[from + offsets.r]
                out[to + 1] = bytes[from + offsets.g]
                out[to + 2] = bytes[from + offsets.b]
                if let a = offsets.a { out[to + 3] = bytes[from + a] }
            }
        }
        return out
    }

    private static func halve(_ source: [UInt8], _ width: Int, _ height: Int) -> (width: Int, height: Int, pixels: [UInt8]) {
        let w = max(width / 2, 1), h = max(height / 2, 1)
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let x0 = min(x * 2, width - 1), x1 = min(x * 2 + 1, width - 1), y0 = min(y * 2, height - 1), y1 = min(y * 2 + 1, height - 1)
                let taps = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]
                var weight = 0
                var sum = [0, 0, 0, 0]
                for (tx, ty) in taps {
                    let at = (ty * width + tx) * 4
                    let a = Int(source[at + 3])
                    sum[3] += a
                    weight += a
                    for c in 0..<3 { sum[c] += Int(source[at + c]) * a }
                }
                let at = (y * w + x) * 4
                if weight > 0 {
                    for c in 0..<3 { out[at + c] = UInt8(min(255, (sum[c] + weight / 2) / weight)) }
                } else {
                    for c in 0..<3 { out[at + c] = UInt8((taps.reduce(0) { $0 + Int(source[($1.1 * width + $1.0) * 4 + c]) } + 2) / 4) }
                }
                out[at + 3] = UInt8((sum[3] + 2) / 4)
            }
        }
        return (w, h, out)
    }

    static func encode(width: Int, height: Int, rgba: [UInt8]) -> [UInt8] {
        var levels: [(width: Int, height: Int, pixels: [UInt8])] = [(width, height, rgba)]
        while levels.count < 13, let last = levels.last, last.width > 1 || last.height > 1 {
            levels.append(halve(last.pixels, last.width, last.height))
        }
        var out: [UInt8] = []
        out.appendU32(0x0080_0000)
        out.appendU32(TexFormat.b8g8r8a8.rawValue)
        out.appendU16(UInt16(width))
        out.appendU16(UInt16(height))
        out.appendU16(1)
        out.append(UInt8(levels.count))
        out.append(0)
        out.appendU32(0)
        out.appendU32(UInt32(min(1, levels.count - 1)))
        out.appendU32(UInt32(min(2, levels.count - 1)))
        var offset = 80
        for i in 0..<13 {
            if i < levels.count {
                out.appendU32(UInt32(offset))
                offset += levels[i].pixels.count
            } else {
                out.appendU32(0)
            }
        }
        for level in levels {
            var bgra = level.pixels
            for i in stride(from: 0, to: bgra.count, by: 4) { bgra.swapAt(i, i + 2) }
            out.append(contentsOf: bgra)
        }
        return out
    }
}
