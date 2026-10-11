import Foundation

public struct EffectCoreOptions {
    public var views: ViewFactory
    public var models: [String: ModelData] = [:]
    public var params: [String: Double] = [:]
    public var seed: UInt32 = 1
    public var maxParticles = 5000

    public init(views: ViewFactory, models: [String: ModelData] = [:], params: [String: Double] = [:], seed: UInt32 = 1, maxParticles: Int = 5000) {
        self.views = views
        self.models = models
        self.params = params
        self.seed = seed
        self.maxParticles = maxParticles
    }
}

private let maxDt = 0.1
private let maxCreations = 10000

public final class EffectCore {
    public let fps: Double
    public let unit: Double
    public private(set) var time = 0.0
    public var timeScale = 1.0
    public private(set) var playing = false
    public private(set) var seed: UInt32
    public var maxParticles: Int
    public let state = EffectState()

    private let defs: EffectDefs
    private let views: ViewFactory
    private var kill: (from: Double, frames: Double)?
    private var killed = false
    private var firings: [Int: Int] = [:]
    private var starts: [TimelineStart] = []
    private var emitterList: [EmitterInstance] = []
    private var particleList: [ParticleInstance] = []
    private let origin = Origin()
    public private(set) var error: Error?

    public init(json data: Data, options: EffectCoreOptions) throws {
        let table = ParamTable()
        let def = try EffectDef.decode(data, table: table)
        views = options.views
        defs = try EffectDefs(
            def, table: table, hasTexture: { [views = options.views] in views.hasTexture($0) }, models: options.models, params: options.params)
        fps = def.fps ?? 30
        unit = def.unit ?? 100
        seed = options.seed
        maxParticles = options.maxParticles
        reset()
    }

    public var finished: Bool {
        killed || (starts.isEmpty && emitterList.isEmpty && particleList.isEmpty)
    }

    public func setPlane(_ plane: Plane) {
        state.plane = plane
        state.turn = .rotation(Vec3(x: plane.tiltX, y: plane.tiltY, z: 0), .xyz)
    }

    public var params: [String: Double] {
        defs.table.cells.mapValues(\.value)
    }

    @discardableResult
    public func setParam(_ name: String, _ value: Double) -> Bool {
        guard defs.def.params?[name] != nil else { return false }
        defs.table.cell(name).value = value
        return true
    }

    public var released: Bool { state.released != nil }
    public var killing: Bool { kill != nil || killed }
    public var particleCount: Int { particleList.count }

    public func release() {
        if state.released == nil { state.released = time }
    }

    @discardableResult
    public func trigger(_ n: Int) -> Bool {
        let firing = firings[n] ?? 0
        firings[n] = firing + 1
        let added = timelineStarts(defs, seed, trigger: n, at: time, firing: firing)
        if added.isEmpty { return false }
        starts = (starts + added).enumerated().sorted { $0.element.time != $1.element.time ? $0.element.time < $1.element.time : $0.offset < $1.offset }.map(\.element)
        return true
    }

    public func play() { playing = true }
    public func pause() { playing = false }

    public func restart(seed: UInt32? = nil) {
        if let seed { self.seed = seed }
        reset()
        playing = true
    }

    public var perspective: Double {
        state.plane.perspective != 0 ? state.plane.perspective : (defs.def.perspective ?? 0)
    }

    public func update(_ dt: Double) {
        if playing && !killed && error == nil {
            time += min(dt, maxDt) * fps * timeScale
            do {
                try startTimelineItems()
                try runCreations()
            } catch {
                self.error = error
            }
            removeDeadParticles()
            if kill != nil && fade <= 0 { end() }
        }
        let f = fade
        for p in particleList { p.update(time, f) }
    }

    private var fade: Double {
        guard let kill else { return 1 }
        return kill.frames > 0 ? max(0, 1 - (time - kill.from) / kill.frames) : 0
    }

    private func reset() {
        clear()
        time = 0
        state.released = nil
        firings = [:]
        kill = nil
        killed = false
        error = nil
        starts = timelineStarts(defs, seed)
    }

    private func clear() {
        for p in particleList { p.destroy() }
        starts = []
        emitterList = []
        particleList = []
    }

    private func end() {
        clear()
        kill = nil
        killed = true
    }

    private func startTimelineItems() throws {
        while let s = starts.first, s.time <= time {
            starts.removeFirst()
            switch s.what {
            case .clip(let clip): runClip(clip, s.time)
            case .emitter(let def, let end, let seed):
                emitterList.append(try EmitterInstance(def, origin, seed, s.time, { end }, state))
            }
        }
    }

    private func runClip(_ clip: TimelineItem.Clip, _ at: Double) {
        if clip.clip == .release {
            if state.released == nil { state.released = at }
        } else if kill == nil {
            kill = (at, clip.fade ?? 0)
        }
    }

    private func runCreations() throws {
        for _ in 0..<maxCreations {
            guard let e = nextEmitter() else { break }
            try create(e, e.takeCreation())
        }
        emitterList = emitterList.filter { $0.nextCreation < .infinity }
    }

    private func nextEmitter() -> EmitterInstance? {
        var best: EmitterInstance?
        var bestTime = Double.infinity
        for e in emitterList {
            let t = e.nextCreation
            if t > time { continue }
            if best == nil || t < bestTime || (t == bestTime && e.seed < best!.seed) {
                best = e
                bestTime = t
            }
        }
        return best
    }

    private func create(_ e: EmitterInstance, _ c: Creation) throws {
        let item = c.item
        let count = max(0, Int(evalParam(item.count, e.ageAt(c.time), 1, c.time - e.born).rounded(.toNearestOrAwayFromZero)))
        let first = e.takeCopies(c.itemIndex, count)
        let points = e.def.emission?.points
        for copy in 0..<count {
            let seed = hash(Int(e.seed), c.itemIndex, c.nth, copy)
            if random01(seed, Slot.probability) >= (item.probability ?? 1) { continue }
            let n = first + copy
            var turn: Vec3?
            if let r = item.copyRotation, n != 0 {
                turn = Vec3(x: r.x * Double(n), y: r.y * Double(n), z: r.z * Double(n))
            }
            let parent = attach(e, item.follow ?? .spawn, c.time, turn, item.copyRotationOrder ?? .xyz)
            switch item.target {
            case .particle(let id):
                guard particleList.count < maxParticles else { continue }
                let def = defs.particle(id)
                let spawn = Spawn(
                    emitter: e, time: c.time, parent: parent, seed: seed, inheritColor: item.inheritColor ?? false, life: item.life,
                    unit: unit, model: { [defs] in defs.model($0) }, state: state, perspective: { [unowned self] in self.perspective },
                    point: (points?.isEmpty == false) ? points![n % points!.count] : nil, views: views)
                particleList.append(try ParticleInstance(def, defs.particleTextures(def), spawn))
            case .emitter(let id):
                let creator = e
                emitterList.append(try EmitterInstance(defs.emitter(id), parent, seed, c.time, { creator.stop }, state))
            }
        }
    }

    private func removeDeadParticles() {
        particleList = particleList.filter { p in
            if !p.isDead(time) { return true }
            p.destroy()
            return false
        }
    }

    public func wireframe() -> [(SIMD2<Double>, SIMD2<Double>, SIMD2<Double>)] {
        var out: [(SIMD2<Double>, SIMD2<Double>, SIMD2<Double>)] = []
        for p in particleList {
            let g = p.geometry, m = p.world, d = p.perspective
            let at = { (i: Int) -> SIMD2<Double> in
                let v = m.apply(Double(g.positions[i * 2]), Double(g.positions[i * 2 + 1]), Double(g.extra?.z[i] ?? 0))
                let w = d > 0 ? max((d - v.z) / d, 0.05) : 1
                return SIMD2(v.x / w, v.y / w)
            }
            for t in stride(from: 0, to: g.indices.count - 2, by: 3) {
                out.append((at(Int(g.indices[t])), at(Int(g.indices[t + 1])), at(Int(g.indices[t + 2]))))
            }
        }
        return out
    }
}
