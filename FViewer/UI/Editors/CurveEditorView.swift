import SwiftUI

private struct KeyRef: Hashable {
    var channel: String
    var index: Int
}

private struct GraphRange: Equatable {
    var t0: Double = -2
    var t1: Double = 62
    var v0: Double = -0.2
    var v1: Double = 1.2
}

enum KeyClipboard {
    static var entries: [(name: String, keys: [CurveKeyPoint])] = []
}

private final class GroupCache {
    var key = ""
    var group: CurveGroup?
    var size = CGSize(width: 400, height: 200)
}

private enum GraphDrag {
    case none
    case scrub
    case keys(origin: [String: [CurveKeyPoint]], selected: [String: Set<Int>], restore: [String: () -> Void])
    case handle(key: KeyRef, outgoing: Bool, restore: () -> Void)
    case box(additive: Bool)
    case scale(origin: [String: [CurveKeyPoint]], selected: [String: Set<Int>], restore: [String: () -> Void], bounds: SIMD4<Double>, handle: Int)
    case idle
}

struct CurveEditorView: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    @State private var range = GraphRange()
    @State private var hidden: Set<String> = []
    @State private var selection: Set<KeyRef> = []
    @State private var activeKey: KeyRef?
    @State private var activeChannel: String?
    @State private var drag = GraphDrag.none
    @State private var boxStart = CGPoint.zero
    @State private var boxEnd = CGPoint.zero
    @State private var measured = CGSize(width: 400, height: 200)
    @FocusState private var focused: Bool

    private let rulerHeight: CGFloat = 18
    private let stripHeight: CGFloat = 12

    @State private var cache = GroupCache()
    @State private var dragActive = false
    @State private var bodyGrab = false
    @AppStorage("curves.radians") private var radians = false
    @AppStorage("curves.palette") private var paletteText = ""
    @AppStorage("curves.saved") private var savedText = ""
    @State private var aim: (key: KeyRef, outgoing: Bool, reach: CGFloat)?
    @State private var ghost: [String: [CurveKeyPoint]] = [:]
    @State private var ghostStamp = 0
    @State private var lastDrag: DragGesture.Value?
    @GestureState private var pressing = false
    @State private var lastClick: (time: Date, point: CGPoint) = (.distantPast, .zero)
    @State private var stopDrag: (track: Int, time: Double, restore: () -> Void, moved: Bool)?
    @State private var stopPicked: (track: Int, time: Double)?
    @State private var stopClick: (time: Date, x: CGFloat) = (.distantPast, 0)

    private var size: CGSize { cache.size }

    private var group: CurveGroup? {
        let key = "\(document.id)|\(document.revision)|\(document.selectionID ?? "")|\(document.activeCurveID ?? "")"
        if cache.key == key { return cache.group }
        cache.key = key
        cache.group = nil
        guard let node = document.selectedNode else { return nil }
        let groups = document.curveGroups(for: node)
        cache.group = groups.first { $0.id == document.activeCurveID } ?? groups.first
        return cache.group
    }

    private func hasGradient(_ group: CurveGroup?) -> Bool { group?.channels.contains { $0.colorComponent != nil } ?? false }
    private var top: CGFloat { rulerHeight + (hasGradient(group) ? stripHeight : 0) }

    private func x(_ t: Double) -> CGFloat { CGFloat((t - range.t0) / (range.t1 - range.t0)) * size.width }
    private func y(_ v: Double) -> CGFloat { size.height - CGFloat((v - range.v0) / (range.v1 - range.v0)) * (size.height - top) }
    private func time(_ px: CGFloat) -> Double { range.t0 + Double(px / max(size.width, 1)) * (range.t1 - range.t0) }
    private func value(_ py: CGFloat) -> Double { range.v0 + Double((size.height - py) / max(size.height - top, 1)) * (range.v1 - range.v0) }

    private func visibleChannels(_ group: CurveGroup) -> [CurveChannel] { group.channels.filter { !hidden.contains($0.id) } }
    private func channel(_ id: String) -> CurveChannel? { group?.channels.first { $0.id == id } }

    private func fit(_ group: CurveGroup?, selectedOnly: Bool = false) {
        guard let group else { return }
        var keys: [CurveKeyPoint] = []
        var low = 0.0, high = 1.0
        var seeded = false
        func include(_ value: Double) {
            if selectedOnly && !seeded {
                low = value
                high = value
                seeded = true
            } else {
                low = min(low, value)
                high = max(high, value)
            }
        }
        for channel in visibleChannels(group) {
            let all = channel.read()
            if selectedOnly {
                let picked = all.enumerated().filter { selection.contains(KeyRef(channel: channel.id, index: $0.offset)) }.map(\.element)
                keys.append(contentsOf: picked)
                picked.forEach { include($0.value) }
            } else {
                keys.append(contentsOf: all)
                guard let first = all.first, let last = all.last else { continue }
                all.forEach { include($0.value) }
                let span = max(last.time - first.time, 1)
                for step in 0...100 { include(CurveMath.sample(all, at: first.time + span * Double(step) / 100)) }
            }
        }
        guard !keys.isEmpty else {
            if !selectedOnly { range = GraphRange() }
            return
        }
        var t0 = 0.0
        var t1 = max(10, keys.map(\.time).max() ?? 10)
        if selectedOnly {
            t0 = keys.map(\.time).min() ?? 0
            t1 = max(t0 + 10, keys.map(\.time).max() ?? 10)
        }
        if high - low < 1e-6 {
            low -= 0.5
            high += 0.5
        }
        let tp = (t1 - t0) * 0.05, vp = (high - low) * 0.1
        range = GraphRange(t0: t0 - tp, t1: t1 + tp, v0: low - vp, v1: high + vp)
    }

    private func gridStep(_ span: Double, target: Double) -> Double {
        let raw = span / max(target, 1)
        let power = pow(10, floor(log10(max(raw, 1e-9))))
        let ratio = raw / power
        return (ratio < 1.5 ? 1 : ratio < 3.5 ? 2 : ratio < 7.5 ? 5 : 10) * power
    }

    private func rate(_ keys: [CurveKeyPoint], _ i: Int) -> (rate: Double, scale: Double) {
        let before: Double? = i >= 1 ? keys[i].time - keys[i - 1].time : nil
        let after: Double? = i + 1 < keys.count ? keys[i + 1].time - keys[i].time : nil
        let scale: Double
        if let before, let after {
            scale = 2 / max(1e-6, before + after)
        } else {
            scale = 1 / max(1e-6, before ?? after ?? 1)
        }
        return (CurveMath.tangent(keys, i) * scale, scale)
    }

    private func handlePoints(_ keys: [CurveKeyPoint], _ i: Int, channel: String) -> (incoming: CGPoint?, outgoing: CGPoint?) {
        guard i < keys.count, keys[i].interpolation == CurveKeyPoint.spline else { return (nil, nil) }
        let key = keys[i]
        let perFrame = size.width / CGFloat(max(range.t1 - range.t0, 1e-9))
        let perValue = (size.height - top) / CGFloat(max(range.v1 - range.v0, 1e-9))
        let dx = perFrame, dy = -CGFloat(rate(keys, i).rate) * perValue
        let length = max(hypot(dx, dy), 1e-6)
        let origin = CGPoint(x: x(key.time), y: y(key.value))
        func reach(_ outgoing: Bool) -> CGFloat {
            if let aim, aim.key == KeyRef(channel: channel, index: i), aim.outgoing == outgoing { return aim.reach }
            return 40
        }
        var incoming: CGPoint?
        var outgoing: CGPoint?
        if i + 1 < keys.count {
            let d = reach(true)
            outgoing = CGPoint(x: origin.x + dx / length * d, y: origin.y + dy / length * d)
        }
        if i >= 1, keys[i - 1].interpolation == CurveKeyPoint.spline {
            let d = reach(false)
            incoming = CGPoint(x: origin.x - dx / length * d, y: origin.y - dy / length * d)
        }
        return (incoming, outgoing)
    }

    var body: some View {
        GeometryReader { outer in
            HStack(spacing: 0) {
                channelList.frame(width: listWidth(outer.size.width))
                Rectangle().fill(Theme.line).frame(width: 1)
                GeometryReader { geometry in
                    sized(geometry.size)
                        .onAppear {
                            cache.size = geometry.size
                            measured = geometry.size
                            fit(group)
                        }
                        .onChange(of: geometry.size) { _, next in
                            cache.size = next
                            measured = next
                        }
                }
                Rectangle().fill(Theme.line).frame(width: 1)
                sidebar.frame(width: sidebarWidth(outer.size.width))
            }
        }
        .background(Theme.gray(0.157))
        .onChange(of: group?.id, initial: true) { _, _ in
            ghost = [:]
            selection = []
            activeKey = nil
            activeChannel = nil
            hidden = []
            fit(group)
        }
    }

    private func sized(_ next: CGSize) -> some View {
        cache.size = next
        return graph
    }

    private func summary(_ group: CurveGroup) -> String {
        let keys = visibleChannels(group).flatMap { $0.read() }
        guard let low = keys.map(\.value).min(), let high = keys.map(\.value).max() else { return "no keys" }
        return "\(keys.count) key\(keys.count == 1 ? "" : "s") · \(String(format: "%.2f", low))…\(String(format: "%.2f", high))"
    }

    private func parameterPicker(_ current: CurveGroup?) -> some View {
        let node = document.selectedNode
        let groups = node.map { document.curveGroups(for: $0) } ?? []
        let constants = node.map { document.sections(for: $0).flatMap(\.fields).filter { $0.animate != nil } } ?? []
        let missing = node.map { document.missingCurves(for: $0) } ?? []
        return Menu {
            ForEach(groups) { group in
                Button((group.id == current?.id ? "✓ " : "") + group.title) { document.activeCurveID = group.id }
            }
            if !constants.isEmpty {
                Divider()
                ForEach(constants) { field in Button("Animate " + field.label) { field.animate?() } }
            }
            if !missing.isEmpty {
                Divider()
                Menu("Add Curve") { ForEach(missing) { curve in Button(curve.title) { curve.create() } } }
            }
        } label: {
            HStack(spacing: 4) {
                Text(current?.title ?? "Parameter").font(.system(size: 11, weight: .semibold)).lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.16)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .help("Every animated parameter of the selected node. A plain number turns into keys the first time it is animated")
    }

    private var channelList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let group {
                    parameterPicker(group)
                    HStack {
                        Text(summary(group)).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                        Spacer()
                        Text(group.isAngle ? "degrees" : "").font(Theme.small).foregroundStyle(Theme.dim)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 16)
                    ForEach(group.channels) { channel in
                        let active = (activeChannel ?? visibleChannels(group).first?.id) == channel.id
                        HStack(spacing: 5) {
                            Image(systemName: hidden.contains(channel.id) ? "eye.slash" : "eye").font(.system(size: 9))
                                .foregroundStyle(Theme.dim).frame(width: 14)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if hidden.contains(channel.id) {
                                        hidden.remove(channel.id)
                                    } else {
                                        hidden.insert(channel.id)
                                        selection = selection.filter { $0.channel != channel.id }
                                        if activeKey?.channel == channel.id { activeKey = nil }
                                    }
                                }
                            RoundedRectangle(cornerRadius: 2).fill(channel.color).frame(width: 10, height: 10)
                            Text(channel.name).font(Theme.font).foregroundStyle(active ? .white : Theme.text).lineLimit(1)
                            if let node = document.selectionID, document.changes.contains(node),
                               document.originalKeys(group: group.id, channel: channel.id, in: node) != channel.read() {
                                ChangeDot()
                            }
                            Spacer(minLength: 0)
                            Text("\(channel.read().count)").font(Theme.small).foregroundStyle(Theme.dim)
                            if let unassign = group.unassign[channel.id], group.channels.count > 1 {
                                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 14, height: 14)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if activeChannel == channel.id { activeChannel = nil }
                                        unassign()
                                    }
                                    .help("Remove this channel from the curve")
                            }
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(active ? Theme.selection : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            hidden = Set(group.channels.map(\.id)).subtracting([channel.id])
                            activeChannel = channel.id
                            fit(group)
                        }
                        .onTapGesture { activeChannel = channel.id }
                        .help("Click: make active · Double-click: show only this channel")
                    }
                    ForEach(group.missing) { entry in
                        HStack(spacing: 5) {
                            Image(systemName: "plus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 14)
                            RoundedRectangle(cornerRadius: 2).stroke(Theme.dim, lineWidth: 1).frame(width: 10, height: 10)
                            Text(entry.title).font(Theme.font).foregroundStyle(Theme.dim).lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture { entry.create() }
                        .help("Add this channel to the curve")
                    }
                } else {
                    parameterPicker(nil)
                }
            }
        }
    }

    private var graph: some View {
        let redrawTriggers = (range, selection, hidden, boxStart, boxEnd, measured, activeChannel, dragActive, document.revision, ghostStamp, radians)
        if case .box = drag { _ = redrawTriggers }
        return Canvas { context, canvasSize in
            _ = redrawTriggers
            let tStep = gridStep(range.t1 - range.t0, target: Double(canvasSize.width) / 70)
            let vStep = gridStep(range.v1 - range.v0, target: Double(canvasSize.height) / 40)
            var t = (range.t0 / tStep).rounded(.down) * tStep
            var gridLines = 0
            while t <= range.t1, gridLines < 400 {
                gridLines += 1
                var line = Path()
                line.move(to: CGPoint(x: x(t), y: top))
                line.addLine(to: CGPoint(x: x(t), y: canvasSize.height))
                context.stroke(line, with: .color(Color.white.opacity(t == 0 ? 0.18 : 0.06)), lineWidth: 1)
                t += tStep
            }
            var v = (range.v0 / vStep).rounded(.down) * vStep
            gridLines = 0
            while v <= range.v1, gridLines < 400 {
                gridLines += 1
                if y(v) > top + 6 {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y(v)))
                    line.addLine(to: CGPoint(x: canvasSize.width, y: y(v)))
                    context.stroke(line, with: .color(Color.white.opacity(abs(v) < vStep / 2 ? 0.18 : 0.06)), lineWidth: 1)
                    let asRadians = group?.isAngle == true && radians
                    let shownValue = asRadians ? v * Double.pi / 180 : v
                    let shownStep = asRadians ? vStep * Double.pi / 180 : vStep
                    let label = String(format: shownStep < 0.1 ? "%.3f" : shownStep < 1 ? "%.2f" : "%.0f", shownValue) + (group?.isAngle == true ? (asRadians ? " rad" : "°") : "")
                    context.draw(Text(label).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: 4, y: y(v) - 7), anchor: .leading)
                }
                v += vStep
            }
            guard let group else {
                drawRuler(&context, canvasSize, tStep)
                return
            }
            for channel in visibleChannels(group) {
                let keys = channel.read()
                guard let first = keys.first, let last = keys.last else { continue }
                let extrapolation = channel.extrapolation()
                var before = Path(), inside = Path(), after = Path()
                var px: CGFloat = 0
                var started = [false, false, false]
                while px <= canvasSize.width {
                    let t = time(px)
                    let point = CGPoint(x: px, y: y(CurveMath.sampleExtended(keys, at: t, pre: extrapolation.pre, post: extrapolation.post)))
                    let part = t < first.time ? 0 : t > last.time ? 2 : 1
                    if part == 0 {
                        if started[0] { before.addLine(to: point) } else { before.move(to: point) }
                    } else if part == 1 {
                        if started[1] { inside.addLine(to: point) } else { inside.move(to: point) }
                    } else {
                        if started[2] { after.addLine(to: point) } else { after.move(to: point) }
                    }
                    started[part] = true
                    px += 2
                }
                if let node = document.selectionID, let was = document.originalKeys(group: group.id, channel: channel.id, in: node), was != keys, !was.isEmpty,
                   ghost[channel.id] == nil || ghost[channel.id] == keys {
                    var old = Path()
                    var gx: CGFloat = 0
                    var begun = false
                    while gx <= canvasSize.width {
                        let point = CGPoint(x: gx, y: y(CurveMath.sampleExtended(was, at: time(gx), pre: extrapolation.pre, post: extrapolation.post)))
                        if begun { old.addLine(to: point) } else { old.move(to: point) }
                        begun = true
                        gx += 2
                    }
                    context.stroke(old, with: .color(Theme.changed.opacity(0.45)), style: StrokeStyle(lineWidth: 1, dash: [1, 3]))
                    for key in was {
                        context.stroke(Path(ellipseIn: CGRect(x: x(key.time) - 2.5, y: y(key.value) - 2.5, width: 5, height: 5)),
                                       with: .color(Theme.changed.opacity(0.55)), lineWidth: 1)
                    }
                }
                if let previous = ghost[channel.id], previous != keys, !previous.isEmpty {
                    var old = Path()
                    var gx: CGFloat = 0
                    var begun = false
                    while gx <= canvasSize.width {
                        let point = CGPoint(x: gx, y: y(CurveMath.sampleExtended(previous, at: time(gx), pre: extrapolation.pre, post: extrapolation.post)))
                        if begun { old.addLine(to: point) } else { old.move(to: point) }
                        begun = true
                        gx += 2
                    }
                    context.stroke(old, with: .color(Color.white.opacity(0.38)), style: StrokeStyle(lineWidth: 1.2, dash: [2, 3]))
                    for key in previous {
                        let dot = CGRect(x: x(key.time) - 3, y: y(key.value) - 3, width: 6, height: 6)
                        context.stroke(Path(ellipseIn: dot), with: .color(Color.white.opacity(0.45)), lineWidth: 1)
                    }
                    for (i, key) in keys.enumerated() where selection.contains(KeyRef(channel: channel.id, index: i)) {
                        let was = previous.min { abs($0.time - key.time) + abs($0.value - key.value) * 0.001 < abs($1.time - key.time) + abs($1.value - key.value) * 0.001 }
                        let old = i < previous.count && previous.count == keys.count ? previous[i] : was
                        guard let old, old != key else { continue }
                        var link = Path()
                        link.move(to: CGPoint(x: x(old.time), y: y(old.value)))
                        link.addLine(to: CGPoint(x: x(key.time), y: y(key.value)))
                        context.stroke(link, with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [1, 2]))
                        let delta = key.value - old.value
                        var text = "F \(JSONNode.format(key.time))  \(String(format: "%.3f", key.value))"
                        if abs(delta) > 1e-6 { text += String(format: "  %@%.3f", delta >= 0 ? "+" : "−", abs(delta)) }
                        if key.time != old.time { text += "  \(key.time > old.time ? "+" : "−")\(JSONNode.format(abs(key.time - old.time)))f" }
                        if key.time == old.time, key.value == old.value {
                            text = String(format: "in %.3f → %.3f   out %.3f → %.3f", old.tangentIn, key.tangentIn, old.tangentOut, key.tangentOut)
                        }
                        let label = context.resolve(Text(text).font(Theme.small).foregroundStyle(.white))
                        let box = label.measure(in: CGSize(width: 260, height: 20))
                        var origin = CGPoint(x: x(key.time) + 10, y: y(key.value) - box.height - 8)
                        origin.x = min(max(origin.x, 2), canvasSize.width - box.width - 10)
                        origin.y = max(origin.y, top + 2)
                        context.fill(Path(roundedRect: CGRect(x: origin.x - 4, y: origin.y - 2, width: box.width + 8, height: box.height + 4), cornerRadius: 3),
                                     with: .color(Color.black.opacity(0.78)))
                        context.draw(label, at: CGPoint(x: origin.x, y: origin.y), anchor: .topLeading)
                    }
                }
                context.stroke(before, with: .color(channel.color.opacity(0.4)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                context.stroke(after, with: .color(channel.color.opacity(0.4)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                context.stroke(inside, with: .color(channel.color), lineWidth: Appearance.curveWidth)
                for (i, key) in keys.enumerated() where channel.colorComponent == nil {
                    let handles = handlePoints(keys, i, channel: channel.id)
                    let chosen = selection.contains(KeyRef(channel: channel.id, index: i))
                    for handle in [handles.incoming, handles.outgoing].compactMap({ $0 }) {
                        var line = Path()
                        line.move(to: CGPoint(x: x(key.time), y: y(key.value)))
                        line.addLine(to: handle)
                        let tint = chosen ? Color(red: 1, green: 0.63, blue: 0.16) : Color(white: 0.62)
                        context.stroke(line, with: .color(tint.opacity(0.9)), lineWidth: 1)
                        context.fill(Path(CGRect(x: handle.x - 3, y: handle.y - 3, width: 6, height: 6)), with: .color(chosen ? tint : Color(white: 0.86)))
                    }
                    if let aim, aim.key == KeyRef(channel: channel.id, index: i) {
                        let label = context.resolve(Text(String(format: "key %d   in %.3f   out %.3f", i, key.tangentIn, key.tangentOut)).font(Theme.small).foregroundStyle(.white))
                        let box = label.measure(in: CGSize(width: 260, height: 20))
                        let at = CGPoint(x: min(max(x(key.time) + 12, 2), canvasSize.width - box.width - 10), y: max(y(key.value) + 10, top + 2))
                        context.fill(Path(roundedRect: CGRect(x: at.x - 4, y: at.y - 2, width: box.width + 8, height: box.height + 4), cornerRadius: 3),
                                     with: .color(Color.black.opacity(0.78)))
                        context.draw(label, at: at, anchor: .topLeading)
                    }
                }
                for (i, key) in keys.enumerated() {
                    let isSelected = selection.contains(KeyRef(channel: channel.id, index: i))
                    let center = CGPoint(x: x(key.time), y: y(key.value))
                    let r: CGFloat = isSelected ? Appearance.selectedSize : Appearance.pointSize
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    var shape = Path(ellipseIn: rect)
                    if key.interpolation == CurveKeyPoint.step { shape = Path(rect) }
                    if key.interpolation == CurveKeyPoint.linear && channel.colorComponent == nil {
                        shape = Path()
                        shape.move(to: CGPoint(x: center.x, y: center.y - r - 1))
                        shape.addLine(to: CGPoint(x: center.x + r + 1, y: center.y))
                        shape.addLine(to: CGPoint(x: center.x, y: center.y + r + 1))
                        shape.addLine(to: CGPoint(x: center.x - r - 1, y: center.y))
                        shape.closeSubpath()
                    }
                    context.fill(shape, with: .color(isSelected ? Color.white : Color.black))
                    context.stroke(shape, with: .color(isSelected ? Appearance.selectedColor : channel.color), lineWidth: 1.5)
                }
            }
            if let bounds = selectionBounds() {
                let rect = transformRect(bounds)
                context.stroke(Path(rect), with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                for corner in transformHandles(rect) {
                    let grip = CGRect(x: corner.x - 3.5, y: corner.y - 3.5, width: 7, height: 7)
                    context.fill(Path(grip), with: .color(Color.white))
                    context.stroke(Path(grip), with: .color(Color(red: 1, green: 0.63, blue: 0.16)), lineWidth: 1)
                }
            }
            if case .box = drag {
                let rect = CGRect(x: min(boxStart.x, boxEnd.x), y: min(boxStart.y, boxEnd.y), width: abs(boxEnd.x - boxStart.x), height: abs(boxEnd.y - boxStart.y))
                context.fill(Path(rect), with: .color(Color.white.opacity(0.06)))
                context.stroke(Path(rect), with: .color(Color.white.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            drawRuler(&context, canvasSize, tStep)
            if hasGradient(group) {
                let red = group.channels.first { $0.colorComponent == 0 }?.read() ?? []
                let green = group.channels.first { $0.colorComponent == 1 }?.read() ?? []
                let blue = group.channels.first { $0.colorComponent == 2 }?.read() ?? []
                var px: CGFloat = 0
                while px < canvasSize.width {
                    let t = time(px)
                    let color = Color(.sRGB, red: CurveMath.sample(red, at: t), green: CurveMath.sample(green, at: t), blue: CurveMath.sample(blue, at: t))
                    context.fill(Path(CGRect(x: px, y: rulerHeight, width: 3, height: stripHeight)), with: .color(color))
                    px += 3
                }
            }
            let px = x(clock.time)
            var playhead = Path()
            playhead.move(to: CGPoint(x: px, y: 0))
            playhead.addLine(to: CGPoint(x: px, y: canvasSize.height))
            context.stroke(playhead, with: .color(Theme.playhead), lineWidth: 1.5)
            let box = CGRect(x: px - 16, y: 1, width: 32, height: rulerHeight - 2)
            context.fill(Path(roundedRect: box, cornerRadius: 3), with: .color(Theme.playhead))
            context.draw(Text(JSONNode.format(clock.time.rounded())).font(Theme.small).foregroundStyle(.white), at: CGPoint(x: px, y: rulerHeight / 2))
        }
        .background(ScrollMonitor(
            onScroll: { delta, flags, point in
                if flags.contains(.command) {
                    zoom(1 - Double(delta.height) * 0.01, at: point, horizontal: true, vertical: true)
                } else if flags.contains(.control) {
                    zoom(1 - Double(delta.height) * 0.01, at: point, horizontal: true, vertical: false)
                } else if flags.contains(.option) {
                    zoom(1 - Double(delta.height) * 0.01, at: point, horizontal: false, vertical: true)
                } else {
                    let dt = Double(delta.width / max(size.width, 1)) * (range.t1 - range.t0)
                    let dv = Double(delta.height / max(size.height, 1)) * (range.v1 - range.v0)
                    range = GraphRange(t0: range.t0 - dt, t1: range.t1 - dt, v0: range.v0 + dv, v1: range.v1 + dv)
                }
            },
            onMagnify: { amount, point in zoom(1 - Double(amount), at: point, horizontal: true, vertical: true) }))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged {
                lastDrag = $0
                handleDrag($0)
            }
            .onEnded {
                endDrag($0)
                lastDrag = nil
            })
        .onChange(of: pressing) { _, now in
            if !now, let last = lastDrag {
                endDrag(last)
                lastDrag = nil
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress { press in
            switch AppShortcuts.canonical(press.characters) {
            case "x", "\u{7f}", "\u{8}":
                deleteSelected()
            case " ":
                clock.playing.toggle()
            case "t":
                cycleInterpolation()
            case "a":
                if press.modifiers.contains(.option) { selection = [] } else { selectAll() }
            case "\u{1b}":
                selection = []
            case "\u{F729}":
                fit(group)
            case ".":
                fit(group, selectedOnly: !selection.isEmpty)
            case "i":
                insertAtPlayhead()
            case "c":
                guard press.modifiers.contains(.command) else { return .ignored }
                copyKeys()
            case "v":
                guard press.modifiers.contains(.command) else { return .ignored }
                pasteKeys()
            default: return .ignored
            }
            return .handled
        }
    }

    private func drawRuler(_ context: inout GraphicsContext, _ canvasSize: CGSize, _ tStep: Double) {
        context.fill(Path(CGRect(x: 0, y: 0, width: canvasSize.width, height: rulerHeight)), with: .color(Color(white: 0.11)))
        var t = (range.t0 / tStep).rounded(.down) * tStep
        while t <= range.t1 {
            context.draw(Text(JSONNode.format(t)).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: x(t) + 3, y: 9), anchor: .leading)
            t += tStep
        }
    }

    private func zoom(_ factor: Double, at point: CGPoint, horizontal: Bool, vertical: Bool) {
        let f = min(max(factor, 0.5), 2)
        let t = time(point.x), v = value(point.y)
        var next = range
        if horizontal {
            next.t0 = t + (range.t0 - t) * f
            next.t1 = t + (range.t1 - t) * f
        }
        if vertical {
            next.v0 = v + (range.v0 - v) * f
            next.v1 = v + (range.v1 - v) * f
        }
        if next.t1 - next.t0 > 0.5 && next.v1 - next.v0 > 1e-5 { range = next }
    }

    private func hitKey(_ point: CGPoint) -> KeyRef? {
        guard let group else { return nil }
        var best: (KeyRef, CGFloat)?
        for channel in visibleChannels(group) {
            for (i, key) in channel.read().enumerated() {
                let d = hypot(x(key.time) - point.x, y(key.value) - point.y)
                if d < Appearance.grabDistance, d < (best?.1 ?? .infinity) { best = (KeyRef(channel: channel.id, index: i), d) }
            }
        }
        return best?.0
    }

    private func hitHandle(_ point: CGPoint) -> (KeyRef, Bool)? {
        guard let group else { return nil }
        for channel in visibleChannels(group) where channel.colorComponent == nil {
            let keys = channel.read()
            for index in keys.indices {
                let handles = handlePoints(keys, index, channel: channel.id)
                if let h = handles.outgoing, hypot(h.x - point.x, h.y - point.y) < 9 { return (KeyRef(channel: channel.id, index: index), true) }
                if let h = handles.incoming, hypot(h.x - point.x, h.y - point.y) < 9 { return (KeyRef(channel: channel.id, index: index), false) }
            }
        }
        return nil
    }

    private func selectionBounds() -> SIMD4<Double>? {
        var times: [Double] = [], values: [Double] = []
        for ref in selection {
            guard let keys = channel(ref.channel)?.read(), ref.index < keys.count else { continue }
            times.append(keys[ref.index].time)
            values.append(keys[ref.index].value)
        }
        guard times.count > 1, let t0 = times.min(), let t1 = times.max(), let v0 = values.min(), let v1 = values.max() else { return nil }
        return SIMD4(t0, t1, v0, v1)
    }

    private func transformRect(_ bounds: SIMD4<Double>) -> CGRect {
        CGRect(x: x(bounds.x), y: y(bounds.w), width: x(bounds.y) - x(bounds.x), height: y(bounds.z) - y(bounds.w)).insetBy(dx: -10, dy: -10)
    }

    private func transformHandles(_ rect: CGRect) -> [CGPoint] {
        [0, 1, 2, 3, 4, 5, 6, 7].map { index -> CGPoint in
            let column = [0, 1, 2, 0, 2, 0, 1, 2][index], row = [0, 0, 0, 1, 1, 2, 2, 2][index]
            return CGPoint(x: rect.minX + rect.width * CGFloat(column) / 2, y: rect.minY + rect.height * CGFloat(row) / 2)
        }
    }

    private func hitTransformHandle(_ point: CGPoint) -> (handle: Int, bounds: SIMD4<Double>)? {
        guard let bounds = selectionBounds() else { return nil }
        for (index, corner) in transformHandles(transformRect(bounds)).enumerated() where hypot(corner.x - point.x, corner.y - point.y) < 7 {
            return (index, bounds)
        }
        return nil
    }

    private func writeMoved(_ origin: [String: [CurveKeyPoint]], _ selected: [String: Set<Int>], _ map: (CurveKeyPoint) -> CurveKeyPoint) {
        var nextSelection: Set<KeyRef> = []
        for (id, keys) in origin {
            guard let channel = channel(id) else { continue }
            let marks = selected[id] ?? []
            var moved = keys.enumerated().map { index, key -> (CurveKeyPoint, Bool) in
                guard marks.contains(index) else { return (key, false) }
                var next = map(key)
                next.time = max(0, next.time.rounded())
                next.value = (next.value * 1000).rounded() / 1000
                if channel.clampUnit { next.value = min(max(next.value, 0), 1) }
                return (next, true)
            }
            moved = moved.enumerated().sorted { a, b in
                a.element.0.time != b.element.0.time ? a.element.0.time < b.element.0.time : a.offset < b.offset
            }.map(\.element)
            for i in 1..<max(moved.count, 1) where moved[i].0.time <= moved[i - 1].0.time {
                moved[i].0.time = moved[i - 1].0.time + 1
            }
            channel.write(moved.map(\.0))
            for (i, entry) in moved.enumerated() where entry.1 { nextSelection.insert(KeyRef(channel: id, index: i)) }
        }
        selection = nextSelection
        if let active = activeKey, !nextSelection.contains(active) { activeKey = nextSelection.first { $0.channel == active.channel } }
        document.liveDrag()
    }

    private func beginScaleDrag(_ handle: Int, _ bounds: SIMD4<Double>) {
        beginKeyDrag()
        if case .keys(let origin, let selected, let restore) = drag {
            drag = .scale(origin: origin, selected: selected, restore: restore, bounds: bounds, handle: handle)
        }
    }

    private func beginKeyDrag() {
        var origin: [String: [CurveKeyPoint]] = [:]
        var selected: [String: Set<Int>] = [:]
        var restore: [String: () -> Void] = [:]
        for ref in selection {
            guard let channel = channel(ref.channel) else { continue }
            if origin[ref.channel] == nil {
                origin[ref.channel] = channel.read()
                restore[ref.channel] = channel.snapshot()
            }
            selected[ref.channel, default: []].insert(ref.index)
        }
        ghost = origin
        drag = .keys(origin: origin, selected: selected, restore: restore)
    }

    private func handleDrag(_ gesture: DragGesture.Value) {
        if case .none = drag {
            focused = true
            ghost = [:]
            ghostStamp += 1
            let flags = NSApp.currentEvent?.modifierFlags ?? NSEvent.modifierFlags
            let shift = flags.contains(.shift), command = flags.contains(.command), option = flags.contains(.option)
            if gesture.startLocation.y < rulerHeight {
                drag = .scrub
            } else if let grip = hitTransformHandle(gesture.startLocation) {
                beginScaleDrag(grip.handle, grip.bounds)
            } else if let (ref, outgoing) = hitHandle(gesture.startLocation), let channel = channel(ref.channel) {
                ghost = [channel.id: channel.read()]
                aim = (ref, outgoing, 40)
                activeKey = ref
                activeChannel = ref.channel
                if !selection.contains(ref) { selection = [ref] }
                drag = .handle(key: ref, outgoing: outgoing, restore: channel.snapshot())
            } else if let hit = hitKey(gesture.startLocation), let channel = channel(hit.channel) {
                activeChannel = hit.channel
                if option {
                    if channel.read().count > 1 {
                        change(channel, "Delete Keyframe") { keys in if hit.index < keys.count { keys.remove(at: hit.index) } }
                        selection = []
                        activeKey = nil
                    }
                    drag = .idle
                } else if shift, channel.colorComponent == nil {
                    change(channel, "Toggle Spline") { keys in
                        guard hit.index < keys.count else { return }
                        if keys[hit.index].interpolation == CurveKeyPoint.spline {
                            keys[hit.index].interpolation = CurveKeyPoint.linear
                        } else {
                            keys[hit.index].interpolation = CurveKeyPoint.spline
                            keys[hit.index].tangentIn = 1
                            keys[hit.index].tangentOut = 1
                        }
                    }
                    selection = [hit]
                    activeKey = hit
                    drag = .idle
                } else {
                    if command {
                        if selection.contains(hit) { selection.remove(hit) } else { selection.insert(hit) }
                    } else if !selection.contains(hit) {
                        selection = [hit]
                    }
                    activeKey = hit
                    beginKeyDrag()
                }
            } else if !command, !shift, let bounds = selectionBounds(), transformRect(bounds).contains(gesture.startLocation) {
                beginKeyDrag()
                bodyGrab = true
            } else {
                boxStart = gesture.startLocation
                boxEnd = gesture.startLocation
                drag = .box(additive: command || shift)
            }
        }
        switch drag {
        case .scrub:
            clock.time = max(0, time(gesture.location.x).rounded())
        case .keys(let origin, let selected, _):
            if hypot(gesture.translation.width, gesture.translation.height) > 3 { dragActive = true }
            guard dragActive else { return }
            let dt = (Double(gesture.translation.width / max(size.width, 1)) * (range.t1 - range.t0)).rounded()
            var dv = -Double(gesture.translation.height / max(size.height - top, 1)) * (range.v1 - range.v0)
            let flags = NSApp.currentEvent?.modifierFlags ?? NSEvent.modifierFlags
            if flags.contains(.control) {
                let step = gridStep(range.v1 - range.v0, target: Double(size.height) / 40) / 10
                dv = (dv / step).rounded() * step
            }
            let lockTime = false
            var nextSelection: Set<KeyRef> = []
            for (id, keys) in origin {
                guard let channel = channel(id) else { continue }
                let marks = selected[id] ?? []
                var moved = keys.enumerated().map { index, key -> (CurveKeyPoint, Bool) in
                    guard marks.contains(index) else { return (key, false) }
                    var next = key
                    if !lockTime { next.time = max(0, key.time + dt) }
                    next.value = dv == 0 ? key.value : ((key.value + dv) * 1000).rounded() / 1000
                    if channel.clampUnit { next.value = min(max(next.value, 0), 1) }
                    return (next, true)
                }
                moved = moved.enumerated().sorted { a, b in
                    a.element.0.time != b.element.0.time ? a.element.0.time < b.element.0.time : a.offset < b.offset
                }.map(\.element)
                for i in 1..<max(moved.count, 1) where moved[i].0.time <= moved[i - 1].0.time {
                    moved[i].0.time = moved[i - 1].0.time + 1
                }
                channel.write(moved.map(\.0))
                for (i, entry) in moved.enumerated() where entry.1 { nextSelection.insert(KeyRef(channel: id, index: i)) }
            }
            selection = nextSelection
            if let active = activeKey, !nextSelection.contains(active) { activeKey = nextSelection.first { $0.channel == active.channel } }
            document.liveDrag()
        case .scale(let origin, let selected, _, let bounds, let handle):
            if hypot(gesture.translation.width, gesture.translation.height) > 2 { dragActive = true }
            guard dragActive else { return }
            let column = [0, 1, 2, 0, 2, 0, 1, 2][handle], row = [0, 0, 0, 1, 1, 2, 2, 2][handle]
            var timeFactor = 1.0, valueFactor = 1.0
            let timeAnchor = column == 0 ? bounds.y : bounds.x, valueAnchor = row == 0 ? bounds.z : bounds.w
            if column != 1, bounds.y - bounds.x > 1e-9 {
                let grabbed = column == 0 ? bounds.x : bounds.y
                timeFactor = (time(gesture.location.x + (column == 0 ? 10 : -10)) - timeAnchor) / (grabbed - timeAnchor)
            }
            if row != 1, bounds.w - bounds.z > 1e-9 {
                let grabbed = row == 0 ? bounds.w : bounds.z
                valueFactor = (value(gesture.location.y + (row == 0 ? 10 : -10)) - valueAnchor) / (grabbed - valueAnchor)
            }
            writeMoved(origin, selected) { key in
                var next = key
                next.time = timeAnchor + (key.time - timeAnchor) * timeFactor
                next.value = valueAnchor + (key.value - valueAnchor) * valueFactor
                return next
            }
        case .handle(let ref, let outgoing, _):
            guard let channel = channel(ref.channel) else { return }
            var keys = channel.read()
            guard ref.index < keys.count else { return }
            let key = keys[ref.index]
            let origin = CGPoint(x: x(key.time), y: y(key.value))
            let px = gesture.location.x - origin.x, py = gesture.location.y - origin.y
            aim = (ref, outgoing, max(12, hypot(px, py)))
            let frames = Double(px / max(size.width, 1)) * (range.t1 - range.t0)
            if (outgoing && frames <= 0.01) || (!outgoing && frames >= -0.01) {
                ghostStamp += 1
                return
            }
            let values = -Double(py / max(size.height - top, 1)) * (range.v1 - range.v0)
            let parts = CurveMath.tangentParts(keys, ref.index)
            let slope = values / frames / rate(keys, ref.index).scale
            func rounded(_ v: Double) -> Double { (v * 1000).rounded() / 1000 }
            func solveOut() { keys[ref.index].tangentOut = rounded((2 * slope - key.tangentIn * parts.fromPrevious) / parts.toNext) }
            func solveIn() { keys[ref.index].tangentIn = rounded((2 * slope - key.tangentOut * parts.toNext) / parts.fromPrevious) }
            if outgoing {
                if abs(parts.toNext) > 1e-9 { solveOut() } else if abs(parts.fromPrevious) > 1e-9 { solveIn() }
            } else {
                if abs(parts.fromPrevious) > 1e-9 { solveIn() } else if abs(parts.toNext) > 1e-9 { solveOut() }
            }
            channel.write(keys)
            ghostStamp += 1
            document.liveDrag()
        case .box:
            boxEnd = gesture.location
        case .none, .idle: break
        }
    }

    private func endDrag(_ gesture: DragGesture.Value) {
        switch drag {
        case .keys(_, _, let restore):
            if dragActive {
                let after = restore.keys.compactMap { id in channel(id).map { $0.snapshot() } }
                let before = Array(restore.values)
                document.registerUndo("Move Keyframes", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
            } else if bodyGrab {
                selection = []
                activeKey = nil
            }
        case .scale(_, _, let restore, _, _):
            if dragActive {
                let after = restore.keys.compactMap { id in channel(id).map { $0.snapshot() } }
                let before = Array(restore.values)
                document.registerUndo("Scale Keyframes", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
            }
        case .handle(let ref, _, let restore):
            if let channel = channel(ref.channel) {
                document.registerUndo("Adjust Handle", undo: restore, redo: channel.snapshot())
            }
        case .box(let additive):
            let rect = CGRect(x: min(boxStart.x, boxEnd.x), y: min(boxStart.y, boxEnd.y), width: abs(boxEnd.x - boxStart.x), height: abs(boxEnd.y - boxStart.y))
            var picked: Set<KeyRef> = additive ? selection : []
            if rect.width > 3 || rect.height > 3, let group {
                for channel in visibleChannels(group) {
                    for (i, key) in channel.read().enumerated() where rect.contains(CGPoint(x: x(key.time), y: y(key.value))) {
                        picked.insert(KeyRef(channel: channel.id, index: i))
                    }
                }
            }
            selection = picked
            activeKey = picked.first
            if rect.width <= 3, rect.height <= 3 {
                let now = Date()
                if now.timeIntervalSince(lastClick.time) < NSEvent.doubleClickInterval,
                   hypot(lastClick.point.x - gesture.location.x, lastClick.point.y - gesture.location.y) < 5 {
                    addKey(at: gesture.location)
                    lastClick = (.distantPast, .zero)
                } else {
                    lastClick = (now, gesture.location)
                }
            }
        default: break
        }
        drag = .none
        dragActive = false
        bodyGrab = false
        aim = nil
    }

    private func change(_ channel: CurveChannel, _ title: String, _ edit: (inout [CurveKeyPoint]) -> Void) {
        let before = channel.snapshot()
        var keys = channel.read()
        edit(&keys)
        channel.write(keys)
        document.registerUndo(title, undo: before, redo: channel.snapshot())
    }

    private func changeSelected(_ title: String, _ edit: (inout [CurveKeyPoint], Set<Int>) -> Void) {
        let byChannel = Dictionary(grouping: selection.filter { !hidden.contains($0.channel) }, by: \.channel)
        let picked = byChannel.compactMap { id, refs in channel(id).map { (channel: $0, indices: Set(refs.map(\.index))) } }
        guard !picked.isEmpty else { return }
        let before = picked.map { $0.channel.snapshot() }
        let shared = picked.filter { $0.channel.colorComponent != nil }.sorted { ($0.channel.colorComponent ?? 0) < ($1.channel.colorComponent ?? 0) }
        for entry in picked where entry.channel.colorComponent == nil {
            var keys = entry.channel.read()
            edit(&keys, entry.indices)
            entry.channel.write(keys)
        }
        if let first = shared.first {
            let bases = shared.map { $0.channel.read() }
            var trials = bases
            for at in shared.indices { edit(&trials[at], shared[at].indices) }
            if zip(trials, bases).contains(where: { $0.count != $1.count }) {
                var keys = bases[0]
                edit(&keys, shared.reduce(into: Set<Int>()) { $0.formUnion($1.indices) })
                first.channel.write(keys)
            } else {
                let count = bases[0].count
                var times = bases[0].map(\.time)
                for index in 0..<count {
                    for at in shared.indices where index < trials[at].count && trials[at][index].time != bases[at][index].time {
                        times[index] = trials[at][index].time
                        break
                    }
                }
                for at in shared.indices { for index in 0..<min(count, trials[at].count) { trials[at][index].time = times[index] } }
                let order = (0..<count).sorted { times[$0] != times[$1] ? times[$0] < times[$1] : $0 < $1 }
                for at in shared.indices {
                    shared[at].channel.write(at == 0 ? trials[at] : order.filter { $0 < trials[at].count }.map { trials[at][$0] })
                }
            }
        }
        let after = picked.map { $0.channel.snapshot() }
        document.registerUndo(title, undo: { before.forEach { $0() } }, redo: { after.forEach { $0() } })
    }

    private func currentChannel() -> CurveChannel? {
        guard let group else { return nil }
        let visible = visibleChannels(group)
        return visible.first { $0.id == activeChannel } ?? visible.first
    }

    private func selectAll() {
        guard let group else { return }
        var all: Set<KeyRef> = []
        for channel in visibleChannels(group) {
            for i in channel.read().indices { all.insert(KeyRef(channel: channel.id, index: i)) }
        }
        selection = all
    }

    private func addKey(at location: CGPoint) {
        guard location.y > top, let channel = currentChannel() else { return }
        let t = max(0, time(location.x).rounded())
        var v = (value(location.y) * 1000).rounded() / 1000
        if channel.clampUnit { v = min(max(v, 0), 1) }
        insertKey(channel, at: t, value: v)
    }

    private func insertAtPlayhead() {
        if let channel = currentChannel() { insertKey(channel, at: clock.time.rounded()) }
    }

    private func insertKey(_ channel: CurveChannel, at t: Double, value fixed: Double? = nil) {
        let existing = channel.read()
        if existing.contains(where: { $0.time == t }) { return }
        let extrapolation = channel.extrapolation()
        let v = fixed ?? (existing.isEmpty ? 0 : CurveMath.sampleExtended(existing, at: t, pre: extrapolation.pre, post: extrapolation.post))
        change(channel, "Insert Keyframe") { keys in
            let interpolation = keys.last(where: { $0.time <= t })?.interpolation ?? keys.first?.interpolation ?? CurveKeyPoint.linear
            keys.append(CurveKeyPoint(time: t, value: v, interpolation: interpolation, tangentOut: 1, tangentIn: 1))
            keys.sort { $0.time < $1.time }
        }
        if let index = channel.read().firstIndex(where: { $0.time == t }) {
            let ref = KeyRef(channel: channel.id, index: index)
            selection = [ref]
            activeKey = ref
        }
    }

    private func resetCurve() {
        guard let group, let node = document.selectionID else { return }
        var before: [() -> Void] = []
        var after: [() -> Void] = []
        for channel in group.channels {
            guard let was = document.originalKeys(group: group.id, channel: channel.id, in: node), was != channel.read() else { continue }
            before.append(channel.snapshot())
            channel.write(was)
            after.append(channel.snapshot())
        }
        guard !before.isEmpty else { return }
        document.registerUndo("Reset Curve", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
        selection = []
        activeKey = nil
    }

    private func copyKeys() {
        guard let group, !selection.isEmpty else { return }
        var copied: [(name: String, keys: [CurveKeyPoint])] = []
        for channel in group.channels {
            let all = channel.read()
            let picked = all.enumerated().filter { selection.contains(KeyRef(channel: channel.id, index: $0.offset)) }.map(\.element)
            if !picked.isEmpty { copied.append((channel.name, picked)) }
        }
        let start = copied.flatMap(\.keys).map(\.time).min() ?? 0
        KeyClipboard.entries = copied.map { entry in
            (entry.name, entry.keys.map { key in
                var shifted = key
                shifted.time -= start
                return shifted
            })
        }
    }

    static let presets: [(name: String, points: [(Double, Double)], spline: Bool)] = [
        ("Hold", [(0, 1), (1, 1)], false), ("Rise", [(0, 0), (1, 1)], false), ("Fade", [(0, 1), (1, 0)], false),
        ("Soft Fade", [(0, 1), (0.6, 1), (1, 0)], true), ("Warm Up", [(0, 0), (0.3, 1), (1, 1)], true), ("Snap In", [(0, 0), (0.1, 1), (1, 1)], false),
        ("Pulse", [(0, 0), (0.5, 1), (1, 0)], true), ("Late Pop", [(0, 0), (0.7, 0), (1, 1)], false), ("S-Curve", [(0, 0), (0.5, 0.5), (1, 1)], true),
        ("Blink", [(0, 1), (0.45, 1), (0.5, 0), (0.55, 1), (1, 1)], false),
    ]

    private var savedPresets: [(name: String, points: [(Double, Double)], spline: Bool)] {
        savedText.split(separator: "|").compactMap { entry -> (name: String, points: [(Double, Double)], spline: Bool)? in
            let parts = entry.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let fields = parts[1].split(separator: ";")
            guard let flag = fields.first else { return nil }
            let points = fields.dropFirst().compactMap { pair -> (Double, Double)? in
                let numbers = pair.split(separator: ",").compactMap { Double($0) }
                return numbers.count == 2 ? (numbers[0], numbers[1]) : nil
            }
            return points.count > 1 ? (String(parts[0]), points, flag == "s") : nil
        }
    }

    private func savePreset() {
        guard let channel = currentChannel() else { return }
        let keys = channel.read()
        guard keys.count > 1, let first = keys.map(\.time).min(), let last = keys.map(\.time).max(), last > first else { return }
        let alert = NSAlert()
        alert.messageText = "Save Curve Preset"
        alert.informativeText = "The shape of the active channel is saved under this name. Saving under an existing name replaces it."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 22))
        field.stringValue = channel.name
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        storePreset(field.stringValue, keys)
    }

    func storePreset(_ rawName: String, _ keys: [CurveKeyPoint]) {
        let name = rawName.replacingOccurrences(of: "|", with: " ").replacingOccurrences(of: "=", with: " ").trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let first = keys.map(\.time).min(), let last = keys.map(\.time).max(), last > first else { return }
        let low = keys.map(\.value).min() ?? 0, high = keys.map(\.value).max() ?? 1
        let span = max(high - low, 1e-9)
        let spline = keys.contains { $0.interpolation == CurveKeyPoint.spline }
        let body = keys.map { String(format: "%.4f,%.4f", ($0.time - first) / (last - first), high - low < 1e-9 ? 1 : ($0.value - low) / span) }
        var entries = savedText.split(separator: "|").map(String.init).filter { !$0.hasPrefix(name + "=") }
        entries.append(name + "=" + (spline ? "s" : "l") + ";" + body.joined(separator: ";"))
        savedText = entries.joined(separator: "|")
    }

    private func removeSavedPreset(_ name: String) {
        savedText = savedText.split(separator: "|").map(String.init).filter { !$0.hasPrefix(name + "=") }.joined(separator: "|")
    }

    private func applyPreset(_ index: Int) {
        guard index < CurveEditorView.presets.count else { return }
        applyShape(CurveEditorView.presets[index])
    }

    private func applyShape(_ preset: (name: String, points: [(Double, Double)], spline: Bool)) {
        guard let channel = currentChannel() else { return }
        let keys = channel.read()
        let first = keys.map(\.time).min() ?? 0
        var last = keys.map(\.time).max() ?? 0
        if last - first < 1 { last = first + max(1, (document.clock.endFrame ?? document.sequencerRows.map(\.end).max() ?? 30).rounded()) }
        var low = keys.map(\.value).min() ?? 0, high = keys.map(\.value).max() ?? 1
        if high - low < 1e-6 {
            low = channel.clampUnit ? 0 : min(0, high)
            high = high == 0 ? 1 : max(high, 0)
        }
        var made: [CurveKeyPoint] = []
        for point in preset.points {
            let time = (first + point.0 * (last - first)).rounded()
            if made.last?.time == time { made.removeLast() }
            made.append(CurveKeyPoint(time: time, value: low + point.1 * (high - low), interpolation: preset.spline ? CurveKeyPoint.spline : CurveKeyPoint.linear,
                                      tangentOut: 1, tangentIn: 1))
        }
        let before = channel.snapshot()
        channel.write(made)
        let after = channel.snapshot()
        document.registerUndo("Curve Preset " + preset.name, undo: before, redo: after)
        selection = []
        activeKey = nil
        if let group { fit(group) }
    }

    private func optimizeKeys(_ tolerance: Double) {
        guard let group else { return }
        var before: [() -> Void] = []
        var after: [() -> Void] = []
        for channel in visibleChannels(group) where channel.colorComponent == nil {
            var keys = channel.read()
            guard keys.count > 2 else { continue }
            let span = max((keys.map(\.value).max() ?? 0) - (keys.map(\.value).min() ?? 0), 1e-6)
            var index = 1
            var changed = false
            while index < keys.count - 1 {
                let a = keys[index - 1], b = keys[index], c = keys[index + 1]
                let straight = a.interpolation == CurveKeyPoint.linear && b.interpolation == CurveKeyPoint.linear
                let expected = a.value + (c.value - a.value) * (b.time - a.time) / max(c.time - a.time, 1e-9)
                if straight, abs(expected - b.value) <= tolerance * span {
                    keys.remove(at: index)
                    changed = true
                } else {
                    index += 1
                }
            }
            guard changed else { continue }
            before.append(channel.snapshot())
            channel.write(keys)
            after.append(channel.snapshot())
        }
        guard !before.isEmpty else { return }
        document.registerUndo("Optimize Curve", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
        selection = []
        activeKey = nil
    }

    private func clearKeys() {
        guard let group, document.format == .avfx else { return }
        var before: [() -> Void] = []
        var after: [() -> Void] = []
        for channel in visibleChannels(group) where !channel.read().isEmpty {
            before.append(channel.snapshot())
            channel.write([])
            after.append(channel.snapshot())
        }
        guard !before.isEmpty else { return }
        document.registerUndo("Clear Keyframes", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
        selection = []
        activeKey = nil
    }

    private func keyTable(_ channel: CurveChannel) -> some View {
        let keys = channel.read()
        let unit = group?.isAngle == true && radians ? Double.pi / 180 : 1
        return VStack(spacing: 2) {
            ForEach(Array(keys.enumerated().prefix(64)), id: \.offset) { index, key in
                let ref = KeyRef(channel: channel.id, index: index)
                HStack(spacing: 3) {
                    NumberField(label: nil, value: key.time, isInteger: true, onLive: { _ in },
                                onCommit: { _, next in
                                    change(channel, "Key Frame") { keys in if index < keys.count { keys[index].time = max(0, next.rounded()) } }
                                })
                        .frame(width: 44)
                    NumberField(label: nil, value: key.value * unit, step: 0.01, digits: 3, onLive: { _ in },
                                onCommit: { _, next in
                                    change(channel, "Key Value") { keys in
                                        guard index < keys.count else { return }
                                        keys[index].value = channel.clampUnit ? min(max(next / unit, 0), 1) : next / unit
                                    }
                                })
                    if channel.colorComponent == nil {
                        Text(["S", "L", "St"][min(max(key.interpolation, 0), 2)]).font(Theme.small).foregroundStyle(Theme.text)
                            .frame(width: 20, height: 20).background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                change(channel, "Set Interpolation") { keys in if index < keys.count { keys[index].interpolation = (keys[index].interpolation + 1) % 3 } }
                            }
                            .help("Interpolation: Spline, Linear or Step. Click to cycle")
                    }
                    Image(systemName: "plus.square.on.square").font(.system(size: 9)).foregroundStyle(Theme.dim).frame(width: 16, height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            change(channel, "Duplicate Keyframe") { keys in
                                guard index < keys.count else { return }
                                var copy = keys[index]
                                copy.time += 1
                                while keys.contains(where: { $0.time == copy.time }) { copy.time += 1 }
                                keys.append(copy)
                                keys.sort { $0.time < $1.time }
                            }
                        }
                        .help("Duplicate this key one frame later")
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 16, height: 20)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            change(channel, "Delete Keyframe") { keys in if index < keys.count { keys.remove(at: index) } }
                            selection = []
                            activeKey = nil
                        }
                        .help("Delete this key")
                }
                .padding(.horizontal, 2)
                .background(RoundedRectangle(cornerRadius: 4).fill(selection.contains(ref) ? Theme.selection.opacity(0.6) : Color.clear))
            }
        }
    }

    private func pasteKeys(replace: Bool = false) {
        guard let group, !KeyClipboard.entries.isEmpty else { return }
        let at = replace ? 0 : clock.time.rounded()
        var before: [() -> Void] = []
        var after: [() -> Void] = []
        var pasted: Set<KeyRef> = []
        for entry in KeyClipboard.entries {
            let target = group.channels.first { $0.name == entry.name && !hidden.contains($0.id) }
                ?? (KeyClipboard.entries.count == 1 ? currentChannel() : nil)
            guard let target else { continue }
            before.append(target.snapshot())
            var keys = replace ? [] : target.read()
            let times = Set(entry.keys.map { $0.time + at })
            keys.removeAll { times.contains($0.time) }
            for key in entry.keys {
                var placed = key
                placed.time += at
                if target.clampUnit { placed.value = min(max(placed.value, 0), 1) }
                keys.append(placed)
            }
            keys.sort { $0.time < $1.time }
            target.write(keys)
            after.append(target.snapshot())
            for (index, key) in target.read().enumerated() where times.contains(key.time) { pasted.insert(KeyRef(channel: target.id, index: index)) }
        }
        guard !before.isEmpty else { return }
        document.registerUndo("Paste Keyframes", undo: { before.reversed().forEach { $0() } }, redo: { after.forEach { $0() } })
        selection = pasted
        activeKey = pasted.first
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        changeSelected("Delete Keyframes") { keys, indices in
            for index in indices.sorted(by: >) where index < keys.count && keys.count > 1 { keys.remove(at: index) }
        }
        selection = []
        activeKey = nil
    }

    private func setInterpolation(_ mode: Int) {
        changeSelected("Set Interpolation") { keys, indices in
            for index in indices where index < keys.count { keys[index].interpolation = mode }
        }
    }

    private func cycleInterpolation() {
        guard let active = activeKey ?? selection.first, let channel = channel(active.channel) else { return }
        let keys = channel.read()
        guard active.index < keys.count else { return }
        setInterpolation((keys[active.index].interpolation + 1) % 3)
    }

    static func holdOrder(_ keys: inout [CurveKeyPoint], _ index: Int) {
        guard index < keys.count else { return }
        let low = index > 0 ? keys[index - 1].time + 1 : -Double.infinity
        let high = index + 1 < keys.count ? keys[index + 1].time - 1 : Double.infinity
        guard low <= high else { return }
        keys[index].time = min(max(keys[index].time, low), high)
    }

    private func keyField(_ label: String, _ channel: CurveChannel, _ index: Int, step: Double, integer: Bool = false,
                          get: @escaping (CurveKeyPoint) -> Double, set: @escaping (inout CurveKeyPoint, Double) -> Void) -> some View {
        let keys = channel.read()
        let current = index < keys.count ? get(keys[index]) : 0
        return HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7).frame(width: 72, alignment: .trailing)
            NumberField(label: nil, value: current, isInteger: integer, step: step,
                        onLive: { next in
                            var live = channel.read()
                            guard index < live.count else { return }
                            set(&live[index], next)
                            CurveEditorView.holdOrder(&live, index)
                            channel.write(live)
                            document.liveDrag()
                        },
                        onCommit: { old, next in
                            var restored = channel.read()
                            guard index < restored.count else { return }
                            set(&restored[index], old)
                            CurveEditorView.holdOrder(&restored, index)
                            channel.write(restored)
                            change(channel, label) { keys in
                                guard index < keys.count else { return }
                                set(&keys[index], next)
                                CurveEditorView.holdOrder(&keys, index)
                            }
                        })
        }
    }

    private func colorRow(_ group: CurveGroup, index: Int) -> some View {
        let channels = (0..<3).compactMap { c in group.channels.first { $0.colorComponent == c } }
        let values = channels.map { channel -> Double in
            let keys = channel.read()
            return index < keys.count ? keys[index].value : 1
        }
        let current = SIMD4(values.count > 0 ? values[0] : 1, values.count > 1 ? values[1] : 1, values.count > 2 ? values[2] : 1, 1)
        func apply(_ color: SIMD4<Double>) {
            for (c, channel) in channels.enumerated() {
                var keys = channel.read()
                guard index < keys.count else { continue }
                keys[index].value = color[c]
                channel.write(keys)
            }
        }
        return VStack(spacing: 4) {
        HStack(spacing: 6) {
            Text("Color").font(Theme.font).foregroundStyle(Theme.text).frame(width: 72, alignment: .trailing)
            ColorField(color: current, alpha: false,
                       onLive: { color in
                           apply(color)
                           document.liveDrag()
                       },
                       onCommit: { old, new in
                           guard let first = channels.first else { return }
                           apply(old)
                           let before = first.snapshot()
                           apply(new)
                           document.registerUndo("Key Color", undo: before, redo: first.snapshot())
                       })
        }
        palette { color in
            guard let first = channels.first else { return }
            let before = first.snapshot()
            apply(color)
            document.registerUndo("Key Color", undo: before, redo: first.snapshot())
        } current: { current }
        }
    }

    static let gradients: [(name: String, stops: [(Double, SIMD3<Double>)])] = [
        ("White", [(0, SIMD3(1, 1, 1)), (1, SIMD3(1, 1, 1))]),
        ("Fade Out", [(0, SIMD3(1, 1, 1)), (1, SIMD3(0, 0, 0))]),
        ("Flash", [(0, SIMD3(0, 0, 0)), (0.15, SIMD3(1, 1, 1)), (1, SIMD3(0, 0, 0))]),
        ("Fire", [(0, SIMD3(1, 0.95, 0.6)), (0.35, SIMD3(1, 0.55, 0.1)), (0.75, SIMD3(0.7, 0.1, 0.02)), (1, SIMD3(0, 0, 0))]),
        ("Ice", [(0, SIMD3(1, 1, 1)), (0.4, SIMD3(0.5, 0.85, 1)), (1, SIMD3(0.05, 0.2, 0.6))]),
        ("Gold", [(0, SIMD3(1, 1, 0.8)), (0.5, SIMD3(1, 0.75, 0.2)), (1, SIMD3(0.4, 0.2, 0))]),
        ("Poison", [(0, SIMD3(0.8, 1, 0.5)), (0.5, SIMD3(0.3, 0.8, 0.2)), (1, SIMD3(0.2, 0.05, 0.3))]),
        ("Rainbow", [(0, SIMD3(1, 0, 0)), (0.2, SIMD3(1, 1, 0)), (0.4, SIMD3(0, 1, 0)), (0.6, SIMD3(0, 1, 1)), (0.8, SIMD3(0, 0, 1)), (1, SIMD3(1, 0, 1))]),
    ]

    private func gradientChannels(_ group: CurveGroup) -> [CurveChannel] {
        (0..<3).compactMap { c in group.channels.first { $0.colorComponent == c } }
    }

    private func gradientStops(_ group: CurveGroup) -> [(time: Double, color: SIMD3<Double>)] {
        let channels = gradientChannels(group)
        guard channels.count == 3 else { return [] }
        let keys = channels.map { $0.read() }
        return keys[0].indices.map { i in
            (keys[0][i].time, SIMD3(keys[0][i].value, i < keys[1].count ? keys[1][i].value : 1, i < keys[2].count ? keys[2][i].value : 1))
        }
    }

    private func writeStops(_ group: CurveGroup, _ stops: [(time: Double, color: SIMD3<Double>)]) {
        let sorted = stops.sorted { $0.time < $1.time }
        for (c, channel) in gradientChannels(group).enumerated() {
            channel.write(sorted.map { CurveKeyPoint(time: $0.time, value: $0.color[c], interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0) })
        }
    }

    private func setStops(_ group: CurveGroup, _ stops: [(time: Double, color: SIMD3<Double>)], title: String) {
        guard let first = gradientChannels(group).first, !stops.isEmpty else { return }
        let before = first.snapshot()
        writeStops(group, stops)
        document.registerUndo(title, undo: before, redo: first.snapshot())
        selection = []
        activeKey = nil
    }

    private func gradientSpan(_ stops: [(time: Double, color: SIMD3<Double>)]) -> (first: Double, last: Double) {
        let first = stops.map(\.time).min() ?? 0
        var last = stops.map(\.time).max() ?? 0
        if last - first < 1 { last = first + max(1, (document.clock.endFrame ?? document.sequencerRows.map(\.end).max() ?? 30).rounded()) }
        return (first, last)
    }

    private func applyGradient(_ group: CurveGroup, _ index: Int) {
        guard index < CurveEditorView.gradients.count else { return }
        let preset = CurveEditorView.gradients[index]
        let span = gradientSpan(gradientStops(group))
        var made: [(time: Double, color: SIMD3<Double>)] = []
        for stop in preset.stops {
            let time = (span.first + stop.0 * (span.last - span.first)).rounded()
            if made.last?.time == time { made.removeLast() }
            made.append((time, stop.1))
        }
        setStops(group, made, title: "Gradient " + preset.name)
        fit(group)
    }

    private func addStop(_ group: CurveGroup) {
        var stops = gradientStops(group)
        let time = max(0, clock.time.rounded())
        guard !stops.contains(where: { $0.time == time }) else { return }
        let keys = gradientChannels(group).map { $0.read() }
        guard keys.count == 3 else { return }
        stops.append((time, SIMD3(CurveMath.sample(keys[0], at: time), CurveMath.sample(keys[1], at: time), CurveMath.sample(keys[2], at: time))))
        setStops(group, stops, title: "Add Color Stop")
    }

    private func reverseStops(_ group: CurveGroup) {
        let stops = gradientStops(group)
        guard stops.count > 1 else { return }
        let colors = stops.map(\.color).reversed()
        setStops(group, zip(stops, colors).map { ($0.time, $1) }, title: "Reverse Gradient")
    }

    private func distributeStops(_ group: CurveGroup) {
        let stops = gradientStops(group)
        guard stops.count > 2 else { return }
        let span = gradientSpan(stops)
        let step = (span.last - span.first) / Double(stops.count - 1)
        guard step >= 1 else { return }
        setStops(group, stops.enumerated().map { ((span.first + Double($0) * step).rounded(), $1.color) }, title: "Distribute Color Stops")
    }

    private func alphaChannel(_ group: CurveGroup) -> CurveChannel? { group.channels.first { $0.name == "Alpha" } }

    private func trackSpan(_ group: CurveGroup) -> (first: Double, last: Double) {
        let times = gradientStops(group).map(\.time) + (alphaChannel(group)?.read().map(\.time) ?? [])
        let first = times.min() ?? 0
        var last = times.max() ?? 0
        if last - first < 1 { last = first + max(1, (document.clock.endFrame ?? document.sequencerRows.map(\.end).max() ?? 30).rounded()) }
        return (first, last)
    }

    private func trackX(_ time: Double, _ span: (first: Double, last: Double), _ width: CGFloat) -> CGFloat {
        8 + CGFloat((time - span.first) / (span.last - span.first)) * (width - 16)
    }

    private func trackTime(_ x: CGFloat, _ span: (first: Double, last: Double), _ width: CGFloat) -> Double {
        max(0, (span.first + Double((x - 8) / max(width - 16, 1)) * (span.last - span.first)).rounded())
    }

    private func drawTracks(_ context: inout GraphicsContext, _ size: CGSize, _ group: CurveGroup) {
        let span = trackSpan(group)
        let channels = gradientChannels(group).map { $0.read() }
        let alpha = alphaChannel(group)?.read() ?? []
        let bar = CGRect(x: 8, y: 16, width: size.width - 16, height: 22)
        context.fill(Path(bar), with: .color(Color(white: 0.1)))
        if channels.count == 3 {
            var px: CGFloat = 0
            while px < bar.width {
                let t = span.first + (span.last - span.first) * Double(px / bar.width)
                let color = Color(.sRGB, red: CurveMath.sample(channels[0], at: t), green: CurveMath.sample(channels[1], at: t), blue: CurveMath.sample(channels[2], at: t))
                context.fill(Path(CGRect(x: bar.minX + px, y: bar.minY, width: 2, height: 11)), with: .color(color))
                let opacity = alpha.isEmpty ? 1 : min(max(CurveMath.sample(alpha, at: t), 0), 1)
                context.fill(Path(CGRect(x: bar.minX + px, y: bar.minY + 11, width: 2, height: 11)), with: .color(color.opacity(opacity)))
                px += 2
            }
        }
        context.stroke(Path(bar), with: .color(Color.black.opacity(0.6)), lineWidth: 1)
        let orange = Color(red: 1, green: 0.63, blue: 0.16)
        for key in alpha {
            let cx = trackX(key.time, span, size.width)
            let chosen = stopPicked?.track == 0 && stopPicked?.time == key.time
            var marker = Path()
            marker.move(to: CGPoint(x: cx, y: 15))
            marker.addLine(to: CGPoint(x: cx - 5, y: 9))
            marker.addLine(to: CGPoint(x: cx - 5, y: 1))
            marker.addLine(to: CGPoint(x: cx + 5, y: 1))
            marker.addLine(to: CGPoint(x: cx + 5, y: 9))
            marker.closeSubpath()
            context.fill(marker, with: .color(Color(white: min(max(key.value, 0), 1))))
            context.stroke(marker, with: .color(chosen ? orange : Color(white: 0.55)), lineWidth: chosen ? 1.6 : 1)
        }
        for stop in gradientStops(group) {
            let cx = trackX(stop.time, span, size.width)
            let chosen = stopPicked?.track == 1 && stopPicked?.time == stop.time
            var marker = Path()
            marker.move(to: CGPoint(x: cx, y: 39))
            marker.addLine(to: CGPoint(x: cx - 5, y: 45))
            marker.addLine(to: CGPoint(x: cx - 5, y: 53))
            marker.addLine(to: CGPoint(x: cx + 5, y: 53))
            marker.addLine(to: CGPoint(x: cx + 5, y: 45))
            marker.closeSubpath()
            context.fill(marker, with: .color(Color(.sRGB, red: stop.color.x, green: stop.color.y, blue: stop.color.z)))
            context.stroke(marker, with: .color(chosen ? orange : Color(white: 0.75)), lineWidth: chosen ? 1.6 : 1)
        }
    }

    private func trackTimes(_ group: CurveGroup, _ track: Int) -> [Double] {
        track == 0 ? (alphaChannel(group)?.read().map(\.time) ?? []) : gradientStops(group).map(\.time)
    }

    private func moveTrackStop(_ group: CurveGroup, _ track: Int, from: Double, to: Double) -> Bool {
        guard from != to, !trackTimes(group, track).contains(to) else { return false }
        if track == 0 {
            guard let channel = alphaChannel(group) else { return false }
            var keys = channel.read()
            guard let index = keys.firstIndex(where: { $0.time == from }) else { return false }
            keys[index].time = to
            channel.write(keys)
        } else {
            var stops = gradientStops(group)
            guard let index = stops.firstIndex(where: { $0.time == from }) else { return false }
            stops[index].time = to
            writeStops(group, stops)
        }
        return true
    }

    private func trackSnapshot(_ group: CurveGroup, _ track: Int) -> (() -> Void)? {
        track == 0 ? alphaChannel(group)?.snapshot() : gradientChannels(group).first?.snapshot()
    }

    private func addTrackStop(_ group: CurveGroup, _ track: Int, at time: Double) {
        guard !trackTimes(group, track).contains(time), let before = trackSnapshot(group, track) else { return }
        if track == 0 {
            guard let channel = alphaChannel(group) else { return }
            var keys = channel.read()
            keys.append(CurveKeyPoint(time: time, value: keys.isEmpty ? 1 : min(max(CurveMath.sample(keys, at: time), 0), 1), interpolation: CurveKeyPoint.linear,
                                      tangentOut: 0, tangentIn: 0))
            channel.write(keys)
        } else {
            let keys = gradientChannels(group).map { $0.read() }
            guard keys.count == 3 else { return }
            var stops = gradientStops(group)
            stops.append((time, SIMD3(CurveMath.sample(keys[0], at: time), CurveMath.sample(keys[1], at: time), CurveMath.sample(keys[2], at: time))))
            writeStops(group, stops)
        }
        if let after = trackSnapshot(group, track) { document.registerUndo(track == 0 ? "Add Alpha Stop" : "Add Color Stop", undo: before, redo: after) }
        stopPicked = (track, time)
    }

    private func removeTrackStop(_ group: CurveGroup, _ track: Int, at time: Double) {
        guard trackTimes(group, track).count > 1, let before = trackSnapshot(group, track) else { return }
        if track == 0 {
            guard let channel = alphaChannel(group) else { return }
            channel.write(channel.read().filter { $0.time != time })
        } else {
            writeStops(group, gradientStops(group).filter { $0.time != time })
        }
        if let after = trackSnapshot(group, track) { document.registerUndo(track == 0 ? "Remove Alpha Stop" : "Remove Color Stop", undo: before, redo: after) }
        stopPicked = nil
    }

    private func trackChanged(_ gesture: DragGesture.Value, _ group: CurveGroup, _ width: CGFloat) {
        let span = trackSpan(group)
        if stopDrag == nil {
            let track = gesture.startLocation.y < 16 ? 0 : gesture.startLocation.y > 38 ? 1 : -1
            guard track >= 0 else { return }
            var best: (time: Double, distance: CGFloat)?
            for time in trackTimes(group, track) {
                let d = abs(trackX(time, span, width) - gesture.startLocation.x)
                if d < 8, d < (best?.distance ?? .infinity) { best = (time, d) }
            }
            guard let best, let restore = trackSnapshot(group, track) else { return }
            stopDrag = (track, best.time, restore, false)
            stopPicked = (track, best.time)
        }
        guard var active = stopDrag, abs(gesture.translation.width) > 2 || active.moved else { return }
        let target = trackTime(gesture.location.x, span, width)
        if moveTrackStop(group, active.track, from: active.time, to: target) {
            active.time = target
            stopPicked = (active.track, target)
            document.liveDrag()
        }
        active.moved = true
        stopDrag = active
    }

    private func trackEnded(_ gesture: DragGesture.Value, _ group: CurveGroup, _ width: CGFloat) {
        let track = gesture.startLocation.y < 16 ? 0 : gesture.startLocation.y > 38 ? 1 : -1
        let now = Date()
        let double = now.timeIntervalSince(stopClick.time) < NSEvent.doubleClickInterval && abs(stopClick.x - gesture.location.x) < 5
        if let active = stopDrag {
            if active.moved {
                if let after = trackSnapshot(group, active.track) {
                    document.registerUndo(active.track == 0 ? "Move Alpha Stop" : "Move Color Stop", undo: active.restore, redo: after)
                }
            } else if double {
                removeTrackStop(group, active.track, at: active.time)
            }
        } else if track >= 0, double {
            addTrackStop(group, track, at: trackTime(gesture.location.x, trackSpan(group), width))
        }
        stopClick = double ? (.distantPast, 0) : (now, gesture.location.x)
        stopDrag = nil
    }

    private func gradientTracks(_ group: CurveGroup) -> some View {
        GeometryReader { geometry in
            Canvas { context, size in drawTracks(&context, size, group) }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { trackChanged($0, group, geometry.size.width) }
                    .onEnded { trackEnded($0, group, geometry.size.width) })
        }
        .frame(height: 54)
        .help("Alpha stops above, colour stops below. Drag a stop to move it, double-click a track to add one, double-click a stop to remove it")
    }

    @ViewBuilder private func pickedStopRow(_ group: CurveGroup) -> some View {
        if let picked = stopPicked, picked.track == 0, let channel = alphaChannel(group), let index = channel.read().firstIndex(where: { $0.time == picked.time }) {
            HStack(spacing: 4) {
                Text("Alpha").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 34, alignment: .leading)
                NumberField(label: nil, value: channel.read()[index].value, step: 0.01,
                            onLive: { _ in },
                            onCommit: { _, next in
                                change(channel, "Alpha Stop") { keys in if index < keys.count { keys[index].value = min(max(next, 0), 1) } }
                            })
                Text("frame \(Int(picked.time))").font(Theme.small).foregroundStyle(Theme.dim)
            }
        } else if let picked = stopPicked, picked.track == 1, let stop = gradientStops(group).first(where: { $0.time == picked.time }) {
            let span = trackSpan(group)
            HStack(spacing: 4) {
                ColorField(color: SIMD4(stop.color.x, stop.color.y, stop.color.z, 1), alpha: false,
                           onLive: { color in
                               var live = gradientStops(group)
                               guard let index = live.firstIndex(where: { $0.time == picked.time }) else { return }
                               live[index].color = SIMD3(color.x, color.y, color.z)
                               writeStops(group, live)
                               document.liveDrag()
                           },
                           onCommit: { old, new in
                               var edited = gradientStops(group)
                               guard let index = edited.firstIndex(where: { $0.time == picked.time }) else { return }
                               edited[index].color = SIMD3(old.x, old.y, old.z)
                               writeStops(group, edited)
                               edited[index].color = SIMD3(new.x, new.y, new.z)
                               setStops(group, edited, title: "Color Stop")
                               stopPicked = picked
                           })
                NumberField(label: nil, value: (picked.time - span.first) / (span.last - span.first) * 100, suffix: "%", step: 0.5, digits: 0,
                            onLive: { _ in },
                            onCommit: { _, next in
                                let target = (span.first + min(max(next, 0), 100) / 100 * (span.last - span.first)).rounded()
                                guard let before = trackSnapshot(group, 1), moveTrackStop(group, 1, from: picked.time, to: target),
                                      let after = trackSnapshot(group, 1) else { return }
                                document.registerUndo("Move Color Stop", undo: before, redo: after)
                                stopPicked = (1, target)
                            })
                    .frame(width: 56)
                    .help("Location of the stop along the gradient")
                Image(systemName: "plus.square.on.square").font(.system(size: 10)).foregroundStyle(Theme.dim).frame(width: 18, height: 18).contentShape(Rectangle())
                    .onTapGesture {
                        var target = picked.time + 1
                        let taken = Set(gradientStops(group).map(\.time))
                        while taken.contains(target) { target += 1 }
                        var stops = gradientStops(group)
                        stops.append((target, stop.color))
                        setStops(group, stops, title: "Duplicate Color Stop")
                        stopPicked = (1, target)
                    }
                    .help("Duplicate this stop one frame later")
            }
        }
    }

    private func gradientPanel(_ group: CurveGroup) -> some View {
        let stops = gradientStops(group)
        return VStack(alignment: .leading, spacing: 4) {
            gradientTracks(group)
            pickedStopRow(group)
            ForEach(Array(stops.enumerated()), id: \.offset) { index, stop in
                HStack(spacing: 4) {
                    Circle().fill(stopPicked?.track == 1 && stopPicked?.time == stop.time ? Color(red: 1, green: 0.63, blue: 0.16) : Color.clear).frame(width: 5, height: 5)
                    NumberField(label: nil, value: stop.time, isInteger: true, step: 1,
                                onLive: { _ in },
                                onCommit: { _, next in
                                    let time = max(0, next.rounded())
                                    var moved = gradientStops(group)
                                    guard index < moved.count, !moved.contains(where: { $0.time == time }) else { return }
                                    moved[index].time = time
                                    setStops(group, moved, title: "Move Color Stop")
                                })
                        .frame(width: 52)
                    ColorField(color: SIMD4(stop.color.x, stop.color.y, stop.color.z, 1), alpha: false,
                               onLive: { color in
                                   var live = gradientStops(group)
                                   guard index < live.count else { return }
                                   live[index].color = SIMD3(color.x, color.y, color.z)
                                   writeStops(group, live)
                                   document.liveDrag()
                               },
                               onCommit: { old, new in
                                   var edited = gradientStops(group)
                                   guard index < edited.count else { return }
                                   edited[index].color = SIMD3(old.x, old.y, old.z)
                                   writeStops(group, edited)
                                   edited[index].color = SIMD3(new.x, new.y, new.z)
                                   setStops(group, edited, title: "Color Stop")
                               })
                    Image(systemName: "xmark").font(.system(size: 9)).foregroundStyle(Theme.dim).frame(width: 16, height: 18).contentShape(Rectangle())
                        .opacity(stops.count > 1 ? 1 : 0.3)
                        .onTapGesture {
                            var left = gradientStops(group)
                            guard left.count > 1, index < left.count else { return }
                            left.remove(at: index)
                            setStops(group, left, title: "Remove Color Stop")
                        }
                }
            }
            HStack(spacing: 2) {
                SegmentButton(title: "Add", active: false) { addStop(group) }
                SegmentButton(title: "Reverse", active: false) { reverseStops(group) }
                SegmentButton(title: "Distribute", active: false) { distributeStops(group) }
                Spacer(minLength: 0)
            }
            FlowLayout(spacing: 4) {
                ForEach(Array(CurveEditorView.gradients.enumerated()), id: \.offset) { index, preset in
                    HStack(spacing: 4) {
                        LinearGradient(stops: preset.stops.map { Gradient.Stop(color: Color(.sRGB, red: $0.1.x, green: $0.1.y, blue: $0.1.z), location: $0.0) },
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: 22, height: 10).clipShape(RoundedRectangle(cornerRadius: 2))
                        Text(preset.name).font(Theme.small).foregroundStyle(Theme.text)
                    }
                    .padding(.horizontal, 5).frame(height: 18)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
                    .contentShape(Rectangle())
                    .onTapGesture { applyGradient(group, index) }
                }
                HelpBadge(text: "Add puts a stop at the playhead with the colour the gradient has there. A preset replaces all stops and keeps the current time range.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func palette(apply: @escaping (SIMD4<Double>) -> Void, current: @escaping () -> SIMD4<Double>) -> some View {
        let saved = paletteText.split(separator: ";").compactMap { entry -> SIMD4<Double>? in
            let parts = entry.split(separator: ",").compactMap { Double($0) }
            return parts.count == 3 ? SIMD4(parts[0], parts[1], parts[2], 1) : nil
        }
        return HStack(spacing: 3) {
            Color.clear.frame(width: 72, height: 1)
            ForEach(Array(saved.enumerated()), id: \.offset) { offset, color in
                RoundedRectangle(cornerRadius: 3).fill(Color(.sRGB, red: color.x, green: color.y, blue: color.z, opacity: 1))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.5), lineWidth: 1))
                    .frame(width: 16, height: 16)
                    .onTapGesture { apply(color) }
                    .contextMenu {
                        Button("Remove from Palette") {
                            var list = paletteText.split(separator: ";").map(String.init)
                            if offset < list.count { list.remove(at: offset) }
                            paletteText = list.joined(separator: ";")
                        }
                    }
                    .help("Click to use this colour")
            }
            Image(systemName: "plus").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 16, height: 16)
                .background(RoundedRectangle(cornerRadius: 3).fill(Theme.gray(0.22)))
                .contentShape(Rectangle())
                .onTapGesture {
                    let color = current()
                    var list = paletteText.split(separator: ";").map(String.init)
                    list.append(String(format: "%.4f,%.4f,%.4f", color.x, color.y, color.z))
                    paletteText = list.suffix(16).joined(separator: ";")
                }
                .help("Save the current colour to the palette")
            Spacer(minLength: 0)
        }
    }

    private func listWidth(_ total: CGFloat) -> CGFloat { min(max(total * 0.16, 110), 240) }

    private func sidebarWidth(_ total: CGFloat) -> CGFloat {
        let wanted = min(max(total * 0.24, 190), 320)
        return max(150, min(wanted, total - listWidth(total) - 180))
    }

    private var sidebar: some View {
        ScrollView {
            VStack(spacing: 6) {
                FlowLayout(spacing: 2) {
                    HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Frame All (Home)") { fit(group) }
                    HeaderButton(symbol: "scope", help: "Frame Selected (.)") { fit(group, selectedOnly: !selection.isEmpty) }
                    HeaderButton(symbol: "plus", help: "Insert Keyframe at the playhead (I) — or double-click the graph") { insertAtPlayhead() }
                    HeaderButton(symbol: "trash", help: "Delete Keyframes (X)") { deleteSelected() }
                    HeaderButton(symbol: "checklist", help: "Select All (A) · Deselect (⌥A)") { selectAll() }
                    HeaderButton(symbol: "arrow.uturn.backward", help: "Reset this curve to how it was when the file was opened") { resetCurve() }
                    SoloButton(document: document)
                    HeaderButton(symbol: "doc.on.doc", help: "Copy the selected keyframes (⌘C)") { copyKeys() }
                    HeaderButton(symbol: "doc.on.clipboard", help: "Paste keyframes at the playhead (⌘V)") { pasteKeys() }
                    HeaderButton(symbol: "doc.on.clipboard.fill", help: "Replace: paste the copied keyframes over the whole curve") { pasteKeys(replace: true) }
                    HeaderButton(symbol: "eraser", help: "Clear: remove every keyframe of the visible channels") { clearKeys() }
                    HeaderButton(symbol: "wand.and.stars", help: "Optimize: remove keys that lie on a straight line between their neighbours") { optimizeKeys(0.005) }

                    if group?.isAngle == true {
                        HeaderButton(symbol: "angle", active: radians, help: "Show angles in radians instead of degrees") { radians.toggle() }
                    }
                    HelpBadge(text: "Drag a key to move it\ndouble-click empty space: new key there\n⌥ click a key: delete\n⇧ click a key: linear ↔ spline\ndrag a square handle to aim the tangent\n⌘ click adds to the selection\ndrag empty space to box-select\n⌃ snaps values\nscroll pans\n⌘ scroll or pinch zooms")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
                if let channel = currentChannel() {
                    Panel(title: "Keys", trailing: channel.name) { keyTable(channel) }
                }
                if currentChannel() != nil, document.format == .avfx {
                    Panel(title: "Presets") {
                        FlowLayout(spacing: 4) {
                            ForEach(Array(CurveEditorView.presets.enumerated()), id: \.offset) { index, preset in
                                Text(preset.name).font(Theme.small).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 18)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
                                    .contentShape(Rectangle())
                                    .onTapGesture { applyPreset(index) }
                            }
                            HelpBadge(text: "A preset replaces the keys of the active channel with a ready shape, kept inside the channel's current time and value range.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        FlowLayout(spacing: 4) {
                            Text("Saved").font(Theme.small).foregroundStyle(Theme.dim).frame(height: 18)
                            ForEach(Array(savedPresets.enumerated()), id: \.offset) { _, preset in
                                Text(preset.name).font(Theme.small).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 18)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
                                    .contentShape(Rectangle())
                                    .onTapGesture { applyShape(preset) }
                                    .contextMenu { Button("Remove Preset") { removeSavedPreset(preset.name) } }
                            }
                            HStack(spacing: 3) {
                                Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                                Text("Save").font(Theme.small)
                            }
                            .foregroundStyle(Theme.dim)
                            .padding(.horizontal, 6)
                            .frame(height: 18)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.dim.opacity(0.45), lineWidth: 1))
                            .contentShape(Rectangle())
                            .onTapGesture { savePreset() }
                            .help("Save the shape of the active channel as a named preset. Right-click a saved preset to remove it")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Panel(title: "Range") {
                    HStack(spacing: 4) {
                        Text("Value").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 34, alignment: .leading)
                        NumberField(label: nil, value: range.v0, step: 0.01, onLive: { if $0 < range.v1 - 1e-6 { range.v0 = $0 } },
                                    onCommit: { _, next in if next < range.v1 - 1e-6 { range.v0 = next } })
                        NumberField(label: nil, value: range.v1, step: 0.01, onLive: { if $0 > range.v0 + 1e-6 { range.v1 = $0 } },
                                    onCommit: { _, next in if next > range.v0 + 1e-6 { range.v1 = next } })
                    }
                    HStack(spacing: 4) {
                        Text("Frame").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 34, alignment: .leading)
                        NumberField(label: nil, value: range.t0, isInteger: true, step: 1, onLive: { if $0 < range.t1 - 1 { range.t0 = $0 } },
                                    onCommit: { _, next in if next < range.t1 - 1 { range.t0 = next } })
                        NumberField(label: nil, value: range.t1, isInteger: true, step: 1, onLive: { if $0 > range.t0 + 1 { range.t1 = $0 } },
                                    onCommit: { _, next in if next > range.t0 + 1 { range.t1 = next } })
                    }
                }
                if let group, gradientChannels(group).count == 3, document.format == .avfx {
                    Panel(title: "Gradient", trailing: "\(gradientStops(group).count) stops") { gradientPanel(group) }
                }
                if !selection.isEmpty {
                    Panel(title: "Selection", trailing: "\(selection.count) keys") {
                        HStack(spacing: 2) {
                            SegmentButton(title: "Spline", active: false) { setInterpolation(0) }
                            SegmentButton(title: "Linear", active: false) { setInterpolation(1) }
                            SegmentButton(title: "Step", active: false) { setInterpolation(2) }
                            Spacer(minLength: 0)
                        }
                    }
                }
                if let active = activeKey, selection.contains(active), let channel = channel(active.channel), active.index < channel.read().count {
                    Panel(title: "Active Keyframe", trailing: channel.name) {
                        keyField("Frame", channel, active.index, step: 1, integer: true, get: { $0.time }, set: { $0.time = max(0, $1.rounded()) })
                        keyField("Value", channel, active.index, step: group?.isAngle == true ? 0.5 : 0.01, get: { $0.value },
                                 set: { $0.value = channel.clampUnit ? min(max($1, 0), 1) : $1 })
                        if channel.colorComponent != nil, let group {
                            colorRow(group, index: active.index)
                        } else {
                            HStack(spacing: 6) {
                                Text("Interpolation").font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7).frame(width: 72, alignment: .trailing)
                                ChoiceField(choices: [FieldChoice(name: "Spline", value: 0), FieldChoice(name: "Linear", value: 1), FieldChoice(name: "Step", value: 2)],
                                            value: channel.read()[active.index].interpolation) { next in
                                    change(channel, "Set Interpolation") { keys in if active.index < keys.count { keys[active.index].interpolation = next } }
                                }
                            }
                            if channel.read()[active.index].interpolation == CurveKeyPoint.spline {
                                keyField("Handle Out", channel, active.index, step: 0.01, get: { $0.tangentOut }, set: { $0.tangentOut = $1 })
                                keyField("Handle In", channel, active.index, step: 0.01, get: { $0.tangentIn }, set: { $0.tangentIn = $1 })
                                HStack(spacing: 2) {
                                    Color.clear.frame(width: 72, height: 1)
                                    SegmentButton(title: "Flat", active: false) {
                                        change(channel, "Flat Handles") { keys in
                                            if active.index < keys.count {
                                                keys[active.index].tangentIn = 0
                                                keys[active.index].tangentOut = 0
                                            }
                                        }
                                    }
                                    SegmentButton(title: "Auto", active: false) {
                                        change(channel, "Auto Handles") { keys in
                                            if active.index < keys.count {
                                                keys[active.index].tangentIn = 1
                                                keys[active.index].tangentOut = 1
                                            }
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                    }
                }
                if let group {
                    if let channel = currentChannel(), !channel.settings.isEmpty {
                        Panel(title: "Extrapolation", trailing: channel.name) { CompactFields(document: document, fields: channel.settings) }
                    }
                    if !group.settings.isEmpty {
                        Panel(title: group.title) { CompactFields(document: document, fields: group.settings) }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .background(Theme.panel)
    }
}

struct CompactFields: View {
    @ObservedObject var document: EffectDocument
    let fields: [PropField]

    var body: some View {
        ForEach(fields) { field in
            HStack(spacing: 6) {
                Text(field.label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.7).frame(width: 92, alignment: .trailing)
                    .help(field.label)
                FieldControl(document: document, field: field)
            }
        }
    }
}
