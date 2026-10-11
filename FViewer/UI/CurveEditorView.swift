import SwiftUI

private struct KeyRef: Equatable {
    var channel: String
    var index: Int
}

private struct GraphRange: Equatable {
    var t0: Double = -2
    var t1: Double = 62
    var v0: Double = -0.2
    var v1: Double = 1.2
}

struct CurveEditorView: View {
    @ObservedObject var document: EffectDocument
    @State private var range = GraphRange()
    @State private var hidden: Set<String> = []
    @State private var selected: KeyRef?
    @State private var activeChannel: String?
    @State private var dragMode = 0
    @State private var dragRange = GraphRange()
    @State private var dragRestore: (() -> Void)?
    @State private var size = CGSize(width: 400, height: 200)
    @FocusState private var focused: Bool

    private let rulerHeight: CGFloat = 18

    private var group: CurveGroup? {
        guard let node = document.selectedNode else { return nil }
        let groups = document.curveGroups(for: node)
        return groups.first { $0.id == document.activeCurveID } ?? groups.first
    }

    private func x(_ t: Double) -> CGFloat { CGFloat((t - range.t0) / (range.t1 - range.t0)) * size.width }
    private func y(_ v: Double) -> CGFloat { size.height - CGFloat((v - range.v0) / (range.v1 - range.v0)) * (size.height - rulerHeight) }
    private func time(_ px: CGFloat) -> Double { range.t0 + Double(px / max(size.width, 1)) * (range.t1 - range.t0) }
    private func value(_ py: CGFloat) -> Double {
        range.v0 + Double((size.height - py) / max(size.height - rulerHeight, 1)) * (range.v1 - range.v0)
    }

    private func visibleChannels(_ group: CurveGroup) -> [CurveChannel] { group.channels.filter { !hidden.contains($0.id) } }

    private func fit(_ group: CurveGroup?) {
        guard let group else { return }
        let keys = visibleChannels(group).flatMap { $0.read() }
        guard let first = keys.first else {
            range = GraphRange()
            return
        }
        var t0 = first.time, t1 = first.time, v0 = first.value, v1 = first.value
        for key in keys {
            t0 = min(t0, key.time)
            t1 = max(t1, key.time)
            v0 = min(v0, key.value)
            v1 = max(v1, key.value)
        }
        t0 = min(t0, 0)
        if t1 - t0 < 10 { t1 = t0 + 30 }
        if v1 - v0 < 1e-6 {
            v0 -= 0.5
            v1 += 0.5
        }
        let tp = (t1 - t0) * 0.06, vp = (v1 - v0) * 0.15
        range = GraphRange(t0: t0 - tp, t1: t1 + tp, v0: v0 - vp, v1: v1 + vp)
    }

    private func gridStep(_ span: Double, target: Double) -> Double {
        let raw = span / max(target, 1)
        let power = pow(10, floor(log10(max(raw, 1e-9))))
        let ratio = raw / power
        return (ratio < 1.5 ? 1 : ratio < 3.5 ? 2 : ratio < 7.5 ? 5 : 10) * power
    }

    var body: some View {
        HStack(spacing: 0) {
            channelList
            Rectangle().fill(Theme.line).frame(width: 1)
            GeometryReader { geometry in
                graph
                    .onAppear {
                        size = geometry.size
                        fit(group)
                    }
                    .onChange(of: geometry.size) { _, next in size = next }
            }
            Rectangle().fill(Theme.line).frame(width: 1)
            sidebar
        }
        .background(Color(white: 0.157))
        .onChange(of: group?.id) { _, _ in
            selected = nil
            activeChannel = nil
            hidden = []
            fit(group)
        }
    }

    private var channelList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if let group {
                    HStack {
                        Text(group.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                        Spacer()
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
                        .onTapGesture { activeChannel = channel.id }
                    }
                } else {
                    Text("Выберите кривую в панели Properties → Animation").font(Theme.font).foregroundStyle(Theme.dim).padding(8)
                }
            }
        }
        .frame(width: 170)
    }

    private var graph: some View {
        Canvas { context, canvasSize in
            let tStep = gridStep(range.t1 - range.t0, target: Double(canvasSize.width) / 70)
            let vStep = gridStep(range.v1 - range.v0, target: Double(canvasSize.height) / 40)
            var t = (range.t0 / tStep).rounded(.down) * tStep
            while t <= range.t1 {
                var line = Path()
                line.move(to: CGPoint(x: x(t), y: rulerHeight))
                line.addLine(to: CGPoint(x: x(t), y: canvasSize.height))
                context.stroke(line, with: .color(Color.white.opacity(t == 0 ? 0.18 : 0.06)), lineWidth: 1)
                context.draw(Text(JSONNode.format(t)).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: x(t) + 3, y: 9), anchor: .leading)
                t += tStep
            }
            var v = (range.v0 / vStep).rounded(.down) * vStep
            while v <= range.v1 {
                if y(v) > rulerHeight + 6 {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y(v)))
                    line.addLine(to: CGPoint(x: canvasSize.width, y: y(v)))
                    context.stroke(line, with: .color(Color.white.opacity(abs(v) < vStep / 2 ? 0.18 : 0.06)), lineWidth: 1)
                    let label = String(format: vStep < 0.1 ? "%.3f" : vStep < 1 ? "%.2f" : "%.0f", v) + (group?.isAngle == true ? "°" : "")
                    context.draw(Text(label).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: 4, y: y(v) - 7), anchor: .leading)
                }
                v += vStep
            }
            context.fill(Path(CGRect(x: 0, y: 0, width: canvasSize.width, height: rulerHeight)), with: .color(Color.black.opacity(0.25)))
            guard let group else { return }
            for channel in visibleChannels(group) {
                let keys = channel.read()
                guard let first = keys.first, let last = keys.last else { continue }
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y(first.value)))
                path.addLine(to: CGPoint(x: x(first.time), y: y(first.value)))
                let from = max(x(first.time), 0), to = min(x(last.time), canvasSize.width)
                if to > from {
                    var px = from
                    while px <= to {
                        path.addLine(to: CGPoint(x: px, y: y(CurveMath.sample(keys, at: time(px)))))
                        px += 2
                    }
                }
                path.addLine(to: CGPoint(x: x(last.time), y: y(last.value)))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y(last.value)))
                context.stroke(path, with: .color(channel.color), lineWidth: 1.5)
                for (i, key) in keys.enumerated() {
                    let isSelected = selected == KeyRef(channel: channel.id, index: i)
                    let center = CGPoint(x: x(key.time), y: y(key.value))
                    let r: CGFloat = isSelected ? 5 : 3.5
                    let shape = key.interpolation == CurveKeyPoint.step
                        ? Path(CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                        : Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                    context.fill(shape, with: .color(isSelected ? Color.white : Color.black))
                    context.stroke(shape, with: .color(isSelected ? Color(red: 1, green: 0.63, blue: 0.16) : channel.color), lineWidth: 1.5)
                }
            }
            let px = x(document.time)
            var playhead = Path()
            playhead.move(to: CGPoint(x: px, y: 0))
            playhead.addLine(to: CGPoint(x: px, y: canvasSize.height))
            context.stroke(playhead, with: .color(Theme.playhead), lineWidth: 1.5)
            let box = CGRect(x: px - 16, y: 1, width: 32, height: rulerHeight - 2)
            context.fill(Path(roundedRect: box, cornerRadius: 3), with: .color(Theme.playhead))
            context.draw(Text(JSONNode.format(document.time.rounded())).font(Theme.small).foregroundStyle(.white), at: CGPoint(x: px, y: rulerHeight / 2))
        }
        .background(ScrollMonitor(
            onScroll: { delta, flags, point in
                if flags.contains(.command) || flags.contains(.control) {
                    zoom(1 - Double(delta.height) * 0.01, at: point, horizontal: true, vertical: !flags.contains(.shift))
                } else {
                    let dt = Double(delta.width / max(size.width, 1)) * (range.t1 - range.t0)
                    let dv = Double(delta.height / max(size.height, 1)) * (range.v1 - range.v0)
                    range = GraphRange(t0: range.t0 - dt, t1: range.t1 - dt, v0: range.v0 + dv, v1: range.v1 + dv)
                }
            },
            onMagnify: { amount, point in zoom(1 - Double(amount), at: point, horizontal: true, vertical: true) }))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { drag in handleDrag(drag) }
            .onEnded { _ in endDrag() })
        .onTapGesture(count: 2) { location in addKey(at: location) }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress { press in
            switch press.characters {
            case "x", "\u{7f}", "\u{8}":
                deleteSelected()
                return .handled
            case "t":
                cycleInterpolation()
                return .handled
            case "a", "\u{F729}":
                fit(group)
                return .handled
            default: return .ignored
            }
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

    private func handleDrag(_ drag: DragGesture.Value) {
        if dragMode == 0 {
            focused = true
            if drag.startLocation.y < rulerHeight {
                dragMode = 1
            } else if let hit = hitKey(drag.startLocation), let channel = group?.channels.first(where: { $0.id == hit.channel }) {
                selected = hit
                activeChannel = hit.channel
                dragRestore = channel.snapshot()
                dragMode = 2
            } else {
                selected = nil
                dragRange = range
                dragMode = 3
            }
        }
        switch dragMode {
        case 1:
            document.time = max(0, time(drag.location.x).rounded())
        case 2:
            guard let selected, let channel = group?.channels.first(where: { $0.id == selected.channel }) else { return }
            var keys = channel.read()
            guard selected.index < keys.count, hypot(drag.translation.width, drag.translation.height) > 2 else { return }
            var t = time(drag.location.x).rounded()
            if selected.index > 0 { t = max(t, keys[selected.index - 1].time + 1) }
            if selected.index + 1 < keys.count { t = min(t, keys[selected.index + 1].time - 1) }
            keys[selected.index].time = t
            var v = value(drag.location.y)
            if NSEvent.modifierFlags.contains(.control) {
                let step = gridStep(range.v1 - range.v0, target: Double(size.height) / 40) / 10
                v = (v / step).rounded() * step
            }
            if !NSEvent.modifierFlags.contains(.shift) || abs(drag.translation.height) > abs(drag.translation.width) { keys[selected.index].value = v }
            channel.write(keys)
            document.liveChanged()
        case 3:
            let dt = Double(drag.translation.width / max(size.width, 1)) * (dragRange.t1 - dragRange.t0)
            let dv = Double(drag.translation.height / max(size.height - rulerHeight, 1)) * (dragRange.v1 - dragRange.v0)
            range = GraphRange(t0: dragRange.t0 - dt, t1: dragRange.t1 - dt, v0: dragRange.v0 + dv, v1: dragRange.v1 + dv)
        default: break
        }
    }

    private func endDrag() {
        if dragMode == 2, let before = dragRestore, let selected, let channel = group?.channels.first(where: { $0.id == selected.channel }) {
            let after = channel.snapshot()
            document.registerUndo("Переместить ключ", undo: before, redo: after)
        }
        dragRestore = nil
        dragMode = 0
    }

    private func change(_ channel: CurveChannel, _ title: String, _ edit: (inout [CurveKeyPoint]) -> Void) {
        let before = channel.snapshot()
        var keys = channel.read()
        edit(&keys)
        channel.write(keys)
        document.registerUndo(title, undo: before, redo: channel.snapshot())
    }

    private func currentChannel() -> CurveChannel? {
        guard let group else { return nil }
        let visible = visibleChannels(group)
        return visible.first { $0.id == activeChannel } ?? visible.first
    }

    private func addKey(at location: CGPoint) {
        guard let channel = currentChannel() else { return }
        insertKey(channel, at: max(0, time(location.x).rounded()), value: nil)
    }

    private func insertKey(_ channel: CurveChannel, at t: Double, value: Double?) {
        let existing = channel.read()
        if existing.contains(where: { $0.time == t }) { return }
        let v = value ?? (existing.isEmpty ? 0 : CurveMath.sample(existing, at: t))
        change(channel, "Добавить ключ") { keys in
            keys.append(CurveKeyPoint(time: t, value: v, interpolation: keys.last?.interpolation ?? CurveKeyPoint.linear, tangentOut: 1, tangentIn: 1))
            keys.sort { $0.time < $1.time }
        }
        if let index = channel.read().firstIndex(where: { $0.time == t }) { selected = KeyRef(channel: channel.id, index: index) }
    }

    private func deleteSelected() {
        guard let selected, let channel = group?.channels.first(where: { $0.id == selected.channel }) else { return }
        change(channel, "Удалить ключ") { keys in
            if selected.index < keys.count { keys.remove(at: selected.index) }
        }
        self.selected = nil
    }

    private func cycleInterpolation() {
        guard let selected, let channel = group?.channels.first(where: { $0.id == selected.channel }) else { return }
        change(channel, "Интерполяция") { keys in
            if selected.index < keys.count { keys[selected.index].interpolation = (keys[selected.index].interpolation + 1) % 3 }
        }
    }

    private func keyField(_ label: String, _ channel: CurveChannel, _ index: Int, step: Double, integer: Bool = false,
                          get: @escaping (CurveKeyPoint) -> Double, set: @escaping (inout CurveKeyPoint, Double) -> Void) -> some View {
        let keys = channel.read()
        let current = index < keys.count ? get(keys[index]) : 0
        return HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 58, alignment: .trailing)
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

    private var sidebar: some View {
        ScrollView {
            VStack(spacing: 6) {
                HStack(spacing: 2) {
                    HeaderButton(symbol: "arrow.up.left.and.arrow.down.right", help: "Показать всё (A / Home)") { fit(group) }
                    HeaderButton(symbol: "plus", help: "Ключ на текущем кадре (или двойной щелчок)") {
                        if let channel = currentChannel() { insertKey(channel, at: document.time.rounded(), value: nil) }
                    }
                    HeaderButton(symbol: "trash", help: "Удалить ключ (X)") { deleteSelected() }
                    HeaderButton(symbol: "point.topleft.down.to.point.bottomright.curvepath", help: "Интерполяция (T)") { cycleInterpolation() }
                    Spacer()
                }
                .padding(.horizontal, 6)
                if let selected, let channel = group?.channels.first(where: { $0.id == selected.channel }), selected.index < channel.read().count {
                    Panel(title: "Active Keyframe") {
                        keyField("Frame", channel, selected.index, step: 1, integer: true, get: { $0.time }, set: { $0.time = max(0, $1.rounded()) })
                        keyField("Value", channel, selected.index, step: group?.isAngle == true ? 0.5 : 0.01, get: { $0.value }, set: { $0.value = $1 })
                        HStack(spacing: 6) {
                            Text("Interp.").font(Theme.font).foregroundStyle(Theme.text).frame(width: 58, alignment: .trailing)
                            ChoiceField(choices: [FieldChoice(name: "Spline", value: 0), FieldChoice(name: "Linear", value: 1), FieldChoice(name: "Step", value: 2)],
                                        value: channel.read()[selected.index].interpolation) { next in
                                change(channel, "Интерполяция") { keys in if selected.index < keys.count { keys[selected.index].interpolation = next } }
                            }
                        }
                        if channel.read()[selected.index].interpolation == CurveKeyPoint.spline {
                            keyField("Tan Out", channel, selected.index, step: 0.01, get: { $0.tangentOut }, set: { $0.tangentOut = $1 })
                            keyField("Tan In", channel, selected.index, step: 0.01, get: { $0.tangentIn }, set: { $0.tangentIn = $1 })
                        }
                    }
                }
                if let group {
                    if !group.settings.isEmpty {
                        Panel(title: group.title) { CompactFields(document: document, fields: group.settings) }
                    }
                    if let channel = currentChannel(), !channel.settings.isEmpty {
                        Panel(title: channel.name) { CompactFields(document: document, fields: channel.settings) }
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 210)
        .background(Theme.panel)
    }
}

struct CompactFields: View {
    @ObservedObject var document: EffectDocument
    let fields: [PropField]

    var body: some View {
        ForEach(fields) { field in
            HStack(spacing: 6) {
                Text(field.label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 78, alignment: .trailing)
                FieldControl(document: document, field: field)
            }
        }
    }
}
