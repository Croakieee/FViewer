import Metal
import SwiftUI
import VfxCore
import VfxMetal

enum MaterialLook {
    static let nodeWidth: CGFloat = 176
    static let header: CGFloat = 24
    static let row: CGFloat = 20

    static func tint(_ category: String) -> Color {
        switch category {
        case "Particle": return Color(red: 0.30, green: 0.62, blue: 0.45)
        case "Constants": return Color(red: 0.72, green: 0.60, blue: 0.25)
        case "Coordinates": return Color(red: 0.70, green: 0.36, blue: 0.36)
        case "Texture": return Color(red: 0.30, green: 0.50, blue: 0.80)
        case "Math": return Color(red: 0.36, green: 0.58, blue: 0.62)
        case "Lighting": return Color(red: 0.80, green: 0.70, blue: 0.30)
        case "Utility": return Color(red: 0.55, green: 0.42, blue: 0.75)
        default: return Color(red: 0.85, green: 0.52, blue: 0.25)
        }
    }

    static func pin(_ name: String) -> Color {
        switch name {
        case "uv": return Color(red: 0.45, green: 0.75, blue: 0.95)
        case "rgb", "color", "emissive": return Color(red: 0.95, green: 0.55, blue: 0.75)
        case "normal": return Color(red: 0.55, green: 0.62, blue: 0.98)
        default: return Color(white: 0.74)
        }
    }

    static func shownParams(_ kind: MaterialNodeKind) -> [(name: String, value: Double)] {
        switch kind.type {
        case "color": return []
        case "gradient": return kind.params.filter { $0.name == "t" || $0.name == "mid" }
        default: return kind.params
        }
    }

    static func extra(_ kind: MaterialNodeKind) -> CGFloat {
        switch kind.type {
        case "texture": return row + 58
        case "color": return 26
        case "gradient": return 18 + 3 * 24
        case "subgraph": return row
        default: return 0
        }
    }

    static func height(_ kind: MaterialNodeKind) -> CGFloat {
        header + CGFloat(max(kind.inputs.count, kind.outputs.count) + shownParams(kind).count) * row + extra(kind) + 6
    }
}

struct MaterialEditorView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var pan = CGSize(width: 30, height: 20)
    @State private var zoom: CGFloat = 1
    @State private var selection: Set<String> = []
    @State private var moving: (origins: [String: CGPoint], before: Any)?
    @State private var wire: (from: String, out: String, end: CGPoint)?
    @State private var box: (start: CGPoint, end: CGPoint)?
    @State private var search = ""
    @State private var quickAdd: CGPoint?
    @State private var quickText = ""
    @State private var previewPin: String?
    @State private var canvasSize = CGSize(width: 600, height: 300)
    @State private var framed = ""
    @State private var pinned = ""
    @State private var lastTap: (time: Date, point: CGPoint) = (.distantPast, .zero)
    @State private var open: Set<String> = Set(MaterialGraph.categories)
    @FocusState private var focused: Bool

    private func selectedAvfxParticle() -> String? {
        guard document.format == .avfx, let selected = document.selectionID, selected.hasPrefix("avfx/Ptcl/") else { return nil }
        let id = selected.split(separator: "/").prefix(3).joined(separator: "/")
        return document.node(id) != nil ? id : nil
    }

    private var avfxParticle: String? {
        if let live = selectedAvfxParticle() { return live }
        return pinned.isEmpty || document.node(pinned) == nil ? nil : pinned
    }

    private func rememberParticle() {
        if let live = selectedAvfxParticle(), live != pinned { pinned = live }
    }

    private func origin(_ node: MaterialNode) -> CGPoint { CGPoint(x: CGFloat(node.x ?? 0) * zoom + pan.width, y: CGFloat(node.y ?? 0) * zoom + pan.height) }

    private func world(_ point: CGPoint) -> CGPoint { CGPoint(x: (point.x - pan.width) / zoom, y: (point.y - pan.height) / zoom) }

    private func pinOffset(_ index: Int) -> CGFloat { (MaterialLook.header + CGFloat(index) * MaterialLook.row + MaterialLook.row / 2) * zoom }

    private func inputPin(_ node: MaterialNode, _ index: Int) -> CGPoint {
        let o = origin(node)
        return CGPoint(x: o.x, y: o.y + pinOffset(index))
    }

    private func outputPin(_ node: MaterialNode, _ index: Int) -> CGPoint {
        let o = origin(node)
        return CGPoint(x: o.x + MaterialLook.nodeWidth * zoom, y: o.y + pinOffset(index))
    }

    private func curve(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        let reach = max(36 * zoom, abs(b.x - a.x) * 0.5)
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x + reach, y: a.y), control2: CGPoint(x: b.x - reach, y: b.y))
        return path
    }

    private func nearestInput(_ point: CGPoint, _ graph: MaterialGraph) -> (node: String, input: String)? {
        var best: (node: String, input: String, distance: CGFloat)?
        for node in graph.nodes {
            guard let kind = MaterialGraph.kind(of: node.type) else { continue }
            let frame = CGRect(origin: origin(node), size: CGSize(width: MaterialLook.nodeWidth * zoom, height: MaterialLook.height(kind) * zoom))
            for (index, name) in kind.inputs.enumerated() {
                let pin = inputPin(node, index)
                var d = hypot(pin.x - point.x, pin.y - point.y)
                if frame.contains(point), abs(pin.y - point.y) < MaterialLook.row * zoom / 2 { d = min(d, 4) }
                if d < 18 * max(zoom, 0.7), d < (best?.distance ?? .infinity) { best = (node.id, name, d) }
            }
        }
        return best.map { ($0.node, $0.input) }
    }

    private func frameAll(_ graph: MaterialGraph) {
        guard !graph.nodes.isEmpty else { return }
        var low = CGPoint(x: CGFloat.infinity, y: CGFloat.infinity), high = CGPoint(x: -CGFloat.infinity, y: -CGFloat.infinity)
        for node in graph.nodes {
            guard let kind = MaterialGraph.kind(of: node.type) else { continue }
            low = CGPoint(x: min(low.x, CGFloat(node.x ?? 0)), y: min(low.y, CGFloat(node.y ?? 0)))
            high = CGPoint(x: max(high.x, CGFloat(node.x ?? 0) + MaterialLook.nodeWidth), y: max(high.y, CGFloat(node.y ?? 0) + MaterialLook.height(kind)))
        }
        let fit = min((canvasSize.width - 60) / max(high.x - low.x, 1), (canvasSize.height - 50) / max(high.y - low.y, 1))
        zoom = min(max(fit, 0.35), 1.2)
        pan = CGSize(width: (canvasSize.width - (high.x - low.x) * zoom) / 2 - low.x * zoom, height: (canvasSize.height - (high.y - low.y) * zoom) / 2 - low.y * zoom)
    }

    private func zoomBy(_ factor: CGFloat, at point: CGPoint) {
        let next = min(max(zoom * factor, 0.35), 2)
        let anchor = world(point)
        zoom = next
        pan = CGSize(width: point.x - anchor.x * next, height: point.y - anchor.y * next)
    }

    private func setParams(_ particle: String, _ node: MaterialNode, _ values: [String: Double], title: String) {
        document.editMaterial(title, in: particle) { graph in
            guard let index = graph.nodes.firstIndex(where: { $0.id == node.id }) else { return }
            var params = graph.nodes[index].params ?? [:]
            for (name, value) in values { params[name] = value }
            graph.nodes[index].params = params
        }
    }

    private func value(_ node: MaterialNode, _ kind: MaterialNodeKind, _ name: String) -> Double {
        node.params?[name] ?? kind.params.first { $0.name == name }?.value ?? 0
    }

    private func textureNames() -> [String] {
        var names = document.textureSlots.map(\.name)
        for asset in app.textureAssets where asset.url.pathExtension.lowercased() == "png" {
            let name = (asset.name as NSString).deletingPathExtension
            if !names.contains(name) { names.append(name) }
        }
        return Array(names.prefix(80))
    }

    private func freeSpot(_ type: String, _ graph: MaterialGraph) -> CGPoint {
        let size = CGSize(width: MaterialLook.nodeWidth, height: MaterialGraph.kind(of: type).map(MaterialLook.height) ?? 80)
        let taken = graph.nodes.compactMap { node -> CGRect? in
            guard let kind = MaterialGraph.kind(of: node.type) else { return nil }
            return CGRect(x: CGFloat(node.x ?? 0), y: CGFloat(node.y ?? 0), width: MaterialLook.nodeWidth, height: MaterialLook.height(kind)).insetBy(dx: -14, dy: -14)
        }
        let start = world(CGPoint(x: 24, y: 24))
        for column in 0..<6 {
            for line in 0..<14 {
                let candidate = CGRect(origin: CGPoint(x: start.x + CGFloat(column) * (MaterialLook.nodeWidth + 28), y: start.y + CGFloat(line) * 44), size: size)
                if !taken.contains(where: { $0.intersects(candidate) }) { return candidate.origin }
            }
        }
        return start
    }

    private func addNode(_ type: String, at screen: CGPoint?, _ particle: String) {
        guard let graph = document.materialGraph(particle) else { return }
        let spot = screen.map(world) ?? freeSpot(type, graph)
        if let id = document.addMaterialNode(type, at: spot, in: particle) { selection = [id] }
    }

    private func colorRow(_ particle: String, _ node: MaterialNode, _ kind: MaterialNodeKind, _ keys: [String], alpha: String?, title: String) -> some View {
        let current = SIMD4(value(node, kind, keys[0]), value(node, kind, keys[1]), value(node, kind, keys[2]), alpha.map { value(node, kind, $0) } ?? 1)
        return ColorField(color: current, alpha: alpha != nil, onLive: { _ in },
                          onCommit: { _, next in
                              var values = [keys[0]: next.x, keys[1]: next.y, keys[2]: next.z]
                              if let alpha { values[alpha] = next.w }
                              setParams(particle, node, values, title: title)
                          })
            .padding(.horizontal, 6)
    }

    private func texturePicker(_ particle: String, _ node: MaterialNode) -> some View {
        Menu {
            ForEach(textureNames(), id: \.self) { name in
                Button(name) {
                    document.editMaterial("Set Texture", in: particle) { graph in
                        if let index = graph.nodes.firstIndex(where: { $0.id == node.id }) { graph.nodes[index].texture = name }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "photo").font(.system(size: 9))
                Text(node.texture ?? "Choose texture").font(Theme.small).lineLimit(1).truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.text)
        }
        .menuStyle(.borderlessButton)
    }

    private func nodeBody(_ node: MaterialNode, _ kind: MaterialNodeKind, _ graph: MaterialGraph, _ particle: String) -> some View {
        let wired = Set(graph.links.filter { $0.to == node.id }.map(\.input))
        return VStack(spacing: 0) {
            ForEach(0..<max(kind.inputs.count, kind.outputs.count), id: \.self) { index in
                HStack(spacing: 4) {
                    if index < kind.inputs.count {
                        let name = kind.inputs[index]
                        Circle().fill(wired.contains(name) ? MaterialLook.pin(name) : Theme.gray(0.14)).overlay(Circle().stroke(MaterialLook.pin(name), lineWidth: 1.5))
                            .frame(width: 10, height: 10).offset(x: -5)
                            .contentShape(Rectangle().inset(by: -7))
                            .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .named("material"))
                                .onChanged { drag in
                                    if wire == nil, let link = graph.links.first(where: { $0.to == node.id && $0.input == name }) {
                                        document.disconnectMaterial(to: node.id, input: name, in: particle)
                                        wire = (link.from, link.out, drag.location)
                                    } else if let active = wire {
                                        wire = (active.from, active.out, drag.location)
                                    }
                                }
                                .onEnded { drag in
                                    if let active = wire, let live = document.materialGraph(particle), let target = nearestInput(drag.location, live) {
                                        document.connectMaterial(from: active.from, out: active.out, to: target.node, input: target.input, in: particle)
                                    }
                                    wire = nil
                                })
                            .onTapGesture { document.disconnectMaterial(to: node.id, input: name, in: particle) }
                            .help(wired.contains(name) ? "Click to disconnect, drag to move the wire to another input" : "Drag a wire here from an output")
                        Text(name).font(Theme.small).foregroundStyle(wired.contains(name) ? Theme.text : Theme.dim)
                    }
                    Spacer(minLength: 0)
                    if index < kind.outputs.count {
                        let name = kind.outputs[index]
                        Text(name).font(Theme.small).foregroundStyle(Theme.text)
                        Circle().fill(MaterialLook.pin(name)).frame(width: 10, height: 10).offset(x: 5)
                            .contentShape(Rectangle().inset(by: -7))
                            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("material"))
                                .onChanged { drag in wire = (node.id, name, drag.location) }
                                .onEnded { drag in
                                    if let target = nearestInput(drag.location, graph) {
                                        document.connectMaterial(from: node.id, out: name, to: target.node, input: target.input, in: particle)
                                    }
                                    wire = nil
                                })
                            .help("Drag to an input to connect")
                    }
                }
                .frame(height: MaterialLook.row)
            }
            if kind.type == "texture" {
                texturePicker(particle, node).padding(.horizontal, 8).frame(height: MaterialLook.row)
                ZStack {
                    CheckerBackground()
                    if let name = node.texture, let image = MaterialPixels.shared.image(app, name: name) {
                        Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                    }
                }
                .frame(height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            }
            if kind.type == "color" {
                colorRow(particle, node, kind, ["r", "g", "b"], alpha: "a", title: "Set Color").frame(height: 26)
            }
            if kind.type == "subgraph" {
                let own = document.materialUse(particle)
                Menu {
                    ForEach(document.sharedMaterialNames.filter { $0 != own }, id: \.self) { name in
                        Button(name) {
                            document.editMaterial("Set Subgraph", in: particle) { graph in
                                if let index = graph.nodes.firstIndex(where: { $0.id == node.id }) { graph.nodes[index].graph = name }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.hexagongrid").font(.system(size: 9))
                        Text(node.graph ?? (document.sharedMaterialNames.isEmpty ? "No shared materials" : "Choose material")).font(Theme.small).lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Theme.text)
                }
                .menuStyle(.borderlessButton)
                .padding(.horizontal, 8)
                .frame(height: MaterialLook.row)
            }
            if kind.type == "gradient" {
                let stops = [("ar", "ag", "ab"), ("br", "bg", "bb"), ("cr", "cg", "cb")]
                let colors = stops.map { Color(.sRGB, red: value(node, kind, $0.0), green: value(node, kind, $0.1), blue: value(node, kind, $0.2)) }
                let mid = min(max(value(node, kind, "mid"), 0.001), 0.999)
                LinearGradient(stops: [.init(color: colors[0], location: 0), .init(color: colors[1], location: mid), .init(color: colors[2], location: 1)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(height: 12).clipShape(RoundedRectangle(cornerRadius: 3)).padding(.horizontal, 8).padding(.vertical, 3)
                ForEach(0..<3, id: \.self) { index in
                    colorRow(particle, node, kind, [stops[index].0, stops[index].1, stops[index].2], alpha: nil, title: "Set Gradient Color").frame(height: 24)
                }
            }
            ForEach(MaterialLook.shownParams(kind), id: \.name) { entry in
                let covered = kind.inputs.contains(entry.name) && wired.contains(entry.name)
                NumberField(label: entry.name, value: value(node, kind, entry.name), step: 0.01, onLive: { _ in },
                            onCommit: { _, next in setParams(particle, node, [entry.name: next], title: "Set " + kind.title + " " + entry.name) })
                    .padding(.horizontal, 6)
                    .frame(height: MaterialLook.row)
                    .opacity(covered ? 0.3 : 1)
                    .allowsHitTesting(!covered)
            }
            Spacer(minLength: 0)
        }
    }

    private func nodeView(_ node: MaterialNode, _ kind: MaterialNodeKind, _ graph: MaterialGraph, _ particle: String) -> some View {
        let chosen = selection.contains(node.id)
        return VStack(spacing: 0) {
            HStack(spacing: 5) {
                Text(node.name?.isEmpty == false ? node.name ?? kind.title : kind.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.white).lineLimit(1)
                if node.name?.isEmpty == false { Text(kind.title).font(.system(size: 9)).foregroundStyle(Color.white.opacity(0.65)).lineLimit(1) }
                Spacer(minLength: 0)
                if node.type != "output" {
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Color.white.opacity(0.75)).frame(width: 16, height: 16)
                        .contentShape(Rectangle()).onTapGesture { document.removeMaterialNodes([node.id], in: particle) }.help("Delete this node")
                }
            }
            .padding(.horizontal, 9)
            .frame(height: MaterialLook.header)
            .background(MaterialLook.tint(kind.category).opacity(0.85))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 2, coordinateSpace: .named("material"))
                .onChanged { drag in
                    if moving == nil {
                        if !selection.contains(node.id) { selection = [node.id] }
                        var origins: [String: CGPoint] = [:]
                        for other in graph.nodes where selection.contains(other.id) || other.id == node.id { origins[other.id] = CGPoint(x: other.x ?? 0, y: other.y ?? 0) }
                        moving = (origins, document.snapshot())
                    }
                    guard let moving, var live = document.materialGraph(particle) else { return }
                    for index in live.nodes.indices {
                        guard let start = moving.origins[live.nodes[index].id] else { continue }
                        live.nodes[index].x = Double(start.x + drag.translation.width / zoom)
                        live.nodes[index].y = Double(start.y + drag.translation.height / zoom)
                    }
                    document.writeMaterial(live, to: particle)
                    document.liveDrag()
                }
                .onEnded { _ in
                    if let moving { document.registerUndo(moving.origins.count == 1 ? "Move Node" : "Move Nodes", since: moving.before) }
                    moving = nil
                })
            .onTapGesture {
                focused = true
                if NSEvent.modifierFlags.contains(.shift) {
                    if selection.contains(node.id) { selection.remove(node.id) } else { selection.insert(node.id) }
                } else {
                    selection = [node.id]
                }
                previewPin = nil
            }
            nodeBody(node, kind, graph, particle)
        }
        .frame(width: MaterialLook.nodeWidth, height: MaterialLook.height(kind), alignment: .top)
        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.gray(0.19)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(chosen ? Color(red: 1, green: 0.63, blue: 0.16) : Color.black.opacity(0.55), lineWidth: chosen ? 2 : 1))
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        .help(kind.help)
    }

    private func drawLinks(_ context: inout GraphicsContext, _ size: CGSize, _ graph: MaterialGraph) {
        let step = 24 * zoom
        if step > 9 {
            var dots = Path()
            var x = pan.width.truncatingRemainder(dividingBy: step)
            while x < size.width {
                var y = pan.height.truncatingRemainder(dividingBy: step)
                while y < size.height {
                    dots.addRect(CGRect(x: x, y: y, width: 1.2, height: 1.2))
                    y += step
                }
                x += step
            }
            context.fill(dots, with: .color(Color.white.opacity(0.11)))
        }
        for link in graph.links {
            guard let from = graph.nodes.first(where: { $0.id == link.from }), let to = graph.nodes.first(where: { $0.id == link.to }),
                  let fromKind = MaterialGraph.kind(of: from.type), let toKind = MaterialGraph.kind(of: to.type),
                  let out = fromKind.outputs.firstIndex(of: link.out), let input = toKind.inputs.firstIndex(of: link.input) else { continue }
            let path = curve(outputPin(from, out), inputPin(to, input))
            context.stroke(path, with: .color(Color.black.opacity(0.45)), lineWidth: 4 * max(zoom, 0.6))
            context.stroke(path, with: .color(MaterialLook.pin(link.out)), lineWidth: 2 * max(zoom, 0.6))
        }
        if let wire, let from = graph.nodes.first(where: { $0.id == wire.from }), let kind = MaterialGraph.kind(of: from.type),
           let out = kind.outputs.firstIndex(of: wire.out) {
            let target = nearestInput(wire.end, graph)
            context.stroke(curve(outputPin(from, out), wire.end), with: .color(target == nil ? Color.white.opacity(0.75) : Color(red: 1, green: 0.63, blue: 0.16)),
                           style: StrokeStyle(lineWidth: 2, dash: target == nil ? [5, 4] : []))
        }
        if let box {
            let rect = CGRect(x: min(box.start.x, box.end.x), y: min(box.start.y, box.end.y), width: abs(box.end.x - box.start.x), height: abs(box.end.y - box.start.y))
            context.fill(Path(rect), with: .color(Color.white.opacity(0.06)))
            context.stroke(Path(rect), with: .color(Color.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
    }

    private func key(_ press: KeyPress, _ graph: MaterialGraph, _ particle: String) -> KeyPress.Result {
        let command = press.modifiers.contains(.command)
        switch AppShortcuts.canonical(press.characters) {
        case "\u{7f}", "\u{8}", "x":
            guard !selection.isEmpty else { return .ignored }
            document.removeMaterialNodes(selection, in: particle)
            selection = []
        case "a":
            if press.modifiers.contains(.option) { selection = [] } else { selection = Set(graph.nodes.map(\.id)) }
        case "d":
            guard command, let part = document.materialSubgraph(selection, in: particle) else { return .ignored }
            selection = Set(document.insertMaterialNodes(part, offset: CGSize(width: 30, height: 30), title: "Duplicate Nodes", in: particle))
        case "c":
            guard command, let part = document.materialSubgraph(selection, in: particle) else { return .ignored }
            MaterialLibrary.clipboard = part
        case "v":
            guard command, let part = MaterialLibrary.clipboard else { return .ignored }
            selection = Set(document.insertMaterialNodes(part, offset: CGSize(width: 40, height: 40), title: "Paste Nodes", in: particle))
        case "\u{F729}", ".":
            frameAll(graph)
        case "\u{1b}":
            selection = []
            quickAdd = nil
        default:
            return .ignored
        }
        return .handled
    }

    private func quickAddPanel(_ particle: String) -> some View {
        let needle = quickText.lowercased()
        let matches = MaterialGraph.kinds.filter { $0.type != "output" && (needle.isEmpty || $0.title.lowercased().contains(needle) || $0.category.lowercased().contains(needle)) }
        return VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                TextField("Add node…", text: $quickText).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                    .onSubmit {
                        if let first = matches.first { addNode(first.type, at: quickAdd, particle) }
                        quickAdd = nil
                    }
            }
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(matches, id: \.type) { kind in
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 2).fill(MaterialLook.tint(kind.category)).frame(width: 4, height: 12)
                            Text(kind.title).font(Theme.font).foregroundStyle(Theme.text)
                            Spacer(minLength: 4)
                            Text(kind.category).font(Theme.small).foregroundStyle(Theme.dim)
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            addNode(kind.type, at: quickAdd, particle)
                            quickAdd = nil
                        }
                        .help(kind.help)
                    }
                }
            }
            .frame(height: 240)
        }
        .padding(8)
        .frame(width: 250)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }

    private func canvas(_ graph: MaterialGraph, _ particle: String) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in drawLinks(&context, size, graph) }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("material"))
                        .onChanged { drag in
                            focused = true
                            if hypot(drag.translation.width, drag.translation.height) > 3 { box = (drag.startLocation, drag.location) }
                        }
                        .onEnded { drag in
                            if let box {
                                let rect = CGRect(x: min(box.start.x, box.end.x), y: min(box.start.y, box.end.y), width: abs(box.end.x - box.start.x),
                                                  height: abs(box.end.y - box.start.y))
                                var picked: Set<String> = NSEvent.modifierFlags.contains(.shift) ? selection : []
                                for node in graph.nodes {
                                    guard let kind = MaterialGraph.kind(of: node.type) else { continue }
                                    let frame = CGRect(origin: origin(node), size: CGSize(width: MaterialLook.nodeWidth * zoom, height: MaterialLook.height(kind) * zoom))
                                    if rect.intersects(frame) { picked.insert(node.id) }
                                }
                                selection = picked
                            } else {
                                selection = []
                                let now = Date()
                                if now.timeIntervalSince(lastTap.time) < NSEvent.doubleClickInterval, hypot(lastTap.point.x - drag.location.x, lastTap.point.y - drag.location.y) < 6 {
                                    quickText = ""
                                    quickAdd = drag.location
                                    lastTap = (.distantPast, .zero)
                                } else {
                                    lastTap = (now, drag.location)
                                }
                            }
                            box = nil
                        })
                ForEach(graph.nodes, id: \.id) { node in
                    if let kind = MaterialGraph.kind(of: node.type) {
                        nodeView(node, kind, graph, particle).scaleEffect(zoom, anchor: .topLeading).offset(x: origin(node).x, y: origin(node).y)
                    }
                }
                HStack(spacing: 2) {
                    HeaderButton(symbol: "plus.magnifyingglass", help: "Zoom in") { zoomBy(1.2, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)) }
                    HeaderButton(symbol: "minus.magnifyingglass", help: "Zoom out") { zoomBy(1 / 1.2, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)) }
                    HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Frame All (Home)") { frameAll(graph) }
                    Text("\(Int((zoom * 100).rounded()))%").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim).frame(width: 38)
                    HelpBadge(text: "Double-click the canvas: add a node by name\nDrag from an output to an input: connect\nClick an input: disconnect · drag it: move the wire\nDrag a header: move · Shift-click or drag a box: select several\n⌘C ⌘V ⌘D copy, paste, duplicate · Delete removes\nScroll: pan · Pinch or ⌘-scroll: zoom · Home: frame all")
                }
                .padding(5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.panel.opacity(0.92)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Theme.gray(0.125))
            .clipped()
            .coordinateSpace(name: "material")
            .background(ScrollMonitor(onScroll: { delta, flags, point in
                if flags.contains(.command) || flags.contains(.control) {
                    zoomBy(1 + delta.height * 0.005, at: point)
                } else {
                    pan = CGSize(width: pan.width + delta.width, height: pan.height + delta.height)
                }
            }, onMagnify: { amount, point in zoomBy(1 + amount, at: point) }))
            .popover(isPresented: Binding(get: { quickAdd != nil }, set: { if !$0 { quickAdd = nil } }),
                     attachmentAnchor: .point(UnitPoint(x: (quickAdd?.x ?? 0) / max(geometry.size.width, 1), y: (quickAdd?.y ?? 0) / max(geometry.size.height, 1))),
                     arrowEdge: .top) { quickAddPanel(particle) }
            .onAppear {
                canvasSize = geometry.size
                if framed != particle {
                    framed = particle
                    frameAll(graph)
                }
            }
            .onChange(of: geometry.size) { _, next in canvasSize = next }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress { key($0, graph, particle) }
    }

    private func palette(_ particle: String, _ graph: MaterialGraph?) -> some View {
        let needle = search.lowercased()
        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                TextField("Search nodes", text: $search).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
            }
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            .padding(8)
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(MaterialGraph.categories.filter { $0 != "Output" }, id: \.self) { category in
                        let kinds = MaterialGraph.kinds.filter { $0.category == category && (needle.isEmpty || $0.title.lowercased().contains(needle)) }
                        if !kinds.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: open.contains(category) || !needle.isEmpty ? "chevron.down" : "chevron.right").font(.system(size: 7, weight: .bold)).frame(width: 9)
                                RoundedRectangle(cornerRadius: 2).fill(MaterialLook.tint(category)).frame(width: 4, height: 11)
                                Text(category).font(.system(size: 11, weight: .medium))
                                Spacer(minLength: 0)
                                Text("\(kinds.count)").font(Theme.small).foregroundStyle(Theme.dim)
                            }
                            .foregroundStyle(Theme.text)
                            .frame(height: 20)
                            .contentShape(Rectangle())
                            .onTapGesture { if open.contains(category) { open.remove(category) } else { open.insert(category) } }
                            if open.contains(category) || !needle.isEmpty {
                                FlowLayout(spacing: 3) {
                                    ForEach(kinds, id: \.type) { kind in
                                        Text(kind.title).font(Theme.small).foregroundStyle(graph != nil ? Theme.text : Theme.dim).padding(.horizontal, 6).frame(height: 18)
                                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.25)))
                                            .contentShape(Rectangle())
                                            .onTapGesture { if graph != nil { addNode(kind.type, at: nil, particle) } }
                                            .help(kind.help)
                                    }
                                }
                                .padding(.bottom, 3)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 196)
        .background(Theme.panel)
    }

    private func status(_ graph: MaterialGraph?, _ resolved: MaterialGraph?) -> some View {
        let compiled = resolved?.compile()
        let shader = resolved.flatMap { graph in MTLCreateSystemDefaultDevice().flatMap { MetalRenderer.shaderProblem(graph, device: $0) } }
        let problem = compiled?.problems.first ?? shader.map { "Shader: " + $0 }
        return HStack(spacing: 14) {
            if let graph, let compiled {
                Text("NODES \(graph.nodes.count)").foregroundStyle(Theme.dim)
                Text("TEXTURE TAPS \(graph.textures.count)/\(MaterialGraph.maxTextures)").foregroundStyle(graph.textures.count > MaterialGraph.maxTextures ? Color.orange : Theme.dim)
                Text("SHADER LINES \(compiled.code.split(separator: "\n").count)").foregroundStyle(Theme.dim)
                if !selection.isEmpty { Text("\(selection.count) SELECTED").foregroundStyle(Theme.text) }
            }
            Spacer(minLength: 4)
            if let problem {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9))
                    Text(problem).lineLimit(1).truncationMode(.tail)
                }
                .foregroundStyle(Color.orange)
            } else if graph != nil {
                HStack(spacing: 4) {
                    Circle().fill(Color.green.opacity(0.85)).frame(width: 6, height: 6)
                    Text("compiled").foregroundStyle(Theme.text)
                }
            }
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(.horizontal, 10)
        .frame(height: 22)
        .background(Theme.header)
    }

    var body: some View {
        let _ = document.revision
        if let particle = document.materialParticleID {
            let graph = document.materialGraph(particle)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    palette(particle, graph)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    if let graph {
                        VStack(spacing: 0) {
                            if let shared = document.materialUse(particle) {
                                let users = document.materialUsers(shared).count
                                HStack(spacing: 8) {
                                    Image(systemName: "link").font(.system(size: 10))
                                    Text("Shared “\(shared)” · \(users) particle\(users == 1 ? "" : "s") · graph edits change all of them")
                                        .font(Theme.small).lineLimit(1)
                                    Spacer(minLength: 4)
                                    SegmentButton(title: "Make Unique", active: false) { document.makeMaterialUnique(in: particle) }
                                }
                                .foregroundStyle(Theme.text)
                                .padding(.horizontal, 10)
                                .frame(height: 26)
                                .background(Theme.accent.opacity(0.35))
                            }
                            canvas(graph, particle)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "circle.hexagongrid").font(.system(size: 26)).foregroundStyle(Theme.dim)
                            Text("This particle has no material").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.text)
                            Text("It is drawn by its texture and layers. A material is a node graph that decides the final colour and alpha. It starts from the same result, so nothing changes until you rewire it.")
                                .font(Theme.small).foregroundStyle(Theme.dim).multilineTextAlignment(.center).frame(maxWidth: 360)
                            SegmentButton(title: "Create Material", active: true) { document.createMaterial(in: particle) }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.gray(0.125))
                    }
                    Rectangle().fill(Theme.line).frame(width: 1)
                    MaterialInspector(document: document, particle: particle, graph: graph, selection: $selection, previewPin: $previewPin)
                }
                status(graph, document.resolvedMaterial(particle))
            }
            .onChange(of: particle) { _, _ in
                selection = []
                if let next = document.materialParticleID.flatMap({ document.materialGraph($0) }) { frameAll(next) }
            }
        } else if document.format == .avfx, let particle = avfxParticle {
            AvfxMaterialView(document: document, particleID: particle)
                .onChange(of: document.selectionID) { _, _ in rememberParticle() }
                .onAppear { rememberParticle() }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "circle.hexagongrid").font(.system(size: 26)).foregroundStyle(Theme.dim)
                Text("Material Editor").font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.text)
                Text("Select a particle in the Outliner to see how it is drawn.").font(Theme.small).foregroundStyle(Theme.dim)
            }
            .onChange(of: document.selectionID) { _, _ in rememberParticle() }
            .onAppear { rememberParticle() }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.gray(0.125))
        }
    }
}
