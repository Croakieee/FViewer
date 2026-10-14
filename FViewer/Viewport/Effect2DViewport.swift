import MetalKit
import SwiftUI
import VfxCore
import VfxMetal

final class Effect2DRenderer: NSObject, MTKViewDelegate {
    private let queue: MTLCommandQueue?
    private var renderer: MetalRenderer?
    private var core: EffectCore?
    private var loadedDocument: UUID?
    private var loadedRevision = -1
    private var libraryToken = -1
    private var loadedTextures: Set<String> = []
    private var duration: Double = 30
    private var appliedSeed = 1
    private var appliedPlane: SIMD3<Double>?
    private var appliedParams: [String: Double] = [:]
    private var hasLoops = false
    private var appliedRelease = false
    private var appliedTriggers = 0
    private var lastFrame = CACurrentMediaTime()
    private var lastActivity = CACurrentMediaTime()
    private var idleSignature: [Double] = []
    private var statusTick = 0
    private var loadedFilter = VisibilityFilter()
    private var linePipeline: MTLRenderPipelineState?
    private let device: MTLDevice?
    var shading = 0
    var pan = SIMD2<Float>(0, 0)
    var zoom: Float = 1
    weak var document: EffectDocument?
    weak var app: AppModel?

    init(device: MTLDevice?) {
        self.device = device
        queue = device?.makeCommandQueue()
        if let device { renderer = try? MetalRenderer(device: device, pixelFormat: .bgra8Unorm) }
        super.init()
        guard let device, let library = try? device.makeLibrary(source: Effect2DRenderer.lineShader, options: nil) else { return }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "lineVertex")
        descriptor.fragmentFunction = library.makeFunction(name: "lineFragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        linePipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static let lineShader = """
    #include <metal_stdlib>
    using namespace metal;
    vertex float4 lineVertex(uint vid [[vertex_id]], const device float2 *positions [[buffer(0)]]) {
        return float4(positions[vid], 0.0, 1.0);
    }
    fragment float4 lineFragment() {
        return float4(0.55, 0.85, 1.0, 0.75);
    }
    """

    private func drawWireframe(_ encoder: MTLRenderCommandEncoder, half: SIMD2<Float>) {
        guard let core, let device, let linePipeline else { return }
        var vertices: [Float] = []
        func add(_ p: SIMD2<Double>) {
            vertices.append((Float(p.x) * zoom + pan.x) / half.x)
            vertices.append(-(Float(p.y) * zoom + pan.y) / half.y)
        }
        for triangle in core.wireframe().prefix(60000) {
            add(triangle.0); add(triangle.1)
            add(triangle.1); add(triangle.2)
            add(triangle.2); add(triangle.0)
        }
        guard !vertices.isEmpty, let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * 4) else { return }
        encoder.setRenderPipelineState(linePipeline)
        encoder.setVertexBuffer(buffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertices.count / 2)
    }

    private func reload(_ document: EffectDocument) {
        guard let renderer, let app else { return }
        if app.libraryToken != libraryToken {
            libraryToken = app.libraryToken
            loadedTextures = []
        }
        loadedDocument = document.id
        loadedRevision = document.previewRevision
        loadedFilter = document.visibilityFilter
        duration = document.duration
        for slot in document.textureSlots where !loadedTextures.contains(slot.name) {
            let found = app.textureURL(slot.name)
            guard let url = found ?? PlaceholderTextures.url(for: slot.name), url.pathExtension.lowercased() == "png" else { continue }
            var modes = app.addressModes(for: slot.name)
            if found == nil, PlaceholderTextures.isMirrored(slot.name) { modes = ("mirror-repeat", "mirror-repeat") }
            if renderer.loadTexture(name: slot.name, url: url, u: AddressMode(rawValue: modes.u) ?? .repeat_, v: AddressMode(rawValue: modes.v) ?? .repeat_) {
                loadedTextures.insert(slot.name)
            }
        }
        var models: [String: ModelData] = [:]
        for name in document.modelNames {
            if let url = app.pixiModelURL(name), let data = try? Data(contentsOf: url), let model = try? JSONDecoder().decode(ModelData.self, from: data) {
                models[name] = model
            }
        }
        renderer.reset()
        core = nil
        let data = document.pixiData(filter: loadedFilter)
        hasLoops = String(decoding: data, as: UTF8.self).contains("\"loop\"")
        do {
            let created = try EffectCore(json: data, options: EffectCoreOptions(views: renderer, models: models, seed: UInt32(max(1, document.clock.seed))))
            appliedSeed = document.clock.seed
            appliedPlane = nil
            appliedParams = [:]
            created.play()
            core = created
            document.clock.status = ""
        } catch {
            document.clock.status = "Effect error: \(error)"
        }
        appliedRelease = false
        appliedTriggers = 0
    }

    private func rewind() {
        core?.restart(seed: UInt32(max(1, document?.clock.seed ?? 1)))
        appliedRelease = false
        appliedTriggers = 0
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        var mouse = CGPoint(x: -1, y: -1)
        if let window = view.window {
            let local = view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            if view.bounds.contains(local) { mouse = local }
        }
        var signature: [Double] = [Double(document?.previewRevision ?? 0), Double(document?.revision ?? 0), Double(document?.selectionID?.hashValue ?? 0)]
        signature.append(contentsOf: [Double(mouse.x), Double(mouse.y), Double(NSEvent.pressedMouseButtons), document?.clock.time ?? 0, Double(document?.clock.seed ?? 0)])
        signature.append(contentsOf: [Double(view.drawableSize.width), Double(view.drawableSize.height)])
        signature.append(contentsOf: [Double(PreviewRules.token), Double(ViewportRenderer.bloom.on ? 1 : 0), Double(ViewportRenderer.bloom.threshold),
                                      Double(ViewportRenderer.bloom.intensity), Double(ViewportRenderer.bloom.radius)])
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
        let now = CACurrentMediaTime()
        let elapsed = now - lastFrame
        lastFrame = now
        if let document, document.format == .pixi {
            if loadedDocument != document.id || loadedRevision != document.previewRevision || libraryToken != (app?.libraryToken ?? 0)
                || loadedFilter != document.visibilityFilter { reload(document) }
            if let core {
                let clock = document.clock
                if appliedSeed != clock.seed {
                    appliedSeed = clock.seed
                    rewind()
                }
                if appliedPlane != document.plane {
                    appliedPlane = document.plane
                    var plane = Plane()
                    plane.tiltX = document.plane.x * .pi / 180
                    plane.tiltY = document.plane.y * .pi / 180
                    plane.perspective = document.plane.z
                    core.setPlane(plane)
                }
                if appliedParams != document.paramOverrides {
                    for (name, value) in document.paramOverrides where appliedParams[name] != value { _ = core.setParam(name, value) }
                    appliedParams = document.paramOverrides
                }
                if core.fps > 0, clock.rate != core.fps { clock.rate = core.fps }
                clock.advance(elapsed, duration: duration, finished: core.finished, held: hasLoops && !core.released && !core.killing)
                if clock.time < core.time - 0.01 { rewind() }
                var steps = 0
                while core.time + 0.01 < clock.time && steps < 4000 {
                    steps += 1
                    if let release = clock.releaseTime, !appliedRelease, core.time >= release {
                        appliedRelease = true
                        core.release()
                    }
                    while appliedTriggers < clock.triggers.count, core.time >= clock.triggers[appliedTriggers].time {
                        core.trigger(clock.triggers[appliedTriggers].index)
                        appliedTriggers += 1
                    }
                    core.update(min(1.0 / 30.0, (clock.time - core.time) / core.fps))
                }
                if steps == 0 { core.update(0) }
                statusTick += 1
                if statusTick % 12 == 0 {
                    let missing = renderer?.missingTextures.count ?? 0
                    var status = "\(core.particleCount) particles" + (missing > 0 ? " · \(missing) missing textures" : "")
                    if let error = core.error { status = "Error: \(error)" }
                    if clock.status != status { clock.status = status }
                }
            }
        }
        guard let renderer, let queue, let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let buffer = queue.makeCommandBuffer(), let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        let half = SIMD2(Float(view.bounds.width / 2), Float(view.bounds.height / 2))
        if core != nil, shading != 1 { renderer.draw(encoder, half: half, zoom: zoom, pan: pan) }
        if shading != 0 { drawWireframe(encoder, half: half) }
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}

final class Effect2DMTKView: MTKView {
    weak var effectRenderer: Effect2DRenderer?

    override func mouseDragged(with event: NSEvent) {
        effectRenderer?.pan += SIMD2(Float(event.deltaX), Float(event.deltaY))
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            effectRenderer?.pan = .zero
            effectRenderer?.zoom = 1
        }
    }

    override func scrollWheel(with event: NSEvent) {
        guard let effectRenderer else { return }
        if event.hasPreciseScrollingDeltas && !event.modifierFlags.contains(.command) {
            effectRenderer.pan += SIMD2(Float(event.scrollingDeltaX), Float(event.scrollingDeltaY))
        } else {
            effectRenderer.zoom = min(8, max(0.1, effectRenderer.zoom * (1 + Float(event.scrollingDeltaY) * 0.02)))
        }
    }

    override func magnify(with event: NSEvent) {
        guard let effectRenderer else { return }
        effectRenderer.zoom = min(8, max(0.1, effectRenderer.zoom * (1 + Float(event.magnification))))
    }
}

struct Effect2DViewport: NSViewRepresentable {
    let document: EffectDocument
    let app: AppModel
    let shading: Int
    var background = 0

    func makeCoordinator() -> Effect2DRenderer { Effect2DRenderer(device: MTLCreateSystemDefaultDevice()) }

    func makeNSView(context: Context) -> Effect2DMTKView {
        let view = Effect2DMTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0.075, green: 0.075, blue: 0.1, alpha: 1)
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        view.effectRenderer = context.coordinator
        context.coordinator.document = document
        context.coordinator.app = app
        return view
    }

    func updateNSView(_ view: Effect2DMTKView, context: Context) {
        let shade = background == 0 ? 0.075 : AppModel.backgrounds[min(max(background, 0), AppModel.backgrounds.count - 1)].value
        view.clearColor = MTLClearColor(red: shade, green: shade, blue: shade + (background == 0 ? 0.025 : 0), alpha: 1)
        context.coordinator.document = document
        context.coordinator.app = app
        context.coordinator.shading = shading
    }
}
