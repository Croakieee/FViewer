import Combine
import MetalKit
import SwiftUI
import simd

final class ViewportCamera: ObservableObject {
    @Published var yaw: Float = 0.7
    @Published var pitch: Float = 0.45
    @Published var distance: Float = 8
    @Published var target = SIMD3<Float>(0, 1, 0)
    @Published var ortho = false
    @Published var fov: Float = 0.75

    var eye: SIMD3<Float> {
        target + (ortho ? max(distance, 400) : distance) * SIMD3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
    }

    func orbit(dx: Float, dy: Float) {
        yaw -= dx * 0.008
        pitch = min(max(pitch + dy * 0.008, -1.55), 1.55)
    }

    func pan(dx: Float, dy: Float) {
        let forward = simd_normalize(target - eye)
        let right = simd_normalize(simd_cross(forward, SIMD3(0, 1, 0)))
        let up = simd_cross(right, forward)
        target += (-dx * right + dy * up) * distance * 0.0015
    }

    func zoom(_ factor: Float) {
        distance = min(max(distance * factor, 0.05), 500)
    }

    func frame(_ bounds: (min: SIMD3<Float>, max: SIMD3<Float>)?) {
        guard let bounds else {
            target = SIMD3(0, 1, 0)
            distance = 8
            return
        }
        target = (bounds.min + bounds.max) / 2
        distance = max(simd_length(bounds.max - bounds.min) * 1.3, 0.5)
    }

    func setView(yaw: Float, pitch: Float) {
        self.yaw = yaw
        self.pitch = pitch
    }
}

struct ViewportScene {
    var meshes: [(mesh: MeshData, highlighted: Bool)] = []
    var showEffect = true
    var effectShading = 0
    var showEmitters = false
    var showBindPoints = false
    var showFloor = false
    var showGizmo = true
    var filter = VisibilityFilter()
    var highlight: VisibilityKey?
    var texture: CGImage?
    var shading = 1
    var revision = 0
}

private struct Uniforms {
    var viewProjection: simd_float4x4
    var model: simd_float4x4
    var tint: SIMD4<Float>
    var options: SIMD4<Float>
    var lightPosition: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero, .zero)
    var lightColor: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero, .zero)
    var dissolve = SIMD4<Float>(0, 0, 0, 0)
    var dissolveColor = SIMD4<Float>(0, 0, 0, 0)
    var dissolveUv = SIMD4<Float>(1, 0, 0, 1)
    var dissolveOffset = SIMD4<Float>(0, 0, 0, 0)
    var dissolveShape = matrix_identity_float4x4
    var dissolveInfo = SIMD4<Float>(0, 0, 0, 0)
    var dissolveBands: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero)
    var shadow = SIMD4<Float>(-1, 0, 0, 0)
    var look = SIMD4<Float>(0, 1, 4 / Float.pi, 0)
    var shadowFaces: (simd_float4x4, simd_float4x4, simd_float4x4, simd_float4x4, simd_float4x4, simd_float4x4) =
        (matrix_identity_float4x4, matrix_identity_float4x4, matrix_identity_float4x4, matrix_identity_float4x4, matrix_identity_float4x4, matrix_identity_float4x4)
}

private struct DrawItem {
    var vertices: MTLBuffer
    var indices: MTLBuffer?
    var count: Int
    var primitive: MTLPrimitiveType
    var tint: SIMD4<Float>
    var lit: Bool
    var textured: Bool
    var wire: Bool
    var pointSize: Float = 1
    var map: MTLTexture?
}

final class ViewportRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let camera: ViewportCamera
    private let queue: MTLCommandQueue
    private var pipeline: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState?
    private var overlayDepthState: MTLDepthStencilState?
    private var sampler: MTLSamplerState?
    private var white: MTLTexture?
    private var texture: MTLTexture?
    private var grid: [DrawItem] = []
    private var items: [DrawItem] = []
    private var sceneRevision = -1
    private var showEffect = true
    private var effectShading = 0
    private var showEmitters = false
    private var showBindPoints = false
    var filter = VisibilityFilter()
    private var highlight: VisibilityKey?
    private var highlightDraws: [ParticleDraw] = []
    private var particleRenderer: ParticleRenderer?
    var player: AvfxPlayer?
    let gizmo = GizmoState()
    static weak var main: ViewportRenderer?
    var captureRequest: ((CGImage) -> Void)?
    private var rulesToken = -1
    var lastDraws: [ParticleDraw] = []

    func effectBounds() -> (min: SIMD3<Float>, max: SIMD3<Float>)? {
        var xs: [Float] = [], ys: [Float] = [], zs: [Float] = []
        for draw in lastDraws {
            let count = draw.geometry.vertexCount
            guard count > 0 else { continue }
            let step = max(1, count / 96)
            for index in stride(from: 0, to: count, by: step) {
                let o = index * RenderGeometry.stride
                let local = SIMD4<Float>(draw.geometry.vertices[o], draw.geometry.vertices[o + 1], draw.geometry.vertices[o + 2], 1)
                let world = draw.model * local
                guard world.x.isFinite, world.y.isFinite, world.z.isFinite else { continue }
                xs.append(world.x)
                ys.append(world.y)
                zs.append(world.z)
            }
        }
        guard xs.count > 0 else { return nil }
        func span(_ values: [Float]) -> (Float, Float) {
            let sorted = values.sorted()
            let trim = sorted.count >= 40 ? sorted.count / 25 : 0
            return (sorted[trim], sorted[sorted.count - 1 - trim])
        }
        let x = span(xs), y = span(ys), z = span(zs)
        return (SIMD3(x.0, y.0, z.0), SIMD3(x.1, y.1, z.1))
    }
    var lastViewProjection = matrix_identity_float4x4
    var lastViewSize = CGSize(width: 1, height: 1)
    var showGizmo = true
    private var alwaysDepthState: MTLDepthStencilState?
    private var effectTextures: [String: LoadedTexture] = [:]
    private var texturePaths: [String] = []
    private var libraryToken = -1
    private var textureRevision = -1
    private var lastFrame = CACurrentMediaTime()
    private var lastActivity = CACurrentMediaTime()
    private var idleSignature: [Double] = []
    private var showFloor = false
    private var floor: DrawItem?
    private var sceneColor: MTLTexture?
    private var postPipeline: MTLRenderPipelineState?
    private var bloomPipeline: MTLRenderPipelineState?
    private var topPipeline: MTLRenderPipelineState?
    private let inFlight = DispatchSemaphore(value: 1)
    private var backdrop: (token: Int, aspect: Float, item: DrawItem)?
    static var bloom: (on: Bool, threshold: Float, intensity: Float, radius: Float) = (false, 0.7, 0.8, 0.03)
    static var scene = PreviewScene()
    static var sceneToken = 0
    static var backgroundColor: SIMD3<Double>?
    static var backgroundImage: CGImage?
    static var backgroundToken = 0
    static var referenceMesh: MeshData?
    static var referenceToken = 0
    private var referenceToken = -1
    private var reference: [DrawItem] = []
    private var shadowPipeline: MTLRenderPipelineState?
    private var shadowMap: MTLTexture?
    private var shadowDepth: MTLTexture?
    private var noShadow: MTLTexture?
    private var shadowState: (index: Int, near: Float, far: Float, faces: [simd_float4x4])?
    static var referenceParts: [(start: Int, count: Int, texture: DecodedTexture?)] = []
    private var postSource: MTLTexture?
    private var postSampler: MTLSamplerState?
    private var quake = (shift: Vec3.zero, turn: Vec3.zero, order: 0)
    private var sceneDepth: MTLTexture?
    weak var document: EffectDocument?
    weak var app: AppModel?

    init?(camera: ViewportCamera) {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.queue = queue
        self.camera = camera
        super.init()
        build()
        if ViewportRenderer.main == nil { ViewportRenderer.main = self }
    }

    private func build() {
        guard let library = try? device.makeLibrary(source: ViewportShaders.source, options: nil) else { return }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "viewportVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "viewportFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        descriptor.depthAttachmentPixelFormat = .depth32Float
        descriptor.rasterSampleCount = 4
        let layout = MTLVertexDescriptor()
        layout.attributes[0].format = .float3
        layout.attributes[0].offset = MemoryLayout<MeshVertex>.offset(of: \.position) ?? 0
        layout.attributes[1].format = .float3
        layout.attributes[1].offset = MemoryLayout<MeshVertex>.offset(of: \.normal) ?? 16
        layout.attributes[2].format = .float4
        layout.attributes[2].offset = MemoryLayout<MeshVertex>.offset(of: \.color) ?? 32
        layout.attributes[3].format = .float2
        layout.attributes[3].offset = MemoryLayout<MeshVertex>.offset(of: \.uv) ?? 48
        layout.layouts[0].stride = MemoryLayout<MeshVertex>.stride
        descriptor.vertexDescriptor = layout
        pipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        let shadow = MTLRenderPipelineDescriptor()
        shadow.vertexFunction = library.makeFunction(name: "shadowVertex")
        shadow.fragmentFunction = library.makeFunction(name: "shadowFragment")
        shadow.colorAttachments[0].pixelFormat = .r32Float
        shadow.depthAttachmentPixelFormat = .depth32Float
        shadow.vertexDescriptor = layout
        shadowPipeline = try? device.makeRenderPipelineState(descriptor: shadow)
        let blank = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: 1, height: 1, mipmapped: false)
        blank.textureType = .type2DArray
        blank.arrayLength = 6
        noShadow = device.makeTexture(descriptor: blank)
        for slice in 0..<6 {
            var far: Float = 1e9
            noShadow?.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, slice: slice, withBytes: &far, bytesPerRow: 4, bytesPerImage: 4)
        }
        descriptor.depthAttachmentPixelFormat = .invalid
        descriptor.rasterSampleCount = 1
        topPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        let post = MTLRenderPipelineDescriptor()
        post.vertexFunction = library.makeFunction(name: "postVertex")
        post.fragmentFunction = library.makeFunction(name: "postFragment")
        post.colorAttachments[0].pixelFormat = .bgra8Unorm
        postPipeline = try? device.makeRenderPipelineState(descriptor: post)
        post.fragmentFunction = library.makeFunction(name: "bloomFragment")
        bloomPipeline = try? device.makeRenderPipelineState(descriptor: post)

        let depth = MTLDepthStencilDescriptor()
        depth.depthCompareFunction = .lessEqual
        depth.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depth)
        let overlay = MTLDepthStencilDescriptor()
        overlay.depthCompareFunction = .lessEqual
        overlay.isDepthWriteEnabled = false
        overlayDepthState = device.makeDepthStencilState(descriptor: overlay)
        let always = MTLDepthStencilDescriptor()
        always.depthCompareFunction = .always
        always.isDepthWriteEnabled = false
        alwaysDepthState = device.makeDepthStencilState(descriptor: always)

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        postSampler = device.makeSamplerState(descriptor: samplerDescriptor)

        let whiteDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        white = device.makeTexture(descriptor: whiteDescriptor)
        white?.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: [UInt8](repeating: 255, count: 4), bytesPerRow: 4)
        buildGrid()
        particleRenderer = ParticleRenderer(device: device, pixelFormat: .bgra8Unorm, depthFormat: .depth32Float, sampleCount: 4)
        particleRenderer?.textureProvider = { [weak self] index in self?.effectTexture(index) }
    }

    private func effectTexture(_ index: Int) -> LoadedTexture? {
        guard index >= 0, index < texturePaths.count else { return nil }
        let path = texturePaths[index]
        let black = PreviewRules.isOn("a8BlackRgb")
        let key = black ? path + "#a8" : path
        if let cached = effectTextures[key] { return cached }
        guard var decoded = app?.decodedTexture(for: path) else { return nil }
        if black, decoded.alphaOnly {
            for i in stride(from: 0, to: decoded.rgba.count - 3, by: 4) {
                decoded.rgba[i] = 0
                decoded.rgba[i + 1] = 0
                decoded.rgba[i + 2] = 0
            }
        }
        guard let texture = ParticleRenderer.makeTexture(device, decoded) else { return nil }
        let loaded = LoadedTexture(texture: texture, alphaOnly: decoded.alphaOnly, cube: ParticleRenderer.makeCube(device, decoded))
        effectTextures[key] = loaded
        return loaded
    }

    private func overlayItems() -> [DrawItem] {
        guard let simulation = player?.simulation, showEmitters || showBindPoints || AvfxSimulation.stage.showTarget else { return [] }
        var lines: [(SIMD3<Float>, SIMD4<Float>)] = []
        var points: [MeshVertex] = []
        if showEmitters, PreviewRules.isOn("emitterMarkers") {
            for marker in simulation.emitterMarkers() {
                let origin = Math3D.point(marker.world, .zero)
                let colors: [SIMD4<Float>] = [SIMD4(0.95, 0.3, 0.3, 1), SIMD4(0.45, 0.85, 0.3, 1), SIMD4(0.3, 0.55, 1, 1)]
                for (axis, color) in zip([SIMD3<Float>(1, 0, 0), SIMD3(0, 1, 0), SIMD3(0, 0, 1)], colors) {
                    let tip = origin + Math3D.direction(marker.world, axis) * 0.3
                    lines.append((origin, color))
                    lines.append((tip, color))
                }
                let tint = ParticleRenderer.debugColor(marker.index + 7)
                points.append(MeshVertex(position: origin, normal: .zero, color: SIMD4(1, 1, 1, 1), uv: .zero))
                for point in marker.points.prefix(400) {
                    points.append(MeshVertex(position: Math3D.point(marker.world, point), normal: .zero, color: tint, uv: .zero))
                }
            }
        }
        let places = simulation.stagePlaces
        let caster = places.caster
        if showBindPoints || AvfxSimulation.stage.showTarget {
            let body = SIMD4<Float>(1, 1, 1, 0.35)
            var figures: [Mat4] = []
            if showBindPoints && AvfxSimulation.skeletonLines.isEmpty { figures.append(caster) }
            if AvfxSimulation.stage.showTarget { figures.append(AvfxSimulation.stage.places(at: simulation.time / 30).target) }
            let figure: [(SIMD3<Float>, SIMD3<Float>)] = [
                (SIMD3(0, 0, 0), SIMD3(0, 1.45, 0)), (SIMD3(-0.2, 1.42, 0), SIMD3(0.2, 1.42, 0)), (SIMD3(-0.2, 1.42, 0), SIMD3(-0.33, 0.78, 0)),
                (SIMD3(0.2, 1.42, 0), SIMD3(0.33, 0.78, 0)), (SIMD3(-0.1, 0.95, 0), SIMD3(-0.1, 0, 0)), (SIMD3(0.1, 0.95, 0), SIMD3(0.1, 0, 0)),
                (SIMD3(-0.1, 0.95, 0), SIMD3(0.1, 0.95, 0)), (SIMD3(0, 1.6, 0.13), SIMD3(0, 1.6, 0.3)),
            ]
            for place in figures {
                for segment in figure {
                    lines.append((Math3D.point(place, segment.0), body))
                    lines.append((Math3D.point(place, segment.1), body))
                }
                for i in 0..<16 {
                    let a = Float(i) / 16 * 2 * .pi, b = Float(i + 1) / 16 * 2 * .pi
                    lines.append((Math3D.point(place, SIMD3(cos(a) * 0.12, 1.6 + sin(a) * 0.13, 0)), body))
                    lines.append((Math3D.point(place, SIMD3(cos(b) * 0.12, 1.6 + sin(b) * 0.13, 0)), body))
                }
            }
        }
        if showBindPoints {
            let color = SIMD4<Float>(1, 0.63, 0.16, 1)
            for point in simulation.usedBindPoints {
                for axis in [SIMD3<Float>(0.08, 0, 0), SIMD3(0, 0.08, 0), SIMD3(0, 0, 0.08)] {
                    lines.append((point - axis, color))
                    lines.append((point + axis, color))
                }
            }
            let used = Set(simulation.schema.binders.compactMap { $0.bindTargetPoint == 3 ? $0.bindPointId : nil })
            let forward = simd_normalize(camera.eye - camera.target)
            let right = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), forward))
            let up = simd_cross(forward, right)
            let glyph = max(0.012, camera.distance * 0.004)
            for (id, local) in AvfxSimulation.bindPoints {
                let point = Math3D.point(caster, local)
                let tint: SIMD4<Float> = used.contains(id) ? SIMD4(1, 0.63, 0.16, 1) : SIMD4(1, 1, 1, 0.3)
                if !used.contains(id) {
                    lines.append((point - right * glyph * 0.6, tint))
                    lines.append((point + right * glyph * 0.6, tint))
                }
                var cursor = point + right * glyph * 1.6 + up * glyph
                for digit in PreviewRules.isOn("bindPointNumbers") ? String(id) : "" {
                    for segment in ViewportRenderer.digitSegments[Int(String(digit)) ?? 0] {
                        lines.append((cursor + right * segment.0.x * glyph + up * segment.0.y * glyph, tint))
                        lines.append((cursor + right * segment.1.x * glyph + up * segment.1.y * glyph, tint))
                    }
                    cursor += right * glyph * 1.5
                }
            }
            for segment in AvfxSimulation.physicsLines {
                lines.append((Math3D.point(caster, segment.0), SIMD4(0.3, 0.85, 1, 0.8)))
                lines.append((Math3D.point(caster, segment.1), SIMD4(0.3, 0.85, 1, 0.8)))
            }
            for segment in AvfxSimulation.skeletonLines {
                lines.append((Math3D.point(caster, segment.0), SIMD4(1, 1, 1, 0.35)))
                lines.append((Math3D.point(caster, segment.1), SIMD4(1, 1, 1, 0.35)))
            }
        }
        var items: [DrawItem] = []
        if let item = lineItem(lines) { items.append(item) }
        if !points.isEmpty, let buffer = frameBuffer(points) {
            items.append(DrawItem(vertices: buffer, indices: nil, count: points.count, primitive: .point, tint: SIMD4(1, 1, 1, 1), lit: false,
                                  textured: false, wire: false, pointSize: 6))
        }
        return items
    }

    private func effectDraws(elapsed: Double, camera state: CameraState) -> (draws: [ParticleDraw], particles: [RParticle])? {
        guard showEffect, let document, document.format == .avfx else { return nil }
        if player?.document !== document { player = AvfxPlayer(document: document) }
        guard let player else { return nil }
        let token = app?.libraryToken ?? 0
        if let revision = app?.textureRevision, revision != textureRevision {
            textureRevision = revision
            particleRenderer?.reset()
        }
        if player.schemaChanged || token != libraryToken || rulesToken != PreviewRules.token {
            rulesToken = PreviewRules.token
            if token != libraryToken { effectTextures = [:] }
            libraryToken = token
            texturePaths = document.textureSlots.map(\.path)
            particleRenderer?.reset()
        }
        let draws = player.frame(elapsed: elapsed, camera: state, filter: filter)
        lastDraws = draws
        highlightDraws = []
        if let highlight, filter.isolated == nil, effectShading == 0, let simulation = player.simulation {
            highlightDraws = simulation.render(camera: state, filter: VisibilityFilter(hidden: filter.hidden, isolated: highlight), record: false)
        }
        return (draws, player.simulation?.schema.particles ?? [])
    }

    private var lineCache: [Int: DrawItem] = [:]
    private var linesBefore: Set<Int> = []
    private var linesNow: Set<Int> = []
    private var framePool: [MTLBuffer] = []
    private var frameSlot = 0

    private func renderShadow(_ buffer: MTLCommandBuffer, lights: [LightDraw]) {
        shadowState = nil
        guard !reference.isEmpty, let shadowPipeline, let index = lights.firstIndex(where: { $0.shadow != nil }), let range = lights[index].shadow else { return }
        let size = 1024
        if shadowMap == nil {
            let color = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: size, height: size, mipmapped: false)
            color.textureType = .type2DArray
            color.arrayLength = 6
            color.usage = [.renderTarget, .shaderRead]
            color.storageMode = .private
            shadowMap = device.makeTexture(descriptor: color)
            let depth = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: size, height: size, mipmapped: false)
            depth.usage = [.renderTarget]
            depth.storageMode = .private
            shadowDepth = device.makeTexture(descriptor: depth)
        }
        guard let shadowMap, let shadowDepth, let depthState else { return }
        let eye = lights[index].position
        var model = player?.simulation?.stagePlaces.caster ?? matrix_identity_float4x4
        let projection = ViewportRenderer.perspective(fovY: .pi / 2, aspect: 1, near: 0.02, far: range.far + 1)
        let axes: [(SIMD3<Float>, SIMD3<Float>)] = [(SIMD3(1, 0, 0), SIMD3(0, 1, 0)), (SIMD3(-1, 0, 0), SIMD3(0, 1, 0)), (SIMD3(0, 1, 0), SIMD3(0, 0, 1)),
                                                    (SIMD3(0, -1, 0), SIMD3(0, 0, 1)), (SIMD3(0, 0, 1), SIMD3(0, 1, 0)), (SIMD3(0, 0, -1), SIMD3(0, 1, 0))]
        var faces: [simd_float4x4] = []
        for (slice, axis) in axes.enumerated() {
            var face = projection * ViewportRenderer.lookAt(eye: eye, target: eye + axis.0, up: axis.1)
            faces.append(face)
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = shadowMap
            pass.colorAttachments[0].slice = slice
            pass.colorAttachments[0].loadAction = .clear
            pass.colorAttachments[0].clearColor = MTLClearColor(red: 1e9, green: 0, blue: 0, alpha: 0)
            pass.colorAttachments[0].storeAction = .store
            pass.depthAttachment.texture = shadowDepth
            pass.depthAttachment.loadAction = .clear
            pass.depthAttachment.clearDepth = 1
            pass.depthAttachment.storeAction = .dontCare
            guard let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
            encoder.setRenderPipelineState(shadowPipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setCullMode(.none)
            var light = SIMD4<Float>(eye.x, eye.y, eye.z, 0)
            encoder.setFragmentBytes(&light, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
            encoder.setVertexBytes(&face, length: MemoryLayout<simd_float4x4>.stride, index: 1)
            encoder.setVertexBytes(&model, length: MemoryLayout<simd_float4x4>.stride, index: 2)
            for item in reference {
                guard let indices = item.indices else { continue }
                encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
                encoder.drawIndexedPrimitives(type: .triangle, indexCount: item.count, indexType: .uint32, indexBuffer: indices, indexBufferOffset: 0)
            }
            encoder.endEncoding()
        }
        shadowState = (index, range.near, range.far, faces)
    }

    private func beginFrameBuffers() {
        frameSlot = 0
        linesBefore = linesNow
        linesNow = []
    }

    fileprivate func frameBuffer<T>(_ values: [T]) -> MTLBuffer? {
        let length = max(MemoryLayout<T>.stride * values.count, 16)
        defer { frameSlot += 1 }
        if frameSlot < framePool.count, framePool[frameSlot].length >= length {
            values.withUnsafeBytes { raw in if let base = raw.baseAddress { framePool[frameSlot].contents().copyMemory(from: base, byteCount: raw.count) } }
            return framePool[frameSlot]
        }
        var size = 4096
        while size < length { size *= 2 }
        guard let buffer = device.makeBuffer(length: size, options: .storageModeShared) else { return nil }
        values.withUnsafeBytes { raw in if let base = raw.baseAddress { buffer.contents().copyMemory(from: base, byteCount: raw.count) } }
        if frameSlot < framePool.count { framePool[frameSlot] = buffer } else { framePool.append(buffer) }
        return buffer
    }

    fileprivate func lineItem(_ points: [(SIMD3<Float>, SIMD4<Float>)], persistent: Bool = false) -> DrawItem? {
        guard !points.isEmpty else { return nil }
        var hasher = Hasher()
        for point in points {
            hasher.combine(point.0)
            hasher.combine(point.1)
        }
        let key = hasher.finalize()
        if let known = lineCache[key], known.count == points.count { return known }
        linesNow.insert(key)
        let vertices = points.map { MeshVertex(position: $0.0, normal: SIMD3(0, 1, 0), color: $0.1, uv: .zero) }
        guard persistent || linesBefore.contains(key) else {
            guard let buffer = frameBuffer(vertices) else { return nil }
            return DrawItem(vertices: buffer, indices: nil, count: vertices.count, primitive: .line, tint: SIMD4(1, 1, 1, 1), lit: false, textured: false, wire: false)
        }
        guard let buffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<MeshVertex>.stride * vertices.count) else { return nil }
        let item = DrawItem(vertices: buffer, indices: nil, count: vertices.count, primitive: .line, tint: SIMD4(1, 1, 1, 1), lit: false,
                            textured: false, wire: false)
        if lineCache.count >= 24 { lineCache.removeAll() }
        lineCache[key] = item
        return item
    }

    private func buildGrid() {
        var points: [(SIMD3<Float>, SIMD4<Float>)] = []
        let extent = 20
        for i in -extent...extent where i != 0 {
            let major = i % 5 == 0
            let color = SIMD4<Float>(1, 1, 1, major ? 0.16 : 0.07)
            let f = Float(i), e = Float(extent)
            points.append((SIMD3(f, 0, -e), color))
            points.append((SIMD3(f, 0, e), color))
            points.append((SIMD3(-e, 0, f), color))
            points.append((SIMD3(e, 0, f), color))
        }
        let e = Float(extent)
        points.append((SIMD3(-e, 0, 0), SIMD4(0.93, 0.25, 0.30, 0.9)))
        points.append((SIMD3(e, 0, 0), SIMD4(0.93, 0.25, 0.30, 0.9)))
        points.append((SIMD3(0, 0, -e), SIMD4(0.25, 0.50, 0.95, 0.9)))
        points.append((SIMD3(0, 0, e), SIMD4(0.25, 0.50, 0.95, 0.9)))
        grid = lineItem(points, persistent: true).map { [$0] } ?? []
        var disc: [MeshVertex] = [MeshVertex(position: SIMD3(0, -0.002, 0), normal: SIMD3(0, 1, 0), color: SIMD4(0.43, 0.38, 0.34, 1), uv: SIMD2(0.5, 0.5))]
        var indices: [UInt32] = []
        let segments = 64
        for i in 0...segments {
            let a = Float(i) / Float(segments) * 2 * .pi
            disc.append(MeshVertex(position: SIMD3(cos(a) * 8, -0.002, sin(a) * 8), normal: SIMD3(0, 1, 0), color: SIMD4(0.43, 0.38, 0.34, 1),
                                   uv: SIMD2(0.5 + cos(a) / 2, 0.5 + sin(a) / 2)))
            if i > 0 { indices.append(contentsOf: [0, UInt32(i + 1), UInt32(i)]) }
        }
        if let vb = device.makeBuffer(bytes: disc, length: MemoryLayout<MeshVertex>.stride * disc.count),
           let ib = device.makeBuffer(bytes: indices, length: 4 * indices.count) {
            floor = DrawItem(vertices: vb, indices: ib, count: indices.count, primitive: .triangle, tint: SIMD4(1, 1, 1, 1), lit: true, textured: false,
                             wire: false)
        }
    }

    private struct PostUniforms {
        var center: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero, .zero)
        var shape: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero, .zero)
        var count = SIMD4<Float>(0, 1, 0, 0)
        var extra: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>) = (.zero, .zero, .zero, .zero)
    }

    private func drawHelpers(_ encoder: MTLRenderCommandEncoder, viewProjection: Mat4, depth: Bool) {
        guard captureRequest == nil else { return }
        for (items, onTop) in [(overlayItems(), false), (gizmoItems(), true)] {
            for item in items {
                var uniforms = Uniforms(viewProjection: viewProjection, model: matrix_identity_float4x4, tint: item.tint,
                                        options: SIMD4(0, 0, item.pointSize, 0))
                if depth { encoder.setDepthStencilState(onTop ? alwaysDepthState ?? overlayDepthState : overlayDepthState) }
                encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentTexture(white, index: 0)
                encoder.drawPrimitives(type: item.primitive, vertexStart: 0, vertexCount: item.count)
            }
        }
    }

    private func applyBloom(buffer: MTLCommandBuffer, target: MTLTexture) {
        guard let bloomPipeline, !target.isFramebufferOnly else { return }
        if postSource?.width != target.width || postSource?.height != target.height {
            let copy = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: target.pixelFormat, width: target.width, height: target.height, mipmapped: false)
            copy.usage = [.shaderRead]
            copy.storageMode = .private
            postSource = device.makeTexture(descriptor: copy)
        }
        guard let postSource, let blit = buffer.makeBlitCommandEncoder() else { return }
        blit.copy(from: target, to: postSource)
        blit.endEncoding()
        let settings = ViewportRenderer.bloom
        var uniforms = SIMD4<Float>(settings.threshold, settings.intensity, settings.radius, Float(target.width) / Float(max(target.height, 1)))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(bloomPipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.stride, index: 0)
        encoder.setFragmentTexture(postSource, index: 0)
        encoder.setFragmentSamplerState(postSampler ?? sampler, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }

    private func backdropItem(aspect: Float) -> DrawItem? {
        guard let image = ViewportRenderer.backgroundImage else {
            backdrop = nil
            return nil
        }
        if let backdrop, backdrop.token == ViewportRenderer.backgroundToken, abs(backdrop.aspect - aspect) < 1e-4 { return backdrop.item }
        let loader = MTKTextureLoader(device: device)
        guard let map = backdrop?.token == ViewportRenderer.backgroundToken ? backdrop?.item.map
                : try? loader.newTexture(cgImage: image, options: [.SRGB: false, .generateMipmaps: true]) else { return nil }
        let ratio = Float(image.width) / Float(max(image.height, 1)) / max(aspect, 1e-4)
        let w: Float = ratio >= 1 ? ratio : 1, h: Float = ratio >= 1 ? 1 : 1 / ratio
        let corners = [(-w, -h, Float(0), Float(1)), (w, -h, 1, 1), (w, h, 1, 0), (-w, -h, 0, 1), (w, h, 1, 0), (-w, h, 0, 0)]
        let quad = corners.map { MeshVertex(position: SIMD3($0.0, $0.1, 0.9999), normal: SIMD3(0, 0, 1), color: SIMD4(1, 1, 1, 1), uv: SIMD2($0.2, $0.3)) }
        guard let buffer = device.makeBuffer(bytes: quad, length: MemoryLayout<MeshVertex>.stride * quad.count) else { return nil }
        let item = DrawItem(vertices: buffer, indices: nil, count: quad.count, primitive: .triangle, tint: SIMD4(1, 1, 1, 1), lit: false, textured: false,
                            wire: false, map: map)
        backdrop = (ViewportRenderer.backgroundToken, aspect, item)
        return item
    }

    private func applyPost(_ effects: [ScreenEffect], buffer: MTLCommandBuffer, target: MTLTexture, viewProjection: simd_float4x4) {
        guard let postPipeline, !target.isFramebufferOnly else { return }
        if postSource?.width != target.width || postSource?.height != target.height {
            let copy = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: target.pixelFormat, width: target.width, height: target.height, mipmapped: false)
            copy.usage = [.shaderRead]
            copy.storageMode = .private
            postSource = device.makeTexture(descriptor: copy)
        }
        guard let postSource, let blit = buffer.makeBlitCommandEncoder() else { return }
        blit.copy(from: target, to: postSource)
        blit.endEncoding()
        var uniforms = PostUniforms()
        let radialMask = PreviewRules.isOn("radialBlurRadiusMask")
        uniforms.count = SIMD4(Float(effects.count), Float(target.width) / Float(max(target.height, 1)), radialMask ? 1 : 0, 0)
        withUnsafeMutableBytes(of: &uniforms) { raw in
            let values = raw.bindMemory(to: SIMD4<Float>.self)
            for (index, effect) in effects.enumerated() {
                let clip = viewProjection * SIMD4(effect.position.x, effect.position.y, effect.position.z, 1)
                let w = abs(clip.w) < 1e-5 ? 1e-5 : clip.w
                let center = SIMD2(clip.x / w * 0.5 + 0.5, 0.5 - clip.y / w * 0.5)
                values[index] = SIMD4(center.x, center.y, Float(effect.kind), clip.w > 0 ? effect.strength : 0)
                values[9 + index] = effect.extra
                if (effect.kind == 3 || effect.kind == 4) && effect.extra.w > 0.5 {
                    values[4 + index] = SIMD4(min(max(effect.length, 0), 1) * 0.12, effect.inner, effect.outer, effect.gradation)
                } else if effect.kind == 7, radialMask {
                    let gradation = PreviewRules.isOn("radialBlurGradation") && effect.inner <= 0 ? effect.gradation : 1
                    values[4 + index] = SIMD4(min(max(effect.length, 0), 1), effect.inner, effect.outer, gradation)
                } else {
                    values[4 + index] = SIMD4(min(max(effect.length, 0), 1) * (effect.kind == 7 ? 0.5 : 0.12), effect.inner, effect.outer, effect.angle)
                }
            }
        }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .dontCare
        pass.colorAttachments[0].storeAction = .store
        guard let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        encoder.setRenderPipelineState(postPipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<PostUniforms>.stride, index: 0)
        encoder.setFragmentTexture(postSource, index: 0)
        encoder.setFragmentSamplerState(postSampler ?? sampler, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
    }

    private func sceneTextures(_ drawable: MTLTexture, depth: MTLTexture) -> Bool {
        if sceneColor?.width != drawable.width || sceneColor?.height != drawable.height {
            let color = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: drawable.pixelFormat, width: drawable.width, height: drawable.height,
                                                                 mipmapped: false)
            color.usage = [.shaderRead]
            color.storageMode = .private
            sceneColor = device.makeTexture(descriptor: color)
        }
        if sceneDepth?.width != depth.width || sceneDepth?.height != depth.height || sceneDepth?.sampleCount != depth.sampleCount {
            let copy = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: depth.pixelFormat, width: depth.width, height: depth.height, mipmapped: false)
            copy.textureType = depth.textureType
            copy.sampleCount = depth.sampleCount
            copy.usage = [.shaderRead, .renderTarget]
            copy.storageMode = .private
            sceneDepth = device.makeTexture(descriptor: copy)
        }
        return sceneColor != nil && sceneDepth != nil
    }

    func update(_ scene: ViewportScene) {
        showEffect = scene.showEffect
        effectShading = scene.effectShading
        showEmitters = scene.showEmitters
        showBindPoints = scene.showBindPoints
        showFloor = scene.showFloor
        showGizmo = scene.showGizmo
        filter = scene.filter
        highlight = scene.highlight
        guard scene.revision != sceneRevision else { return }
        sceneRevision = scene.revision
        items = []
        texture = nil
        if let image = scene.texture {
            let loader = MTKTextureLoader(device: device)
            texture = try? loader.newTexture(cgImage: image, options: [.SRGB: false, .generateMipmaps: true])
            let aspect = Float(image.width) / Float(max(image.height, 1))
            let w = aspect >= 1 ? 1 : aspect, h = aspect >= 1 ? 1 / aspect : 1
            let quad = [
                MeshVertex(position: SIMD3(-w, 0.2, 0), normal: SIMD3(0, 0, 1), color: SIMD4(1, 1, 1, 1), uv: SIMD2(0, 1)),
                MeshVertex(position: SIMD3(w, 0.2, 0), normal: SIMD3(0, 0, 1), color: SIMD4(1, 1, 1, 1), uv: SIMD2(1, 1)),
                MeshVertex(position: SIMD3(w, 0.2 + 2 * h, 0), normal: SIMD3(0, 0, 1), color: SIMD4(1, 1, 1, 1), uv: SIMD2(1, 0)),
                MeshVertex(position: SIMD3(-w, 0.2 + 2 * h, 0), normal: SIMD3(0, 0, 1), color: SIMD4(1, 1, 1, 1), uv: SIMD2(0, 0)),
            ]
            let indices: [UInt32] = [0, 1, 2, 0, 2, 3]
            if let vb = device.makeBuffer(bytes: quad, length: MemoryLayout<MeshVertex>.stride * 4),
               let ib = device.makeBuffer(bytes: indices, length: 24) {
                items.append(DrawItem(vertices: vb, indices: ib, count: 6, primitive: .triangle, tint: SIMD4(1, 1, 1, 1), lit: false,
                                      textured: true, wire: false))
            }
        }
        for entry in scene.meshes {
            let mesh = entry.mesh
            let accent: SIMD4<Float> = entry.highlighted ? SIMD4(1.0, 0.63, 0.16, 1) : SIMD4(0.75, 0.75, 0.75, 1)
            var shown = mesh.vertices
            if scene.shading == 3 {
                for i in shown.indices {
                    let n = shown[i].normal * 0.5 + SIMD3<Float>(repeating: 0.5)
                    shown[i].color = SIMD4(n.x, n.y, n.z, 1)
                }
            } else if scene.shading == 4 {
                for i in shown.indices {
                    let uv = shown[i].uv
                    shown[i].color = SIMD4(uv.x - uv.x.rounded(.down), uv.y - uv.y.rounded(.down), 0.15, 1)
                }
            }
            if !shown.isEmpty, !mesh.indices.isEmpty,
               let vb = device.makeBuffer(bytes: shown, length: MemoryLayout<MeshVertex>.stride * shown.count),
               let ib = device.makeBuffer(bytes: mesh.indices, length: 4 * mesh.indices.count) {
                if scene.shading > 0 {
                    let tint: SIMD4<Float> = scene.shading >= 2 ? SIMD4(1, 1, 1, 1) : SIMD4(0.72, 0.72, 0.72, 1)
                    items.append(DrawItem(vertices: vb, indices: ib, count: mesh.indices.count, primitive: .triangle, tint: tint,
                                          lit: scene.shading < 3, textured: false, wire: false))
                }
                if scene.shading == 0 || entry.highlighted {
                    items.append(DrawItem(vertices: vb, indices: ib, count: mesh.indices.count, primitive: .triangle,
                                          tint: SIMD4(accent.x, accent.y, accent.z, scene.shading == 0 ? 0.9 : 0.35), lit: false,
                                          textured: false, wire: true))
                }
            }
            if !mesh.emitPoints.isEmpty,
               let vb = device.makeBuffer(bytes: mesh.emitPoints, length: MemoryLayout<MeshVertex>.stride * mesh.emitPoints.count) {
                items.append(DrawItem(vertices: vb, indices: nil, count: mesh.emitPoints.count, primitive: .point,
                                      tint: SIMD4(accent.x, accent.y, accent.z, 1), lit: false, textured: false, wire: false, pointSize: 7))
                var normals: [(SIMD3<Float>, SIMD4<Float>)] = []
                for point in mesh.emitPoints {
                    normals.append((point.position, SIMD4(0.36, 0.82, 0.82, 0.9)))
                    normals.append((point.position + point.normal * 0.15, SIMD4(0.36, 0.82, 0.82, 0.1)))
                }
                if let item = lineItem(normals, persistent: true) { items.append(item) }
            }
        }
    }

    static let digitSegments: [[(SIMD2<Float>, SIMD2<Float>)]] = {
        let a = (SIMD2<Float>(0, 2), SIMD2<Float>(1, 2)), b = (SIMD2<Float>(1, 2), SIMD2<Float>(1, 1)), c = (SIMD2<Float>(1, 1), SIMD2<Float>(1, 0))
        let d = (SIMD2<Float>(0, 0), SIMD2<Float>(1, 0)), e = (SIMD2<Float>(0, 1), SIMD2<Float>(0, 0)), f = (SIMD2<Float>(0, 2), SIMD2<Float>(0, 1))
        let g = (SIMD2<Float>(0, 1), SIMD2<Float>(1, 1))
        return [[a, b, c, d, e, f], [b, c], [a, b, g, e, d], [a, b, g, c, d], [f, g, b, c], [a, f, g, c, d], [a, f, g, e, c, d], [a, b, c], [a, b, c, d, e, f, g],
                [a, b, c, d, f, g]]
    }()

    private func gizmoItems() -> [DrawItem] {
        guard showGizmo, let simulation = player?.simulation else {
            gizmo.handles = []
            return []
        }
        updateGizmo(simulation)
        var lines: [(SIMD3<Float>, SIMD4<Float>)] = []
        var tips: [MeshVertex] = []
        for handle in gizmo.handles {
            let hot = gizmo.active?.index == handle.index
            let color = hot ? SIMD4<Float>(1, 1, 1, 1) : handle.color
            for i in 1..<handle.points.count {
                lines.append((handle.points[i - 1], color))
                lines.append((handle.points[i], color))
            }
            if handle.kind != 1, handle.kind != 5, let tip = handle.points.last { tips.append(MeshVertex(position: tip, normal: .zero, color: color, uv: .zero)) }
        }
        var result: [DrawItem] = []
        if let item = lineItem(lines) { result.append(item) }
        if !tips.isEmpty, let buffer = frameBuffer(tips) {
            result.append(DrawItem(vertices: buffer, indices: nil, count: tips.count, primitive: .point, tint: SIMD4(1, 1, 1, 1), lit: false,
                                   textured: false, wire: false, pointSize: 11))
        }
        return result
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func pick(at point: CGPoint, in size: CGSize) {
        guard showEffect, size.width > 1, size.height > 1, let document, document.format == .avfx, let simulation = player?.simulation else { return }
        if showBindPoints, let selected = document.selectionID, selected.hasPrefix("avfx/Bind/"), let node = document.node(selected) {
            var best: (id: Int, distance: CGFloat)?
            let caster = simulation.stagePlaces.caster
            for (id, local) in AvfxSimulation.bindPoints {
                let world = Math3D.point(caster, local)
                let clip = lastViewProjection * SIMD4<Float>(world.x, world.y, world.z, 1)
                guard clip.w > 1e-5 else { continue }
                let screen = CGPoint(x: CGFloat((clip.x / clip.w) * 0.5 + 0.5) * size.width, y: CGFloat((clip.y / clip.w) * 0.5 + 0.5) * size.height)
                let d = hypot(screen.x - point.x, screen.y - point.y)
                if d < 12, d < (best?.distance ?? .infinity) { best = (id, d) }
            }
            if let best {
                let holders = [node] + node.children
                for holder in holders {
                    if let field = document.sections(for: holder).flatMap(\.fields).first(where: { $0.tag == "BPID" }) {
                        document.commit(field, from: field.read(), to: .int(best.id))
                        AppDelegate.model?.notice = "Bind point \(best.id) set on \(holder.title)"
                        return
                    }
                }
            }
        }
        let forward = simd_normalize(camera.eye - camera.target)
        let right = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), forward))
        let up = simd_cross(forward, right)
        let half = tan(camera.fov / 2)
        let x = (Float(point.x / size.width) * 2 - 1) * half * Float(size.width / size.height)
        let y = (Float(point.y / size.height) * 2 - 1) * half
        var origin = camera.eye
        var direction = simd_normalize(right * x + up * y - forward)
        if camera.ortho {
            origin = camera.eye + (right * x + up * y) * camera.distance
            direction = -forward
        }
        if let particle = simulation.pick(origin: origin, direction: direction, draws: lastDraws) {
            let id = "avfx/Ptcl/\(particle)"
            if document.node(id) != nil { document.selectionID = id }
        } else {
            clearTarget()
        }
    }

    func clearTarget() {
        guard let document, let root = document.outline.first?.id, document.selectionID != root else { return }
        document.selectionID = root
    }

    func draw(in view: MTKView) {
        var mouse = CGPoint(x: -1, y: -1)
        if let window = view.window {
            let local = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            if view.bounds.contains(local) { mouse = local }
        }
        var signature: [Double] = [Double(camera.yaw), Double(camera.pitch), Double(camera.distance), Double(camera.fov)]
        signature.append(contentsOf: [Double(camera.target.x), Double(camera.target.y), Double(camera.target.z), camera.ortho ? 1 : 0])
        signature.append(contentsOf: [Double(document?.previewRevision ?? 0), Double(document?.revision ?? 0), Double(document?.selectionID?.hashValue ?? 0)])
        signature.append(contentsOf: [Double(mouse.x), Double(mouse.y), Double(NSEvent.pressedMouseButtons), document?.clock.time ?? 0, Double(document?.clock.seed ?? 0)])
        signature.append(contentsOf: [Double(view.drawableSize.width), Double(view.drawableSize.height)])
        signature.append(contentsOf: [Double(PreviewRules.token), Double(ViewportRenderer.bloom.on ? 1 : 0), Double(ViewportRenderer.bloom.threshold),
                                      Double(ViewportRenderer.bloom.intensity), Double(ViewportRenderer.bloom.radius)])
        signature.append(Double(ViewportRenderer.sceneToken))
        signature.append(Double(String(describing: ViewportRenderer.backgroundColor).hashValue % 100_000))
        signature.append(Double(String(describing: document?.visibilityFilter).hashValue % 100_000))
        if signature != idleSignature {
            idleSignature = signature
            lastActivity = CACurrentMediaTime()
        }
        let playing = document?.clock.playing ?? true
        let busy = playing || CACurrentMediaTime() - lastActivity < 1.5
        let rate = busy ? 60 : 10
        if view.preferredFramesPerSecond != rate { view.preferredFramesPerSecond = rate }
        guard pipeline != nil else { return }
        let aspect = Float(view.drawableSize.width / max(view.drawableSize.height, 1))
        let near = max(camera.distance * 0.01, 0.01)
        let projection = camera.ortho
            ? ViewportRenderer.orthographic(height: 2 * camera.distance * tan(camera.fov / 2), aspect: aspect, near: near, far: 2000)
            : ViewportRenderer.perspective(fovY: camera.fov, aspect: aspect, near: near, far: 2000)
        var viewMatrix = ViewportRenderer.lookAt(eye: camera.eye, target: camera.target, up: SIMD3(0, 1, 0))
        if quake.shift != .zero || quake.turn != .zero {
            let turn = simd_quatf(angle: quake.turn.x, axis: Vec3(1, 0, 0)) * simd_quatf(angle: quake.turn.y, axis: Vec3(0, 1, 0))
                * simd_quatf(angle: quake.turn.z, axis: Vec3(0, 0, 1))
            viewMatrix = Math3D.compose(quake.shift, turn, Vec3(1, 1, 1), order: quake.order).inverse * viewMatrix
        }
        let viewProjection = projection * viewMatrix
        lastViewProjection = viewProjection
        lastViewSize = view.bounds.size
        let now = CACurrentMediaTime()
        let elapsed = now - lastFrame
        lastFrame = now
        let forward = simd_normalize(camera.eye - camera.target)
        let right = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), forward))
        let cameraState = CameraState(position: camera.eye, rotation: Math3D.quaternion(x: right, y: simd_cross(forward, right), z: forward),
                                      fovY: camera.fov, viewportHeight: Float(view.drawableSize.height))
        let effect = effectDraws(elapsed: elapsed, camera: cameraState)
        let screen = effect != nil ? player?.simulation?.screenEffects(camera: camera.eye, filter: filter) : nil
        quake = PreviewRules.isOn("cameraQuake") ? screen?.quake ?? (.zero, .zero, 0) : (.zero, .zero, 0)
        let lights = Array((effect != nil ? player?.simulation?.lights(filter: filter) : nil ?? []) ?? []).prefix(4)
        let split = effect.map { particleRenderer?.needsScene($0.particles) ?? false } ?? false
        let waited = inFlight.wait(timeout: .now() + 0.1) == .success
        guard let pipeline, let descriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let buffer = queue.makeCommandBuffer() else {
            if waited { inFlight.signal() }
            return
        }
        if waited { buffer.addCompletedHandler { [inFlight] _ in inFlight.signal() } }
        beginFrameBuffers()
        renderShadow(buffer, lights: Array(lights))
        let depthTarget = descriptor.depthAttachment.texture
        let resolved = descriptor.colorAttachments[0].resolveTexture ?? descriptor.colorAttachments[0].texture
        let canSplit = split && depthTarget != nil && resolved != nil && descriptor.colorAttachments[0].resolveTexture != nil
        if canSplit {
            descriptor.colorAttachments[0].storeAction = .storeAndMultisampleResolve
            descriptor.depthAttachment.storeAction = .store
        }
        let bloomOn = ViewportRenderer.bloom.on && showEffect
        let helpersOnTop = (bloomOn || screen?.effects.isEmpty == false) && topPipeline != nil && !drawable.texture.isFramebufferOnly
        guard var encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            buffer.commit()
            return
        }
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentSamplerState(sampler, index: 0)
        encoder.setFragmentTexture(white, index: 1)
        encoder.setFragmentTexture(noShadow, index: 2)
        encoder.setCullMode(.none)
        func lit(_ uniforms: inout Uniforms) {
            var positions = [SIMD4<Float>](repeating: .zero, count: 4), colors = [SIMD4<Float>](repeating: .zero, count: 4)
            for (i, light) in lights.enumerated() {
                positions[i] = SIMD4(light.position.x, light.position.y, light.position.z, light.decay)
                colors[i] = SIMD4(light.color.x, light.color.y, light.color.z, light.point ? light.reach : -1)
            }
            uniforms.lightPosition = (positions[0], positions[1], positions[2], positions[3])
            uniforms.lightColor = (colors[0], colors[1], colors[2], colors[3])
            uniforms.options.w = lights.isEmpty ? 0 : 1
            if let shadowState {
                uniforms.shadow = SIMD4(Float(shadowState.index), shadowState.near, shadowState.far, 0.04)
                let f = shadowState.faces
                uniforms.shadowFaces = (f[0], f[1], f[2], f[3], f[4], f[5])
            }
        }
        let ground = showFloor ? [floor].compactMap { $0 } : []
        if referenceToken != ViewportRenderer.referenceToken {
            referenceToken = ViewportRenderer.referenceToken
            reference = []
            if let mesh = ViewportRenderer.referenceMesh, !mesh.vertices.isEmpty, !mesh.indices.isEmpty,
               let vb = device.makeBuffer(bytes: mesh.vertices, length: MemoryLayout<MeshVertex>.stride * mesh.vertices.count) {
                let parts = ViewportRenderer.referenceParts.isEmpty ? [(start: 0, count: mesh.indices.count, texture: nil)] : ViewportRenderer.referenceParts
                for part in parts where part.count > 0 && part.start + part.count <= mesh.indices.count {
                    let slice = Array(mesh.indices[part.start..<(part.start + part.count)])
                    guard let ib = device.makeBuffer(bytes: slice, length: 4 * slice.count) else { continue }
                    let map = part.texture.flatMap { ParticleRenderer.makeTexture(device, $0) }
                    reference.append(DrawItem(vertices: vb, indices: ib, count: slice.count, primitive: .triangle,
                                              tint: map == nil ? SIMD4(0.62, 0.62, 0.66, 1) : SIMD4(1, 1, 1, 1), lit: true, textured: false, wire: false, map: map))
                }
            }
        }
        if showEffect, let item = backdropItem(aspect: aspect) {
            var uniforms = Uniforms(viewProjection: matrix_identity_float4x4, model: matrix_identity_float4x4, tint: item.tint, options: SIMD4(0, 1, 1, 0))
            encoder.setDepthStencilState(overlayDepthState)
            encoder.setTriangleFillMode(.fill)
            encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            encoder.setFragmentTexture(item.map ?? white, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: item.count)
        }
        let dissolving = effect != nil && PreviewRules.isOn("dissolve") ? player?.simulation?.dissolve(filter: filter) : nil
        let dissolveMap = dissolving.flatMap { $0.texture >= 0 ? particleRenderer?.textureProvider($0.texture)?.texture : nil }
        let stage = player?.simulation?.stagePlaces ?? (caster: matrix_identity_float4x4, target: matrix_identity_float4x4)
        for (pass, list) in [ground, grid, items, reference].enumerated() {
            for item in list {
                var uniforms = Uniforms(viewProjection: viewProjection, model: pass == 3 ? stage.caster : matrix_identity_float4x4, tint: item.tint,
                                        options: SIMD4(item.lit && pass != 0 ? 1 : 0, item.textured || item.map != nil ? 1 : 0, item.pointSize, 0))
                if item.lit { lit(&uniforms) }
                let scene = ViewportRenderer.scene
                uniforms.look = SIMD4(scene.toneMap && (pass == 0 || pass == 3) ? 1 : 0, pow(2, scene.exposure), scene.lightIntensity / .pi, 0)
                if pass == 3, let dissolving, dissolveMap != nil || dissolving.shaped {
                    uniforms.dissolve = SIMD4(dissolving.amount, dissolving.edge, dissolving.reverse ? 1 : 0, 1)
                    uniforms.dissolveColor = SIMD4(dissolving.color.x, dissolving.color.y, dissolving.color.z, 0)
                    uniforms.dissolveUv = dissolving.uvMatrix
                    uniforms.dissolveOffset = SIMD4(dissolving.uvOffset.x, dissolving.uvOffset.y, dissolveMap != nil ? 1 : 0, dissolving.shaped ? 1 : 0)
                    uniforms.dissolveShape = dissolving.inverse
                    uniforms.dissolveInfo = SIMD4(Float(dissolving.shape), dissolving.widths.x, dissolving.widths.y, dissolving.widths.z)
                    uniforms.dissolveBands = (dissolving.colors[0], dissolving.colors[1], dissolving.colors[2])
                }
                encoder.setFragmentTexture(dissolveMap ?? white, index: 1)
                encoder.setFragmentTexture(shadowState != nil ? shadowMap : noShadow, index: 2)
                encoder.setDepthStencilState(pass == 1 || item.wire || item.textured ? overlayDepthState : depthState)
                encoder.setTriangleFillMode(item.wire ? .lines : .fill)
                encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentTexture(item.map ?? (item.textured ? (texture ?? white) : white), index: 0)
                if let indices = item.indices {
                    encoder.drawIndexedPrimitives(type: item.primitive, indexCount: item.count, indexType: .uint32, indexBuffer: indices,
                                                  indexBufferOffset: 0)
                } else {
                    encoder.drawPrimitives(type: item.primitive, vertexStart: 0, vertexCount: item.count)
                }
            }
        }
        particleRenderer?.sceneColor = nil
        particleRenderer?.sceneDepth = nil
        if canSplit, let depthTarget, let resolved, sceneTextures(resolved, depth: depthTarget), let sceneColor, let sceneDepth {
            encoder.endEncoding()
            if let blit = buffer.makeBlitCommandEncoder() {
                blit.copy(from: resolved, to: sceneColor)
                blit.copy(from: depthTarget, to: sceneDepth)
                blit.endEncoding()
            }
            descriptor.colorAttachments[0].loadAction = .load
            descriptor.colorAttachments[0].storeAction = .multisampleResolve
            descriptor.depthAttachment.loadAction = .load
            descriptor.depthAttachment.storeAction = .dontCare
            guard let second = buffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                buffer.commit()
                return
            }
            encoder = second
            particleRenderer?.sceneColor = sceneColor
            particleRenderer?.sceneDepth = sceneDepth
        }
        if let effect, let particleRenderer {
            particleRenderer.viewport = SIMD2(Float(view.drawableSize.width), Float(view.drawableSize.height))
            particleRenderer.clip = SIMD2(near, 2000)
            particleRenderer.orthographic = camera.ortho
            particleRenderer.softDistance = player?.simulation?.schema.softFadeRange ?? 0.5
            particleRenderer.scene = ViewportRenderer.scene
            particleRenderer.globalFog = player?.simulation?.schema.globalFog ?? 0
            particleRenderer.draw(encoder, draws: effect.draws, particles: effect.particles, view: viewMatrix, projection: projection, camera: Math3D.position(viewMatrix.inverse),
                                  shading: effectShading)
            if !highlightDraws.isEmpty {
                particleRenderer.drawHighlight(encoder, draws: highlightDraws, particles: effect.particles, view: viewMatrix, projection: projection,
                                               camera: Math3D.position(viewMatrix.inverse), color: SIMD4(1.0, 0.5, 0.05, 1))
            }
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentSamplerState(sampler, index: 0)
            encoder.setFragmentTexture(white, index: 1)
            encoder.setFragmentTexture(noShadow, index: 2)
            encoder.setCullMode(.none)
            if !helpersOnTop { drawHelpers(encoder, viewProjection: viewProjection, depth: true) }
        }
        encoder.endEncoding()
        if let effects = screen?.effects, !effects.isEmpty, postPipeline != nil { applyPost(Array(effects.prefix(4)), buffer: buffer, target: drawable.texture, viewProjection: viewProjection) }
        if bloomOn { applyBloom(buffer: buffer, target: drawable.texture) }
        if helpersOnTop, let topPipeline {
            let pass = MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture = drawable.texture
            pass.colorAttachments[0].loadAction = .load
            pass.colorAttachments[0].storeAction = .store
            if let top = buffer.makeRenderCommandEncoder(descriptor: pass) {
                top.setRenderPipelineState(topPipeline)
                top.setFragmentSamplerState(sampler, index: 0)
                top.setFragmentTexture(white, index: 1)
                top.setFragmentTexture(noShadow, index: 2)
                top.setCullMode(.none)
                drawHelpers(top, viewProjection: viewProjection, depth: false)
                top.endEncoding()
            }
        }
        if let request = captureRequest, effect != nil {
            captureRequest = nil
            let texture = drawable.texture
            buffer.addCompletedHandler { _ in
                let w = texture.width, h = texture.height
                guard w > 0, h > 0, !texture.isFramebufferOnly else { return }
                var bytes = [UInt8](repeating: 0, count: w * h * 4)
                texture.getBytes(&bytes, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
                for i in stride(from: 0, to: bytes.count, by: 4) { bytes.swapAt(i, i + 2) }
                guard let provider = CGDataProvider(data: Data(bytes) as CFData),
                      let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: provider, decode: nil,
                                          shouldInterpolate: true, intent: .defaultIntent) else { return }
                DispatchQueue.main.async { request(image) }
            }
        }
        buffer.present(drawable)
        buffer.commit()
    }

    static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tan(fovY / 2)
        let x = y / aspect
        let z = far / (near - far)
        return simd_float4x4(columns: (SIMD4(x, 0, 0, 0), SIMD4(0, y, 0, 0), SIMD4(0, 0, z, -1), SIMD4(0, 0, z * near, 0)))
    }

    static func orthographic(height: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 2 / max(height, 1e-5)
        let x = y / aspect
        let z = 1 / (near - far)
        return simd_float4x4(columns: (SIMD4(x, 0, 0, 0), SIMD4(0, y, 0, 0), SIMD4(0, 0, z, 0), SIMD4(0, 0, z * near, 1)))
    }

    static func lookAt(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let f = simd_normalize(eye - target)
        let r = simd_normalize(simd_cross(up, f))
        let u = simd_cross(f, r)
        return simd_float4x4(columns: (
            SIMD4(r.x, u.x, f.x, 0), SIMD4(r.y, u.y, f.y, 0), SIMD4(r.z, u.z, f.z, 0),
            SIMD4(-simd_dot(r, eye), -simd_dot(u, eye), -simd_dot(f, eye), 1)))
    }
}

final class ViewportMTKView: MTKView {
    var camera: ViewportCamera?

    override var acceptsFirstResponder: Bool { true }

    private var pressPoint: NSPoint?

    private var draggingGizmo = false

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        pressPoint = event.locationInWindow
        draggingGizmo = (delegate as? ViewportRenderer)?.gizmoBegin(at: convert(event.locationInWindow, from: nil)) ?? false
    }

    override func mouseUp(with event: NSEvent) {
        defer { pressPoint = nil }
        if draggingGizmo {
            draggingGizmo = false
            (delegate as? ViewportRenderer)?.gizmoEnd()
            return
        }
        guard let pressPoint, hypot(event.locationInWindow.x - pressPoint.x, event.locationInWindow.y - pressPoint.y) < 3 else { return }
        let point = convert(event.locationInWindow, from: nil)
        (delegate as? ViewportRenderer)?.pick(at: point, in: bounds.size)
    }

    override func mouseDragged(with event: NSEvent) {
        if draggingGizmo {
            (delegate as? ViewportRenderer)?.gizmoMove(to: convert(event.locationInWindow, from: nil))
            return
        }
        if event.modifierFlags.contains(.shift) {
            camera?.pan(dx: Float(event.deltaX), dy: Float(event.deltaY))
        } else if event.modifierFlags.contains(.control) || event.modifierFlags.contains(.command) {
            camera?.zoom(1 + Float(event.deltaY) * 0.01)
        } else {
            camera?.orbit(dx: Float(event.deltaX), dy: Float(event.deltaY))
        }
    }

    override func otherMouseDragged(with event: NSEvent) { mouseDragged(with: event) }

    override func rightMouseDragged(with event: NSEvent) {
        camera?.pan(dx: Float(event.deltaX), dy: Float(event.deltaY))
    }

    override func scrollWheel(with event: NSEvent) {
        let dx = Float(event.scrollingDeltaX), dy = Float(event.scrollingDeltaY)
        if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.control) || !event.hasPreciseScrollingDeltas {
            camera?.zoom(exp(-dy * (event.hasPreciseScrollingDeltas ? 0.005 : 0.08)))
        } else if event.modifierFlags.contains(.shift) {
            camera?.pan(dx: dx * 2, dy: dy * 2)
        } else {
            camera?.orbit(dx: dx, dy: dy)
        }
    }

    override func magnify(with event: NSEvent) {
        camera?.zoom(1 - Float(event.magnification))
    }

    override func keyDown(with event: NSEvent) {
        guard let camera, let key = event.charactersIgnoringModifiers else { return super.keyDown(with: event) }
        switch key {
        case "1": camera.setView(yaw: 0, pitch: 0)
        case "3": camera.setView(yaw: .pi / 2, pitch: 0)
        case "7": camera.setView(yaw: 0, pitch: 1.55)
        case ".": NotificationCenter.default.post(name: .viewportFrameAll, object: nil)
        case "\u{1b}": (delegate as? ViewportRenderer)?.clearTarget()
        default: super.keyDown(with: event)
        }
    }
}

extension Notification.Name {
    static let viewportFrameAll = Notification.Name("viewportFrameAll")
}

struct MetalViewport: NSViewRepresentable {
    let camera: ViewportCamera
    let scene: ViewportScene
    let document: EffectDocument
    let app: AppModel
    var background = 0

    func makeCoordinator() -> ViewportRenderer? { ViewportRenderer(camera: camera) }

    func makeNSView(context: Context) -> ViewportMTKView {
        let view = ViewportMTKView()
        view.device = context.coordinator?.device ?? MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 4
        view.framebufferOnly = false
        view.depthStencilStorageMode = .private
        view.clearColor = MTLClearColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 1)
        view.delegate = context.coordinator
        view.camera = camera
        view.preferredFramesPerSecond = 60
        context.coordinator?.document = document
        context.coordinator?.app = app
        context.coordinator?.update(scene)
        return view
    }

    func updateNSView(_ view: ViewportMTKView, context: Context) {
        let shade = AppModel.backgrounds[min(max(background, 0), AppModel.backgrounds.count - 1)].value
        if let custom = ViewportRenderer.backgroundColor {
            view.clearColor = MTLClearColor(red: custom.x, green: custom.y, blue: custom.z, alpha: 1)
        } else {
            view.clearColor = MTLClearColor(red: shade, green: shade, blue: shade, alpha: 1)
        }
        context.coordinator?.document = document
        context.coordinator?.app = app
        context.coordinator?.update(scene)
    }
}
