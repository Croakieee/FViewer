import Foundation

public struct ExtraAttributes {
    public var uv2: [Float]
    public var uv3: [Float]
    public var uv4: [Float]
    public var color: [Float]
    public var z: [Float]
}

public final class GeometryData {
    public var positions: [Float]
    public var uvs: [Float]
    public var indices: [UInt32]
    public var extra: ExtraAttributes?
    public private(set) var version = 0
    public private(set) var indexVersion = 0

    public init(positions: [Float], uvs: [Float], indices: [UInt32], extra: ExtraAttributes? = nil) {
        self.positions = positions
        self.uvs = uvs
        self.indices = indices
        self.extra = extra
    }

    public var vertexCount: Int { positions.count / 2 }

    public func changed() { version += 1 }
    public func indicesChanged() { indexVersion += 1 }
}

private var quads: [String: GeometryData] = [:]

func quadGeometry(_ width: Double, _ height: Double) -> GeometryData {
    let key = "\(width)x\(height)"
    if let g = quads[key] { return g }
    let w = Float(width / 2), h = Float(height / 2)
    let g = GeometryData(positions: [-w, -h, w, -h, w, h, -w, h], uvs: [0, 0, 1, 0, 1, 1, 0, 1], indices: [0, 1, 2, 0, 2, 3])
    quads[key] = g
    return g
}

private var windmills: [String: GeometryData] = [:]

func windmillGeometry(_ size: Double, _ mirror: Bool) -> GeometryData {
    let key = "\(size)\(mirror ? "m" : "")"
    if let g = windmills[key] { return g }
    let h = size / 2
    var positions: [Float] = [], uvs: [Float] = [], indices: [UInt32] = []
    let signs: [(Double, Double)] = [(1, 1), (-1, 1), (-1, -1), (1, -1)]
    for k in 0..<4 {
        let c = cos(Double(k) * .pi / 2), s = sin(Double(k) * .pi / 2)
        let (sx, sy) = signs[k]
        let base = UInt32(positions.count / 2)
        for (a, b) in [(0.0, 0.0), (h, 0), (h, h), (0, h)] {
            let x = mirror ? sx * a : a * c - b * s
            let y = mirror ? sy * b : a * s + b * c
            positions += [Float(x), Float(-y)]
            uvs += [Float(1 - a / h), Float(1 - b / h)]
        }
        indices += [base, base + 1, base + 2, base, base + 2, base + 3]
    }
    let g = GeometryData(positions: positions, uvs: uvs, indices: indices)
    windmills[key] = g
    return g
}

private var meshes: [String: GeometryData] = [:]

func meshGeometry(_ name: String, _ model: ModelData, _ unit: Double) -> GeometryData {
    let key = "\(name)@\(unit)"
    if let g = meshes[key] { return g }
    let p = model.positions
    let n = p.count / 2
    var positions = [Float](repeating: 0, count: p.count)
    for i in stride(from: 0, to: p.count, by: 2) {
        positions[i] = Float(p[i] * unit)
        positions[i + 1] = Float(-p[i + 1] * unit)
    }
    let channel = { (c: Int) -> [Float] in (c < model.uvs.count ? model.uvs[c] : model.uvs[0]).map { Float($0 + 0.5) } }
    var color = [Float](repeating: 1, count: n * 4)
    for i in 0..<n {
        if let rgb = model.color {
            color[i * 4] = Float(rgb[i * 3])
            color[i * 4 + 1] = Float(rgb[i * 3 + 1])
            color[i * 4 + 2] = Float(rgb[i * 3 + 2])
        }
        if let a = model.alpha { color[i * 4 + 3] = Float(a[i]) }
    }
    let z = model.z.map { $0.map { Float($0 * unit) } } ?? [Float](repeating: 0, count: n)
    let g = GeometryData(
        positions: positions, uvs: channel(0), indices: model.indices,
        extra: ExtraAttributes(uv2: channel(1), uv3: channel(2), uv4: channel(3), color: color, z: z))
    meshes[key] = g
    return g
}

func ownMeshGeometry(_ shared: GeometryData) -> GeometryData {
    GeometryData(positions: shared.positions, uvs: shared.uvs, indices: shared.indices, extra: shared.extra)
}

final class RingGeometry {
    let data: GeometryData
    private let segments: Int, rows: Int
    private var shape = ""

    init(segments: Int, rows: Int) {
        let n = max(1, segments), m = max(1, rows)
        var uvs = [Float](repeating: 0, count: (n + 1) * (m + 1) * 2)
        var indices: [UInt32] = []
        for i in 0...n {
            for j in 0...m {
                uvs[(i * (m + 1) + j) * 2] = Float(i) / Float(n)
                uvs[(i * (m + 1) + j) * 2 + 1] = Float(j) / Float(m)
                if i < n && j < m {
                    let a = UInt32(i * (m + 1) + j), b = a + UInt32(m + 1)
                    indices += [a, a + 1, b, a + 1, b + 1, b]
                }
            }
        }
        data = GeometryData(positions: [Float](repeating: 0, count: (n + 1) * (m + 1) * 2), uvs: uvs, indices: indices)
        self.segments = n
        self.rows = m
    }

    func set(_ inner: Double, _ outer: Double, _ angle: Double) -> Bool {
        let key = "\(inner),\(outer),\(angle)"
        if key == shape { return false }
        shape = key
        let n = segments, m = rows
        for i in 0...n {
            let a = Double(i) / Double(n) * angle * .pi / 180
            for j in 0...m {
                let r = inner + (outer - inner) * Double(j) / Double(m)
                data.positions[(i * (m + 1) + j) * 2] = Float(cos(a) * r)
                data.positions[(i * (m + 1) + j) * 2 + 1] = Float(sin(a) * r)
            }
        }
        data.changed()
        return true
    }
}

final class RoundRectGeometry {
    let data: GeometryData
    private let corner: Int, rows: Int
    private var shape = ""

    init(cornerSegments: Int, rows: Int) {
        let c = max(1, cornerSegments), m = max(1, rows)
        let n = 4 * (c + 1) + 1
        var indices: [UInt32] = []
        for i in 0..<(n - 1) {
            for j in 0..<m {
                let a = UInt32(i * (m + 1) + j), b = a + UInt32(m + 1)
                indices += [a, a + 1, b, a + 1, b + 1, b]
            }
        }
        data = GeometryData(
            positions: [Float](repeating: 0, count: n * (m + 1) * 2), uvs: [Float](repeating: 0, count: n * (m + 1) * 2), indices: indices)
        corner = c
        self.rows = m
    }

    func set(_ width: Double, _ height: Double, _ radius: Double, _ thickness: Double, _ uLength: Double) -> Bool {
        let key = "\(width),\(height),\(radius),\(thickness),\(uLength)"
        if key == shape { return false }
        shape = key
        let c = corner, m = rows
        let hw = max(0, width / 2), hh = max(0, height / 2)
        let r = max(0, min(radius, hw, hh))
        let signs: [(Double, Double, Double)] = [(1, -1, -90), (1, 1, 0), (-1, 1, 90), (-1, -1, 180)]
        func at(_ cornerIndex: Int, _ k: Int, _ offset: Double) -> (Double, Double) {
            let (sx, sy, start) = signs[cornerIndex]
            let rr = max(0, r + offset)
            let a = (start + 90 * Double(k) / Double(c)) * .pi / 180
            return (sx * max(0, hw + offset - rr) + cos(a) * rr, sy * max(0, hh + offset - rr) + sin(a) * rr)
        }
        var loop: [(Int, Int)] = [(3, c)]
        for cornerIndex in 0..<4 { for k in 0...c { loop.append((cornerIndex, k)) } }
        var along = [0.0]
        var prev = at(loop[0].0, loop[0].1, 0)
        for i in 1..<loop.count {
            let p = at(loop[i].0, loop[i].1, 0)
            along.append(along[i - 1] + hypot(p.0 - prev.0, p.1 - prev.1))
            prev = p
        }
        let length = along.last! > 0 ? along.last! : 1
        let repeats = uLength > 0 ? max(1, (length / uLength).rounded()) : 1
        for (i, (cornerIndex, k)) in loop.enumerated() {
            let u = Float(along[i] / length * repeats)
            for j in 0...m {
                let p = at(cornerIndex, k, thickness * (Double(j) / Double(m) - 0.5))
                let o = (i * (m + 1) + j) * 2
                data.positions[o] = Float(p.0)
                data.positions[o + 1] = Float(p.1)
                data.uvs[o] = u
                data.uvs[o + 1] = Float(j) / Float(m)
            }
        }
        data.changed()
        return true
    }
}

struct TrailPoint {
    var x = 0.0, y = 0.0, z = 0.0
    var width = 0.0
    var line: [Float] = [1, 1, 1, 1]
    var edge: [Float] = [1, 1, 1, 1]
}

final class TrailGeometry {
    let data: GeometryData
    let count: Int

    init(points: Int) {
        let n = max(2, points)
        var uvs = [Float](repeating: 0, count: n * 3 * 2)
        var indices: [UInt32] = []
        for i in 0..<n {
            for j in 0..<3 {
                uvs[(i * 3 + j) * 2] = Float(j) / 2
                uvs[(i * 3 + j) * 2 + 1] = Float(i) / Float(n - 1)
            }
            if i < n - 1 {
                for j in 0..<2 {
                    let a = UInt32(i * 3 + j), b = a + 3
                    indices += [a, b, a + 1, a + 1, b, b + 1]
                }
            }
        }
        data = GeometryData(
            positions: [Float](repeating: 0, count: n * 3 * 2), uvs: uvs, indices: indices,
            extra: ExtraAttributes(
                uv2: uvs, uv3: uvs, uv4: uvs, color: [Float](repeating: 1, count: n * 3 * 4), z: [Float](repeating: 0, count: n * 3)))
        count = n
    }

    func set(_ points: [TrailPoint]) {
        let n = count
        for i in 0..<n {
            let p = points[i]
            let a = points[max(0, i - 1)], b = points[min(n - 1, i + 1)]
            var dx = b.x - a.x, dy = b.y - a.y
            let length = hypot(dx, dy)
            if length > 1e-6 {
                dx /= length
                dy /= length
            } else {
                dx = 1
                dy = 0
            }
            for j in 0..<3 {
                let o = i * 3 + j
                let side = Double(j - 1) * p.width
                data.positions[o * 2] = Float(p.x - dy * side)
                data.positions[o * 2 + 1] = Float(p.y + dx * side)
                data.extra!.z[o] = Float(p.z)
                let c = j == 1 ? p.line : p.edge
                for k in 0..<4 { data.extra!.color[o * 4 + k] = c[k] }
            }
        }
        data.changed()
    }
}

final class FaceOrder {
    private let geometry: GeometryData
    private let source: [UInt32]
    private var order: [Int]

    init(_ geometry: GeometryData) {
        self.geometry = geometry
        source = geometry.indices
        order = Array(0..<(geometry.indices.count / 3))
    }

    func update(_ depthOf: (Double, Double, Double) -> Double) {
        let p = geometry.positions
        let z = geometry.extra?.z ?? []
        var seen = [Double](repeating: 0, count: p.count / 2)
        for i in 0..<seen.count { seen[i] = depthOf(Double(p[i * 2]), Double(p[i * 2 + 1]), i < z.count ? Double(z[i]) : 0) }
        let src = source
        var depth = [Double](repeating: 0, count: order.count)
        for t in 0..<depth.count { depth[t] = seen[Int(src[t * 3])] + seen[Int(src[t * 3 + 1])] + seen[Int(src[t * 3 + 2])] }
        order.sort { depth[$0] < depth[$1] }
        for (i, t) in order.enumerated() {
            geometry.indices[i * 3] = src[t * 3]
            geometry.indices[i * 3 + 1] = src[t * 3 + 1]
            geometry.indices[i * 3 + 2] = src[t * 3 + 2]
        }
        geometry.indicesChanged()
    }
}
