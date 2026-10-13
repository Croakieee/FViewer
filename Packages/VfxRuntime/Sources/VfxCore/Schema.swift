import Foundation

public final class ParamTable {
    public final class Cell {
        public var value: Double = 0
    }

    public private(set) var cells: [String: Cell] = [:]

    public init() {}

    public func cell(_ name: String) -> Cell {
        if let c = cells[name] { return c }
        let c = Cell()
        cells[name] = c
        return c
    }
}

public extension CodingUserInfoKey {
    static let paramTable = CodingUserInfoKey(rawValue: "vfx.paramTable")!
}

public struct Key: Decodable {
    public var time: Double
    public var value: Double
    public var spline: Spline?

    public struct Spline: Decodable {
        public var inWeight: Double
        public var outWeight: Double
        enum CodingKeys: String, CodingKey { case inWeight = "in", outWeight = "out" }
    }
}

public struct Curve: Decodable {
    public enum After: String, Decodable { case hold, `repeat`, add }
    public var keys: [Key]
    public var after: After?
}

public struct ParamRef: Decodable {
    public var param: String
    public var times: Double?
    public var plus: Double?
    public let cell: ParamTable.Cell

    enum CodingKeys: String, CodingKey { case param, times, plus }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        param = try c.decode(String.self, forKey: .param)
        times = try c.decodeIfPresent(Double.self, forKey: .times)
        plus = try c.decodeIfPresent(Double.self, forKey: .plus)
        guard let table = decoder.userInfo[.paramTable] as? ParamTable else {
            throw DecodingError.dataCorruptedError(forKey: .param, in: c, debugDescription: "no ParamTable in userInfo")
        }
        cell = table.cell(param)
    }
}

public enum Param: Decodable {
    case constant(Double)
    case keys([Key])
    case curve(Curve)
    case ref(ParamRef)

    private enum Probe: String, CodingKey { case keys, param }

    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if let v = try? single.decode(Double.self) { self = .constant(v); return }
        if let k = try? single.decode([Key].self) { self = .keys(k); return }
        let probe = try decoder.container(keyedBy: Probe.self)
        if probe.contains(.param) { self = .ref(try single.decode(ParamRef.self)); return }
        if probe.contains(.keys) { self = .curve(try single.decode(Curve.self)); return }
        throw DecodingError.dataCorruptedError(in: single, debugDescription: "not a number, keys, curve or param")
    }

    static func isParamObject(_ decoder: Decoder) -> Bool {
        guard let probe = try? decoder.container(keyedBy: Probe.self) else { return true }
        return probe.contains(.param) || probe.contains(.keys)
    }
}

public struct Vec2Param: Decodable {
    public var x: Param?
    public var y: Param?
}

public struct Vec3Param: Decodable {
    public var x: Param?
    public var y: Param?
    public var z: Param?
}

public enum AxesParam: Decodable {
    case uniform(Param)
    case axes(Vec3Param)

    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if (try? single.decode(Double.self)) != nil || (try? single.decode([Key].self)) != nil || Param.isParamObject(decoder) {
            self = .uniform(try single.decode(Param.self))
        } else {
            self = .axes(try single.decode(Vec3Param.self))
        }
    }
}

public enum Axes2Param: Decodable {
    case uniform(Param)
    case axes(Vec2Param)

    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if (try? single.decode(Double.self)) != nil || (try? single.decode([Key].self)) != nil || Param.isParamObject(decoder) {
            self = .uniform(try single.decode(Param.self))
        } else {
            self = .axes(try single.decode(Vec2Param.self))
        }
    }
}

public struct ColorKey: Decodable {
    public var time: Double
    public var value: String
}

public enum ColorParam: Decodable {
    case constant(String)
    case keys([ColorKey])

    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if let s = try? single.decode(String.self) { self = .constant(s) } else { self = .keys(try single.decode([ColorKey].self)) }
    }
}

public enum Range: Decodable {
    case constant(Double)
    case between(Double, Double)

    public init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if let v = try? single.decode(Double.self) { self = .constant(v); return }
        let pair = try single.decode([Double].self)
        guard pair.count == 2 else { throw DecodingError.dataCorruptedError(in: single, debugDescription: "range needs [min, max]") }
        self = .between(pair[0], pair[1])
    }

    var maxValue: Double {
        switch self {
        case .constant(let v): return v
        case .between(let a, let b): return max(a, b)
        }
    }

    var minValue: Double {
        switch self {
        case .constant(let v): return v
        case .between(let a, let b): return min(a, b)
        }
    }
}

public struct RotationRange: Decodable {
    public var x: Range?
    public var y: Range?
    public var z: Range?

    enum CodingKeys: String, CodingKey { case x, y, z }

    public init(from decoder: Decoder) throws {
        if let r = try? decoder.singleValueContainer().decode(Range.self) {
            z = r
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decodeIfPresent(Range.self, forKey: .x)
        y = try c.decodeIfPresent(Range.self, forKey: .y)
        z = try c.decodeIfPresent(Range.self, forKey: .z)
    }
}

public struct TurnValue: Decodable {
    public var x = 0.0
    public var y = 0.0
    public var z = 0.0

    enum CodingKeys: String, CodingKey { case x, y, z }

    public init(from decoder: Decoder) throws {
        if let v = try? decoder.singleValueContainer().decode(Double.self) {
            z = v
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0
        y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0
        z = try c.decodeIfPresent(Double.self, forKey: .z) ?? 0
    }
}

public struct EffectDef: Decodable {
    public var fps: Double?
    public var unit: Double?
    public var perspective: Double?
    public var params: [String: Double]?
    public var timelines: [TimelineDef]
    public var emitters: [EmitterDef]
    public var particles: [ParticleDef]

    public static func decode(_ data: Data, table: ParamTable) throws -> EffectDef {
        let decoder = JSONDecoder()
        decoder.userInfo[.paramTable] = table
        return try decoder.decode(EffectDef.self, from: data)
    }
}

public struct TimelineDef: Decodable {
    public var start: Double?
    public var trigger: Int?
    public var items: [TimelineItem]
}

public enum TimelineItem: Decodable {
    case emitter(id: String, start: Double?, end: Double?)
    case clip(Clip)

    public struct Clip: Decodable {
        public enum Kind: String, Decodable { case release, kill }
        public var clip: Kind
        public var start: Double?
        public var fade: Double?
    }

    enum CodingKeys: String, CodingKey { case emitter, start, end, clip }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.clip) {
            self = .clip(try decoder.singleValueContainer().decode(Clip.self))
        } else {
            self = .emitter(
                id: try c.decode(String.self, forKey: .emitter),
                start: try c.decodeIfPresent(Double.self, forKey: .start),
                end: try c.decodeIfPresent(Double.self, forKey: .end))
        }
    }

    var start: Double {
        switch self {
        case .emitter(_, let s, _): return s ?? 0
        case .clip(let c): return c.start ?? 0
        }
    }
}

public struct LoopSection: Decodable {
    public var start: Double
    public var end: Double
}

public enum RotationOrder: String, Decodable { case xyz, xzy, yxz, yzx, zxy, zyx }

public struct EmitterDef: Decodable {
    public var id: String
    public var life: Double
    public var position: Vec3Param?
    public var rotation: Param?
    public var rotationX: Param?
    public var rotationY: Param?
    public var rotationOrder: RotationOrder?
    public var startRotation: RotationRange?
    public var scale: AxesParam?
    public var loop: LoopSection?
    public var emission: Emission?
    public var color: ColorParam?
    public var brightness: Param?
    public var alpha: Param?
    public var items: [EmitterItem]
}

public struct Emission: Decodable {
    public struct Offset: Decodable {
        public var x: Range?
        public var y: Range?
        public var z: Range?
    }

    public struct Point: Decodable {
        public var x: Double
        public var y: Double
        public var z: Double?
    }

    public var offset: Offset?
    public var points: [Point]?
    public var speed: Range?
    public var direction: Range?
}

public enum Follow: String, Decodable { case always, spawn }

public struct EmitterItem: Decodable {
    public enum Target {
        case particle(String)
        case emitter(String)
    }

    public var target: Target
    public var delay: Double?
    public var `repeat`: Bool?
    public var interval: Double?
    public var count: Param?
    public var copyRotation: TurnValue?
    public var copyRotationOrder: RotationOrder?
    public var probability: Double?
    public var follow: Follow?
    public var inheritColor: Bool?
    public var life: Range?

    enum CodingKeys: String, CodingKey {
        case particle, emitter, delay, `repeat`, interval, count, copyRotation, copyRotationOrder, probability, follow, inheritColor, life
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let p = try c.decodeIfPresent(String.self, forKey: .particle) {
            target = .particle(p)
        } else {
            target = .emitter(try c.decode(String.self, forKey: .emitter))
        }
        delay = try c.decodeIfPresent(Double.self, forKey: .delay)
        `repeat` = try c.decodeIfPresent(Bool.self, forKey: .repeat)
        interval = try c.decodeIfPresent(Double.self, forKey: .interval)
        count = try c.decodeIfPresent(Param.self, forKey: .count)
        copyRotation = try c.decodeIfPresent(TurnValue.self, forKey: .copyRotation)
        copyRotationOrder = try c.decodeIfPresent(RotationOrder.self, forKey: .copyRotationOrder)
        probability = try c.decodeIfPresent(Double.self, forKey: .probability)
        follow = try c.decodeIfPresent(Follow.self, forKey: .follow)
        inheritColor = try c.decodeIfPresent(Bool.self, forKey: .inheritColor)
        life = try c.decodeIfPresent(Range.self, forKey: .life)
    }
}

public enum BlendMode: String, Decodable { case normal, add, screen }

public struct UvParam: Decodable {
    public var scale: Axes2Param?
    public var scroll: Vec2Param?
    public var rotation: Param?
    public var channel: Int?
}

public struct EdgeColor: Decodable {
    public var color: String?
    public var alpha: Double?
}

public struct EdgePair: Decodable {
    public var inner: EdgeColor?
    public var outer: EdgeColor?
}

public struct Softness: Decodable {
    public var inner: Double?
    public var outer: Double?
}

public struct Profile3<T: Decodable>: Decodable {
    public var begin: T?
    public var center: T?
    public var end: T?
}

public enum Shape: Decodable {
    case ring(innerRadius: Param, outerRadius: Param, angle: Param?, angleRandom: Double?, segments: Int?, rows: Int?, softness: Softness?, edgeColor: EdgePair?)
    case roundRect(width: Param, height: Param, thickness: Param, radius: Param?, uLength: Double?, cornerSegments: Int?, rows: Int?, softness: Softness?, edgeColor: EdgePair?)
    case decal
    case quad
    case windmill(mirror: Bool)
    case mesh(model: String)
    case trail(Trail)

    public struct Trail: Decodable {
        public var frames: Double
        public var points: Int
        public var center: Double
        public var width: Param
        public var widthProfile: Profile3<Double>?
        public var color: Profile3<EdgeColor>?
        public var edge: Profile3<EdgeColor>?
    }

    enum CodingKeys: String, CodingKey {
        case type, innerRadius, outerRadius, angle, angleRandom, segments, rows, softness, edgeColor
        case width, height, thickness, radius, uLength, cornerSegments, mirror, model
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "ring":
            self = .ring(
                innerRadius: try c.decode(Param.self, forKey: .innerRadius),
                outerRadius: try c.decode(Param.self, forKey: .outerRadius),
                angle: try c.decodeIfPresent(Param.self, forKey: .angle),
                angleRandom: try c.decodeIfPresent(Double.self, forKey: .angleRandom),
                segments: try c.decodeIfPresent(Int.self, forKey: .segments),
                rows: try c.decodeIfPresent(Int.self, forKey: .rows),
                softness: try c.decodeIfPresent(Softness.self, forKey: .softness),
                edgeColor: try c.decodeIfPresent(EdgePair.self, forKey: .edgeColor))
        case "roundRect":
            self = .roundRect(
                width: try c.decode(Param.self, forKey: .width),
                height: try c.decode(Param.self, forKey: .height),
                thickness: try c.decode(Param.self, forKey: .thickness),
                radius: try c.decodeIfPresent(Param.self, forKey: .radius),
                uLength: try c.decodeIfPresent(Double.self, forKey: .uLength),
                cornerSegments: try c.decodeIfPresent(Int.self, forKey: .cornerSegments),
                rows: try c.decodeIfPresent(Int.self, forKey: .rows),
                softness: try c.decodeIfPresent(Softness.self, forKey: .softness),
                edgeColor: try c.decodeIfPresent(EdgePair.self, forKey: .edgeColor))
        case "decal": self = .decal
        case "quad": self = .quad
        case "windmill": self = .windmill(mirror: try c.decodeIfPresent(Bool.self, forKey: .mirror) ?? false)
        case "mesh": self = .mesh(model: try c.decode(String.self, forKey: .model))
        case "trail": self = .trail(try decoder.singleValueContainer().decode(Trail.self))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c, debugDescription: "unknown shape \(type)")
        }
    }
}

public struct NineSlice: Decodable {
    public var borderX: Double
    public var borderY: Double
    public var stretch: Axes2Param

    enum CodingKeys: String, CodingKey { case border, stretch }
    struct XY: Decodable { var x: Double; var y: Double }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let b = try? c.decode(Double.self, forKey: .border) {
            borderX = b
            borderY = b
        } else {
            let b = try c.decode(XY.self, forKey: .border)
            borderX = b.x
            borderY = b.y
        }
        stretch = try c.decode(Axes2Param.self, forKey: .stretch)
    }
}

public struct TextureLayer: Decodable {
    public enum Combine: String, Decodable { case multiply, add, none, max, min }
    public enum AlphaMode: String, Decodable { case multiply, keep }
    public var texture: String
    public var uv: UvParam?
    public var colorToAlpha: Bool?
    public var combine: Combine?
    public var alpha: AlphaMode?
}

public struct Distortion: Decodable {
    public enum Target: Decodable, Equatable {
        case texture
        case layer(Int)

        public init(from decoder: Decoder) throws {
            let single = try decoder.singleValueContainer()
            if let i = try? single.decode(Int.self) { self = .layer(i) } else { _ = try single.decode(String.self); self = .texture }
        }
    }

    public var texture: String
    public var uv: UvParam?
    public var power: Param
    public var targets: [Target]?
}

public enum Cull: String, Decodable { case inner, outer }

public struct ParticleDef: Decodable {
    public var id: String
    public var texture: String?
    public var shape: Shape?
    public var uv: UvParam?
    public var nineSlice: NineSlice?
    public var colorToAlpha: Bool?
    public var luminance: Bool?
    public var layers: [TextureLayer]?
    public var distortion: Distortion?
    public var life: Range
    public var loop: LoopSection?
    public var stretchCurves: Bool?
    public var blend: BlendMode?
    public var drawPriority: Double?
    public var startRotation: RotationRange?
    public var startScale: Range?
    public var position: Vec3Param?
    public var rotation: Param?
    public var rotationX: Param?
    public var rotationY: Param?
    public var rotationOrder: RotationOrder?
    public var scale: AxesParam?
    public var cull: Cull?
    public var sortTriangles: Bool?
    public var color: ColorParam?
    public var brightness: Param?
    public var alpha: Param?
    public var material: MaterialGraph?

    var forever: Bool {
        if case .constant(let v) = life { return v == -1 }
        return false
    }
}

public struct ModelData: Decodable {
    public var positions: [Double]
    public var z: [Double]?
    public var indices: [UInt32]
    public var uvs: [[Double]]
    public var color: [Double]?
    public var alpha: [Double]?
}
