import SwiftUI
import simd

struct AxisGizmo: View {
    @ObservedObject var camera: ViewportCamera

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
        .allowsHitTesting(false)
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
        .background(RoundedRectangle(cornerRadius: 4).fill(document.soloPreview ? Theme.changed.opacity(0.75) : Color(white: 0.22)))
        .contentShape(Rectangle())
        .onTapGesture { document.setSolo(!document.soloPreview) }
        .help("Play only the selected emitter or particle, looping over the frames where it is alive. Edits show up on the next loop")
    }
}

struct ViewportPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var camera = ViewportCamera()
    @State private var framedKey = ""
    @State private var effectView: (yaw: Float, pitch: Float, distance: Float, target: SIMD3<Float>)?

    private var scene: ViewportScene {
        var scene = ViewportScene()
        scene.shading = app.viewportMode
        scene.effectShading = app.effectShading
        scene.showEmitters = app.showEmitters
        scene.showBindPoints = app.showBindPoints
        scene.filter = document.visibilityFilter
        scene.highlight = app.highlightSelection ? document.visibilityKey(forNodeID: document.selectionID) : nil
        let selected = document.selectionID ?? ""
        var key = "\(document.id)|\(document.revision)|\(app.viewportMode)|"
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
            HeaderButton(symbol: "sparkle.magnifyingglass", active: app.highlightSelection,
                         help: "Outline the selected emitter or particle in the playing effect") { app.highlightSelection.toggle() }
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
                        .onTapGesture {
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
                    HeaderButton(symbol: "dot.radiowaves.left.and.right", active: app.showEmitters, help: "Show emitter axes and shape points") {
                        app.showEmitters.toggle()
                    }
                    HeaderButton(symbol: "figure.stand", active: app.showBindPoints, help: "Show the reference figure and bind points") {
                        app.showBindPoints.toggle()
                    }
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
                    Text("User Perspective").font(.system(size: 11, weight: .medium))
                    Text(document.selectedNode.map { "\(document.title) | \($0.title)" } ?? document.title).font(Theme.small)
                }
                .foregroundStyle(Color.white.opacity(0.8))
                .shadow(color: .black, radius: 1)
                .padding(10)
                .allowsHitTesting(false)
                AxisGizmo(camera: camera).frame(maxWidth: .infinity, alignment: .topTrailing).padding(8)
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
