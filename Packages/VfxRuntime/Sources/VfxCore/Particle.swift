import Foundation

struct Spawn {
    let emitter: EmitterInstance
    let time: Double
    let parent: Parent
    let seed: UInt32
    let inheritColor: Bool
    let life: Range?
    let unit: Double
    let model: (String) -> ModelData
    let state: EffectState
    let perspective: () -> Double
    let point: Emission.Point?
    let views: ViewFactory
}

final class ParticleInstance {
    var owner = ""
    let def: ParticleDef
    let view: ParticleView
    let geometry: GeometryData
    let life: Double
    let born: Double
    let emitter: EmitterInstance
    private(set) var world = Affine3.identity
    private(set) var perspective = 0.0

    private let parent: Parent
    private let timeScale: Double
    private let color: ParsedColor
    private let colorSource: EmitterInstance?
    private let state: EffectState
    private let perspectiveOf: () -> Double
    private let offset: Vec3
    private let vx: Double, vy: Double
    private let startRotation: Vec3
    private let startScale: Double
    private let ringAngleOffset: Double
    private let ring: RingGeometry?
    private let roundRect: RoundRectGeometry?
    private let trail: TrailGeometry?
    private var trailPoints: [TrailPoint] = []
    private let faces: FaceOrder?

    init(_ def: ParticleDef, _ textures: ParticleTextures, _ spawn: Spawn) throws {
        self.def = def
        let seed = spawn.seed
        let emission = spawn.emitter.def.emission
        parent = spawn.parent
        born = spawn.time
        emitter = spawn.emitter
        perspectiveOf = spawn.perspective
        colorSource = spawn.inheritColor ? spawn.emitter : nil
        state = spawn.state

        life = spawn.life == nil && def.forever ? .infinity : drawRange(spawn.life ?? def.life, 1, seed, Slot.life)
        timeScale = (spawn.life != nil || def.stretchCurves == true) && !def.forever ? def.life.maxValue / life : 1
        offset = Vec3(
            x: drawRange(emission?.offset?.x, 0, seed, Slot.offsetX) + (spawn.point?.x ?? 0),
            y: drawRange(emission?.offset?.y, 0, seed, Slot.offsetY) + (spawn.point?.y ?? 0),
            z: drawRange(emission?.offset?.z, 0, seed, Slot.offsetZ) + (spawn.point?.z ?? 0))
        let speed = drawRange(emission?.speed, 0, seed, Slot.speed)
        let direction = drawRange(emission?.direction, 0, seed, Slot.direction) * .pi / 180
        vx = cos(direction) * speed
        vy = sin(direction) * speed
        startRotation = drawRotation(def.startRotation, seed)
        startScale = drawRange(def.startScale, 1, seed, Slot.startScale)
        var angleRandom = 0.0
        if case .ring(_, _, _, let ar, _, _, _, _) = def.shape { angleRandom = ar ?? 0 }
        ringAngleOffset = drawRange(.between(-angleRandom, angleRandom), 0, seed, Slot.ringAngle)
        color = try parseColor(def.color)

        var softness = (inner: 0.0, outer: 0.0)
        var edges: EdgePair?
        var ring: RingGeometry?, roundRect: RoundRectGeometry?, trail: TrailGeometry?
        let geometry: GeometryData
        var own = false
        var faces: FaceOrder?
        switch def.shape {
        case .ring(_, _, _, _, let segments, let rows, let s, let e):
            ring = RingGeometry(segments: segments ?? 64, rows: rows ?? 1)
            geometry = ring!.data
            own = true
            softness = (s?.inner ?? 0, s?.outer ?? 0)
            edges = e
        case .roundRect(_, _, _, _, _, let corner, let rows, let s, let e):
            roundRect = RoundRectGeometry(cornerSegments: corner ?? 8, rows: rows ?? 1)
            geometry = roundRect!.data
            own = true
            softness = (s?.inner ?? 0, s?.outer ?? 0)
            edges = e
        case .trail(let t):
            trail = TrailGeometry(points: t.points)
            geometry = trail!.data
            own = true
        case .decal, .quad:
            geometry = quadGeometry(spawn.unit, spawn.unit)
        case .windmill(let mirror):
            geometry = windmillGeometry(spawn.unit, mirror)
        case .mesh(let model):
            let shared = meshGeometry(model, spawn.model(model), spawn.unit)
            if def.sortTriangles == true {
                geometry = ownMeshGeometry(shared)
                own = true
                faces = FaceOrder(geometry)
            } else {
                geometry = shared
            }
        case nil:
            if let t = def.texture {
                let size = spawn.views.textureSize(t)
                geometry = quadGeometry(size.width, size.height)
            } else {
                geometry = quadGeometry(spawn.unit, spawn.unit)
            }
        }
        self.ring = ring
        self.roundRect = roundRect
        self.trail = trail
        self.faces = faces
        self.geometry = geometry
        if case .trail(let t) = def.shape, let trail { trailPoints = try Self.trailPoints(t, trail.count) }

        let rgba = { (c: EdgeColor?) throws -> [Float] in
            let rgb = try parseHex(c?.color ?? "#ffffff")
            return [Float(rgb.r), Float(rgb.g), Float(rgb.b), Float(c?.alpha ?? 1)]
        }
        view = spawn.views.createParticleView(ParticleViewSpec(
            geometry: geometry,
            ownsGeometry: own,
            textures: textures,
            blend: def.blend ?? .normal,
            drawPriority: def.drawPriority ?? 0,
            edgeSoftness: softness,
            edgeColor: (try rgba(edges?.inner), try rgba(edges?.outer)),
            cull: def.cull,
            material: def.material))
    }

    private func loopedAgeAt(_ time: Double) -> Double {
        loopedAge(time, born, def.loop, state.released)
    }

    func isDead(_ time: Double) -> Bool {
        loopedAgeAt(time) >= life
    }

    func update(_ time: Double, _ fade: Double) {
        let d = def
        let age = time - born
        let t = loopedAgeAt(time) * timeScale
        let total = age * timeScale

        perspective = perspectiveOf()
        if trail != nil {
            world = .identity
            setTrail(time, t, total)
        } else {
            world = placedAt(time)
        }
        view.setPlacement(world, perspective: perspective)
        if let faces {
            let w = world
            faces.update { x, y, z in w.apply(x, y, z).z }
            view.geometryChanged()
        }

        var rgb = evalColor(color, t)
        var alpha = evalParam(d.alpha, t, 1, total) * fade
        if let colorSource {
            let c = colorSource.colorAt(time)
            rgb = Rgb(r: rgb.r * c.r, g: rgb.g * c.g, b: rgb.b * c.b)
            alpha *= c.a
        }
        view.setColor(rgb, brightness: evalParam(d.brightness, t, 1, total), alpha: alpha)
        if d.material != nil {
            let scrambled = sin(born * 12.9898 + 78.233) * 43758.5453
            view.setMaterial(age: age, life: life > 0 ? min(max(loopedAgeAt(time) / life, 0), 1) : 0, seed: scrambled - scrambled.rounded(.down))
        }

        switch d.shape {
        case .roundRect(let width, let height, let thickness, let radius, let uLength, _, _, _, _):
            let th = evalParam(thickness, t, 0, total)
            if roundRect!.set(
                evalParam(width, t, 0, total), evalParam(height, t, 0, total), evalParam(radius, t, th / 2, total), th, uLength ?? 0)
            {
                view.geometryChanged()
            }
        case .ring(let inner, let outer, let angle, _, _, _, _, _):
            let a = evalParam(angle, t, 360, total) + ringAngleOffset
            if ring!.set(evalParam(inner, t, 0, total), evalParam(outer, t, 0, total), a) { view.geometryChanged() }
        default: break
        }

        if let n = d.nineSlice {
            let s = evalAxes2(n.stretch, t, 1, total)
            view.setNineSlice(borderX: n.borderX, borderY: n.borderY, stretchX: s.x, stretchY: s.y)
        }
        if let uv = d.uv { setUv(.base, uv, t, total) }
        for (i, layer) in (d.layers ?? []).enumerated() {
            if let uv = layer.uv { setUv(.layer(i), uv, t, total) }
        }
        if let dist = d.distortion {
            if let uv = dist.uv { setUv(.distortion, uv, t, total) }
            view.setDistortPower(evalParam(dist.power, t, 0, total))
        }
    }

    func destroy() {
        view.destroy()
    }

    func worldAt(_ time0: Double) -> Affine3 {
        let d = def
        let time = max(time0, born)
        let base = parent.matrixAt(time)
        let age = time - born
        let t = loopedAgeAt(time) * timeScale
        let total = age * timeScale
        var p = evalVec3(d.position, t, 0, total)
        p.x += offset.x + vx * age
        p.y += offset.y + vy * age
        p.z += offset.z
        var s = evalAxes(d.scale, t, 1, total)
        s.x *= startScale
        s.y *= startScale
        s.z *= startScale
        let r = Vec3(
            x: startRotation.x + evalParam(d.rotationX, t, 0, total),
            y: startRotation.y + evalParam(d.rotationY, t, 0, total),
            z: startRotation.z + evalParam(d.rotation, t, 0, total))
        return base.appending(.local(position: p, rotation: r, order: d.rotationOrder ?? .xyz, scale: s))
    }

    private func placedAt(_ time: Double) -> Affine3 {
        state.turn.appending(worldAt(time))
    }

    private func setTrail(_ time: Double, _ t: Double, _ total: Double) {
        guard case .trail(let shape) = def.shape, let trail else { return }
        let n = trailPoints.count
        let width = evalParam(shape.width, t, 0, total)
        let w = shape.widthProfile
        let span = min(shape.frames, max(0, time - born))
        for i in 0..<n {
            let k = Double(i) / Double(n - 1)
            let p = placedAt(time - span * k).apply(0, 0, 0)
            trailPoints[i].x = p.x
            trailPoints[i].y = p.y
            trailPoints[i].z = p.z
            trailPoints[i].width = width * profile(k, shape.center, w?.begin ?? 1, w?.center ?? 1, w?.end ?? 1)
        }
        trail.set(trailPoints)
        view.geometryChanged()
    }

    private static func trailPoints(_ shape: Shape.Trail, _ n: Int) throws -> [TrailPoint] {
        let rgba = { (c: EdgeColor?) throws -> [Double] in
            let rgb = try parseHex(c?.color ?? "#ffffff")
            return [rgb.r, rgb.g, rgb.b, c?.alpha ?? 1]
        }
        let line = [try rgba(shape.color?.begin), try rgba(shape.color?.center), try rgba(shape.color?.end)]
        let edge = shape.edge.map { e in [try? rgba(e.begin), try? rgba(e.center), try? rgba(e.end)].map { $0 ?? [1, 1, 1, 1] } } ?? line
        return (0..<n).map { i in
            let k = Double(i) / Double(n - 1)
            let mix = { (c: [[Double]]) -> [Float] in (0..<4).map { Float(profile(k, shape.center, c[0][$0], c[1][$0], c[2][$0])) } }
            return TrailPoint(line: mix(line), edge: mix(edge))
        }
    }

    private func setUv(_ slot: UvSlot, _ uv: UvParam, _ t: Double, _ total: Double) {
        let scale = evalAxes2(uv.scale, t, 1, total)
        let sx = evalParam(uv.scroll?.x, t, 0, total), sy = evalParam(uv.scroll?.y, t, 0, total)
        view.setUv(slot, scaleX: scale.x, scaleY: scale.y, scrollX: sx, scrollY: sy, rotation: evalParam(uv.rotation, t, 0, total))
    }
}

func profile(_ k: Double, _ center: Double, _ begin: Double, _ mid: Double, _ end: Double) -> Double {
    if k <= center { return center > 0 ? begin + (mid - begin) * (k / center) : mid }
    return mid + (end - mid) * ((k - center) / max(1e-6, 1 - center))
}
