import Combine
import SwiftUI

enum PaintTool: String, CaseIterable {
    case pan = "Pan", brush = "Paintbrush", eraser = "Eraser", fill = "Bucket Fill", picker = "Color Picker", select = "Rectangle Select"

    var symbol: String {
        switch self {
        case .pan: return "hand.raised"
        case .brush: return "paintbrush.pointed"
        case .eraser: return "eraser"
        case .fill: return "drop"
        case .picker: return "eyedropper"
        case .select: return "rectangle.dashed"
        }
    }
}

final class TextureEditorModel: ObservableObject {
    @Published var image = TextureImage(width: 1, height: 1, rgba: [0, 0, 0, 0])
    @Published var tool = PaintTool.brush
    @Published var color = SIMD4<Double>(1, 1, 1, 1)
    @Published var size: Double = 12
    @Published var opacity: Double = 1
    @Published var hardness: Double = 0.7
    @Published var tolerance: Double = 24
    @Published var channels = [true, true, true, true]
    @Published var zoom: Double = 1
    @Published var offset = CGSize.zero
    @Published var selection: CGRect?
    @Published var brightness: Double = 0
    @Published var contrast: Double = 0
    @Published var revision = 0
    private(set) var undoStack: [TextureImage] = []
    private(set) var redoStack: [TextureImage] = []
    var sourcePath = ""
    var loadedKey = ""
    var loadedTarget: String?
    var appliedRevision = 0
    var unsaved: Bool { !loadedKey.isEmpty && revision != appliedRevision }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func load(_ next: TextureImage, path: String, key: String) {
        image = next
        sourcePath = path
        loadedKey = key
        undoStack = []
        redoStack = []
        selection = nil
        revision += 1
        appliedRevision = revision
    }

    func checkpoint() {
        undoStack.append(image)
        let room = max(4, min(40, 268_435_456 / max(image.rgba.count, 1)))
        while undoStack.count > room { undoStack.removeFirst() }
        redoStack = []
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(image)
        image = last
        revision += 1
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(image)
        image = next
        revision += 1
    }

    func apply(_ title: String, _ change: (TextureImage) -> TextureImage) {
        checkpoint()
        image = change(image)
        if let rect = selection, rect.maxX > CGFloat(image.width) || rect.maxY > CGFloat(image.height) { selection = nil }
        revision += 1
    }

    private func allowed(_ x: Int, _ y: Int) -> Bool {
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return false }
        guard let rect = selection else { return true }
        return CGFloat(x) >= rect.minX && CGFloat(x) < rect.maxX && CGFloat(y) >= rect.minY && CGFloat(y) < rect.maxY
    }

    private func stamp(at point: CGPoint, erase: Bool, into pixels: inout [UInt8]) {
        let radius = max(size / 2, 0.5)
        let x0 = Int(safe: (Double(point.x) - radius).rounded(.down)), x1 = Int(safe: (Double(point.x) + radius).rounded(.up))
        let y0 = Int(safe: (Double(point.y) - radius).rounded(.down)), y1 = Int(safe: (Double(point.y) + radius).rounded(.up))
        let rgb = [color.x, color.y, color.z].map { $0 * 255 }
        for y in y0...y1 {
            for x in x0...x1 where allowed(x, y) {
                let distance = hypot(Double(x) + 0.5 - Double(point.x), Double(y) + 0.5 - Double(point.y))
                guard distance <= radius else { continue }
                let edge = radius * hardness
                let falloff = distance <= edge ? 1 : max(0, 1 - (distance - edge) / max(radius - edge, 0.001))
                let strength = falloff * opacity
                let at = (y * image.width + x) * 4
                if erase {
                    if channels[3] { pixels[at + 3] = UInt8(max(0, Double(pixels[at + 3]) * (1 - strength))) }
                } else {
                    for k in 0..<3 where channels[k] {
                        pixels[at + k] = UInt8(max(0, min(255, Double(pixels[at + k]) * (1 - strength) + rgb[k] * strength)))
                    }
                    if channels[3] {
                        pixels[at + 3] = UInt8(max(0, min(255, Double(pixels[at + 3]) * (1 - strength) + color.w * 255 * strength)))
                    }
                }
            }
        }
    }

    func stroke(from a: CGPoint, to b: CGPoint, erase: Bool) {
        let distance = hypot(b.x - a.x, b.y - a.y)
        let steps = Int(safe: distance / CGFloat(max(size / 4, 0.5)), in: 1...20000)
        var pixels = image.rgba
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            stamp(at: CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), erase: erase, into: &pixels)
        }
        image.rgba = pixels
        revision += 1
    }

    func pick(at point: CGPoint) {
        let x = Int(point.x), y = Int(point.y)
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return }
        let at = (y * image.width + x) * 4
        color = SIMD4(Double(image.rgba[at]) / 255, Double(image.rgba[at + 1]) / 255, Double(image.rgba[at + 2]) / 255, Double(image.rgba[at + 3]) / 255)
    }

    func fill(at point: CGPoint) {
        let sx = Int(safe: point.x), sy = Int(safe: point.y)
        guard allowed(sx, sy) else { return }
        checkpoint()
        let width = image.width, height = image.height
        var pixels = image.rgba
        guard pixels.count >= width * height * 4 else { return }
        var x0 = 0, y0 = 0, x1 = width, y1 = height
        if let rect = selection {
            x0 = max(0, Int(safe: rect.minX.rounded(.up)))
            y0 = max(0, Int(safe: rect.minY.rounded(.up)))
            x1 = min(width, Int(safe: rect.maxX.rounded(.up)))
            y1 = min(height, Int(safe: rect.maxY.rounded(.up)))
        }
        let start = (sy * width + sx) * 4
        let target = [Int(pixels[start]), Int(pixels[start + 1]), Int(pixels[start + 2]), Int(pixels[start + 3])]
        let paint = [color.x, color.y, color.z, color.w].map { Double(UInt8(safe: ($0 * 255).rounded())) }
        let limit = Int(safe: tolerance)
        let mask = channels
        let keep = 1 - opacity, mix = opacity
        var visited = [Bool](repeating: false, count: width * height)
        var stack = [sy * width + sx]
        pixels.withUnsafeMutableBufferPointer { buffer in
            visited.withUnsafeMutableBufferPointer { seen in
                while let cell = stack.popLast() {
                    if seen[cell] { continue }
                    let at = cell * 4
                    if abs(Int(buffer[at]) - target[0]) > limit || abs(Int(buffer[at + 1]) - target[1]) > limit
                        || abs(Int(buffer[at + 2]) - target[2]) > limit || abs(Int(buffer[at + 3]) - target[3]) > limit { continue }
                    seen[cell] = true
                    for k in 0..<4 where mask[k] { buffer[at + k] = UInt8(safe: Double(buffer[at + k]) * keep + paint[k] * mix) }
                    let x = cell % width, y = cell / width
                    if x + 1 < x1, !seen[cell + 1] { stack.append(cell + 1) }
                    if x - 1 >= x0, !seen[cell - 1] { stack.append(cell - 1) }
                    if y + 1 < y1, !seen[cell + width] { stack.append(cell + width) }
                    if y - 1 >= y0, !seen[cell - width] { stack.append(cell - width) }
                }
            }
        }
        image.rgba = pixels
        revision += 1
    }

    func adjust(_ change: (Int, [UInt8], Int) -> UInt8, title: String) {
        apply(title) { source in
            var out = source
            for y in 0..<source.height {
                for x in 0..<source.width where allowed(x, y) {
                    let at = (y * source.width + x) * 4
                    for k in 0..<4 where channels[k] { out.rgba[at + k] = change(k, source.rgba, at) }
                }
            }
            return out
        }
    }

    private static func luminance(_ src: [UInt8], _ at: Int) -> UInt8 {
        let sum: Int = Int(src[at]) * 299 + Int(src[at + 1]) * 587 + Int(src[at + 2]) * 114 + 500
        return UInt8(sum / 1000)
    }

    func invert() {
        adjust({ k, src, at in
            if k == 3 { return src[at + 3] }
            return 255 - src[at + k]
        }, title: "Invert")
    }

    func desaturate() {
        adjust({ k, src, at in
            if k == 3 { return src[at + 3] }
            return TextureEditorModel.luminance(src, at)
        }, title: "Desaturate")
    }

    private func alphaOnly(_ title: String, _ change: @escaping ([UInt8], Int) -> UInt8) {
        let saved = channels
        channels = [false, false, false, true]
        adjust({ _, src, at in change(src, at) }, title: title)
        channels = saved
    }

    func luminanceToAlpha() { alphaOnly("Luminance to Alpha") { src, at in TextureEditorModel.luminance(src, at) } }

    func opaque() { alphaOnly("Alpha to Opaque") { _, _ in 255 } }

    func premultiply() {
        adjust({ k, src, at in
            if k == 3 { return src[at + 3] }
            let value: Int = Int(src[at + k]) * Int(src[at + 3]) / 255
            return UInt8(value)
        }, title: "Premultiply")
    }

    func applyBrightnessContrast() {
        let shift: Double = brightness * 255
        let factor: Double = tan((contrast + 1) * Double.pi / 4)
        adjust({ k, src, at in
            if k == 3 { return src[at + 3] }
            let value: Double = (Double(src[at + k]) - 127.5) * factor + 127.5 + shift
            return UInt8(max(0, min(255, value.rounded())))
        }, title: "Brightness-Contrast")
        brightness = 0
        contrast = 0
    }

    private var shown: (revision: Int, channels: [Bool], size: Int, image: CGImage?)?

    func display() -> CGImage? {
        if let shown, shown.revision == revision, shown.channels == channels, shown.size == image.rgba.count { return shown.image }
        let fresh = makeDisplay()
        shown = (revision, channels, image.rgba.count, fresh)
        return fresh
    }

    private func makeDisplay() -> CGImage? {
        var pixels = image.rgba
        let onlyAlpha = !channels[0] && !channels[1] && !channels[2] && channels[3]
        for i in stride(from: 0, to: pixels.count, by: 4) {
            if onlyAlpha {
                let a = pixels[i + 3]
                pixels[i] = a
                pixels[i + 1] = a
                pixels[i + 2] = a
                pixels[i + 3] = 255
                continue
            }
            for k in 0..<3 where !channels[k] { pixels[i + k] = 0 }
            if !channels[3] { pixels[i + 3] = 255 }
        }
        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else { return nil }
        return CGImage(width: image.width, height: image.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: image.width * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil, shouldInterpolate: false,
                       intent: .defaultIntent)
    }
}

struct TextureEditorView: View {
    @EnvironmentObject var app: AppModel
    @StateObject private var model = TextureEditorModel()
    @State private var last: CGPoint?
    @State private var dragStart: CGPoint?
    @State private var panStart: CGSize?
    @GestureState private var pressing = false
    @State private var hover: CGPoint?
    @State private var repeatImage = false
    @State private var uvModel: Int?
    @State private var canvasSize = CGSize(width: 600, height: 400)

    private var block: AvfxBlock? {
        guard let document = app.document, let id = app.textureEditorTarget, case .avfx(let block, _, _)? = document.node(id)?.payload,
              block.tag == "Tex", block.children == nil else { return nil }
        return block
    }

    private func reload() {
        guard let block, let document = app.document else { return }
        let path = block.stringValue
        let key = "\(document.id)|\(app.textureEditorTarget ?? "")|\(path)"
        guard key != model.loadedKey else { return }
        if model.unsaved, let previous = model.loadedTarget, previous != app.textureEditorTarget {
            let alert = NSAlert()
            alert.messageText = "Discard the changes to this texture?"
            alert.informativeText = "The edits were not applied to the effect."
            alert.addButton(withTitle: "Keep Editing")
            alert.addButton(withTitle: "Discard")
            if alert.runModal() == .alertFirstButtonReturn {
                app.textureEditorTarget = previous
                return
            }
        }
        if let decoded = app.decodedTexture(for: path) {
            model.load(TextureImage(width: decoded.width, height: decoded.height, rgba: decoded.rgba), path: path, key: key)
        } else if let image = app.image(for: path), let pixels = AtexWriter.rgba(from: image) {
            model.load(TextureImage(width: pixels.width, height: pixels.height, rgba: pixels.pixels), path: path, key: key)
        } else {
            model.load(TextureImage(width: 256, height: 256, rgba: [UInt8](repeating: 0, count: 256 * 256 * 4)), path: path, key: key)
        }
        model.loadedTarget = app.textureEditorTarget
        model.zoom = max(1, (480 / Double(max(model.image.width, model.image.height, 1))).rounded(.down))
        model.offset = .zero
    }

    var body: some View {
        VStack(spacing: 0) {
            menuBar
            HStack(spacing: 0) {
                toolbox
                Rectangle().fill(Theme.line).frame(width: 1)
                canvas
                Rectangle().fill(Theme.line).frame(width: 1)
                dock.frame(width: 250)
            }
            statusBar
        }
        .frame(minWidth: 860, minHeight: 540)
        .background(Theme.window)
        .preferredColorScheme(Theme.scheme)
        .onAppear { reload() }
        .onChange(of: app.textureEditorTarget) { _, _ in reload() }
    }

    private func menu<Items: View>(_ title: String, @ViewBuilder _ items: () -> Items) -> some View {
        Menu(content: items) {
            Text(title).font(Theme.font).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 20)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var menuBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "photo.artframe").font(.system(size: 11)).foregroundStyle(NodeTint.texture.color)
            Text((model.sourcePath as NSString).lastPathComponent).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text).lineLimit(1)
            fileMenu
            editMenu
            imageMenu
            colorsMenu
            viewMenu
            Spacer()
            HeaderButton(symbol: "arrow.uturn.backward", help: "Undo") { model.undo() }
            HeaderButton(symbol: "arrow.uturn.forward", help: "Redo") { model.redo() }
            SegmentButton(title: "Apply to Effect", active: block != nil) { applyToEffect() }
            HelpBadge(text: "Apply to Effect writes a new texture file next to the effect, in the format chosen under Properties → Textures → Import Settings, and points the slot at it. The original file is never changed.")
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(Theme.gray(0.094))
    }

    private var fileMenu: some View {
        menu("File") {
            Button("Apply to Effect") { applyToEffect() }.disabled(block == nil)
            Button("Export PNG…") { exportPNG() }
            Button("Revert") {
                model.loadedKey = ""
                reload()
            }
        }
    }

    private var editMenu: some View {
        menu("Edit") {
            Button("Undo") { model.undo() }.disabled(!model.canUndo)
            Button("Redo") { model.redo() }.disabled(!model.canRedo)
            Divider()
            Button("Select All") { model.selection = CGRect(x: 0, y: 0, width: model.image.width, height: model.image.height) }
            Button("Select None") { model.selection = nil }
        }
    }

    private var imageMenu: some View {
        menu("Image") {
            Button("Rotate 90° Clockwise") { model.apply("Rotate") { $0.rotated(clockwise: true) } }
            Button("Rotate 90° Counter-Clockwise") { model.apply("Rotate") { $0.rotated(clockwise: false) } }
            Button("Flip Horizontally") { model.apply("Flip") { $0.flipped(horizontal: true) } }
            Button("Flip Vertically") { model.apply("Flip") { $0.flipped(horizontal: false) } }
            Divider()
            Button("Scale to 50%") { model.apply("Scale") { $0.resized(width: max($0.width / 2, 1), height: max($0.height / 2, 1)) } }
            Button("Scale to 200%") { model.apply("Scale") { $0.resized(width: min($0.width * 2, 8192), height: min($0.height * 2, 8192)) } }
            Button("Scale to Power of Two") {
                model.apply("Scale") { image in
                    func nearest(_ value: Int) -> Int { max(1, 1 << Int(safe: (log2(Double(max(value, 1)))).rounded())) }
                    return image.resized(width: nearest(image.width), height: nearest(image.height))
                }
            }
            if let rect = model.selection, rect.width >= 1, rect.height >= 1 {
                Button("Crop to Selection") {
                    model.apply("Crop") { image in
                        let x0 = max(0, Int(rect.minX)), y0 = max(0, Int(rect.minY))
                        let w = min(Int(rect.width), image.width - x0), h = min(Int(rect.height), image.height - y0)
                        guard w > 0, h > 0 else { return image }
                        var out = [UInt8](repeating: 0, count: w * h * 4)
                        for y in 0..<h {
                            for x in 0..<w {
                                let from = ((y0 + y) * image.width + x0 + x) * 4, to = (y * w + x) * 4
                                for k in 0..<4 { out[to + k] = image.rgba[from + k] }
                            }
                        }
                        return TextureImage(width: w, height: h, rgba: out)
                    }
                    model.selection = nil
                }
            }
        }
    }

    private var colorsMenu: some View {
        menu("Colors") {
            Button("Invert") { model.invert() }
            Button("Desaturate") { model.desaturate() }
            Button("Luminance to Alpha") { model.luminanceToAlpha() }
            Button("Alpha to Opaque") { model.opaque() }
            Button("Premultiply Colour by Alpha") { model.premultiply() }
        }
    }

    private var viewMenu: some View {
        menu("View") {
            Button("Zoom In") { model.zoom = min(model.zoom * 2, 64) }
            Button("Zoom Out") { model.zoom = max(model.zoom / 2, 0.0625) }
            Button("Zoom 1:1") {
                model.zoom = 1
                model.offset = .zero
            }
            Button("Zoom to Fit") { fitView() }
            Divider()
            Button((repeatImage ? "✓ " : "") + "Repeat Image") { repeatImage.toggle() }
            Menu("UV Overlay") {
                Button((uvModel == nil ? "✓ " : "") + "None") { uvModel = nil }
                ForEach(0..<modelCount, id: \.self) { index in
                    Button((uvModel == index ? "✓ " : "") + "Model \(index)") { uvModel = index }
                }
            }
        }
    }

    private var toolbox: some View {
        VStack(spacing: 2) {
            ForEach(PaintTool.allCases, id: \.self) { tool in
                HeaderButton(symbol: tool.symbol, active: model.tool == tool, help: tool.rawValue) { model.tool = tool }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .frame(width: 34)
        .background(Theme.panel)
    }

    private var modelCount: Int { app.document?.avfxRoot?.childrenNamed("Modl").count ?? 0 }

    private func fitView() {
        let room = CGSize(width: max(canvasSize.width - 40, 20), height: max(canvasSize.height - 40, 20))
        model.zoom = min(max(Double(min(room.width / CGFloat(max(model.image.width, 1)), room.height / CGFloat(max(model.image.height, 1)))), 0.0625), 64)
        model.offset = .zero
    }

    private func pixel(at point: CGPoint) -> (x: Int, y: Int, rgba: [UInt8])? {
        let x = Int(safe: point.x.rounded(.down)), y = Int(safe: point.y.rounded(.down))
        guard x >= 0, y >= 0, x < model.image.width, y < model.image.height else { return nil }
        let at = (y * model.image.width + x) * 4
        guard at + 3 < model.image.rgba.count else { return nil }
        return (x, y, Array(model.image.rgba[at..<at + 4]))
    }

    private func drawOverlays(_ context: inout GraphicsContext, _ frame: CGRect, _ shown: CGImage?) {
        if repeatImage, let shown {
            let image = context.resolve(Image(decorative: shown, scale: 1).interpolation(model.zoom >= 2 ? .none : .medium))
            var faded = context
            faded.opacity = 0.55
            for row in -1...1 {
                for column in -1...1 where row != 0 || column != 0 {
                    faded.draw(image, in: frame.offsetBy(dx: CGFloat(column) * frame.width, dy: CGFloat(row) * frame.height))
                }
            }
        }
        if let uvModel, let root = app.document?.avfxRoot {
            let models = root.childrenNamed("Modl")
            guard uvModel < models.count else { return }
            let mesh = Gltf.mesh(from: models[uvModel])
            let uvs = mesh.uvs[0]
            var wires = Path()
            for t in stride(from: 0, to: mesh.indices.count - 2, by: 3) {
                let ids = [Int(mesh.indices[t]), Int(mesh.indices[t + 1]), Int(mesh.indices[t + 2])]
                guard ids.allSatisfy({ $0 < uvs.count }) else { continue }
                let points = ids.map { CGPoint(x: frame.minX + CGFloat(uvs[$0].x + 0.5) * frame.width, y: frame.minY + CGFloat(uvs[$0].y + 0.5) * frame.height) }
                wires.move(to: points[0])
                wires.addLine(to: points[1])
                wires.addLine(to: points[2])
                wires.closeSubpath()
            }
            context.stroke(wires, with: .color(Color.black.opacity(0.6)), lineWidth: 2)
            context.stroke(wires, with: .color(Color(red: 1, green: 0.63, blue: 0.16)), lineWidth: 1)
        }
    }

    private func imagePoint(_ location: CGPoint, in size: CGSize) -> CGPoint {
        let origin = CGPoint(x: size.width / 2 + model.offset.width - CGFloat(model.image.width) * model.zoom / 2,
                             y: size.height / 2 + model.offset.height - CGFloat(model.image.height) * model.zoom / 2)
        return CGPoint(x: (location.x - origin.x) / model.zoom, y: (location.y - origin.y) / model.zoom)
    }

    private var canvas: some View {
        GeometryReader { geometry in
            let size = geometry.size
            surface(size)
                .background(Theme.gray(0.2))
            .background(ScrollMonitor(
                onScroll: { delta, flags, point in
                    if flags.contains(.command) {
                        zoom(by: 1 + delta.height * 0.01, at: point, in: size)
                    } else {
                        model.offset.width += delta.width
                        model.offset.height += delta.height
                    }
                },
                onMagnify: { amount, point in zoom(by: 1 + amount, at: point, in: size) }))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .updating($pressing) { _, state, _ in state = true }
                .onChanged { drag in
                    hover = imagePoint(drag.location, in: size)
                    handle(drag, size)
                }
                .onEnded { _ in finish() })
            .onChange(of: pressing) { _, now in if !now { finish() } }
            .onContinuousHover { phase in
                if case .active(let point) = phase { hover = imagePoint(point, in: size) } else { hover = nil }
            }
            .onAppear { canvasSize = size }
            .onChange(of: size) { _, next in canvasSize = next }
        }
    }

    private func surface(_ size: CGSize) -> some View {
        let shown = model.display()
        let stamp = model.revision
        let zoom = model.zoom
        let offset = model.offset
        let selection = model.selection
        let extras = (repeatImage, uvModel)
        return Canvas { context, _ in
            _ = (stamp, zoom, offset, selection, extras.0, extras.1)
            draw(&context, size, shown)
        }
    }

    private func draw(_ context: inout GraphicsContext, _ size: CGSize, _ shown: CGImage?) {
        let width = CGFloat(model.image.width) * model.zoom, height = CGFloat(model.image.height) * model.zoom
        let frame = CGRect(x: size.width / 2 + model.offset.width - width / 2, y: size.height / 2 + model.offset.height - height / 2,
                           width: width, height: height)
        let cell: CGFloat = 8
        let firstRow = max(0, Int(safe: ((0 - frame.minY) / cell).rounded(.down))), firstColumn = max(0, Int(safe: ((0 - frame.minX) / cell).rounded(.down)))
        let bottom = min(frame.maxY, size.height), right = min(frame.maxX, size.width)
        var y = frame.minY + CGFloat(firstRow) * cell
        var row = firstRow
        while y < bottom {
            var x = frame.minX + CGFloat(firstColumn) * cell
            var column = firstColumn
            while x < right {
                let rect = CGRect(x: x, y: y, width: min(cell, frame.maxX - x), height: min(cell, frame.maxY - y))
                context.fill(Path(rect), with: .color(Color(white: (row + column) % 2 == 0 ? 0.4 : 0.6)))
                x += cell
                column += 1
            }
            y += cell
            row += 1
        }
        if let shown {
            context.draw(context.resolve(Image(decorative: shown, scale: 1).interpolation(model.zoom >= 2 ? .none : .medium)), in: frame)
        }
        drawOverlays(&context, frame, shown)
        context.stroke(Path(frame), with: .color(Color.black.opacity(0.8)), lineWidth: 1)
        if model.zoom >= 12 {
            var grid = Path()
            for i in 0...model.image.width {
                grid.move(to: CGPoint(x: frame.minX + CGFloat(i) * model.zoom, y: frame.minY))
                grid.addLine(to: CGPoint(x: frame.minX + CGFloat(i) * model.zoom, y: frame.maxY))
            }
            for i in 0...model.image.height {
                grid.move(to: CGPoint(x: frame.minX, y: frame.minY + CGFloat(i) * model.zoom))
                grid.addLine(to: CGPoint(x: frame.maxX, y: frame.minY + CGFloat(i) * model.zoom))
            }
            context.stroke(grid, with: .color(Color.black.opacity(0.25)), lineWidth: 0.5)
        }
        if let rect = model.selection {
            let box = CGRect(x: frame.minX + rect.minX * model.zoom, y: frame.minY + rect.minY * model.zoom, width: rect.width * model.zoom,
                             height: rect.height * model.zoom)
            context.stroke(Path(box), with: .color(.black), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            context.stroke(Path(box), with: .color(.white), style: StrokeStyle(lineWidth: 1, dash: [4, 4], dashPhase: 4))
        }
    }

    private func zoom(by factor: CGFloat, at point: CGPoint, in size: CGSize) {
        let before = imagePoint(point, in: size)
        model.zoom = min(max(model.zoom * Double(factor), 0.0625), 64)
        let after = imagePoint(point, in: size)
        model.offset.width += (after.x - before.x) * model.zoom
        model.offset.height += (after.y - before.y) * model.zoom
    }

    private func handle(_ drag: DragGesture.Value, _ size: CGSize) {
        let point = imagePoint(drag.location, in: size)
        let first = dragStart == nil
        if first { dragStart = imagePoint(drag.startLocation, in: size) }
        switch model.tool {
        case .pan:
            if panStart == nil { panStart = model.offset }
            if let start = panStart { model.offset = CGSize(width: start.width + drag.translation.width, height: start.height + drag.translation.height) }
        case .brush, .eraser:
            if first { model.checkpoint() }
            model.stroke(from: last ?? point, to: point, erase: model.tool == .eraser)
            last = point
        case .picker:
            model.pick(at: point)
        case .fill:
            if first { model.fill(at: point) }
        case .select:
            guard let start = dragStart else { return }
            let x0 = max(0, min(start.x, point.x).rounded(.down)), y0 = max(0, min(start.y, point.y).rounded(.down))
            let x1 = min(CGFloat(model.image.width), max(start.x, point.x).rounded(.up)), y1 = min(CGFloat(model.image.height), max(start.y, point.y).rounded(.up))
            model.selection = x1 - x0 >= 1 && y1 - y0 >= 1 ? CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0) : nil
        }
    }

    private func finish() {
        last = nil
        dragStart = nil
        panStart = nil
    }

    private func slider(_ label: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, step: Double, integer: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 70, alignment: .trailing)
            NumberField(label: nil, value: value.wrappedValue, isInteger: integer, step: step, digits: 2,
                        onLive: { value.wrappedValue = min(max($0, range.lowerBound), range.upperBound) },
                        onCommit: { _, next in value.wrappedValue = min(max(next, range.lowerBound), range.upperBound) })
        }
    }

    private var dock: some View {
        ScrollView {
            VStack(spacing: 6) {
                Panel(title: "View", memory: "texture.view") {
                    FlowLayout(spacing: 4) {
                        SegmentButton(title: "Fit", active: false) { fitView() }
                        SegmentButton(title: "1:1", active: false) {
                            model.zoom = 1
                            model.offset = .zero
                        }
                        SegmentButton(title: "Repeat", active: repeatImage) { repeatImage.toggle() }
                        HelpBadge(text: "Repeat draws the image tiled around itself, to check how its edges meet. UV shows where a model of the effect reads this texture.")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if modelCount > 0 {
                        FlowLayout(spacing: 4) {
                            Text("UV").font(Theme.small).foregroundStyle(Theme.dim).frame(height: 20)
                            SegmentButton(title: "None", active: uvModel == nil) { uvModel = nil }
                            ForEach(0..<modelCount, id: \.self) { index in
                                SegmentButton(title: "Model \(index)", active: uvModel == index) { uvModel = index }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Panel(title: "Tool Options", trailing: model.tool.rawValue) {
                    HStack(spacing: 8) {
                        Text("Colour").font(Theme.font).foregroundStyle(Theme.text).frame(width: 70, alignment: .trailing)
                        ColorField(color: model.color, alpha: true, onLive: { model.color = $0 }, onCommit: { _, next in model.color = next })
                    }
                    slider("Size", $model.size, 1...256, step: 0.25)
                    slider("Opacity", $model.opacity, 0...1, step: 0.01)
                    slider("Hardness", $model.hardness, 0...1, step: 0.01)
                    slider("Threshold", $model.tolerance, 0...255, step: 1, integer: true)
                }
                Panel(title: "Channels") {
                    ForEach(0..<4, id: \.self) { index in
                        CheckBox(isOn: model.channels[index], label: ["Red", "Green", "Blue", "Alpha"][index]) { model.channels[index] = $0 }
                    }
                    HStack {
                        SegmentButton(title: "RGBA", active: false) { model.channels = [true, true, true, true] }
                        SegmentButton(title: "RGB", active: false) { model.channels = [true, true, true, false] }
                        SegmentButton(title: "Alpha", active: false) { model.channels = [false, false, false, true] }
                        Spacer(minLength: 0)
                        HelpBadge(text: "Ticked channels are the ones shown and the only ones that painting, filling and colour adjustments change.")
                    }
                }
                Panel(title: "Brightness-Contrast") {
                    slider("Brightness", $model.brightness, -1...1, step: 0.01)
                    slider("Contrast", $model.contrast, -1...1, step: 0.01)
                    HStack {
                        Spacer()
                        SegmentButton(title: "Apply", active: model.brightness != 0 || model.contrast != 0) { model.applyBrightnessContrast() }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .background(Theme.panel)
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text("\(model.image.width) × \(model.image.height)").font(Theme.small).foregroundStyle(Theme.text)
            Text("\(Int(safe: (model.zoom * 100).rounded()))%").font(Theme.small).foregroundStyle(Theme.dim)
            if let rect = model.selection {
                Text("Selection \(Int(rect.minX)), \(Int(rect.minY))  \(Int(rect.width)) × \(Int(rect.height))").font(Theme.small).foregroundStyle(Theme.dim)
            }
            if let hover, let sample = pixel(at: hover) {
                HStack(spacing: 6) {
                    Text("X \(sample.x)  Y \(sample.y)").foregroundStyle(Theme.dim)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.sRGB, red: Double(sample.rgba[0]) / 255, green: Double(sample.rgba[1]) / 255, blue: Double(sample.rgba[2]) / 255, opacity: 1))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.6), lineWidth: 1))
                        .frame(width: 12, height: 12)
                    Text("R \(sample.rgba[0])  G \(sample.rgba[1])  B \(sample.rgba[2])  A \(sample.rgba[3])").foregroundStyle(Theme.text)
                    Text(String(format: "#%02X%02X%02X%02X", sample.rgba[0], sample.rgba[1], sample.rgba[2], sample.rgba[3])).foregroundStyle(Theme.dim)
                }
                .font(.system(size: 10, design: .monospaced))
            }
            if repeatImage { Text("Repeat").font(Theme.small).foregroundStyle(Theme.changed) }
            if let uvModel { Text("UV of Model \(uvModel)").font(Theme.small).foregroundStyle(Theme.changed) }
            Spacer()
            if model.canUndo { ChangeDot() }
        }
        .padding(.horizontal, 10)
        .frame(height: 20)
        .background(Theme.gray(0.094))
    }

    private func applyToEffect() {
        guard let block, let document = app.document else { return }
        guard model.loadedKey.hasPrefix("\(document.id)|"), block.stringValue == model.sourcePath, model.loadedTarget == app.textureEditorTarget else {
            app.errorMessage = "The texture list changed since this image was opened. Open the texture again from the Outliner before applying"
            return
        }
        do {
            let name = ((block.stringValue as NSString).lastPathComponent as NSString).deletingPathExtension
            let written = try app.writeTexture(Data(app.encodeTexture(model.image)), name: name, ext: "atex", for: block, in: document, title: "Edit Texture")
            app.notice = "Texture written to \(written.lastPathComponent)"
            model.loadedKey = "\(document.id)|\(app.textureEditorTarget ?? "")|\(block.stringValue)"
            model.sourcePath = block.stringValue
            model.appliedRevision = model.revision
        } catch {
            app.errorMessage = error.localizedDescription
        }
    }

    private func exportPNG() {
        guard let image = DecodedTexture(width: model.image.width, height: model.image.height, formatName: "", mipLevels: 1, alphaOnly: false, rgba: model.image.rgba).makeImage(),
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { return }
        let panel = NSSavePanel()
        panel.title = "Export PNG"
        panel.nameFieldStringValue = ((model.sourcePath as NSString).lastPathComponent as NSString).deletingPathExtension + ".png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: .atomic)
    }
}
