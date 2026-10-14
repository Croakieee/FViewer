import Foundation
import simd

struct PolylineColors {
    var begin = Vec4(1, 1, 1, 1)
    var center = Vec4(1, 1, 1, 1)
    var end = Vec4(1, 1, 1, 1)
    var edgeBegin = Vec4(1, 1, 1, 1)
    var edgeCenter = Vec4(1, 1, 1, 1)
    var edgeEnd = Vec4(1, 1, 1, 1)
}

final class PolylineTrail {
    let geometry = RenderGeometry()
    let data: RPolyline
    var historyFrames: Float = 20
    private var history: [(time: Float, position: Vec3)] = []
    private let points: Int
    private let across: Int

    init(_ data: RPolyline) {
        self.data = data
        points = max(2, data.pointCount)
        across = data.useEdge ? 3 : 2
        for _ in 0..<(points * across) { geometry.add(.zero, uv: .zero) }
        for i in 0..<(points - 1) {
            for j in 0..<(across - 1) {
                let a = UInt32(i * across + j)
                let b = a + UInt32(across)
                geometry.indices.append(contentsOf: [a, b, a + 1, a + 1, b, b + 1])
            }
        }
    }

    var drawable: Bool { history.count >= 2 }

    func setPoints(_ list: [Vec3]) {
        history = list.enumerated().map { (Float(list.count - 1 - $0.offset), $0.element) }.reversed()
        historyFrames = Float(max(1, list.count - 1))
    }

    func record(_ time: Float, _ position: Vec3) {
        if let last = history.last, time <= last.time {
            history[history.count - 1].position = position
            return
        }
        history.append((time, position))
        let keep = max(1, historyFrames)
        while history.count > 2, history[1].time <= time - keep { history.removeFirst() }
    }

    var spline = false
    var fixedSide: Vec3?

    private func at(_ t: Float) -> Vec3 {
        guard let first = history.first, let last = history.last else { return .zero }
        if t <= first.time { return first.position }
        for i in 1..<history.count where t <= history[i].time {
            let a = history[i - 1], b = history[i]
            let f = (t - a.time) / max(1e-6, b.time - a.time)
            guard spline else { return a.position + (b.position - a.position) * f }
            let p0 = i >= 2 ? history[i - 2].position : a.position, p3 = i + 1 < history.count ? history[i + 1].position : b.position
            let f2 = f * f, f3 = f2 * f
            let c1: Vec3 = b.position - p0
            let c2: Vec3 = 2 * p0 - 5 * a.position + 4 * b.position - p3
            let c3: Vec3 = 3 * a.position - p0 - 3 * b.position + p3
            let sum: Vec3 = 2 * a.position + c1 * f + c2 * f2 + c3 * f3
            return 0.5 * sum
        }
        return last.position
    }

    func build(camera: Vec3, width: Float, begin: Float, center: Float, end: Float, colors: PolylineColors) {
        guard let first = history.first, let last = history.last, history.count >= 2 else { return }
        let now = last.time
        let start = max(first.time, now - max(1, historyFrames))
        let centerK = min(1, max(0, Float(data.pointCountCenter) / Float(points - 1)))
        let step = (now - start) / Float(points - 1)
        func mix(_ k: Float) -> (first: Bool, amount: Float) {
            k <= centerK ? (true, centerK > 0 ? k / centerK : 1) : (false, (k - centerK) / max(1e-6, 1 - centerK))
        }
        for i in 0..<points {
            let k = Float(i) / Float(points - 1)
            let t = now - step * Float(i)
            let p = at(t)
            let direction = at(t + max(step, 0.5)) - at(t - max(step, 0.5))
            var side = fixedSide ?? simd_cross(direction, camera - p)
            side = simd_length_squared(side) < 1e-12 ? Vec3(0, 1, 0) : simd_normalize(side)
            let part = mix(k)
            let w = width * (part.first ? begin + (center - begin) * part.amount : center + (end - center) * part.amount)
            let line = part.first ? colors.begin + (colors.center - colors.begin) * part.amount : colors.center + (colors.end - colors.center) * part.amount
            let edge = part.first ? colors.edgeBegin + (colors.edgeCenter - colors.edgeBegin) * part.amount
                : colors.edgeCenter + (colors.edgeEnd - colors.edgeCenter) * part.amount
            for j in 0..<across {
                let a = Float(j) / Float(across - 1)
                let o = i * across + j
                geometry.setPosition(o, p + side * ((a - 0.5) * 2 * w))
                geometry.setColor(o, data.useEdge && j != 1 ? edge : line)
                geometry.vertices[o * RenderGeometry.stride + 10] = a - 0.5
                geometry.vertices[o * RenderGeometry.stride + 11] = 0.5 - k
                for extra in stride(from: 12, to: 18, by: 2) {
                    geometry.vertices[o * RenderGeometry.stride + extra] = a - 0.5
                    geometry.vertices[o * RenderGeometry.stride + extra + 1] = 0.5 - k
                }
            }
        }
        geometry.version += 1
    }
}
