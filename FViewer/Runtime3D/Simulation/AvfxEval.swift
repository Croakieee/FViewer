import Foundation
import simd

struct CurveTime {
    var t: Float
    var total: Float

    init(_ t: Float, total: Float? = nil) {
        self.t = t
        self.total = total ?? t
    }
}

extension RCurve {
    private func value(_ key: AvfxKey) -> Vec3 { color ? Vec3(key.x, key.y, key.z) : Vec3(repeating: key.z) }

    private func tangent(_ i: Int) -> Vec3 {
        let key = keys[i]
        let v = value(key)
        let previous: Vec3? = i > 0 ? value(keys[i - 1]) : nil
        let next: Vec3? = i + 1 < keys.count ? value(keys[i + 1]) : nil
        let toNext = next.map { $0 - v } ?? previous.map { v - $0 } ?? .zero
        let fromPrevious = previous.map { v - $0 } ?? toNext
        return 0.5 * key.y * fromPrevious + 0.5 * key.x * toNext
    }

    private func tangentScale(_ span: Float, _ other: Float?) -> Float {
        guard let other else { return 1 }
        return 2 * span / (span + other)
    }

    private func segment(_ i: Int, _ t: Float) -> Vec3 {
        let a = keys[i - 1], b = keys[i]
        let va = value(a), vb = value(b)
        let span = Float(b.time - a.time)
        if span <= 0 { return vb }
        let f = (t - Float(a.time)) / span
        let onArrival = PreviewRules.hot.stepKeyOnArrival
        if !color, onArrival ? b.type == 2 : a.type == 2 { return onArrival && t >= Float(b.time) ? vb : va }
        if color || a.type == 1 || a.type == 2 { return va + (vb - va) * f }
        let f2 = f * f, f3 = f2 * f
        let h00 = 2 * f3 - 3 * f2 + 1, h10 = f3 - 2 * f2 + f, h01 = -2 * f3 + 3 * f2, h11 = f3 - f2
        let before: Float? = i >= 2 ? Float(a.time - keys[i - 2].time) : nil
        let after: Float? = i + 1 < keys.count ? Float(keys[i + 1].time - b.time) : nil
        let m0 = tangent(i - 1) * tangentScale(span, before)
        let m1 = tangent(i) * tangentScale(span, after)
        return h00 * va + h10 * m0 + h01 * vb + h11 * m1
    }

    func eval3(_ time: CurveTime) -> Vec3 {
        let count = keys.count
        guard count > 0 else { return .zero }
        let first = keys[0]
        if count == 1 { return value(first) }
        let last = keys[count - 1]
        var t = post == 2 && PreviewRules.hot.periodicCurves ? time.total : time.t
        let start = Float(first.time), end = Float(last.time)
        let duration = end - start
        var cycles: Float = 0
        if t < start, duration > 0, pre == 1 || pre == 2 {
            cycles = ((t - start) / duration).rounded(.down)
            t -= cycles * duration
            if pre == 1 { cycles = 0 }
        } else if t > end, duration > 0, post == 1 || post == 2 {
            cycles = ((t - start) / duration).rounded(.down)
            t -= cycles * duration
            if post == 1 { cycles = 0 }
        }
        var out: Vec3
        if t <= start {
            out = value(first)
        } else if t >= end {
            out = value(last)
        } else {
            var i = 1
            while i < count - 1 && Float(keys[i].time) < t { i += 1 }
            out = segment(i, t)
        }
        if cycles != 0 { out += cycles * (value(last) - value(first)) }
        return out
    }
}

enum Eval {
    static func curve(_ curve: RCurve?, _ time: CurveTime, _ fallback: Float = 0) -> Float {
        guard let curve else { return fallback }
        return curve.eval3(time).x
    }

    static func randomOffset(_ random: RCurve?, type: Int, _ time: CurveTime, _ seed: Float) -> Float {
        guard let random else { return 0 }
        let type = random.random != 0 && PreviewRules.hot.randomTypeOnRandom ? random.random : type
        var seed = seed
        if type >= 3, PreviewRules.hot.randomAlwaysPerFrame {
            let mixed = sin(seed * 12.9898 + Float(Int(time.t.rounded(.down))) * 78.233) * 43758.5453
            seed = mixed - mixed.rounded(.down)
        }
        let amplitude = curve(random, time)
        switch type {
        case 1, 4: return amplitude * seed
        case 2, 5: return -amplitude * seed
        default: return amplitude * (seed * 2 - 1)
        }
    }

    static func withRandom(_ value: RCurve?, _ random: RCurve?, _ time: CurveTime, _ fallback: Float, _ seed: Float) -> Float {
        curve(value, time, fallback) + randomOffset(random, type: value?.random ?? 0, time, seed)
    }

    static func axes(_ c: RCurve3, _ time: CurveTime, _ fallback: Float, _ seed: RandomSeed, _ slot: Int) -> Vec3 {
        func linked(_ v: Vec3, _ mode: Int) -> Vec3 {
            var x = v.x, y = v.y, z = v.z
            switch mode {
            case 1: y = x; z = x
            case 2: y = x
            case 3: z = x
            case 4: x = y; z = y
            case 5: x = y
            case 6: z = y
            case 7: x = z; y = z
            case 8: x = z
            case 9: y = z
            default: break
            }
            return Vec3(x, y, z)
        }
        let base = Vec3(curve(c.x, time, fallback), curve(c.y, time, fallback), curve(c.z, time, fallback))
        var offsets = Vec3(randomOffset(c.rx, type: c.x?.random ?? 0, time, seed.get(slot)),
                           randomOffset(c.ry, type: c.y?.random ?? 0, time, seed.get(slot + 1)),
                           randomOffset(c.rz, type: c.z?.random ?? 0, time, seed.get(slot + 2)))
        if PreviewRules.hot.axisConnectRandom { offsets = linked(offsets, c.connectRandom) }
        return linked(base + offsets, c.connect)
    }

    static func color(_ c: RColor, _ time: CurveTime, _ seed: RandomSeed) -> Vec4 {
        var rgb = c.rgb?.eval3(time) ?? Vec3(1, 1, 1)
        var alpha = curve(c.a, time, 1)
        let brightness = curve(c.bri, time, 1) + randomOffset(c.ranBri, type: c.bri?.random ?? 0, time, seed.get(7))
        if PreviewRules.hot.colorRandom {
            rgb += Vec3(randomOffset(c.ranR, type: 0, time, seed.get(32)), randomOffset(c.ranG, type: 0, time, seed.get(33)),
                        randomOffset(c.ranB, type: 0, time, seed.get(34)))
            alpha += randomOffset(c.ranA, type: c.a?.random ?? 0, time, seed.get(35))
        }
        return Vec4(rgb.x * curve(c.sclR, time, 1) * brightness, rgb.y * curve(c.sclG, time, 1) * brightness,
                    rgb.z * curve(c.sclB, time, 1) * brightness, alpha * curve(c.sclA, time, 1))
    }
}
