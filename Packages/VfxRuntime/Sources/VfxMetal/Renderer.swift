import CoreGraphics
import Foundation
import ImageIO
import Metal
import VfxCore
import simd

public struct VfxTexture {
    public let texture: MTLTexture
    public let sampler: MTLSamplerState
}

public enum AddressMode: String {
    case repeat_ = "repeat"
    case mirror = "mirror-repeat"
    case clamp = "clamp-to-edge"

    var metal: MTLSamplerAddressMode {
        switch self {
        case .repeat_: return .repeat
        case .mirror: return .mirrorRepeat
        case .clamp: return .clampToEdge
        }
    }
}

public enum RendererError: Error {
    case shader(String)
}

struct VertexUniforms {
    var placement = matrix_identity_float4x4
    var view = SIMD4<Float>(1, 1, 1, 0)
    var pan = SIMD4<Float>(0, 0, 0, 0)
}

struct FragmentUniforms {
    var uv0 = matrix_identity_float3x3
    var uv1 = matrix_identity_float3x3
    var uv2 = matrix_identity_float3x3
    var uv3 = matrix_identity_float3x3
    var uvDistort = matrix_identity_float3x3
    var particleColor = SIMD4<Float>(1, 1, 1, 1)
    var edgeInner = SIMD4<Float>(1, 1, 1, 1)
    var edgeOuter = SIMD4<Float>(1, 1, 1, 1)
    var nineSlice = SIMD4<Float>(0, 0, 0, 0)
    var uvChannel = SIMD4<Float>(1, 1, 1, 1)
    var layerMode = SIMD4<Float>(0, 0, 0, 0)
    var layerAlphaMode = SIMD4<Float>(0, 0, 0, 0)
    var layerColorToAlpha = SIMD4<Float>(0, 0, 0, 0)
    var layerDistort = SIMD4<Float>(0, 0, 0, 0)
    var misc0 = SIMD4<Float>(1, 0, 0, 0)
    var misc1 = SIMD4<Float>(0, 0, 0, 0)
    var material = SIMD4<Float>(0, 0, 0, 0)
    var lightDir = SIMD4<Float>(0, 0, 1, 0)
    var lightColor = SIMD4<Float>(1, 1, 1, 1)
    var ambient = SIMD4<Float>(0.25, 0.25, 0.25, 1)
}

final class GeometryBuffers {
    let positions: MTLBuffer
    let uvs: MTLBuffer
    let uv2: MTLBuffer
    let uv3: MTLBuffer
    let uv4: MTLBuffer
    let color: MTLBuffer
    let z: MTLBuffer
    let indices: MTLBuffer
    let indexCount: Int
    private(set) var version: Int
    private(set) var indexVersion: Int

    init(_ device: MTLDevice, _ g: GeometryData) {
        func buffer<T>(_ a: [T]) -> MTLBuffer {
            a.withUnsafeBytes { device.makeBuffer(bytes: $0.baseAddress!, length: max(4, $0.count), options: .storageModeShared)! }
        }
        let n = g.vertexCount
        positions = buffer(g.positions)
        uvs = buffer(g.uvs)
        uv2 = buffer(g.extra?.uv2 ?? g.uvs)
        uv3 = buffer(g.extra?.uv3 ?? g.uvs)
        uv4 = buffer(g.extra?.uv4 ?? g.uvs)
        color = buffer(g.extra?.color ?? [Float](repeating: 1, count: n * 4))
        z = buffer(g.extra?.z ?? [Float](repeating: 0, count: n))
        indices = buffer(g.indices)
        indexCount = g.indices.count
        version = g.version
        indexVersion = g.indexVersion
    }

    func sync(_ g: GeometryData) {
        func copy<T>(_ a: [T], _ b: MTLBuffer) {
            a.withUnsafeBytes { b.contents().copyMemory(from: $0.baseAddress!, byteCount: min($0.count, b.length)) }
        }
        if g.version != version {
            version = g.version
            copy(g.positions, positions)
            copy(g.uvs, uvs)
            if let e = g.extra {
                copy(e.uv2, uv2)
                copy(e.uv3, uv3)
                copy(e.uv4, uv4)
                copy(e.color, color)
                copy(e.z, z)
            }
        }
        if g.indexVersion != indexVersion {
            indexVersion = g.indexVersion
            copy(g.indices, indices)
        }
    }
}

public final class MetalRenderer: ViewFactory {
    public let device: MTLDevice
    private var pipelines: [BlendMode: MTLRenderPipelineState] = [:]
    private var materialPipelines: [String: [BlendMode: MTLRenderPipelineState]] = [:]
    private var failedMaterials: Set<String> = []
    private let pixelFormat: MTLPixelFormat
    private let vertexFunction: MTLFunction?
    public static var lastMaterialError: String?
    private var textures: [String: VfxTexture] = [:]
    private let white: VfxTexture
    private var shared: [ObjectIdentifier: GeometryBuffers] = [:]
    private var views: [MetalParticleView] = []
    private var created = 0
    public private(set) var missingTextures = Set<String>()

    public init(device: MTLDevice, pixelFormat: MTLPixelFormat) throws {
        self.device = device
        self.pixelFormat = pixelFormat
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: particleShaderSource, options: nil)
        } catch {
            throw RendererError.shader(String(describing: error))
        }
        vertexFunction = library.makeFunction(name: "particleVertex")
        white = MetalRenderer.solid(device)
        pipelines = try makePipelines(vertex: vertexFunction, fragment: library.makeFunction(name: "particleFragment"))
    }

    private func makePipelines(vertex: MTLFunction?, fragment: MTLFunction?) throws -> [BlendMode: MTLRenderPipelineState] {
        var result: [BlendMode: MTLRenderPipelineState] = [:]
        for blend in [BlendMode.normal, .add, .screen, .opaque] {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = vertex
            d.fragmentFunction = fragment
            let a = d.colorAttachments[0]!
            a.pixelFormat = pixelFormat
            a.isBlendingEnabled = true
            a.rgbBlendOperation = .add
            a.alphaBlendOperation = .add
            switch blend {
            case .normal:
                a.sourceRGBBlendFactor = .one
                a.destinationRGBBlendFactor = .oneMinusSourceAlpha
                a.sourceAlphaBlendFactor = .one
                a.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            case .add:
                a.sourceRGBBlendFactor = .one
                a.destinationRGBBlendFactor = .one
                a.sourceAlphaBlendFactor = .one
                a.destinationAlphaBlendFactor = .one
            case .screen:
                a.sourceRGBBlendFactor = .one
                a.destinationRGBBlendFactor = .oneMinusSourceColor
                a.sourceAlphaBlendFactor = .one
                a.destinationAlphaBlendFactor = .oneMinusSourceAlpha
            case .opaque:
                a.isBlendingEnabled = false
            }
            result[blend] = try device.makeRenderPipelineState(descriptor: d)
        }
        return result
    }

    private static var checked: [String: String] = [:]

    public static func shaderProblem(_ graph: MaterialGraph, device: MTLDevice) -> String? {
        let body = graph.compile().code
        guard !body.isEmpty else { return nil }
        if let known = checked[body] { return known.isEmpty ? nil : known }
        var problem = ""
        do {
            _ = try device.makeLibrary(source: particleShaderHeader + particleFragmentSource(name: "materialFragment", body: body), options: nil)
        } catch {
            let text = String(describing: error)
            problem = text.components(separatedBy: "error: ").dropFirst().first?.components(separatedBy: "\n").first ?? text
        }
        if checked.count > 200 { checked = [:] }
        checked[body] = problem
        return problem.isEmpty ? nil : problem
    }

    func materialKey(_ compiled: MaterialGraph.Compiled) -> String? {
        let body = compiled.code
        guard !body.isEmpty else { return nil }
        if materialPipelines[body] != nil { return body }
        if failedMaterials.contains(body) { return nil }
        do {
            let library = try device.makeLibrary(source: particleShaderHeader + particleFragmentSource(name: "materialFragment", body: body), options: nil)
            materialPipelines[body] = try makePipelines(vertex: library.makeFunction(name: "particleVertex"),
                                                        fragment: library.makeFunction(name: "materialFragment"))
            MetalRenderer.lastMaterialError = nil
            return body
        } catch {
            failedMaterials.insert(body)
            MetalRenderer.lastMaterialError = String(describing: error)
            return nil
        }
    }

    func pipeline(_ blend: BlendMode, material: String?) -> MTLRenderPipelineState {
        if let material, let set = materialPipelines[material], let pipeline = set[blend] { return pipeline }
        return pipelines[blend]!
    }

    @discardableResult
    public func loadTexture(name: String, url: URL, u: AddressMode, v: AddressMode) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return false }
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let drawn = pixels.withUnsafeMutableBytes { buf -> Bool in
            guard let ctx = CGContext(
                data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return false }
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: w, height: h, mipmapped: false)
        d.usage = .shaderRead
        guard let t = device.makeTexture(descriptor: d) else { return false }
        t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: pixels, bytesPerRow: w * 4)
        textures[name] = VfxTexture(texture: t, sampler: sampler(u.metal, v.metal))
        return true
    }

    private func sampler(_ u: MTLSamplerAddressMode, _ v: MTLSamplerAddressMode) -> MTLSamplerState {
        let d = MTLSamplerDescriptor()
        d.minFilter = .linear
        d.magFilter = .linear
        d.sAddressMode = u
        d.tAddressMode = v
        return device.makeSamplerState(descriptor: d)!
    }

    private static func solid(_ device: MTLDevice) -> VfxTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        let t = device.makeTexture(descriptor: d)!
        t.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: [UInt8](repeating: 255, count: 4), bytesPerRow: 4)
        let s = MTLSamplerDescriptor()
        s.minFilter = .linear
        s.magFilter = .linear
        return VfxTexture(texture: t, sampler: device.makeSamplerState(descriptor: s)!)
    }

    func texture(_ name: String?) -> VfxTexture {
        guard let name else { return white }
        if let t = textures[name] { return t }
        missingTextures.insert(name)
        return white
    }

    public func hasTexture(_ name: String) -> Bool { true }

    public func textureSize(_ name: String) -> (width: Double, height: Double) {
        let t = texture(name).texture
        return (Double(t.width), Double(t.height))
    }

    public func createParticleView(_ spec: ParticleViewSpec) -> ParticleView {
        let buffers: GeometryBuffers
        if spec.ownsGeometry {
            buffers = GeometryBuffers(device, spec.geometry)
        } else if let b = shared[ObjectIdentifier(spec.geometry)] {
            buffers = b
        } else {
            buffers = GeometryBuffers(device, spec.geometry)
            shared[ObjectIdentifier(spec.geometry)] = buffers
        }
        created += 1
        let view = MetalParticleView(spec, buffers, renderer: self, order: created)
        views.append(view)
        return view
    }

    func remove(_ view: MetalParticleView) {
        views.removeAll { $0 === view }
    }

    public func reset() {
        views.removeAll()
        missingTextures.removeAll()
    }

    public func draw(_ encoder: MTLRenderCommandEncoder, half: SIMD2<Float>, zoom: Float, pan: SIMD2<Float>) {
        encoder.setFrontFacing(.counterClockwise)
        let ordered = views.sorted { $0.priority != $1.priority ? $0.priority < $1.priority : $0.order < $1.order }
        for v in ordered {
            v.encode(encoder, pipeline: pipeline(v.blend, material: v.materialKey), half: half, zoom: zoom, pan: pan)
        }
    }
}

final class MetalParticleView: ParticleView {
    let blend: BlendMode
    let priority: Double
    let order: Int
    private let geometry: GeometryData
    private let buffers: GeometryBuffers
    private weak var renderer: MetalRenderer?
    private let cull: Cull?
    private var vertex = VertexUniforms()
    private var perspective: Float = 0
    private var fragment = FragmentUniforms()
    private let textures: [VfxTexture]
    let materialKey: String?

    init(_ spec: ParticleViewSpec, _ buffers: GeometryBuffers, renderer: MetalRenderer, order: Int) {
        blend = spec.blend
        priority = spec.drawPriority
        self.order = order
        geometry = spec.geometry
        self.buffers = buffers
        self.renderer = renderer
        cull = spec.cull
        let t = spec.textures
        let layers = t.layers
        func perLayer(_ value: (ParticleLayer) -> Float) -> SIMD4<Float> {
            SIMD4((0..<3).map { $0 < layers.count ? value(layers[$0]) : 0 } + [0])
        }
        let combine: [TextureLayer.Combine: Float] = [.multiply: 1, .add: 2, .none: 3, .max: 4, .min: 5]
        fragment.layerMode = perLayer { combine[$0.combine]! }
        fragment.layerAlphaMode = perLayer { $0.alpha == .keep ? 1 : 0 }
        fragment.layerColorToAlpha = perLayer { $0.colorToAlpha ? 1 : 0 }
        fragment.layerDistort = perLayer { $0.distorted ? 1 : 0 }
        fragment.uvChannel = SIMD4(Float(t.baseChannel), Float(layers.count > 0 ? layers[0].channel : 1),
                                   Float(layers.count > 1 ? layers[1].channel : 1), Float(layers.count > 2 ? layers[2].channel : 1))
        fragment.misc0 = SIMD4(Float(t.distortion?.channel ?? 1), 0, t.distortion?.base == true ? 1 : 0, t.baseColorToAlpha ? 1 : 0)
        fragment.misc1 = SIMD4(t.baseLuminance ? 1 : 0, Float(spec.edgeSoftness.inner), Float(spec.edgeSoftness.outer), 0)
        fragment.edgeInner = SIMD4(spec.edgeColor.inner)
        fragment.edgeOuter = SIMD4(spec.edgeColor.outer)
        var bound = [
            renderer.texture(t.base),
            renderer.texture(layers.count > 0 ? layers[0].texture : nil),
            renderer.texture(layers.count > 1 ? layers[1].texture : nil),
            renderer.texture(layers.count > 2 ? layers[2].texture : nil),
            renderer.texture(t.distortion?.texture),
        ]
        if let graph = spec.material {
            let scene = graph.light ?? MaterialLight()
            let direction = scene.directionVector, tint = scene.colorVector, fill = scene.ambientVector
            fragment.lightDir = SIMD4(direction.x, direction.y, direction.z, 0)
            fragment.lightColor = SIMD4(tint.x, tint.y, tint.z, 1)
            fragment.ambient = SIMD4(fill.x, fill.y, fill.z, 1)
            let compiled = graph.compile()
            materialKey = renderer.materialKey(compiled)
            for slot in 0..<MaterialGraph.maxTextures { bound.append(renderer.texture(slot < compiled.textures.count ? compiled.textures[slot] : nil)) }
        } else {
            materialKey = nil
            for _ in 0..<MaterialGraph.maxTextures { bound.append(renderer.texture(nil)) }
        }
        textures = bound
    }

    func setMaterial(age: Double, life: Double, seed: Double) {
        fragment.material = SIMD4(Float(age), Float(life), Float(seed), 0)
    }

    func setPlacement(_ m: Affine3, perspective: Double) {
        vertex.placement = m.float4x4
        self.perspective = Float(perspective)
    }

    func setColor(_ color: Rgb, brightness: Double, alpha: Double) {
        fragment.particleColor = SIMD4(Float(color.r * brightness), Float(color.g * brightness), Float(color.b * brightness), Float(alpha))
    }

    func setUv(_ slot: UvSlot, scaleX: Double, scaleY: Double, scrollX: Double, scrollY: Double, rotation: Double) {
        let r = rotation * .pi / 180
        let c = cos(r), s = sin(r)
        let m = simd_float3x3(columns: (
            SIMD3(Float(scaleX * c), Float(-scaleY * s), 0),
            SIMD3(Float(scaleX * s), Float(scaleY * c), 0),
            SIMD3(Float(scrollX), Float(scrollY), 1)))
        switch slot {
        case .base: fragment.uv0 = m
        case .layer(0): fragment.uv1 = m
        case .layer(1): fragment.uv2 = m
        case .layer(_): fragment.uv3 = m
        case .distortion: fragment.uvDistort = m
        }
    }

    func setNineSlice(borderX: Double, borderY: Double, stretchX: Double, stretchY: Double) {
        fragment.nineSlice = SIMD4(Float(borderX), Float(borderY), Float(max(stretchX, 1e-3)), Float(max(stretchY, 1e-3)))
    }

    func setDistortPower(_ power: Double) {
        fragment.misc0.y = Float(power)
    }

    func geometryChanged() {
        buffers.sync(geometry)
    }

    func destroy() {
        renderer?.remove(self)
    }

    func encode(_ e: MTLRenderCommandEncoder, pipeline: MTLRenderPipelineState, half: SIMD2<Float>, zoom: Float, pan: SIMD2<Float>) {
        guard buffers.indexCount > 0 else { return }
        e.setRenderPipelineState(pipeline)
        e.setCullMode(cull == .inner ? .back : cull == .outer ? .front : .none)
        vertex.view = SIMD4(half.x, half.y, zoom, perspective)
        vertex.pan = SIMD4(pan.x, pan.y, 0, 0)
        let b = buffers
        for (i, buffer) in [b.positions, b.uvs, b.uv2, b.uv3, b.uv4, b.color, b.z].enumerated() {
            e.setVertexBuffer(buffer, offset: 0, index: i)
        }
        e.setVertexBytes(&vertex, length: MemoryLayout<VertexUniforms>.stride, index: 7)
        e.setFragmentBytes(&fragment, length: MemoryLayout<FragmentUniforms>.stride, index: 0)
        for (i, t) in textures.enumerated() {
            e.setFragmentTexture(t.texture, index: i)
            e.setFragmentSamplerState(t.sampler, index: i)
        }
        e.drawIndexedPrimitives(type: .triangle, indexCount: b.indexCount, indexType: .uint32, indexBuffer: b.indices, indexBufferOffset: 0)
    }
}
