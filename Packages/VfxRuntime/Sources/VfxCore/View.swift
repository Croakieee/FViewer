public enum UvSlot: Hashable {
    case base
    case distortion
    case layer(Int)
}

public let maxLayers = 3

public struct ParticleLayer {
    public var texture: String
    public var combine: TextureLayer.Combine
    public var alpha: TextureLayer.AlphaMode
    public var colorToAlpha: Bool
    public var distorted: Bool
    public var channel: Int
}

public struct ParticleTextures {
    public var base: String?
    public var baseColorToAlpha: Bool
    public var baseLuminance: Bool
    public var baseChannel: Int
    public var layers: [ParticleLayer]
    public var distortion: (texture: String, base: Bool, channel: Int)?
}

public struct ParticleViewSpec {
    public var geometry: GeometryData
    public var ownsGeometry: Bool
    public var textures: ParticleTextures
    public var blend: BlendMode
    public var drawPriority: Double
    public var edgeSoftness: (inner: Double, outer: Double)
    public var edgeColor: (inner: [Float], outer: [Float])
    public var cull: Cull?
}

public protocol ParticleView: AnyObject {
    func setPlacement(_ m: Affine3, perspective: Double)
    func setColor(_ color: Rgb, brightness: Double, alpha: Double)
    func setUv(_ slot: UvSlot, scaleX: Double, scaleY: Double, scrollX: Double, scrollY: Double, rotation: Double)
    func setNineSlice(borderX: Double, borderY: Double, stretchX: Double, stretchY: Double)
    func setDistortPower(_ power: Double)
    func geometryChanged()
    func destroy()
}

public protocol ViewFactory: AnyObject {
    func hasTexture(_ name: String) -> Bool
    func textureSize(_ name: String) -> (width: Double, height: Double)
    func createParticleView(_ spec: ParticleViewSpec) -> ParticleView
}
