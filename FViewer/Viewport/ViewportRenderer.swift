import Combine
import MetalKit
import SwiftUI
import simd

final class ViewportCamera: ObservableObject {
    @Published var yaw: Float = 0.7
    @Published var pitch: Float = 0.45
    @Published var distance: Float = 8
    @Published var target = SIMD3<Float>(0, 1, 0)

    var eye: SIMD3<Float> {
        target + distance * SIMD3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
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
    var filter = VisibilityFilter()
    var texture: CGImage?
    var shading = 1
    var revision = 0
}

private struct Uniforms {
    var viewProjection: simd_float4x4
    var model: simd_float4x4
    var tint: SIMD4<Float>
    var options: SIMD4<Float>
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
    private var filter = VisibilityFilter()
    private var particleRenderer: ParticleRenderer?
    private var player: AvfxPlayer?
    private var effectTextures: [String: LoadedTexture] = [:]
    private var texturePaths: [String] = []
    private var libraryToken = -1
    private var lastFrame = CACurrentMediaTime()
    weak var document: EffectDocument?
    weak var app: AppModel?

    init?(camera: ViewportCamera) {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
        self.device = device
        self.queue = queue
        self.camera = camera
        super.init()
        build()
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

        let depth = MTLDepthStencilDescriptor()
        depth.depthCompareFunction = .lessEqual
        depth.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depth)
        let overlay = MTLDepthStencilDescriptor()
        overlay.depthCompareFunction = .lessEqual
        overlay.isDepthWriteEnabled = false
        overlayDepthState = device.makeDepthStencilState(descriptor: overlay)

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)

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
        if let cached = effectTextures[path] { return cached }
        guard let decoded = app?.decodedTexture(for: path), let texture = ParticleRenderer.makeTexture(device, decoded) else { return nil }
        let loaded = LoadedTexture(texture: texture, alphaOnly: decoded.alphaOnly)
        effectTextures[path] = loaded
        return loaded
    }

    private func overlayItems() -> [DrawItem] {
        guard let simulation = player?.simulation, showEmitters || showBindPoints else { return [] }
        var lines: [(SIMD3<Float>, SIMD4<Float>)] = []
        var points: [MeshVertex] = []
        if showEmitters {
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
        if showBindPoints {
            let color = SIMD4<Float>(1, 0.63, 0.16, 1)
            for point in simulation.usedBindPoints {
                for axis in [SIMD3<Float>(0.08, 0, 0), SIMD3(0, 0.08, 0), SIMD3(0, 0, 0.08)] {
                    lines.append((point - axis, color))
                    lines.append((point + axis, color))
                }
            }
            let body = SIMD4<Float>(1, 1, 1, 0.35)
            let figure: [(SIMD3<Float>, SIMD3<Float>)] = [
                (SIMD3(0, 0, 0), SIMD3(0, 1.45, 0)), (SIMD3(-0.2, 1.42, 0), SIMD3(0.2, 1.42, 0)), (SIMD3(-0.2, 1.42, 0), SIMD3(-0.33, 0.78, 0)),
                (SIMD3(0.2, 1.42, 0), SIMD3(0.33, 0.78, 0)), (SIMD3(-0.1, 0.95, 0), SIMD3(-0.1, 0, 0)), (SIMD3(0.1, 0.95, 0), SIMD3(0.1, 0, 0)),
                (SIMD3(-0.1, 0.95, 0), SIMD3(0.1, 0.95, 0)),
            ]
            for segment in figure {
                lines.append((segment.0, body))
                lines.append((segment.1, body))
            }
            for i in 0..<16 {
                let a = Float(i) / 16 * 2 * .pi, b = Float(i + 1) / 16 * 2 * .pi
                lines.append((SIMD3(cos(a) * 0.12, 1.6 + sin(a) * 0.13, 0), body))
                lines.append((SIMD3(cos(b) * 0.12, 1.6 + sin(b) * 0.13, 0), body))
            }
        }
        var items: [DrawItem] = []
        if let item = lineItem(lines) { items.append(item) }
        if !points.isEmpty, let buffer = device.makeBuffer(bytes: points, length: MemoryLayout<MeshVertex>.stride * points.count) {
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
        if player.schemaChanged || token != libraryToken {
            if token != libraryToken { effectTextures = [:] }
            libraryToken = token
            texturePaths = document.textureSlots.map(\.path)
            particleRenderer?.reset()
        }
        let draws = player.frame(elapsed: elapsed, camera: state, filter: filter)
        return (draws, player.simulation?.schema.particles ?? [])
    }

    private func lineItem(_ points: [(SIMD3<Float>, SIMD4<Float>)]) -> DrawItem? {
        let vertices = points.map { MeshVertex(position: $0.0, normal: SIMD3(0, 1, 0), color: $0.1, uv: .zero) }
        guard !vertices.isEmpty,
              let buffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<MeshVertex>.stride * vertices.count) else { return nil }
        return DrawItem(vertices: buffer, indices: nil, count: vertices.count, primitive: .line, tint: SIMD4(1, 1, 1, 1), lit: false,
                        textured: false, wire: false)
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
        grid = lineItem(points).map { [$0] } ?? []
    }

    func update(_ scene: ViewportScene) {
        showEffect = scene.showEffect
        effectShading = scene.effectShading
        showEmitters = scene.showEmitters
        showBindPoints = scene.showBindPoints
        filter = scene.filter
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
            if !mesh.vertices.isEmpty, !mesh.indices.isEmpty,
               let vb = device.makeBuffer(bytes: mesh.vertices, length: MemoryLayout<MeshVertex>.stride * mesh.vertices.count),
               let ib = device.makeBuffer(bytes: mesh.indices, length: 4 * mesh.indices.count) {
                if scene.shading > 0 {
                    let tint: SIMD4<Float> = scene.shading == 2 ? SIMD4(1, 1, 1, 1) : SIMD4(0.72, 0.72, 0.72, 1)
                    items.append(DrawItem(vertices: vb, indices: ib, count: mesh.indices.count, primitive: .triangle, tint: tint,
                                          lit: true, textured: false, wire: false))
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
                if let item = lineItem(normals) { items.append(item) }
            }
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let pipeline, let descriptor = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let buffer = queue.makeCommandBuffer(), let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) else { return }
        let aspect = Float(view.drawableSize.width / max(view.drawableSize.height, 1))
        let projection = ViewportRenderer.perspective(fovY: 0.75, aspect: aspect, near: max(camera.distance * 0.01, 0.01), far: 2000)
        let viewMatrix = ViewportRenderer.lookAt(eye: camera.eye, target: camera.target, up: SIMD3(0, 1, 0))
        let viewProjection = projection * viewMatrix
        let now = CACurrentMediaTime()
        let elapsed = now - lastFrame
        lastFrame = now
        let forward = simd_normalize(camera.eye - camera.target)
        let right = simd_normalize(simd_cross(SIMD3<Float>(0, 1, 0), forward))
        let cameraState = CameraState(position: camera.eye, rotation: Math3D.quaternion(x: right, y: simd_cross(forward, right), z: forward),
                                      fovY: 0.75, viewportHeight: Float(view.drawableSize.height))
        let effect = effectDraws(elapsed: elapsed, camera: cameraState)
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentSamplerState(sampler, index: 0)
        encoder.setCullMode(.none)
        for (pass, list) in [grid, items].enumerated() {
            for item in list {
                var uniforms = Uniforms(viewProjection: viewProjection, model: matrix_identity_float4x4, tint: item.tint,
                                        options: SIMD4(item.lit ? 1 : 0, item.textured ? 1 : 0, item.pointSize, 0))
                encoder.setDepthStencilState(pass == 0 || item.wire || item.textured ? overlayDepthState : depthState)
                encoder.setTriangleFillMode(item.wire ? .lines : .fill)
                encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentTexture(item.textured ? (texture ?? white) : white, index: 0)
                if let indices = item.indices {
                    encoder.drawIndexedPrimitives(type: item.primitive, indexCount: item.count, indexType: .uint32, indexBuffer: indices,
                                                  indexBufferOffset: 0)
                } else {
                    encoder.drawPrimitives(type: item.primitive, vertexStart: 0, vertexCount: item.count)
                }
            }
        }
        if let effect, let particleRenderer {
            particleRenderer.draw(encoder, draws: effect.draws, particles: effect.particles, view: viewMatrix, projection: projection, camera: camera.eye,
                                  shading: effectShading)
            encoder.setRenderPipelineState(pipeline)
            encoder.setFragmentSamplerState(sampler, index: 0)
            encoder.setCullMode(.none)
            for item in overlayItems() {
                var uniforms = Uniforms(viewProjection: viewProjection, model: matrix_identity_float4x4, tint: item.tint,
                                        options: SIMD4(0, 0, item.pointSize, 0))
                encoder.setDepthStencilState(overlayDepthState)
                encoder.setVertexBuffer(item.vertices, offset: 0, index: 0)
                encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
                encoder.setFragmentTexture(white, index: 0)
                encoder.drawPrimitives(type: item.primitive, vertexStart: 0, vertexCount: item.count)
            }
        }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }

    static func perspective(fovY: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let y = 1 / tan(fovY / 2)
        let x = y / aspect
        let z = far / (near - far)
        return simd_float4x4(columns: (SIMD4(x, 0, 0, 0), SIMD4(0, y, 0, 0), SIMD4(0, 0, z, -1), SIMD4(0, 0, z * near, 0)))
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

    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }

    override func mouseDragged(with event: NSEvent) {
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
            camera?.zoom(1 - dy * (event.hasPreciseScrollingDeltas ? 0.005 : 0.08))
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

    func makeCoordinator() -> ViewportRenderer? { ViewportRenderer(camera: camera) }

    func makeNSView(context: Context) -> ViewportMTKView {
        let view = ViewportMTKView()
        view.device = context.coordinator?.device ?? MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.sampleCount = 4
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
        context.coordinator?.document = document
        context.coordinator?.app = app
        context.coordinator?.update(scene)
    }
}
