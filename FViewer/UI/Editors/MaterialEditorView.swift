import SwiftUI
import VfxCore
import VfxMetal

struct MaterialEditorView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var pan = CGSize(width: 20, height: 10)
    @State private var moving: (id: String, origin: CGPoint, before: Any)?
    @State private var wire: (from: String, out: String, end: CGPoint)?
    @State private var selected: String?
    @State private var open: Set<String> = ["Particle", "Texture", "Math"]

    private static let nodeWidth: CGFloat = 164
    private static let header: CGFloat = 22
    private static let row: CGFloat = 20

    private func rows(_ kind: MaterialNodeKind) -> Int { max(kind.inputs.count, kind.outputs.count) + kind.params.count + (kind.texture ? 1 : 0) }

    private func height(_ kind: MaterialNodeKind) -> CGFloat { MaterialEditorView.header + CGFloat(rows(kind)) * MaterialEditorView.row + 6 }

    private func origin(_ node: MaterialNode) -> CGPoint { CGPoint(x: CGFloat(node.x ?? 0) + pan.width, y: CGFloat(node.y ?? 0) + pan.height) }

    private func inputPin(_ node: MaterialNode, _ index: Int) -> CGPoint {
        let o = origin(node)
        return CGPoint(x: o.x, y: o.y + MaterialEditorView.header + CGFloat(index) * MaterialEditorView.row + MaterialEditorView.row / 2)
    }

    private func outputPin(_ node: MaterialNode, _ index: Int) -> CGPoint {
        let o = origin(node)
        return CGPoint(x: o.x + MaterialEditorView.nodeWidth, y: o.y + MaterialEditorView.header + CGFloat(index) * MaterialEditorView.row + MaterialEditorView.row / 2)
    }

    private func curve(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        let reach = max(40, abs(b.x - a.x) * 0.5)
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x + reach, y: a.y), control2: CGPoint(x: b.x - reach, y: b.y))
        return path
    }

    private func pinColor(_ name: String) -> Color {
        switch name {
        case "uv": return Color(red: 0.45, green: 0.75, blue: 0.95)
        case "rgb", "color", "emissive": return Color(red: 0.95, green: 0.55, blue: 0.75)
        default: return Color(white: 0.72)
        }
    }

    private func nearestInput(_ point: CGPoint, _ graph: MaterialGraph) -> (node: String, input: String)? {
        var best: (node: String, input: String, distance: CGFloat)?
        for node in graph.nodes {
            guard let kind = MaterialGraph.kind(of: node.type) else { continue }
            for (index, name) in kind.inputs.enumerated() {
                let pin = inputPin(node, index)
                let d = hypot(pin.x - point.x, pin.y - point.y)
                if d < 16, d < (best?.distance ?? .infinity) { best = (node.id, name, d) }
            }
        }
        return best.map { ($0.node, $0.input) }
    }

    private func setParam(_ particle: String, _ node: MaterialNode, _ name: String, _ value: Double, title: String) {
        document.editMaterial(title, in: particle) { graph in
            guard let index = graph.nodes.firstIndex(where: { $0.id == node.id }) else { return }
            var params = graph.nodes[index].params ?? [:]
            params[name] = value
            graph.nodes[index].params = params
        }
    }

    private func textureNames() -> [String] {
        var names = document.textureSlots.map(\.name)
        for asset in app.textureAssets where asset.url.pathExtension.lowercased() == "png" {
            let name = (asset.name as NSString).deletingPathExtension
            if !names.contains(name) { names.append(name) }
        }
        return Array(names.prefix(60))
    }

    private func nodeView(_ node: MaterialNode, _ kind: MaterialNodeKind, _ graph: MaterialGraph, _ particle: String) -> some View {
        let wired = Set(graph.links.filter { $0.to == node.id }.map(\.input))
        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text(kind.title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text).lineLimit(1)
                Spacer(minLength: 0)
                if node.type != "output" {
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 16, height: 16)
                        .contentShape(Rectangle()).onTapGesture { document.removeMaterialNode(node.id, in: particle) }.help("Delete this node")
                }
            }
            .padding(.horizontal, 8)
            .frame(height: MaterialEditorView.header)
            .background(node.type == "output" ? Theme.changed.opacity(0.35) : Theme.gray(0.3))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("material"))
                .onChanged { value in
                    if moving == nil { moving = (node.id, CGPoint(x: node.x ?? 0, y: node.y ?? 0), document.snapshot()) }
                    guard let moving, var live = document.materialGraph(particle), let index = live.nodes.firstIndex(where: { $0.id == node.id }) else { return }
                    live.nodes[index].x = Double(moving.origin.x + value.translation.width)
                    live.nodes[index].y = Double(moving.origin.y + value.translation.height)
                    document.writeMaterial(live, to: particle)
                    document.liveDrag()
                }
                .onEnded { _ in
                    if let moving { document.registerUndo("Move Node", since: moving.before) }
                    moving = nil
                })
            .onTapGesture { selected = node.id }
            ForEach(0..<max(kind.inputs.count, kind.outputs.count), id: \.self) { index in
                HStack(spacing: 4) {
                    if index < kind.inputs.count {
                        let name = kind.inputs[index]
                        Circle().fill(wired.contains(name) ? pinColor(name) : Color.clear).overlay(Circle().stroke(pinColor(name), lineWidth: 1.5))
                            .frame(width: 9, height: 9).offset(x: -4.5)
                            .contentShape(Rectangle().inset(by: -6))
                            .onTapGesture { document.disconnectMaterial(to: node.id, input: name, in: particle) }
                            .help(wired.contains(name) ? "Click to disconnect" : "Drag a wire here from an output")
                        Text(name).font(Theme.small).foregroundStyle(wired.contains(name) ? Theme.text : Theme.dim)
                    }
                    Spacer(minLength: 0)
                    if index < kind.outputs.count {
                        let name = kind.outputs[index]
                        Text(name).font(Theme.small).foregroundStyle(Theme.text)
                        Circle().fill(pinColor(name)).frame(width: 9, height: 9).offset(x: 4.5)
                            .contentShape(Rectangle().inset(by: -6))
                            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("material"))
                                .onChanged { value in wire = (node.id, name, value.location) }
                                .onEnded { value in
                                    if let target = nearestInput(value.location, graph) {
                                        document.connectMaterial(from: node.id, out: name, to: target.node, input: target.input, in: particle)
                                    }
                                    wire = nil
                                })
                            .help("Drag to an input to connect")
                    }
                }
                .frame(height: MaterialEditorView.row)
            }
            if kind.texture {
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
                .padding(.horizontal, 8)
                .frame(height: MaterialEditorView.row)
            }
            ForEach(kind.params, id: \.name) { entry in
                let live = node.params?[entry.name] ?? entry.value
                let covered = kind.inputs.contains(entry.name) && wired.contains(entry.name)
                NumberField(label: entry.name, value: live, step: 0.01, onLive: { _ in },
                            onCommit: { _, next in setParam(particle, node, entry.name, next, title: "Set " + kind.title + " " + entry.name) })
                    .padding(.horizontal, 6)
                    .frame(height: MaterialEditorView.row)
                    .opacity(covered ? 0.35 : 1)
                    .allowsHitTesting(!covered)
            }
            Spacer(minLength: 0)
        }
        .frame(width: MaterialEditorView.nodeWidth, height: height(kind), alignment: .top)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.gray(0.2)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected == node.id ? Theme.changed : Color.black.opacity(0.5), lineWidth: selected == node.id ? 1.5 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .help(kind.help)
    }

    private func canvas(_ graph: MaterialGraph, _ particle: String) -> some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                var dots = Path()
                var x = pan.width.truncatingRemainder(dividingBy: 24)
                while x < size.width {
                    var y = pan.height.truncatingRemainder(dividingBy: 24)
                    while y < size.height {
                        dots.addRect(CGRect(x: x, y: y, width: 1, height: 1))
                        y += 24
                    }
                    x += 24
                }
                context.fill(dots, with: .color(Color.white.opacity(0.12)))
                for link in graph.links {
                    guard let from = graph.nodes.first(where: { $0.id == link.from }), let to = graph.nodes.first(where: { $0.id == link.to }),
                          let fromKind = MaterialGraph.kind(of: from.type), let toKind = MaterialGraph.kind(of: to.type),
                          let out = fromKind.outputs.firstIndex(of: link.out), let input = toKind.inputs.firstIndex(of: link.input) else { continue }
                    context.stroke(curve(outputPin(from, out), inputPin(to, input)), with: .color(pinColor(link.out).opacity(0.9)), lineWidth: 1.6)
                }
                if let wire, let from = graph.nodes.first(where: { $0.id == wire.from }), let kind = MaterialGraph.kind(of: from.type),
                   let out = kind.outputs.firstIndex(of: wire.out) {
                    context.stroke(curve(outputPin(from, out), wire.end), with: .color(Color.white.opacity(0.8)), style: StrokeStyle(lineWidth: 1.4, dash: [4, 3]))
                }
            }
            ForEach(graph.nodes, id: \.id) { node in
                if let kind = MaterialGraph.kind(of: node.type) {
                    nodeView(node, kind, graph, particle).offset(x: origin(node).x, y: origin(node).y)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.gray(0.13))
        .clipped()
        .coordinateSpace(name: "material")
        .background(ScrollMonitor(onScroll: { delta, _, _ in pan = CGSize(width: pan.width + delta.width, height: pan.height + delta.height) },
                                  onMagnify: { _, _ in }))
    }

    private func palette(_ particle: String, hasMaterial: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if hasMaterial {
                    SegmentButton(title: "Remove Material", active: false) { document.removeMaterial(in: particle) }
                } else {
                    SegmentButton(title: "+ New Material", active: false) { document.createMaterial(in: particle) }
                }
                Text("ADD NODE").font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.dim).padding(.top, 6)
                ForEach(MaterialGraph.categories.filter { $0 != "Output" }, id: \.self) { category in
                    HStack(spacing: 4) {
                        Image(systemName: open.contains(category) ? "chevron.down" : "chevron.right").font(.system(size: 7, weight: .bold)).frame(width: 9)
                        Text(category).font(Theme.font)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Theme.text)
                    .frame(height: 18)
                    .contentShape(Rectangle())
                    .onTapGesture { if open.contains(category) { open.remove(category) } else { open.insert(category) } }
                    if open.contains(category) {
                        FlowLayout(spacing: 3) {
                            ForEach(MaterialGraph.kinds.filter { $0.category == category }, id: \.type) { kind in
                                Text(kind.title).font(Theme.small).foregroundStyle(hasMaterial ? Theme.text : Theme.dim).padding(.horizontal, 6).frame(height: 18)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.24)))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        guard hasMaterial else { return }
                                        let count = document.materialGraph(particle)?.nodes.count ?? 0
                                        let spot = CGPoint(x: 220 - pan.width + CGFloat(count % 4) * 18, y: 40 - pan.height + CGFloat(count % 6) * 22)
                                        selected = document.addMaterialNode(kind.type, at: spot, in: particle)
                                    }
                                    .help(kind.help)
                            }
                        }
                    }
                }
            }
            .padding(8)
        }
        .frame(width: 190)
        .background(Theme.panel)
    }

    private func status(_ graph: MaterialGraph?) -> some View {
        let compiled = graph?.compile()
        let problem = compiled?.problems.first ?? (graph != nil ? MetalRenderer.lastMaterialError.map { "Shader: " + $0.prefix(160) } : nil)
        return HStack(spacing: 14) {
            if let graph, let compiled {
                Text("NODES \(graph.nodes.count)").foregroundStyle(Theme.dim)
                Text("TEXTURE TAPS \(graph.textures.count)/\(MaterialGraph.maxTextures)").foregroundStyle(graph.textures.count > MaterialGraph.maxTextures ? Color.orange : Theme.dim)
                Text("LINES \(compiled.code.split(separator: "\n").count)").foregroundStyle(Theme.dim)
            }
            Spacer(minLength: 4)
            if let problem {
                Text(problem).foregroundStyle(Color.orange).lineLimit(1).truncationMode(.tail)
            } else if graph != nil {
                Text("compiled").foregroundStyle(Color.green.opacity(0.8))
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
                    palette(particle, hasMaterial: graph != nil)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    if let graph {
                        canvas(graph, particle)
                    } else {
                        VStack(spacing: 6) {
                            Text("This particle has no material").font(Theme.font).foregroundStyle(Theme.text)
                            Text("It is drawn by its texture and layers. A material is a node graph that decides the final colour and alpha; it starts from the same result, so nothing changes until you rewire it.")
                                .font(Theme.small).foregroundStyle(Theme.dim).multilineTextAlignment(.center).frame(maxWidth: 380)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.gray(0.13))
                    }
                }
                status(graph)
            }
        } else {
            VStack(spacing: 6) {
                Text("Material Editor").font(Theme.font).foregroundStyle(Theme.text)
                Text(document.format == .pixi ? "Select a particle to edit its material." : "Materials belong to 2D effects (.json). An .avfx particle is drawn by fixed game fields.")
                    .font(Theme.small).foregroundStyle(Theme.dim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.gray(0.13))
        }
    }
}
