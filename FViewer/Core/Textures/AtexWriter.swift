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
}
