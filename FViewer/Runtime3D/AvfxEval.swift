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
        if color || a.type == 1 { return va + (vb - va) * f }
        if a.type == 2 { return va }
        let f2 = f * f, f3 = f2 * f
        let h00 = 2 * f3 - 3 * f2 + 1, h10 = f3 - 2 * f2 + f, h01 = -2 * f3 + 3 * f2, h11 = f3 - f2
        let before: Float? = i >= 2 ? Float(a.time - keys[i - 2].time) : nil
        let after: Float? = i + 1 < keys.count ? Float(keys[i + 1].time - b.time) : nil
        let m0 = tangent(i - 1) * tangentScale(span, before)
        let m1 = tangent(i) * tangentScale(span, after)
        return h00 * va + h10 * m0 + h01 * vb + h11 * m1
    }

    func eval3(_ time: CurveTime) -> Vec3 {
        guard let first = keys.first, let last = keys.last else { return .zero }
        if keys.count == 1 { return value(first) }
        var t = post == 2 ? time.total : time.t
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
            while i < keys.count - 1 && Float(keys[i].time) < t { i += 1 }
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
        let offsets = Vec3(randomOffset(c.rx, type: c.x?.random ?? 0, time, seed.get(slot)),
                           randomOffset(c.ry, type: c.y?.random ?? 0, time, seed.get(slot + 1)),
                           randomOffset(c.rz, type: c.z?.random ?? 0, time, seed.get(slot + 2)))
        return linked(base, c.connect) + linked(offsets, PreviewRules.isOn("axisConnectRandom") ? c.connectRandom : c.connect)
    }

    static func color(_ c: RColor, _ time: CurveTime, _ seed: RandomSeed) -> Vec4 {
        let rgb = c.rgb?.eval3(time) ?? Vec3(1, 1, 1)
        let brightness = curve(c.bri, time, 1) + (c.ranBri != nil ? curve(c.ranBri, time) * (seed.get(7) * 2 - 1) : 0)
        return Vec4(rgb.x * curve(c.sclR, time, 1) * brightness, rgb.y * curve(c.sclG, time, 1) * brightness,
                    rgb.z * curve(c.sclB, time, 1) * brightness, curve(c.a, time, 1) * curve(c.sclA, time, 1))
    }
}
