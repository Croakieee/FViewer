import AppKit
import simd

struct GizmoHandle {
    var index: Int
    var kind: Int
    var axis: Int
    var points: [Vec3]
    var color: SIMD4<Float>
}

final class GizmoState {
    var handles: [GizmoHandle] = []
    var rootID: String?
    var origin = Vec3.zero
    var basis = simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
    var unit = Vec3(1, 1, 1)
    var size: Float = 1
    var radiusModel: Mat4?
    var radiusLocal = Vec3.zero
    var radiusTags: [String] = []
    var radiusMode = 0
    var radiusScale = 1.0
    var lengthModel: Mat4?
    var shapeType = 0
    var active: (index: Int, kind: Int, axis: Int, start: CGPoint, values: [Double], before: Any, origin: Vec3, basis: simd_quatf, unit: Vec3, size: Float,
                 radiusModel: Mat4?, radiusLocal: Vec3)?
}

extension ViewportRenderer {
    static let gizmoColors: [SIMD4<Float>] = [SIMD4(0.95, 0.3, 0.33, 1), SIMD4(0.5, 0.86, 0.3, 1), SIMD4(0.3, 0.56, 1, 1)]

    private func gizmoRoot() -> String? {
        guard let document, document.format == .avfx, let selected = document.selectionID else { return nil }
        let root = selected.split(separator: "/").prefix(3).joined(separator: "/")
        return (root.hasPrefix("avfx/Emit/") || root.hasPrefix("avfx/Ptcl/")) && document.node(root) != nil ? root : nil
    }

    private func transformField(_ root: String, _ group: String, _ axis: Int) -> PropField? {
        guard let document, let node = document.node(root) else { return nil }
        let id = "\(root)#transform\(group)\(["X", "Y", "Z"][axis])"
        return document.sections(for: node).flatMap(\.fields).first { $0.id == id }
    }

    private func radiusChannels(_ root: String, _ tags: [String]) -> (channels: [CurveChannel], angle: Bool) {
        guard !tags.isEmpty, let document, let node = document.node(root) else { return ([], false) }
        var result: [CurveChannel] = []
        var angle = false
        for child in node.children {
            guard case .avfx(let block, _, let record) = child.payload, record == nil, block.tag == "Data" else { continue }
            for group in document.curveGroups(for: child) where tags.contains(group.tag) {
                if let channel = group.channels.first {
                    result.append(channel)
                    angle = group.isAngle
                }
            }
        }
        return (result, angle)
    }

    func updateGizmo(_ simulation: AvfxSimulation) {
        if let active = gizmo.active {
            gizmo.origin = active.origin
            gizmo.basis = active.basis
            gizmo.unit = active.unit
            gizmo.size = active.size
        }
        guard let root = gizmoRoot(), let index = Int(root.split(separator: "/").last ?? "") else {
            gizmo.handles = []
            gizmo.rootID = nil
            return
        }
        gizmo.rootID = root
        if gizmo.active == nil {
            gizmo.radiusModel = nil
            gizmo.lengthModel = nil
            gizmo.shapeType = 0
            gizmo.radiusTags = []
            gizmo.radiusScale = 1
            var origin: Vec3?
            var basis = simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
            var unit = Vec3(1, 1, 1)
            if root.hasPrefix("avfx/Emit/") {
                if let emitter = simulation.emitters.first(where: { $0.schema.index == index }) {
                    origin = Math3D.position(emitter.world)
                    let parent = Math3D.decompose(emitter.anchor())
                    basis = parent.rotation
                    unit = parent.scale
                    let type = emitter.schema.type
                    gizmo.shapeType = type
                    if type == 4 { gizmo.lengthModel = emitter.world }
                    if type == 3 || type == 4 {
                        gizmo.radiusModel = emitter.world
                        gizmo.radiusTags = ["Rads", "Rad"]
                        gizmo.radiusMode = 2
                    } else if type == 1 || type == 2 {
                        gizmo.radiusModel = emitter.world
                        gizmo.radiusTags = ["IjA"]
                        gizmo.radiusMode = 3
                    }
                }
            } else if let particle = simulation.particles.first(where: { $0.schema.index == index }) {
                if let draw = lastDraws.first(where: { $0.particle == index && !$0.isSprite }) ?? lastDraws.first(where: { $0.particle == index }) {
                    let parent = Math3D.decompose(draw.parent)
                    basis = parent.rotation
                    unit = parent.scale
                    origin = draw.worldBounds?.centre ?? Math3D.position(draw.model)
                    let type = particle.schema.type
                    if type == 12 || type == 11, !draw.isSprite {
                        gizmo.radiusModel = draw.model
                        gizmo.radiusTags = type == 12 ? ["RB", "RE"] : ["WID"]
                        gizmo.radiusMode = type == 12 ? 0 : 1
                    }
                }
            }
            guard let origin else {
                gizmo.handles = []
                return
            }
            gizmo.origin = origin
            gizmo.basis = basis
            gizmo.unit = Vec3(max(abs(unit.x), 1e-4), max(abs(unit.y), 1e-4), max(abs(unit.z), 1e-4))
            gizmo.size = max(0.05, (camera.ortho ? camera.distance : simd_distance(camera.eye, origin)) * 0.13)
        } else {
            gizmo.radiusModel = gizmo.active?.radiusModel
            if gizmo.active?.kind == 4 { gizmo.lengthModel = gizmo.active?.radiusModel }
        }
        var handles: [GizmoHandle] = []
        let axes = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)]
        for axis in 0..<3 {
            let direction = gizmo.basis.act(axes[axis])
            handles.append(GizmoHandle(index: handles.count, kind: 0, axis: axis, points: [gizmo.origin, gizmo.origin + direction * gizmo.size],
                                       color: ViewportRenderer.gizmoColors[axis]))
        }
        for axis in 0..<3 {
            let direction = gizmo.basis.act(axes[axis])
            var color = ViewportRenderer.gizmoColors[axis]
            color.w = 0.8
            handles.append(GizmoHandle(index: handles.count, kind: 3, axis: axis,
                                       points: [gizmo.origin + direction * gizmo.size * 1.12, gizmo.origin + direction * gizmo.size * 1.34], color: color))
        }
        for axis in 0..<3 {
            let u = gizmo.basis.act(axes[(axis + 1) % 3]), v = gizmo.basis.act(axes[(axis + 2) % 3])
            var ring: [Vec3] = []
            for step in 0...40 {
                let a = Float(step) / 40 * 2 * .pi
                ring.append(gizmo.origin + (u * cos(a) + v * sin(a)) * gizmo.size * 0.72)
            }
            var color = ViewportRenderer.gizmoColors[axis]
            color.w = 0.55
            handles.append(GizmoHandle(index: handles.count, kind: 1, axis: axis, points: ring, color: color))
        }
        let radius = radiusChannels(root, gizmo.radiusTags)
        if !radius.channels.isEmpty { gizmo.radiusScale = radius.angle ? 180 / .pi : 1 }
        let length = gizmo.lengthModel == nil && gizmo.shapeType != 4 ? nil : radiusChannels(root, ["Len"]).channels.first
        if let model = gizmo.radiusModel {
            if let first = radius.channels.first {
                let raw = first.read().first.map { Float($0.value) } ?? radiusDefault
                var local: Vec3
                switch gizmo.radiusMode {
                case 1: local = Vec3(0.5 + raw, 0.01, 0)
                case 3:
                    let angle = raw / Float(gizmo.radiusScale)
                    local = Vec3(sin(angle), 0, cos(angle))
                default: local = Vec3(raw, 0, 0)
                }
                if gizmo.active == nil { gizmo.radiusLocal = local }
                let centre = Math3D.point(model, .zero)
                var points = [centre, Math3D.point(model, local)]
                if gizmo.radiusMode == 0 || gizmo.radiusMode == 2 { points.append(points[1] + stub(model, Vec3(1, 0, 0))) }
                handles.append(GizmoHandle(index: handles.count, kind: 2, axis: 0, points: points, color: SIMD4(1, 0.72, 0.28, 1)))
            }
        }
        let half = Float(length?.read().first?.value ?? 0) / 2
        if let model = gizmo.lengthModel, length != nil {
            let top = Math3D.point(model, Vec3(0, half, 0))
            handles.append(GizmoHandle(index: handles.count, kind: 4, axis: 1, points: [top, top + stub(model, Vec3(0, 1, 0))], color: SIMD4(1, 0.72, 0.28, 1)))
        }
        handles.append(contentsOf: shapeOutline(radius.channels.first?.read().first?.value, half: half, firstIndex: handles.count))
        gizmo.handles = handles
    }

    private var radiusDefault: Float {
        gizmo.radiusMode == 1 || gizmo.radiusMode == 3 ? 0 : 1
    }

    private func stub(_ model: Mat4, _ axis: Vec3) -> Vec3 {
        let direction = Math3D.direction(model, axis)
        return simd_length_squared(direction) > 1e-12 ? simd_normalize(direction) * gizmo.size * 0.25 : .zero
    }

    private func shapeOutline(_ first: Double?, half: Float, firstIndex: Int) -> [GizmoHandle] {
        guard let model = gizmo.radiusModel ?? gizmo.lengthModel, gizmo.shapeType >= 1, gizmo.shapeType <= 4 else { return [] }
        let color = SIMD4<Float>(1, 0.72, 0.28, 0.45)
        var outlines: [[Vec3]] = []
        func circle(_ point: (Float) -> Vec3) -> [Vec3] { (0...48).map { point(Float($0) / 48 * 2 * .pi) } }
        switch gizmo.shapeType {
        case 3:
            let r = Float(first ?? 1)
            outlines = [circle { Vec3(cos($0) * r, 0, sin($0) * r) }, circle { Vec3(cos($0) * r, sin($0) * r, 0) }, circle { Vec3(0, cos($0) * r, sin($0) * r) }]
        case 4:
            let r = Float(first ?? 1)
            outlines = [circle { Vec3(cos($0) * r, half, sin($0) * r) }, circle { Vec3(cos($0) * r, -half, sin($0) * r) }]
            for step in 0..<4 {
                let a = Float(step) / 4 * 2 * .pi
                outlines.append([Vec3(cos(a) * r, -half, sin(a) * r), Vec3(cos(a) * r, half, sin(a) * r)])
            }
        default:
            let angle = Float(first ?? 0) / Float(gizmo.radiusScale)
            outlines = [circle { Vec3(sin(angle) * cos($0), sin(angle) * sin($0), cos(angle)) }]
            for step in 0..<4 {
                let a = Float(step) / 4 * 2 * .pi
                outlines.append([.zero, Vec3(sin(angle) * cos(a), sin(angle) * sin(a), cos(angle))])
            }
        }
        return outlines.enumerated().map { offset, points in
            GizmoHandle(index: firstIndex + offset, kind: 5, axis: 0, points: points.map { Math3D.point(model, $0) }, color: color)
        }
    }

    private func project(_ world: Vec3) -> CGPoint? {
        let clip = lastViewProjection * SIMD4<Float>(world.x, world.y, world.z, 1)
        guard clip.w > 1e-5 else { return nil }
        return CGPoint(x: CGFloat((clip.x / clip.w) * 0.5 + 0.5) * lastViewSize.width, y: CGFloat((clip.y / clip.w) * 0.5 + 0.5) * lastViewSize.height)
    }

    private func distance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let length = dx * dx + dy * dy
        let t = length > 0 ? min(max(((p.x - a.x) * dx + (p.y - a.y) * dy) / length, 0), 1) : 0
        return hypot(p.x - (a.x + dx * t), p.y - (a.y + dy * t))
    }

    func gizmoHandle(at point: CGPoint) -> GizmoHandle? {
        var best: (GizmoHandle, CGFloat)?
        for handle in gizmo.handles where handle.kind != 5 {
            var nearest = CGFloat.infinity
            for i in 1..<handle.points.count {
                guard let a = project(handle.points[i - 1]), let b = project(handle.points[i]) else { continue }
                nearest = min(nearest, distance(point, a, b))
            }
            let reach: CGFloat = handle.kind == 1 ? 5 : 8
            let score = nearest - (handle.kind == 2 || handle.kind == 4 ? 2 : handle.kind == 1 ? 0 : 1)
            if nearest <= reach, score < (best?.1 ?? .infinity) { best = (handle, score) }
        }
        return best?.0
    }

    func gizmoBegin(at point: CGPoint) -> Bool {
        guard showGizmo, let document, let root = gizmo.rootID, let handle = gizmoHandle(at: point) else { return false }
        var values: [Double] = []
        switch handle.kind {
        case 0: values = (0..<3).map { transformField(root, "Pos", $0)?.read().number ?? 0 }
        case 1: values = (0..<3).map { transformField(root, "Rot", $0)?.read().number ?? 0 }
        case 3: values = (0..<3).map { transformField(root, "Scl", $0)?.read().number ?? 1 }
        case 4: values = radiusChannels(root, ["Len"]).channels.map { $0.read().first?.value ?? 0 }
        default: values = radiusChannels(root, gizmo.radiusTags).channels.map { $0.read().first?.value ?? Double(radiusDefault) }
        }
        if handle.kind == 4 {
            gizmo.active = (handle.index, handle.kind, handle.axis, point, values, document.snapshot(), gizmo.origin, gizmo.basis, gizmo.unit, gizmo.size,
                            gizmo.lengthModel, Vec3(0, Float(values.first ?? 0) / 2, 0))
            return true
        }
        gizmo.active = (handle.index, handle.kind, handle.axis, point, values, document.snapshot(), gizmo.origin, gizmo.basis, gizmo.unit, gizmo.size,
                        gizmo.radiusModel, gizmo.radiusLocal)
        return true
    }

    func gizmoMove(to point: CGPoint) {
        guard let active = gizmo.active, let document, let root = gizmo.rootID else { return }
        let axes = [Vec3(1, 0, 0), Vec3(0, 1, 0), Vec3(0, 0, 1)]
        let dx = point.x - active.start.x, dy = point.y - active.start.y
        switch active.kind {
        case 0:
            let direction = active.basis.act(axes[active.axis])
            guard let a = project(active.origin), let b = project(active.origin + direction * active.size), let field = transformField(root, "Pos", active.axis) else { return }
            let sx = b.x - a.x, sy = b.y - a.y
            let length = sx * sx + sy * sy
            guard length > 1 else { return }
            let amount = Double((dx * sx + dy * sy) / length) * Double(active.size) / Double(active.unit[active.axis])
            document.setLive(field, .double(((active.values[active.axis] + amount) * 10000).rounded() / 10000))
        case 1:
            guard let centre = project(active.origin), let field = transformField(root, "Rot", active.axis) else { return }
            let from = atan2(active.start.y - centre.y, active.start.x - centre.x), to = atan2(point.y - centre.y, point.x - centre.x)
            var delta = Double(to - from)
            while delta > .pi { delta -= 2 * .pi }
            while delta < -.pi { delta += 2 * .pi }
            let facing = simd_dot(active.basis.act(axes[active.axis]), camera.eye - active.origin) >= 0 ? 1.0 : -1.0
            document.setLive(field, .double(((active.values[active.axis] + delta * facing * 180 / .pi) * 100).rounded() / 100))
        case 3:
            let direction = active.basis.act(axes[active.axis])
            guard let a = project(active.origin), let b = project(active.origin + direction * active.size), let field = transformField(root, "Scl", active.axis) else { return }
            let sx = b.x - a.x, sy = b.y - a.y
            let length = sx * sx + sy * sy
            guard length > 1 else { return }
            let factor = max(0.01, 1 + Double((dx * sx + dy * sy) / length))
            let base = abs(active.values[active.axis]) < 1e-6 ? 1 : active.values[active.axis]
            document.setLive(field, .double((base * factor * 10000).rounded() / 10000))
        default:
            let along = active.kind == 4 ? Vec3(0, 1, 0) : Vec3(1, 0, 0)
            guard let model = active.radiusModel, let a = project(Math3D.point(model, active.radiusLocal)),
                  let b = project(Math3D.point(model, active.radiusLocal + along)) else { return }
            let sx = b.x - a.x, sy = b.y - a.y
            let length = sx * sx + sy * sy
            guard length > 0.01 else { return }
            let scale = gizmo.radiusScale
            let amount = Double((dx * sx + dy * sy) / length) * (active.kind == 4 ? 2 : gizmo.radiusMode == 3 ? scale : 1)
            for (slot, channel) in radiusChannels(root, active.kind == 4 ? ["Len"] : gizmo.radiusTags).channels.enumerated() where slot < active.values.count {
                var keys = channel.read()
                if keys.isEmpty {
                    guard amount != 0 else { continue }
                    keys = [CurveKeyPoint(time: 0, value: active.values[slot] + amount, interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0)]
                } else {
                    let shift = active.values[slot] + amount - keys[0].value
                    for i in keys.indices { keys[i].value = ((keys[i].value + shift) * 10000).rounded() / 10000 }
                }
                channel.write(keys)
            }
            document.liveChanged()
        }
    }

    func gizmoEnd() {
        guard let active = gizmo.active, let document else { return }
        gizmo.active = nil
        document.registerUndo(active.kind == 0 ? "Move" : active.kind == 1 ? "Rotate" : active.kind == 3 ? "Scale" : "Resize", since: active.before)
    }
}
