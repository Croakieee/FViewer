import Foundation

public struct MaterialNode: Decodable {
    public var id: String
    public var type: String
    public var x: Double?
    public var y: Double?
    public var texture: String?
    public var params: [String: Double]?

    public init(id: String, type: String, x: Double? = nil, y: Double? = nil, texture: String? = nil, params: [String: Double]? = nil) {
        self.id = id
        self.type = type
        self.x = x
        self.y = y
        self.texture = texture
        self.params = params
    }
}

public struct MaterialLink: Decodable {
    public var from: String
    public var out: String
    public var to: String
    public var input: String

    enum CodingKeys: String, CodingKey {
        case from, out, to
        case input = "in"
    }

    public init(from: String, out: String, to: String, input: String) {
        self.from = from
        self.out = out
        self.to = to
        self.input = input
    }
}

public struct MaterialNodeKind {
    public let type: String
    public let title: String
    public let category: String
    public let inputs: [String]
    public let outputs: [String]
    public let params: [(name: String, value: Double)]
    public let texture: Bool
    public let help: String
}

public struct MaterialGraph: Decodable {
    public var nodes: [MaterialNode]
    public var links: [MaterialLink]

    public init(nodes: [MaterialNode], links: [MaterialLink]) {
        self.nodes = nodes
        self.links = links
    }

    public static let maxTextures = 3

    public static let categories = ["Particle", "Constants", "Coordinates", "Texture", "Math", "Utility", "Output"]

    private static func kind(_ type: String, _ title: String, _ category: String, _ inputs: [String], _ outputs: [String],
                             _ params: [(String, Double)], _ help: String) -> MaterialNodeKind {
        MaterialNodeKind(type: type, title: title, category: category, inputs: inputs, outputs: outputs, params: params.map { (name: $0.0, value: $0.1) },
                         texture: false, help: help)
    }

    private static func kind(_ type: String, _ title: String, _ category: String, _ inputs: [String], _ outputs: [String], _ help: String) -> MaterialNodeKind {
        MaterialNodeKind(type: type, title: title, category: category, inputs: inputs, outputs: outputs, params: [], texture: false, help: help)
    }

    private static func kind(_ type: String, _ title: String, _ category: String, _ inputs: [String], _ outputs: [String], texture: Bool,
                             _ help: String) -> MaterialNodeKind {
        MaterialNodeKind(type: type, title: title, category: category, inputs: inputs, outputs: outputs, params: [], texture: texture, help: help)
    }

    public static let kinds: [MaterialNodeKind] = [
        kind("layers", "Layer Stack", "Particle", [], ["rgb", "a"], "The particle's texture and its layers, combined as without a material"),
        kind("particleColor", "Particle Color", "Particle", [], ["rgb", "a"], "Colour, brightness and alpha of the particle at this moment"),
        kind("vertexColor", "Vertex Color", "Particle", [], ["rgb", "a"], "Colour stored in the vertices of the shape"),
        kind("age", "Particle Age", "Particle", [], ["out"], "Seconds since the particle appeared"),
        kind("life", "Relative Time", "Particle", [], ["out"], "0 when the particle appears, 1 when it ends"),
        kind("random", "Particle Random", "Particle", [], ["out"], "A number from 0 to 1 that differs between particles"),
        kind("band", "Edge Coordinate", "Particle", [], ["out"], "0 on the inner edge of the shape, 1 on the outer"),
        kind("float", "Constant", "Constants", [], ["out"], [("value", 1)], "One number"),
        kind("color", "Color", "Constants", [], ["rgb", "a"], [("r", 1), ("g", 1), ("b", 1), ("a", 1)], "A fixed colour"),
        kind("uv", "Texture Coordinate", "Coordinates", [], ["uv"], [("channel", 1)], "UV set 1 to 4 of the shape"),
        kind("tiling", "Tiling & Offset", "Coordinates", ["uv"], ["uv"], [("tileX", 1), ("tileY", 1), ("offsetX", 0), ("offsetY", 0)], "Repeats and shifts the UVs"),
        kind("panner", "Panner", "Coordinates", ["uv", "time"], ["uv"], [("speedX", 0.2), ("speedY", 0)], "Scrolls the UVs over time"),
        kind("rotator", "Rotator", "Coordinates", ["uv", "time"], ["uv"], [("speed", 0.25), ("centerX", 0.5), ("centerY", 0.5)],
             "Turns the UVs around a centre; speed is turns per second"),
        kind("texture", "Texture Sample", "Texture", ["uv"], ["rgb", "r", "g", "b", "a"], texture: true, "Reads a texture at the given UVs"),
        kind("add", "Add", "Math", ["a", "b"], ["out"], [("a", 0), ("b", 0)], "a + b"),
        kind("subtract", "Subtract", "Math", ["a", "b"], ["out"], [("a", 0), ("b", 0)], "a − b"),
        kind("multiply", "Multiply", "Math", ["a", "b"], ["out"], [("a", 1), ("b", 1)], "a × b"),
        kind("divide", "Divide", "Math", ["a", "b"], ["out"], [("a", 1), ("b", 1)], "a ÷ b"),
        kind("lerp", "Lerp", "Math", ["a", "b", "t"], ["out"], [("a", 0), ("b", 1), ("t", 0.5)], "Blends from a to b by t"),
        kind("min", "Min", "Math", ["a", "b"], ["out"], [("a", 0), ("b", 1)], "The smaller of two values"),
        kind("max", "Max", "Math", ["a", "b"], ["out"], [("a", 0), ("b", 1)], "The larger of two values"),
        kind("power", "Power", "Math", ["a", "b"], ["out"], [("a", 1), ("b", 2)], "a raised to b"),
        kind("oneMinus", "One Minus", "Math", ["x"], ["out"], [("x", 0)], "1 − x"),
        kind("abs", "Abs", "Math", ["x"], ["out"], [("x", 0)], "Absolute value"),
        kind("frac", "Frac", "Math", ["x"], ["out"], [("x", 0)], "Fractional part"),
        kind("sine", "Sine", "Math", ["x"], ["out"], [("x", 0)], "sin(x × 2π), mapped to 0…1"),
        kind("saturate", "Saturate", "Math", ["x"], ["out"], [("x", 0)], "Clamps to 0…1"),
        kind("clamp", "Clamp", "Math", ["x"], ["out"], [("x", 0), ("min", 0), ("max", 1)], "Clamps to a range"),
        kind("step", "Step", "Math", ["x"], ["out"], [("x", 0), ("edge", 0.5)], "0 below the edge, 1 above"),
        kind("smoothstep", "Smoothstep", "Math", ["x"], ["out"], [("x", 0), ("from", 0), ("to", 1)], "A soft step between two edges"),
        kind("desaturate", "Desaturate", "Utility", ["rgb"], ["out"], [("amount", 1)], "Moves a colour toward grey"),
        kind("radial", "Radial Falloff", "Utility", ["uv"], ["out"], [("radius", 0.5), ("softness", 0.5)], "1 in the centre of the UVs, fading to 0 at the radius"),
        kind("noise", "Noise", "Utility", ["uv", "time"], ["out"], [("scale", 6), ("speed", 0.5)], "Smooth animated noise from 0 to 1"),
        kind("split", "Split", "Utility", ["rgb"], ["r", "g", "b", "a"], "Takes a colour apart"),
        kind("combine", "Combine", "Utility", ["r", "g", "b", "a"], ["rgb"], [("r", 0), ("g", 0), ("b", 0), ("a", 1)], "Builds a colour from numbers"),
        kind("output", "Output", "Output", ["color", "alpha", "emissive"], [], "What the particle shows. Unwired inputs keep the layer stack's value"),
    ]

    public static func kind(of type: String) -> MaterialNodeKind? { kinds.first { $0.type == type } }

    public var textures: [String] {
        var names: [String] = []
        for node in nodes where node.type == "texture" {
            if let name = node.texture, !name.isEmpty, !names.contains(name) { names.append(name) }
        }
        return names
    }

    public struct Compiled {
        public var code: String
        public var textures: [String]
        public var problems: [String]
    }

    public func compile() -> Compiled {
        var lines: [String] = []
        var done: [String: Int] = [:]
        var visiting: Set<String> = []
        var problems: [String] = []
        var counter = 0
        let slots = Array(textures.prefix(MaterialGraph.maxTextures))
        if textures.count > MaterialGraph.maxTextures { problems.append("Only \(MaterialGraph.maxTextures) different textures can be sampled") }
        let byID = Dictionary(nodes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        func literal(_ value: Double) -> String { String(format: "%.6f", value.isFinite ? value : 0) }

        func param(_ node: MaterialNode, _ name: String) -> Double {
            node.params?[name] ?? MaterialGraph.kind(of: node.type)?.params.first { $0.name == name }?.value ?? 0
        }

        func emit(_ id: String) -> Int? {
            if let index = done[id] { return index }
            guard let node = byID[id], let kind = MaterialGraph.kind(of: node.type) else {
                problems.append("Unknown node \(id)")
                return nil
            }
            guard !visiting.contains(id) else {
                problems.append("The graph has a loop at \(kind.title)")
                return nil
            }
            visiting.insert(id)
            defer { visiting.remove(id) }

            func input(_ name: String) -> String {
                if let link = links.first(where: { $0.to == id && $0.input == name }), let source = emit(link.from),
                   let sourceKind = byID[link.from].flatMap({ MaterialGraph.kind(of: $0.type) }), sourceKind.outputs.contains(link.out) {
                    return "n\(source)_\(link.out)"
                }
                if name == "uv" { return "float4(channelUv(i, u.uvChannel.x) + 0.5, 0.0, 0.0)" }
                if name == "time" { return "float4(u.material.x)" }
                if name == "rgb" { return "float4(c.rgb, c.a)" }
                return "float4(\(literal(param(node, name))))"
            }

            counter += 1
            let index = counter
            let n = "n\(index)"
            func set(_ output: String, _ expression: String) { lines.append("    float4 \(n)_\(output) = \(expression);") }
            func p(_ name: String) -> String { literal(param(node, name)) }

            switch node.type {
            case "layers":
                set("rgb", "float4(c.rgb, c.a)")
                set("a", "float4(c.a)")
            case "particleColor":
                set("rgb", "float4(u.particleColor.rgb, u.particleColor.a)")
                set("a", "float4(u.particleColor.a)")
            case "vertexColor":
                set("rgb", "float4(i.color.rgb, i.color.a)")
                set("a", "float4(i.color.a)")
            case "age": set("out", "float4(u.material.x)")
            case "life": set("out", "float4(u.material.y)")
            case "random": set("out", "float4(u.material.z)")
            case "band": set("out", "float4(i.band)")
            case "float": set("out", "float4(\(p("value")))")
            case "color":
                set("rgb", "float4(\(p("r")), \(p("g")), \(p("b")), \(p("a")))")
                set("a", "float4(\(p("a")))")
            case "uv": set("uv", "float4(channelUv(i, \(p("channel"))) + 0.5, 0.0, 0.0)")
            case "tiling":
                set("uv", "float4(\(input("uv")).xy * float2(\(p("tileX")), \(p("tileY"))) + float2(\(p("offsetX")), \(p("offsetY"))), 0.0, 0.0)")
            case "panner":
                set("uv", "float4(\(input("uv")).xy + float2(\(p("speedX")), \(p("speedY"))) * \(input("time")).x, 0.0, 0.0)")
            case "rotator":
                let centre = "float2(\(p("centerX")), \(p("centerY")))"
                lines.append("    float \(n)_turn = \(input("time")).x * \(p("speed")) * 6.2831853;")
                lines.append("    float2 \(n)_d = \(input("uv")).xy - \(centre);")
                set("uv", "float4(float2(\(n)_d.x * cos(\(n)_turn) - \(n)_d.y * sin(\(n)_turn), \(n)_d.x * sin(\(n)_turn) + \(n)_d.y * cos(\(n)_turn)) + \(centre), 0.0, 0.0)")
            case "texture":
                if let name = node.texture, let slot = slots.firstIndex(of: name) {
                    lines.append("    float4 \(n)_s = straight(mat\(slot).sample(matSmp\(slot), \(input("uv")).xy));")
                } else {
                    lines.append("    float4 \(n)_s = float4(1.0);")
                }
                set("rgb", "\(n)_s")
                for channel in ["r", "g", "b", "a"] { set(channel, "float4(\(n)_s.\(channel))") }
            case "add": set("out", "\(input("a")) + \(input("b"))")
            case "subtract": set("out", "\(input("a")) - \(input("b"))")
            case "multiply": set("out", "\(input("a")) * \(input("b"))")
            case "divide": set("out", "\(input("a")) / max(abs(\(input("b"))), float4(1e-5)) * sign(\(input("b")) + float4(1e-9))")
            case "lerp": set("out", "mix(\(input("a")), \(input("b")), clamp(\(input("t")).x, 0.0, 1.0))")
            case "min": set("out", "min(\(input("a")), \(input("b")))")
            case "max": set("out", "max(\(input("a")), \(input("b")))")
            case "power": set("out", "pow(max(\(input("a")), float4(0.0)), \(input("b")))")
            case "oneMinus": set("out", "float4(1.0) - \(input("x"))")
            case "abs": set("out", "abs(\(input("x")))")
            case "frac": set("out", "fract(\(input("x")))")
            case "sine": set("out", "sin(\(input("x")) * 6.2831853) * 0.5 + 0.5")
            case "saturate": set("out", "clamp(\(input("x")), float4(0.0), float4(1.0))")
            case "clamp": set("out", "clamp(\(input("x")), float4(\(p("min"))), float4(\(p("max"))))")
            case "step": set("out", "step(float4(\(p("edge"))), \(input("x")))")
            case "smoothstep": set("out", "smoothstep(float4(\(p("from"))), float4(\(p("to")) + 1e-5), \(input("x")))")
            case "desaturate":
                lines.append("    float4 \(n)_in = \(input("rgb"));")
                set("out", "float4(mix(\(n)_in.rgb, float3(dot(\(n)_in.rgb, float3(0.299, 0.587, 0.114))), \(p("amount"))), \(n)_in.a)")
            case "radial":
                set("out", "float4(1.0 - smoothstep(\(p("radius")) * (1.0 - \(p("softness"))), \(p("radius")) + 1e-5, length(\(input("uv")).xy - 0.5)))")
            case "noise":
                set("out", "float4(materialNoise(\(input("uv")).xy * \(p("scale")) + \(input("time")).x * \(p("speed"))))")
            case "split":
                lines.append("    float4 \(n)_in = \(input("rgb"));")
                for channel in ["r", "g", "b", "a"] { set(channel, "float4(\(n)_in.\(channel))") }
            case "combine":
                set("rgb", "float4(\(input("r")).x, \(input("g")).x, \(input("b")).x, \(input("a")).x)")
            case "output":
                break
            default:
                problems.append("Unknown node type \(node.type)")
                return nil
            }
            done[id] = index
            return index
        }

        guard let output = nodes.first(where: { $0.type == "output" }) else {
            return Compiled(code: "", textures: slots, problems: ["The graph has no Output node"])
        }
        func wired(_ name: String) -> String? {
            guard let link = links.first(where: { $0.to == output.id && $0.input == name }), let source = emit(link.from),
                  let kind = byID[link.from].flatMap({ MaterialGraph.kind(of: $0.type) }), kind.outputs.contains(link.out) else { return nil }
            return "n\(source)_\(link.out)"
        }
        let color = wired("color"), alpha = wired("alpha"), emissive = wired("emissive")
        if let color { lines.append("    c.rgb = \(color).rgb;") }
        if let alpha { lines.append("    c.a = \(alpha).x;") }
        if let emissive { lines.append("    c.rgb += \(emissive).rgb;") }
        return Compiled(code: lines.joined(separator: "\n"), textures: slots, problems: problems)
    }
}
