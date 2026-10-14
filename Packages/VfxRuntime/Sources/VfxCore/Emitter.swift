import Foundation

public struct Plane {
    public var tiltX = 0.0
    public var tiltY = 0.0
    public var perspective = 0.0
    public init() {}
}

public final class EffectState {
    public var released: Double? { didSet { generation &+= 1 } }
    var generation = 0
    public var plane = Plane()
    public var turn = Affine3.identity
    public var fps = 30.0
}

public struct Rgba {
    public var r = 1.0, g = 1.0, b = 1.0, a = 1.0
}

struct Creation {
    let item: EmitterItem
    let itemIndex: Int
    let time: Double
    let nth: Int
}

final class EmitterInstance: Parent {
    let def: EmitterDef
    let parent: Parent
    let seed: UInt32
    let born: Double
    private let limit: () -> Double
    private let state: EffectState
    private var nextTime: [Double]
    private var made: [Int]
    private var copies: [Int]
    private let color: ParsedColor
    private let startRotation: Vec3
    private var cachedStop: (generation: Int, value: Double)?

    init(_ def: EmitterDef, _ parent: Parent, _ seed: UInt32, _ born: Double, _ limit: @escaping () -> Double, _ state: EffectState) throws {
        self.def = def
        self.parent = parent
        self.seed = seed
        self.born = born
        self.limit = limit
        self.state = state
        nextTime = def.items.map { born + max(0, $0.delay ?? 0) }
        made = def.items.map { _ in 0 }
        copies = def.items.map { _ in 0 }
        color = try parseColor(def.color)
        startRotation = drawRotation(def.startRotation, seed)
    }

    var stop: Double {
        if let cachedStop, cachedStop.generation == state.generation { return cachedStop.value }
        let value = computeStop()
        cachedStop = (state.generation, value)
        return value
    }

    private func computeStop() -> Double {
        let limit = self.limit()
        if def.life < 0 { return limit }
        guard let loop = def.loop else { return min(born + def.life, limit) }
        guard let released = state.released else { return limit }
        let at = max(released, born)
        return min(at + max(0, def.life - loopedAge(at, born, loop, nil)), limit)
    }

    func ageAt(_ time: Double) -> Double {
        loopedAge(time, born, def.loop, state.released)
    }

    func matrixAt(_ time: Double) -> Affine3 {
        let base = parent.matrixAt(time)
        let age = ageAt(time), total = time - born
        let p = evalVec3(def.position, age, 0, total)
        let s = evalAxes(def.scale, age, 1, total)
        let r = Vec3(
            x: startRotation.x + evalParam(def.rotationX, age, 0, total),
            y: startRotation.y + evalParam(def.rotationY, age, 0, total),
            z: startRotation.z + evalParam(def.rotation, age, 0, total))
        return base.appending(.local(position: p, rotation: r, order: def.rotationOrder ?? .xyz, scale: s))
    }

    func takeCopies(_ itemIndex: Int, _ count: Int) -> Int {
        let first = copies[itemIndex]
        copies[itemIndex] = first + count
        return first
    }

    func colorAt(_ time: Double) -> Rgba {
        let age = ageAt(time), total = time - born
        let brightness = evalParam(def.brightness, age, 1, total)
        let c = evalColor(color, age)
        return Rgba(r: c.r * brightness, g: c.g * brightness, b: c.b * brightness, a: evalParam(def.alpha, age, 1, total))
    }

    var nextCreation: Double {
        let i = nextItem()
        return i < 0 ? .infinity : nextTime[i]
    }

    func takeCreation() -> Creation {
        let i = nextItem()
        let item = def.items[i]
        let time = nextTime[i]
        let nth = made[i]
        made[i] = nth + 1
        nextTime[i] = item.repeat == true ? time + (item.interval ?? 1) : .infinity
        return Creation(item: item, itemIndex: i, time: time, nth: nth)
    }

    private func nextItem() -> Int {
        var best = -1
        let stop = self.stop
        for i in 0..<nextTime.count where nextTime[i] < stop && (best < 0 || nextTime[i] < nextTime[best]) {
            best = i
        }
        return best
    }
}
