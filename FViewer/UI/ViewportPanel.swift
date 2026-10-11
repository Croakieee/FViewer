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

struct ViewportPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @StateObject private var camera = ViewportCamera()
    @State private var framedKey = ""

    private var scene: ViewportScene {
        var scene = ViewportScene()
        scene.shading = app.viewportMode
        let selected = document.selectionID ?? ""
        var key = "\(document.id)|\(document.revision)|\(app.viewportMode)|"
        let meshes = app.meshes(for: document)
        let focused = meshes.filter { selected.hasPrefix($0.id) }
        for entry in focused.isEmpty ? meshes : focused {
            scene.meshes.append((entry.mesh, !focused.isEmpty))
            key += entry.id + ";"
        }
        if let slot = document.textureSlots.first(where: { $0.nodeID == selected }) {
            scene.texture = app.image(for: slot.path)
            scene.meshes = []
            key += "tex:" + slot.path
        }
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

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "view.3d", title: "3D Viewport") {
                Spacer()
                HeaderButton(symbol: "scope", help: "Показать всё (.)") { frameAll() }
                HStack(spacing: 1) {
                    HeaderButton(symbol: "square.grid.3x3", active: app.viewportMode == 0, help: "Каркас") { app.viewportMode = 0 }
                    HeaderButton(symbol: "circle.fill", active: app.viewportMode == 1, help: "Сплошной") { app.viewportMode = 1 }
                    HeaderButton(symbol: "circle.lefthalf.filled", active: app.viewportMode == 2, help: "Цвета вершин") { app.viewportMode = 2 }
                }
            }
            ZStack(alignment: .topLeading) {
                MetalViewport(camera: camera, scene: scene)
                VStack(alignment: .leading, spacing: 2) {
                    Text("User Perspective").font(.system(size: 11, weight: .medium))
                    Text(document.selectedNode.map { "\(document.title) | \($0.title)" } ?? document.title).font(Theme.small)
                    if scene.meshes.isEmpty && scene.texture == nil {
                        Text("Проигрывание эффекта ещё не реализовано: показываются модели и текстуры").font(Theme.small).padding(.top, 4)
                    }
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
            let key = scene.meshes.count.description + (scene.texture == nil ? "" : "t") + (document.selectionID ?? "")
            if key != framedKey, scene.texture != nil || document.selectionID?.contains("Modl") == true {
                framedKey = key
                frameAll()
            }
        }
        .onChange(of: document.id) { _, _ in frameAll() }
        .onReceive(NotificationCenter.default.publisher(for: .viewportFrameAll)) { _ in frameAll() }
    }
}
