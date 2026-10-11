import SwiftUI

struct SequencerView: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
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
    private func x(_ t: Double, _ width: CGFloat, _ span: Double) -> CGFloat { CGFloat((t + 2) / span) * width }
    private func time(_ px: CGFloat, _ width: CGFloat, _ span: Double) -> Double { Double(px / max(width, 1)) * span - 2 }

    private var triggerMenu: some View {
        Menu {
            ForEach(0..<max(document.triggerCount, 1), id: \.self) { index in
                Button("Trigger \(index)") { clock.trigger(index) }
            }
        } label: {
            Image(systemName: "bolt").font(.system(size: 11)).foregroundStyle(Theme.text).frame(width: 24, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.22)))
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
            if row.depth == 0, let id = row.nodeID, let add = document.node(id + "/Item")?.actions.first(where: { $0.title == "Add Item" }) {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.text)
                    .frame(width: 16, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture(perform: add.perform).help("Add an item to this timeline")
            }
        }
        .opacity(row.enabledField.map { $0.read() == .bool(true) ? 1 : 0.55 } ?? 1)
        .contextMenu {
            if let id = row.nodeID, let node = document.node(id) {
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
        let duration = max(30, (rows.map(\.end).max() ?? 30).rounded(.up))
        let end = clock.endFrame ?? duration
        let span = currentSpan(max(end, duration))
        VStack(spacing: 0) {
            FlowLayout(spacing: 6) {
                HStack(spacing: 6) {
                    HeaderButton(symbol: "backward.end.fill", help: "Jump to start") { clock.rewind() }
                    HeaderButton(symbol: clock.playing ? "pause.fill" : "play.fill", active: clock.playing, help: "Play / Pause") { clock.playing.toggle() }
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
                    NumberField(label: "End", value: end, isInteger: true, onLive: { clock.endFrame = max(1, $0.rounded()) },
                                onCommit: { _, next in clock.endFrame = max(1, next.rounded()) })
                        .frame(width: 92)
                        .help("Last frame of playback. The timeline scale stays fixed to this range")
                    HeaderButton(symbol: "arrow.uturn.backward", active: clock.endFrame != nil, help: "Use the effect's own length (\(Int(duration)) frames)") {
                        clock.endFrame = nil
                    }
                    ChoiceField(choices: [FieldChoice(name: "0.1×", value: 10), FieldChoice(name: "0.25×", value: 25), FieldChoice(name: "0.5×", value: 50),
                                          FieldChoice(name: "1×", value: 100), FieldChoice(name: "2×", value: 200)],
                                value: Int((clock.speed * 100).rounded())) { clock.speed = Double($0) / 100 }
                        .frame(width: 64)
                        .help("Playback speed")
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
                                context.draw(Text("\(Int(t))").font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: x(t, width, span) + 3, y: 9), anchor: .leading)
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
                                if row.openEnded {
                                    context.fill(shape, with: .linearGradient(Gradient(colors: [row.tint.color.opacity(0.85), row.tint.color.opacity(0.1)]),
                                                                              startPoint: CGPoint(x: bar.minX, y: 0), endPoint: CGPoint(x: bar.maxX, y: 0)))
                                } else {
                                    context.fill(shape, with: .color(row.tint.color.opacity(row.depth == 0 ? 0.55 : 0.8)))
                                }
                                if row.endField != nil && !row.openEnded {
                                    context.fill(Path(CGRect(x: bar.maxX - 4, y: bar.minY + 2, width: 2, height: bar.height - 4)), with: .color(Color.black.opacity(0.35)))
                                }
                                if row.startField != nil && bar.width > 14 {
                                    context.fill(Path(CGRect(x: bar.minX + 2, y: bar.minY + 2, width: 2, height: bar.height - 4)), with: .color(Color.black.opacity(0.35)))
                                }
                                if selected { context.stroke(shape, with: .color(.white), lineWidth: 1.5) }
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
                            context.draw(Text("\(Int(clock.time.rounded()))").font(Theme.small).foregroundStyle(.white), at: CGPoint(x: px, y: rulerHeight / 2))
                        }
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
            .background(Color(white: 0.157))
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear { labelWidth = min(max(geometry.size.width * 0.16, 140), 300) }
                .onChange(of: geometry.size.width) { _, width in labelWidth = min(max(width * 0.16, 140), 300) }
        })
    }

    private func handleDrag(_ drag: DragGesture.Value, rows: [SequencerRow], width: CGFloat, span liveValue: Double) {
        if dragMode == 0 {
            dragMode = 1
            frozenSpan = liveValue
            liveSpan = liveValue
            let index = Int((drag.startLocation.y - rulerHeight) / rowHeight)
            if drag.startLocation.y > rulerHeight, index >= 0, index < rows.count {
                let row = rows[index]
                document.selectionID = row.nodeID
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
        guard let row = dragRow, abs(drag.translation.width) > 2 else { return }
        let delta = (Double(drag.translation.width / max(width, 1)) * span).rounded()
        func value(_ field: PropField, _ v: Double) -> FieldValue { if case .int = field.kind { return .int(Int(v)) }; return .double(v) }
        if dragMode == 2 {
            let shift = max(delta, -dragStart)
            if let start = row.startField { start.write?(value(start, dragStart + shift)) }
            if let end = row.endField, !row.openEnded, dragEnd > 0 { end.write?(value(end, dragEnd + shift)) }
        } else if dragMode == 3, let end = row.endField {
            end.write?(value(end, max(dragStart + 1, dragEnd + delta)))
        } else if dragMode == 4, let start = row.startField {
            start.write?(value(start, min(max(0, dragStart + delta), dragEnd - 1)))
        }
        document.liveChanged()
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
