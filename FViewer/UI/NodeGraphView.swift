import SwiftUI

private struct NodeMetrics {
    static let width: CGFloat = 176
    static let header: CGFloat = 22
    static let line: CGFloat = 15
    static let thumbnail: CGFloat = 54
    static let columnGap: CGFloat = 250
    static let rowGap: CGFloat = 14

    static func height(_ node: GraphNode) -> CGFloat {
        header + CGFloat(node.lines.count) * line + (node.texturePath != nil ? thumbnail + 6 : 0) + (node.lines.isEmpty && node.texturePath == nil ? 0 : 8)
    }
}

private final class LinkMenu: NSObject {
    private var actions: [() -> Void] = []

    @objc private func pick(_ item: NSMenuItem) {
        if item.tag >= 0, item.tag < actions.count { actions[item.tag]() }
    }

    static func show(_ options: [LinkOption], title: String) {
        let handler = LinkMenu()
        let menu = NSMenu(title: title)
        let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())
        for (index, option) in options.enumerated() {
            let item = NSMenuItem(title: option.title, action: #selector(pick(_:)), keyEquivalent: "")
            item.target = handler
            item.tag = index
            handler.actions.append(option.perform)
            menu.addItem(item)
        }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

struct NodeGraphView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var offset = CGSize(width: 30, height: 30)
    @State private var zoom: CGFloat = 1
    @State private var moved: [String: CGPoint] = [:]
    @State private var dragOrigin: CGPoint?
    @State private var panOrigin: CGSize?
    @State private var wire: (from: String, point: CGPoint)?
    @State private var wireFromInput = false
    @State private var linkNote: String?
    @State private var hoveredSocket: String?
    @State private var selectedEdge: String?
    @State private var rewire: (edge: GraphEdge, point: CGPoint)?
    @State private var loadedDocument: UUID?
    @GestureState private var pressing = false
    @FocusState private var focused: Bool

    private func layout(_ graph: EffectGraph) -> [String: CGPoint] {
        var positions: [String: CGPoint] = [:]
        var heights: [Int: CGFloat] = [:]
        for node in graph.nodes {
            let y = heights[node.column, default: 0]
            positions[node.id] = moved[node.id] ?? CGPoint(x: CGFloat(node.column) * NodeMetrics.columnGap, y: y)
            heights[node.column] = y + NodeMetrics.height(node) + NodeMetrics.rowGap
        }
        return positions
    }

    private func screen(_ point: CGPoint) -> CGPoint { CGPoint(x: point.x * zoom + offset.width, y: point.y * zoom + offset.height) }
    private func graphPoint(_ point: CGPoint) -> CGPoint { CGPoint(x: (point.x - offset.width) / zoom, y: (point.y - offset.height) / zoom) }

    private func outputPoint(_ origin: CGPoint) -> CGPoint { CGPoint(x: origin.x + NodeMetrics.width, y: origin.y + NodeMetrics.header / 2) }
    private func inputPoint(_ origin: CGPoint) -> CGPoint { CGPoint(x: origin.x, y: origin.y + NodeMetrics.header / 2) }

    private func curve(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        let reach = max(40 * zoom, abs(b.x - a.x) * 0.5)
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x + reach, y: a.y), control2: CGPoint(x: b.x - reach, y: b.y))
        return path
    }

    private func curvePoint(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        let reach = max(40 * zoom, abs(b.x - a.x) * 0.5)
        let c1 = CGPoint(x: a.x + reach, y: a.y), c2 = CGPoint(x: b.x - reach, y: b.y)
        let u = 1 - t
        return CGPoint(x: u * u * u * a.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * b.x,
                       y: u * u * u * a.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * b.y)
    }

    private func nodeHit(_ graph: EffectGraph, _ positions: [String: CGPoint], at point: CGPoint) -> GraphNode? {
        let p = graphPoint(point)
        return graph.nodes.last { node in
            guard let origin = positions[node.id] else { return false }
            return CGRect(x: origin.x - 6, y: origin.y - 4, width: NodeMetrics.width + 12, height: NodeMetrics.height(node) + 8).contains(p)
        }
    }

    private func edgeHit(_ graph: EffectGraph, _ positions: [String: CGPoint], at point: CGPoint) -> GraphEdge? {
        var best: (GraphEdge, CGFloat)?
        for edge in graph.edges {
            guard let from = positions[edge.from], let to = positions[edge.to] else { continue }
            let a = screen(outputPoint(from)), b = screen(inputPoint(to))
            for step in 0...24 {
                let p = curvePoint(a, b, CGFloat(step) / 24)
                let d = hypot(p.x - point.x, p.y - point.y)
                if d < 7, d < (best?.1 ?? .infinity) { best = (edge, d) }
            }
        }
        return best?.0
    }

    var body: some View {
        let graph = document.graph
        let positions = layout(graph)
        let tints = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0.tint) })
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    let spacing = 24 * zoom
                    if spacing > 6 {
                        var gx = offset.width.truncatingRemainder(dividingBy: spacing)
                        while gx < size.width {
                            var gy = offset.height.truncatingRemainder(dividingBy: spacing)
                            while gy < size.height {
                                context.fill(Path(CGRect(x: gx, y: gy, width: 1.2, height: 1.2)), with: .color(Color.white.opacity(0.08)))
                                gy += spacing
                            }
                            gx += spacing
                        }
                    }
                    for edge in graph.edges where rewire?.edge.id != edge.id {
                        guard let from = positions[edge.from], let to = positions[edge.to] else { continue }
                        let a = screen(outputPoint(from)), b = screen(inputPoint(to))
                        let selected = selectedEdge == edge.id
                        let color = selected ? Color.white : (tints[edge.from] ?? .plain).color.opacity(0.85)
                        context.stroke(curve(a, b), with: .color(color),
                                       style: StrokeStyle(lineWidth: selected ? 2.5 : 1.6, dash: edge.dashed ? [5, 4] : []))
                        if !edge.label.isEmpty, zoom > 0.6 {
                            let mid = curvePoint(a, b, 0.5)
                            let text = Text(edge.label).font(.system(size: 9)).foregroundStyle(Theme.text)
                            let resolved = context.resolve(text)
                            let box = resolved.measure(in: CGSize(width: 200, height: 20))
                            context.fill(Path(roundedRect: CGRect(x: mid.x - box.width / 2 - 4, y: mid.y - box.height / 2 - 1, width: box.width + 8, height: box.height + 2),
                                              cornerRadius: 3), with: .color(Theme.gray(0.12)))
                            context.draw(resolved, at: mid)
                        }
                    }
                    if let wire, let from = positions[wire.from] {
                        let aimed = nodeHit(graph, positions, at: wire.point).map { $0.id != wire.from && !document.linkOptions(wire.from, $0.id).options.isEmpty }
                        let color: Color = aimed == true ? .green : aimed == false ? Color(red: 1, green: 0.45, blue: 0.4) : .white
                        let path = wireFromInput ? curve(wire.point, screen(inputPoint(from))) : curve(screen(outputPoint(from)), wire.point)
                        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                    }
                    if let rewire, let from = positions[rewire.edge.from] {
                        context.stroke(curve(screen(outputPoint(from)), rewire.point), with: .color(Theme.changed), style: StrokeStyle(lineWidth: 2.5, dash: [5, 3]))
                    }
                }
                .background(ScrollMonitor(
                    onScroll: { delta, flags, point in
                        if flags.contains(.command) {
                            zoomBy(1 + delta.height * 0.01, at: point)
                        } else {
                            offset.width += delta.width
                            offset.height += delta.height
                        }
                    },
                    onMagnify: { amount, point in zoomBy(1 + amount, at: point) }))
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 2)
                    .updating($pressing) { _, state, _ in state = true }
                    .onChanged { drag in
                        if panOrigin == nil, rewire == nil, let edge = edgeHit(graph, positions, at: drag.startLocation), edge.retarget != nil {
                            rewire = (edge, drag.location)
                            selectedEdge = edge.id
                            focused = true
                        }
                        if let active = rewire {
                            rewire = (active.edge, drag.location)
                            return
                        }
                        if panOrigin == nil { panOrigin = offset }
                        if let origin = panOrigin { offset = CGSize(width: origin.width + drag.translation.width, height: origin.height + drag.translation.height) }
                    }
                    .onEnded { drag in
                        if let active = rewire, let hit = nodeHit(graph, positions, at: drag.location) {
                            document.retarget(active.edge, to: hit.id)
                            selectedEdge = nil
                        }
                        rewire = nil
                        panOrigin = nil
                    })
                .onTapGesture { location in
                    focused = true
                    selectedEdge = edgeHit(graph, positions, at: location)?.id
                }
                ForEach(graph.nodes) { node in
                    if let origin = positions[node.id] {
                        nodeView(node, graph: graph, positions: positions)
                            .scaleEffect(zoom, anchor: .topLeading)
                            .offset(x: origin.x * zoom + offset.width, y: origin.y * zoom + offset.height)
                    }
                }
                HStack(spacing: 6) {
                    HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Frame All (Home)") { frameAll(graph, positions, geometry.size) }
                    HeaderButton(symbol: "rectangle.3.group", help: "Reset the layout") { moved = [:] }
                    if let selectedEdge, let edge = graph.edges.first(where: { $0.id == selectedEdge }), let remove = edge.remove {
                        HStack(spacing: 4) {
                            Image(systemName: "trash").font(.system(size: 9))
                            Text("Remove Link").font(Theme.font)
                        }
                        .foregroundStyle(Color(red: 1, green: 0.5, blue: 0.45))
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
                        .onTapGesture {
                            remove()
                            self.selectedEdge = nil
                        }
                    }
                    HelpBadge(text: "Drag from a socket onto another node to link them, in either direction\nnodes that can take the link turn green\ndrag an existing link onto another node to switch it\nclick a link and press X to remove it\ndrag nodes to arrange")
                    if let linkNote {
                        Text(linkNote).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1)
                            .padding(.horizontal, 8).frame(height: 20)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.16)))
                    }
                }
                .padding(6)
            }
            .clipped()
            .background(Theme.gray(0.115))
            .focusable()
            .focusEffectDisabled()
            .focused($focused)
            .onKeyPress { press in
                switch press.characters {
                case "x", "\u{7f}", "\u{8}":
                    if let selectedEdge, let edge = graph.edges.first(where: { $0.id == selectedEdge }), let remove = edge.remove {
                        remove()
                        self.selectedEdge = nil
                    }
                    return .handled
                case "\u{F729}":
                    frameAll(graph, positions, geometry.size)
                    return .handled
                default: return .ignored
                }
            }
            .onChange(of: pressing) { _, now in
                if !now {
                    panOrigin = nil
                    dragOrigin = nil
                    wire = nil
                    rewire = nil
                }
            }
            .onAppear {
                if loadedDocument != document.id {
                    loadedDocument = document.id
                    moved = [:]
                    frameAll(graph, layout(graph), geometry.size)
                }
            }
            .onChange(of: document.id) { _, _ in
                loadedDocument = document.id
                moved = [:]
                let fresh = document.graph
                frameAll(fresh, layout(fresh), geometry.size)
            }
        }
    }

    private func finishLink(_ a: String, _ b: String) {
        guard a != b else { return }
        let result = document.linkOptions(a, b)
        if result.options.isEmpty {
            show(result.problem ?? "These nodes cannot be linked")
        } else if result.options.count == 1 {
            result.options[0].perform()
            linkNote = nil
        } else {
            linkNote = nil
            LinkMenu.show(result.options, title: "Link \(EffectDocument.linkKind(a)) and \(EffectDocument.linkKind(b)) as")
        }
    }

    private func show(_ note: String) {
        linkNote = note
        app.notice = note
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { if linkNote == note { linkNote = nil } }
    }

    private func socket(_ node: GraphNode, input: Bool, graph: EffectGraph, positions: [String: CGPoint]) -> some View {
        let key = node.id + (input ? "<" : ">")
        let hot = hoveredSocket == key || (wire?.from == node.id && wireFromInput == input)
        return Circle().fill(input ? Color(white: 0.75) : node.tint.color)
            .overlay(Circle().stroke(hot ? Color.white : Color.black, lineWidth: hot ? 2 : 1))
            .frame(width: 13, height: 13)
            .scaleEffect(hot ? 1.3 : 1)
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .onHover { inside in
                if inside { hoveredSocket = key } else if hoveredSocket == key { hoveredSocket = nil }
            }
            .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("graph"))
                .updating($pressing) { _, state, _ in state = true }
                .onChanged { drag in
                    wireFromInput = input
                    wire = (node.id, drag.location)
                }
                .onEnded { drag in
                    let hit = nodeHit(graph, positions, at: drag.location)
                    wire = nil
                    if let hit { finishLink(node.id, hit.id) }
                })
            .help("Drag onto another node to link them")
    }

    private func zoomBy(_ factor: CGFloat, at point: CGPoint) {
        let next = min(max(zoom * factor, 0.25), 2)
        let anchor = graphPoint(point)
        zoom = next
        offset = CGSize(width: point.x - anchor.x * next, height: point.y - anchor.y * next)
    }

    private func frameAll(_ graph: EffectGraph, _ positions: [String: CGPoint], _ size: CGSize) {
        var bounds: CGRect?
        for node in graph.nodes {
            guard let origin = positions[node.id] else { continue }
            let rect = CGRect(x: origin.x, y: origin.y, width: NodeMetrics.width, height: NodeMetrics.height(node))
            bounds = bounds.map { $0.union(rect) } ?? rect
        }
        guard let bounds, bounds.width > 0, bounds.height > 0, size.width > 80, size.height > 80 else { return }
        let fitted = min((size.width - 60) / bounds.width, (size.height - 70) / bounds.height)
        zoom = min(max(fitted, 0.6), 1)
        offset = CGSize(width: 30 - bounds.minX * zoom, height: 40 - bounds.minY * zoom)
    }

    private func nodeView(_ node: GraphNode, graph: EffectGraph, positions: [String: CGPoint]) -> some View {
        let selected = document.selectionID == node.id
        let hidden = node.visibility.map { document.hidden.contains($0) } ?? false
        let linkable = wire.map { $0.from != node.id && !document.linkOptions($0.from, node.id).options.isEmpty } ?? false
        let linking = linkable && (wire.map { nodeHit(graph, positions, at: $0.point)?.id == node.id } ?? false)
        let relinking = rewire.map { document.canRetarget($0.edge, to: node.id) } ?? false
        let aimed = rewire.map { nodeHit(graph, positions, at: $0.point)?.id == node.id } ?? false
        let target = linking || (relinking && aimed)
        return VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: node.symbol).font(.system(size: 9)).foregroundStyle(.black.opacity(0.75))
                Text(node.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.black.opacity(0.85)).lineLimit(1)
                if document.changes.contains(node.id) {
                    Circle().fill(Color.white).overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1)).frame(width: 6, height: 6)
                        .help("Changed since the file was opened")
                }
                Spacer(minLength: 0)
                if let key = node.visibility {
                    Image(systemName: hidden ? "eye.slash" : "eye").font(.system(size: 9)).foregroundStyle(.black.opacity(0.7))
                        .frame(width: 16, height: NodeMetrics.header).contentShape(Rectangle())
                        .onTapGesture { document.toggleHidden(key) }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: NodeMetrics.header)
            .background(node.tint.color.opacity(hidden ? 0.45 : 1))
            VStack(alignment: .leading, spacing: 0) {
                if let path = node.texturePath {
                    ZStack {
                        CheckerBackground()
                        if let image = app.image(for: path) {
                            Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                        }
                    }
                    .frame(height: NodeMetrics.thumbnail)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(.top, 6)
                }
                ForEach(Array(node.lines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1).frame(height: NodeMetrics.line)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, node.lines.isEmpty && node.texturePath == nil ? 0 : 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: NodeMetrics.width, height: NodeMetrics.height(node), alignment: .top)
        .background(Color(white: 0.19))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(target ? Color.green : linkable ? Color.green.opacity(0.55) : relinking ? Theme.changed.opacity(0.8)
            : selected ? Color.white : Color.black.opacity(0.6), lineWidth: target ? 3 : selected || relinking || linkable ? 2 : 1))
        .overlay(alignment: .topLeading) {
            if !node.id.hasPrefix("avfx/Schd") {
                socket(node, input: true, graph: graph, positions: positions).offset(x: -15, y: NodeMetrics.header / 2 - 15)
            }
        }
        .overlay(alignment: .topTrailing) {
            if node.hasOutput {
                socket(node, input: false, graph: graph, positions: positions).offset(x: 15, y: NodeMetrics.header / 2 - 15)
            }
        }
        .opacity(hidden ? 0.6 : 1)
        .onTapGesture(count: 2) {
            if node.selectable {
                document.selectionID = node.id
                app.openEditor(for: node.id)
            }
        }
        .onTapGesture {
            focused = true
            selectedEdge = nil
            if node.selectable { document.selectionID = node.id }
        }
        .gesture(DragGesture(minimumDistance: 3)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { drag in
                if dragOrigin == nil { dragOrigin = positions[node.id] }
                if let origin = dragOrigin {
                    moved[node.id] = CGPoint(x: origin.x + drag.translation.width / zoom, y: origin.y + drag.translation.height / zoom)
                }
            }
            .onEnded { _ in dragOrigin = nil })
        .contextMenu {
            if let key = node.visibility {
                Button(hidden ? "Show" : "Hide") { document.toggleHidden(key) }
                Button("Isolate") {
                    document.selectionID = node.id
                    document.isolateSelection = true
                }
            }
            if let outline = document.node(node.id) {
                ForEach(outline.actions) { action in
                    Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform)
                }
            }
        }
    }
}
