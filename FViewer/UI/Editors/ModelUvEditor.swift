import SwiftUI
import simd

struct ModelUvEditor: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @ObservedObject var session: ModelEditSession
    private var scale: CGFloat { session.uvScale }
    private var origin: CGPoint { session.uvOrigin }
    @State private var size = CGSize(width: 1, height: 1)
    @State private var mouse = CGPoint.zero
    @State private var dragStart: CGPoint?
    @State private var dragNow: CGPoint?
    @State private var dragMode = 0
    @State private var modal: ModelModal?
    @FocusState private var focused: Bool

    private static let selected = Color(red: 1, green: 0.55, blue: 0.1)

    private func screen(_ uv: SIMD2<Float>) -> CGPoint { CGPoint(x: origin.x + CGFloat(uv.x) * scale, y: origin.y + CGFloat(uv.y) * scale) }
    private func uv(_ point: CGPoint) -> SIMD2<Float> { SIMD2(Float((point.x - origin.x) / scale), Float((point.y - origin.y) / scale)) }

    private func frame(selectedOnly: Bool) {
        let all = session.currentUVs
        var picked = selectedOnly && !session.selection.isEmpty ? session.selection.filter { $0 < all.count }.map { all[$0] } : all
        if !selectedOnly || picked.isEmpty { picked += [SIMD2(0, 0), SIMD2(1, 1)] }
        let low = picked.reduce(picked[0]) { simd_min($0, $1) }, high = picked.reduce(picked[0]) { simd_max($0, $1) }
        let extent = max(CGFloat(max(high.x - low.x, high.y - low.y)), 0.02)
        let room = max(min(size.width, size.height) - 48, 40)
        session.uvScale = room / extent
        session.uvOrigin = CGPoint(x: (size.width - CGFloat(high.x + low.x) * scale) / 2, y: (size.height - CGFloat(high.y + low.y) * scale) / 2)
    }

    private func nearest(_ point: CGPoint) -> Int? {
        var best: (distance: CGFloat, index: Int?) = (10, nil)
        for (index, value) in session.currentUVs.enumerated() {
            let p = screen(value)
            let d = hypot(p.x - point.x, p.y - point.y)
            if d < best.distance { best = (d, index) }
        }
        return best.index
    }

    private func click(_ point: CGPoint, extend: Bool) {
        guard let hit = nearest(point) else {
            if !extend { session.selectNone() }
            return
        }
        let all = session.currentUVs
        let stacked = Set(all.indices.filter { simd_distance(all[$0], all[hit]) < 1e-5 })
        if extend {
            if session.selection.contains(hit) { session.selection.subtract(stacked) } else { session.selection.formUnion(stacked) }
        } else {
            session.selection = stacked
            session.emitSelection = []
        }
    }

    private func boxSelect(_ a: CGPoint, _ b: CGPoint, extend: Bool) {
        let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        var picked: Set<Int> = extend ? session.selection : []
        for (index, value) in session.currentUVs.enumerated() where rect.contains(screen(value)) { picked.insert(index) }
        session.selection = picked
        if !extend { session.emitSelection = [] }
    }

    private func hint(_ kind: Character, _ axis: Int?) -> String {
        let name = kind == "g" ? "Move UVs" : kind == "s" ? "Scale UVs" : "Rotate UVs"
        let along = axis.map { " along " + ["U", "V"][$0] } ?? ""
        return name + along + " · X / Y constrain · click or Return confirms · Esc cancels"
    }

    private func begin(_ kind: Character) {
        guard modal == nil, !session.selection.isEmpty else { return }
        modal = ModelModal(kind: kind, start: mouse, before: session.capture(), axis: nil)
        session.status = hint(kind, nil)
    }

    private func applyModal() {
        guard let modal else { return }
        session.restore(modal.before)
        let origins = session.uvs(in: modal.before.draw, set: session.uvSet)
        let picked = session.selection.filter { $0 < origins.count }
        guard !picked.isEmpty else { return }
        let pivot = picked.map { origins[$0] }.reduce(SIMD2<Float>(0, 0), +) / Float(picked.count)
        let pivotScreen = screen(pivot)
        var transform: (SIMD2<Float>) -> SIMD2<Float> = { $0 }
        switch modal.kind {
        case "g":
            var delta = SIMD2(Float((mouse.x - modal.start.x) / scale), Float((mouse.y - modal.start.y) / scale))
            if modal.axis == 0 { delta.y = 0 }
            if modal.axis == 1 { delta.x = 0 }
            transform = { $0 + delta }
        case "s":
            let base = max(hypot(modal.start.x - pivotScreen.x, modal.start.y - pivotScreen.y), 1)
            let factor = Float(hypot(mouse.x - pivotScreen.x, mouse.y - pivotScreen.y) / base)
            let amount = SIMD2<Float>(modal.axis == 1 ? 1 : factor, modal.axis == 0 ? 1 : factor)
            transform = { pivot + ($0 - pivot) * amount }
        default:
            let angle = Float(atan2(mouse.y - pivotScreen.y, mouse.x - pivotScreen.x) - atan2(modal.start.y - pivotScreen.y, modal.start.x - pivotScreen.x))
            let c = cos(angle), s = sin(angle)
            transform = { value in
                let d = value - pivot
                return pivot + SIMD2(d.x * c - d.y * s, d.x * s + d.y * c)
            }
        }
        for index in picked { session.setUV(index, transform(origins[index])) }
        document.liveDrag()
    }

    private func confirm() {
        guard let modal else { return }
        session.commit(modal.kind == "g" ? "Move UVs" : modal.kind == "s" ? "Scale UVs" : "Rotate UVs", from: modal.before)
        self.modal = nil
        session.status = ""
    }

    private func cancel() {
        guard let modal else { return }
        session.cancel(modal.before)
        self.modal = nil
        session.status = ""
    }

    private func drawGrid(_ context: inout GraphicsContext, _ canvas: CGSize) {
        let first = uv(.zero), last = uv(CGPoint(x: canvas.width, y: canvas.height))
        let step: Float = scale > 900 ? 0.0625 : scale > 220 ? 0.125 : scale > 60 ? 0.25 : 1
        var fine = Path()
        var tiles = Path()
        var value = (first.x / step).rounded(.down) * step
        while value <= last.x {
            let x = origin.x + CGFloat(value) * scale
            if abs(value.rounded() - value) < 1e-4 {
                tiles.move(to: CGPoint(x: x, y: 0))
                tiles.addLine(to: CGPoint(x: x, y: canvas.height))
            } else {
                fine.move(to: CGPoint(x: x, y: 0))
                fine.addLine(to: CGPoint(x: x, y: canvas.height))
            }
            value += step
            if value > first.x + 400 * step { break }
        }
        value = (first.y / step).rounded(.down) * step
        while value <= last.y {
            let y = origin.y + CGFloat(value) * scale
            if abs(value.rounded() - value) < 1e-4 {
                tiles.move(to: CGPoint(x: 0, y: y))
                tiles.addLine(to: CGPoint(x: canvas.width, y: y))
            } else {
                fine.move(to: CGPoint(x: 0, y: y))
                fine.addLine(to: CGPoint(x: canvas.width, y: y))
            }
            value += step
            if value > first.y + 400 * step { break }
        }
        context.stroke(fine, with: .color(Color.white.opacity(0.05)), lineWidth: 1)
        context.stroke(tiles, with: .color(Color.white.opacity(0.14)), lineWidth: 1)
    }

    private func drawContent(_ context: inout GraphicsContext, _ canvas: CGSize) {
        let unit = CGRect(x: origin.x, y: origin.y, width: scale, height: scale)
        context.fill(Path(unit), with: .color(Color.black.opacity(0.22)))
        if !session.texturePath.isEmpty, let image = app.image(for: session.texturePath) {
            context.draw(Image(decorative: image, scale: 1), in: unit)
        }
        drawGrid(&context, canvas)
        context.stroke(Path(unit), with: .color(Color.white.opacity(0.45)), lineWidth: 1)
        let points = session.currentUVs.map { screen($0) }
        let list = session.indices
        var wires = Path()
        for t in stride(from: 0, to: list.count - 2, by: 3) {
            guard list[t] < points.count, list[t + 1] < points.count, list[t + 2] < points.count else { continue }
            wires.move(to: points[list[t]])
            wires.addLine(to: points[list[t + 1]])
            wires.addLine(to: points[list[t + 2]])
            wires.closeSubpath()
        }
        context.fill(wires, with: .color(Color.white.opacity(0.05)))
        context.stroke(wires, with: .color(Color(white: 0.78).opacity(0.9)), lineWidth: 0.8)
        var plain = Path()
        var picked = Path()
        for (index, point) in points.enumerated() {
            if session.selection.contains(index) {
                picked.addEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
            } else {
                plain.addEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
            }
        }
        context.fill(plain, with: .color(Color(white: 0.08)))
        context.stroke(plain, with: .color(Color(white: 0.75)), lineWidth: 0.6)
        context.fill(picked, with: .color(ModelUvEditor.selected))
        if dragMode == 1, let a = dragStart, let b = dragNow {
            let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
            context.fill(Path(rect), with: .color(Color.white.opacity(0.06)))
            context.stroke(Path(rect), with: .color(Color.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        let cursor = uv(mouse)
        context.draw(Text(String(format: "U %.3f  V %.3f", cursor.x, cursor.y)).font(Theme.small).foregroundColor(Theme.dim),
                     at: CGPoint(x: 8, y: canvas.height - 10), anchor: .leading)
    }

    private func key(_ press: KeyPress) -> KeyPress.Result {
        switch press.characters {
        case "g", "s", "r":
            begin(Character(press.characters))
        case "x", "y":
            guard var active = modal else { return .ignored }
            let axis = press.characters == "x" ? 0 : 1
            active.axis = active.axis == axis ? nil : axis
            modal = active
            session.status = hint(active.kind, active.axis)
            applyModal()
        case "\r", " ":
            guard modal != nil else { return .ignored }
            confirm()
        case "\u{1b}":
            if modal != nil { cancel() } else { session.selectNone() }
        case "a":
            if press.modifiers.contains(.option) { session.selectNone() } else { session.selection = Set(0..<session.vertexCount) }
        case "l":
            session.selectLinked()
        case ".":
            frame(selectedOnly: true)
        case "\u{F729}":
            frame(selectedOnly: false)
        default:
            return .ignored
        }
        return .handled
    }

    private var textureMenu: some View {
        Menu {
            Button("None") { session.texturePath = "" }
            ForEach(document.textureSlots) { slot in
                Button(slot.name + " · " + (slot.path.split(separator: "/").last.map(String.init) ?? slot.path)) { session.texturePath = slot.path }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "photo").font(.system(size: 10))
                Text(session.texturePath.isEmpty ? "Image" : (session.texturePath.split(separator: "/").last.map(String.init) ?? "Image"))
                    .font(Theme.small).lineLimit(1)
            }
            .foregroundStyle(Theme.text)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Texture shown behind the UVs")
    }

    private func dragChanged(_ value: DragGesture.Value) {
        focused = true
        mouse = value.location
        if modal != nil {
            applyModal()
            return
        }
        if dragStart == nil {
            dragStart = value.startLocation
            dragMode = NSEvent.modifierFlags.contains(.option) ? 2 : 0
        }
        if dragMode == 2 {
            let last = dragNow ?? value.startLocation
            session.uvOrigin = CGPoint(x: origin.x + value.location.x - last.x, y: origin.y + value.location.y - last.y)
        } else if dragMode == 0, hypot(value.translation.width, value.translation.height) > 4 {
            dragMode = 1
        }
        dragNow = value.location
    }

    private func dragEnded(_ value: DragGesture.Value) {
        let extend = NSEvent.modifierFlags.contains(.shift)
        if modal != nil {
            confirm()
        } else if dragMode == 1, let start = dragStart {
            boxSelect(start, value.location, extend: extend)
        } else if dragMode == 0 {
            click(value.location, extend: extend)
        }
        dragStart = nil
        dragNow = nil
        dragMode = 0
    }

    private func scrolled(_ delta: CGSize, _ flags: NSEvent.ModifierFlags, _ point: CGPoint) {
        if flags.contains(.command) || flags.contains(.control) {
            zoom(1 + delta.height * 0.005, at: point)
        } else {
            session.uvOrigin = CGPoint(x: origin.x + delta.width, y: origin.y + delta.height)
        }
    }

    private func magnified(_ amount: CGFloat, _ point: CGPoint) {
        zoom(1 + amount, at: point)
    }

    var body: some View {
        let revision = document.revision
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("UV Editor").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text).fixedSize()
                Text("UV Map").font(Theme.small).foregroundStyle(Theme.dim).fixedSize()
                HStack(spacing: 1) {
                    ForEach(0..<4, id: \.self) { index in
                        SegmentButton(title: "\(index + 1)", active: session.uvSet == index) {
                            session.uvSet = index
                            frame(selectedOnly: false)
                        }
                    }
                }
                textureMenu
                Spacer()
                HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Frame All (Home)") { frame(selectedOnly: false) }
                HelpBadge(text: "Click: select · Shift-click: add · Drag: box select\nG move · S scale · R rotate, then X / Y to constrain\nA all · ⌥A none · L linked · . frame selected · Home frame all\nScroll or ⌥-drag: pan · Pinch or ⌘-scroll: zoom\nThe selection is shared with the 3D viewport.")
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            GeometryReader { geometry in
                Canvas { context, canvasSize in
                    _ = revision
                    drawContent(&context, canvasSize)
                }
                .background(Theme.gray(0.2))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { dragChanged($0) }.onEnded { dragEnded($0) })
                .onContinuousHover { phase in
                    if case .active(let point) = phase {
                        mouse = point
                        if !focused { focused = true }
                        if modal != nil { applyModal() }
                    }
                }
                .background(ScrollMonitor(onScroll: { scrolled($0, $1, $2) }, onMagnify: { magnified($0, $1) }))
                .onAppear {
                    size = geometry.size
                    reframeIfNeeded()
                }
                .onChange(of: geometry.size) { _, next in
                    size = next
                    reframeIfNeeded()
                }
            }
            .clipped()
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress { key($0) }
    }

    private func reframeIfNeeded() {
        let key = "\(session.uvSet)"
        guard key != session.framedUV, size.width > 10 else { return }
        session.framedUV = key
        frame(selectedOnly: false)
    }

    private func zoom(_ factor: CGFloat, at point: CGPoint) {
        let next = min(max(scale * factor, 8), 40000)
        let ratio = next / scale
        session.uvOrigin = CGPoint(x: point.x - (point.x - origin.x) * ratio, y: point.y - (point.y - origin.y) * ratio)
        session.uvScale = next
    }
}
