import SwiftUI

struct UvSetPreview: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    let uvSet: AvfxBlock
    @State private var layer = 0

    private static let layerTitles: [(tag: String, title: String)] = [
        ("TC1", "Color 1"), ("TC2", "Color 2"), ("TC3", "Color 3"), ("TC4", "Color 4"), ("TD", "Distortion"), ("TN", "Normal"), ("TR", "Reflection"),
    ]

    private var index: Int { uvSet.parent?.childrenNamed("UvSt").firstIndex { $0 === uvSet } ?? 0 }

    private var users: [(title: String, path: String?)] {
        guard let particle = uvSet.parent, let root = document.avfxRoot else { return [] }
        let textures = root.childrenNamed("Tex").map(\.stringValue)
        var result: [(String, String?)] = []
        for entry in UvSetPreview.layerTitles {
            guard let block = particle.child(entry.tag), block.int("UvSN", 0) == index else { continue }
            let texture = block.int("TxNo", -1)
            let enabled = block.child("bEna").map { $0.data.first == 1 } ?? true
            result.append((entry.title + (enabled ? "" : " (off)"), texture >= 0 && texture < textures.count ? textures[texture] : nil))
        }
        return result
    }

    private func value(_ group: String, _ axis: String?, fallback: Double, at time: Double) -> Double {
        let holder = axis.map { uvSet.child(group)?.child($0) } ?? uvSet.child(group)
        let keys = (holder?.curveKeys ?? []).map {
            CurveKeyPoint(time: Double($0.time), value: Double($0.z), interpolation: $0.type, tangentOut: Double($0.x), tangentIn: Double($0.y))
        }
        guard !keys.isEmpty else { return fallback }
        return CurveMath.sampleExtended(keys, at: time, pre: holder?.int("BvPr") ?? 0, post: holder?.int("BvPo") ?? 0)
    }

    private func render(_ texture: DecodedTexture?, side: Int, time: Double) -> (image: CGImage?, text: String) {
        let sx = value("Scl", "X", fallback: 1, at: time), sy = value("Scl", "Y", fallback: 1, at: time)
        let ox = value("Scr", "X", fallback: 0, at: time), oy = value("Scr", "Y", fallback: 0, at: time)
        let rotation = value("Rot", nil, fallback: 0, at: time)
        let text = String(format: "Scale %.2f × %.2f · Scroll %.2f, %.2f · Rotation %.1f°", sx, sy, ox, oy, rotation * 180 / .pi)
        let c = cos(-rotation), s = sin(-rotation)
        var pixels = [UInt8](repeating: 255, count: side * side * 4)
        for y in 0..<side {
            for x in 0..<side {
                let u = (Double(x) + 0.5) / Double(side) - 0.5, v = (Double(y) + 0.5) / Double(side) - 0.5
                var tx = sx * c * u + sx * s * v + ox + 0.5
                var ty = -sy * s * u + sy * c * v + oy + 0.5
                tx -= tx.rounded(.down)
                ty -= ty.rounded(.down)
                let at = (y * side + x) * 4
                if let texture, texture.width > 0, texture.height > 0 {
                    let px = Int(safe: tx * Double(texture.width), in: 0...texture.width - 1), py = Int(safe: ty * Double(texture.height), in: 0...texture.height - 1)
                    let from = (py * texture.width + px) * 4
                    let alpha = texture.alphaOnly ? 255 : Int(texture.rgba[from + 3])
                    for k in 0..<3 {
                        let value = texture.alphaOnly ? Int(texture.rgba[from + 3]) : Int(texture.rgba[from + k])
                        pixels[at + k] = UInt8((value * alpha + 40 * (255 - alpha)) / 255)
                    }
                } else {
                    let checker = (Int(tx * 4) + Int(ty * 4)) % 2 == 0
                    pixels[at] = checker ? 90 : 50
                    pixels[at + 1] = checker ? 90 : 50
                    pixels[at + 2] = checker ? 100 : 60
                }
            }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return (nil, text) }
        let image = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: provider, decode: nil,
                            shouldInterpolate: true, intent: .defaultIntent)
        return (image, text)
    }

    var body: some View {
        let users = self.users
        let chosen = min(layer, max(users.count - 1, 0))
        let path = users.isEmpty ? nil : users[chosen].path
        let result = render(path.flatMap { app.decodedTexture(for: $0) }, side: 160, time: max(0, clock.time))
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                Theme.gray(0.12)
                if let image = result.image {
                    Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(1, contentMode: .fit)
                }
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack(spacing: 4) {
                Text(result.text).font(Theme.small).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
                if users.isEmpty {
                    HelpBadge(text: "No texture layer uses UV Set \(index). Pick it in a layer's UV Set field.", symbol: "exclamationmark.triangle", tint: .orange)
                }
                if let distortion = uvSet.parent?.child("TD"), distortion.child("bEna")?.data.first == 1,
                   distortion.child("bT\(index + 1)")?.data.first == 1 {
                    HelpBadge(text: users.contains { !$0.title.hasPrefix("Distortion") }
                              ? "Distortion shifts this set: Distort UV \(index + 1) is on."
                              : "Distort UV \(index + 1) is on, but no colour layer uses this set, so the distortion has nothing to shift here.",
                              symbol: "waveform.path", tint: Theme.changed)
                }
                if uvSet.int("CUvT") != 0 {
                    HelpBadge(text: "Calculate UV is set to the by-pixel-position mode. The preview only draws the by-parameters mode.",
                              symbol: "exclamationmark.triangle", tint: .orange)
                }
                HelpBadge(text: "How the texture is laid on the particle at the playhead frame.\nScale: number of repeats.\nScroll: shift of the texture; animate it for flowing water or fire.\nRotation: turn of the texture.\nThe Random curves give each particle its own offset.")
            }
            if !users.isEmpty {
                FlowLayout(spacing: 2) {
                    ForEach(Array(users.enumerated()), id: \.offset) { offset, user in
                        SegmentButton(title: user.title, active: offset == chosen) { layer = offset }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
