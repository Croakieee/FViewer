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

    var softness: Float?
    var vFromHead = true
    private var chain: [Vec3]?
    private var chainTime: Float = 0
    private var lastTime: Float = 0
    private var lastPosition = Vec3.zero

    private func advanceChain(_ time: Float, _ position: Vec3) {
        guard var c = chain else {
            chain = [Vec3](repeating: position, count: points)
            chainTime = time
            lastTime = time
            lastPosition = position
            return
        }
        let steps = Int(((time - chainTime) * 2 + 1e-6).rounded(.down))
        let soft = min(1, max(0, softness ?? 0))
        let span = max(1e-6, time - lastTime)
        if steps > 0 {
            for s in 1...steps {
                for i in stride(from: c.count - 1, to: 0, by: -1) {
                    let k = 1 - soft * Float(i) / Float(c.count - 1)
                    c[i] += (c[i - 1] - c[i]) * k
                }
                let f = min(1, (chainTime + Float(s) / 2 - lastTime) / span)
                c[0] = lastPosition + (position - lastPosition) * f
            }
            chainTime += Float(steps) / 2
        }
        c[0] = position
        chain = c
        lastTime = time
        lastPosition = position
    }

    func record(_ time: Float, _ position: Vec3) {
        if softness != nil { advanceChain(time, position) } else { chain = nil }
        if let last = history.last, time <= last.time {
            history[history.count - 1].position = position
            return
        }
        history.append((time, position))
        let keep = max(1, historyFrames)
        while history.count > 2, history[1].time <= time - keep { history.removeFirst() }
    }

    var fixedSide: Vec3?

    private func at(_ t: Float) -> Vec3 {
        guard let first = history.first, let last = history.last else { return .zero }
        if t <= first.time { return first.position }
        for i in 1..<history.count where t <= history[i].time {
            let a = history[i - 1], b = history[i]
            let f = (t - a.time) / max(1e-6, b.time - a.time)
            return a.position + (b.position - a.position) * f
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
        var along = (0..<points).map { Float($0) / Float(points - 1) }
        if let chain, chain.count == points {
            var total: Float = 0
            var sums: [Float] = [0]
            for i in 1..<points {
                total += simd_distance(chain[i], chain[i - 1])
                sums.append(total)
            }
            if total > 1e-6 { along = sums.map { $0 / total } }
        }
        var lastDirection = Vec3.zero
        for i in 0..<points {
            let k = along[i]
            let p: Vec3
            var direction: Vec3
            if let chain, chain.count == points {
                p = chain[i]
                direction = chain[max(0, i - 1)] - chain[min(points - 1, i + 1)]
            } else {
                let t = now - step * Float(i)
                p = at(t)
                direction = at(t + max(step, 0.5)) - at(t - max(step, 0.5))
            }
            if simd_length_squared(direction) < 1e-8, simd_length_squared(lastDirection) > 0 { direction = lastDirection } else { lastDirection = direction }
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
                let v = vFromHead ? k - 0.5 : 0.5 - k
                for extra in stride(from: 10, to: 18, by: 2) {
                    geometry.vertices[o * RenderGeometry.stride + extra] = a - 0.5
                    geometry.vertices[o * RenderGeometry.stride + extra + 1] = v
                }
            }
        }
        geometry.version += 1
    }
}
