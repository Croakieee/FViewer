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
}

struct LoadedTexture {
    var texture: MTLTexture
    var alphaOnly: Bool
}

private struct PreparedMaterial {
    var uniforms = ParticleUniforms()
    var textures: [MTLTexture?] = [nil, nil, nil, nil, nil, nil]
    var samplers: [MTLSamplerState?] = [nil, nil, nil, nil, nil, nil]
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

    init?(_ device: MTLDevice, _ g: RenderGeometry) {
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
    private lazy var emptyDepth: MTLTexture? = {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: 1, height: 1, mipmapped: false)
        descriptor.textureType = .type2DMultisample
        descriptor.sampleCount = 4
        descriptor.usage = [.shaderRead, .renderTarget]
        descriptor.storageMode = .private
        return device.makeTexture(descriptor: descriptor)
    }()
    var sceneColor: MTLTexture?
    var sceneDepth: MTLTexture?
    var viewport = SIMD2<Float>(1, 1)
    var clip = SIMD2<Float>(0.1, 2000)
    var softDistance: Float = 0.5
    private var materials: [Int: PreparedMaterial] = [:]
    private var buffers: [ObjectIdentifier: GeometryBuffers] = [:]
    private var frameIndex = 0
    var textureProvider: (Int) -> LoadedTexture? = { _ in nil }

    init?(device: MTLDevice, pixelFormat: MTLPixelFormat, depthFormat: MTLPixelFormat, sampleCount: Int) {
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
        ]
        for factor in factors {
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
    }

    func reset() {
        materials = [:]
        buffers = [:]
    }

    private static var mipQueue: MTLCommandQueue?

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

    private func sampler(_ u: Int, _ v: Int, filter: Int = 1) -> MTLSamplerState? {
        let level = PreviewRules.isOn("textureFilter") ? min(max(filter, 0), 4) : 1
        let key = u * 3 + v + level * 16
        if let cached = samplers[key] { return cached }
        func mode(_ border: Int) -> MTLSamplerAddressMode { border == 1 ? .clampToEdge : border == 2 ? .mirrorRepeat : .repeat }
        let d = MTLSamplerDescriptor()
        d.minFilter = .linear
        d.magFilter = .linear
        d.mipFilter = .linear
        d.maxAnisotropy = level >= 2 ? [4, 8, 16][level - 2] : 1
        d.sAddressMode = mode(u)
        d.tAddressMode = mode(v)
        let state = device.makeSamplerState(descriptor: d)
        samplers[key] = state
        return state
    }

    private func prepare(_ ps: RParticle) -> PreparedMaterial {
        var m = PreparedMaterial()
        let plainUv = ps.type == 2 || (ps.type == 1 && ps.simple == nil)
        let isModel = ps.type == 5 || ps.type == 13 || ps.type == 14
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
            if i > 0, (calcColor == 1 && texture.alphaOnly) || calcColor == 5 { calcColor = 9 }
            flags[i] = Vec4(1, Float(calcColor), Float(layer.calcAlpha), layer.colorToAlpha ? 1 : 0)
            m.textures[slots[i]] = texture.texture
            m.samplers[slots[i]] = sampler(layer.borderU, layer.borderV, filter: layer.filter)
        }
        m.uniforms.layer = (flags[0], flags[1], flags[2], flags[3])
        if let tc1 = ps.tc1, loaded[0] != nil { m.frames = tc1.textures.map { textureProvider($0)?.texture } }
        var distortion: RTextureLayer?
        if PreviewRules.isOn("distortion"), let td = ps.distortion, td.enabled, let first = td.textures.first, let texture = textureProvider(first) {
            distortion = td
            m.textures[2] = texture.texture
            m.samplers[2] = sampler(td.borderU, td.borderV, filter: td.filter)
        }
        func distorted(_ layer: RTextureLayer?, _ present: Bool) -> Float {
            guard let distortion, let layer, present, layer.uvSet >= 0, layer.uvSet < 4 else { return 0 }
            return distortion.targets[layer.uvSet] ? 1 : 0
        }
        m.uniforms.distortLayers = Vec4(distorted(layers[0], loaded[0] != nil), distorted(layers[1], loaded[1] != nil),
                                        distorted(layers[2], loaded[2] != nil), distorted(layers[3], loaded[3] != nil))
        var palette = false
        if PreviewRules.isOn("paletteAlpha"), let tp = ps.palette, tp.enabled, tp.texture >= 0, let texture = textureProvider(tp.texture) {
            palette = true
            m.textures[5] = texture.texture
            m.samplers[5] = sampler(tp.border, tp.border)
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
        default: m.blend = 0
        }
        let premultiply: Float = mode == 4 || mode == 3 ? 1 : mode == 1 ? 2 : 0
        let fresnel = isModel && ps.fresnelType != 0 && (ps.colorBegin != nil || ps.colorEnd != nil)
        let lineGradient = ps.type == 3 && (ps.colorBegin != nil || ps.colorEnd != nil)
        let sprites = ps.simple != nil && (ps.type == 1 || ps.type == 3)
        let vertexColors = isModel || ps.type == 12 || ps.type == 6
        m.uniforms.flags = Vec4(vertexColors ? 1 : 0, fresnel ? 1 : 0, sprites ? 1 : 0, lineGradient ? 1 : 0)
        m.uniforms.flags2 = Vec4(premultiply, distortion != nil ? 1 : 0, palette ? 1 : 0, PreviewRules.isOn("tc1Luminance") ? 1 : 0)
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
            m.cull = .front
        } else if ps.culling == 1 {
            m.cull = .back
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
        particles.contains { $0.softParticle || ($0.tc1?.enabled == true && $0.tc1?.screenCopy == true) }
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
        for draw in draws {
            guard draw.particle < particles.count else { continue }
            if materials[draw.particle] == nil { materials[draw.particle] = prepare(particles[draw.particle]) }
            guard let material = materials[draw.particle] else { continue }
            let key = ObjectIdentifier(draw.geometry)
            if buffers[key] == nil, let created = GeometryBuffers(device, draw.geometry) { buffers[key] = created }
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
            u.spriteColor = draw.spriteColor
            u.spriteCell = draw.spriteCell
            u.uvMatrix = (draw.uvMatrix[0], draw.uvMatrix[1], draw.uvMatrix[2], draw.uvMatrix[3], draw.uvMatrix[4])
            func offset(_ i: Int) -> Vec4 { Vec4(draw.uvOffset[i].x, draw.uvOffset[i].y, 0, 0) }
            u.uvOffset = (offset(0), offset(1), offset(2), offset(3), offset(4))
            u.misc.y = draw.distortPower
            u.misc.z = draw.paletteOffset
            u.cameraPosition = Vec4(camera.x, camera.y, camera.z, 1)
            let sceneReady = !wire && sceneColor != nil && sceneDepth != nil
            u.scene = Vec4(sceneReady && material.soft ? softDistance : 0, sceneReady ? material.screenCopy : 0, viewport.x, viewport.y)
            u.scene2 = Vec4(clip.x, clip.y, PreviewRules.isOn("softDepthOffset") ? 1 : 0, 0)
            if material.screenCopy > 0, !sceneReady, !wire { u.color.w = 0 }
            if wire {
                u.debugColor = wireColor ?? ParticleRenderer.debugColor(draw.particle)
                u.misc.w = 0
                encoder.setRenderPipelineState(pipelines[0])
                encoder.setDepthStencilState(depthStates[0])
                encoder.setCullMode(.none)
            } else {
                encoder.setRenderPipelineState(pipelines[material.blend])
                encoder.setDepthStencilState(depthStates[(material.depthTest ? 2 : 0) + (material.depthWrite ? 1 : 0)])
                encoder.setCullMode(material.cull)
            }
            encoder.setVertexBuffer(geometry.vertices, offset: 0, index: 0)
            encoder.setVertexBytes(&u, length: MemoryLayout<ParticleUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&u, length: MemoryLayout<ParticleUniforms>.stride, index: 1)
            for slot in 0..<6 {
                var texture = material.textures[slot]
                if slot == 0, draw.frame > 0, draw.frame < material.frames.count, let frame = material.frames[draw.frame] { texture = frame }
                encoder.setFragmentTexture(texture ?? white, index: slot)
                encoder.setFragmentSamplerState(material.samplers[slot] ?? sampler(0, 0), index: slot)
            }
            encoder.setFragmentTexture(sceneColor ?? white, index: 6)
            encoder.setFragmentTexture(sceneDepth ?? emptyDepth, index: 7)
            encoder.drawIndexedPrimitives(type: .triangle, indexCount: geometry.indexCount, indexType: .uint32, indexBuffer: geometry.indices,
                                          indexBufferOffset: 0)
        }
        if frameIndex % 120 == 0 {
            buffers = buffers.filter { frameIndex - $0.value.usedFrame < 240 }
        }
    }
}
