enum Slot {
    static let probability = 0
    static let life = 1
    static let speed = 2
    static let direction = 3
    static let offsetX = 4
    static let offsetY = 5
    static let startRotation = 6
    static let startScale = 7
    static let ringAngle = 8
    static let startRotationX = 9
    static let startRotationY = 10
    static let offsetZ = 11
}

private func mix(_ h0: UInt32) -> UInt32 {
    var h = h0
    h ^= h >> 16
    h = h &* 0x7feb352d
    h ^= h >> 15
    h = h &* 0x846ca68b
    h ^= h >> 16
    return h
}

public func hash(_ values: Int...) -> UInt32 {
    var h: UInt32 = 0
    for v in values {
        h = mix(h &+ 0x9e3779b9 &+ UInt32(truncatingIfNeeded: v))
    }
    return h
}

func random01(_ seed: UInt32, _ slot: Int) -> Double {
    Double(hash(Int(seed), slot)) / 4294967296
}

func drawRange(_ r: Range?, _ def: Double, _ seed: UInt32, _ slot: Int) -> Double {
    guard let r else { return def }
    switch r {
    case .constant(let v): return v
    case .between(let a, let b): return a + (b - a) * random01(seed, slot)
    }
}

func drawRotation(_ r: RotationRange?, _ seed: UInt32) -> Vec3 {
    Vec3(
        x: drawRange(r?.x, 0, seed, Slot.startRotationX),
        y: drawRange(r?.y, 0, seed, Slot.startRotationY),
        z: drawRange(r?.z, 0, seed, Slot.startRotation))
}
