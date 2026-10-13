import SwiftUI
import VfxCore

final class MaterialPixels {
    static let shared = MaterialPixels()
    private var cache: [String: (width: Int, height: Int, data: [UInt8])] = [:]
    private var missing: Set<String> = []

    func reset() {
        cache = [:]
        missing = []
    }

    private func load(_ name: String, _ app: AppModel) -> (width: Int, height: Int, data: [UInt8])? {
        if let hit = cache[name] { return hit }
        if missing.contains(name) { return nil }
        guard let url = app.textureURL(name) ?? PlaceholderTextures.url(for: name), let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            missing.insert(name)
            return nil
        }
        let side = 128
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else {
            missing.insert(name)
            return nil
        }
        cache[name] = (side, side, pixels)
        return cache[name]
    }

    func sampler(_ app: AppModel, names: [String]) -> (String, SIMD2<Float>) -> SIMD4<Float> {
        var loaded: [String: (width: Int, height: Int, data: [UInt8])] = [:]
        for name in names { if let texture = load(name, app) { loaded[name] = texture } }
        return { name, uv in
            guard let texture = loaded[name] else { return SIMD4(repeating: 1) }
            let u = uv.x - uv.x.rounded(.down), v = uv.y - uv.y.rounded(.down)
            let x = Int(safe: u * Float(texture.width), in: 0...texture.width - 1), y = Int(safe: v * Float(texture.height), in: 0...texture.height - 1)
            let o = (y * texture.width + x) * 4
            let a = Float(texture.data[o + 3]) / 255
            guard a > 0 else { return SIMD4(0, 0, 0, 0) }
            return SIMD4(Float(texture.data[o]) / 255 / a, Float(texture.data[o + 1]) / 255 / a, Float(texture.data[o + 2]) / 255 / a, a)
        }
    }

    func image(_ app: AppModel, name: String) -> CGImage? {
        guard let texture = load(name, app) else { return nil }
        return MaterialPixels.makeImage(texture.data, texture.width, texture.height)
    }

    static func makeImage(_ data: [UInt8], _ width: Int, _ height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(data) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: true,
                       intent: .defaultIntent)
    }

    func render(_ graph: MaterialGraph, node: String, pin: String?, side: Int, time: Float, base: String?,
                layers stack: [(texture: String, combine: String, keepAlpha: Bool)] = [], light: MaterialLight? = nil, app: AppModel) -> CGImage? {
        var names = graph.textures
        if let base, !names.contains(base) { names.append(base) }
        for layer in stack where !names.contains(layer.texture) { names.append(layer.texture) }
        let sample = sampler(app, names: names)
        let evaluate = graph.evaluator(node: node, output: pin, light: light, texture: sample)
        let scalar = pin.map { !["rgb", "uv", "normal"].contains($0) } ?? false
        let showsAlpha = pin == nil || pin == "rgb"
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let life = min(max(time.truncatingRemainder(dividingBy: 2) / 2, 0), 1)
        for y in 0..<side {
            for x in 0..<side {
                let uv = SIMD2((Float(x) + 0.5) / Float(side), (Float(y) + 0.5) / Float(side))
                var layers = base.map { sample($0, uv) } ?? SIMD4(repeating: 1)
                for layer in stack {
                    let l = sample(layer.texture, uv)
                    switch layer.combine {
                    case "add": layers = SIMD4(layers.x + l.x, layers.y + l.y, layers.z + l.z, layers.w)
                    case "max": layers = SIMD4(max(layers.x, l.x), max(layers.y, l.y), max(layers.z, l.z), layers.w)
                    case "min": layers = SIMD4(min(layers.x, l.x), min(layers.y, l.y), min(layers.z, l.z), layers.w)
                    case "none": break
                    default: layers = SIMD4(layers.x * l.x, layers.y * l.y, layers.z * l.z, layers.w)
                    }
                    if !layer.keepAlpha { layers.w *= l.w }
                }
                var value = evaluate(MaterialGraph.Sample(uv: uv, age: time, life: life, random: 0.37, layers: layers, particle: SIMD4(1, 1, 1, 1)))
                if scalar { value = SIMD4(value.x, value.x, value.x, 1) }
                if pin == "uv" { value = SIMD4(value.x - value.x.rounded(.down), value.y - value.y.rounded(.down), 0, 1) }
                if pin == "normal" { value = SIMD4(value.x * 0.5 + 0.5, value.y * 0.5 + 0.5, value.z * 0.5 + 0.5, 1) }
                let alpha = showsAlpha ? min(max(value.w, 0), 1) : 1
                let o = (y * side + x) * 4
                pixels[o] = UInt8(safe: min(max(value.x, 0), 1) * alpha * 255)
                pixels[o + 1] = UInt8(safe: min(max(value.y, 0), 1) * alpha * 255)
                pixels[o + 2] = UInt8(safe: min(max(value.z, 0), 1) * alpha * 255)
                pixels[o + 3] = UInt8(safe: alpha * 255)
            }
        }
        return MaterialPixels.makeImage(pixels, side, side)
    }
}

struct MaterialPreviewImage: View {
    @EnvironmentObject var app: AppModel
    let graph: MaterialGraph
    let node: String
    let pin: String?
    let base: String?
    var layers: [(texture: String, combine: String, keepAlpha: Bool)] = []
    var light: MaterialLight?
    var side = 72
    var animated = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: animated ? 0.12 : 3600)) { timeline in
            let time = Float(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 600))
            ZStack {
                CheckerBackground()
                if let image = MaterialPixels.shared.render(graph, node: node, pin: pin, side: side, time: time, base: base, layers: layers, light: light, app: app) {
                    Image(decorative: image, scale: 1).resizable().interpolation(.medium)
                }
            }
        }
    }
}
