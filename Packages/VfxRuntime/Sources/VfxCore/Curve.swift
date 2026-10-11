import Foundation

public typealias ParsedColor = [(time: Double, rgb: Rgb)]

public func parseColor(_ c: ColorParam?) throws -> ParsedColor {
    switch c {
    case nil: return [(0, Rgb(r: 1, g: 1, b: 1))]
    case .constant(let s): return [(0, try parseHex(s))]
    case .keys(let keys): return try keys.map { ($0.time, try parseHex($0.value)) }
    }
}

public func evalColor(_ keys: ParsedColor, _ t: Double) -> Rgb {
    guard let first = keys.first else { return Rgb(r: 1, g: 1, b: 1) }
    if t <= first.time { return first.rgb }
    for i in 1..<keys.count where t < keys[i].time {
        let a = keys[i - 1], b = keys[i]
        let f = (t - a.time) / (b.time - a.time)
        return Rgb(r: a.rgb.r + (b.rgb.r - a.rgb.r) * f, g: a.rgb.g + (b.rgb.g - a.rgb.g) * f, b: a.rgb.b + (b.rgb.b - a.rgb.b) * f)
    }
    return keys[keys.count - 1].rgb
}

public func evalParam(_ p: Param?, _ t0: Double, _ def: Double, _ total: Double? = nil) -> Double {
    guard let p else { return def }
    switch p {
    case .constant(let v): return v
    case .keys(let keys): return evalKeys(keys, t0, def)
    case .ref(let r): return r.cell.value * (r.times ?? 1) + (r.plus ?? 0)
    case .curve(let c):
        let after = c.after ?? .hold
        let t = after == .add ? (total ?? t0) : t0
        guard let first = c.keys.first, let last = c.keys.last, after != .hold, t > last.time, last.time > first.time else {
            return evalKeys(c.keys, t, def)
        }
        let span = last.time - first.time
        let cycles = ((t - first.time) / span).rounded(.down)
        let value = evalKeys(c.keys, t - cycles * span, def)
        return after == .add ? value + cycles * (last.value - first.value) : value
    }
}

private func evalKeys(_ keys: [Key], _ t: Double, _ def: Double) -> Double {
    guard let first = keys.first else { return def }
    if t <= first.time { return first.value }
    for i in 1..<keys.count where t < keys[i].time {
        let a = keys[i - 1], b = keys[i]
        let f = (t - a.time) / (b.time - a.time)
        return a.spline != nil ? spline(keys, i, f) : a.value + (b.value - a.value) * f
    }
    return keys[keys.count - 1].value
}

private func slope(_ keys: [Key], _ i: Int) -> Double {
    let k = keys[i]
    let prev = i > 0 ? keys[i - 1] : nil
    let next = i + 1 < keys.count ? keys[i + 1] : nil
    let dNext = next.map { $0.value - k.value } ?? prev.map { k.value - $0.value } ?? 0
    let dPrev = prev.map { k.value - $0.value } ?? dNext
    return 0.5 * (k.spline?.inWeight ?? 1) * dPrev + 0.5 * (k.spline?.outWeight ?? 1) * dNext
}

private func slopeScale(_ span: Double, _ other: Double?) -> Double {
    guard let other else { return 1 }
    return 2 * span / (span + other)
}

private func spline(_ keys: [Key], _ i: Int, _ f: Double) -> Double {
    let a = keys[i - 1], b = keys[i]
    let span = b.time - a.time
    let prev = i >= 2 ? keys[i - 2] : nil
    let next = i + 1 < keys.count ? keys[i + 1] : nil
    let m0 = slope(keys, i - 1) * slopeScale(span, prev.map { a.time - $0.time })
    let m1 = slope(keys, i) * slopeScale(span, next.map { $0.time - b.time })
    let f2 = f * f, f3 = f2 * f
    return (2 * f3 - 3 * f2 + 1) * a.value + (f3 - 2 * f2 + f) * m0 + (-2 * f3 + 3 * f2) * b.value + (f3 - f2) * m1
}

public func evalAxes(_ p: AxesParam?, _ t: Double, _ def: Double, _ total: Double) -> Vec3 {
    switch p {
    case nil: return Vec3(x: def, y: def, z: def)
    case .uniform(let q):
        let v = evalParam(q, t, def, total)
        return Vec3(x: v, y: v, z: v)
    case .axes(let a):
        return Vec3(x: evalParam(a.x, t, def, total), y: evalParam(a.y, t, def, total), z: evalParam(a.z, t, def, total))
    }
}

public func evalAxes2(_ p: Axes2Param?, _ t: Double, _ def: Double, _ total: Double) -> (x: Double, y: Double) {
    switch p {
    case nil: return (def, def)
    case .uniform(let q):
        let v = evalParam(q, t, def, total)
        return (v, v)
    case .axes(let a): return (evalParam(a.x, t, def, total), evalParam(a.y, t, def, total))
    }
}

public func evalVec3(_ p: Vec3Param?, _ t: Double, _ def: Double, _ total: Double) -> Vec3 {
    Vec3(x: evalParam(p?.x, t, def, total), y: evalParam(p?.y, t, def, total), z: evalParam(p?.z, t, def, total))
}
