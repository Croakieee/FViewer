import SwiftUI
import simd

struct ModelCamera {
    var eye: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var forward: SIMD3<Float>
    var focal: Float
    var size: CGSize

    init(yaw: Float, pitch: Float, distance: Float, target: SIMD3<Float>, size: CGSize) {
        let offset = SIMD3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)) * distance
        eye = target + offset
        forward = simd_normalize(target - eye)
        var side = simd_cross(forward, SIMD3<Float>(0, 1, 0))
        if simd_length(side) < 1e-5 { side = SIMD3(1, 0, 0) }
        right = simd_normalize(side)
        up = simd_cross(right, forward)
        focal = Float(min(size.width, size.height)) / 2 / tan(0.75 / 2)
        self.size = size
    }

    func depth(_ point: SIMD3<Float>) -> Float { simd_dot(point - eye, forward) }

    func project(_ point: SIMD3<Float>) -> CGPoint? {
        let v = point - eye
        let z = simd_dot(v, forward)
        guard z > 0.01 else { return nil }
        return CGPoint(x: size.width / 2 + CGFloat(simd_dot(v, right) * focal / z), y: size.height / 2 - CGFloat(simd_dot(v, up) * focal / z))
    }
}

struct ModelViewport3D: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var session: ModelEditSession
    @State private var size = CGSize(width: 1, height: 1)
    @State private var mouse = CGPoint.zero
    @State private var dragStart: CGPoint?
    @State private var dragNow: CGPoint?
    @State private var dragMode = 0
    @State private var modal: ModelModal?
    @FocusState private var focused: Bool

    private static let selected = Color(red: 1, green: 0.55, blue: 0.1)
    private static let axisColors = [Color(red: 0.9, green: 0.3, blue: 0.3), Color(red: 0.5, green: 0.8, blue: 0.25), Color(red: 0.3, green: 0.5, blue: 0.95)]
    private static let axes = [SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 1, 0), SIMD3<Float>(0, 0, 1)]

    private var camera: ModelCamera { ModelCamera(yaw: session.yaw, pitch: session.pitch, distance: session.distance, target: session.target, size: size) }

    private func frame(selectedOnly: Bool) {
        guard let bounds = session.bounds(selectedOnly: selectedOnly) else {
            session.target = SIMD3(0, 0, 0)
            session.distance = 3
            return
        }
        session.target = (bounds.low + bounds.high) / 2
        let radius = max(simd_length(bounds.high - bounds.low) / 2, 0.02)
        session.distance = radius / tan(0.75 / 2) * 1.35
    }

    private func nearest(_ point: CGPoint) -> (vertex: Int?, emit: Int?) {
        let cam = camera
        var best: (distance: CGFloat, vertex: Int?, emit: Int?) = (10, nil, nil)
        for (index, position) in session.positions.enumerated() {
            guard let screen = cam.project(position) else { continue }
            let d = hypot(screen.x - point.x, screen.y - point.y)
            if d < best.distance { best = (d, index, nil) }
        }
        if session.showEmit {
            for (index, position) in session.emitPositions.enumerated() {
                guard let screen = cam.project(position) else { continue }
                let d = hypot(screen.x - point.x, screen.y - point.y)
                if d < best.distance { best = (d, nil, index) }
            }
        }
        return (best.vertex, best.emit)
    }

    private func faceAt(_ point: CGPoint) -> [Int]? {
        let cam = camera
        let positions = session.positions
        let screen = positions.map { cam.project($0) }
        let list = session.indices
        var best: (corners: [Int], depth: Float)?
        for t in stride(from: 0, to: list.count - 2, by: 3) {
            let ids = [list[t], list[t + 1], list[t + 2]]
            guard ids.allSatisfy({ $0 < screen.count }), let a = screen[ids[0]], let b = screen[ids[1]], let c = screen[ids[2]] else { continue }
            func side(_ p: CGPoint, _ q: CGPoint) -> CGFloat { (q.x - p.x) * (point.y - p.y) - (q.y - p.y) * (point.x - p.x) }
            let s0 = side(a, b), s1 = side(b, c), s2 = side(c, a)
            guard (s0 >= 0 && s1 >= 0 && s2 >= 0) || (s0 <= 0 && s1 <= 0 && s2 <= 0) else { continue }
            let depth = (cam.depth(positions[ids[0]]) + cam.depth(positions[ids[1]]) + cam.depth(positions[ids[2]])) / 3
            if depth < (best?.depth ?? .infinity) { best = (ids, depth) }
        }
        return best?.corners
    }

    private func edgeAt(_ point: CGPoint) -> (a: Int, b: Int)? {
        let cam = camera
        let screen = session.positions.map { cam.project($0) }
        var best: (edge: (a: Int, b: Int), distance: CGFloat)?
        for edge in session.meshEdges() {
            guard edge.a < screen.count, edge.b < screen.count, let a = screen[edge.a], let b = screen[edge.b] else { continue }
            let dx = b.x - a.x, dy = b.y - a.y
            let length = dx * dx + dy * dy
            let t = length > 0 ? min(max(((point.x - a.x) * dx + (point.y - a.y) * dy) / length, 0), 1) : 0
            let d = hypot(point.x - (a.x + dx * t), point.y - (a.y + dy * t))
            if d < 8, d < (best?.distance ?? .infinity) { best = (edge, d) }
        }
        return best?.edge
    }

    private func click(_ point: CGPoint, extend: Bool) {
        if session.selectMode == 1 {
            if let edge = edgeAt(point) {
                let both = session.selection.contains(edge.a) && session.selection.contains(edge.b)
                if extend {
                    if both {
                        session.selection.remove(edge.a)
                        session.selection.remove(edge.b)
                    } else {
                        session.selection.insert(edge.a)
                        session.selection.insert(edge.b)
                    }
                } else {
                    session.selection = [edge.a, edge.b]
                    session.emitSelection = []
                }
            } else if !extend {
                session.selectNone()
            }
            return
        }
        if session.faceMode {
            if let corners = faceAt(point) {
                let all = corners.allSatisfy { session.selection.contains($0) }
                if extend {
                    if all { corners.forEach { session.selection.remove($0) } } else { corners.forEach { session.selection.insert($0) } }
                } else {
                    session.selection = Set(corners)
                    session.emitSelection = []
                }
            } else if !extend {
                session.selectNone()
            }
            return
        }
        let hit = nearest(point)
        if let vertex = hit.vertex {
            if extend {
                if session.selection.contains(vertex) { session.selection.remove(vertex) } else { session.selection.insert(vertex) }
            } else {
                session.selection = [vertex]
                session.emitSelection = []
            }
        } else if let emit = hit.emit {
            if extend {
                if session.emitSelection.contains(emit) { session.emitSelection.remove(emit) } else { session.emitSelection.insert(emit) }
            } else {
                session.emitSelection = [emit]
                session.selection = []
            }
        } else if !extend {
            session.selectNone()
        }
    }

    private func boxSelect(_ a: CGPoint, _ b: CGPoint, extend: Bool) {
        let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        let cam = camera
        var vertices: Set<Int> = extend ? session.selection : []
        var points: Set<Int> = extend ? session.emitSelection : []
        for (index, position) in session.positions.enumerated() {
            if let screen = cam.project(position), rect.contains(screen) { vertices.insert(index) }
        }
        if session.showEmit {
            for (index, position) in session.emitPositions.enumerated() {
                if let screen = cam.project(position), rect.contains(screen) { points.insert(index) }
            }
        }
        session.selection = vertices
        session.emitSelection = points
    }

    private func begin(_ kind: Character) {
        guard modal == nil, !(session.selection.isEmpty && session.emitSelection.isEmpty) else { return }
        modal = ModelModal(kind: kind, start: mouse, before: session.capture(), axis: nil)
        session.status = hint(kind, nil)
        session.modalConfirm = { confirm() }
        session.modalOwner = "3d"
    }

    private func hint(_ kind: Character, _ axis: Int?) -> String {
        let name = kind == "g" ? "Move" : kind == "s" ? "Scale" : "Rotate"
        let along = axis.map { " along " + ["X", "Y", "Z"][$0] } ?? ""
        return name + along + " · X / Y / Z constrain · click or Return confirms · Esc cancels"
    }

    private func applyModal() {
        guard let modal else { return }
        session.restore(modal.before)
        let cam = camera
        let origins = session.positions(in: modal.before.draw), emitOrigins = session.emitPositions(in: modal.before.emit)
        let picked = session.selection.filter { $0 < origins.count }.map { origins[$0] } + session.emitSelection.filter { $0 < emitOrigins.count }.map { emitOrigins[$0] }
        guard !picked.isEmpty else { return }
        let pivot = picked.reduce(SIMD3<Float>(0, 0, 0), +) / Float(picked.count)
        let pivotScreen = cam.project(pivot) ?? CGPoint(x: size.width / 2, y: size.height / 2)
        var transform: (SIMD3<Float>) -> SIMD3<Float> = { $0 }
        var turnNormal: ((SIMD3<Float>) -> SIMD3<Float>)?
        var turnTangent: ((SIMD3<Float>) -> SIMD3<Float>)?
        func unit(_ value: SIMD3<Float>, _ fallback: SIMD3<Float>) -> SIMD3<Float> {
            let length = simd_length(value)
            return length > 1e-6 && length.isFinite ? value / length : fallback
        }
        switch modal.kind {
        case "g":
            let scale = max(cam.depth(pivot), 0.01) / cam.focal
            var delta = cam.right * Float(mouse.x - modal.start.x) * scale - cam.up * Float(mouse.y - modal.start.y) * scale
            if let axis = modal.axis { delta = ModelViewport3D.axes[axis] * simd_dot(delta, ModelViewport3D.axes[axis]) }
            transform = { $0 + delta }
        case "s":
            let base = max(hypot(modal.start.x - pivotScreen.x, modal.start.y - pivotScreen.y), 1)
            let factor = Float(hypot(mouse.x - pivotScreen.x, mouse.y - pivotScreen.y) / base)
            var scale = SIMD3<Float>(repeating: factor)
            if let axis = modal.axis {
                scale = SIMD3(1, 1, 1)
                scale[axis] = factor
            }
            transform = { pivot + ($0 - pivot) * scale }
            if modal.axis != nil, scale.x > 1e-4, scale.y > 1e-4, scale.z > 1e-4 {
                turnNormal = { unit($0 / scale, $0) }
                turnTangent = { unit($0 * scale, $0) }
            }
        default:
            let from = atan2(modal.start.y - pivotScreen.y, modal.start.x - pivotScreen.x)
            let to = atan2(mouse.y - pivotScreen.y, mouse.x - pivotScreen.x)
            let axis = modal.axis.map { ModelViewport3D.axes[$0] } ?? cam.forward
            let rotation = simd_quatf(angle: Float(to - from), axis: axis)
            transform = { pivot + rotation.act($0 - pivot) }
            turnNormal = { rotation.act($0) }
            turnTangent = { rotation.act($0) }
        }
        for index in session.selection where index < origins.count {
            session.setPosition(index, transform(origins[index]))
            if let turnNormal { session.setNormal(index, turnNormal(session.normal(index))) }
            if let turnTangent { session.setTangent(index, turnTangent(session.tangent(index))) }
        }
        for index in session.emitSelection where index < emitOrigins.count {
            session.setEmitPosition(index, transform(emitOrigins[index]))
            if let turnNormal { session.setEmitNormal(index, turnNormal(session.emitNormal(index))) }
        }
        document.liveDrag()
    }

    private func confirm() {
        guard let modal else { return }
        let title = modal.kind == "g" ? "Move Vertices" : modal.kind == "s" ? "Scale Vertices" : "Rotate Vertices"
        session.commit(title, from: modal.before)
        self.modal = nil
        session.status = ""
        session.modalOwner = nil
        session.modalConfirm = nil
    }

    private func cancel() {
        guard let modal else { return }
        session.cancel(modal.before)
        self.modal = nil
        session.status = ""
        session.modalOwner = nil
        session.modalConfirm = nil
    }

    private func drawGrid(_ context: inout GraphicsContext, _ cam: ModelCamera) {
        let step: Float = session.distance > 20 ? 5 : session.distance > 4 ? 1 : session.distance > 0.8 ? 0.25 : 0.05
        let count = 12
        let extent = step * Float(count)
        var lines = Path()
        for i in -count...count {
            let offset = Float(i) * step
            if i != 0 {
                if let a = cam.project(SIMD3(offset, 0, -extent)), let b = cam.project(SIMD3(offset, 0, extent)) {
                    lines.move(to: a)
                    lines.addLine(to: b)
                }
                if let a = cam.project(SIMD3(-extent, 0, offset)), let b = cam.project(SIMD3(extent, 0, offset)) {
                    lines.move(to: a)
                    lines.addLine(to: b)
                }
            }
        }
        context.stroke(lines, with: .color(Color.white.opacity(0.07)), lineWidth: 1)
        for (axis, color) in [(0, ModelViewport3D.axisColors[0]), (2, ModelViewport3D.axisColors[2])] {
            let direction = ModelViewport3D.axes[axis] * extent
            if let a = cam.project(-direction), let b = cam.project(direction) {
                var line = Path()
                line.move(to: a)
                line.addLine(to: b)
                context.stroke(line, with: .color(color.opacity(0.55)), lineWidth: 1)
            }
        }
    }

    private func drawMesh(_ context: inout GraphicsContext, _ cam: ModelCamera) {
        let positions = session.positions
        let screen = positions.map { cam.project($0) }
        let list = session.indices
        var wires = Path()
        var fills = Path()
        for t in stride(from: 0, to: list.count - 2, by: 3) {
            guard list[t] < screen.count, list[t + 1] < screen.count, list[t + 2] < screen.count,
                  let a = screen[list[t]], let b = screen[list[t + 1]], let c = screen[list[t + 2]] else { continue }
            var triangle = Path()
            triangle.move(to: a)
            triangle.addLine(to: b)
            triangle.addLine(to: c)
            triangle.closeSubpath()
            wires.addPath(triangle)
            if session.showFaces {
                if session.showColors {
                    let mix = (session.color(list[t]) + session.color(list[t + 1]) + session.color(list[t + 2])) / 3
                    context.fill(triangle, with: .color(Color(.sRGB, red: mix.x, green: mix.y, blue: mix.z, opacity: 0.25 + mix.w * 0.6)))
                } else {
                    fills.addPath(triangle)
                }
            }
        }
        if session.showFaces, !session.showColors { context.fill(fills, with: .color(Color.white.opacity(0.07))) }
        var chosen = Path()
        for t in session.selectedFaces() {
            guard let a = screen[list[t]], let b = screen[list[t + 1]], let c = screen[list[t + 2]] else { continue }
            chosen.move(to: a)
            chosen.addLine(to: b)
            chosen.addLine(to: c)
            chosen.closeSubpath()
        }
        context.fill(chosen, with: .color(ModelViewport3D.selected.opacity(0.28)))
        if !session.selection.isEmpty {
            var lit = Path()
            for edge in session.meshEdges() where session.selection.contains(edge.a) && session.selection.contains(edge.b) {
                guard edge.a < screen.count, edge.b < screen.count, let a = screen[edge.a], let b = screen[edge.b] else { continue }
                lit.move(to: a)
                lit.addLine(to: b)
            }
            context.stroke(lit, with: .color(ModelViewport3D.selected), lineWidth: 1.6)
        }
        context.stroke(wires, with: .color(Color(white: 0.62).opacity(0.85)), lineWidth: 0.8)
        if session.showNormals, let bounds = session.bounds(selectedOnly: false) {
            let length = max(simd_length(bounds.high - bounds.low) * 0.04, 0.005)
            var normals = Path()
            for (index, position) in positions.enumerated() {
                guard let a = screen[index], let b = cam.project(position + session.normal(index) * length) else { continue }
                normals.move(to: a)
                normals.addLine(to: b)
            }
            context.stroke(normals, with: .color(Color(red: 0.3, green: 0.85, blue: 0.9).opacity(0.8)), lineWidth: 1)
        }
        var plain = Path()
        var picked = Path()
        for (index, point) in screen.enumerated() {
            guard let point else { continue }
            if session.selection.contains(index) {
                picked.addEllipse(in: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6))
            } else {
                plain.addEllipse(in: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
            }
        }
        context.fill(plain, with: .color(Color(white: 0.08)))
        context.stroke(plain, with: .color(Color(white: 0.7)), lineWidth: 0.6)
        context.fill(picked, with: .color(ModelViewport3D.selected))
    }

    private func drawEmit(_ context: inout GraphicsContext, _ cam: ModelCamera) {
        guard session.showEmit else { return }
        let points = session.emitPositions
        guard !points.isEmpty else { return }
        let reach = max((session.bounds(selectedOnly: false).map { simd_length($0.high - $0.low) } ?? 1) * 0.05, 0.01)
        for (index, position) in points.enumerated() {
            guard let a = cam.project(position) else { continue }
            let chosen = session.emitSelection.contains(index)
            let color = chosen ? ModelViewport3D.selected : Color(red: 0.25, green: 0.85, blue: 0.7)
            let normal = session.emitNormal(index)
            if simd_length(normal) > 1e-6, let b = cam.project(position + simd_normalize(normal) * reach) {
                var line = Path()
                line.move(to: a)
                line.addLine(to: b)
                context.stroke(line, with: .color(color.opacity(0.8)), lineWidth: 1)
            }
            var diamond = Path()
            let r: CGFloat = chosen ? 5 : 4
            diamond.move(to: CGPoint(x: a.x, y: a.y - r))
            diamond.addLine(to: CGPoint(x: a.x + r, y: a.y))
            diamond.addLine(to: CGPoint(x: a.x, y: a.y + r))
            diamond.addLine(to: CGPoint(x: a.x - r, y: a.y))
            diamond.closeSubpath()
            context.fill(diamond, with: .color(color))
        }
    }

    private func drawOverlay(_ context: inout GraphicsContext, _ cam: ModelCamera) {
        if let modal, let axis = modal.axis, let pivot = session.selectionCenter {
            let direction = ModelViewport3D.axes[axis] * session.distance * 4
            if let a = cam.project(pivot - direction), let b = cam.project(pivot + direction) {
                var line = Path()
                line.move(to: a)
                line.addLine(to: b)
                context.stroke(line, with: .color(ModelViewport3D.axisColors[axis]), lineWidth: 1)
            }
        }
        if dragMode == 1, let a = dragStart, let b = dragNow {
            let rect = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
            context.fill(Path(rect), with: .color(Color.white.opacity(0.06)))
            context.stroke(Path(rect), with: .color(Color.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        let corner = CGPoint(x: 34, y: size.height - 34)
        for axis in 0..<3 {
            let direction = ModelViewport3D.axes[axis]
            let tip = CGPoint(x: corner.x + CGFloat(simd_dot(direction, cam.right)) * 22, y: corner.y - CGFloat(simd_dot(direction, cam.up)) * 22)
            var line = Path()
            line.move(to: corner)
            line.addLine(to: tip)
            context.stroke(line, with: .color(ModelViewport3D.axisColors[axis]), lineWidth: 1.5)
            context.draw(Text(["X", "Y", "Z"][axis]).font(.system(size: 9, weight: .bold)).foregroundColor(ModelViewport3D.axisColors[axis]),
                         at: CGPoint(x: corner.x + (tip.x - corner.x) * 1.35, y: corner.y + (tip.y - corner.y) * 1.35))
        }
    }

    private func key(_ press: KeyPress) -> KeyPress.Result {
        let typed = AppShortcuts.canonical(press.characters)
        switch typed {
        case "g", "s", "r":
            begin(Character(typed))
        case "\u{7f}", "\u{8}":
            if session.faceMode { session.deleteSelectedFaces() } else { session.deleteSelectedVertices() }
        case "e":
            if session.extrudeSelection() { begin("g") }
        case "f":
            session.fillFace()
        case "m":
            session.mergeSelection()
        case "D":
            session.duplicateSelection()
            begin("g")
        case "x", "y", "z":
            if modal == nil, typed == "x" {
                if session.faceMode { session.deleteSelectedFaces() } else { session.deleteSelectedVertices() }
                return .handled
            }
            guard var active = modal else { return .ignored }
            let axis = ["x", "y", "z"].firstIndex(of: typed) ?? 0
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
            if press.modifiers.contains(.option) { session.selectNone() } else { session.selectAll() }
        case "l":
            session.selectLinked()
        case ".":
            frame(selectedOnly: true)
        case "\u{F729}":
            frame(selectedOnly: false)
        case "1":
            session.yaw = 0
            session.pitch = 0
        case "3":
            session.yaw = .pi / 2
            session.pitch = 0
        case "7":
            session.yaw = 0
            session.pitch = 1.55
        default:
            return .ignored
        }
        return .handled
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
            session.yaw -= Float(value.location.x - (dragNow ?? value.startLocation).x) * 0.008
            session.pitch = min(max(session.pitch + Float(value.location.y - (dragNow ?? value.startLocation).y) * 0.008, -1.55), 1.55)
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
            session.distance = min(max(session.distance * Float(1 - delta.height * 0.005), 0.02), 500)
        } else if flags.contains(.shift) {
            let cam = camera
            let scale = session.distance / cam.focal
            session.target += -cam.right * Float(delta.width) * scale + cam.up * Float(delta.height) * scale
        } else {
            session.yaw -= Float(delta.width) * 0.008
            session.pitch = min(max(session.pitch + Float(delta.height) * 0.008, -1.55), 1.55)
        }
    }

    private func magnified(_ amount: CGFloat, _ point: CGPoint) {
        session.distance = min(max(session.distance * Float(1 - amount), 0.02), 500)
    }

    var body: some View {
        let revision = document.revision
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("3D Viewport").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text).fixedSize()
                HStack(spacing: 1) {
                    HeaderButton(symbol: "smallcircle.filled.circle.fill", active: session.selectMode == 0, help: "Vertex select: click picks a vertex") { session.selectMode = 0 }
                    HeaderButton(symbol: "line.diagonal", active: session.selectMode == 1, help: "Edge select: click picks an edge") { session.selectMode = 1 }
                    HeaderButton(symbol: "triangle.fill", active: session.selectMode == 2, help: "Face select: click picks a triangle") { session.selectMode = 2 }
                }
                Spacer()
                HeaderButton(symbol: "square.on.square.dashed", active: session.showFaces, help: "Faces") { session.showFaces.toggle() }
                HeaderButton(symbol: "paintpalette", active: session.showColors, help: "Vertex colours on faces") { session.showColors.toggle() }
                HeaderButton(symbol: "arrow.up.right", active: session.showNormals, help: "Vertex normals") { session.showNormals.toggle() }
                HeaderButton(symbol: "smallcircle.filled.circle", active: session.showEmit, help: "Emit points") { session.showEmit.toggle() }
                HeaderButton(symbol: "scope", help: "Frame Selected (.)") { frame(selectedOnly: true) }
                HelpBadge(text: "Click: select · Shift-click: add · Drag: box select\nG move · S scale · R rotate, then X / Y / Z to constrain\nX or Delete: delete · E extrude · F fill a face from 3 or 4 vertices · M merge · Shift-D duplicate\nA all · ⌥A none · L linked · . frame selected\nScroll or ⌥-drag: orbit · Shift-scroll: pan · Pinch or ⌘-scroll: zoom · 1 3 7 views")
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            GeometryReader { geometry in
                Canvas { context, canvasSize in
                    _ = revision
                    let cam = ModelCamera(yaw: session.yaw, pitch: session.pitch, distance: session.distance, target: session.target, size: canvasSize)
                    drawGrid(&context, cam)
                    drawMesh(&context, cam)
                    drawEmit(&context, cam)
                    drawOverlay(&context, cam)
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
                .onAppear { size = geometry.size }
                .onChange(of: geometry.size) { _, next in size = next }
            }
            .clipped()
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress { key($0) }
        .onDisappear { cancel() }
        .onAppear {
            if !session.framed3D {
                session.framed3D = true
                frame(selectedOnly: false)
            }
        }
    }
}
