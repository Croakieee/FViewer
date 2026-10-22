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
            readout("time", String(format: "%.2f s · frame %d", clock.time / 30, Int(safe: clock.time.rounded())))
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
        let look = PreviewSettings.look
        let changed = look != PreviewLook()
        HStack(spacing: 4) {
            Image(systemName: "sparkles.rectangle.stack").font(.system(size: 10))
            Text(changed ? "Preview · Look" : "Preview").font(Theme.font)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(shown || changed ? Theme.accent : Theme.gray(0.22)))
        .contentShape(Rectangle())
        .pressable { shown.toggle() }
        .help("Background and look of the preview. None of them is saved into the effect")
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Background").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
                FlowLayout(spacing: 4) {
                    ForEach(Array(AppModel.backgrounds.enumerated()), id: \.offset) { index, entry in
                        SegmentButton(title: entry.name, active: PreviewSettings.backgroundColor == nil && app.viewportBackground == index) {
                            app.viewportBackground = index
                            app.setPreviewColor(nil)
                        }
                    }
                }
                row("Color") {
                    let shade = AppModel.backgrounds[min(max(app.viewportBackground, 0), AppModel.backgrounds.count - 1)].value
                    let current = PreviewSettings.backgroundColor ?? SIMD3(shade, shade, shade)
                    ColorField(color: SIMD4(current.x, current.y, current.z, 1), alpha: false,
                               onLive: { app.setPreviewColor(SIMD3($0.x, $0.y, $0.z)) },
                               onCommit: { _, next in app.setPreviewColor(SIMD3(next.x, next.y, next.z)) })
                }
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                row("Light Power") {
                    NumberField(label: nil, value: Double(look.lightIntensity), step: 0.1, digits: 1, onLive: { v in app.setLook { $0.lightIntensity = Float(v) } },
                                onCommit: { _, next in app.setLook { $0.lightIntensity = Float(next) } })
                }
                .help("How bright the effect's Point and Directional Lights make the floor and the mannequins")
                CheckBox(isOn: look.toneMap, label: "Scene Tone Map") { on in app.setLook { $0.toneMap = on } }
                    .help("The floor and the mannequins go through the game's scene tone curve; particles never do")
                row("Exposure") {
                    NumberField(label: nil, value: Double(look.exposure), suffix: " EV", step: 0.05, digits: 2, onLive: { v in app.setLook { $0.exposure = Float(v) } },
                                onCommit: { _, next in app.setLook { $0.exposure = Float(next) } })
                }
                .opacity(look.toneMap ? 1 : 0.4)
                .allowsHitTesting(look.toneMap)
                SegmentButton(title: "Reset Look", active: false) { app.setLook { $0 = PreviewLook() } }
            }
            .padding(12)
            .frame(width: 290)
            .background(Theme.panel)
            .preferredColorScheme(Theme.scheme)
        }
    }
}

struct StageMenu: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var bridge: PlayerBridge
    @State private var shown = false

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 82, alignment: .trailing)
            content()
        }
    }

    private func number(_ value: Float, _ suffix: String, _ step: Double, _ set: @escaping (inout PreviewStage, Float) -> Void) -> some View {
        NumberField(label: nil, value: Double(value), suffix: suffix, step: step, digits: 1, onLive: { v in app.setStage { set(&$0, Float(v)) } },
                    onCommit: { _, next in app.setStage { set(&$0, Float(next)) } })
    }

    @ViewBuilder private func mover(_ title: String, _ path: WritableKeyPath<PreviewStage, StageMover>) -> some View {
        let m = PreviewSettings.stage[keyPath: path]
        Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Motion") {
            ChoiceField(choices: StageMover.Motion.allCases.map { FieldChoice(name: $0.title, value: $0.rawValue) }, value: m.motion.rawValue) { value in
                app.setStage { $0[keyPath: path].motion = StageMover.Motion(rawValue: value) ?? .still }
            }
        }
        Group {
            row("Distance") { number(m.amplitude, " m", 0.1) { $0[keyPath: path].amplitude = $1 } }
            row("Period") { number(m.period, " s", 0.1) { $0[keyPath: path].period = $1 } }
        }
        .opacity(m.motion == .still ? 0.4 : 1)
        .allowsHitTesting(m.motion != .still)
        CheckBox(isOn: m.jump, label: "Jump") { on in app.setStage { $0[keyPath: path].jump = on } }
        Group {
            row("Jump Height") { number(m.jumpHeight, " m", 0.1) { $0[keyPath: path].jumpHeight = $1 } }
            row("Jump Period") { number(m.jumpPeriod, " s", 0.1) { $0[keyPath: path].jumpPeriod = $1 } }
        }
        .opacity(m.jump ? 1 : 0.4)
        .allowsHitTesting(m.jump)
    }

    @ViewBuilder private var characterRows: some View {
        let character = PreviewSettings.character
        let models = PreviewSettings.models
        let active = PreviewSettings.activeModel
        Text("Caster").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Model") {
            ChoiceField(choices: [FieldChoice(name: "Mannequin", value: -1)] + models.enumerated().map { FieldChoice(name: $0.element.name, value: $0.offset) },
                        value: models.firstIndex { $0.name == character.model } ?? -1) { value in
                app.setCharacter { $0.model = models.indices.contains(value) ? models[value].name : "" }
            }
        }
        .help("The figure the effect binds to: the mannequin, or a character model (.glb of ffxiv_mdls) with its skeleton's bind points")
        row("Folder") {
            Text(PreviewSettings.modelsFolder?.path ?? "Not chosen").font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1).truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)
            SegmentButton(title: "Choose…", active: false) { app.chooseModelsFolder() }
        }
        .help("Folder with the .glb models: _glb, _models or monster folders inside it are searched, and the skeleton bind points (.eid) next to it in chara/")
        if active != nil {
            row("Pose") {
                ChoiceField(choices: [FieldChoice(name: "Rest Pose", value: -1)] + bridge.characterClips.enumerated().map { FieldChoice(name: "\($0.element.name) · \($0.element.frames) f", value: $0.offset) },
                            value: bridge.characterClips.firstIndex { $0.name == character.pose } ?? -1) { value in
                    app.setCharacter { $0.pose = bridge.characterClips.indices.contains(value) ? bridge.characterClips[value].name : "" }
                }
            }
            row("Pose Frame") {
                NumberField(label: nil, value: Double(character.poseFrame), suffix: " f", step: 1, digits: 0, onLive: { v in app.setCharacter { $0.poseFrame = Float(v) } },
                            onCommit: { _, next in app.setCharacter { $0.poseFrame = Float(next) } })
            }
            .opacity(character.pose.isEmpty || character.posePlay ? 0.4 : 1)
            .allowsHitTesting(!character.pose.isEmpty && !character.posePlay)
            CheckBox(isOn: character.posePlay, label: "Play the Pose on the Effect's Clock") { on in app.setCharacter { $0.posePlay = on } }
                .opacity(character.pose.isEmpty ? 0.4 : 1)
                .allowsHitTesting(!character.pose.isEmpty)
        }
        if !bridge.characterStatus.isEmpty {
            Text(bridge.characterStatus).font(Theme.small).foregroundStyle(Theme.dim).fixedSize(horizontal: false, vertical: true)
        }
    }

    var body: some View {
        let stage = PreviewSettings.stage
        let moving = stage.caster.motion != .still || stage.target.motion != .still || stage.caster.jump || stage.target.jump
        HStack(spacing: 4) {
            Image(systemName: "figure.stand").font(.system(size: 10))
            Text(moving ? "Stage · Moving" : "Stage").font(Theme.font)
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 7)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(shown || moving ? Theme.accent : Theme.gray(0.22)))
        .contentShape(Rectangle())
        .pressable { shown.toggle() }
        .help("Caster and target mannequins the effect binds to: where the target stands and how both move on the effect's clock")
        .popover(isPresented: $shown, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                characterRows
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                Text("Target").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
                CheckBox(isOn: stage.showTarget, label: "Show Target") { on in app.setStage { $0.showTarget = on } }
                row("Distance") { number(stage.distance, " m", 0.1) { $0.distance = $1 } }
                row("Side") { number(stage.side, " m", 0.1) { $0.side = $1 } }
                CheckBox(isOn: stage.faceEachOther, label: "Face Each Other") { on in app.setStage { $0.faceEachOther = on } }
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                mover("Caster Motion", \.caster)
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                mover("Target Motion", \.target)
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                SegmentButton(title: "Reset Stage", active: false) { app.setStage { $0 = PreviewStage() } }
            }
            .padding(12)
            .frame(width: 280)
            .background(Theme.panel)
            .preferredColorScheme(Theme.scheme)
        }
    }
}

struct GizmoMenu: View {
    @EnvironmentObject var app: AppModel
    @State private var shown = false

    private var states: [Bool] { [app.showEmitters, app.showBindPoints, app.showFloor, app.showRelief] }

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
                CheckBox(isOn: app.showEmitters, label: "Emitter markers") { app.showEmitters = $0 }
                CheckBox(isOn: app.showBindPoints, label: "Mannequin and bind points") { app.showBindPoints = $0 }
                CheckBox(isOn: app.showFloor, label: "Floor and grid") { app.showFloor = $0 }
                CheckBox(isOn: app.showRelief, label: "Uneven ground: steps, ramp, wall") { app.showRelief = $0 }
                    .help("Shows how projected decals lie on steps, a slope and a wall ahead of the caster")
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
    @State private var bridge = PlayerBridge()
    @State private var framedKey = ""

    private var scene: ViewportScene {
        var scene = ViewportScene()
        scene.shading = app.viewportMode
        let selected = document.selectionID ?? ""
        var key = "\(document.id)|\(document.previewRevision)|\(app.viewportMode)|"
        for entry in app.meshes(for: document).filter({ selected.hasPrefix($0.id) }) {
            scene.meshes.append((entry.mesh, true))
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

    private var playerKey: Int {
        var hasher = Hasher()
        hasher.combine(document.id)
        hasher.combine(document.previewRevision)
        hasher.combine(document.showOriginal)
        hasher.combine(document.visibilityFilter.hidden)
        hasher.combine(document.visibilityFilter.isolated)
        hasher.combine(app.viewportBackground)
        hasher.combine(app.effectShading)
        hasher.combine(app.showEmitters)
        hasher.combine(app.showBindPoints)
        hasher.combine(app.showFloor)
        hasher.combine(app.showRelief)
        hasher.combine(app.libraryToken)
        hasher.combine(PreviewSettings.token)
        return hasher.finalize()
    }

    private var playerShadingButtons: some View {
        HStack(spacing: 1) {
            HeaderButton(symbol: "circle.fill", active: app.effectShading == 0, help: "Textured") { app.effectShading = 0 }
            HeaderButton(symbol: "circle.grid.cross", active: app.effectShading != 0, help: "Textured with the particles' wireframe drawn over") { app.effectShading = 2 }
        }
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
        let mesh = scene
        let showEffect = mesh.isEmpty
        return VStack(spacing: 0) {
            EditorHeader(symbol: "view.3d", title: "3D Viewport") {
                Menu {
                    if showEffect {
                        Button("Front") { bridge.look(from: SIMD3(0, 0, 1)) }
                        Button("Right") { bridge.look(from: SIMD3(1, 0, 0)) }
                        Button("Top") { bridge.look(from: SIMD3(0, 1, 0.001)) }
                        Button("Reset View") { bridge.resetCamera() }
                    } else {
                        Button("Front") { camera.setView(yaw: 0, pitch: 0) }
                        Button("Right") { camera.setView(yaw: .pi / 2, pitch: 0) }
                        Button("Top") { camera.setView(yaw: 0, pitch: 1.55) }
                        Button("Frame All") { frameAll() }
                    }
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
                if showEffect {
                    HelpBadge(text: "Drag: orbit\n⇧ or ⌘ Drag, or right drag: pan\nScroll: zoom\n1 / 3 / 7: front, right, top\n. : reset view")
                    PreviewMenu()
                    StageMenu(bridge: bridge)
                    GizmoMenu()
                    isolateButton
                    playerShadingButtons
                } else {
                    HelpBadge(text: "Drag: orbit\n⇧ Drag or right drag: pan\nScroll: orbit on a trackpad, zoom with a mouse wheel\nPinch or ⌘ Scroll: zoom\n1 / 3 / 7: front, right, top\n. : frame all")
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
                PlayerViewport(bridge: bridge, document: document, app: app, revision: playerKey)
                if showEffect {
                    PlayerStatus(bridge: bridge)
                } else {
                    MeshViewport(camera: camera, scene: mesh, background: app.viewportBackground)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if !showEffect { ProjectionLabel(camera: camera) }
                    Text(document.selectedNode.map { "\(document.title) | \($0.title)" } ?? document.title).font(Theme.small)
                }
                .foregroundStyle(Color.white.opacity(0.8))
                .shadow(color: .black, radius: 1)
                .padding(10)
                .allowsHitTesting(false)
                if !showEffect { AxisGizmo(camera: camera).frame(maxWidth: .infinity, alignment: .topTrailing).padding(8) }
            }
            if showEffect {
                PlayerFooter(bridge: bridge, clock: document.clock)
            } else {
                ViewportFooter(clock: document.clock, camera: camera) {
                    camera.setView(yaw: 0.7, pitch: 0.45)
                    frameAll()
                }
            }
        }
        .onChange(of: document.selectionID) { _, _ in
            let key = scene.meshes.count.description + (scene.texture == nil ? "" : "t") + (document.selectionID ?? "")
            if !scene.isEmpty, key != framedKey {
                framedKey = key
                frameAll()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .viewportFrameAll)) { _ in
            if scene.isEmpty { bridge.resetCamera() } else { frameAll() }
        }
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
