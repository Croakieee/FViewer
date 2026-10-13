import SwiftUI

struct SequencerView: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    @AppStorage("timeline.density") private var showDensity = true
    @AppStorage("timeline.seconds") private var showSeconds = false
    @State private var locked: Set<String> = []

    private func stamp(_ frame: Double) -> String {
        showSeconds ? String(format: "%.2f", frame / 30) : "\(Int(frame.rounded()))"
    }
    @State private var dragMode = 0
    @State private var dragRow: SequencerRow?
    @State private var dragStart: Double = 0
    @State private var dragEnd: Double = 0

    private let rowHeight: CGFloat = 20
    private let rulerHeight: CGFloat = 18
    @State private var labelWidth: CGFloat = 170

    @State private var frozenSpan: Double?
    @GestureState private var pressing = false
    @State private var liveSpan: Double = 64

    private func currentSpan(_ end: Double) -> Double { frozenSpan ?? max(end, 1) * 1.08 + 4 }
    @State private var viewZoom: Double = 1
    @AppStorage("timeline.snap") private var snapping = true

    private func renameTarget(_ row: SequencerRow) -> String? {
        guard let id = row.nodeID else { return nil }
        switch document.visibilityKey(forNodeID: id) {
        case .emitter(let index): return "avfx/Emit/\(index)"
        case .particle(let index): return "avfx/Ptcl/\(index)"
        case .timeline(let index): return "avfx/TmLn/\(index)"
        case nil: return document.node(id) != nil ? id : nil
        }
    }

    private func snapped(_ frame: Double, _ row: SequencerRow, _ width: CGFloat, _ span: Double) -> Double {
        guard snapping else { return frame }
        let reach = 7 * (span / viewZoom) / Double(max(width, 1))
        var marks = [clock.time.rounded(), clock.startFrame]
        if let end = clock.endFrame { marks.append(end) }
        for other in document.sequencerRows where other.id != row.id && other.depth > 0 {
            marks.append(other.start)
            if !other.openEnded { marks.append(other.end) }
        }
        var best = frame
        var nearest = reach
        for mark in marks where abs(mark - frame) < nearest {
            nearest = abs(mark - frame)
            best = mark
        }
        return best
    }

    private func duplicateAtPlayhead(_ row: SequencerRow) {
        guard let id = row.nodeID, let node = document.node(id), let duplicate = node.actions.first(where: { $0.title == "Duplicate" }) else { return }
        let before = document.sequencerRows.count
        let frame = clock.time.rounded()
        duplicate.perform()
        let rows = document.sequencerRows
        guard rows.count > before, let at = rows.firstIndex(where: { $0.id == row.id }),
              let fresh = rows[(at + 1)...].first(where: { $0.depth == row.depth }), let start = fresh.startField else { return }
        let shift = frame - fresh.start
        if shift != 0 {
            func value(_ field: PropField, _ v: Double) -> FieldValue { if case .int = field.kind { return .int(Int(v)) }; return .double(v) }
            start.write?(value(start, start.read().number + shift))
            if let finish = fresh.endField, !fresh.openEnded { finish.write?(value(finish, finish.read().number + shift)) }
            document.amendLastUndo()
        }
        document.selectionID = fresh.nodeID
    }
    @State private var viewStart: Double = 0

    private func x(_ t: Double, _ width: CGFloat, _ span: Double) -> CGFloat { CGFloat((t + 2 / viewZoom - viewStart) / (span / viewZoom)) * width }
    private func time(_ px: CGFloat, _ width: CGFloat, _ span: Double) -> Double { Double(px / max(width, 1)) * (span / viewZoom) - 2 / viewZoom + viewStart }

    private var triggerMenu: some View {
        Menu {
            ForEach(0..<max(document.triggerCount, 1), id: \.self) { index in
                Button("Trigger \(index)") { clock.trigger(index) }
            }
        } label: {
            Image(systemName: "bolt").font(.system(size: 11)).foregroundStyle(Theme.text).frame(width: 24, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Fire a scheduler trigger, as the game does on events such as the end of a cast")
    }

    private func rowLabel(_ index: Int, _ row: SequencerRow) -> some View {
        let changes = document.changes
        return HStack(spacing: 5) {
            Color.clear.frame(width: CGFloat(row.depth) * 12)
            RoundedRectangle(cornerRadius: 2).fill(row.tint.color).frame(width: 8, height: 8)
            Text(row.label).font(Theme.font).foregroundStyle(document.selectionID == row.nodeID ? .white : Theme.text).lineLimit(1)
                .onTapGesture(count: 2) { if let target = renameTarget(row) { AppDelegate.model?.renameNode(target) } }
                .help("Double-click to rename")
            if let id = row.nodeID, changes.contains(id) { ChangeDot(added: changes.added.contains(id)) }
            Spacer(minLength: 0)
            if let enabled = row.enabledField {
                let value = enabled.read()
                Image(systemName: value == .bool(true) ? "checkmark.square.fill" : "square").font(.system(size: 10))
                    .foregroundStyle(value == .bool(true) ? Theme.text : Theme.dim)
                    .frame(width: 16, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture { document.commit(enabled, from: value, to: .bool(value != .bool(true))) }
                    .help("Enabled")
            }
            if row.depth > 0, let id = row.nodeID {
                let solo = document.soloPreview && document.selectionID == id
                Image(systemName: "headphones").font(.system(size: 9)).foregroundStyle(solo ? Theme.changed : Theme.dim)
                    .frame(width: 16, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture {
                        if solo {
                            document.setSolo(false)
                        } else {
                            document.selectionID = id
                            document.setSolo(true)
                        }
                    }
                    .help("Solo: play only this item")
                Image(systemName: locked.contains(id) ? "lock.fill" : "lock.open").font(.system(size: 9))
                    .foregroundStyle(locked.contains(id) ? Theme.text : Theme.dim)
                    .frame(width: 16, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture { if locked.contains(id) { locked.remove(id) } else { locked.insert(id) } }
                    .help("Lock: the strip cannot be moved or resized")
            }
            if row.depth == 0, let id = row.nodeID, let add = document.node(id + "/Item")?.actions.first(where: { $0.title == "Add Item" }) {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.text)
                    .frame(width: 16, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture {
                        let before = Set(document.sequencerRows.map(\.id))
                        let frame = clock.time.rounded()
                        add.perform()
                        if let fresh = document.sequencerRows.first(where: { !before.contains($0.id) && $0.id.hasPrefix(id + "/") }), let start = fresh.startField {
                            let shift = frame - fresh.start
                            if shift != 0 {
                                func value(_ field: PropField, _ v: Double) -> FieldValue { if case .int = field.kind { return .int(Int(v)) }; return .double(v) }
                                start.write?(value(start, (start.read().number ?? 0) + shift))
                                if let finish = fresh.endField, !fresh.openEnded { finish.write?(value(finish, (finish.read().number ?? 0) + shift)) }
                                document.amendLastUndo()
                            }
                            document.selectionID = fresh.nodeID
                        }
                    }
                    .help("Add an item to this timeline at the playhead")
            }
        }
        .opacity(row.enabledField.map { $0.read() == .bool(true) ? 1 : 0.55 } ?? 1)
        .contextMenu {
            if let id = row.nodeID, let node = document.node(id) {
                if let target = renameTarget(row) { Button("Rename…") { AppDelegate.model?.renameNode(target) } }
                Button("Copy Parameters") { ParameterClipboard.copy(node, in: document) }
                Button("Paste Parameters") { ParameterClipboard.paste(into: node, in: document) }
                if row.depth > 0, node.actions.contains(where: { $0.title == "Duplicate" }) {
                    Button("Duplicate at Playhead") { duplicateAtPlayhead(row) }
                }
                Divider()
                ForEach(node.actions) { action in Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform) }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: rowHeight)
        .background(document.selectionID == row.nodeID ? Theme.selection : index % 2 == 1 ? Color.white.opacity(0.025) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = row.nodeID }
    }

    var body: some View {
        let rows = document.sequencerRows
        let densityPeak = document.density.mapValues { $0.max() ?? 0 }
        let duration = max(30, (rows.map(\.end).max() ?? 30).rounded(.up))
        let end = clock.endFrame ?? duration
        let span = currentSpan(max(end, duration))
        VStack(spacing: 0) {
            FlowLayout(spacing: 6) {
                HStack(spacing: 6) {
                    HeaderButton(symbol: "backward.end.fill", help: "Jump to start") { clock.rewind() }
                    HeaderButton(symbol: "backward.frame.fill", help: "Step one frame back") {
                        clock.playing = false
                        clock.time = max(0, (clock.time - 1).rounded())
                    }
                    HeaderButton(symbol: clock.playing ? "pause.fill" : "play.fill", active: clock.playing, help: "Play / Pause") { clock.playing.toggle() }
                    HeaderButton(symbol: "forward.frame.fill", help: "Step one frame forward") {
                        clock.playing = false
                        clock.time = (clock.time + 1).rounded()
                    }
                    HeaderButton(symbol: "forward.end.fill", help: "Jump to end") { clock.time = end }
                    HeaderButton(symbol: "repeat", active: clock.loop, help: "Loop playback") { clock.loop.toggle() }
                    SoloButton(document: document)
                    HeaderButton(symbol: "lock.open", help: "Release loop points: held particles and emitters play out") { clock.release() }
                    triggerMenu
                }
                .fixedSize()
                HStack(spacing: 6) {
                    NumberField(label: "Frame", value: clock.time, isInteger: true, onLive: { clock.time = max(0, $0) },
                                onCommit: { _, next in clock.time = max(0, next) })
                        .frame(width: 100)
                    NumberField(label: "Start", value: clock.startFrame, isInteger: true, onLive: { clock.startFrame = min(max(0, $0.rounded()), end - 1) },
                                onCommit: { _, next in clock.startFrame = min(max(0, next.rounded()), end - 1) })
                        .frame(width: 96)
                        .help("First frame of playback. Drag the edges of the range on the ruler to set it by hand")
                    NumberField(label: "End", value: end, isInteger: true, onLive: { clock.endFrame = max(1, $0.rounded()) },
                                onCommit: { _, next in clock.endFrame = max(1, next.rounded()) })
                        .frame(width: 92)
                        .help("Last frame of playback. The timeline scale stays fixed to this range")
                    HeaderButton(symbol: "arrow.uturn.backward", active: clock.endFrame != nil || clock.startFrame > 0,
                                 help: "Use the effect's own length (\(Int(duration)) frames)") {
                        clock.endFrame = nil
                        clock.startFrame = 0
                    }
                    HeaderButton(symbol: "clock", active: showSeconds, help: "Show seconds instead of frames on the ruler") { showSeconds.toggle() }
                    ChoiceField(choices: [FieldChoice(name: "0.1×", value: 10), FieldChoice(name: "0.25×", value: 25), FieldChoice(name: "0.5×", value: 50),
                                          FieldChoice(name: "1×", value: 100), FieldChoice(name: "2×", value: 200)],
                                value: Int((clock.speed * 100).rounded())) { clock.speed = Double($0) / 100 }
                        .frame(width: 64)
                        .help("Playback speed")
                    NumberField(label: "Seed", value: Double(clock.seed), isInteger: true, onLive: { _ in },
                                onCommit: { _, next in clock.seed = Int(min(max(next, 0), 999_999)) })
                        .frame(width: 92)
                        .help("Random seed of the preview. Another seed plays another variation of the same effect")
                    HeaderButton(symbol: "chart.xyaxis.line", active: showDensity, help: "Show how many particles are alive on each frame inside the strips") {
                        showDensity.toggle()
                        if showDensity { document.scheduleDensity() }
                    }
                    .onAppear { if showDensity { document.scheduleDensity() } }
                    .onChange(of: document.previewRevision) { _, _ in if showDensity { document.scheduleDensity() } }
                    .onChange(of: document.id) { _, _ in if showDensity { document.scheduleDensity() } }
                    HeaderButton(symbol: "dot.squareshape.split.2x2", active: snapping,
                                 help: "Snap: a dragged strip sticks to the playhead, the playback range and the edges of other strips") { snapping.toggle() }
                    Slider(value: $viewZoom, in: 1...40).controlSize(.mini).frame(width: 70).help("Timeline zoom")
                    HeaderButton(symbol: "arrow.left.and.right.square", active: viewZoom > 1.001, help: "Fit To Contents: reset the timeline zoom") {
                        viewZoom = 1
                        viewStart = 0
                    }
                }
                .fixedSize()
                Text(clock.status.isEmpty ? "30 fps" : clock.status + " · 30 fps").font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                    .frame(height: 20)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel)
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: rulerHeight)
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            rowLabel(index, row)
                        }
                    }
                    .frame(width: labelWidth)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    GeometryReader { geometry in
                        Canvas { context, canvasSize in
                            let width = canvasSize.width
                            let step: Double = span > 400 ? 50 : span > 160 ? 20 : span > 60 ? 10 : 5
                            var t = 0.0
                            while t <= span {
                                var line = Path()
                                line.move(to: CGPoint(x: x(t, width, span), y: rulerHeight))
                                line.addLine(to: CGPoint(x: x(t, width, span), y: canvasSize.height))
                                context.stroke(line, with: .color(Color.white.opacity(0.06)), lineWidth: 1)
                                context.draw(Text(stamp(t)).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: x(t, width, span) + 3, y: 9), anchor: .leading)
                                t += step
                            }
                            context.fill(Path(CGRect(x: 0, y: 0, width: width, height: rulerHeight)), with: .color(Color.black.opacity(0.25)))
                            for (index, row) in rows.enumerated() {
                                let top = rulerHeight + CGFloat(index) * rowHeight
                                if index % 2 == 1 {
                                    context.fill(Path(CGRect(x: 0, y: top, width: width, height: rowHeight)), with: .color(Color.white.opacity(0.025)))
                                }
                                let bar = CGRect(x: x(row.start, width, span), y: top + (row.depth == 0 ? 7 : 3), width: max(x(row.end, width, span) - x(row.start, width, span), 3),
                                                 height: row.depth == 0 ? 6 : rowHeight - 6)
                                let selected = document.selectionID == row.nodeID
                                let shape = Path(roundedRect: bar, cornerRadius: 3)
                                let barTint = row.depth > 0 ? (Appearance.barColor ?? row.tint.color) : row.tint.color
                                if row.openEnded {
                                    context.fill(shape, with: .linearGradient(Gradient(colors: [barTint.opacity(0.85), barTint.opacity(0.1)]),
                                                                              startPoint: CGPoint(x: bar.minX, y: 0), endPoint: CGPoint(x: bar.maxX, y: 0)))
                                } else {
                                    context.fill(shape, with: .color(barTint.opacity(row.depth == 0 ? 0.55 : 0.8)))
                                }
                                if showDensity, let values = document.density[row.densityKey], let peak = densityPeak[row.densityKey], peak > 0 {
                                    let area = row.depth == 0 ? CGRect(x: bar.minX, y: top + 2, width: bar.width, height: rowHeight - 4) : bar.insetBy(dx: 0, dy: 1)
                                    let first = max(0, Int(row.start.rounded(.down))), last = min(values.count - 1, Int(row.end.rounded(.up)))
                                    if last > first {
                                        var fill = Path()
                                        var line = Path()
                                        fill.move(to: CGPoint(x: x(Double(first), width, span), y: area.minY))
                                        for frame in first...last {
                                            let point = CGPoint(x: min(max(x(Double(frame), width, span), area.minX), area.maxX),
                                                                y: area.maxY - CGFloat(values[frame] / peak) * area.height)
                                            fill.addLine(to: point)
                                            if frame == first { line.move(to: point) } else { line.addLine(to: point) }
                                        }
                                        fill.addLine(to: CGPoint(x: min(x(Double(last), width, span), area.maxX), y: area.minY))
                                        fill.closeSubpath()
                                        context.drawLayer { layer in
                                            layer.clip(to: Path(roundedRect: area, cornerRadius: 3))
                                            layer.fill(fill, with: .color(Color.black.opacity(row.depth == 0 ? 0.3 : 0.42)))
                                            layer.stroke(line, with: .color(Color.white.opacity(0.9)), lineWidth: 1)
                                        }
                                    }
                                }
                                if let loop = row.loop {
                                    let from = x(loop.start, width, span), to = x(loop.end, width, span)
                                    var mark = Path()
                                    mark.move(to: CGPoint(x: from, y: bar.maxY - 3))
                                    mark.addLine(to: CGPoint(x: from, y: bar.maxY))
                                    mark.addLine(to: CGPoint(x: to, y: bar.maxY))
                                    mark.addLine(to: CGPoint(x: to, y: bar.maxY - 3))
                                    context.stroke(mark, with: .color(Color(red: 1, green: 0.85, blue: 0.3)), lineWidth: 1.5)
                                }
                                if let id = row.nodeID, locked.contains(id) {
                                    context.fill(shape, with: .color(Color.black.opacity(0.3)))
                                }
                                if row.endField != nil && !row.openEnded {
                                    context.fill(Path(CGRect(x: bar.maxX - 4, y: bar.minY + 2, width: 2, height: bar.height - 4)), with: .color(Color.black.opacity(0.35)))
                                }
                                if row.startField != nil && bar.width > 14 {
                                    context.fill(Path(CGRect(x: bar.minX + 2, y: bar.minY + 2, width: 2, height: bar.height - 4)), with: .color(Color.black.opacity(0.35)))
                                }
                                if selected { context.stroke(shape, with: .color(Appearance.barSelectedColor), lineWidth: 1.5) }
                            }
                            let endX = x(end, width, span)
                            context.fill(Path(CGRect(x: endX, y: rulerHeight, width: max(width - endX, 0), height: canvasSize.height - rulerHeight)),
                                         with: .color(Color.black.opacity(0.28)))
                            context.fill(Path(CGRect(x: 0, y: rulerHeight, width: max(x(clock.startFrame, width, span), 0), height: canvasSize.height - rulerHeight)),
                                         with: .color(Color.black.opacity(0.28)))
                            var endLine = Path()
                            endLine.move(to: CGPoint(x: endX, y: 0))
                            endLine.addLine(to: CGPoint(x: endX, y: canvasSize.height))
                            context.stroke(endLine, with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.8)), lineWidth: 1)
                            let px = x(clock.time, width, span)
                            var playhead = Path()
                            playhead.move(to: CGPoint(x: px, y: 0))
                            playhead.addLine(to: CGPoint(x: px, y: canvasSize.height))
                            context.stroke(playhead, with: .color(Theme.playhead), lineWidth: 1.5)
                            let box = CGRect(x: px - 16, y: 1, width: 32, height: rulerHeight - 2)
                            context.fill(Path(roundedRect: box, cornerRadius: 3), with: .color(Theme.playhead))
                            if clock.startFrame > 0 {
                                let startX = x(clock.startFrame, width, span)
                                var startLine = Path()
                                startLine.move(to: CGPoint(x: startX, y: 0))
                                startLine.addLine(to: CGPoint(x: startX, y: canvasSize.height))
                                context.stroke(startLine, with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.8)), lineWidth: 1)
                            }
                            var range = Path()
                            range.addRect(CGRect(x: x(clock.startFrame, width, span), y: rulerHeight - 3, width: max(endX - x(clock.startFrame, width, span), 0), height: 3))
                            context.fill(range, with: .color(Color(red: 1, green: 0.63, blue: 0.16).opacity(0.7)))
                            context.draw(Text(stamp(clock.time)).font(Theme.small).foregroundStyle(.white), at: CGPoint(x: px, y: rulerHeight / 2))
                        }
                        .background(ScrollMonitor(
                            onScroll: { delta, flags, point in
                                if flags.contains(.command) {
                                    zoomTimeline(1 + Double(delta.height) * 0.01, at: point.x, width: geometry.size.width, span: span)
                                } else if abs(delta.width) > abs(delta.height) {
                                    viewStart = max(0, viewStart - Double(delta.width / max(geometry.size.width, 1)) * span / viewZoom)
                                }
                            },
                            onMagnify: { amount, point in zoomTimeline(1 + Double(amount), at: point.x, width: geometry.size.width, span: span) }))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .updating($pressing) { _, state, _ in state = true }
                            .onChanged { drag in handleDrag(drag, rows: rows, width: geometry.size.width, span: span) }
                            .onEnded { _ in endDrag() })
                        .onChange(of: pressing) { _, now in if !now { endDrag() } }
                    }
                    .frame(height: rulerHeight + CGFloat(rows.count) * rowHeight + 8)
                }
            }
            .background(Theme.gray(0.157))
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear { labelWidth = min(max(geometry.size.width * 0.2, 200), 320) }
                .onChange(of: geometry.size.width) { _, width in labelWidth = min(max(width * 0.2, 200), 320) }
        })
    }

    private func zoomTimeline(_ factor: Double, at px: CGFloat, width: CGFloat, span: Double) {
        let anchor = time(px, width, span)
        viewZoom = min(max(viewZoom * factor, 1), 40)
        let shifted = time(px, width, span)
        viewStart = viewZoom <= 1.001 ? 0 : max(0, viewStart + anchor - shifted)
    }

    private func handleDrag(_ drag: DragGesture.Value, rows: [SequencerRow], width: CGFloat, span liveValue: Double) {
        if dragMode == 0 {
            dragMode = 1
            frozenSpan = liveValue
            liveSpan = liveValue
            let index = Int((drag.startLocation.y - rulerHeight) / rowHeight)
            if drag.startLocation.y <= rulerHeight {
                let finish = clock.endFrame ?? max(30, (rows.map(\.end).max() ?? 30).rounded(.up))
                if abs(drag.startLocation.x - x(finish, width, liveValue)) <= 5 {
                    dragMode = 6
                } else if abs(drag.startLocation.x - x(clock.startFrame, width, liveValue)) <= 5 {
                    dragMode = 5
                }
            }
            if drag.startLocation.y > rulerHeight, index >= 0, index < rows.count {
                let row = rows[index]
                document.selectionID = row.nodeID
                if let id = row.nodeID, locked.contains(id) { return }
                let left = x(row.start, width, liveValue), right = x(row.end, width, liveValue)
                if drag.startLocation.x >= left - 4, drag.startLocation.x <= right + 4, row.startField != nil || row.endField != nil {
                    dragRow = row
                    dragStart = row.startField?.read().number ?? 0
                    dragEnd = row.endField?.read().number ?? 0
                    let resizable = row.endField != nil && !row.openEnded
                    let wide = right - left > 16
                    if resizable, drag.startLocation.x > right - 7 {
                        dragMode = 3
                    } else if resizable, wide, row.startField != nil, drag.startLocation.x < left + 7 {
                        dragMode = 4
                    } else {
                        dragMode = 2
                    }
                }
            }
        }
        let span = liveSpan
        if dragMode == 1 {
            clock.time = max(0, time(drag.location.x, width, span).rounded())
            return
        }
        if dragMode == 5 || dragMode == 6 {
            let frame = max(0, time(drag.location.x, width, span).rounded())
            let finish = clock.endFrame ?? max(30, (rows.map(\.end).max() ?? 30).rounded(.up))
            if dragMode == 5 { clock.startFrame = min(frame, finish - 1) } else { clock.endFrame = max(frame, clock.startFrame + 1) }
            return
        }
        guard let row = dragRow, abs(drag.translation.width) > 2 else { return }
        let delta = (Double(drag.translation.width / max(width, 1)) * span / viewZoom).rounded()
        func value(_ field: PropField, _ v: Double) -> FieldValue { if case .int = field.kind { return .int(Int(v)) }; return .double(v) }
        if dragMode == 2 {
            var shift = max(delta, -dragStart)
            let byStart = snapped(dragStart + shift, row, width, span)
            if byStart != dragStart + shift {
                shift = byStart - dragStart
            } else if !row.openEnded, dragEnd > 0 {
                shift = snapped(dragEnd + shift, row, width, span) - dragEnd
            }
            shift = max(shift, -dragStart)
            if let start = row.startField { start.write?(value(start, dragStart + shift)) }
            if let end = row.endField, !row.openEnded, dragEnd > 0 { end.write?(value(end, dragEnd + shift)) }
        } else if dragMode == 3, let end = row.endField {
            end.write?(value(end, max(dragStart + 1, snapped(dragEnd + delta, row, width, span))))
        } else if dragMode == 4, let start = row.startField {
            start.write?(value(start, min(max(0, snapped(dragStart + delta, row, width, span)), dragEnd - 1)))
        }
        document.liveDrag()
    }

    private func endDrag() {
        defer {
            dragMode = 0
            dragRow = nil
            frozenSpan = nil
        }
        guard dragMode >= 2, let row = dragRow else { return }
        let fields = [(row.startField, dragStart), (row.endField, dragEnd)].compactMap { pair in pair.0.map { ($0, pair.1) } }
        let before = fields.map { field, original -> (PropField, FieldValue, FieldValue) in
            let now = field.read()
            let old: FieldValue = { if case .int = field.kind { return .int(Int(original)) }; return .double(original) }()
            return (field, old, now)
        }
        guard before.contains(where: { $0.1 != $0.2 }) else { return }
        document.registerUndo("Move Strip", undo: { before.forEach { $0.0.write?($0.1) } }, redo: { before.forEach { $0.0.write?($0.2) } })
    }
}
