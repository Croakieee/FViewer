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
    @State private var lastDrag: DragGesture.Value?
    @GestureState private var pressing = false
    @State private var lastClick: (time: Date, point: CGPoint) = (.distantPast, .zero)

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
        for channel in visibleChannels(group) {
            let all = channel.read()
            if selectedOnly {
                keys.append(contentsOf: all.enumerated().filter { selection.contains(KeyRef(channel: channel.id, index: $0.offset)) }.map(\.element))
            } else {
                keys.append(contentsOf: all)
            }
        }
        guard let first = keys.first else {
            if !selectedOnly { range = GraphRange() }
            return
        }
        var t0 = first.time, t1 = first.time, v0 = first.value, v1 = first.value
        for key in keys {
            t0 = min(t0, key.time)
            t1 = max(t1, key.time)
            v0 = min(v0, key.value)
            v1 = max(v1, key.value)
        }
        if !selectedOnly { t0 = min(t0, 0) }
        if t1 - t0 < 10 { t1 = t0 + (selectedOnly ? 10 : 30) }
        if v1 - v0 < 1e-6 {
            v0 -= 0.5
            v1 += 0.5
        }
        let tp = (t1 - t0) * 0.08, vp = (v1 - v0) * 0.18
        range = GraphRange(t0: t0 - tp, t1: t1 + tp, v0: v0 - vp, v1: v1 + vp)
    }

    private func gridStep(_ span: Double, target: Double) -> Double {
        let raw = span / max(target, 1)
        let power = pow(10, floor(log10(max(raw, 1e-9))))
        let ratio = raw / power
        return (ratio < 1.5 ? 1 : ratio < 3.5 ? 2 : ratio < 7.5 ? 5 : 10) * power
    }

    private func handlePoints(_ keys: [CurveKeyPoint], _ i: Int) -> (incoming: (Double, Double)?, outgoing: (Double, Double)?) {
        guard i < keys.count else { return (nil, nil) }
        let key = keys[i]
        var incoming: (Double, Double)?
        var outgoing: (Double, Double)?
        if i + 1 < keys.count, key.interpolation == CurveKeyPoint.spline {
            let span = keys[i + 1].time - key.time
            let before: Double? = i >= 1 ? key.time - keys[i - 1].time : nil
            let slope = CurveMath.tangent(keys, i) * CurveMath.tangentScale(span, before)
            outgoing = (key.time + span / 3, key.value + slope / 3)
        }
        if i >= 1, keys[i - 1].interpolation == CurveKeyPoint.spline {
            let span = key.time - keys[i - 1].time
            let after: Double? = i + 1 < keys.count ? keys[i + 1].time - key.time : nil
            let slope = CurveMath.tangent(keys, i) * CurveMath.tangentScale(span, after)
            incoming = (key.time - span / 3, key.value - slope / 3)
        }
        return (incoming, outgoing)
    }

    var body: some View {
        GeometryReader { outer in
            HStack(spacing: 0) {
                channelList.frame(width: min(max(outer.size.width * 0.14, 140), 260))
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
                sidebar.frame(width: min(max(outer.size.width * 0.2, 210), 340))
            }
        }
        .background(Color(white: 0.157))
        .onChange(of: group?.id, initial: true) { _, _ in
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

    private var channelList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let group {
                    HStack {
                        Text(group.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                        Spacer()
                        Text(group.isAngle ? "degrees" : "").font(Theme.small).foregroundStyle(Theme.dim)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 22)
                    ForEach(group.channels) { channel in
                        let active = (activeChannel ?? visibleChannels(group).first?.id) == channel.id
                        HStack(spacing: 5) {
                            Image(systemName: hidden.contains(channel.id) ? "eye.slash" : "eye").font(.system(size: 9))
                                .foregroundStyle(Theme.dim).frame(width: 14)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if hidden.contains(channel.id) { hidden.remove(channel.id) } else { hidden.insert(channel.id) }
                                }
                            RoundedRectangle(cornerRadius: 2).fill(channel.color).frame(width: 10, height: 10)
                            Text(channel.name).font(Theme.font).foregroundStyle(active ? .white : Theme.text).lineLimit(1)
                            Spacer(minLength: 0)
                            Text("\(channel.read().count)").font(Theme.small).foregroundStyle(Theme.dim)
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
                } else {
                    Text("Pick a curve under Properties → Animation").font(Theme.font).foregroundStyle(Theme.dim).padding(8)
                }
            }
        }
    }

    private var graph: some View {
        let redrawTriggers = (range, selection, hidden, boxStart, boxEnd, measured, activeChannel, dragActive, document.revision)
        if case .box = drag { _ = redrawTriggers }
        return Canvas { context, canvasSize in
            _ = redrawTriggers
            let tStep = gridStep(range.t1 - range.t0, target: Double(canvasSize.width) / 70)
            let vStep = gridStep(range.v1 - range.v0, target: Double(canvasSize.height) / 40)
            var t = (range.t0 / tStep).rounded(.down) * tStep
            while t <= range.t1 {
                var line = Path()
                line.move(to: CGPoint(x: x(t), y: top))
                line.addLine(to: CGPoint(x: x(t), y: canvasSize.height))
                context.stroke(line, with: .color(Color.white.opacity(t == 0 ? 0.18 : 0.06)), lineWidth: 1)
                t += tStep
            }
            var v = (range.v0 / vStep).rounded(.down) * vStep
            while v <= range.v1 {
                if y(v) > top + 6 {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y(v)))
                    line.addLine(to: CGPoint(x: canvasSize.width, y: y(v)))
                    context.stroke(line, with: .color(Color.white.opacity(abs(v) < vStep / 2 ? 0.18 : 0.06)), lineWidth: 1)
                    let label = String(format: vStep < 0.1 ? "%.3f" : vStep < 1 ? "%.2f" : "%.0f", v) + (group?.isAngle == true ? "°" : "")
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
                context.stroke(before, with: .color(channel.color.opacity(0.4)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                context.stroke(after, with: .color(channel.color.opacity(0.4)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                context.stroke(inside, with: .color(channel.color), lineWidth: 1.6)
                for (i, key) in keys.enumerated() where selection.contains(KeyRef(channel: channel.id, index: i)) && channel.colorComponent == nil {
                    let handles = handlePoints(keys, i)
                    for handle in [handles.incoming, handles.outgoing].compactMap({ $0 }) {
                        var line = Path()
                        line.move(to: CGPoint(x: x(key.time), y: y(key.value)))
                        line.addLine(to: CGPoint(x: x(handle.0), y: y(handle.1)))
                        context.stroke(line, with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.9)), lineWidth: 1)
                        let dot = CGRect(x: x(handle.0) - 3.5, y: y(handle.1) - 3.5, width: 7, height: 7)
                        context.fill(Path(ellipseIn: dot), with: .color(Color(red: 1, green: 0.63, blue: 0.16)))
                    }
                }
                for (i, key) in keys.enumerated() {
                    let isSelected = selection.contains(KeyRef(channel: channel.id, index: i))
                    let center = CGPoint(x: x(key.time), y: y(key.value))
                    let r: CGFloat = isSelected ? 4.5 : 3.5
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
                    context.stroke(shape, with: .color(isSelected ? Color(red: 1, green: 0.63, blue: 0.16) : channel.color), lineWidth: 1.5)
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
            switch press.characters {
            case "x", "\u{7f}", "\u{8}":
                deleteSelected()
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
                if d < 9, d < (best?.1 ?? .infinity) { best = (KeyRef(channel: channel.id, index: i), d) }
            }
        }
        return best?.0
    }

    private func hitHandle(_ point: CGPoint) -> (KeyRef, Bool)? {
        guard let group else { return nil }
        for channel in visibleChannels(group) where channel.colorComponent == nil {
            let keys = channel.read()
            for ref in selection where ref.channel == channel.id {
                let handles = handlePoints(keys, ref.index)
                if let h = handles.outgoing, hypot(x(h.0) - point.x, y(h.1) - point.y) < 8 { return (ref, true) }
                if let h = handles.incoming, hypot(x(h.0) - point.x, y(h.1) - point.y) < 8 { return (ref, false) }
            }
        }
        return nil
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
        drag = .keys(origin: origin, selected: selected, restore: restore)
    }

    private func handleDrag(_ gesture: DragGesture.Value) {
        if case .none = drag {
            focused = true
            let shift = NSEvent.modifierFlags.contains(.shift)
            if gesture.startLocation.y < rulerHeight {
                drag = .scrub
            } else if let (ref, outgoing) = hitHandle(gesture.startLocation), let channel = channel(ref.channel) {
                drag = .handle(key: ref, outgoing: outgoing, restore: channel.snapshot())
            } else if let hit = hitKey(gesture.startLocation) {
                if shift {
                    if selection.contains(hit) { selection.remove(hit) } else { selection.insert(hit) }
                } else if !selection.contains(hit) {
                    selection = [hit]
                }
                activeKey = hit
                activeChannel = hit.channel
                beginKeyDrag()
            } else {
                boxStart = gesture.startLocation
                boxEnd = gesture.startLocation
                drag = .box(additive: shift)
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
            let flags = NSEvent.modifierFlags
            if flags.contains(.control) {
                let step = gridStep(range.v1 - range.v0, target: Double(size.height) / 40) / 10
                dv = (dv / step).rounded() * step
            }
            let lockTime = flags.contains(.option)
            var nextSelection: Set<KeyRef> = []
            for (id, keys) in origin {
                guard let channel = channel(id) else { continue }
                let marks = selected[id] ?? []
                var moved = keys.enumerated().map { index, key -> (CurveKeyPoint, Bool) in
                    guard marks.contains(index) else { return (key, false) }
                    var next = key
                    if !lockTime { next.time = max(0, key.time + dt) }
                    next.value = key.value + dv
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
            document.liveChanged()
        case .handle(let ref, let outgoing, _):
            guard let channel = channel(ref.channel) else { return }
            var keys = channel.read()
            guard ref.index < keys.count else { return }
            let key = keys[ref.index]
            let parts = CurveMath.tangentParts(keys, ref.index)
            let target = value(gesture.location.y)
            if outgoing, ref.index + 1 < keys.count, abs(parts.toNext) > 1e-9 {
                let span = keys[ref.index + 1].time - key.time
                let before: Double? = ref.index >= 1 ? key.time - keys[ref.index - 1].time : nil
                let tangent = (target - key.value) * 3 / CurveMath.tangentScale(span, before)
                keys[ref.index].tangentOut = (2 * tangent - key.tangentIn * parts.fromPrevious) / parts.toNext
            } else if !outgoing, ref.index >= 1, abs(parts.fromPrevious) > 1e-9 {
                let span = key.time - keys[ref.index - 1].time
                let after: Double? = ref.index + 1 < keys.count ? keys[ref.index + 1].time - key.time : nil
                let tangent = (key.value - target) * 3 / CurveMath.tangentScale(span, after)
                keys[ref.index].tangentIn = (2 * tangent - key.tangentOut * parts.toNext) / parts.fromPrevious
            }
            channel.write(keys)
            document.liveChanged()
        case .box:
            boxEnd = gesture.location
        case .none: break
        }
    }

    private func endDrag(_ gesture: DragGesture.Value) {
        switch drag {
        case .keys(_, _, let restore):
            if dragActive {
                let after = restore.keys.compactMap { id in channel(id).map { $0.snapshot() } }
                let before = Array(restore.values)
                document.registerUndo("Move Keyframes", undo: { before.forEach { $0() } }, redo: { after.forEach { $0() } })
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
    }

    private func change(_ channel: CurveChannel, _ title: String, _ edit: (inout [CurveKeyPoint]) -> Void) {
        let before = channel.snapshot()
        var keys = channel.read()
        edit(&keys)
        channel.write(keys)
        document.registerUndo(title, undo: before, redo: channel.snapshot())
    }

    private func changeSelected(_ title: String, _ edit: (inout [CurveKeyPoint], Set<Int>) -> Void) {
        let byChannel = Dictionary(grouping: selection, by: \.channel)
        var before: [() -> Void] = []
        var after: [() -> Void] = []
        for (id, refs) in byChannel {
            guard let channel = channel(id) else { continue }
            before.append(channel.snapshot())
            var keys = channel.read()
            edit(&keys, Set(refs.map(\.index)))
            channel.write(keys)
            after.append(channel.snapshot())
        }
        guard !before.isEmpty else { return }
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
        insertKey(channel, at: max(0, time(location.x).rounded()))
    }

    private func insertAtPlayhead() {
        if let channel = currentChannel() { insertKey(channel, at: clock.time.rounded()) }
    }

    private func insertKey(_ channel: CurveChannel, at t: Double) {
        let existing = channel.read()
        if existing.contains(where: { $0.time == t }) { return }
        let extrapolation = channel.extrapolation()
        let v = existing.isEmpty ? 0 : CurveMath.sampleExtended(existing, at: t, pre: extrapolation.pre, post: extrapolation.post)
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

    private func keyField(_ label: String, _ channel: CurveChannel, _ index: Int, step: Double, integer: Bool = false,
                          get: @escaping (CurveKeyPoint) -> Double, set: @escaping (inout CurveKeyPoint, Double) -> Void) -> some View {
        let keys = channel.read()
        let current = index < keys.count ? get(keys[index]) : 0
        return HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 64, alignment: .trailing)
            NumberField(label: nil, value: current, isInteger: integer, step: step,
                        onLive: { next in
                            var live = channel.read()
                            guard index < live.count else { return }
                            set(&live[index], next)
                            channel.write(live)
                            document.liveChanged()
                        },
                        onCommit: { old, next in
                            var restored = channel.read()
                            guard index < restored.count else { return }
                            set(&restored[index], old)
                            channel.write(restored)
                            change(channel, label) { keys in if index < keys.count { set(&keys[index], next) } }
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
        return HStack(spacing: 6) {
            Text("Color").font(Theme.font).foregroundStyle(Theme.text).frame(width: 64, alignment: .trailing)
            ColorField(color: current, alpha: false,
                       onLive: { color in
                           apply(color)
                           document.liveChanged()
                       },
                       onCommit: { old, new in
                           guard let first = channels.first else { return }
                           apply(old)
                           let before = first.snapshot()
                           apply(new)
                           document.registerUndo("Key Color", undo: before, redo: first.snapshot())
                       })
        }
    }

    private var sidebar: some View {
        ScrollView {
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Frame All (Home)") { fit(group) }
                    HeaderButton(symbol: "scope", help: "Frame Selected (.)") { fit(group, selectedOnly: !selection.isEmpty) }
                    HeaderButton(symbol: "plus", help: "Insert Keyframe at the playhead (I) — or double-click the graph") { insertAtPlayhead() }
                    HeaderButton(symbol: "trash", help: "Delete Keyframes (X)") { deleteSelected() }
                    HeaderButton(symbol: "checklist", help: "Select All (A) · Deselect (⌥A)") { selectAll() }
                    Spacer()
                }
                .padding(.horizontal, 6)
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
                                Text("Interpolation").font(Theme.font).foregroundStyle(Theme.text).frame(width: 64, alignment: .trailing).lineLimit(1)
                                ChoiceField(choices: [FieldChoice(name: "Spline", value: 0), FieldChoice(name: "Linear", value: 1), FieldChoice(name: "Step", value: 2)],
                                            value: channel.read()[active.index].interpolation) { next in
                                    change(channel, "Set Interpolation") { keys in if active.index < keys.count { keys[active.index].interpolation = next } }
                                }
                            }
                            if channel.read()[active.index].interpolation == CurveKeyPoint.spline {
                                keyField("Handle Out", channel, active.index, step: 0.01, get: { $0.tangentOut }, set: { $0.tangentOut = $1 })
                                keyField("Handle In", channel, active.index, step: 0.01, get: { $0.tangentIn }, set: { $0.tangentIn = $1 })
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
                    Text("Drag keys to move · ⇧ click adds to selection · drag empty space to box-select · ⌃ snaps values · ⌥ keeps the frame · scroll pans · ⌘ scroll or pinch zooms")
                        .font(Theme.small).foregroundStyle(Theme.dim).padding(.horizontal, 10).frame(maxWidth: .infinity, alignment: .leading)
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
                Text(field.label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 86, alignment: .trailing)
                FieldControl(document: document, field: field)
            }
        }
    }
}
