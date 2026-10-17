import SwiftUI
import simd

struct AxisGizmo: View {
    @ObservedObject var camera: ViewportCamera
    @State private var dragged: CGPoint?

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2 - 9
            let forward = simd_normalize(camera.target - camera.eye)
            let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
            let up = simd_cross(right, forward)
            let axes: [(SIMD3<Float>, Color, String)] = [
                (SIMD3(1, 0, 0), Color(red: 0.93, green: 0.25, blue: 0.30), "X"),
                (SIMD3(0, 1, 0), Color(red: 0.55, green: 0.80, blue: 0.20), "Y"),
                (SIMD3(0, 0, 1), Color(red: 0.25, green: 0.50, blue: 0.95), "Z"),
            ]
            var ends: [(CGPoint, Float, Color, String, Bool)] = []
            for axis in axes {
                for sign in [Float(1), Float(-1)] {
                    let v = axis.0 * sign
                    let point = CGPoint(x: center.x + CGFloat(simd_dot(v, right)) * radius, y: center.y - CGFloat(simd_dot(v, up)) * radius)
                    ends.append((point, -simd_dot(v, forward), axis.1, axis.2, sign > 0))
                }
            }
            for end in ends.sorted(by: { $0.1 < $1.1 }) {
                if end.4 {
                    var line = Path()
                    line.move(to: center)
                    line.addLine(to: end.0)
                    context.stroke(line, with: .color(end.2), lineWidth: 2)
                }
                let dot = CGRect(x: end.0.x - 7, y: end.0.y - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: dot), with: .color(end.4 ? end.2 : end.2.opacity(0.35)))
                if end.4 {
                    context.draw(Text(end.3).font(.system(size: 9, weight: .bold)).foregroundStyle(.black), at: end.0)
                }
            }
        }
        .frame(width: 76, height: 76)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { value in
                if hypot(value.translation.width, value.translation.height) > 3 {
                    let last = dragged ?? value.startLocation
                    camera.orbit(dx: Float(value.location.x - last.x) * 1.5, dy: Float(value.location.y - last.y) * 1.5)
                    dragged = value.location
                }
            }
            .onEnded { value in
                if dragged == nil { tap(value.location) }
                dragged = nil
            })
        .help("Click an axis to look along it, click the centre to switch between perspective and orthographic, drag to orbit")
    }

    private func tap(_ point: CGPoint) {
        let center = CGPoint(x: 38, y: 38)
        let radius: CGFloat = 38 - 9
        let forward = simd_normalize(camera.target - camera.eye)
        let right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, forward)
        let views: [(SIMD3<Float>, Float, Float)] = [
            (SIMD3(1, 0, 0), .pi / 2, 0), (SIMD3(-1, 0, 0), -.pi / 2, 0), (SIMD3(0, 1, 0), camera.yaw, 1.55), (SIMD3(0, -1, 0), camera.yaw, -1.55),
            (SIMD3(0, 0, 1), 0, 0), (SIMD3(0, 0, -1), .pi, 0),
        ]
        var best: (distance: CGFloat, depth: Float, yaw: Float, pitch: Float)?
        for view in views {
            let ball = CGPoint(x: center.x + CGFloat(simd_dot(view.0, right)) * radius, y: center.y - CGFloat(simd_dot(view.0, up)) * radius)
            let distance = hypot(ball.x - point.x, ball.y - point.y)
            let depth = -simd_dot(view.0, forward)
            let nearest = best?.depth ?? -2
            if (distance < 9) && (depth > nearest) { best = (distance, depth, view.1, view.2) }
        }
        if let best {
            camera.setView(yaw: best.yaw, pitch: best.pitch)
        } else if hypot(point.x - center.x, point.y - center.y) < 14 {
            camera.ortho.toggle()
        }
    }
}

struct SoloButton: View {
    @ObservedObject var document: EffectDocument

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle").font(.system(size: 11))
            Text("Solo").font(Theme.font)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(document.soloPreview ? Theme.changed.opacity(0.75) : Theme.gray(0.22)))
        .contentShape(Rectangle())
        .pressable { document.setSolo(!document.soloPreview) }
        .help("Play only the selected emitter or particle, looping over the frames where it is alive. Edits show up on the next loop")
    }
}

struct ProjectionLabel: View {
    @ObservedObject var camera: ViewportCamera

    var body: some View {
        Text(camera.ortho ? "User Orthographic" : "User Perspective").font(.system(size: 11, weight: .medium))
    }
}

struct ViewportFooter: View {
    @ObservedObject var clock: PlaybackClock
    @ObservedObject var camera: ViewportCamera
    let reset: () -> Void

    private func readout(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(Theme.dim)
            Text(value).foregroundStyle(Theme.text)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            readout("effect", clock.status.isEmpty ? "—" : clock.status)
            readout("time", String(format: "%.2f s · frame %d", clock.time / 30, Int(safe: clock.time.rounded())))
            if clock.frameMilliseconds > 0 { readout("timing", String(format: "%.1f ms · %.0f fps", clock.frameMilliseconds, clock.framesPerSecond)) }
            Spacer(minLength: 4)
            HeaderButton(symbol: "arrow.counterclockwise", help: "Reset View: the default angle, framed on the whole effect") { reset() }
            CheckBox(isOn: camera.ortho, label: "ortho") { camera.ortho = $0 }.fixedSize()
            HStack(spacing: 4) {
                Text("FOV").foregroundStyle(Theme.dim)
                NumberField(label: nil, value: Double(camera.fov * 180 / .pi), suffix: "°", step: 0.5, digits: 0,
                            onLive: { camera.fov = Float(min(max($0, 8), 90)) * .pi / 180 },
                            onCommit: { _, next in camera.fov = Float(min(max(next, 8), 90)) * .pi / 180 })
                    .frame(width: 56)
            }
            .opacity(camera.ortho ? 0.4 : 1)
            .allowsHitTesting(!camera.ortho)
            CheckBox(isOn: clock.lockSeed, label: "lock seed") { clock.lockSeed = $0 }.fixedSize()
                .help("On: every replay uses the same random seed. Off: each restart and loop picks a new one, so replays vary")
        }
        .font(.system(size: 10, design: .monospaced))
        .lineLimit(1)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Theme.header)
    }
}

struct PreviewMenu: View {
    @EnvironmentObject var app: AppModel
    @State private var shown = false

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 70, alignment: .trailing)
            content()
        }
    }

    var body: some View {
        let bloom = ViewportRenderer.bloom
        HStack(spacing: 4) {
            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 10))
            Text(bloom.on ? "Preview · Bloom" : "Preview").font(Theme.font)
            if ViewportRenderer.scene != PreviewScene() { Text("· Scene").font(Theme.font) }
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(shown || bloom.on || ViewportRenderer.scene != PreviewScene() ? Theme.accent : Theme.gray(0.22)))
        .contentShape(Rectangle())
        .pressable { shown.toggle() }
        .help("Preview background, bloom and the scene stand-ins. None of them is saved into the effect")
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Background").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
                FlowLayout(spacing: 4) {
                    ForEach(Array(AppModel.backgrounds.enumerated()), id: \.offset) { index, entry in
                        SegmentButton(title: entry.name, active: ViewportRenderer.backgroundColor == nil && app.viewportBackground == index) {
                            app.viewportBackground = index
                            app.setPreviewColor(nil)
                        }
                    }
                }
                row("Color") {
                    let shade = AppModel.backgrounds[min(max(app.viewportBackground, 0), AppModel.backgrounds.count - 1)].value
                    let current = ViewportRenderer.backgroundColor ?? SIMD3(shade, shade, shade)
                    ColorField(color: SIMD4(current.x, current.y, current.z, 1), alpha: false,
                               onLive: { app.setPreviewColor(SIMD3($0.x, $0.y, $0.z)) },
                               onCommit: { _, next in app.setPreviewColor(SIMD3(next.x, next.y, next.z)) })
                }
                row("Image") {
                    SegmentButton(title: ViewportRenderer.backgroundImage == nil ? "Choose…" : "Replace…", active: false) { app.choosePreviewImage() }
                    if ViewportRenderer.backgroundImage != nil { SegmentButton(title: "Remove", active: false) { app.clearPreviewImage() } }
                    Spacer(minLength: 0)
                }
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                CheckBox(isOn: bloom.on, label: "Bloom") { app.setBloom(on: $0) }
                row("Threshold") {
                    NumberField(label: nil, value: Double(bloom.threshold), step: 0.01, digits: 2, onLive: { app.setBloom(threshold: Float($0)) },
                                onCommit: { _, next in app.setBloom(threshold: Float(next)) })
                }
                row("Intensity") {
                    NumberField(label: nil, value: Double(bloom.intensity), step: 0.01, digits: 2, onLive: { app.setBloom(intensity: Float($0)) },
                                onCommit: { _, next in app.setBloom(intensity: Float(next)) })
                }
                row("Scatter") {
                    NumberField(label: nil, value: Double(bloom.radius * 100), step: 0.05, digits: 1, onLive: { app.setBloom(radius: Float($0) / 100) },
                                onCommit: { _, next in app.setBloom(radius: Float(next) / 100) })
                }
                Text("Bloom is a preview aid: it shows how bright parts would glow, the game applies its own.").font(Theme.small).foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                let scene = ViewportRenderer.scene
                Text("Scene").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
                row("Brightness") {
                    NumberField(label: nil, value: Double(scene.brightness), step: 0.01, digits: 2, onLive: { v in app.setScene { $0.brightness = Float(v) } },
                                onCommit: { _, next in app.setScene { $0.brightness = Float(next) } })
                }
                row("Environment") {
                    ColorField(color: SIMD4(Double(scene.environment.x), Double(scene.environment.y), Double(scene.environment.z), 1), alpha: false,
                               onLive: { c in app.setScene { $0.environment = Vec3(Float(c.x), Float(c.y), Float(c.z)) } },
                               onCommit: { _, c in app.setScene { $0.environment = Vec3(Float(c.x), Float(c.y), Float(c.z)) } })
                }
                row("Sunlight") {
                    ColorField(color: SIMD4(Double(scene.sunlight.x), Double(scene.sunlight.y), Double(scene.sunlight.z), 1), alpha: false,
                               onLive: { c in app.setScene { $0.sunlight = Vec3(Float(c.x), Float(c.y), Float(c.z)) } },
                               onCommit: { _, c in app.setScene { $0.sunlight = Vec3(Float(c.x), Float(c.y), Float(c.z)) } })
                }
                CheckBox(isOn: scene.fog, label: "Fog") { on in app.setScene { $0.fog = on } }
                row("Fog Color") {
                    ColorField(color: SIMD4(Double(scene.fogColor.x), Double(scene.fogColor.y), Double(scene.fogColor.z), 1), alpha: false,
                               onLive: { c in app.setScene { $0.fogColor = Vec3(Float(c.x), Float(c.y), Float(c.z)) } },
                               onCommit: { _, c in app.setScene { $0.fogColor = Vec3(Float(c.x), Float(c.y), Float(c.z)) } })
                }
                .opacity(scene.fog ? 1 : 0.4)
                .allowsHitTesting(scene.fog)
                row("Fog Start") {
                    NumberField(label: nil, value: Double(scene.fogStart), suffix: " m", step: 0.5, digits: 1, onLive: { v in app.setScene { $0.fogStart = Float(v) } },
                                onCommit: { _, next in app.setScene { $0.fogStart = Float(next) } })
                }
                .opacity(scene.fog ? 1 : 0.4)
                .allowsHitTesting(scene.fog)
                row("Fog End") {
                    NumberField(label: nil, value: Double(scene.fogEnd), suffix: " m", step: 0.5, digits: 1, onLive: { v in app.setScene { $0.fogEnd = Float(v) } },
                                onCommit: { _, next in app.setScene { $0.fogEnd = Float(next) } })
                }
                .opacity(scene.fog ? 1 : 0.4)
                .allowsHitTesting(scene.fog)
                Text("Stand-ins for the zone: Brightness drives Apply Tone Map, Environment and Sunlight the Apply Rate values, Fog the Apply Fog and Global Fog settings. The game takes them from the area the effect plays in.")
                    .font(Theme.small).foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(width: 290)
            .background(Theme.panel)
            .preferredColorScheme(Theme.scheme)
        }
    }
}

struct GizmoMenu: View {
    @EnvironmentObject var app: AppModel
    @State private var shown = false

    private var states: [Bool] { [app.showGizmo, app.highlightSelection, app.showEmitters, app.showBindPoints, app.showFloor] }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "eye").font(.system(size: 10))
            Text("Gizmos").font(Theme.font)
            Text("\(states.filter { $0 }.count)/\(states.count)").font(Theme.small).foregroundStyle(Theme.dim)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(shown ? Theme.accent : Theme.gray(0.22)))
        .contentShape(Rectangle())
        .pressable { shown.toggle() }
        .help("Choose which helpers are drawn in the viewport")
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                CheckBox(isOn: app.showGizmo, label: "Move, rotate, scale and shape handles") { app.showGizmo = $0 }
                CheckBox(isOn: app.highlightSelection, label: "Wire of the selected emitter or particle") { app.highlightSelection = $0 }
                CheckBox(isOn: app.showEmitters, label: "Emitter axes and shape points") { app.showEmitters = $0 }
                CheckBox(isOn: app.showBindPoints, label: "Reference figure and bind points") { app.showBindPoints = $0 }
                CheckBox(isOn: app.showFloor, label: "Floor") { app.showFloor = $0 }
            }
            .padding(12)
            .background(Theme.panel)
            .preferredColorScheme(Theme.scheme)
        }
    }
}

struct ViewportPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @StateObject private var camera = ViewportCamera()
    @State private var framedKey = ""
    @State private var effectView: (yaw: Float, pitch: Float, distance: Float, target: SIMD3<Float>)?

    private var scene: ViewportScene {
        var scene = ViewportScene()
        scene.shading = app.viewportMode
        scene.effectShading = app.effectShading
        scene.showEmitters = app.showEmitters
        scene.showBindPoints = app.showBindPoints
        scene.showFloor = app.showFloor
        scene.showGizmo = app.showGizmo
        scene.filter = document.visibilityFilter
        scene.highlight = app.highlightSelection ? document.visibilityKey(forNodeID: document.selectionID) : nil
        let selected = document.selectionID ?? ""
        var key = "\(document.id)|\(document.previewRevision)|\(app.viewportMode)|"
        let meshes = app.meshes(for: document)
        for entry in meshes.filter({ selected.hasPrefix($0.id) }) {
            scene.meshes.append((entry.mesh, true))
            key += entry.id + ";"
        }
        if let slot = document.textureSlots.first(where: { $0.nodeID == selected }) {
            scene.texture = app.image(for: slot.path)
            scene.meshes = []
            key += "tex:" + slot.path
        }
        scene.showEffect = scene.meshes.isEmpty && scene.texture == nil
        scene.revision = key.hashValue
        return scene
    }

    private func frameAll() {
        var lo: SIMD3<Float>?
        var hi: SIMD3<Float>?
        for entry in scene.meshes {
            guard let bounds = entry.mesh.bounds else { continue }
            lo = lo.map { simd_min($0, bounds.min) } ?? bounds.min
            hi = hi.map { simd_max($0, bounds.max) } ?? bounds.max
        }
        if scene.texture != nil {
            lo = SIMD3(-1, 0.2, 0)
            hi = SIMD3(1, 2.2, 0)
        }
        if let bounds = ViewportRenderer.main?.effectBounds() {
            lo = lo.map { simd_min($0, bounds.min) } ?? bounds.min
            hi = hi.map { simd_max($0, bounds.max) } ?? bounds.max
        }
        if let lo, let hi { camera.frame((lo, hi)) } else { camera.frame(nil) }
    }

    private var shadingButtons: some View {
        HStack(spacing: 1) {
            HeaderButton(symbol: "circle.fill", active: app.effectShading == 0, help: "Textured") { app.effectShading = 0 }
            HeaderButton(symbol: "square.grid.3x3", active: app.effectShading == 1, help: "Wireframe only") { app.effectShading = 1 }
            HeaderButton(symbol: "circle.grid.cross", active: app.effectShading == 2, help: "Textured with wireframe overlay") { app.effectShading = 2 }
        }
    }

    private var isolateButton: some View {
        HStack(spacing: 1) {
            HeaderButton(symbol: "scope", active: document.isolateSelection, help: "Isolate the selected timeline, emitter or particle") {
                document.isolateSelection.toggle()
            }
            SoloButton(document: document)
        }
    }

    private var visibilityNote: some View {
        let filter = document.visibilityFilter
        return Group {
            if !filter.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash").font(.system(size: 9))
                    Text(filter.isolated != nil ? "Isolated" : "\(filter.hidden.count) hidden").font(Theme.small)
                    Text("Show All").font(Theme.small).underline()
                        .pressable {
                            document.hidden = []
                            document.isolateSelection = false
                        }
                }
                .foregroundStyle(Color(red: 1, green: 0.75, blue: 0.3))
            }
        }
    }

    var body: some View {
        if document.format == .pixi {
            VStack(spacing: 0) {
                EditorHeader(symbol: "view.2d", title: "2D Viewport") {
                    visibilityNote
                    Spacer()
                    HelpBadge(text: "Drag: pan\nPinch or ⌘ Scroll: zoom\nDouble-click: reset")
                    HeaderButton(symbol: "circle.lefthalf.filled", help: "Cycle the background") {
                        app.viewportBackground = (app.viewportBackground + 1) % AppModel.backgrounds.count
                    }
                    if document.format == .avfx, document.isDirty || document.showOriginal {
                        HeaderButton(symbol: "clock.arrow.circlepath", active: document.showOriginal,
                                     help: "Play the effect as it was opened, to compare with your changes") {
                            document.showOriginal.toggle()
                        }
                    }
                    PlaneButton(document: document, clock: document.clock)
                    isolateButton
                    shadingButtons
                }
                Effect2DViewport(document: document, app: app, shading: app.effectShading, background: app.viewportBackground)
            }
        } else {
            viewport3D
        }
    }

    private var viewport3D: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "view.3d", title: "3D Viewport") {
                Menu {
                    Button("Front") { camera.setView(yaw: 0, pitch: 0) }
                    Button("Right") { camera.setView(yaw: .pi / 2, pitch: 0) }
                    Button("Top") { camera.setView(yaw: 0, pitch: 1.55) }
                    Button("Frame All") { frameAll() }
                    Divider()
                    ForEach(Array(AppModel.backgrounds.enumerated()), id: \.offset) { index, entry in
                        Button((app.viewportBackground == index ? "✓ " : "") + "Background: " + entry.name) { app.viewportBackground = index }
                    }
                } label: {
                    Text("View").font(Theme.font).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 20)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                visibilityNote
                Spacer()
                if scene.showEffect {
                    HelpBadge(text: "Drag: orbit\n⇧ Drag or right drag: pan\nScroll: orbit on a trackpad, zoom with a mouse wheel\nPinch or ⌘ Scroll: zoom\n1 / 3 / 7: front, right, top\n. : frame all")
                    PreviewMenu()
                    GizmoMenu()
                    isolateButton
                    shadingButtons
                } else {
                    HStack(spacing: 1) {
                        HeaderButton(symbol: "square.grid.3x3", active: app.viewportMode == 0, help: "Wireframe") { app.viewportMode = 0 }
                        HeaderButton(symbol: "circle.fill", active: app.viewportMode == 1, help: "Solid") { app.viewportMode = 1 }
                        HeaderButton(symbol: "circle.lefthalf.filled", active: app.viewportMode == 2, help: "Vertex colors") { app.viewportMode = 2 }
                        HeaderButton(symbol: "arrow.up.right", active: app.viewportMode == 3, help: "Normals") { app.viewportMode = 3 }
                        HeaderButton(symbol: "square.grid.2x2", active: app.viewportMode == 4, help: "UV 1") { app.viewportMode = 4 }
                    }
                }
            }
            ZStack(alignment: .topLeading) {
                MetalViewport(camera: camera, scene: scene, document: document, app: app, background: app.viewportBackground)
                VStack(alignment: .leading, spacing: 2) {
                    ProjectionLabel(camera: camera)
                    Text(document.selectedNode.map { "\(document.title) | \($0.title)" } ?? document.title).font(Theme.small)
                }
                .foregroundStyle(Color.white.opacity(0.8))
                .shadow(color: .black, radius: 1)
                .padding(10)
                .allowsHitTesting(false)
                AxisGizmo(camera: camera).frame(maxWidth: .infinity, alignment: .topTrailing).padding(8)
            }
            ViewportFooter(clock: document.clock, camera: camera) {
                camera.setView(yaw: 0.7, pitch: 0.45)
                frameAll()
            }
        }
        .onAppear { frameAll() }
        .onChange(of: document.selectionID) { _, _ in
            let preview = !scene.showEffect
            if preview, effectView == nil { effectView = (camera.yaw, camera.pitch, camera.distance, camera.target) }
            let key = scene.meshes.count.description + (scene.texture == nil ? "" : "t") + (document.selectionID ?? "")
            if key != framedKey, scene.texture != nil || document.selectionID?.contains("Modl") == true {
                framedKey = key
                frameAll()
            }
            if !preview, let saved = effectView {
                camera.yaw = saved.yaw
                camera.pitch = saved.pitch
                camera.distance = saved.distance
                camera.target = saved.target
                effectView = nil
                framedKey = ""
            }
        }
        .onChange(of: document.id) { _, _ in frameAll() }
        .onReceive(NotificationCenter.default.publisher(for: .viewportFrameAll)) { _ in frameAll() }
    }
}

struct PlaneButton: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    @State private var shown = false

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 96, alignment: .trailing)
            content().frame(width: 110)
        }
    }

    var body: some View {
        HeaderButton(symbol: "perspective", active: shown || document.plane != .zero || !document.paramOverrides.isEmpty,
                     help: "Effect plane, seed and parameters of the preview") { shown.toggle() }
            .popover(isPresented: $shown, arrowEdge: .bottom) {
                VStack(spacing: 4) {
                    row("Tilt X") {
                        NumberField(label: nil, value: document.plane.x, suffix: "°", step: 1, onLive: { document.plane.x = $0 }, onCommit: { _, v in document.plane.x = v })
                    }
                    row("Tilt Y") {
                        NumberField(label: nil, value: document.plane.y, suffix: "°", step: 1, onLive: { document.plane.y = $0 }, onCommit: { _, v in document.plane.y = v })
                    }
                    row("Perspective") {
                        NumberField(label: nil, value: document.plane.z, step: 0.01, onLive: { document.plane.z = max(0, $0) },
                                    onCommit: { _, v in document.plane.z = max(0, v) })
                    }
                    row("Seed") {
                        NumberField(label: nil, value: Double(clock.seed), isInteger: true, onLive: { _ in },
                                    onCommit: { _, v in clock.seed = Int(safe: v, in: 1...999_999) })
                    }
                    ForEach(document.effectParams, id: \.name) { param in
                        row(param.name) {
                            NumberField(label: nil, value: document.paramOverrides[param.name] ?? param.value, step: 0.05,
                                        onLive: { document.paramOverrides[param.name] = $0 }, onCommit: { _, v in document.paramOverrides[param.name] = v })
                        }
                    }
                    row("") {
                        SegmentButton(title: "Reset", active: false) {
                            document.plane = .zero
                            document.paramOverrides = [:]
                            document.liveChanged()
                        }
                    }
                }
                .padding(10)
                .background(Theme.panel)
                .preferredColorScheme(Theme.scheme)
            }
    }
}
