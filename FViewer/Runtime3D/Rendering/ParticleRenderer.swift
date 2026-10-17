import Metal
import simd

private struct ParticleUniforms {
    var view = matrix_identity_float4x4
    var projection = matrix_identity_float4x4
    var model = matrix_identity_float4x4
    var normalMatrix = matrix_identity_float4x4
    var color = Vec4(1, 1, 1, 1)
    var colorBegin = Vec4(1, 1, 1, 1)
    var colorEnd = Vec4(1, 1, 1, 1)
    var spriteColor = Vec4(1, 1, 1, 1)
    var spriteCell = Vec4(0, 0, 1, 1)
    var uvMatrix: (Vec4, Vec4, Vec4, Vec4, Vec4) = (Vec4(1, 0, 0, 1), Vec4(1, 0, 0, 1), Vec4(1, 0, 0, 1), Vec4(1, 0, 0, 1), Vec4(1, 0, 0, 1))
    var uvOffset: (Vec4, Vec4, Vec4, Vec4, Vec4) = (.zero, .zero, .zero, .zero, .zero)
    var layer: (Vec4, Vec4, Vec4, Vec4) = (.zero, .zero, .zero, .zero)
    var channels = Vec4.zero
    var misc = Vec4.zero
    var distortLayers = Vec4.zero
    var flags = Vec4.zero
    var flags2 = Vec4.zero
    var cameraPosition = Vec4.zero
    var debugColor = Vec4.zero
    var scene = Vec4.zero
    var scene2 = Vec4.zero
    var flags3 = Vec4.zero
    var flags4 = Vec4.zero
    var pixelUv = Vec4.zero
    var litDirection = Vec4.zero
    var litAmbient = Vec4.zero
    var litColor = Vec4.zero
    var fresnelAxis = Vec4.zero
    var pointPosition: (Vec4, Vec4) = (.zero, .zero)
    var pointColor: (Vec4, Vec4) = (.zero, .zero)
    var normalInfo = Vec4.zero
    var reflectInfo = Vec4.zero
    var decalInverse = matrix_identity_float4x4
    var decalInfo = Vec4.zero
    var decalPlane = Vec4.zero
    var sceneTint = Vec4(1, 1, 1, 1)
    var sceneFog = Vec4.zero
    var fogColor = Vec4.zero
}

struct PreviewScene: Equatable {
    var brightness: Float = 1
    var environment = Vec3(1, 1, 1)
    var sunlight = Vec3(1, 1, 1)
    var fog = false
    var fogColor = Vec3(0.55, 0.6, 0.68)
    var fogStart: Float = 20
    var fogEnd: Float = 120
    var toneMap = false
    var exposure: Float = 0
    var lightIntensity: Float = 4
}

struct LoadedTexture {
    var texture: MTLTexture
    var alphaOnly: Bool
    var cube: MTLTexture? = nil
}

private struct PreparedMaterial {
    var uniforms = ParticleUniforms()
    var textures: [MTLTexture?] = [nil, nil, nil, nil, nil, nil, nil]
    var samplers: [MTLSamplerState?] = [nil, nil, nil, nil, nil, nil, nil]
    var reflectCube: MTLTexture?
    var reflectFlat: MTLTexture?
    var frames: [MTLTexture?] = []
    var blend = 0
    var depthTest = true
    var depthWrite = false
    var cull = MTLCullMode.none
    var hasColorEnds = false
    var soft = false
    var screenCopy: Float = 0
}

private final class GeometryBuffers {
    let vertices: MTLBuffer
    let indices: MTLBuffer
    let indexCount: Int
    var version: Int
    var usedFrame = 0
    weak var owner: RenderGeometry?
    let vertexFloats: Int

    func matches(_ g: RenderGeometry) -> Bool { owner === g && g.indices.count == indexCount && g.vertices.count == vertexFloats && g.version == version }

    init?(_ device: MTLDevice, _ g: RenderGeometry) {
        owner = g
        vertexFloats = g.vertices.count
        guard !g.vertices.isEmpty, !g.indices.isEmpty,
              let vb = device.makeBuffer(bytes: g.vertices, length: g.vertices.count * 4),
              let ib = device.makeBuffer(bytes: g.indices, length: g.indices.count * 4) else { return nil }
        vertices = vb
        indices = ib
        indexCount = g.indices.count
        version = g.version
    }

    func sync(_ g: RenderGeometry) {
        guard g.version != version else { return }
        version = g.version
        vertices.contents().copyMemory(from: g.vertices, byteCount: min(g.vertices.count * 4, vertices.length))
    }
}

final class ParticleRenderer {
    private let device: MTLDevice
    private var pipelines: [MTLRenderPipelineState] = []
    private var depthStates: [MTLDepthStencilState] = []
    private var samplers: [Int: MTLSamplerState] = [:]
    private var white: MTLTexture?
    private var whiteCube: MTLTexture?
    private var samples = 4
    private lazy var emptyDepth: MTLTexture? = {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: 1, height: 1, mipmapped: false)
        descriptor.textureType = .type2DMultisample
        descriptor.sampleCount = samples
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        return device.makeTexture(descriptor: descriptor)
    }()
    var sceneColor: MTLTexture?
    var sceneDepth: MTLTexture?
    var viewport = SIMD2<Float>(1, 1)
    var clip = SIMD2<Float>(0.1, 2000)
    var softDistance: Float = 0.5
    var scene = PreviewScene()
    var globalFog: Float = 0
    var orthographic = false
    private var materials: [Int: PreparedMaterial] = [:]
    private var buffers: [ObjectIdentifier: GeometryBuffers] = [:]
    private var frameIndex = 0
    var textureProvider: (Int) -> LoadedTexture? = { _ in nil }

    init?(device: MTLDevice, pixelFormat: MTLPixelFormat, depthFormat: MTLPixelFormat, sampleCount: Int) {
        samples = max(sampleCount, 1)
        self.device = device
        guard let library = try? device.makeLibrary(source: ParticleShader.source, options: nil) else { return nil }
        let layout = MTLVertexDescriptor()
        let formats: [(MTLVertexFormat, Int)] = [(.float3, 0), (.float3, 12), (.float4, 24), (.float2, 40), (.float2, 48), (.float2, 56), (.float2, 64)]
        for (i, entry) in formats.enumerated() {
            layout.attributes[i].format = entry.0
            layout.attributes[i].offset = entry.1
        }
        layout.layouts[0].stride = RenderGeometry.stride * 4
        let factors: [(MTLBlendFactor, MTLBlendFactor, MTLBlendFactor, MTLBlendFactor)] = [
            (.sourceAlpha, .oneMinusSourceAlpha, .one, .oneMinusSourceAlpha),
            (.destinationColor, .zero, .zero, .one),
            (.sourceAlpha, .one, .zero, .one),
            (.zero, .oneMinusSourceColor, .zero, .one),
            (.oneMinusDestinationColor, .one, .zero, .one),
            (.one, .one, .zero, .one),
            (.one, .one, .zero, .one),
            (.one, .oneMinusSourceAlpha, .one, .oneMinusSourceAlpha),
            (.one, .one, .zero, .one),
        ]
        for (slot, factor) in factors.enumerated() {
            let d = MTLRenderPipelineDescriptor()
            d.vertexFunction = library.makeFunction(name: "particleVertex")
            d.fragmentFunction = library.makeFunction(name: "particleFragment")
            d.vertexDescriptor = layout
            d.rasterSampleCount = sampleCount
            d.depthAttachmentPixelFormat = depthFormat
            let a = d.colorAttachments[0]!
            a.pixelFormat = pixelFormat
            a.isBlendingEnabled = true
            a.sourceRGBBlendFactor = factor.0
            a.destinationRGBBlendFactor = factor.1
            a.sourceAlphaBlendFactor = factor.2
            a.destinationAlphaBlendFactor = factor.3
            if slot == 5 { a.rgbBlendOperation = .min }
            if slot == 6 { a.rgbBlendOperation = .max }
            guard let state = try? device.makeRenderPipelineState(descriptor: d) else { return nil }
            pipelines.append(state)
        }
        for test in [false, true] {
            for write in [false, true] {
                let d = MTLDepthStencilDescriptor()
                d.depthCompareFunction = test ? .lessEqual : .always
                d.isDepthWriteEnabled = write
                guard let state = device.makeDepthStencilState(descriptor: d) else { return nil }
                depthStates.append(state)
            }
        }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        white = device.makeTexture(descriptor: descriptor)
        white?.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: [UInt8](repeating: 255, count: 4), bytesPerRow: 4)
        whiteCube = device.makeTexture(descriptor: MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm, size: 1, mipmapped: false))
        for face in 0..<6 {
            whiteCube?.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, slice: face, withBytes: [UInt8](repeating: 255, count: 4),
                               bytesPerRow: 4, bytesPerImage: 4)
        }
    }

    func reset() {
        materials = [:]
        buffers = [:]
    }

    private static var mipQueue: MTLCommandQueue?

    static func makeCube(_ device: MTLDevice, _ decoded: DecodedTexture) -> MTLTexture? {
        guard decoded.faces.count == 6, decoded.width == decoded.height else { return nil }
        let size = decoded.width
        let descriptor = MTLTextureDescriptor.textureCubeDescriptor(pixelFormat: .rgba8Unorm, size: size, mipmapped: size > 1)
        descriptor.usage = size > 1 ? [.shaderRead, .renderTarget] : [.shaderRead]
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        for (face, pixels) in decoded.faces.enumerated() {
            texture.replace(region: MTLRegionMake2D(0, 0, size, size), mipmapLevel: 0, slice: face, withBytes: pixels,
                            bytesPerRow: size * 4, bytesPerImage: size * size * 4)
        }
        if size > 1 {
            if mipQueue == nil { mipQueue = device.makeCommandQueue() }
            if let buffer = mipQueue?.makeCommandBuffer(), let blit = buffer.makeBlitCommandEncoder() {
                blit.generateMipmaps(for: texture)
                blit.endEncoding()
                buffer.commit()
            }
        }
        return texture
    }

    static func makeTexture(_ device: MTLDevice, _ decoded: DecodedTexture) -> MTLTexture? {
        let mipped = decoded.width > 1 && decoded.height > 1
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: decoded.width, height: decoded.height, mipmapped: mipped)
        descriptor.usage = mipped ? [.shaderRead, .renderTarget] : [.shaderRead]
        guard let texture = device.makeTexture(descriptor: descriptor) else { return nil }
        texture.replace(region: MTLRegionMake2D(0, 0, decoded.width, decoded.height), mipmapLevel: 0, withBytes: decoded.rgba,
                        bytesPerRow: decoded.width * 4)
        if mipped {
            if mipQueue == nil { mipQueue = device.makeCommandQueue() }
            if let buffer = mipQueue?.makeCommandBuffer(), let blit = buffer.makeBlitCommandEncoder() {
                blit.generateMipmaps(for: texture)
                blit.endEncoding()
                buffer.commit()
            }
        }
        return texture
    }

    private func sampler(_ u: Int, _ v: Int, filter: Int = 1, mipmaps: Bool = true) -> MTLSamplerState? {
        let level = PreviewRules.isOn("textureFilter") ? min(max(filter, 0), 4) : 1
        let key = u * 3 + v + level * 16 + (mipmaps ? 0 : 128)
        if let cached = samplers[key] { return cached }
        func mode(_ border: Int) -> MTLSamplerAddressMode { border == 1 ? .clampToEdge : border == 2 ? .mirrorRepeat : .repeat }
        let d = MTLSamplerDescriptor()
        d.minFilter = .linear
        d.magFilter = .linear
        d.mipFilter = mipmaps ? .linear : .notMipmapped
        d.maxAnisotropy = level >= 2 ? [4, 8, 16][level - 2] : 1
        d.sAddressMode = mode(u)
        d.tAddressMode = mode(v)
        let state = device.makeSamplerState(descriptor: d)
        samplers[key] = state
        return state
    }

    private func prepare(_ ps: RParticle) -> PreparedMaterial {
        var m = PreparedMaterial()
        let plainUv = PreviewRules.isOn("plainUv") && (ps.type == 2 || (ps.type == 1 && ps.simple == nil))
        let isModel = ps.type == 5 || ps.type == 13 || ps.type == 14
        let mipmaps = !((ps.type == 10 || ps.type == 11) && PreviewRules.isOn("decalNoMipmaps"))
        let layers: [RTextureLayer?] = [ps.tc1, plainUv ? nil : ps.tc2, plainUv ? nil : ps.tc3, plainUv ? nil : ps.tc4]
        let slots = [0, 1, 3, 4]
        var loaded: [LoadedTexture?] = [nil, nil, nil, nil]
        var flags: [Vec4] = [.zero, .zero, .zero, .zero]
        let copiesScene = PreviewRules.isOn("screenCopy") && ps.tc1?.enabled == true && ps.tc1?.screenCopy == true
        for (i, layer) in layers.enumerated() {
            if i == 0, copiesScene { continue }
            guard let layer, layer.enabled, let first = layer.textures.first, let texture = textureProvider(first) else { continue }
            loaded[i] = texture
            var calcColor = layer.calcColor
            if i > 0, (calcColor == 1 && texture.alphaOnly && PreviewRules.isOn("addAlphaOnly")) || (calcColor == 5 && PreviewRules.isOn("calcColorFive")) { calcColor = 9 }
            flags[i] = Vec4(1, Float(calcColor), Float(layer.calcAlpha), layer.colorToAlpha ? 1 : 0)
            m.textures[slots[i]] = texture.texture
            m.samplers[slots[i]] = sampler(layer.borderU, layer.borderV, filter: layer.filter, mipmaps: mipmaps)
        }
        m.uniforms.layer = (flags[0], flags[1], flags[2], flags[3])
        if let tc1 = ps.tc1, loaded[0] != nil { m.frames = tc1.textures.map { textureProvider($0)?.texture } }
        var distortion: RTextureLayer?
        if PreviewRules.isOn("distortion"), let td = ps.distortion, td.enabled, let first = td.textures.first, let texture = textureProvider(first) {
            distortion = td
            m.textures[2] = texture.texture
            m.samplers[2] = sampler(td.borderU, td.borderV, filter: td.filter, mipmaps: mipmaps)
        }
        func distorted(_ layer: RTextureLayer?, _ present: Bool) -> Float {
            guard let distortion, let layer, present, layer.uvSet >= 0, layer.uvSet < 4 else { return 0 }
            return distortion.targets[layer.uvSet] ? 1 : 0
        }
        m.uniforms.distortLayers = Vec4(distorted(layers[0], loaded[0] != nil), distorted(layers[1], loaded[1] != nil),
                                        distorted(layers[2], loaded[2] != nil), distorted(layers[3], loaded[3] != nil))
        var palette = false
        let channels = PreviewRules.isOn("paletteChannels")
        if channels || PreviewRules.isOn("paletteAlpha"), let tp = ps.palette, tp.enabled, tp.texture >= 0, let texture = textureProvider(tp.texture) {
            palette = true
            m.textures[5] = texture.texture
            m.samplers[5] = sampler(tp.border, tp.border)
        }
        if ps.lit, PreviewRules.isOn("normalMap"), let tn = ps.normalLayer, tn.enabled, let first = tn.textures.first, let texture = textureProvider(first) {
            m.textures[6] = texture.texture
            m.samplers[6] = sampler(tn.borderU, tn.borderV)
            let sets = [ps.tc1, ps.tc2, ps.distortion, ps.tc3, ps.tc4].map { $0?.uvSet }
            m.uniforms.normalInfo = Vec4(1, Float(sets.firstIndex { $0 == tn.uvSet } ?? 0), 1, 0)
        }
        if PreviewRules.isOn("reflectionLayer"), let tr = ps.reflection, tr.enabled, let first = tr.textures.first, let texture = textureProvider(first) {
            if let cube = texture.cube { m.reflectCube = cube } else { m.reflectFlat = texture.texture }
            m.uniforms.reflectInfo = Vec4(texture.cube != nil ? 1 : 2, Float(tr.calcColor), 0, 0)
        }
        func channel(_ layer: RTextureLayer?) -> Float { isModel ? Float(min(max(layer?.uvSet ?? 0, 0), 3)) : 0 }
        m.uniforms.channels = Vec4(channel(layers[0]), channel(layers[1]), channel(distortion), channel(layers[2]))
        m.uniforms.misc = Vec4(channel(layers[3]), 0, 0, ps.depthOffset)
        let mode = ps.drawMode >= 9 && ps.drawMode <= 12 ? ps.drawMode - 8 : ps.drawMode
        switch mode {
        case 1: m.blend = 1
        case 2: m.blend = 2
        case 3: m.blend = 3
        case 4: m.blend = 4
        case 6: m.blend = 5
        case 7: m.blend = 6
        default: m.blend = 0
        }
        let blendBeforeClamp = (mode == 0 || mode == 8) && PreviewRules.isOn("blendBeforeClamp")
        if blendBeforeClamp { m.blend = 7 }
        let addBeforeClamp = mode == 2 && PreviewRules.isOn("addBeforeClamp")
        if addBeforeClamp { m.blend = 8 }
        let premultiply: Float = mode == 4 || mode == 3 || mode == 7 || blendBeforeClamp || addBeforeClamp ? 1 : mode == 1 || mode == 6 ? 2 : 0
        let fresnel = isModel && ps.fresnelType != 0 && (ps.colorBegin != nil || ps.colorEnd != nil) && PreviewRules.isOn("modelFresnel")
        let lineGradient = ps.type == 3 && (ps.colorBegin != nil || ps.colorEnd != nil) && PreviewRules.isOn("lineGradient")
        let sprites = ps.simple != nil && (ps.type == 1 || ps.type == 3)
        let vertexColors = isModel || ps.type == 12 || ps.type == 6
        m.uniforms.flags = Vec4(vertexColors ? 1 : 0, fresnel ? 1 : 0, sprites ? 1 : 0, lineGradient ? 1 : 0)
        let paletteChannels = palette && channels && loaded[0] != nil
        m.uniforms.flags2 = Vec4(premultiply, distortion != nil ? 1 : 0, palette && !paletteChannels ? 1 : 0, PreviewRules.isOn("tc1Luminance") ? 1 : 0)
        let tc1White = PreviewRules.isOn("textureLessTc1White") && (ps.tc1 == nil || ps.tc1?.enabled == false || ps.tc1?.textures.isEmpty == true)
            && loaded[0] == nil && !copiesScene
        let tc1NoAlpha = tc1White && ps.tc1?.enabled != true && PreviewRules.isOn("tc1OffNoAlpha") && (loaded[1] != nil || loaded[2] != nil || loaded[3] != nil)
        m.uniforms.flags3 = Vec4(PreviewRules.isOn("distortionHalfRange") ? 1 : 0, paletteChannels ? 1 : 0, PreviewRules.isOn("softQuadratic") ? 1 : 0,
                                 tc1NoAlpha ? 2 : tc1White ? 1 : 0)
        m.uniforms.flags4 = Vec4(PreviewRules.isOn("tc1Luminance") && PreviewRules.isOn("tc1MultiplyWhite") ? 1 : 0, PreviewRules.isOn("depthOffsetCentre") ? 1 : 0, 0, PreviewRules.isOn("distortionKeepsFootprint") ? 1 : 0)
        if PreviewRules.isOn("pixelPositionUv") {
            func pixel(_ layer: RTextureLayer?) -> Float {
                guard let layer, layer.uvSet >= 0, layer.uvSet < ps.uvSets.count else { return 0 }
                return ps.uvSets[layer.uvSet].pixelPosition ? 1 : 0
            }
            m.uniforms.pixelUv = Vec4(pixel(ps.tc1), pixel(ps.tc2), pixel(ps.distortion), pixel(ps.tc3))
            m.uniforms.flags4.z = pixel(ps.tc4)
        }
        m.hasColorEnds = fresnel || lineGradient
        m.soft = ps.softParticle && PreviewRules.isOn("softParticles")
        if copiesScene {
            let shifted = distortion != nil && (ps.tc1.map { $0.uvSet >= 0 && $0.uvSet < 4 && distortion?.targets[$0.uvSet] == true } ?? false)
            m.screenCopy = shifted ? 2 : 1
        }
        m.depthTest = ps.depthTest
        m.depthWrite = ps.depthWrite
        if ps.type == 10 || ps.type == 11 || ps.type == 6 {
            m.cull = .none
        } else if ps.culling == 2 {
            m.cull = PreviewRules.isOn("cullingWinding") ? .front : .back
        } else if ps.culling == 1 {
            m.cull = PreviewRules.isOn("cullingWinding") ? .back : .front
        }
        return m
    }

    static func debugColor(_ index: Int) -> Vec4 {
        let hue = (Float(index) * 0.618034).truncatingRemainder(dividingBy: 1) * 6
        let x = 1 - abs(hue.truncatingRemainder(dividingBy: 2) - 1)
        let rgb: Vec3
        switch Int(hue) {
        case 0: rgb = Vec3(1, x, 0)
        case 1: rgb = Vec3(x, 1, 0)
        case 2: rgb = Vec3(0, 1, x)
        case 3: rgb = Vec3(0, x, 1)
        case 4: rgb = Vec3(x, 0, 1)
        default: rgb = Vec3(1, 0, x)
        }
        let soft = rgb * 0.75 + Vec3(0.25, 0.25, 0.25)
        return Vec4(soft.x, soft.y, soft.z, 0.9)
    }

    func needsScene(_ particles: [RParticle]) -> Bool {
        let decals = PreviewRules.isOn("decalProjection")
        return particles.contains { $0.softParticle || ($0.tc1?.enabled == true && $0.tc1?.screenCopy == true) || (decals && ($0.type == 10 || $0.type == 11)) }
    }

    func draw(_ encoder: MTLRenderCommandEncoder, draws: [ParticleDraw], particles: [RParticle], view: Mat4, projection: Mat4, camera: Vec3,
              shading: Int) {
        if shading != 1 { drawPass(encoder, draws: draws, particles: particles, view: view, projection: projection, camera: camera, wire: false) }
        if shading != 0 { drawPass(encoder, draws: draws, particles: particles, view: view, projection: projection, camera: camera, wire: true) }
        encoder.setTriangleFillMode(.fill)
    }

    func drawHighlight(_ encoder: MTLRenderCommandEncoder, draws: [ParticleDraw], particles: [RParticle], view: Mat4, projection: Mat4, camera: Vec3,
                       color: Vec4) {
        drawPass(encoder, draws: draws, particles: particles, view: view, projection: projection, camera: camera, wire: true, wireColor: color)
        encoder.setTriangleFillMode(.fill)
    }

    private func drawPass(_ encoder: MTLRenderCommandEncoder, draws: [ParticleDraw], particles: [RParticle], view: Mat4, projection: Mat4,
                          camera: Vec3, wire: Bool, wireColor: Vec4? = nil) {
        frameIndex += 1
        encoder.setFrontFacing(.counterClockwise)
        encoder.setTriangleFillMode(wire ? .lines : .fill)
        let softDepthOffset: Float = PreviewRules.isOn("softDepthOffset") ? 1 : 0
        let fallbackSampler = sampler(0, 0)
        var boundPipeline: ObjectIdentifier?, boundDepth: ObjectIdentifier?, boundCull: MTLCullMode?, boundVertices: ObjectIdentifier?
        var boundTextures = [ObjectIdentifier??](repeating: .none, count: 11), boundSamplers = [ObjectIdentifier??](repeating: .none, count: 7)
        func bind(_ texture: MTLTexture?, _ slot: Int) {
            let id = texture.map { ObjectIdentifier($0) }
            if boundTextures[slot] != .some(id) {
                encoder.setFragmentTexture(texture, index: slot)
                boundTextures[slot] = .some(id)
            }
        }
        for draw in draws {
            guard draw.particle < particles.count else { continue }
            if materials[draw.particle] == nil { materials[draw.particle] = prepare(particles[draw.particle]) }
            guard let material = materials[draw.particle] else { continue }
            let key = ObjectIdentifier(draw.geometry)
            if buffers[key]?.matches(draw.geometry) != true { buffers[key] = GeometryBuffers(device, draw.geometry) }
            guard let geometry = buffers[key] else { continue }
            geometry.sync(draw.geometry)
            geometry.usedFrame = frameIndex
            var u = material.uniforms
            u.view = view
            u.projection = projection
            u.model = draw.model
            u.normalMatrix = draw.model.inverse.transpose
            u.color = draw.color
            u.colorBegin = draw.colorBegin
            u.colorEnd = draw.colorEnd
            u.litDirection = Vec4(draw.light.direction.x, draw.light.direction.y, draw.light.direction.z, Float(draw.lit))
            u.litAmbient = Vec4(draw.light.ambient.x, draw.light.ambient.y, draw.light.ambient.z, 0)
            u.litColor = Vec4(draw.light.color.x, draw.light.color.y, draw.light.color.z, 0)
            u.fresnelAxis = draw.fresnelAxis
            u.pointPosition = (.zero, .zero)
            u.pointColor = (.zero, .zero)
            u.normalInfo.z = draw.normalPower
            u.normalInfo.w = Float(draw.pointLightType)
            for (k, light) in draw.pointLights.prefix(2).enumerated() {
                let position = Vec4(light.position.x, light.position.y, light.position.z, light.decay)
                let color = Vec4(light.color.x, light.color.y, light.color.z, light.reach)
                if k == 0 { u.pointPosition.0 = position; u.pointColor.0 = color } else { u.pointPosition.1 = position; u.pointColor.1 = color }
            }
            u.spriteColor = draw.spriteColor
            u.spriteCell = draw.spriteCell
            u.uvMatrix = (draw.uvMatrix[0], draw.uvMatrix[1], draw.uvMatrix[2], draw.uvMatrix[3], draw.uvMatrix[4])
            func offset(_ i: Int) -> Vec4 { Vec4(draw.uvOffset[i].x, draw.uvOffset[i].y, 0, 0) }
            u.uvOffset = (offset(0), offset(1), offset(2), offset(3), offset(4))
            u.misc.y = draw.distortPower
            u.misc.z = draw.paletteOffset
            u.cameraPosition = Vec4(camera.x, camera.y, camera.z, 1)
            if u.flags4.y > 0.5 {
                let centre = draw.depthCentre ?? Vec3(draw.model.columns.3.x, draw.model.columns.3.y, draw.model.columns.3.z)
                u.misc.w = min(material.uniforms.misc.w, 1) * simd_distance(centre, camera)
            }
            let sceneReady = !wire && sceneColor != nil && sceneDepth != nil
            u.scene = Vec4(sceneReady && material.soft ? softDistance : 0, sceneReady ? material.screenCopy : 0, viewport.x, viewport.y)
            u.scene2 = Vec4(clip.x, clip.y, softDepthOffset, orthographic ? 1 : 0)
            if material.screenCopy > 0, !sceneReady, !wire { u.color.w = 0 }
            if !wire {
                let ps = particles[draw.particle]
                var tint = Vec3(1, 1, 1)
                if PreviewRules.isOn("sceneLightRates") {
                    tint *= Vec3(1, 1, 1) + (scene.environment - Vec3(1, 1, 1)) * ps.environmentRate
                    tint *= Vec3(1, 1, 1) + (scene.sunlight - Vec3(1, 1, 1)) * ps.directionalRate
                }
                if ps.toneMap, PreviewRules.isOn("sceneToneMap") { tint /= sqrt(max(scene.brightness, 0.01)) }
                u.sceneTint = Vec4(tint.x, tint.y, tint.z, 1)
                let fogShare = max(ps.fog ? 1 : 0, globalFog)
                if scene.fog, fogShare > 0, PreviewRules.isOn("sceneFog") {
                    let mode = ps.drawMode >= 9 && ps.drawMode <= 12 ? ps.drawMode - 8 : ps.drawMode
                    let kind: Float = [2, 3, 4, 7].contains(mode) ? 1 : mode == 1 || mode == 6 ? 2 : 0
                    u.sceneFog = Vec4(scene.fogStart, max(scene.fogEnd, scene.fogStart + 0.01), fogShare, kind)
                    u.fogColor = Vec4(scene.fogColor.x, scene.fogColor.y, scene.fogColor.z, 0)
                }
            }
            if let decal = draw.decal, !wire {
                u.decalInverse = decal.inverse
                u.decalInfo = decal.info
                u.decalPlane = Vec4(decal.ground, 1, sceneReady ? 1 : 0, 0)
                u.scene.x = 0
                u.misc.w = 0
            }
            if wire { u.debugColor = wireColor ?? ParticleRenderer.debugColor(draw.particle); u.misc.w = 0 }
            let pipeline = wire ? pipelines[0] : pipelines[material.blend]
            let projected = draw.decal != nil && !wire
            let depth = wire || draw.overScene || projected ? depthStates[0] : depthStates[(material.depthTest ? 2 : 0) + (material.depthWrite ? 1 : 0)]
            let cull: MTLCullMode = wire ? .none : projected ? (simd_determinant(draw.model) < 0 ? .back : .front) : material.cull
            if boundPipeline != ObjectIdentifier(pipeline) {
                encoder.setRenderPipelineState(pipeline)
                boundPipeline = ObjectIdentifier(pipeline)
            }
            if boundDepth != ObjectIdentifier(depth) {
                encoder.setDepthStencilState(depth)
                boundDepth = ObjectIdentifier(depth)
            }
            if boundCull != cull {
                encoder.setCullMode(cull)
                boundCull = cull
            }
            if boundVertices != ObjectIdentifier(geometry.vertices) {
                encoder.setVertexBuffer(geometry.vertices, offset: 0, index: 0)
                boundVertices = ObjectIdentifier(geometry.vertices)
            }
            encoder.setVertexBytes(&u, length: MemoryLayout<ParticleUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&u, length: MemoryLayout<ParticleUniforms>.stride, index: 1)
            for slot in 0..<7 {
                var texture = material.textures[slot]
                if slot == 0, draw.frame > 0, draw.frame < material.frames.count, let frame = material.frames[draw.frame] { texture = frame }
                bind(texture ?? white, slot == 6 ? 8 : slot)
                let state = material.samplers[slot] ?? fallbackSampler
                let id = state.map { ObjectIdentifier($0) }
                if boundSamplers[slot] != .some(id) {
                    encoder.setFragmentSamplerState(state, index: slot)
                    boundSamplers[slot] = .some(id)
                }
            }
            bind(sceneColor ?? white, 6)
            bind(sceneDepth ?? emptyDepth, 7)
            bind(material.reflectCube ?? whiteCube, 9)
            bind(material.reflectFlat ?? white, 10)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: geometry.indexCount, indexType: .uint32, indexBuffer: geometry.indices,
                                          indexBufferOffset: 0)
        }
        if frameIndex % 120 == 0 {
            buffers = buffers.filter { frameIndex - $0.value.usedFrame < 240 }
        }
    }
}
