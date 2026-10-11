import Foundation

struct CurveKeyPoint: Equatable {
    var time: Double
    var value: Double
    var interpolation: Int
    var tangentOut: Double
    var tangentIn: Double

    static let spline = 0
    static let linear = 1
    static let step = 2
}

enum CurveMath {
    static func sample(_ keys: [CurveKeyPoint], at t: Double) -> Double {
        guard let first = keys.first, let last = keys.last else { return 0 }
        if keys.count == 1 || t <= first.time { return first.value }
        if t >= last.time { return last.value }
        var i = 1
        while i < keys.count - 1 && keys[i].time < t { i += 1 }
        let a = keys[i - 1], b = keys[i]
        let span = b.time - a.time
        if span <= 0 { return b.value }
        let f = (t - a.time) / span
        switch a.interpolation {
        case CurveKeyPoint.linear:
            return a.value + (b.value - a.value) * f
        case CurveKeyPoint.step:
            return a.value
        default:
            let f2 = f * f, f3 = f2 * f
            let h00 = 2 * f3 - 3 * f2 + 1
            let h10 = f3 - 2 * f2 + f
            let h01 = -2 * f3 + 3 * f2
            let h11 = f3 - f2
            let before: Double? = i >= 2 ? a.time - keys[i - 2].time : nil
            let after: Double? = i + 1 < keys.count ? keys[i + 1].time - b.time : nil
            let m0 = tangent(keys, i - 1) * tangentScale(span, before)
            let m1 = tangent(keys, i) * tangentScale(span, after)
            return h00 * a.value + h10 * m0 + h01 * b.value + h11 * m1
        }
    }

    private static func tangent(_ keys: [CurveKeyPoint], _ i: Int) -> Double {
        let k = keys[i]
        let previous: CurveKeyPoint? = i > 0 ? keys[i - 1] : nil
        let next: CurveKeyPoint? = i + 1 < keys.count ? keys[i + 1] : nil
        let toNext = next.map { $0.value - k.value } ?? previous.map { k.value - $0.value } ?? 0
        let fromPrevious = previous.map { k.value - $0.value } ?? toNext
        return 0.5 * k.tangentIn * fromPrevious + 0.5 * k.tangentOut * toNext
    }

    private static func tangentScale(_ span: Double, _ other: Double?) -> Double {
        guard let other else { return 1 }
        return 2 * span / (span + other)
    }

    static func halfToFloat(_ h: UInt16) -> Float {
        let sign: UInt32 = UInt32(h & 0x8000) << 16
        let exponent = Int((h >> 10) & 0x1f)
        var mantissa = UInt32(h & 0x3ff)
        if exponent == 0 {
            if mantissa == 0 { return Float(bitPattern: sign) }
            var e = -1
            repeat {
                e += 1
                mantissa <<= 1
            } while mantissa & 0x400 == 0
            mantissa &= 0x3ff
            return Float(bitPattern: sign | UInt32(127 - 15 - e) << 23 | mantissa << 13)
        }
        if exponent == 31 { return Float(bitPattern: sign | 0x7f80_0000 | mantissa << 13) }
        return Float(bitPattern: sign | UInt32(exponent - 15 + 127) << 23 | mantissa << 13)
    }
}
