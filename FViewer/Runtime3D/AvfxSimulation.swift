import Foundation
import simd

struct CameraState {
    var position: Vec3
    var rotation: simd_quatf
    var fovY: Float
    var viewportHeight: Float
}

struct ScreenEffect {
    var kind: Int
    var position: Vec3
    var strength: Float
    var length: Float
    var inner: Float
    var outer: Float
    var angle: Float
}

struct LightDraw {
    var position: Vec3
    var color: Vec3
    var distance: Float
    var decay: Float
}

struct ParticleDraw {
    var particle: Int
    var geometry: RenderGeometry
    var model: Mat4
    var color: Vec4
    var colorBegin = Vec4(1, 1, 1, 1)
    var colorEnd = Vec4(1, 1, 1, 1)
    var uvMatrix = [Vec4](repeating: Vec4(1, 0, 0, 1), count: 5)
    var uvOffset = [SIMD2<Float>](repeating: .zero, count: 5)
    var frame = 0
    var distortPower: Float = 0
    var paletteOffset: Float = 0
    var spriteColor = Vec4(1, 1, 1, 1)
    var spriteCell = Vec4(0, 0, 1, 1)
    var isSprite = false
    var order = 0
    var sequence = 0
}

private enum ParticleKind {
    static let powder = 1, windmill = 2, line = 3, laser = 4, model = 5, polyline = 6, quad = 8, decal = 10, decalRing = 11, disc = 12, lightModel = 13
}

private enum Base {
    static let x = 0, y = 1, z = 2, moveDirection = 3, billboardAxisY = 4, screenBillboard = 5, cameraBillboard = 6
    static let moveDirectionBillboard = 7, cameraBillboardAxisY = 8, treeBillboard = 9
}

private enum Influence {
    static let initialPosition = 0, withOptions = 1, allAlways = 2, allAlwaysNoPosition = 4, withOptionsNoPosition = 7
}

private func lifeFrames(_ value: Float, _ random: Float, _ seed: Float) -> Float {
    if value < 0 { return .infinity }
    return max(1, value + random * (seed * 2 - 1))
}

final class EmitterInstance {
    let schema: REmitter
    let anchor: () -> Mat4
    var age: Float = 0
    var world = matrix_identity_float4x4
    var color = Vec4(1, 1, 1, 1)
    let seed: RandomSeed
    var nextSpawn: [Float]
    var nextChild: [Float]
    var order = 0
    let lifetime: Float
    var points: [EmitPoint] = []
    var stopped = false
    var timeline = -1
    var parent: EmitterInstance?
    var injected: [Int: Int] = [:]
    var velocity = Vec3.zero
    var travel = Vec3.zero
    var fall: Float = 0
    var moving = false
    var holdWhile: (() -> Bool)?
    var liveChildren = 0
    var cameraRotation: simd_quatf?

    init(schema: REmitter, anchor: @escaping () -> Mat4, endFrames: Float, random: inout SeededRandom) {
        self.schema = schema
        self.anchor = anchor
        seed = RandomSeed(&random)
        let life = lifeFrames(schema.life.value, schema.life.random, seed.get(0))
        lifetime = min(life, endFrames > 0 ? endFrames : .infinity)
        nextSpawn = schema.particleItems.map { Float(max(0, $0.generateDelay)) }
        nextChild = schema.emitterItems.map { Float(max(0, $0.generateDelay)) }
    }

    var alive: Bool { age < lifetime || (holdWhile?() ?? false) }
    var loops: Bool { schema.loopEnd > schema.loopStart && schema.loopStart >= 0 }

    func matrix(for seed: RandomSeed) -> Mat4 {
        let time = CurveTime(age)
        let position = Eval.axes(schema.position, time, 0, seed, 1)
        let rotation = Eval.axes(schema.rotation, time, 0, seed, 4)
        let scale = Eval.axes(schema.scale, time, 1, seed, 8)
        var out = anchor() * Math3D.compose(position, Math3D.euler(rotation, order: schema.rotationOrder), scale)
        if let cameraRotation, schema.rotationBase == Base.cameraBillboardAxisY {
            let parts = Math3D.decompose(out)
            out = Math3D.compose(parts.position, cameraRotation * Math3D.euler(rotation, order: schema.rotationOrder), parts.scale)
        }
        if moving { out = Math3D.translation(travel) * out }
        return out
    }

    func updateTransform() {
        world = matrix(for: seed)
        color = Eval.color(schema.color, CurveTime(age), seed)
    }

    private var ordered: Bool { [1, 3, 5, 7].contains(schema.generateMethod) }
    private var onVertex: Bool { [2, 3, 6, 7].contains(schema.generateMethod) }

    func nextPoint(_ random: inout SeededRandom) -> EmitPoint? {
        if (schema.type == 1 || schema.type == 2) && PreviewRules.isOn("coneEmitters") {
            let at = CurveTime(age)
            let half = max(0, Eval.curve(schema.coneAngle, at, 0) + Eval.curve(schema.coneAngleRandom, at, 0) * (random.next() * 2 - 1))
            let cosine = 1 - random.next() * (1 - cos(min(half, .pi)))
            let sine = (max(0, 1 - cosine * cosine)).squareRoot()
            let turn = random.next() * 2 * .pi
            let local = Vec3(sine * cos(turn), sine * sin(turn), cosine)
            let angles = Vec3(Eval.curve(schema.coneRotation[0], at, 0), Eval.curve(schema.coneRotation[1], at, 0), Eval.curve(schema.coneRotation[2], at, 0))
            return EmitPoint(position: .zero, normal: simd_act(Math3D.euler(angles, order: schema.dataRotationOrder), local))
        }
        guard !points.isEmpty else { return nil }
        let index: Int
        if ordered {
            index = order % points.count
            order += 1
        } else {
            index = min(points.count - 1, Int(random.next() * Float(points.count)))
        }
        if schema.type != 3 { return points[index] }
        let direction = points[index].normal
        if !onVertex { return EmitPoint(position: .zero, normal: direction) }
        return EmitPoint(position: direction * Eval.curve(schema.radius, CurveTime(age), 1), normal: direction)
    }

    func wrap(_ span: Float) {
        age -= span
        for i in nextSpawn.indices { nextSpawn[i] -= span }
        for i in nextChild.indices { nextChild[i] -= span }
    }

    func stopParticleItem(_ index: Int) {
        if index < nextSpawn.count { nextSpawn[index] = .infinity }
    }

    func due(particles: Bool, limit: Int, random: inout SeededRandom) -> [(item: REmitterItem, count: Int)] {
        let items = particles ? schema.particleItems : schema.emitterItems
        var next = particles ? nextSpawn : nextChild
        var out: [(REmitterItem, Int)] = []
        guard alive, !stopped else { return out }
        for i in items.indices {
            let item = items[i]
            if !item.enabled {
                next[i] = .infinity
                continue
            }
            var guardCount = 0
            while age >= next[i] && guardCount < limit {
                guardCount += 1
                let at = CurveTime(next[i])
                let perItem = item.createTime == 1 ? max(0, item.createCount) : 1
                let base = Eval.curve(schema.createCount, at, 1)
                    + Eval.randomOffset(schema.createCountRandom, type: schema.createCountRandom?.random ?? 0, at, random.next())
                let count = Int(base.rounded()) * perItem
                if count > 0 { out.append((item, count)) }
                let interval = Eval.curve(schema.createInterval, at, 0)
                    + Eval.randomOffset(schema.createIntervalRandom, type: schema.createIntervalRandom?.random ?? 0, at, random.next())
                next[i] = interval > 0 && item.createTime == 0 ? next[i] + interval : .infinity
            }
        }
        if particles { nextSpawn = next } else { nextChild = next }
        return out
    }
}

final class ParticleInstance {
    let schema: RParticle
    let item: REmitterItem
    let emitter: EmitterInstance
    let geometry: RenderGeometry?
    let cloud: SpriteCloud?
    var trail: PolylineTrail?
    let seed: RandomSeed
    let emitterSeed: RandomSeed
    var age: Float = 0
    var totalAge: Float = 0
    var spawnMatrix: Mat4
    var offset = Vec3.zero
    var localFlight = false
    var localTravel = Vec3.zero
    var localVelocity = Vec3.zero
    var velocity = Vec3.zero
    var travel = Vec3.zero
    let lifetime: Float
    var fresh = true
    var copyIndex = 0
    let timeScale: Float
    let follow: Bool
    let withOptions: Bool
    var lastWorld = Vec3.zero
    var hasLastWorld = false
    var moveDirection = Vec3.zero
    let sequence: Int

    init(schema: RParticle, item: REmitterItem, emitter: EmitterInstance, geometry: RenderGeometry?, cloud: SpriteCloud?, sequence: Int,
         random: inout SeededRandom) {
        self.schema = schema
        self.item = item
        self.emitter = emitter
        self.geometry = geometry
        self.cloud = cloud
        self.sequence = sequence
        seed = RandomSeed(&random, count: 26)
        emitterSeed = RandomSeed(&random)
        let life = item.overrideLife
            ? lifeFrames(item.overrideLifeValue, item.overrideLifeRandom, seed.get(0))
            : lifeFrames(schema.life.value, schema.life.random, seed.get(0))
        lifetime = life
        let own = schema.life.value
        timeScale = item.overrideLife && own > 0 && life.isFinite ? own / life : 1
        follow = item.influenceCoord == Influence.allAlways || item.influenceCoord == Influence.allAlwaysNoPosition
        withOptions = item.influenceCoord == Influence.withOptions || item.influenceCoord == Influence.withOptionsNoPosition
        spawnMatrix = emitter.matrix(for: emitterSeed)
    }

    var alive: Bool { age < lifetime || (cloud != nil && cloud?.finished == false) }
    var curveTime: CurveTime { CurveTime(age * timeScale, total: totalAge * timeScale) }
    var loops: Bool { schema.loopEnd > schema.loopStart && schema.loopStart >= 0 }
}

private final class TimelineStart {
    let index: Int
    let at: Float
    var spawned: Set<Int> = []

    init(index: Int, at: Float) {
        self.index = index
        self.at = at
    }
}

final class AvfxSimulation {
    static var skeletonBindPoints: [Int: Vec3]?
    static var skeletonLines: [(Vec3, Vec3)] = []
    static var bindPoints: [Int: Vec3] { skeletonBindPoints ?? defaultBindPoints }

    static let defaultBindPoints: [Int: Vec3] = [
        1: Vec3(0, 1.58, 0.08), 3: Vec3(0.3, 0.85, 0.1), 4: Vec3(0.3, 1.2, 0.1), 5: Vec3(0.3, 1.6, 0.1), 6: Vec3(-0.2, 1.42, 0),
        7: Vec3(0.2, 1.42, 0), 8: Vec3(-0.3, 1.05, 0), 9: Vec3(0.3, 1.05, 0), 10: Vec3(-0.1, 0.3, 0), 11: Vec3(0.1, 0.3, 0),
        16: Vec3(0, 1.0, 0.4), 25: Vec3(0, 1.72, 0), 26: Vec3(0, 1.6, 0), 27: Vec3(0, 1.6, 0.12), 28: Vec3(0, 1.3, 0.05),
        29: Vec3(0, 1.0, 0), 30: Vec3(0, 1.0, 0), 31: Vec3(0, 0.95, 0), 32: Vec3(-0.33, 0.78, 0), 33: Vec3(0.33, 0.78, 0),
        34: Vec3(-0.1, 0.03, 0.05), 35: Vec3(0.1, 0.03, 0.05), 42: Vec3(0, 2.0, 0), 43: Vec3(-0.04, 1.6, 0.1), 44: Vec3(0.04, 1.6, 0.1),
        71: Vec3(0, 0, 0), 77: Vec3(-0.33, 0.78, 0), 78: Vec3(0.33, 0.78, 0),
    ]

    let schema: REffectSchema
    private(set) var time: Float = 0
    private(set) var released = false
    private(set) var emitters: [EmitterInstance] = []
    private(set) var particles: [ParticleInstance] = []
    var groundY: Float = 0
    var useBindPoints = true
    var maxParticles = 4000

    private var random = SeededRandom(seed: 1)
    private var startedTimelines: Set<Int> = []
    private var timelineStarts: [TimelineStart] = []
    private var kill: (from: Float, frames: Float)?
    private var killed = false
    private var pendingRestart = false
    private var sequence = 0
    private var cameraRotation: simd_quatf?
    private var cameraPosition = Vec3.zero
    private var modelGeometry: [Int: RenderGeometry] = [:]
    private var emitPoints: [Int: [EmitPoint]] = [:]

    var seed: UInt64 = 1
    private(set) var clipLog: [(time: Float, type: String)] = []

    init(schema: REffectSchema) {
        self.schema = schema
    }

    func restart() {
        emitters = []
        particles = []
        timelineStarts = []
        startedTimelines = []
        released = false
        kill = nil
        killed = false
        time = 0
        sequence = 0
        random = SeededRandom(seed: seed)
        clipLog = []
    }

    func release() { released = true }

    @discardableResult
    func trigger(_ n: Int) -> Bool {
        guard n >= 0, n < schema.triggers.count else { return false }
        let t = schema.triggers[n]
        guard t.enabled, t.timeline >= 0, t.timeline < schema.timelines.count else { return false }
        startedTimelines.insert(t.timeline)
        timelineStarts.append(TimelineStart(index: t.timeline, at: time + Float(t.start)))
        return true
    }

    func advance(_ frames: Float) {
        time += frames
        step(frames)
        if pendingRestart {
            pendingRestart = false
            let kept = Array(clipLog.suffix(200))
            restart()
            clipLog = kept
        }
    }

    private var fade: Float {
        guard let kill else { return 1 }
        return kill.frames > 0 ? max(0, 1 - (time - kill.from) / kill.frames) : 0
    }

    private var emittersDone: Bool {
        let allStarted = schema.scheduler.allSatisfy { !$0.enabled || startedTimelines.contains($0.timeline) }
        let allSpawned = timelineStarts.allSatisfy { start in
            guard start.index >= 0, start.index < schema.timelines.count else { return true }
            return schema.timelines[start.index].items.enumerated().allSatisfy { !$0.element.enabled || start.spawned.contains($0.offset) }
        }
        return allStarted && allSpawned && emitters.isEmpty
    }

    var finished: Bool { killed || (emittersDone && particles.isEmpty) }

    var held: Bool {
        !released && (emitters.contains { $0.holdWhile != nil || $0.loops || $0.lifetime == .infinity }
            || particles.contains { $0.loops || $0.lifetime == .infinity })
    }

    private func runClip(_ clip: RClip) {
        clipLog.append((time, clip.type))
        switch clip.type {
        case "ULLP": release()
        case "END ":
            emitters.forEach { $0.stopped = true }
            release()
        case "KILL": kill = (time, Float(max(0, clip.ints[0])))
        case "REST": pendingRestart = true
        case "TRG ": trigger(clip.ints[0])
        case "RTRG":
            let lo = min(clip.ints[0], clip.ints[1]), hi = max(clip.ints[0], clip.ints[1])
            trigger(lo + Int(random.next() * Float(hi - lo + 1)))
        default: break
        }
    }

    private func binderMatrix(_ index: Int) -> () -> Mat4 {
        var object = matrix_identity_float4x4
        if index >= 0, index < schema.binders.count, schema.binders[index].type == 3, PreviewRules.isOn("cameraBinder") {
            let distance = schema.binders[index].distance
            return { [weak self] in
                guard let self else { return matrix_identity_float4x4 }
                return Math3D.compose(self.cameraPosition, self.cameraRotation ?? simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1))
                    * Math3D.translation(Vec3(0, 0, distance))
            }
        }
        if useBindPoints, index >= 0, index < schema.binders.count, schema.binders[index].bindTargetPoint == 3,
           let point = AvfxSimulation.bindPoints[schema.binders[index].bindPointId] {
            object = Math3D.translation(point)
        }
        let revised = Math3D.compose(schema.revisedPosition, Math3D.euler(schema.revisedRotation, order: 0), schema.revisedScale)
        let result = object * revised
        return { result }
    }

    private func points(for model: Int) -> [EmitPoint] {
        if let cached = emitPoints[model] { return cached }
        let result = model >= 0 && model < schema.models.count ? GeometryBuilder.emitPoints(schema.models[model]) : []
        emitPoints[model] = result
        return result
    }

    private func setupShape(_ e: EmitterInstance) {
        let s = e.schema
        switch s.type {
        case 5:
            e.points = points(for: s.modelIndex)
        case 3:
            let nx = max(1, s.divideX), ny = max(1, s.divideY)
            let poles = s.generateMethod < 4
            var directions: [Vec3] = []
            if poles { directions.append(Vec3(0, 1, 0)) }
            if ny > 1 {
                for j in 1..<ny {
                    let theta = Float.pi * Float(j) / Float(ny)
                    for i in 0..<nx {
                        let a = Float(i) / Float(nx) * 2 * .pi
                        directions.append(Vec3(sin(theta) * cos(a), cos(theta), sin(theta) * sin(a)))
                    }
                }
            }
            if poles { directions.append(Vec3(0, -1, 0)) }
            e.points = directions.map { EmitPoint(position: $0, normal: $0) }
        case 4:
            let nx = max(1, s.divideX), ny = max(0, s.divideY)
            let radius = Eval.curve(s.radius, CurveTime(0), 1)
            let length = Eval.curve(s.length, CurveTime(0), 0)
            for j in 0...ny {
                let y = ny > 0 ? (Float(j) / Float(ny) - 0.5) * length : 0
                for i in 0..<nx {
                    let a = Float(i) / Float(nx) * 2 * .pi
                    let normal = Vec3(cos(a), 0, sin(a))
                    e.points.append(EmitPoint(position: Vec3(normal.x * radius, y, normal.z * radius), normal: normal))
                }
            }
        default: break
        }
    }

    private func spawnEmitter(_ schema: REmitter, anchor: @escaping () -> Mat4, endFrames: Float, startAge: Float) -> EmitterInstance {
        let e = EmitterInstance(schema: schema, anchor: anchor, endFrames: endFrames, random: &random)
        e.cameraRotation = cameraRotation
        setupShape(e)
        e.age = max(0, startAge)
        emitters.append(e)
        return e
    }

    private var revisedSpeedScale: Float {
        (abs(schema.revisedScale.x) + abs(schema.revisedScale.y) + abs(schema.revisedScale.z)) / 3
    }

    private func injectionSpeed(_ e: EmitterInstance) -> Float {
        let at = CurveTime(e.age)
        var speed = Eval.curve(e.schema.injectionSpeed, at, 0)
        if e.schema.injectionSpeedRandom != nil { speed += Eval.curve(e.schema.injectionSpeedRandom, at, 0) * (random.next() * 2 - 1) }
        return speed
    }

    private func step(_ frames: Float) {
        if kill != nil, fade <= 0 {
            emitters = []
            particles = []
            timelineStarts = []
            startedTimelines = []
            kill = nil
            killed = true
            return
        }
        for s in schema.scheduler where s.enabled && !startedTimelines.contains(s.timeline) && time >= Float(s.start) {
            startedTimelines.insert(s.timeline)
            timelineStarts.append(TimelineStart(index: s.timeline, at: Float(s.start)))
        }
        for start in Array(timelineStarts) {
            guard start.index >= 0, start.index < schema.timelines.count else { continue }
            let timeline = schema.timelines[start.index]
            let local = time - start.at
            for (i, item) in timeline.items.enumerated() {
                if !item.enabled || start.spawned.contains(i) || local < Float(item.start) { continue }
                start.spawned.insert(i)
                if item.clip >= 0, item.clip < timeline.clips.count { runClip(timeline.clips[item.clip]) }
                guard item.emitter >= 0, item.emitter < schema.emitters.count else { continue }
                let binder = item.binder >= 0 ? item.binder : timeline.binder
                let end: Float = item.end > item.start ? Float(item.end - item.start) : 0
                let e = spawnEmitter(schema.emitters[item.emitter], anchor: binderMatrix(binder), endFrames: end, startAge: local - Float(item.start))
                e.timeline = start.index
                if item.end < 0 { e.holdWhile = { [unowned self] in !self.released } }
            }
        }

        var created: [EmitterInstance] = []
        var queue: [EmitterInstance] = []
        for e in emitters {
            e.age += frames
            let loopStart = Float(e.schema.loopStart), loopEnd = Float(e.schema.loopEnd)
            if !released, e.loops, e.age >= loopEnd { e.wrap(loopEnd - loopStart) }
            if e.moving { moveEmitter(e, frames) }
            e.cameraRotation = cameraRotation
            e.updateTransform()
            queue.append(e)
        }
        var head = 0
        while head < queue.count {
            let e = queue[head]
            head += 1
            for (item, count) in e.due(particles: true, limit: 64, random: &random) {
                guard item.target >= 0, item.target < schema.particles.count else { continue }
                let ps = schema.particles[item.target]
                if ps.life.value < 0 && !item.overrideLife { e.stopParticleItem(item.index) }
                if ps.loopEnd > ps.loopStart && ps.loopStart >= 0 { e.stopParticleItem(item.index) }
                let first = e.injected[item.index] ?? 0
                e.injected[item.index] = first + count
                for n in 0..<count {
                    if random.next() * 100 >= Float(item.probability) { continue }
                    if e.schema.childLimit > 0 && e.liveChildren >= e.schema.childLimit { break }
                    if particles.count >= maxParticles { break }
                    particles.append(spawnParticle(ps, item, e, copyIndex: first + n))
                    e.liveChildren += 1
                }
            }
            for (item, count) in e.due(particles: false, limit: 8, random: &random) {
                guard item.target >= 0, item.target < schema.emitters.count else { continue }
                let child = schema.emitters[item.target]
                for n in 0..<count {
                    guard emitters.count + created.count < 2000 else { break }
                    let point = e.nextPoint(&random)
                    var at: Mat4?
                    if let point {
                        var m = Math3D.translation(point.position)
                        if e.schema.type == 4 { m = m * Math3D.rotationY(atan2(point.normal.x, point.normal.z)) }
                        at = m
                    }
                    let follow = item.influenceCoord == Influence.allAlways || item.influenceCoord == Influence.allAlwaysNoPosition
                    let withOptions = item.influenceCoord == Influence.withOptions || item.influenceCoord == Influence.withOptionsNoPosition
                    let fixed = at.map { e.world * $0 } ?? e.world
                    let current: () -> Mat4 = { at.map { e.world * $0 } ?? e.world }
                    let keepPosition = item.inheritPosition && item.influenceCoord != Influence.withOptionsNoPosition
                    let revisedScale = schema.revisedScale
                    let anchor: () -> Mat4
                    if follow {
                        anchor = current
                    } else if withOptions {
                        anchor = {
                            let now = Math3D.decompose(current())
                            let origin = keepPosition ? now.position : Math3D.position(fixed)
                            return Math3D.compose(origin, item.inheritRotation ? now.rotation : simd_quatf(angle: 0, axis: Vec3(0, 1, 0)),
                                                  item.inheritScale ? now.scale : revisedScale)
                        }
                    } else {
                        anchor = { fixed }
                    }
                    let c = EmitterInstance(schema: child, anchor: anchor, endFrames: 0, random: &random)
                    if item.generateDelayByOne && item.generateDelay > 0 { c.age = -Float(n * item.generateDelay) }
                    c.timeline = e.timeline
                    c.parent = e
                    c.cameraRotation = cameraRotation
                    if let point {
                        let speed = injectionSpeed(e) * revisedSpeedScale
                        if speed != 0 {
                            c.velocity = Math3D.direction(e.world, point.normal) * speed
                            c.moving = true
                        }
                    }
                    setupShape(c)
                    c.updateTransform()
                    created.append(c)
                    queue.append(c)
                }
            }
        }
        emitters.append(contentsOf: created)
        var carriers = Set<ObjectIdentifier>()
        for e in emitters {
            var ancestor = e.parent
            while let a = ancestor {
                carriers.insert(ObjectIdentifier(a))
                ancestor = a.parent
            }
        }
        for p in particles where p.follow || p.withOptions {
            var ancestor: EmitterInstance? = p.emitter
            while let a = ancestor {
                carriers.insert(ObjectIdentifier(a))
                ancestor = a.parent
            }
        }
        let fresh = Set(created.map { ObjectIdentifier($0) })
        emitters.removeAll { !$0.alive && !fresh.contains(ObjectIdentifier($0)) && !carriers.contains(ObjectIdentifier($0)) }

        for p in particles {
            if p.fresh {
                p.fresh = false
                continue
            }
            move(p, frames)
            p.cloud?.step(frames, alive: p.age < p.lifetime, random: &random)
            p.age += frames
            p.totalAge += frames
            let loopStart = Float(p.schema.loopStart), loopEnd = Float(p.schema.loopEnd)
            if !released, p.loops, p.age >= loopEnd { p.age -= loopEnd - loopStart }
        }
        for p in particles where !p.alive { p.emitter.liveChildren -= 1 }
        particles.removeAll { !$0.alive }
    }

    private func moveEmitter(_ e: EmitterInstance, _ frames: Float) {
        let at = CurveTime(e.age)
        let gravity = Eval.curve(e.schema.gravity, at, 0)
        let scale = Eval.curve(e.schema.airResistance, at, 1)
        e.fall += gravity * frames
        e.travel.y += e.fall * frames
        e.travel += e.velocity * scale * frames
    }

    private func move(_ p: ParticleInstance, _ frames: Float) {
        let s = p.schema
        let t = p.curveTime
        let gravity = Eval.curve(s.gravity, t, 0) + Eval.randomOffset(s.gravityRandom, type: s.gravity?.random ?? 0, t, p.seed.get(25))
        if gravity != 0 { p.velocity.y += gravity * frames }
        let scale = Eval.curve(s.airResistance, t, 1) + Eval.randomOffset(s.airResistanceRandom, type: s.airResistance?.random ?? 0, t, p.seed.get(12))
        if p.localFlight && simd_length_squared(p.localVelocity) > 0 { p.localTravel += p.localVelocity * scale * frames }
        if simd_length_squared(p.velocity) == 0 { return }
        p.travel += p.velocity * scale * frames
    }

    static var skinMesh: MeshData?
    static var skinToken = 0
    private var skinToken = -1

    private func geometry(for ps: RParticle) -> RenderGeometry? {
        switch ps.type {
        case ParticleKind.model, ParticleKind.lightModel:
            if let cached = modelGeometry[ps.modelIndex] { return cached }
            guard ps.modelIndex >= 0, ps.modelIndex < schema.models.count, let built = GeometryBuilder.model(schema.models[ps.modelIndex]) else {
                return GeometryBuilder.quad
            }
            modelGeometry[ps.modelIndex] = built
            return built
        case 14:
            guard PreviewRules.isOn("modelSkin"), let mesh = AvfxSimulation.skinMesh else { return nil }
            if skinToken == AvfxSimulation.skinToken, let cached = modelGeometry[-1000] { return cached }
            let built = RenderGeometry()
            for vertex in mesh.vertices { built.add(vertex.position, normal: vertex.normal, uv: vertex.uv) }
            built.indices = mesh.indices
            modelGeometry[-1000] = built
            skinToken = AvfxSimulation.skinToken
            return built
        case ParticleKind.quad, ParticleKind.powder: return GeometryBuilder.quad
        case ParticleKind.line: return ps.simple != nil ? GeometryBuilder.quad : nil
        case ParticleKind.windmill: return GeometryBuilder.windmill(mirror: ps.windmillUvType == 1)
        case ParticleKind.decal: return GeometryBuilder.decal
        case ParticleKind.decalRing: return GeometryBuilder.decalRing(fan: ps.ringFan)
        case ParticleKind.laser: return GeometryBuilder.laser
        case ParticleKind.disc: return ps.disc.map { GeometryBuilder.disc(countU: $0.countU, countV: $0.countV) }
        default: return nil
        }
    }

    private func spawnParticle(_ ps: RParticle, _ item: REmitterItem, _ e: EmitterInstance, copyIndex: Int) -> ParticleInstance {
        let trail = ps.type == ParticleKind.polyline && PreviewRules.isOn("trails") ? ps.polyline.map { PolylineTrail($0) } : nil
        let shape = trail?.geometry ?? geometry(for: ps)
        var cloud: SpriteCloud?
        if shape != nil, let simple = ps.simple, ps.type == ParticleKind.powder || ps.type == ParticleKind.line {
            cloud = SpriteCloud(anim: simple, points: simple.injectionPosition == 1 ? points(for: simple.injectionModel) : [],
                                lines: ps.type == ParticleKind.line)
        }
        sequence += 1
        let p = ParticleInstance(schema: ps, item: item, emitter: e, geometry: shape, cloud: cloud, sequence: sequence, random: &random)
        p.copyIndex = copyIndex
        p.trail = trail
        let point = e.nextPoint(&random)
        p.localFlight = p.withOptions && item.inheritPosition && item.influenceCoord != Influence.withOptionsNoPosition && point != nil
        if let point {
            p.offset = point.position
            p.spawnMatrix = p.spawnMatrix * Math3D.translation(point.position)
            let speed = injectionSpeed(e)
            if p.localFlight {
                if speed != 0 { p.localVelocity = point.normal * speed }
            } else if speed != 0 {
                p.velocity = Math3D.direction(p.spawnMatrix, point.normal) * speed * revisedSpeedScale
            }
        }
        if item.influenceCoord == Influence.initialPosition && !p.follow && !p.withOptions {
            p.spawnMatrix = Math3D.compose(Math3D.position(p.spawnMatrix), simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), schema.revisedScale)
        }
        return p
    }

    private func discShape(_ d: RDisc, _ t: CurveTime, _ seed: RandomSeed) -> DiscShape {
        func at(_ tag: String, _ fallback: Float, _ slot: Int) -> Float {
            Eval.withRandom(d.curves[tag], d.curves[tag + "R"], t, fallback, seed.get(slot))
        }
        return DiscShape(angle: at("Ang", 2 * .pi, 16), radiusBegin: at("RB", 1, 17), radiusEnd: at("RE", 1, 18), widthBegin: at("WB", 1, 19),
                         widthEnd: at("WE", 1, 20), heightBeginInner: at("HBI", 0, 21), heightEndInner: at("HEI", 0, 22),
                         heightBeginOuter: at("HBO", 0, 23), heightEndOuter: at("HEO", 0, 24))
    }

    private func laserMatrix(_ m: Mat4, base: Int, length: Float, width: Float, camera: Vec3, _ p: ParticleInstance) -> Mat4 {
        let cx = Vec3(m.columns.0.x, m.columns.0.y, m.columns.0.z)
        let cy = Vec3(m.columns.1.x, m.columns.1.y, m.columns.1.z)
        let cz = Vec3(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        let origin = Math3D.position(m)
        var axis = cz
        var across = simd_length(cx)
        if base == Base.x {
            axis = cx
            across = simd_length(cz)
        } else if base == Base.y {
            axis = cy
        } else if base == Base.moveDirection {
            if p.hasLastWorld {
                let d = origin - p.lastWorld
                if simd_length_squared(d) > 1e-10 { p.moveDirection = d }
            }
            p.lastWorld = origin
            p.hasLastWorld = true
            let direction = simd_length_squared(p.moveDirection) > 0 ? p.moveDirection : simd_length_squared(p.velocity) > 0 ? p.velocity : cz
            axis = simd_normalize(direction) * simd_length(cz)
        }
        let along = axis * length
        let toCamera = camera - (origin + along * 0.5)
        var side = simd_cross(toCamera, along)
        if simd_length_squared(side) < 1e-12 { side = Vec3(1, 0, 0) }
        side = simd_normalize(side) * width * across
        let normal = simd_length_squared(along) > 1e-12 ? simd_normalize(simd_cross(along, side)) : Vec3(0, 1, 0)
        return Math3D.basis(side, normal, along, origin: origin)
    }

    private func visible(_ p: ParticleInstance, _ filter: VisibilityFilter) -> Bool {
        if filter.isEmpty { return true }
        var chain: [EmitterInstance] = []
        var current: EmitterInstance? = p.emitter
        while let e = current {
            chain.append(e)
            current = e.parent
        }
        if filter.hidden.contains(.particle(p.schema.index)) { return false }
        if chain.contains(where: { filter.hidden.contains(.emitter($0.schema.index)) || filter.hidden.contains(.timeline($0.timeline)) }) { return false }
        switch filter.isolated {
        case .particle(let index): return p.schema.index == index
        case .emitter(let index): return chain.contains { $0.schema.index == index }
        case .timeline(let index): return chain.contains { $0.timeline == index }
        case nil: return true
        }
    }

    private func effectorTime(_ effector: REffector, _ start: Float) -> Float {
        var age = start
        if !released, PreviewRules.isOn("loopEffectors"), effector.loopEnd > effector.loopStart, effector.loopStart >= 0, age >= Float(effector.loopEnd) {
            let span = Float(effector.loopEnd - effector.loopStart)
            age = Float(effector.loopStart) + (age - Float(effector.loopStart)).truncatingRemainder(dividingBy: span)
        }
        return age
    }

    func screenEffects(camera: Vec3, filter: VisibilityFilter = VisibilityFilter()) -> (effects: [ScreenEffect], quake: Float, phase: Float) {
        var effects: [ScreenEffect] = []
        var quake: Float = 0, phase: Float = 0
        for e in emitters where e.schema.index < schema.emitterEffectors.count {
            let index = schema.emitterEffectors[e.schema.index]
            guard index >= 0, index < schema.effectors.count else { continue }
            if filter.hidden.contains(.emitter(e.schema.index)) || filter.hidden.contains(.timeline(e.timeline)) { continue }
            let effector = schema.effectors[index]
            let age = effectorTime(effector, e.age)
            let t = CurveTime(age)
            let origin = Math3D.point(e.world, Vec3(0, 0, 0))
            let distance = simd_length(camera - origin)
            switch effector.type {
            case 3, 4, 5, 7:
                guard PreviewRules.isOn("postEffects") else { continue }
                var strength = Eval.curve(effector.strength, t, 1) * fade
                if effector.fadeEnd > effector.fadeStart { strength *= 1 - min(max((distance - effector.fadeStart) / (effector.fadeEnd - effector.fadeStart), 0), 1) }
                guard strength > 0.001 else { continue }
                effects.append(ScreenEffect(kind: effector.type, position: origin, strength: strength, length: Eval.curve(effector.length, t, 0.1),
                                            inner: Eval.curve(effector.inner, t, 0), outer: Eval.curve(effector.outer, t, 0), angle: Eval.curve(effector.angle, t, 0)))
            case 6, 9:
                guard PreviewRules.isOn("cameraQuake") else { continue }
                let position = Math3D.point(e.world, Eval.axes(effector.position, t, 0, e.seed, 1))
                let reach = simd_length(camera - position)
                let near = Eval.curve(effector.quakeIn, t, 0), far = Eval.curve(effector.quakeOut, t, 0)
                var amount = abs(Eval.curve(effector.quake, t, 0)) * fade
                if far > near { amount *= 1 - min(max((reach - near) / (far - near), 0), 1) } else if far > 0, reach > far { amount = 0 }
                if amount > quake {
                    quake = amount
                    phase = e.age
                }
            default: continue
            }
        }
        return (effects, quake, phase)
    }

    func lights(filter: VisibilityFilter = VisibilityFilter()) -> [LightDraw] {
        var result: [LightDraw] = []
        guard PreviewRules.isOn("lights") else { return result }
        for e in emitters where e.schema.index < schema.emitterEffectors.count {
            let index = schema.emitterEffectors[e.schema.index]
            guard index >= 0, index < schema.effectors.count, schema.effectors[index].type == 0 || schema.effectors[index].type == 1 else { continue }
            if filter.hidden.contains(.emitter(e.schema.index)) || filter.hidden.contains(.timeline(e.timeline)) { continue }
            let effector = schema.effectors[index]
            let t = CurveTime(effectorTime(effector, e.age))
            let color = Eval.color(effector.color, t, e.seed)
            let peak = max(color.x, color.y, color.z, 1e-6)
            let strength = peak * max(0, color.w) * fade
            guard strength > 0 else { continue }
            if effector.type == 1 {
                guard PreviewRules.isOn("directionalLights"), let rotation = effector.rotation else { continue }
                let turn = Math3D.euler(Eval.axes(rotation, t, 0, e.seed, 1), order: 0)
                let origin = Math3D.point(e.world, Vec3(0, 0, 0))
                let toward = Math3D.point(e.world, turn.act(Vec3(0, 0, 1))) - origin
                let reach = simd_length(toward)
                guard reach > 1e-5 else { continue }
                result.append(LightDraw(position: origin - toward / reach * 100_000, color: Vec3(color.x, color.y, color.z) / peak * strength * max(0, Eval.curve(effector.power, t, 1)),
                                        distance: 0, decay: 0))
                continue
            }
            result.append(LightDraw(position: Math3D.point(e.world, Eval.axes(effector.position, t, 0, e.seed, 1)),
                                    color: Vec3(color.x, color.y, color.z) / peak * strength, distance: Eval.curve(effector.distance, t, 0),
                                    decay: Float(effector.attenuation + 1)))
        }
        return result
    }

    func emitterMarkers() -> [(index: Int, world: Mat4, points: [Vec3])] {
        emitters.map { e in
            let radius = e.schema.type == 3 ? Eval.curve(e.schema.radius, CurveTime(e.age), 1) : 1
            var points = e.points.map { $0.position * (e.schema.type == 3 ? radius : 1) }
            if e.schema.type == 1 || e.schema.type == 2 {
                let t = CurveTime(e.age)
                let angle = min(max(Eval.curve(e.schema.coneAngle, t, 0), 0), .pi)
                let turn = Math3D.euler(Vec3(Eval.curve(e.schema.coneRotation[0], t, 0), Eval.curve(e.schema.coneRotation[1], t, 0),
                                             Eval.curve(e.schema.coneRotation[2], t, 0)), order: e.schema.dataRotationOrder)
                for ring in 1...4 {
                    let reach = Float(ring) * 0.25
                    for step in 0..<32 {
                        let around = Float(step) / 32 * 2 * .pi
                        points.append(turn.act(Vec3(sin(angle) * cos(around), sin(angle) * sin(around), cos(angle)) * reach))
                    }
                }
            }
            return (e.schema.index, e.world, points)
        }
    }

    func pick(origin: Vec3, direction: Vec3, camera: CameraState, filter: VisibilityFilter) -> Int? {
        var best: (particle: Int, distance: Float)?
        for draw in render(camera: camera, filter: filter) {
            let centre = Math3D.position(draw.model)
            let scale = Math3D.decompose(draw.model).scale
            let radius = max(0.08, max(abs(scale.x), abs(scale.y), abs(scale.z)) * 0.5)
            let along = simd_dot(centre - origin, direction)
            guard along > 0 else { continue }
            let miss = simd_length(centre - (origin + direction * along))
            guard miss <= radius else { continue }
            let score = miss / radius + along * 0.001
            if best == nil || score < (best?.distance ?? .infinity) { best = (draw.particle, score) }
        }
        return best?.particle
    }

    var usedBindPoints: [Vec3] {
        schema.binders.compactMap { $0.bindTargetPoint == 3 ? AvfxSimulation.bindPoints[$0.bindPointId] : nil }
    }

    func render(camera: CameraState, filter: VisibilityFilter = VisibilityFilter()) -> [ParticleDraw] {
        cameraRotation = camera.rotation
        cameraPosition = camera.position
        let identity = simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
        let pixelAngle = 2 * tan(camera.fovY / 2) / max(1, camera.viewportHeight)
        let fadeNow = fade
        var draws: [ParticleDraw] = []
        for p in particles {
            guard let shape = p.geometry, visible(p, filter) else { continue }
            let s = p.schema
            let t = p.curveTime
            let localPosition = Eval.axes(s.position, t, 0, p.seed, 1)
            var localRotation = Eval.axes(s.rotation, t, 0, p.seed, 4)
            let spun = p.totalAge * p.timeScale
            localRotation.x += Eval.curve(s.rotVelX, t) * spun
            localRotation.y += Eval.curve(s.rotVelY, t) * spun
            localRotation.z += Eval.curve(s.rotVelZ, t) * spun
            let injection = Math3D.euler(p.item.injectionAngle * Float(p.copyIndex), order: s.rotationOrder)
            let hasInjection = simd_length_squared(p.item.injectionAngle) > 0 && p.copyIndex != 0
            let treeQuadFixed = s.type == ParticleKind.quad && s.rotationBase == Base.treeBillboard
            let billboardBases = [Base.screenBillboard, Base.cameraBillboard, Base.billboardAxisY, Base.cameraBillboardAxisY,
                                  Base.moveDirectionBillboard, Base.treeBillboard]
            let billboard = !treeQuadFixed && ((s.type == ParticleKind.powder && p.cloud == nil) || s.type == ParticleKind.windmill
                || billboardBases.contains(s.rotationBase))
            let localScale = Eval.axes(s.scale, t, 1, p.seed, 8)
            var local = Math3D.compose(localPosition, Math3D.euler(localRotation, order: s.rotationOrder), localScale)
            if !billboard && hasInjection { local = Mat4(injection) * local }
            if s.type == ParticleKind.quad {
                if s.rotationBase == Base.x {
                    local = local * Math3D.rotationY(.pi / 2)
                } else if s.rotationBase == Base.y {
                    local = local * Math3D.rotationX(-.pi / 2)
                }
            }

            let emitterWorld = p.emitter.matrix(for: p.emitterSeed)
            var m: Mat4
            if p.follow {
                m = emitterWorld
                if simd_length_squared(p.offset) > 0 { m = m * Math3D.translation(p.offset) }
                m = m * local
            } else if p.withOptions {
                let item = p.item
                let keepPosition = item.inheritPosition && item.influenceCoord != Influence.withOptionsNoPosition
                var origin = Math3D.position(keepPosition ? emitterWorld : p.spawnMatrix)
                if p.localFlight { origin = Math3D.point(emitterWorld, p.offset + p.localTravel) }
                let now = Math3D.decompose(emitterWorld)
                m = Math3D.compose(origin, item.inheritRotation ? now.rotation : identity, item.inheritScale ? now.scale : schema.revisedScale)
                if !p.localFlight && keepPosition && simd_length_squared(p.offset) > 0 { m = m * Math3D.translation(p.offset) }
                m = m * local
            } else {
                m = p.spawnMatrix * local
            }
            if simd_length_squared(p.travel) > 0 { m = Math3D.translation(p.travel) * m }

            if s.rotationBase == Base.moveDirectionBillboard {
                let parts = Math3D.decompose(m)
                if p.hasLastWorld {
                    let d = parts.position - p.lastWorld
                    if simd_length_squared(d) > 1e-10 { p.moveDirection = d }
                }
                if simd_length_squared(p.moveDirection) == 0 { p.moveDirection = simd_length_squared(p.velocity) > 0 ? p.velocity : Vec3(0, 1, 0) }
                p.lastWorld = parts.position
                p.hasLastWorld = true
                let zAxis = simd_normalize(camera.position - parts.position)
                var yAxis = p.moveDirection - zAxis * simd_dot(p.moveDirection, zAxis)
                if simd_length_squared(yAxis) < 1e-12 { yAxis = camera.rotation.act(Vec3(0, 1, 0)) }
                yAxis = simd_normalize(yAxis)
                let xAxis = simd_normalize(simd_cross(yAxis, zAxis))
                m = Math3D.compose(parts.position, Math3D.quaternion(x: xAxis, y: yAxis, z: zAxis), parts.scale)
            } else if billboard {
                let parts = Math3D.decompose(m)
                let fullRotation = s.type == ParticleKind.model || s.type == ParticleKind.lightModel || s.type == ParticleKind.disc || s.type == 14
                let roll = fullRotation ? Math3D.euler(localRotation, order: s.rotationOrder) : simd_quatf(angle: localRotation.z, axis: Vec3(0, 0, 1))
                var facing = camera.rotation
                if [Base.billboardAxisY, Base.cameraBillboardAxisY, Base.treeBillboard].contains(s.rotationBase) {
                    facing = simd_quatf(angle: atan2(camera.position.x - parts.position.x, camera.position.z - parts.position.z), axis: Vec3(0, 1, 0))
                }
                m = Math3D.compose(parts.position, facing * (hasInjection ? injection : identity) * roll, parts.scale)
            }
            if s.type == ParticleKind.laser {
                let length = Eval.withRandom(s.lineLength, s.lineLengthRandom, t, 1, p.seed.get(14))
                let width = Eval.withRandom(s.laserWidth, s.laserWidthRandom, t, 1, p.seed.get(16))
                m = laserMatrix(m, base: s.rotationBase, length: length, width: width, camera: camera.position, p)
            }
            if s.type == ParticleKind.decalRing {
                let width = Eval.withRandom(s.ringWidth, s.ringWidthRandom, t, 0, p.seed.get(14))
                GeometryBuilder.setRingRadii(shape, fan: s.ringFan, inner: 0.5 - width, outer: 0.5 + width)
            }
            if let disc = s.disc {
                let inner = disc.colorInner.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                let outer = disc.colorOuter.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                GeometryBuilder.setDisc(shape, countU: disc.countU, countV: disc.countV, shape: discShape(disc, t, p.seed), inner: inner, outer: outer)
            }
            if s.type == ParticleKind.decal || s.type == ParticleKind.decalRing {
                var parts = Math3D.decompose(m)
                if abs(parts.position.y - groundY) <= abs(parts.scale.y) / 2 {
                    parts.position.y = groundY
                    m = Math3D.compose(parts.position, parts.rotation, parts.scale)
                } else {
                    continue
                }
            }

            if let trail = p.trail, let line = s.polyline {
                if line.createType == 1 {
                    trail.historyFrames = Float(line.pointCount) / 2
                    trail.record(p.totalAge, Math3D.position(m))
                } else {
                    let length = Eval.curve(line.length, t, 1)
                    let count = max(2, line.pointCount)
                    trail.setPoints((0..<count).map { Math3D.point(m, Vec3(0, length * Float($0) / Float(count - 1), 0)) })
                }
                guard trail.drawable else { continue }
                func tint(_ c: RColor?) -> Vec4 { c.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1) }
                trail.build(camera: camera.position, width: Eval.curve(line.width, t, 1), begin: Eval.curve(line.widthBegin, t, 1),
                            center: Eval.curve(line.widthCenter, t, 1), end: Eval.curve(line.widthEnd, t, 1),
                            colors: PolylineColors(begin: tint(line.colorBegin), center: tint(line.colorCenter), end: tint(line.colorEnd),
                                                   edgeBegin: tint(line.colorEdgeBegin), edgeCenter: tint(line.colorEdgeCenter),
                                                   edgeEnd: tint(line.colorEdgeEnd)))
                m = matrix_identity_float4x4
            }

            var color = Eval.color(s.color, t, p.seed)
            color.w *= fadeNow
            if PreviewRules.isOn("revisedColor") {
                color.x *= schema.revisedColor.x
                color.y *= schema.revisedColor.y
                color.z *= schema.revisedColor.z
            }
            if p.item.influenceColor != 0 { color *= p.emitter.color }

            let mode = s.drawMode >= 9 && s.drawMode <= 12 ? s.drawMode - 8 : s.drawMode
            var draw = ParticleDraw(particle: s.index, geometry: shape, model: s.type == 14 ? matrix_identity_float4x4 : m, color: color)
            draw.order = s.drawPriority * 1000 + (mode == 0 || mode == 8 ? 500 : 0) + s.index
            draw.sequence = p.sequence
            if s.colorBegin != nil || s.colorEnd != nil {
                draw.colorBegin = s.colorBegin.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                draw.colorEnd = s.colorEnd.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
            }
            if let tc1 = s.tc1, tc1.textures.count > 1 {
                let n = Eval.curve(tc1.texN, t, 0) + Eval.curve(tc1.texNRandom, t, 0) * p.seed.get(15)
                draw.frame = min(tc1.textures.count - 1, max(0, Int(n.rounded(.down))))
            }
            let plainUv = s.type == ParticleKind.windmill || (s.type == ParticleKind.powder && s.simple == nil)
            let layers: [RTextureLayer?] = [s.tc1, s.tc2, s.distortion, s.tc3, s.tc4]
            for (slot, layer) in layers.enumerated() {
                if slot != 2 && plainUv { continue }
                guard let layer, layer.enabled, layer.uvSet >= 0, layer.uvSet < s.uvSets.count else { continue }
                let uv = s.uvSets[layer.uvSet]
                let scale = Eval.axes(uv.scale, t, 1, p.seed, 11)
                let scroll = Eval.axes(uv.scroll, t, 0, p.seed, 13)
                let rotation = (PreviewRules.isOn("uvRotationReversed") ? -1 : 1) * Eval.curve(uv.rotation, t)
                let c = cos(rotation), sn = sin(rotation)
                draw.uvMatrix[slot] = Vec4(scale.x * c, scale.x * sn, -scale.y * sn, scale.y * c)
                draw.uvOffset[slot] = SIMD2(scroll.x, scroll.y)
            }
            if let distortion = s.distortion, distortion.enabled { draw.distortPower = Eval.curve(distortion.power, t, 0) }
            if let palette = s.palette, palette.enabled {
                draw.paletteOffset = Eval.withRandom(palette.offset, palette.offsetRandom, t, 0, p.seed.get(13))
            }

            if let cloud = p.cloud {
                let parts = Math3D.decompose(m)
                let lineLength = Eval.withRandom(s.lineLength, s.lineLengthRandom, t, 1, p.seed.get(14))
                let sprites = cloud.render(frame: m, cameraRotation: camera.rotation, cameraPosition: camera.position, particleScale: parts.scale,
                                           pixelAngle: pixelAngle, lineLength: lineLength, revisedScale: schema.revisedScale)
                for sprite in sprites {
                    var copy = draw
                    copy.model = sprite.model
                    copy.spriteColor = sprite.color
                    copy.spriteCell = sprite.cell
                    copy.isSprite = true
                    draws.append(copy)
                }
            } else {
                draws.append(draw)
            }
        }
        return draws.enumerated().sorted {
            $0.element.order != $1.element.order ? $0.element.order < $1.element.order
                : $0.element.sequence != $1.element.sequence ? $0.element.sequence < $1.element.sequence : $0.offset < $1.offset
        }.map(\.element)
    }
}
