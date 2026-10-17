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
    var gradation: Float = 1
    var extra = Vec4.zero
}

struct LightDraw {
    var position: Vec3
    var color: Vec3
    var distance: Float
    var decay: Float
    var reach: Float = 0
    var point = false
}

struct DissolveState {
    var texture: Int
    var amount: Float
    var edge: Float
    var reverse: Bool
    var color = Vec3(1, 1, 1)
    var uvMatrix = Vec4(1, 0, 0, 1)
    var uvOffset = SIMD2<Float>(0, 0)
    var shaped = false
    var shape = 0
    var inverse = matrix_identity_float4x4
    var widths = Vec3.zero
    var colors = [Vec4](repeating: .zero, count: 3)
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
    var depthCentre: Vec3?
    var spriteColor = Vec4(1, 1, 1, 1)
    var spriteCell = Vec4(0, 0, 1, 1)
    var isSprite = false
    var order = 0
    var sequence = 0
    var parent = matrix_identity_float4x4
    var overScene = false
    var lit = 0
    var light = (direction: Vec3.zero, ambient: Vec3.zero, color: Vec3.zero)
    var pointLights: [LightDraw] = []
    var normalPower: Float = 1
    var pointLightType = 0
    var fresnelAxis = Vec4.zero
}

extension ParticleDraw {
    var worldBounds: (centre: Vec3, radius: Float)? {
        guard model == matrix_identity_float4x4, geometry.vertexCount > 0 else { return nil }
        var low = Vec3(repeating: .greatestFiniteMagnitude), high = Vec3(repeating: -.greatestFiniteMagnitude)
        let step = max(1, geometry.vertexCount / 64)
        for index in stride(from: 0, to: geometry.vertexCount, by: step) {
            let o = index * RenderGeometry.stride
            let point = Vec3(geometry.vertices[o], geometry.vertices[o + 1], geometry.vertices[o + 2])
            low = simd_min(low, point)
            high = simd_max(high, point)
        }
        return ((low + high) / 2, max(0.08, simd_length(high - low) * 0.5))
    }
}

private enum ParticleKind {
    static let powder = 1, windmill = 2, line = 3, laser = 4, model = 5, polyline = 6, quad = 8, decal = 10, decalRing = 11, disc = 12, lightModel = 13
}

private enum Base {
    static let x = 0, y = 1, z = 2, moveDirection = 3, billboardAxisY = 4, screenBillboard = 5, cameraBillboard = 6
    static let moveDirectionBillboard = 7, cameraBillboardAxisY = 8, treeBillboard = 9
}

private enum Influence {
    static let initialPosition = 0, withOptions = 1, allAlways = 2, allAlwaysNoPosition = 4, withOptionsNoPosition = 7, unknown = 8, unknownNoPosition = 9

    static func noPosition(_ coord: Int) -> Bool {
        (coord == allAlwaysNoPosition || coord == 5 || coord == withOptionsNoPosition || coord == unknownNoPosition) && PreviewRules.isOn("noPositionGround")
    }

    static func follows(_ coord: Int) -> Bool {
        coord == allAlways || coord == allAlwaysNoPosition || ((coord == unknown || coord == unknownNoPosition) && PreviewRules.isOn("influenceUnknownFollows"))
    }
}

private func normalAxes(_ n: Vec3) -> (x: Vec3, y: Vec3, z: Vec3) {
    let z = simd_normalize(n)
    var y = Vec3(0, 1, 0) - z * z.y
    if simd_length_squared(y) < 1e-8 { y = Vec3(1, 0, 0) - z * z.x }
    y = simd_normalize(y)
    return (simd_cross(y, z), y, z)
}

private func normalBasis(_ n: Vec3) -> Mat4 {
    let axes = normalAxes(n)
    return Math3D.basis(axes.x, axes.y, axes.z)
}

private func flightFrame(_ v: Vec3, up: Vec3) -> simd_quatf {
    guard simd_length_squared(v) > 1e-12 else { return simd_quatf(angle: 0, axis: Vec3(0, 1, 0)) }
    let z = simd_normalize(v)
    var y = up - z * simd_dot(up, z)
    if simd_length_squared(y) < 1e-8 { y = Vec3(1, 0, 0) - z * z.x }
    y = simd_normalize(y)
    return Math3D.quaternion(x: simd_cross(y, z), y: y, z: z)
}

private func unitVector(_ value: Vec3, _ fallback: Vec3) -> Vec3 {
    let length = simd_length(value)
    return length > 1e-6 && length.isFinite ? value / length : fallback
}

private func lifeFrames(_ value: Float, _ random: Float, _ seed: Float, type: Int = 0) -> Float {
    if value < 0 { return .infinity }
    let type = PreviewRules.isOn("lifeRandomType") ? type : 0
    let offset: Float = type == 1 || type == 4 ? random * seed : type == 2 || type == 5 ? -random * seed : random * (seed * 2 - 1)
    return max(1, value + offset)
}

final class EmitterInstance {
    let schema: REmitter
    let anchor: () -> Mat4
    var age: Float = 0
    var totalAge: Float = 0
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
    var instance: TimelineStart?
    var dying: (from: Float, frames: Float)?
    var parent: EmitterInstance?
    var injected: [Int: Int] = [:]
    var velocity = Vec3.zero
    var travel = Vec3.zero
    var fall: Float = 0
    var moving = false
    var holdWhile: (() -> Bool)?
    var liveChildren = 0
    var binder = -1
    var effectorOverride: Int?
    var timeScale: Float = 1
    var colorFrom: (mode: Int, initial: Vec4)?
    var injectedChildren: [Int: Int] = [:]
    var cameraRotation: simd_quatf?
    var cameraPosition: Vec3?
    var born = false
    static var birthCreates = true
    static var pastLife = true
    static var ignoreEnabled = true
    private var firstSpawn: [Float] = []
    private var firstChild: [Float] = []

    init(schema: REmitter, anchor: @escaping () -> Mat4, endFrames: Float, random: inout SeededRandom) {
        self.schema = schema
        self.anchor = anchor
        seed = RandomSeed(&random, count: 40)
        var life = lifeFrames(schema.life.value, schema.life.random, seed.get(0), type: schema.life.randomType)
        if schema.life.value == 0, endFrames > 0, PreviewRules.isOn("emitterLifeZeroWindow") { life = .infinity }
        lifetime = min(life, endFrames > 0 ? endFrames : .infinity)
        let lifetime = lifetime
        let loops = schema.loopEnd > schema.loopStart && schema.loopStart >= 0
        let last = PreviewRules.isOn("createTimeLast")
        func first(_ item: REmitterItem) -> Float {
            let start = Float(max(0, item.generateDelay))
            guard last, item.createTime == 2, lifetime.isFinite, !loops else { return start }
            let interval = Eval.curve(schema.createInterval, CurveTime(0), 0)
            return interval > 0 ? max(start, ((lifetime - 1) / interval).rounded(.down) * interval) : start
        }
        nextSpawn = schema.particleItems.map(first)
        nextChild = schema.emitterItems.map(first)
        firstSpawn = nextSpawn
        firstChild = nextChild
    }

    var delayPending: Bool {
        guard !stopped, EmitterInstance.pastLife else { return false }
        return zip(nextSpawn, firstSpawn).contains { $0 == $1 && $0 >= lifetime && $0 < 600 }
            || zip(nextChild, firstChild).contains { $0 == $1 && $0 >= lifetime && $0 < 600 }
    }

    var alive: Bool { age < lifetime || (holdWhile?() ?? false) }
    var loops: Bool { schema.loopEnd > schema.loopStart && schema.loopStart >= 0 }

    var curveTime: CurveTime { PreviewRules.isOn("emitterPeriodicCurves") ? CurveTime(age, total: totalAge) : CurveTime(age) }

    func matrix(for seed: RandomSeed) -> Mat4 {
        let time = curveTime
        let position = Eval.axes(schema.position, time, 0, seed, 1)
        let rotation = Eval.axes(schema.rotation, time, 0, seed, 4)
        let scale = Eval.axes(schema.scale, time, 1, seed, 8)
        var out = anchor() * Math3D.compose(position, Math3D.euler(rotation, order: schema.rotationOrder), scale,
                                            order: PreviewRules.isOn("coordComputeOrder") ? schema.coordOrder : 0)
        if let cameraRotation, schema.rotationBase == Base.cameraBillboardAxisY, PreviewRules.isOn("emitterCameraBillboard") {
            let parts = Math3D.decompose(out)
            out = Math3D.compose(parts.position, cameraRotation * Math3D.euler(rotation, order: schema.rotationOrder), parts.scale)
        } else if PreviewRules.isOn("emitterBillboards") {
            let base = schema.rotationBase
            let own = Math3D.euler(rotation, order: schema.rotationOrder)
            if let cameraRotation, base == Base.screenBillboard || base == Base.cameraBillboard {
                let parts = Math3D.decompose(out)
                out = Math3D.compose(parts.position, cameraRotation * own, parts.scale)
            } else if let cameraPosition, base == Base.billboardAxisY || base == Base.treeBillboard {
                let parts = Math3D.decompose(out)
                let yaw = simd_quatf(angle: atan2(cameraPosition.x - parts.position.x, cameraPosition.z - parts.position.z), axis: Vec3(0, 1, 0))
                out = Math3D.compose(parts.position, yaw * own, parts.scale)
            } else if base == Base.moveDirection || base == Base.moveDirectionBillboard, moving {
                let motion = velocity * Eval.curve(schema.airResistance, CurveTime(age), 1) + Vec3(0, fall, 0)
                if simd_length_squared(motion) > 1e-10 {
                    let parts = Math3D.decompose(out)
                    let z = simd_normalize(motion)
                    let x = simd_normalize(simd_cross(abs(z.y) > 0.999 ? Vec3(1, 0, 0) : Vec3(0, 1, 0), z))
                    out = Math3D.compose(parts.position, Math3D.quaternion(x: x, y: simd_cross(z, x), z: z) * own, parts.scale)
                }
            }
        }
        if moving { out = Math3D.translation(travel) * out }
        return out
    }

    private lazy var randomFree = [schema.position, schema.rotation, schema.scale].allSatisfy { $0.rx == nil && $0.ry == nil && $0.rz == nil }
    private var passMatrix: (pass: Int, matrix: Mat4)?

    func matrix(for seed: RandomSeed, pass: Int) -> Mat4 {
        guard randomFree else { return matrix(for: seed) }
        if let passMatrix, passMatrix.pass == pass { return passMatrix.matrix }
        let result = matrix(for: seed)
        passMatrix = (pass, result)
        return result
    }

    func updateTransform() {
        world = matrix(for: seed)
        color = Eval.color(schema.color, curveTime, seed)
        if let colorFrom { color *= colorFrom.mode == 2 ? parent?.color ?? colorFrom.initial : colorFrom.initial }
    }

    private var ordered: Bool { [1, 3, 5, 7].contains(schema.generateMethod) }
    private var onVertex: Bool { [2, 3, 6, 7].contains(schema.generateMethod) }

    private func shapeAngles(_ random: inout SeededRandom) -> Vec3 {
        let at = CurveTime(age)
        let spread = PreviewRules.isOn("emitterShapeRandom")
        var out = Vec3.zero
        for k in 0..<3 {
            let c = schema.coneRotation[k]
            out[k] = Eval.curve(c, at, 0)
            if spread, let r = schema.coneRotationRandom[k] { out[k] += Eval.randomOffset(r, type: c?.random ?? 0, at, random.next()) }
        }
        return out
    }

    func injectionTurn(_ point: EmitPoint?, _ seed: (Int) -> Float) -> simd_quatf? {
        let any = schema.anyDirection
        guard PreviewRules.isOn(any ? "emitterInjectionAngle" : "emitterVelocityAngle") else { return nil }
        let at = CurveTime(age)
        var a = Vec3.zero
        for k in 0..<3 {
            let c = any ? schema.injectAngles[k] : schema.velocityRandom[k]
            a[k] = Eval.curve(c, at, 0) + (any ? Eval.randomOffset(schema.injectAnglesRandom[k], type: c?.random ?? 0, at, seed(k)) : 0)
        }
        guard a != .zero else { return nil }
        let turn = Math3D.euler(a, order: schema.rotationOrder)
        guard any, let point, simd_length_squared(point.normal) >= 1e-8 else { return turn }
        let axes = normalAxes(point.normal)
        let frame = Math3D.quaternion(x: axes.x, y: axes.y, z: axes.z)
        return frame * turn * frame.inverse
    }

    func nextPoint(_ random: inout SeededRandom) -> EmitPoint? {
        guard let p = shapePoint(&random) else { return nil }
        let t = schema.type
        guard PreviewRules.isOn("shapeAngles"), t == 2 || t == 3 || t == 4 || t == 5 else { return p }
        let angles = shapeAngles(&random)
        guard angles != .zero else { return p }
        let q = Math3D.euler(angles, order: schema.dataRotationOrder)
        return EmitPoint(position: q.act(p.position), normal: q.act(p.normal))
    }

    private func shapePoint(_ random: inout SeededRandom) -> EmitPoint? {
        if schema.type == 2, PreviewRules.isOn("coneModelRings"), !points.isEmpty {
            let point = points[ordered ? order % points.count : min(points.count - 1, Int(random.next() * Float(points.count)))]
            if ordered { order += 1 }
            let at = CurveTime(age)
            let r = Eval.curve(schema.radius, at, 1)
            var k: Float = 1
            if PreviewRules.isOn("emitterShapeRandom"), schema.radiusRandom != nil, r != 0 {
                k = 1 + Eval.randomOffset(schema.radiusRandom, type: schema.radius?.random ?? 0, at, random.next()) / r
            }
            return EmitPoint(position: onVertex ? point.position * k : .zero, normal: point.normal)
        }
        if (schema.type == 1 || schema.type == 2) && PreviewRules.isOn("coneEmitters") {
            let at = CurveTime(age)
            let half = max(0, Eval.curve(schema.coneAngle, at, 0) + Eval.curve(schema.coneAngleRandom, at, 0) * (random.next() * 2 - 1))
            let cosine = 1 - random.next() * (1 - cos(min(half, .pi)))
            let sine = (max(0, 1 - cosine * cosine)).squareRoot()
            let turn = random.next() * 2 * .pi
            let local = Vec3(sine * cos(turn), sine * sin(turn), cosine)
            let direction = simd_act(Math3D.euler(shapeAngles(&random), order: schema.dataRotationOrder), local)
            if schema.type == 1, PreviewRules.isOn("coneSizes") {
                let spread = PreviewRules.isOn("emitterShapeRandom")
                func size(_ c: RCurve?, _ r: RCurve?) -> Float {
                    guard spread, let r else { return Eval.curve(c, at, 0) }
                    return Eval.curve(c, at, 0) + Eval.randomOffset(r, type: c?.random ?? 0, at, random.next())
                }
                let inner = size(schema.innerSize, schema.innerSizeRandom), outer = size(schema.outerSize, schema.outerSizeRandom)
                return EmitPoint(position: direction * (inner + random.next() * (outer - inner)), normal: direction)
            }
            return EmitPoint(position: .zero, normal: direction)
        }
        guard !points.isEmpty else { return nil }
        let index: Int
        if ordered {
            index = order % points.count
            order += 1
        } else {
            index = min(points.count - 1, Int(random.next() * Float(points.count)))
        }
        if schema.type == 4 {
            let at = CurveTime(age)
            let radius = Eval.curve(schema.radius, at, 1), length = Eval.curve(schema.length, at, 0)
            let point = points[index]
            return EmitPoint(position: Vec3(point.position.x * radius, point.position.y * length, point.position.z * radius), normal: point.normal)
        }
        if schema.type == 5, !onVertex, PreviewRules.isOn("modelToVertexFromCentre") { return EmitPoint(position: .zero, normal: points[index].normal) }
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
        let open = alive
        let birthCreates = EmitterInstance.birthCreates
        let pastLife = EmitterInstance.pastLife
        let firsts = particles ? firstSpawn : firstChild
        guard !stopped, open || birthCreates || pastLife else { return out }
        for i in items.indices {
            let item = items[i]
            if !item.enabled && !EmitterInstance.ignoreEnabled {
                next[i] = .infinity
                continue
            }
            var guardCount = 0
            while age >= next[i] && guardCount < limit
                    && (open || (birthCreates && next[i] < lifetime) || (pastLife && i < firsts.count && next[i] == firsts[i] && next[i] < 600)) {
                guardCount += 1
                let at = CurveTime(next[i])
                let single = item.createTime == 1 || (item.createTime == 2 && PreviewRules.isOn("createTimeLast"))
                let perItem = single ? max(0, item.createCount) : 1
                let base = Eval.curve(schema.createCount, at, 1)
                    + Eval.randomOffset(schema.createCountRandom, type: schema.createCount?.random ?? schema.createCountRandom?.random ?? 0, at, random.next())
                let once = single && PreviewRules.isOn("createOnceOwnCount")
                let count = once ? min(perItem, 4000) : min(Int(safe: base.rounded(), in: 0...4000) * perItem, 4000)
                if count > 0 { out.append((item, count)) }
                let interval = Eval.curve(schema.createInterval, at, 0)
                    + Eval.randomOffset(schema.createIntervalRandom, type: schema.createInterval?.random ?? schema.createIntervalRandom?.random ?? 0, at, random.next())
                let step = PreviewRules.isOn("createIntervalWholeFrame") ? max(interval, 1) : interval
                next[i] = interval > 0 && item.createTime == 0 ? next[i] + step : .infinity
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
    var geometry: RenderGeometry?
    var modelPick = -1
    let cloud: SpriteCloud?
    var trail: PolylineTrail?
    let seed: RandomSeed
    let emitterSeed: RandomSeed
    var bornColor: Vec4?
    var dying: (from: Float, frames: Float)?
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
    var link: RParticle?
    var linkSeed: RandomSeed
    var normalFrame: Mat4?
    var injectTurn: Mat4?
    var stuck: Vec3?
    var discCopies: [(geometry: RenderGeometry, seed: RandomSeed)] = []
    var lagPosition: Vec3?
    var lagTime: Float = 0
    var launch = (velocity: Vec3.zero, local: Vec3.zero)
    var spin: (launch: Vec3, launchLocal: Vec3, fall: Vec3, frame: simd_quatf, frameLocal: simd_quatf)?

    init(schema: RParticle, item: REmitterItem, emitter: EmitterInstance, geometry: RenderGeometry?, cloud: SpriteCloud?, sequence: Int,
         random: inout SeededRandom) {
        self.schema = schema
        self.item = item
        self.emitter = emitter
        self.geometry = geometry
        self.cloud = cloud
        self.sequence = sequence
        seed = RandomSeed(&random, count: 40)
        emitterSeed = RandomSeed(&random)
        linkSeed = RandomSeed(&random)
        var life = item.overrideLife
            ? lifeFrames(item.overrideLifeValue, item.overrideLifeRandom, seed.get(0))
            : lifeFrames(schema.life.value, schema.life.random, seed.get(0), type: schema.life.randomType)
        if item.inheritParentLife, PreviewRules.isOn("inheritParentLife") { life = max(1, emitter.lifetime - emitter.age) }
        lifetime = life
        let own = schema.life.value
        timeScale = item.overrideLife && own > 0 && life.isFinite ? own / life : 1
        follow = Influence.follows(item.influenceCoord)
        withOptions = item.influenceCoord == Influence.withOptions || item.influenceCoord == Influence.withOptionsNoPosition
        spawnMatrix = PreviewRules.isOn("emitterRandomOnce") ? emitter.world : emitter.matrix(for: emitterSeed)
    }

    var alive: Bool { age < lifetime || (cloud != nil && cloud?.finished == false) }
    var curveTime: CurveTime { CurveTime(age * timeScale, total: totalAge * timeScale) }
    var loops: Bool { schema.loopEnd > schema.loopStart && schema.loopStart >= 0 }
}

final class TimelineStart {
    let index: Int
    var at: Float
    let source: TimelineSource?
    var spawned: Set<Int> = []
    var released = false

    init(index: Int, at: Float, source: TimelineSource?) {
        self.index = index
        self.at = at
        self.source = source
    }
}

final class AvfxSimulation {
    static var skeletonBindPoints: [Int: Vec3]?
    static var skeletonLines: [(Vec3, Vec3)] = []
    static var physicsLines: [(Vec3, Vec3)] = []
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
    private var startedItems: Set<Int> = []
    private var timelineStarts: [TimelineStart] = []
    var events: [PreviewEvent] = []
    private var appliedEvents: Set<UUID> = []
    private var pendingRestart = false
    private var epoch: Float = 0
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
        startedItems = []
        appliedEvents = []
        released = false
        epoch = 0
        time = 0
        sequence = 0
        random = SeededRandom(seed: seed)
        clipLog = []
        soundCues = []
        fadeIns = []
    }

    var soundCues: [(emitter: EmitterInstance, path: String, index: Int)] = []

    private func cueSound(_ e: EmitterInstance) {
        guard e.schema.soundIndex >= 0, !e.schema.sound.isEmpty else { return }
        soundCues.append((e, e.schema.sound, e.schema.soundIndex))
    }

    func release() { released = true }

    private func itemRuns(_ index: Int) -> Bool { index < 32 || !PreviewRules.isOn("timelineItemLimit") }

    func stop() {
        for e in emitters where e.dying == nil {
            e.dying = (time, 0)
            e.stopped = true
        }
        for p in particles where p.dying == nil { p.dying = (time, 0) }
        timelineStarts = []
        startedItems = Set(schema.scheduler.indices)
        released = true
    }

    private func isReleased(_ e: EmitterInstance) -> Bool { released || (e.instance?.released ?? false) }

    @discardableResult
    func trigger(_ n: Int) -> Bool {
        guard n >= 0, n < schema.triggers.count else { return false }
        let t = schema.triggers[n]
        guard t.enabled, t.timeline >= 0, t.timeline < schema.timelines.count, timelineStarts.count < 256 else { return false }
        timelineStarts.append(TimelineStart(index: t.timeline, at: time + Float(t.start), source: .trigger(n)))
        return true
    }

    func applyEvents() {
        for event in events where !appliedEvents.contains(event.id) && Double(time) >= event.frame - 0.001 {
            appliedEvents.insert(event.id)
            switch event.kind {
            case .trigger(let index): trigger(index)
            case .release: release()
            case .stop: stop()
            }
        }
    }

    func advance(_ frames: Float) {
        applyEvents()
        time += frames
        step(frames)
        if pendingRestart {
            pendingRestart = false
            emitters = []
            particles = []
            timelineStarts = []
            startedItems = []
            released = false
            epoch = time
        }
    }

    private func fade(_ dying: (from: Float, frames: Float)?) -> Float {
        guard let dying else { return 1 }
        return dying.frames > 0 ? max(0, 1 - (time - dying.from) / dying.frames) : 0
    }

    private var emittersDone: Bool {
        let allStarted = schema.scheduler.enumerated().allSatisfy { !$0.element.enabled || $0.element.timeline < 0 || startedItems.contains($0.offset) }
            && !events.contains { !appliedEvents.contains($0.id) }
        let allSpawned = timelineStarts.allSatisfy { start in
            guard start.index >= 0, start.index < schema.timelines.count else { return true }
            return schema.timelines[start.index].items.enumerated().allSatisfy { !$0.element.enabled || !itemRuns($0.offset) || start.spawned.contains($0.offset) }
        }
        return allStarted && allSpawned && emitters.isEmpty
    }

    var finished: Bool { emittersDone && particles.isEmpty }

    var held: Bool {
        emitters.contains { !isReleased($0) && ($0.holdWhile != nil || $0.loops || $0.lifetime == .infinity) }
            || particles.contains { !isReleased($0.emitter) && ($0.loops || $0.lifetime == .infinity) }
    }

    private func targets(_ clip: RClip) -> Set<Int>? {
        let sources = clip.ints.dropFirst().compactMap(TimelineSource.init(target:))
        guard !sources.isEmpty else { return nil }
        return Set(sources.compactMap { source -> Int? in
            switch source {
            case .scheduler(let index): return index < schema.scheduler.count ? schema.scheduler[index].timeline : nil
            case .trigger(let index): return index < schema.triggers.count ? schema.triggers[index].timeline : nil
            }
        }.filter { $0 >= 0 })
    }

    private func matches(_ instance: TimelineStart?, _ targets: Set<Int>?) -> Bool {
        guard let targets else { return true }
        return (instance?.index).map(targets.contains) == true
    }

    private func runKill(_ clip: RClip, from start: TimelineStart) {
        let frames = Float(max(0, clip.ints[0]))
        let targets = targets(clip)
        for e in emitters where e.dying == nil && matches(e.instance, targets) {
            e.dying = (time, frames)
            e.stopped = true
        }
        for p in particles where p.dying == nil && matches(p.emitter.instance, targets) { p.dying = (time, frames) }
        timelineStarts.removeAll { $0 !== start && matches($0, targets) }
    }

    private func unlock(_ clip: RClip) {
        guard let targets = targets(clip) else {
            release()
            return
        }
        for start in timelineStarts where matches(start, targets) { start.released = true }
        for e in emitters where matches(e.instance, targets) { e.instance?.released = true }
    }

    func timelineStates() -> [Int: String] {
        var states: [Int: String] = [:]
        func rank(_ state: String) -> Int { ["playing": 1, "released": 2, "held": 3, "fading": 4][state] ?? 0 }
        func note(_ timeline: Int, _ state: String) {
            guard timeline >= 0 else { return }
            if rank(state) > rank(states[timeline] ?? "") { states[timeline] = state }
        }
        for start in timelineStarts where start.index >= 0 && start.index < schema.timelines.count {
            let pending = schema.timelines[start.index].items.indices.contains { !start.spawned.contains($0) && schema.timelines[start.index].items[$0].enabled && itemRuns($0) }
            if pending { note(start.index, start.released || released ? "released" : "playing") }
        }
        for e in emitters {
            if e.dying != nil {
                note(e.timeline, "fading")
            } else if !isReleased(e) && (e.holdWhile != nil || e.loops || e.lifetime == .infinity) {
                note(e.timeline, "held")
            } else {
                note(e.timeline, isReleased(e) ? "released" : "playing")
            }
        }
        for p in particles {
            if p.dying != nil {
                note(p.emitter.timeline, "fading")
            } else if !isReleased(p.emitter) && (p.loops || p.lifetime == .infinity) {
                note(p.emitter.timeline, "held")
            } else {
                note(p.emitter.timeline, "playing")
            }
        }
        return states
    }

    private var fadeIns: [(targets: Set<Int>?, from: Float, frames: Float)] = []

    private func fadeIn(_ e: EmitterInstance) -> Float {
        var k: Float = 1
        for f in fadeIns where matches(e.instance, f.targets) {
            k *= f.frames > 0 ? min(1, max(0, (time - f.from) / f.frames)) : 1
        }
        return k
    }

    private func restartTimeline(_ index: Int) {
        guard index >= 0, index < schema.timelines.count else { return }
        let dropped = Set(timelineStarts.filter { $0.index == index }.map { ObjectIdentifier($0) })
        emitters.removeAll { $0.instance.map { dropped.contains(ObjectIdentifier($0)) } ?? false }
        particles.removeAll { $0.emitter.instance.map { dropped.contains(ObjectIdentifier($0)) } ?? false }
        let source = timelineStarts.first { $0.index == index }?.source
        timelineStarts.removeAll { $0.index == index }
        timelineStarts.append(TimelineStart(index: index, at: time, source: source))
    }

    private lazy var effectorCarrier = REmitter(index: -1, type: 0, loopStart: 0, loopEnd: 0, childLimit: 0, rotationBase: 2, rotationOrder: 0,
                                                life: RLife(), color: RColor(), position: RCurve3(), rotation: RCurve3(), scale: RCurve3(),
                                                particleItems: [], emitterItems: [], modelIndex: -1, generateMethod: 0, divideX: 1, divideY: 1)

    func effectorIndex(_ e: EmitterInstance) -> Int? {
        if let override = e.effectorOverride { return override }
        guard e.schema.index >= 0, e.schema.index < schema.emitterEffectors.count else { return nil }
        let index = schema.emitterEffectors[e.schema.index]
        return index >= 0 && index < schema.effectors.count ? index : nil
    }

    private func runClip(_ clip: RClip, from start: TimelineStart) {
        clipLog.append((time, clip.type))
        switch clip.type {
        case "ULLP": unlock(clip)
        case "END ":
            emitters.forEach { $0.stopped = true }
            release()
        case "KILL": runKill(clip, from: start)
        case "REST":
            if PreviewRules.isOn("resetOneTimeline"), let targets = targets(clip) {
                for index in targets.sorted() { restartTimeline(index) }
            } else {
                pendingRestart = true
            }
        case "FADI":
            guard PreviewRules.isOn("fadeInClip") else { break }
            fadeIns.append((targets(clip), time, Float(max(0, clip.ints[0]))))
        case "TRG ": trigger(clip.ints[0])
        case "RTRG":
            let lo = min(clip.ints[0], clip.ints[1]), hi = max(clip.ints[0], clip.ints[1])
            trigger(lo + Int(random.next() * Float(hi - lo + 1)))
        default: break
        }
    }

    private func binderMatrix(_ index: Int) -> () -> Mat4 {
        let binder: RBinder? = index >= 0 && index < schema.binders.count ? schema.binders[index] : nil
        let core = binderCore(binder)
        guard let binder else { return cameraSpace(core) }
        var wrapped = core
        var scale = PreviewRules.isOn("vfxScaleBias") && !binder.ignoreVfxScale ? binder.vfxScaleBias : 1
        if binder.transformScale != 0, PreviewRules.isOn("binderTransformScale") {
            scale *= binder.bindPoint == 1 ? AvfxSimulation.targetScale : AvfxSimulation.casterScale
        }
        if scale != 1 {
            let inner = wrapped, scaling = Math3D.compose(.zero, simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), Vec3(repeating: scale))
            let revised = revisedMatrix
            let unrevised = revised.inverse
            wrapped = { inner() * unrevised * scaling * revised }
        }
        if schema.fitGround, PreviewRules.isOn("fitGround") {
            let inner = wrapped, ground = groundY
            wrapped = {
                var m = inner()
                m.columns.3.y = ground
                return m
            }
        }
        wrapped = cameraSpace(wrapped)
        if let spring = binder.spring, PreviewRules.isOn("binderSpring") {
            let inner = wrapped, born = time, randomPart = random.next()
            var position: Vec3?
            var stepped = time
            wrapped = { [weak self] in
                let m = inner()
                guard let self else { return m }
                let target = Math3D.position(m)
                guard var p = position else {
                    position = target
                    stepped = self.time
                    return m
                }
                while stepped + 0.5 <= self.time {
                    stepped += 0.5
                    let at = CurveTime(stepped - born)
                    let k = Eval.curve(spring, at, 1) + Eval.randomOffset(binder.springRandom, type: spring.random, at, randomPart)
                    p += (target - p) * min(max(k, 0), 2)
                }
                position = p
                var out = m
                out.columns.3 = Vec4(p.x, p.y, p.z, 1)
                return out
            }
        }
        var freeze = Float.infinity
        if binder.coordUpdate >= 0, PreviewRules.isOn("binderUpdateFrame") { freeze = Float(binder.coordUpdate) }
        if binder.life > 0, PreviewRules.isOn("binderLife") { freeze = min(freeze, Float(binder.life)) }
        if freeze.isFinite {
            let inner = wrapped, born = time
            var held: Mat4?
            wrapped = { [weak self] in
                if let held { return held }
                let m = inner()
                if let self, self.time - born >= freeze { held = m }
                return m
            }
        }
        return wrapped
    }

    static var casterScale: Float = 1
    static var targetScale: Float = 1

    private var revisedMatrix: Mat4 {
        let rotation = PreviewRules.isOn("revisedRotationNeedsAgs") && !schema.adjustGlobalScale ? Vec3.zero : schema.revisedRotation
        return Math3D.compose(schema.revisedPosition, Math3D.euler(rotation, order: 0), schema.revisedScale)
    }

    private func cameraSpace(_ inner: @escaping () -> Mat4) -> () -> Mat4 {
        guard schema.cameraSpace, PreviewRules.isOn("cameraSpace") else { return inner }
        return { [weak self] in
            guard let self else { return inner() }
            return Math3D.compose(self.cameraPosition, self.cameraRotation ?? simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1)) * inner()
        }
    }

    private func binderCore(_ binder: RBinder?) -> () -> Mat4 {
        let revised = revisedMatrix
        guard let binder else { return { revised } }
        if binder.type == 3, PreviewRules.isOn("cameraBinder") {
            let distance = binder.distance
            return { [weak self] in
                guard let self else { return matrix_identity_float4x4 }
                return Math3D.compose(self.cameraPosition, self.cameraRotation ?? simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1))
                    * Math3D.translation(Vec3(0, 0, Eval.curve(distance, CurveTime(self.time), 0))) * revised
            }
        }
        var object = bindPoint(onTarget: binder.bindPoint == 1, targetPoint: binder.bindTargetPoint, id: binder.bindPointId)
        if !binder.followTargetOrientation, PreviewRules.isOn("binderFollowTargetOrientation") { object = Math3D.translation(Math3D.position(object)) }
        if let goal = binder.goal, let carry = binder.carryOver, [1, 2, 4].contains(binder.type), PreviewRules.isOn("binderLinearPath") {
            let from = Math3D.position(object)
            let to = Math3D.position(bindPoint(onTarget: goal.bindPoint == 1, targetPoint: goal.targetPoint, id: goal.id))
            let turn = Math3D.decompose(object).rotation
            let path = binder.type == 2 && PreviewRules.isOn("splineBinderRings") ? splinePath(from, to, binder, carry) : nil
            let start = time
            return { [weak self] in
                let k = Eval.curve(carry, CurveTime((self?.time ?? start) - start), 0)
                let at = path?(k) ?? from + (to - from) * k
                return Math3D.compose(at, turn, Vec3(1, 1, 1)) * revised
            }
        }
        if (1...4).contains(binder.rotationType), PreviewRules.isOn("binderRotationType") {
            let kind = binder.rotationType, place = object
            return { [weak self] in
                guard let self else { return place * revised }
                let at = Math3D.position(place)
                let facing: simd_quatf
                switch kind {
                case 1: facing = self.cameraRotation ?? simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
                case 3:
                    let z = simd_normalize(self.cameraPosition - at + Vec3(0, 0, 1e-6))
                    let x = simd_normalize(simd_cross(abs(z.y) > 0.999 ? Vec3(1, 0, 0) : Vec3(0, 1, 0), z))
                    facing = Math3D.quaternion(x: x, y: simd_cross(z, x), z: z)
                default: facing = simd_quatf(angle: atan2(self.cameraPosition.x - at.x, self.cameraPosition.z - at.z), axis: Vec3(0, 1, 0))
                }
                return Math3D.compose(at, facing, Vec3(1, 1, 1)) * revised
            }
        }
        let result = object * revised
        guard PreviewRules.isOn("binderOffset") else { return { result } }
        let offset = binder.offset
        guard offset.x != nil || offset.y != nil || offset.z != nil else { return { result } }
        let base = object
        return { [weak self] in
            let at = CurveTime(self?.time ?? 0)
            return base * Math3D.translation(Vec3(Eval.curve(offset.x, at), Eval.curve(offset.y, at), Eval.curve(offset.z, at))) * revised
        }
    }

    private func splinePath(_ from: Vec3, _ to: Vec3, _ binder: RBinder, _ carry: RCurve) -> ((Float) -> Vec3)? {
        guard !binder.rings.isEmpty else { return nil }
        var flat = to - from
        flat.y = 0
        let forward = simd_length_squared(flat) > 1e-8 ? simd_normalize(flat) : Vec3(0, 0, 1)
        let up = Vec3(0, 1, 0), side = simd_normalize(simd_cross(up, forward))
        var points = [from], knots: [Float] = [0]
        for ring in binder.rings {
            var jitter = Vec3.zero
            if ring.radius > 0 {
                let a = random.next() * 2 * .pi, b = acos(random.next() * 2 - 1), r = ring.radius * cbrt(random.next())
                jitter = Vec3(sin(b) * cos(a), cos(b), sin(b) * sin(a)) * r
            }
            points.append(from + (to - from) * ring.position.z + side * ring.position.x + up * ring.position.y + jitter)
            knots.append(Eval.curve(carry, CurveTime(Float(ring.time)), 0))
        }
        points.append(to)
        knots.append(1)
        if zip(knots, knots.dropFirst()).contains(where: { $0 >= $1 }) { knots = (0..<points.count).map { Float($0) / Float(points.count - 1) } }
        let n = points.count
        func tangent(_ i: Int) -> Vec3 {
            let a = max(0, i - 1), b = min(n - 1, i + 1)
            return (points[b] - points[a]) / max(1e-5, knots[b] - knots[a])
        }
        return { u in
            if u <= knots[0] { return points[0] + tangent(0) * (u - knots[0]) }
            if u >= knots[n - 1] { return points[n - 1] + tangent(n - 1) * (u - knots[n - 1]) }
            var i = 0
            while i < n - 2 && u > knots[i + 1] { i += 1 }
            let span = knots[i + 1] - knots[i], f = (u - knots[i]) / span
            let f2 = f * f, f3 = f2 * f
            let h00 = 2 * f3 - 3 * f2 + 1, h10 = f3 - 2 * f2 + f, h01 = -2 * f3 + 3 * f2, h11 = f3 - f2
            return points[i] * h00 + tangent(i) * (h10 * span) + points[i + 1] * h01 + tangent(i + 1) * (h11 * span)
        }
    }

    static var targetPosition = Vec3(0, 0, 6)

    private func bindPoint(onTarget: Bool, targetPoint: Int, id: Int) -> Mat4 {
        var m = onTarget && PreviewRules.isOn("binderTarget")
            ? Math3D.compose(AvfxSimulation.targetPosition, simd_quatf(angle: .pi, axis: Vec3(0, 1, 0)), Vec3(1, 1, 1)) : matrix_identity_float4x4
        if useBindPoints, targetPoint == 3, let point = AvfxSimulation.bindPoints[id] { m = m * Math3D.translation(point) }
        return m
    }

    private var guides: [Int: [Vec3]] = [:]

    private func weaponLine(_ type: Int) -> (base: Vec3, tip: Vec3) {
        let points = AvfxSimulation.bindPoints
        let base = points[3] ?? Vec3(0.3, 0.85, 0.1), tip = points[5] ?? Vec3(0.3, 1.6, 0.1)
        guard type == 1 else { return (base, tip) }
        let hand = points[78] ?? Vec3(-base.x, base.y, base.z)
        let reach = tip - base
        return (hand, hand + Vec3(-reach.x, reach.y, reach.z))
    }

    private func connectEnd(_ e: EmitterInstance, reverse: Bool) -> Vec3 {
        var root = e
        while let up = root.parent { root = up }
        if root.binder >= 0, root.binder < schema.binders.count, PreviewRules.isOn("binderLinearPath") {
            let b = schema.binders[root.binder]
            if let goal = b.goal, [1, 2, 4].contains(b.type) {
                return Math3D.position(reverse ? bindPoint(onTarget: b.bindPoint == 1, targetPoint: b.bindTargetPoint, id: b.bindPointId)
                                       : bindPoint(onTarget: goal.bindPoint == 1, targetPoint: goal.targetPoint, id: goal.id))
            }
        }
        return reverse || !PreviewRules.isOn("binderTarget") ? .zero : AvfxSimulation.targetPosition
    }

    private func points(for model: Int) -> [EmitPoint] {
        if let cached = emitPoints[model] { return cached }
        let result = model >= 0 && model < schema.models.count ? GeometryBuilder.emitPoints(schema.models[model]) : []
        emitPoints[model] = result
        return result
    }

    private func setupShape(_ e: EmitterInstance) {
        let s = e.schema
        let startZ = PreviewRules.isOn("ringStartZ")
        switch s.type {
        case 5:
            e.points = points(for: s.modelIndex)
        case 2 where PreviewRules.isOn("coneModelRings"):
            let nx = max(1, s.divideX), ny = max(1, s.divideY)
            let r = Eval.curve(s.radius, CurveTime(0), 1), angle = Eval.curve(s.coneAngle, CurveTime(0), 0)
            for j in 1...ny {
                let theta = angle * Float(j) / Float(ny)
                for i in 0..<nx {
                    let a = Float(i) / Float(nx) * 2 * .pi
                    let normal = Vec3(sin(theta) * cos(a), sin(theta) * sin(a), cos(theta))
                    e.points.append(EmitPoint(position: normal * r, normal: normal))
                }
            }
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
                        directions.append(startZ ? Vec3(sin(theta) * sin(a), cos(theta), sin(theta) * cos(a)) : Vec3(sin(theta) * cos(a), cos(theta), sin(theta) * sin(a)))
                    }
                }
            }
            if poles { directions.append(Vec3(0, -1, 0)) }
            e.points = directions.map { EmitPoint(position: $0, normal: $0) }
        case 4:
            let nx = max(1, s.divideX), ny = max(0, s.divideY)
            for j in 0...ny {
                let y = ny > 0 ? Float(j) / Float(ny) - 0.5 : 0
                for i in 0..<nx {
                    let a = Float(i) / Float(nx) * 2 * .pi
                    let normal = startZ ? Vec3(sin(a), 0, cos(a)) : Vec3(cos(a), 0, sin(a))
                    e.points.append(EmitPoint(position: Vec3(normal.x, y, normal.z), normal: normal))
                }
            }
        default: break
        }
    }

    private func spawnEmitter(_ schema: REmitter, anchor: @escaping () -> Mat4, endFrames: Float, startAge: Float) -> EmitterInstance {
        let e = EmitterInstance(schema: schema, anchor: anchor, endFrames: endFrames, random: &random)
        e.cameraRotation = cameraRotation
        e.cameraPosition = cameraPosition
        setupShape(e)
        e.age = startAge < 0 && PreviewRules.isOn("binderGenerateDelay") ? startAge : max(0, startAge)
        e.totalAge = e.age
        e.born = true
        emitters.append(e)
        cueSound(e)
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
        if emitters.contains(where: { $0.dying != nil }) || particles.contains(where: { $0.dying != nil }) {
            emitters.removeAll { $0.dying != nil && fade($0.dying) <= 0 }
            for p in particles where p.dying != nil && fade(p.dying) <= 0 { p.emitter.liveChildren -= 1 }
            particles.removeAll { $0.dying != nil && fade($0.dying) <= 0 }
        }
        for (index, s) in schema.scheduler.enumerated() where s.enabled && s.timeline >= 0 && !startedItems.contains(index) && time - epoch >= Float(s.start) {
            startedItems.insert(index)
            timelineStarts.append(TimelineStart(index: s.timeline, at: epoch + Float(s.start), source: .scheduler(index)))
        }
        for start in Array(timelineStarts) {
            guard start.index >= 0, start.index < schema.timelines.count, timelineStarts.contains(where: { $0 === start }) else { continue }
            let timeline = schema.timelines[start.index]
            if timeline.loopEnd > timeline.loopStart, timeline.loopStart >= 0, !released, !start.released, PreviewRules.isOn("timelineLoop"),
               time - start.at >= Float(timeline.loopEnd) {
                start.at += Float(timeline.loopEnd - timeline.loopStart)
                for (i, item) in timeline.items.enumerated() where item.start >= timeline.loopStart { start.spawned.remove(i) }
            }
            let local = time - start.at
            for (i, item) in timeline.items.enumerated() where item.clip >= 0 && item.emitter < 0 {
                if !item.enabled || !itemRuns(i) || start.spawned.contains(i) || local < Float(item.start) { continue }
                start.spawned.insert(i)
                if item.clip < timeline.clips.count { runClip(timeline.clips[item.clip], from: start) }
            }
            for (i, item) in timeline.items.enumerated() {
                if !item.enabled || !itemRuns(i) || start.spawned.contains(i) || local < Float(item.start) { continue }
                start.spawned.insert(i)
                if item.clip >= 0, item.clip < timeline.clips.count { runClip(timeline.clips[item.clip], from: start) }
                let binder = item.binder >= 0 ? item.binder : timeline.binder
                let end: Float = item.end > item.start ? Float(item.end - item.start) : 0
                let delay = binder >= 0 && binder < schema.binders.count && PreviewRules.isOn("binderGenerateDelay") ? Float(schema.binders[binder].generateDelay) : 0
                if item.effector >= 0, item.effector < schema.effectors.count, PreviewRules.isOn("timelineEffectors") {
                    let carrier = spawnEmitter(effectorCarrier, anchor: binderMatrix(binder), endFrames: end, startAge: local - Float(item.start) - delay)
                    carrier.effectorOverride = item.effector
                    carrier.timeline = start.index
                    carrier.instance = start
                    carrier.binder = binder
                    if item.end < 0 { carrier.holdWhile = { [unowned self] in !self.released && !start.released } }
                }
                guard item.emitter >= 0, item.emitter < schema.emitters.count else { continue }
                let e = spawnEmitter(schema.emitters[item.emitter], anchor: binderMatrix(binder), endFrames: end, startAge: local - Float(item.start) - delay)
                e.timeline = start.index
                e.instance = start
                e.binder = binder
                if item.end < 0 { e.holdWhile = { [unowned self] in !self.released && !start.released } }
            }
        }

        var created: [EmitterInstance] = []
        var queue: [EmitterInstance] = []
        EmitterInstance.birthCreates = PreviewRules.isOn("emitterBirthNoAge")
        EmitterInstance.pastLife = PreviewRules.isOn("generateDelayPastLife")
        EmitterInstance.ignoreEnabled = PreviewRules.isOn("emitterItemsIgnoreEnabled")
        for e in emitters {
            if e.born && EmitterInstance.birthCreates {
                e.born = false
            } else {
                e.age += frames * e.timeScale
                e.totalAge += frames * e.timeScale
            }
            let loopStart = Float(e.schema.loopStart), loopEnd = Float(e.schema.loopEnd)
            if !isReleased(e), e.loops, e.age >= loopEnd { e.wrap(loopEnd - loopStart) }
            if e.moving { moveEmitter(e, frames) }
            e.cameraRotation = cameraRotation
            e.cameraPosition = cameraPosition
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
                if PreviewRules.isOn("heldOnce"), ps.loopEnd > ps.loopStart && ps.loopStart >= 0 { e.stopParticleItem(item.index) }
                let first = PreviewRules.isOn("injectionAnglePerCreation") ? e.injected[item.index] ?? 0 : 0
                e.injected[item.index] = first + count
                for n in 0..<count {
                    if random.next() * 100 >= Float(item.probability) { continue }
                    if PreviewRules.isOn("childLimit"), e.schema.childLimit > 0 && e.liveChildren >= e.schema.childLimit { break }
                    if particles.count >= maxParticles { break }
                    particles.append(spawnParticle(ps, item, e, copyIndex: first + n))
                    e.liveChildren += 1
                }
            }
            for (item, count) in e.due(particles: false, limit: 8, random: &random) {
                guard item.target >= 0, item.target < schema.emitters.count else { continue }
                let child = schema.emitters[item.target]
                let itemProps = PreviewRules.isOn("childEmitterItemProps")
                let firstChild = PreviewRules.isOn("injectionAnglePerCreation") ? e.injectedChildren[item.index] ?? 0 : 0
                e.injectedChildren[item.index] = firstChild + count
                for n in 0..<count {
                    guard emitters.count + created.count < 2000 else { break }
                    if itemProps {
                        if random.next() * 100 >= Float(item.probability) { continue }
                        if e.schema.childLimit > 0,
                           emitters.filter({ $0.parent === e && $0.alive }).count + created.filter({ $0.parent === e }).count >= e.schema.childLimit { break }
                    }
                    let point = e.nextPoint(&random)
                    let turn = e.injectionTurn(point) { _ in self.random.next() }
                    let k = PreviewRules.isOn("injectionAngleChildEmitters") ? firstChild + n : 0
                    let byAngle: Mat4? = k != 0 && item.injectionAngle != .zero ? Mat4(Math3D.euler(item.injectionAngle * Float(k), order: child.rotationOrder)) : nil
                    var at: Mat4?
                    if point != nil || turn != nil || byAngle != nil {
                        var m = Math3D.translation(point?.position ?? .zero)
                        if let byAngle { m = byAngle * m }
                        if let turn { m = m * Mat4(turn) }
                        if let point, e.schema.type == 4, PreviewRules.isOn("cylinderPointFrame") {
                            m = m * Math3D.rotationY(atan2(point.normal.x, point.normal.z))
                        } else if let point, item.localDirection == 1, simd_length_squared(point.normal) > 1e-8, PreviewRules.isOn("localDirectionChildEmitters") {
                            m = m * normalBasis(point.normal)
                        }
                        at = m
                    }
                    let follow = Influence.follows(item.influenceCoord)
                    let withOptions = item.influenceCoord == Influence.withOptions || item.influenceCoord == Influence.withOptionsNoPosition
                    var fixed = at.map { e.world * $0 } ?? e.world
                    if itemProps, item.influenceCoord == Influence.initialPosition {
                        fixed = Math3D.compose(Math3D.position(fixed), simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), schema.revisedScale)
                    }
                    let spawnFrame = fixed
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
                        anchor = { spawnFrame }
                    }
                    let grounded: () -> Mat4
                    if Influence.noPosition(item.influenceCoord) {
                        let inner = anchor, ground = groundY
                        grounded = {
                            var m = inner()
                            m.columns.3.y = ground
                            return m
                        }
                    } else {
                        grounded = anchor
                    }
                    let inheritLife = item.inheritParentLife && e.lifetime.isFinite && PreviewRules.isOn("inheritParentLife")
                    let c = EmitterInstance(schema: child, anchor: grounded, endFrames: inheritLife ? max(1, e.lifetime - e.age) : 0, random: &random)
                    if item.generateDelayByOne && item.generateDelay > 0 { c.age = -Float(n * item.generateDelay); c.totalAge = c.age }
                    c.timeline = e.timeline
                    c.instance = e.instance
                    c.binder = e.binder
                    if itemProps {
                        if item.overrideLife, child.life.value > 0 {
                            c.timeScale = child.life.value / max(1, item.overrideLifeValue + item.overrideLifeRandom * (random.next() * 2 - 1))
                        }
                        if item.influenceColor != 0 { c.colorFrom = (item.influenceColor, e.color) }
                        if item.startFrame > 0, !item.startFrameNullUpdate {
                            c.age += Float(item.startFrame)
                            c.totalAge += Float(item.startFrame)
                        }
                    }
                    c.parent = e
                    c.cameraRotation = cameraRotation
                    c.cameraPosition = cameraPosition
                    if let point {
                        let speed = injectionSpeed(e) * revisedSpeedScale
                        if speed != 0 {
                            c.velocity = Math3D.direction(e.world, turn?.act(point.normal) ?? point.normal) * speed
                            c.moving = true
                        }
                    }
                    if item.inheritParentVelocity, e.moving, PreviewRules.isOn("inheritParentVelocity") {
                        c.velocity += e.velocity
                        c.moving = true
                    }
                    setupShape(c)
                    c.updateTransform()
                    cueSound(c)
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
        emitters.removeAll { !$0.alive && !fresh.contains(ObjectIdentifier($0)) && !carriers.contains(ObjectIdentifier($0)) && !$0.delayPending }

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
            if !isReleased(p.emitter), p.loops, p.age >= loopEnd { p.age -= loopEnd - loopStart }
        }
        if PreviewRules.isOn("releasedEndlessEnd") {
            for p in particles where p.dying == nil && p.lifetime == .infinity && isReleased(p.emitter) && !p.emitter.alive { p.dying = (time, 0) }
        }
        for p in particles where !p.alive { p.emitter.liveChildren -= 1 }
        particles.removeAll { !$0.alive }
    }

    private func moveEmitter(_ e: EmitterInstance, _ frames: Float) {
        let at = CurveTime(e.age)
        let s = e.schema
        let spread = PreviewRules.isOn("emitterMotionRandom")
        let gravity = Eval.curve(s.gravity, at, 0) + (spread ? Eval.randomOffset(s.gravityRandom, type: s.gravity?.random ?? 0, at, e.seed.get(13)) : 0)
        let scale = Eval.curve(s.airResistance, at, 1) + (spread ? Eval.randomOffset(s.airResistanceRandom, type: s.airResistance?.random ?? 0, at, e.seed.get(14)) : 0)
        e.fall += gravity * frames
        e.travel.y += e.fall * frames
        e.travel += e.velocity * scale * frames
    }

    private func move(_ p: ParticleInstance, _ frames: Float) {
        let s = p.schema
        let t = p.curveTime
        let gravity = Eval.curve(s.gravity, t, 0)
            + (PreviewRules.isOn("gravityRandom") ? Eval.randomOffset(s.gravityRandom, type: s.gravity?.random ?? 0, t, p.seed.get(25)) : 0)
        if (s.rotVelX != nil || s.rotVelY != nil || s.rotVelZ != nil) && PreviewRules.isOn("rotationVelocityTurnsFlight") {
            if p.spin == nil {
                p.spin = (p.velocity, p.localVelocity, .zero, flightFrame(p.velocity, up: Math3D.direction(p.spawnMatrix, Vec3(0, 1, 0))),
                          flightFrame(p.localVelocity, up: Vec3(0, 1, 0)))
            }
            let spinRandom = PreviewRules.isOn("rotationVelocityRandom")
            func turn(_ c: RCurve?, _ r: RCurve?, _ slot: Int) -> Float { spinRandom ? Eval.withRandom(c, r, t, 0, p.seed.get(slot)) : Eval.curve(c, t) }
            let angles = Vec3(turn(s.rotVelX, s.rotVelRandom[0], 20), turn(s.rotVelY, s.rotVelRandom[1], 21), turn(s.rotVelZ, s.rotVelRandom[2], 22))
            let q = Math3D.euler(angles, order: [5, 3, 4, 1, 2, 0][min(max(s.rotationOrder, 0), 5)])
            if var spin = p.spin {
                spin.fall.y += gravity * frames
                p.velocity = simd_length_squared(spin.launch) > 0 ? (spin.frame * q * spin.frame.inverse).act(spin.launch) + spin.fall : spin.fall
                if simd_length_squared(spin.launchLocal) > 0 { p.localVelocity = (spin.frameLocal * q * spin.frameLocal.inverse).act(spin.launchLocal) }
                p.spin = spin
            }
        } else if gravity != 0 {
            p.velocity.y += gravity * frames
        }
        let scale = Eval.curve(s.airResistance, t, 1) + Eval.randomOffset(s.airResistanceRandom, type: s.airResistance?.random ?? 0, t, p.seed.get(12))
        if p.localFlight && simd_length_squared(p.localVelocity) > 0 { p.localTravel += p.localVelocity * scale * frames }
        if simd_length_squared(p.velocity) == 0 { return }
        p.travel += p.velocity * scale * frames
    }

    static var skinMesh: MeshData?
    static var skinTargets = 1 | 8
    static var skinToken = 0
    private var skinToken = -1

    private func model(_ index: Int) -> RenderGeometry? {
        if let cached = modelGeometry[index] { return cached }
        guard index >= 0, index < schema.models.count, let built = GeometryBuilder.model(schema.models[index]) else { return nil }
        modelGeometry[index] = built
        return built
    }

    private func modelChoice(_ ps: RParticle, _ seed: Float) -> Int? {
        let list = ps.modelIndices
        guard list.count > 1, ps.modelRandom.count > 0, ps.morph == nil, ps.animationNumber == nil, PreviewRules.isOn("modelNumberRandom") else { return nil }
        return min(Int(seed * Float(ps.modelRandom.count + 1)), ps.modelRandom.count) % list.count
    }

    private func morphTargets(_ ps: RParticle) -> [RenderGeometry]? {
        guard ps.morph != nil, ps.modelIndices.count > 1, PreviewRules.isOn("modelMorph") else { return nil }
        let targets = ps.modelIndices.compactMap { model($0) }
        guard targets.count == ps.modelIndices.count, let first = targets.first,
              targets.allSatisfy({ $0.vertices.count == first.vertices.count }) else { return nil }
        return targets
    }

    private func morph(_ p: ParticleInstance, _ t: CurveTime) {
        guard let shape = p.geometry, let curve = p.schema.morph, let targets = morphTargets(p.schema) else { return }
        let raw = Eval.curve(curve, t, 0)
        let m = PreviewRules.isOn("morphExtrapolates") ? raw : min(max(raw, 0), Float(targets.count - 1))
        let k = min(max(Int(m.rounded(.down)), 0), targets.count - 2), f = m - Float(k)
        let key = "\(k)|\(f)"
        guard shape.cacheKey != key else { return }
        shape.cacheKey = key
        let a = targets[k].vertices, b = targets[k + 1].vertices
        let stride = RenderGeometry.stride
        for v in 0..<shape.vertexCount {
            let o = v * stride
            for c in 0..<6 { shape.vertices[o + c] = a[o + c] + (b[o + c] - a[o + c]) * f }
        }
        shape.version += 1
    }

    private func geometry(for ps: RParticle) -> RenderGeometry? {
        switch ps.type {
        case ParticleKind.model, ParticleKind.lightModel:
            if let targets = morphTargets(ps), let first = targets.first {
                let copy = RenderGeometry()
                copy.vertices = first.vertices
                copy.indices = first.indices
                return copy
            }
            return model(ps.modelIndex) ?? GeometryBuilder.quad
        case 14:
            guard PreviewRules.isOn("modelSkin"), let mesh = AvfxSimulation.skinMesh else { return nil }
            if PreviewRules.isOn("auraTarget"), ps.auraTarget & AvfxSimulation.skinTargets == 0 { return nil }
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
        case ParticleKind.decalRing: return GeometryBuilder.ring(fan: ps.ringFan, inner: 0.5, outer: 0.5)
        case ParticleKind.laser: return GeometryBuilder.laser
        case ParticleKind.disc:
            return ps.disc.map { GeometryBuilder.disc(countU: $0.countU, countV: $0.countV, intervalFactorV: PreviewRules.isOn("discIntervalFactor") ? $0.intervalFactorV : 0) }
        default: return nil
        }
    }

    private func spawnParticle(_ ps: RParticle, _ item: REmitterItem, _ e: EmitterInstance, copyIndex: Int) -> ParticleInstance {
        let trail = ps.type == ParticleKind.polyline && PreviewRules.isOn("trails") ? ps.polyline.map { PolylineTrail($0) } : nil
        let shape = trail?.geometry ?? geometry(for: ps)
        var cloud: SpriteCloud?
        if shape != nil, let simple = ps.simple, ps.type == ParticleKind.powder || ps.type == ParticleKind.line {
            cloud = SpriteCloud(anim: simple, points: simple.injectionPosition == 1 ? points(for: simple.injectionModel) : [],
                                bindPoints: simple.injectionPosition == 1 && simple.bindModel >= 0 ? points(for: simple.bindModel) : [],
                                lines: ps.type == ParticleKind.line)
        }
        sequence += 1
        let p = ParticleInstance(schema: ps, item: item, emitter: e, geometry: shape, cloud: cloud, sequence: sequence, random: &random)
        if let pick = modelChoice(ps, p.seed.get(36)), let picked = model(ps.modelIndices[pick]) {
            p.geometry = picked
            p.modelPick = pick
        }
        p.copyIndex = copyIndex
        p.trail = trail
        if item.parameterLink >= 0, item.parameterLink != item.target, item.parameterLink < schema.particles.count, PreviewRules.isOn("parameterLink") {
            p.link = schema.particles[item.parameterLink]
        }
        let startFrame = PreviewRules.isOn("itemStartFrame") ? item.startFrame : 0
        let preRun = startFrame > 0 && !(item.startFrameNullUpdate && PreviewRules.isOn("startFrameNullUpdate")) ? startFrame : 0
        if startFrame > 0 && preRun == 0 {
            p.age = Float(startFrame)
            p.totalAge = p.age
        }
        let point = e.nextPoint(&random)
        let turn = e.injectionTurn(point) { p.seed.get(26 + $0) }
        if let turn { p.injectTurn = Mat4(turn) }
        p.localFlight = p.withOptions && item.inheritPosition && item.influenceCoord != Influence.withOptionsNoPosition && point != nil
        if let point {
            p.offset = point.position
            if item.localDirection == 1, simd_length_squared(point.normal) > 1e-8, PreviewRules.isOn("localDirectionFollowsNormal") {
                p.normalFrame = normalBasis(point.normal)
            }
            p.spawnMatrix = p.spawnMatrix * Math3D.translation(point.position)
            let direction = turn?.act(point.normal) ?? point.normal
            let speed = injectionSpeed(e)
            if p.localFlight {
                if speed != 0 { p.localVelocity = direction * speed }
            } else if speed != 0 {
                p.velocity = Math3D.direction(p.spawnMatrix, direction) * speed * revisedSpeedScale
            }
        }
        if item.inheritParentVelocity, e.moving, PreviewRules.isOn("inheritParentVelocity") { p.velocity += e.velocity }
        if item.influenceCoord == Influence.initialPosition && !p.follow && !p.withOptions {
            p.spawnMatrix = Math3D.compose(Math3D.position(p.spawnMatrix), simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), schema.revisedScale)
        }
        p.launch = (p.velocity, p.localVelocity)
        for _ in 0..<preRun {
            move(p, 1)
            p.age += 1
            p.totalAge += 1
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
            if recording {
                if p.hasLastWorld {
                    let d = origin - p.lastWorld
                    if simd_length_squared(d) > 1e-10 { p.moveDirection = d }
                }
                p.lastWorld = origin
                p.hasLastWorld = true
            }
            let direction = simd_length_squared(p.moveDirection) > 0 ? p.moveDirection : simd_length_squared(p.velocity) > 0 ? p.velocity : cz
            axis = unitVector(direction, Vec3(0, 1, 0)) * simd_length(cz)
        }
        let along = axis * length
        let toCamera = camera - (origin + along * 0.5)
        var side = simd_cross(toCamera, along)
        if simd_length_squared(side) < 1e-12 { side = Vec3(1, 0, 0) }
        side = simd_normalize(side)
        let crossing = simd_cross(along, side)
        let normal = simd_length_squared(crossing) > 1e-12 ? simd_normalize(crossing) : Vec3(0, 1, 0)
        side *= width * across
        return Math3D.basis(side, normal, along, origin: origin)
    }

    func dissolve(filter: VisibilityFilter) -> DissolveState? {
        for p in particles {
            let s = p.schema
            guard let d = s.dissolve, d.target & 1 != 0, visible(p, filter) else { continue }
            let shaped = PreviewRules.isOn("dissolveShape")
            let tc1 = s.tc1.flatMap { $0.enabled ? $0 : nil }
            let texture = tc1?.textures.first ?? -1
            guard shaped || texture >= 0 else { continue }
            let t = p.curveTime
            var state = DissolveState(texture: texture, amount: Eval.curve(d.erosion, t, 0), edge: max(0.001, Eval.curve(d.endWidth, t, 0.1)), reverse: d.reverse)
            if shaped {
                let local = Math3D.compose(Eval.axes(s.position, t, 0, p.seed, 1), Math3D.euler(Eval.axes(s.rotation, t, 0, p.seed, 4), order: s.rotationOrder),
                                           Eval.axes(s.scale, t, 1, p.seed, 8))
                let parent = p.follow ? p.emitter.world : p.spawnMatrix
                let world = Math3D.translation(p.travel) * parent * local
                state.shaped = true
                state.shape = d.shape
                state.inverse = world.inverse
                state.widths = Vec3(max(0, Eval.curve(d.startWidth, t, 0)), max(0, Eval.curve(d.midWidth, t, 0)), max(0, Eval.curve(d.endWidth, t, 0)))
                let strength = Eval.curve(d.intensity, t, 1)
                state.colors = [d.startColor, d.midColor, d.endColor].map { c in
                    guard let c else { return .zero }
                    let v = Eval.color(c, t, p.seed)
                    return Vec4(v.x * strength, v.y * strength, v.z * strength, min(max(v.w, 0), 1))
                }
            }
            guard let tc1 else { return state }
            let color = Eval.color(s.color, t, p.seed)
            let strength = Eval.curve(d.intensity, t, 1)
            state.color = Vec3(color.x, color.y, color.z) * strength
            if tc1.uvSet >= 0, tc1.uvSet < s.uvSets.count {
                let uv = s.uvSets[tc1.uvSet]
                let scale = Eval.axes(uv.scale, t, 1, p.seed, 26)
                let scroll = Eval.axes(uv.scroll, t, 0, p.seed, 29)
                let rotation = (PreviewRules.isOn("uvRotationReversed") ? -1 : 1) * Eval.curve(uv.rotation, t)
                let c = cos(rotation), sn = sin(rotation)
                state.uvMatrix = Vec4(scale.x * c, scale.x * sn, -scale.y * sn, scale.y * c)
                state.uvOffset = SIMD2(scroll.x, scroll.y)
            }
            return state
        }
        return nil
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
        let endsWithEmitter = PreviewRules.isOn("effectorEndsWithEmitter")
        for e in emitters where e.alive || !endsWithEmitter {
            guard let index = effectorIndex(e) else { continue }
            if filter.hidden.contains(.emitter(e.schema.index)) || filter.hidden.contains(.timeline(e.timeline)) { continue }
            let effector = schema.effectors[index]
            let age = effectorTime(effector, e.age)
            let t = CurveTime(age)
            let origin = Math3D.point(e.world, Vec3(0, 0, 0))
            let distance = simd_length((effector.fadeFromCaster && PreviewRules.isOn("effectorFadeBase") ? Vec3.zero : camera) - origin)
            switch effector.type {
            case 3, 4, 5, 7:
                guard PreviewRules.isOn("postEffects") else { continue }
                var strength = Eval.curve(effector.strength, t, 1) * fade(e.dying)
                if effector.fadeEnd > effector.fadeStart { strength *= 1 - min(max((distance - effector.fadeStart) / (effector.fadeEnd - effector.fadeStart), 0), 1) }
                guard strength > 0.001 else { continue }
                var effect = ScreenEffect(kind: effector.type, position: origin, strength: strength, length: Eval.curve(effector.length, t, 0.1),
                                          inner: Eval.curve(effector.inner, t, 0), outer: Eval.curve(effector.outer, t, 0), angle: Eval.curve(effector.angle, t, 0),
                                          gradation: Eval.curve(effector.gradation, t, 0))
                if PreviewRules.isOn("screenEffectorFields") {
                    switch effector.type {
                    case 3:
                        let ramp = min(1, age / 30)
                        effect.extra = Vec4(Eval.curve(effector.refraction, t, 0) * ramp, Eval.curve(effector.separation, t, 0) * ramp,
                                            Eval.curve(effector.effectStrength, t, 0) * ramp, 1)
                    case 4:
                        if effect.outer < effect.inner {
                            effect.inner = 0
                            effect.outer = 0.1
                        }
                        effect.extra = Vec4(0, 0, 0, 1)
                    case 5:
                        effect.angle *= .pi / 180
                        effect.strength *= effector.angleStrength.map { Eval.curve($0, t, 1) } ?? 1
                        effect.extra = Vec4(effector.singleSide ? 1 : 0, 0, 0, 1)
                    default: break
                    }
                }
                effects.append(effect)
            case 6, 9:
                guard PreviewRules.isOn("cameraQuake") else { continue }
                let position = Math3D.point(e.world, Eval.axes(effector.position, t, 0, e.seed, 1))
                let reach = simd_length(camera - position)
                let near = Eval.curve(effector.quakeIn, t, 0), far = Eval.curve(effector.quakeOut, t, 0)
                var amount = abs(Eval.curve(effector.quake, t, 0)) * fade(e.dying)
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
        let endsWithEmitter = PreviewRules.isOn("effectorEndsWithEmitter")
        for e in emitters where e.alive || !endsWithEmitter {
            guard let index = effectorIndex(e), schema.effectors[index].type == 0 || schema.effectors[index].type == 1 else { continue }
            if filter.hidden.contains(.emitter(e.schema.index)) || filter.hidden.contains(.timeline(e.timeline)) { continue }
            let effector = schema.effectors[index]
            let t = CurveTime(effectorTime(effector, e.age))
            let color = Eval.color(effector.color, t, e.seed)
            let peak = max(color.x, color.y, color.z, 1e-6)
            let strength = peak * max(0, color.w) * fade(e.dying)
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
            let maxAttenuation = effector.attenuation >= 3 && PreviewRules.isOn("pointLightMax")
            let scaleDistance = Eval.curve(effector.distance, t, 0)
            result.append(LightDraw(position: Math3D.point(e.world, Eval.axes(effector.position, t, 0, e.seed, 1)),
                                    color: Vec3(color.x, color.y, color.z) / peak * strength, distance: scaleDistance,
                                    decay: maxAttenuation ? 0 : Float(effector.attenuation + 1),
                                    reach: scaleDistance > 0 ? max(0, Eval.curve(effector.color.bri, t, 1)) / scaleDistance : 1e6, point: true))
        }
        return result
    }

    func emitterMarkers() -> [(index: Int, world: Mat4, points: [Vec3])] {
        emitters.map { e in
            let radius = e.schema.type == 3 ? Eval.curve(e.schema.radius, CurveTime(e.age), 1) : 1
            var points = e.points.map { $0.position * (e.schema.type == 3 ? radius : 1) }
            if e.schema.type == 4 {
                let at = CurveTime(e.age)
                let ring = Eval.curve(e.schema.radius, at, 1), length = Eval.curve(e.schema.length, at, 0)
                points = e.points.map { Vec3($0.position.x * ring, $0.position.y * length, $0.position.z * ring) }
            }
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

    func pick(origin: Vec3, direction: Vec3, draws: [ParticleDraw]) -> Int? {
        var best: (particle: Int, distance: Float)?
        for draw in draws {
            var centre = Math3D.position(draw.model)
            let scale = Math3D.decompose(draw.model).scale
            var radius = max(0.08, max(abs(scale.x), abs(scale.y), abs(scale.z)) * 0.5)
            if let bounds = draw.worldBounds {
                centre = bounds.centre
                radius = bounds.radius
            }
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

    private var recording = true
    private static let billboardBases: Set<Int> = [Base.screenBillboard, Base.cameraBillboard, Base.billboardAxisY, Base.cameraBillboardAxisY,
                                                   Base.moveDirectionBillboard, Base.treeBillboard]
    private static let yawBases: Set<Int> = [Base.billboardAxisY, Base.cameraBillboardAxisY, Base.treeBillboard]
    private var renderPass = 0

    private func particleDirectionalLight(_ filter: VisibilityFilter) -> (direction: Vec3, ambient: Vec3, color: Vec3)? {
        if schema.directionalLightSource == 2, PreviewRules.isOn("inGameLight") {
            return (-simd_normalize(Vec3(0.4, 0.8, 0.45)), Vec3(repeating: 0.45), Vec3(repeating: 0.55))
        }
        guard schema.directionalLightSource == 1, PreviewRules.isOn("particleDirectionalLight") else { return nil }
        for e in emitters where e.alive {
            guard let index = effectorIndex(e), schema.effectors[index].type == 1 else { continue }
            if filter.hidden.contains(.emitter(e.schema.index)) || filter.hidden.contains(.timeline(e.timeline)) { continue }
            let effector = schema.effectors[index]
            let t = CurveTime(effectorTime(effector, e.age))
            let ambient = effector.ambient.map { Eval.color($0, t, e.seed) } ?? .zero
            let color = Eval.color(effector.color, t, e.seed) * Eval.curve(effector.power, t, 1)
            let r = effector.rotation.map { Eval.axes($0, t, 0, e.seed, 0) } ?? .zero
            let turn = Math3D.euler(Vec3(-r.x, r.y, r.z), order: effector.rotationOrder)
            let direction = simd_normalize(Math3D.decompose(e.world).rotation.act(turn.act(Vec3(0, 0, -1))))
            return (direction, Vec3(ambient.x, ambient.y, ambient.z), Vec3(color.x, color.y, color.z))
        }
        return (.zero, .zero, .zero)
    }

    private func angleFade(_ camera: Vec3) -> Float {
        guard PreviewRules.isOn("angleFade"), schema.angleFade.contains(where: { $0.enabled }) else { return 1 }
        let length = max(1e-6, simd_length(camera))
        let angles = [acos(min(max(camera.y / length, -1), 1)), abs(atan2(camera.x, camera.z))]
        var k: Float = 1
        for (i, fade) in schema.angleFade.prefix(2).enumerated() where fade.enabled && angles[i] > fade.inner {
            k *= fade.outer > fade.inner ? max(0, 1 - (angles[i] - fade.inner) / (fade.outer - fade.inner)) : 0
        }
        return k
    }

    func render(camera: CameraState, filter: VisibilityFilter = VisibilityFilter(), record: Bool = true) -> [ParticleDraw] {
        recording = record
        renderPass += 1
        defer { recording = true }
        cameraRotation = camera.rotation
        cameraPosition = camera.position
        let identity = simd_quatf(angle: 0, axis: Vec3(0, 1, 0))
        let pixelAngle = 2 * tan(camera.fovY / 2) / max(1, camera.viewportHeight)
        let randomOnce = PreviewRules.isOn("emitterRandomOnce"), flightUnscaled = PreviewRules.isOn("localFlightUnscaled")
        let binderRotation = PreviewRules.isOn("inheritBinderRotation"), moveAxisZ = PreviewRules.isOn("moveDirectionAxisZ")
        let treeOwnAxis = PreviewRules.isOn("modelTreeBillboardOwnAxis"), collisionFreeze = PreviewRules.isOn("collisionFreeze")
        let angleFade = angleFade(camera.position)
        let overScene = [0, 8, 9].contains(schema.drawLayer) && PreviewRules.isOn("drawLayerOverScene")
        let keepEmitterRotation = PreviewRules.isOn("billboardModelKeepsEmitterRotation")
        let particleLight = particleDirectionalLight(filter)
        let localPoint = schema.pointLightSources.0 == 3 || schema.pointLightSources.1 == 3
        let particlePoints = particleLight != nil && localPoint && PreviewRules.isOn("particlePointLights") ? Array(lights(filter: filter).filter(\.point).prefix(2)) : []
        var draws: [ParticleDraw] = []
        for p in particles {
            guard p.geometry != nil, visible(p, filter) else { continue }
            if p.schema.movementParticle, PreviewRules.isOn("movementParticle") { continue }
            let s = p.schema
            let t = p.curveTime
            if s.morph != nil { morph(p, t) }
            if let number = s.animationNumber, s.morph == nil, s.modelIndices.count > 1, PreviewRules.isOn("modelAnimationNumber") {
                let pick = min(max(Int(Eval.curve(number, t, 0).rounded(.down)), 0), s.modelIndices.count - 1)
                if pick != p.modelPick, let picked = model(s.modelIndices[pick]) {
                    p.geometry = picked
                    p.modelPick = pick
                }
            }
            if p.modelPick >= 0, s.modelRandom.interval > 0, s.modelRandom.type >= 3 {
                let step = Float(Int(p.age / Float(s.modelRandom.interval)))
                let mixed = sin(p.seed.get(36) * 12.9898 + step * 78.233) * 43758.5453
                if let pick = modelChoice(s, mixed - mixed.rounded(.down)), pick != p.modelPick, let picked = model(s.modelIndices[pick]) {
                    p.geometry = picked
                    p.modelPick = pick
                }
            }
            guard var shape = p.geometry else { continue }
            let localPosition = Eval.axes(s.position, t, 0, p.seed, 1)
            let ownRotation = Eval.axes(s.rotation, t, 0, p.seed, 4)
            var localRotation = ownRotation
            let spun = p.totalAge * p.timeScale
            let spinRandom = PreviewRules.isOn("rotationVelocityRandom")
            localRotation.x += (spinRandom ? Eval.withRandom(s.rotVelX, s.rotVelRandom[0], t, 0, p.seed.get(20)) : Eval.curve(s.rotVelX, t)) * spun
            localRotation.y += (spinRandom ? Eval.withRandom(s.rotVelY, s.rotVelRandom[1], t, 0, p.seed.get(21)) : Eval.curve(s.rotVelY, t)) * spun
            localRotation.z += (spinRandom ? Eval.withRandom(s.rotVelZ, s.rotVelRandom[2], t, 0, p.seed.get(22)) : Eval.curve(s.rotVelZ, t)) * spun
            let injection = Math3D.euler(p.item.injectionAngle * Float(p.copyIndex), order: s.rotationOrder)
            let hasInjection = simd_length_squared(p.item.injectionAngle) > 0 && p.copyIndex != 0
            let treeQuadFixed = s.type == ParticleKind.quad && s.rotationBase == Base.treeBillboard && PreviewRules.isOn("treeBillboardFixed")
            let billboard = !treeQuadFixed && ((s.type == ParticleKind.powder && p.cloud == nil) || s.type == ParticleKind.windmill
                || AvfxSimulation.billboardBases.contains(s.rotationBase))
            let localScale = Eval.axes(s.scale, t, 1, p.seed, 8)
            let computeOrder = PreviewRules.isOn("coordComputeOrder")
            var local = Math3D.compose(localPosition, Math3D.euler(localRotation, order: s.rotationOrder), localScale, order: computeOrder ? s.coordOrder : 0)
            let link = p.link
            var linkRotation = Vec3.zero
            if let link {
                linkRotation = Eval.axes(link.rotation, t, 0, p.linkSeed, 4)
                local = Math3D.compose(Eval.axes(link.position, t, 0, p.linkSeed, 1), Math3D.euler(linkRotation, order: link.rotationOrder),
                                       Eval.axes(link.scale, t, 1, p.linkSeed, 8), order: computeOrder ? link.coordOrder : 0) * local
            }
            if !billboard, let normalFrame = p.normalFrame { local = normalFrame * local }
            if !billboard, let injectTurn = p.injectTurn { local = injectTurn * local }
            if !billboard && hasInjection { local = Mat4(injection) * local }
            if s.type == ParticleKind.quad {
                if s.rotationBase == Base.x {
                    local = local * Math3D.rotationY(.pi / 2)
                } else if s.rotationBase == Base.y {
                    local = local * Math3D.rotationX(-.pi / 2)
                }
            }

            let emitterWorld = randomOnce ? p.emitter.world : p.emitter.matrix(for: p.emitterSeed, pass: renderPass)
            var parent: Mat4
            if p.follow {
                parent = emitterWorld
                if simd_length_squared(p.offset) > 0 { parent = parent * Math3D.translation(p.offset) }
            } else if p.withOptions {
                let item = p.item
                let keepPosition = item.inheritPosition && item.influenceCoord != Influence.withOptionsNoPosition
                var origin = Math3D.position(keepPosition ? emitterWorld : p.spawnMatrix)
                let now = Math3D.decompose(emitterWorld)
                if p.localFlight {
                    origin = flightUnscaled ? Math3D.point(emitterWorld, p.offset) + now.rotation.act(schema.revisedScale * p.localTravel)
                        : Math3D.point(emitterWorld, p.offset + p.localTravel)
                }
                var rotation = item.inheritRotation ? now.rotation : identity
                if !item.inheritRotation, item.inheritBinderRotation, binderRotation {
                    var top = p.emitter
                    while let up = top.parent { top = up }
                    rotation = Math3D.decompose(top.anchor()).rotation
                }
                parent = Math3D.compose(origin, rotation, item.inheritScale ? now.scale : schema.revisedScale)
                if !p.localFlight && keepPosition && simd_length_squared(p.offset) > 0 { parent = parent * Math3D.translation(p.offset) }
            } else {
                parent = p.spawnMatrix
            }
            if Influence.noPosition(p.item.influenceCoord) { parent.columns.3.y = groundY }
            if p.follow, p.item.unstickiness > 1, PreviewRules.isOn("influenceUnstickiness") {
                let target = Math3D.position(parent)
                var held = p.lagPosition ?? target
                if recording {
                    var stepped = p.lagTime
                    if p.lagPosition == nil { stepped = p.totalAge }
                    while stepped + 1 <= p.totalAge {
                        stepped += 1
                        held += (target - held) / p.item.unstickiness
                    }
                    p.lagPosition = held
                    p.lagTime = stepped
                }
                parent.columns.3 = Vec4(held.x, held.y, held.z, 1)
            }
            if simd_length_squared(p.travel) > 0 { parent = Math3D.translation(p.travel) * parent }
            var m = parent * local

            if s.rotationBase == Base.moveDirection, s.type != ParticleKind.laser, moveAxisZ {
                let parts = Math3D.decompose(m)
                if recording {
                    if p.hasLastWorld {
                        let d = parts.position - p.lastWorld
                        if simd_length_squared(d) > 1e-10 { p.moveDirection = d }
                    }
                    p.lastWorld = parts.position
                    p.hasLastWorld = true
                }
                if simd_length_squared(p.moveDirection) > 0 {
                    let z = simd_normalize(p.moveDirection)
                    let x = simd_normalize(simd_cross(abs(z.y) > 0.999 ? Vec3(1, 0, 0) : Vec3(0, 1, 0), z))
                    m = Math3D.compose(parts.position, Math3D.quaternion(x: x, y: simd_cross(z, x), z: z) * Math3D.euler(ownRotation, order: s.rotationOrder), parts.scale)
                }
            } else if s.rotationBase == Base.moveDirectionBillboard, PreviewRules.isOn("moveDirectionStreaks") {
                let parts = Math3D.decompose(m)
                if recording {
                    if p.hasLastWorld {
                        let d = parts.position - p.lastWorld
                        if simd_length_squared(d) > 1e-10 { p.moveDirection = d }
                    }
                    if simd_length_squared(p.moveDirection) == 0 { p.moveDirection = simd_length_squared(p.velocity) > 0 ? p.velocity : Vec3(0, 1, 0) }
                    p.lastWorld = parts.position
                    p.hasLastWorld = true
                }
                let zAxis = unitVector(camera.position - parts.position, Vec3(0, 0, 1))
                var yAxis = p.moveDirection - zAxis * simd_dot(p.moveDirection, zAxis)
                if simd_length_squared(yAxis) < 1e-12 { yAxis = camera.rotation.act(Vec3(0, 1, 0)) }
                yAxis = simd_normalize(yAxis)
                let xAxis = unitVector(simd_cross(yAxis, zAxis), Vec3(1, 0, 0))
                let facing = PreviewRules.isOn("moveDirectionRotation")
                    ? Math3D.quaternion(x: xAxis, y: -zAxis, z: yAxis) * Math3D.euler(ownRotation, order: s.rotationOrder)
                    : Math3D.quaternion(x: xAxis, y: yAxis, z: zAxis)
                m = Math3D.compose(parts.position, facing, parts.scale)
            } else if billboard {
                let parts = Math3D.decompose(m)
                let fullRotation = s.type == ParticleKind.model || s.type == ParticleKind.lightModel || s.type == ParticleKind.disc || s.type == 14
                var roll = fullRotation ? Math3D.euler(localRotation, order: s.rotationOrder) : simd_quatf(angle: localRotation.z, axis: Vec3(0, 0, 1))
                if fullRotation, keepEmitterRotation {
                    var root = p.emitter
                    while let up = root.parent { root = up }
                    roll = Math3D.decompose(root.anchor()).rotation.inverse * Math3D.decompose(emitterWorld).rotation * roll
                }
                if let link {
                    roll = (fullRotation ? Math3D.euler(linkRotation, order: link.rotationOrder) : simd_quatf(angle: linkRotation.z, axis: Vec3(0, 0, 1))) * roll
                }
                if s.rotationBase == Base.treeBillboard, s.type == ParticleKind.model || s.type == ParticleKind.lightModel, treeOwnAxis {
                    let axis = simd_normalize(parts.rotation.act(Vec3(0, 1, 0)))
                    let toCamera = camera.position - parts.position
                    let face = toCamera - axis * simd_dot(toCamera, axis)
                    if simd_length_squared(face) > 1e-10 {
                        let z = simd_normalize(face)
                        m = Math3D.compose(parts.position, Math3D.quaternion(x: simd_cross(axis, z), y: axis, z: z), parts.scale)
                    }
                } else {
                    var facing = camera.rotation
                    if AvfxSimulation.yawBases.contains(s.rotationBase) {
                        facing = simd_quatf(angle: atan2(camera.position.x - parts.position.x, camera.position.z - parts.position.z), axis: Vec3(0, 1, 0))
                    }
                    m = Math3D.compose(parts.position, facing * (hasInjection ? injection : identity) * roll, parts.scale)
                }
            }
            if s.type == ParticleKind.laser {
                let length = Eval.withRandom(s.lineLength, s.lineLengthRandom, t, 1, p.seed.get(14))
                let width = Eval.withRandom(s.laserWidth, s.laserWidthRandom, t, 1, p.seed.get(16))
                m = laserMatrix(m, base: s.rotationBase, length: length, width: width, camera: camera.position, p)
            }
            if s.type == ParticleKind.decalRing {
                let width = Eval.withRandom(s.ringWidth, s.ringWidthRandom, t, 0, p.seed.get(14))
                shape = GeometryBuilder.ring(fan: s.ringFan, inner: 0.5 - width, outer: 0.5 + width)
            }
            if let disc = s.disc {
                let inner = disc.colorInner.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                let outer = disc.colorOuter.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                GeometryBuilder.setDisc(shape, countU: disc.countU, countV: disc.countV, shape: discShape(disc, t, p.seed), inner: inner, outer: outer)
            }
            if s.type == ParticleKind.decal || s.type == ParticleKind.decalRing {
                if s.decalScalingScale != 1, PreviewRules.isOn("decalScalingScale") {
                    var root = p.emitter
                    while let up = root.parent { root = up }
                    let bias = root.binder >= 0 && root.binder < schema.binders.count && PreviewRules.isOn("vfxScaleBias") ? schema.binders[root.binder].vfxScaleBias : 1
                    if bias != 0, bias != 1 {
                        let k = (1 - s.decalScalingScale) / bias + s.decalScalingScale
                        let parts = Math3D.decompose(m)
                        m = Math3D.compose(parts.position, parts.rotation, parts.scale * k)
                    }
                }
                var parts = Math3D.decompose(m)
                if abs(parts.position.y - groundY) <= abs(parts.scale.y) / 2 {
                    parts.position.y = groundY
                    m = Math3D.compose(parts.position, parts.rotation, parts.scale)
                } else {
                    continue
                }
            }

            var trailHead: Vec3?
            if let trail = p.trail, let line = s.polyline {
                let count = max(2, line.pointCount)
                var space = matrix_identity_float4x4
                if line.isLocal, PreviewRules.isOn("polylineLocal") {
                    var root = p.emitter
                    while let up = root.parent { root = up }
                    space = root.anchor()
                }
                let toSpace = space.inverse
                if line.createType == 1 {
                    let chain = PreviewRules.isOn("polylineChain")
                    trail.softness = chain ? Eval.curve(line.softness, t, 0) : nil
                    trail.historyFrames = chain ? Float(line.pointCount) / 2 + 2
                        : p.lifetime.isFinite && PreviewRules.isOn("trailWholePath") ? .infinity : Float(line.pointCount) / 2
                    var head = Math3D.position(m)
                    if line.bindWeapon, PreviewRules.isOn("polylineBindWeapon") { head = weaponLine(line.bindWeaponType).tip }
                    if recording { trail.record(p.totalAge, Math3D.point(toSpace, head)) }
                } else if line.bindWeapon, PreviewRules.isOn("polylineBindWeapon") {
                    let weapon = weaponLine(line.bindWeaponType)
                    trail.setPoints((0..<count).map { Math3D.point(toSpace, weapon.base + (weapon.tip - weapon.base) * (Float($0) / Float(count - 1))) })
                } else if line.connectTarget, PreviewRules.isOn("polylineConnectTarget") {
                    let from = Math3D.position(m), to = connectEnd(p.emitter, reverse: line.connectReverse)
                    trail.setPoints((0..<count).map { Math3D.point(toSpace, from + (to - from) * (Float($0) / Float(count - 1))) })
                } else {
                    let length = Eval.curve(line.length, t, 1)
                    let base = PreviewRules.isOn("polylineAxisFromBase") ? s.rotationBase : 1
                    let axis = base == 0 ? Vec3(1, 0, 0) : base == 2 ? Vec3(0, 0, 1) : Vec3(0, 1, 0)
                    trail.setPoints((0..<count).map { Math3D.point(toSpace, Math3D.point(m, axis * (length * Float($0) / Float(count - 1)))) })
                }
                guard trail.drawable else { continue }
                trail.vFromHead = PreviewRules.isOn("polylineVFromHead")
                let axis = line.noBillboardAxis == 0 ? Vec3(1, 0, 0) : line.noBillboardAxis == 2 ? Vec3(0, 0, 1) : Vec3(0, 1, 0)
                trail.fixedSide = line.noBillboard && PreviewRules.isOn("polylineShape") ? Math3D.direction(toSpace * m, axis) : nil
                func tint(_ c: RColor?) -> Vec4 { c.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1) }
                let widthScale = PreviewRules.isOn("polylineWidthRevised") ? (schema.revisedScale.x + schema.revisedScale.y) / 2 : 1
                let spread = PreviewRules.isOn("polylineWidthRandom")
                func width(_ c: RCurve?, _ k: Int) -> Float { spread ? Eval.withRandom(c, line.widthRandom[k], t, 1, p.seed.get(16 + k)) : Eval.curve(c, t, 1) }
                trail.jitter = PreviewRules.isOn("polylinePointDistortion") ? abs(Eval.curve(line.pointDistortion, t, 0)) : 0
                trail.jitterPhase = Int((p.totalAge * 2).rounded(.down)) &+ p.sequence &* 7919
                trail.build(camera: Math3D.point(toSpace, camera.position), width: width(line.width, 0) * widthScale, begin: width(line.widthBegin, 1),
                            center: width(line.widthCenter, 2), end: width(line.widthEnd, 3),
                            colors: PolylineColors(begin: tint(line.colorBegin), center: tint(line.colorCenter), end: tint(line.colorEnd),
                                                   edgeBegin: tint(line.colorEdgeBegin), edgeCenter: tint(line.colorEdgeCenter),
                                                   edgeEnd: tint(line.colorEdgeEnd)))
                if line.tagNumber > 0, PreviewRules.isOn("polylineTagHelper") {
                    if recording { guides[line.tagNumber] = trail.centerline.map { Math3D.point(space, $0) } }
                    continue
                }
                trailHead = Math3D.position(m)
                m = space
            }
            if s.collision == 0, recording, PreviewRules.isOn("collisionRespawn"), Math3D.position(m).y < groundY, p.age > 0 {
                p.age = 0
                p.totalAge = 0
                p.travel = .zero
                p.localTravel = .zero
                p.velocity = p.launch.velocity
                p.localVelocity = p.launch.local
                p.spin = nil
            }
            if s.collision == 2, collisionFreeze {
                let parts = Math3D.decompose(m)
                if p.stuck == nil, recording, parts.position.y < groundY { p.stuck = Vec3(parts.position.x, groundY, parts.position.z) }
                if let stuck = p.stuck { m = Math3D.compose(stuck, parts.rotation, parts.scale) }
            }

            var color = Eval.color(s.color, t, p.seed)
            if let link { color *= Eval.color(link.color, t, p.linkSeed) }
            color.w *= fade(p.dying) * angleFade
            if !fadeIns.isEmpty { color.w *= fadeIn(p.emitter) }
            if let clip = schema.ownClip, PreviewRules.isOn("effectOwnClip") {
                let reach = simd_length(Math3D.position(m == matrix_identity_float4x4 ? parent : m) - camera.position)
                func ramp(_ a: Float, _ b: Float) -> Float {
                    let low = min(a, b), high = max(a, b)
                    return high - low < 1e-5 ? (reach >= high ? 1 : 0) : min(max((reach - low) / (high - low), 0), 1)
                }
                if clip.near.1 > 0 { color.w *= ramp(clip.near.0, clip.near.1) }
                if clip.far.1 > 0 { color.w *= 1 - ramp(clip.far.0, clip.far.1) }
            }
            if PreviewRules.isOn("revisedColor") {
                color.x *= schema.revisedColor.x
                color.y *= schema.revisedColor.y
                color.z *= schema.revisedColor.z
            }
            if p.item.influenceColor == 1 {
                if p.bornColor == nil { p.bornColor = p.emitter.color }
                color *= p.bornColor ?? p.emitter.color
            } else if p.item.influenceColor != 0 {
                color *= p.emitter.color
            }
            if PreviewRules.isOn("clipDistance"), s.clipNear != nil || s.clipFar != nil, !s.clipFromCaster {
                let place = Vec3(m.columns.3.x, m.columns.3.y, m.columns.3.z)
                let reach = simd_length(place - camera.position)
                func share(_ start: Float, _ end: Float) -> Float {
                    abs(end - start) < 1e-5 ? (reach < end ? 1 : 0) : min(max((end - reach) / (end - start), 0), 1)
                }
                if let near = s.clipNear { color.w *= 1 - pow(share(near.start, near.end), 1.5) }
                if let far = s.clipFar { color.w *= pow(share(far.start, far.end), 1.5) }
            }

            let mode = s.drawMode >= 9 && s.drawMode <= 12 ? s.drawMode - 8 : s.drawMode
            var draw = ParticleDraw(particle: s.index, geometry: shape, model: s.type == 14 ? matrix_identity_float4x4 : m, color: color)
            draw.parent = parent
            draw.depthCentre = trailHead
            draw.order = s.drawPriority * 1000 + ((mode == 0 || mode == 8) && PreviewRules.isOn("blendAfterAdditive") ? 500 : 0) + s.index
            draw.sequence = p.sequence
            draw.overScene = overScene
            if (s.fresnelType == 2 || s.fresnelType == 3), PreviewRules.isOn("fresnelAxis") {
                let turn = Math3D.euler(Eval.axes(s.fresnelRotation, t, 0, p.seed, 9), order: s.rotationOrder)
                let axis = s.fresnelType == 2 ? Math3D.direction(m, turn.act(Vec3(0, 0, 1))) : simd_normalize(turn.act(Vec3(0, 0, 1)))
                draw.fresnelAxis = Vec4(axis.x, axis.y, axis.z, 1)
            }
            if s.lit, let particleLight {
                draw.lit = min(max(s.lightType, 0), 2) + 1
                draw.light = particleLight
                draw.pointLights = particlePoints
                draw.pointLightType = s.pointLightType
                draw.normalPower = abs(Eval.curve(s.normalPower, t, 1))
            }
            if let skin = s.skin, PreviewRules.isOn("modelSkinMasks") {
                let emissive = Eval.curve(skin.emissive, t, 0) + Eval.randomOffset(skin.emissiveRandom, type: skin.emissive?.random ?? 0, t, p.seed.get(38))
                draw.color.x *= max(0, 1 + emissive)
                draw.color.y *= max(0, 1 + emissive)
                draw.color.z *= max(0, 1 + emissive)
                let fresnel = Eval.curve(skin.fresnel, t, 0)
                if fresnel > 0 {
                    let specular = Eval.curve(skin.specular, t, 0) + Eval.randomOffset(skin.specularRandom, type: skin.specular?.random ?? 0, t, p.seed.get(39))
                    let k = max(0, 1 + specular * fresnel)
                    draw.colorBegin = Vec4(draw.colorBegin.x * k, draw.colorBegin.y * k, draw.colorBegin.z * k, draw.colorBegin.w)
                }
                let density = Eval.axes(skin.density, t, 0, p.seed, 33)
                let su = 1 / max(0.05, 1 + density.x + density.z), sv = 1 / max(0.05, 1 + density.y + density.z)
                for slot in 0..<5 {
                    let u = draw.uvMatrix[slot]
                    draw.uvMatrix[slot] = Vec4(u.x * su, u.y * su, u.z * sv, u.w * sv)
                }
            }
            if s.colorBegin != nil || s.colorEnd != nil {
                draw.colorBegin = s.colorBegin.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                draw.colorEnd = s.colorEnd.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
            }
            if let tc1 = s.tc1, tc1.textures.count > 1 {
                let n = Eval.curve(tc1.texN, t, 0) + Eval.curve(tc1.texNRandom, t, 0) * p.seed.get(15)
                draw.frame = min(tc1.textures.count - 1, max(0, Int(safe: n.rounded(.down))))
            }
            let plainUv = PreviewRules.isOn("plainUv") && (s.type == ParticleKind.windmill || (s.type == ParticleKind.powder && s.simple == nil))
            for slot in 0..<5 {
                if slot != 2 && plainUv { continue }
                guard let layer = slot == 0 ? s.tc1 : slot == 1 ? s.tc2 : slot == 2 ? s.distortion : slot == 3 ? s.tc3 : s.tc4, layer.enabled, layer.uvSet >= 0, layer.uvSet < s.uvSets.count else { continue }
                let uv = s.uvSets[layer.uvSet]
                let scale = Eval.axes(uv.scale, t, 1, p.seed, 26)
                let scroll = Eval.axes(uv.scroll, t, 0, p.seed, 29)
                let turn = PreviewRules.isOn("uvRotationRandom") ? Eval.withRandom(uv.rotation, uv.rotationRandom, t, 0, p.seed.get(23)) : Eval.curve(uv.rotation, t)
                let rotation = (PreviewRules.isOn("uvRotationReversed") ? -1 : 1) * turn
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
                if let tag = s.simple?.polylineTag, tag > 0 { cloud.guide = guides[tag] ?? [] }
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
                if let disc = s.disc, disc.partsCount > 1, PreviewRules.isOn("discPartsCount") {
                    while p.discCopies.count < disc.partsCount - 1 {
                        var seeded = SeededRandom(seed: UInt64(p.sequence) &* 2654435761 &+ UInt64(p.discCopies.count + 1))
                        p.discCopies.append((GeometryBuilder.disc(countU: disc.countU, countV: disc.countV,
                                                                  intervalFactorV: PreviewRules.isOn("discIntervalFactor") ? disc.intervalFactorV : 0),
                                             RandomSeed(&seeded, count: 40)))
                    }
                    let inner = disc.colorInner.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                    let outer = disc.colorOuter.map { Eval.color($0, t, p.seed) } ?? Vec4(1, 1, 1, 1)
                    for copy in p.discCopies {
                        GeometryBuilder.setDisc(copy.geometry, countU: disc.countU, countV: disc.countV, shape: discShape(disc, t, copy.seed), inner: inner, outer: outer)
                        var extra = draw
                        extra.geometry = copy.geometry
                        draws.append(extra)
                    }
                }
            }
        }
        let orders = draws.map(\.order)
        let drawOrder = PreviewRules.isOn("drawOrder") ? schema.drawOrder : 0
        let sequences = drawOrder == 1 ? draws.map { -$0.sequence } : draws.map(\.sequence)
        if drawOrder == 2 {
            let depths = draws.map { simd_length_squared(Math3D.position($0.model == matrix_identity_float4x4 ? $0.parent : $0.model) - camera.position) }
            return draws.indices.sorted {
                orders[$0] != orders[$1] ? orders[$0] < orders[$1] : depths[$0] != depths[$1] ? depths[$0] > depths[$1] : $0 < $1
            }.map { draws[$0] }
        }
        return draws.indices.sorted {
            orders[$0] != orders[$1] ? orders[$0] < orders[$1] : sequences[$0] != sequences[$1] ? sequences[$0] < sequences[$1] : $0 < $1
        }.map { draws[$0] }
    }
}
