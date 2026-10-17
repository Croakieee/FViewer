import SwiftUI

struct SequencerView: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    @AppStorage("timeline.density") private var showDensity = true
    @AppStorage("timeline.seconds") private var showSeconds = false
    @AppStorage("timeline.snap") private var snapping = true
    @State private var locked: Set<String> = []
    @State private var collapsed: Set<Int> = []
    @State private var selectedEvent: UUID?
    @State private var hoverFrame: Double = 0

    @State private var dragMode = 0
    @State private var dragRow: SequencerRow?
    @State private var dragStart: Double = 0
    @State private var dragEnd: Double = 0
    @State private var eventDrag: (id: UUID, frame: Double)?
    @State private var labelWidth: CGFloat = 220
    @State private var frozenSpan: Double?
    @GestureState private var pressing = false
    @State private var liveSpan: Double = 64
    @State private var viewZoom: Double = 1
    @State private var viewStart: Double = 0

    private let rowHeight: CGFloat = 22
    private let rulerHeight: CGFloat = 22
    private let markerHeight: CGFloat = 24
    private var bodyTop: CGFloat { rulerHeight + markerHeight }

    private static let loopColor = Color(red: 1, green: 0.78, blue: 0.3)
    private static let rangeColor = Color(red: 1, green: 0.63, blue: 0.16)

    private func stamp(_ frame: Double) -> String {
        showSeconds ? String(format: "%.2f", frame / 30) : "\(Int(safe: frame.rounded()))"
    }

    private func currentSpan(_ end: Double) -> Double { frozenSpan ?? max(end, 1) * 1.08 + 4 }

    private func x(_ t: Double, _ width: CGFloat, _ span: Double) -> CGFloat { CGFloat((t + 2 / viewZoom - viewStart) / (span / viewZoom)) * width }
    private func time(_ px: CGFloat, _ width: CGFloat, _ span: Double) -> Double { Double(px / max(width, 1)) * (span / viewZoom) - 2 / viewZoom + viewStart }

    private func visibleRows(_ rows: [SequencerRow]) -> [SequencerRow] {
        rows.filter { $0.depth == 0 || !collapsed.contains($0.timeline ?? -1) }
    }

    private func effectLength(_ rows: [SequencerRow]) -> Double {
        max(30, (rows.map(\.end).max() ?? 30).rounded(.up), (clock.lastEventFrame + 10).rounded(.up))
    }

    private func renameTarget(_ row: SequencerRow) -> String? {
        guard let id = row.nodeID else { return nil }
        switch document.visibilityKey(forNodeID: id) {
        case .emitter(let index): return "avfx/Emit/\(index)"
        case .particle(let index): return "avfx/Ptcl/\(index)"
        case .timeline(let index): return "avfx/TmLn/\(index)"
        case nil: return document.node(id) != nil ? id : nil
        }
    }

    private func fieldValue(_ field: PropField, _ v: Double) -> FieldValue {
        if case .int = field.kind { return .int(Int(v)) }
        return .double(v)
    }

    private func snapped(_ frame: Double, _ row: SequencerRow, _ width: CGFloat, _ span: Double) -> Double {
        guard snapping else { return frame }
        let reach = 7 * (span / viewZoom) / Double(max(width, 1))
        var marks = [clock.time.rounded(), clock.startFrame] + clock.events.map(\.frame)
        if let end = clock.endFrame { marks.append(end) }
        for other in document.sequencerRows where other.id != row.id && other.depth > 0 {
            marks.append(other.start)
            if !other.openEnded { marks.append(other.end) }
        }
        let absolute = frame + row.base
        var best = absolute
        var nearest = reach
        for mark in marks where abs(mark - absolute) < nearest {
            nearest = abs(mark - absolute)
            best = mark
        }
        return best - row.base
    }

    private func placeAtPlayhead(_ fresh: SequencerRow) {
        guard let start = fresh.startField else { return }
        let shift = clock.time.rounded() - fresh.start
        if shift != 0 {
            start.write?(fieldValue(start, start.read().number + shift))
            if let finish = fresh.endField, !fresh.openEnded { finish.write?(fieldValue(finish, finish.read().number + shift)) }
            document.amendLastUndo()
        }
        document.selectionID = fresh.nodeID
    }

    private func duplicateAtPlayhead(_ row: SequencerRow) {
        guard let id = row.nodeID, let node = document.node(id), let duplicate = node.actions.first(where: { $0.title == "Duplicate" }) else { return }
        let before = document.sequencerRows.count
        duplicate.perform()
        let rows = document.sequencerRows
        guard rows.count > before, let at = rows.firstIndex(where: { $0.id == row.id }),
              let fresh = rows[(at + 1)...].first(where: { $0.depth == row.depth }) else { return }
        placeAtPlayhead(fresh)
    }

    private func addItem(to row: SequencerRow) {
        guard let id = row.nodeID, let add = document.node(id + "/Item")?.actions.first(where: { $0.title == "Add Item" }) else { return }
        let before = Set(document.sequencerRows.map(\.id))
        add.perform()
        if let timeline = row.timeline { collapsed.remove(timeline) }
        if let fresh = document.sequencerRows.first(where: { !before.contains($0.id) && $0.id.hasPrefix(id + "/") }) { placeAtPlayhead(fresh) }
    }

    private var triggerTitles: [(index: Int, title: String, usable: Bool)] {
        if document.avfxRoot != nil {
            return document.triggerSlots.enumerated().map { index, slot in
                let target = slot.timeline >= 0 ? " → " + document.timelineName(slot.timeline) : " · empty"
                return (index, EffectDocument.triggerName(index) + target + (slot.enabled ? "" : " · off"), slot.enabled && slot.timeline >= 0)
            }
        }
        return (0..<max(document.triggerCount, 1)).map { ($0, "Trigger \($0)", true) }
    }

    private func eventLabel(_ kind: PreviewEvent.Kind) -> String {
        if case .trigger(let index) = kind, document.avfxRoot != nil, let meaning = EffectDocument.triggerMeanings[index] { return "T\(index) · " + meaning }
        return EffectDocument.eventShort(kind)
    }

    private func eventColor(_ kind: PreviewEvent.Kind) -> Color {
        switch kind {
        case .trigger: return clock.isEnding(kind) ? Color(red: 0.98, green: 0.55, blue: 0.35) : Color(red: 0.42, green: 0.66, blue: 1)
        case .release: return Color(red: 1, green: 0.8, blue: 0.3)
        case .stop: return Color(red: 0.95, green: 0.42, blue: 0.38)
        }
    }

    private func eventHelp(_ event: PreviewEvent) -> String {
        let frame = Int(safe: event.frame)
        let tail = ". Drag to move, right-click to change, mute or delete"
        switch event.kind {
        case .trigger(let index):
            let slot = document.avfxRoot != nil && index < document.triggerSlots.count ? document.triggerSlots[index] : nil
            let target = slot.map { $0.timeline >= 0 ? "starts " + document.timelineName($0.timeline) : "its slot is empty" } ?? "starts its timeline"
            let ending = clock.isEnding(event.kind) ? ", which ends the effect (releases its loops or kills what runs)" : ""
            return EffectDocument.triggerName(index) + " at frame \(frame): the game fires it and it " + target + ending + tail
        case .release:
            return "Release at frame \(frame): the game lets go of the effect. Loops and open-ended items are released and it plays to the end" + tail
        case .stop:
            return "Remove at frame \(frame): the game deletes the effect at once" + tail
        }
    }

    @ViewBuilder private func eventKindButtons(_ choose: @escaping (PreviewEvent.Kind) -> Void, current: PreviewEvent.Kind?) -> some View {
        ForEach(triggerTitles, id: \.index) { entry in
            Button {
                choose(.trigger(entry.index))
            } label: {
                if current == .trigger(entry.index) { Label(entry.title, systemImage: "checkmark") } else { Text(entry.title) }
            }
            .disabled(!entry.usable && current != .trigger(entry.index))
        }
        Divider()
        Button {
            choose(.release)
        } label: {
            if current == .release { Label("Release", systemImage: "checkmark") } else { Text("Release") }
        }
        Button {
            choose(.stop)
        } label: {
            if current == .stop { Label("Remove", systemImage: "checkmark") } else { Text("Remove") }
        }
    }

    private func addEvent(_ kind: PreviewEvent.Kind, at frame: Double? = nil) {
        selectedEvent = clock.addEvent(kind, at: frame).id
        clock.playing = true
    }

    private func jumpToEvent(forward: Bool) {
        let now = clock.time.rounded()
        let frames = clock.events.map(\.frame)
        guard let target = forward ? frames.filter({ $0 > now }).min() : frames.filter({ $0 < now }).max() else { return }
        clock.playing = false
        clock.time = target
    }

    private func headerMenu<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        Menu(content: content) {
            Text(title).font(Theme.font).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 20)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private func toggleLabel(_ title: String, _ on: Bool) -> some View {
        Group { if on { Label(title, systemImage: "checkmark") } else { Text(title) } }
    }

    private func header(end: Double, length: Double, rows: [SequencerRow]) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 0) {
                headerMenu("View") {
                    Button { showSeconds.toggle() } label: { toggleLabel("Show Seconds", showSeconds) }
                    Button {
                        showDensity.toggle()
                        if showDensity { document.scheduleDensity() }
                    } label: { toggleLabel("Show Particle Count", showDensity) }
                    Button { snapping.toggle() } label: { toggleLabel("Snap", snapping) }
                    Divider()
                    Button("Frame All") {
                        viewZoom = 1
                        viewStart = 0
                    }
                    Button("Expand All Timelines") { collapsed = [] }
                    Button("Collapse All Timelines") { collapsed = Set(rows.compactMap { $0.depth == 0 ? $0.timeline : nil }) }
                }
                headerMenu("Marker") {
                    Menu("Add Game Event at Frame \(Int(safe: clock.time.rounded(.down)))") {
                        eventKindButtons({ addEvent($0) }, current: nil)
                    }
                    Divider()
                    Button("Jump to Previous Event") { jumpToEvent(forward: false) }.disabled(clock.events.isEmpty)
                    Button("Jump to Next Event") { jumpToEvent(forward: true) }.disabled(clock.events.isEmpty)
                    Divider()
                    Button("Delete Selected Event", role: .destructive) {
                        if let selectedEvent { clock.removeEvent(selectedEvent) }
                        selectedEvent = nil
                    }
                    .disabled(selectedEvent == nil || !clock.events.contains { $0.id == selectedEvent })
                    Button("Delete All Events", role: .destructive) { clock.events = [] }.disabled(clock.events.isEmpty)
                    if document.avfxRoot != nil {
                        Button("Reset to the Effect's Start") { clock.events = document.defaultEvents }
                    }
                }
                headerMenu("Playback") {
                    Button { clock.loop.toggle() } label: { toggleLabel("Loop", clock.loop) }
                    Menu("Speed") {
                        ForEach([0.1, 0.25, 0.5, 1, 2], id: \.self) { value in
                            Button { clock.speed = value } label: { toggleLabel(value == 1 ? "1×" : String(format: "%g×", value), abs(clock.speed - value) < 0.001) }
                        }
                    }
                    Divider()
                    Button { clock.lockSeed.toggle() } label: { toggleLabel("Keep Seed on Restart", clock.lockSeed) }
                    Button("New Seed") {
                        clock.seed = Int.random(in: 1...9999)
                        clock.rewind()
                    }
                    Divider()
                    Button("Use the Effect's Length (\(Int(safe: length)) Frames)") {
                        clock.endFrame = nil
                        clock.startFrame = 0
                    }
                    .disabled(clock.endFrame == nil && clock.startFrame == 0)
                }
            }
            .fixedSize()
            Spacer(minLength: 8)
            HStack(spacing: 2) {
                HeaderButton(symbol: "backward.end.fill", help: "Jump to start (⇧←)") { clock.rewind() }
                HeaderButton(symbol: "arrowtriangle.left.circle", help: "Jump to the previous game event") { jumpToEvent(forward: false) }
                HeaderButton(symbol: "backward.frame.fill", help: "Step one frame back (←)") {
                    clock.playing = false
                    clock.time = max(0, (clock.time - 1).rounded())
                }
                HeaderButton(symbol: clock.playing ? "pause.fill" : "play.fill", active: clock.playing, help: "Play / Pause (Space)") { clock.playing.toggle() }
                HeaderButton(symbol: "forward.frame.fill", help: "Step one frame forward (→)") {
                    clock.playing = false
                    clock.time = (clock.time + 1).rounded()
                }
                HeaderButton(symbol: "arrowtriangle.right.circle", help: "Jump to the next game event") { jumpToEvent(forward: true) }
                HeaderButton(symbol: "forward.end.fill", help: "Jump to end (⇧→)") { clock.time = end }
                NumberField(label: nil, value: clock.time, isInteger: true, onLive: { clock.time = max(0, $0) }, onCommit: { _, next in clock.time = max(0, next) })
                    .frame(width: 58)
                    .padding(.leading, 4)
                    .help("Current frame")
            }
            .fixedSize()
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                HeaderButton(symbol: "repeat", active: clock.loop, help: "Loop playback") { clock.loop.toggle() }
                NumberField(label: "Start", value: clock.startFrame, isInteger: true, onLive: { clock.startFrame = min(max(0, $0.rounded()), end - 1) },
                            onCommit: { _, next in clock.startFrame = min(max(0, next.rounded()), end - 1) })
                    .frame(width: 92)
                    .help("First frame of playback. Drag the edges of the range on the ruler to set it by hand")
                NumberField(label: "End", value: end, isInteger: true, onLive: { clock.endFrame = max(clock.startFrame + 1, $0.rounded()) },
                            onCommit: { _, next in clock.endFrame = max(clock.startFrame + 1, next.rounded()) })
                    .frame(width: 88)
                    .help("Last frame of playback")
                NumberField(label: "Seed", value: Double(clock.seed), isInteger: true, onLive: { _ in },
                            onCommit: { _, next in clock.seed = Int(min(max(next, 0), 999_999)) })
                    .frame(width: 88)
                    .help("Random seed of the preview. Another seed plays another variation of the same effect")
                HeaderButton(symbol: "chart.xyaxis.line", active: showDensity, help: "Show how many particles are alive on each frame inside the emitter strips") {
                    showDensity.toggle()
                    if showDensity { document.scheduleDensity() }
                }
                HeaderButton(symbol: "dot.squareshape.split.2x2", active: snapping,
                             help: "Snap: a dragged strip sticks to the playhead, the game events, the playback range and the edges of other strips") { snapping.toggle() }
            }
            .fixedSize()
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(Theme.panel)
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
    }

    private var eventsLabel: some View {
        HStack(spacing: 5) {
            Image(systemName: "flag.fill").font(.system(size: 9)).foregroundStyle(Theme.dim).frame(width: 12)
            Text("Game Events").font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            HelpBadge(text: "What the game sends to a running effect, replayed on every loop and kept next to the file, never inside it.\n\nTrigger n: starts the timeline in trigger slot n (0 end of animation, 1 interrupted, 2 mount landing, 3 takeoff, 4 sheathe, 5 draw, 8/9 crafting or gathering, 10 mount, 11 dismount). Orange triggers end the effect.\nRelease: the game lets go; loops are released and the effect plays out.\nRemove: the game deletes the effect at once.\n\nWithout an ending event the effect stays held, as in the game until it ends it. Muted events stay on the lane but do not play.")
            Spacer(minLength: 0)
            Menu {
                Section("Add at Frame \(Int(safe: clock.time.rounded(.down)))") {
                    eventKindButtons({ addEvent($0) }, current: nil)
                }
            } label: {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.text).frame(width: 18, height: markerHeight)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Add a game event at the playhead")
        }
        .padding(.horizontal, 6)
        .frame(height: markerHeight)
        .background(Theme.gray(0.19))
    }

    private func eventMarker(_ event: PreviewEvent, width: CGFloat, span: Double) -> some View {
        let frame = eventDrag?.id == event.id ? eventDrag?.frame ?? event.frame : event.frame
        let tint = eventColor(event.kind)
        let selected = selectedEvent == event.id
        return HStack(spacing: 3) {
            Image(systemName: "arrowtriangle.down.fill").font(.system(size: 9)).foregroundStyle(tint)
            Text(eventLabel(event.kind)).font(.system(size: 10, weight: selected ? .bold : .medium)).lineLimit(1)
                .foregroundStyle(selected ? Color.white : Theme.text)
                .strikethrough(event.muted)
        }
        .padding(.horizontal, 3)
        .frame(height: 16)
        .background(RoundedRectangle(cornerRadius: 3).fill(selected ? tint.opacity(0.45) : Theme.gray(0.16).opacity(0.85)))
        .opacity(event.muted ? 0.45 : 1)
        .fixedSize()
        .contentShape(Rectangle())
        .help((event.muted ? "Muted. " : "") + eventHelp(event))
        .onTapGesture {
            selectedEvent = event.id
            clock.playing = false
            clock.time = event.frame
        }
        .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .named("sequencerCanvas"))
            .onChanged { drag in
                selectedEvent = event.id
                var target = max(0, time(drag.location.x, width, span).rounded())
                if snapping, abs(target - clock.time.rounded()) <= 7 * (span / viewZoom) / Double(max(width, 1)) { target = clock.time.rounded() }
                eventDrag = (event.id, target)
            }
            .onEnded { _ in
                if let drag = eventDrag { clock.moveEvent(drag.id, to: drag.frame) }
                eventDrag = nil
            })
        .contextMenu {
            Section("Frame \(Int(safe: event.frame))") {
                eventKindButtons({ clock.setEventKind(event.id, $0) }, current: event.kind)
            }
            Divider()
            Button(event.muted ? "Unmute" : "Mute") { clock.setMuted(event.id, !event.muted) }
            Button("Delete Event", role: .destructive) {
                clock.removeEvent(event.id)
                if selectedEvent == event.id { selectedEvent = nil }
            }
        }
        .offset(x: x(frame, width, span) - 7, y: rulerHeight + (markerHeight - 16) / 2)
    }

    private func stateDot(_ row: SequencerRow) -> some View {
        let state = row.timeline.flatMap { clock.timelineStates[$0] }
        let waiting = !row.started
        let triggers = row.sources.compactMap { source -> Int? in if case .trigger(let index) = source { return index }; return nil }
        let help: String = {
            if waiting {
                if triggers.isEmpty { return "Nothing starts this timeline" }
                return "Waits for " + triggers.map { EffectDocument.triggerName($0) }.joined(separator: " or ") + ". Fire it with the bolt or add it on the Game Events lane"
            }
            return state.map(LifecycleBadge.help) ?? "Idle on this frame"
        }()
        return Circle()
            .strokeBorder(waiting ? Theme.dim : Color.clear, lineWidth: 1)
            .background(Circle().fill(waiting ? Color.clear : state.map(LifecycleBadge.color) ?? Theme.gray(0.3)))
            .frame(width: 7, height: 7)
            .frame(width: 12, height: rowHeight)
            .contentShape(Rectangle())
            .help(help)
    }

    @ViewBuilder private func fireButton(_ row: SequencerRow) -> some View {
        let triggers = row.sources.compactMap { source -> Int? in if case .trigger(let index) = source { return index }; return nil }
        if document.avfxRoot != nil, !triggers.isEmpty {
            let tint = row.started ? Theme.dim : Theme.playhead
            if triggers.count == 1 {
                Image(systemName: "bolt.fill").font(.system(size: 9)).foregroundStyle(tint)
                    .frame(width: 18, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture { addEvent(.trigger(triggers[0])) }
                    .help("Fire " + EffectDocument.triggerName(triggers[0]) + ": adds it on the Game Events lane at the playhead and plays")
            } else {
                Menu {
                    ForEach(triggers, id: \.self) { index in Button("Fire " + EffectDocument.triggerName(index)) { addEvent(.trigger(index)) } }
                } label: {
                    Image(systemName: "bolt.fill").font(.system(size: 9)).foregroundStyle(tint).frame(width: 18, height: rowHeight)
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Fire one of the triggers that start this timeline")
            }
        }
    }

    private func channelIcon(_ symbol: String, on: Bool, tint: Color = Theme.text, help: String, action: @escaping () -> Void) -> some View {
        Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(on ? tint : Theme.dim.opacity(0.8))
            .frame(width: 18, height: rowHeight).contentShape(Rectangle())
            .onTapGesture(perform: action)
            .help(help)
    }

    private func rowLabel(_ row: SequencerRow) -> some View {
        let changes = document.changes
        let selected = document.selectionID != nil && document.selectionID == row.nodeID
        let isHeader = row.depth == 0
        return HStack(spacing: 4) {
            if isHeader {
                let timeline = row.timeline ?? -1
                let open = !collapsed.contains(timeline)
                Image(systemName: open ? "chevron.down" : "chevron.right").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim)
                    .frame(width: 14, height: rowHeight).contentShape(Rectangle())
                    .onTapGesture { if open { collapsed.insert(timeline) } else { collapsed.remove(timeline) } }
                    .help(open ? "Collapse" : "Expand")
            } else {
                Color.clear.frame(width: 18)
            }
            if let clip = row.clip {
                Image(systemName: ClipStyle.symbol(clip.code)).font(.system(size: 9)).foregroundStyle(ClipStyle.color(clip.code)).frame(width: 10)
                    .help(EffectDocument.clipHelp(clip.code))
            } else {
                RoundedRectangle(cornerRadius: 2).fill(row.tint.color).frame(width: 9, height: 9)
            }
            Text(row.label).font(isHeader ? .system(size: 11, weight: .semibold) : Theme.font)
                .foregroundStyle(selected ? .white : Theme.text).lineLimit(1).truncationMode(.middle)
                .onTapGesture(count: 2) { if let target = renameTarget(row) { AppDelegate.model?.renameNode(target) } }
                .help(row.label + (row.clip.map { "\n" + EffectDocument.clipHelp($0.code) } ?? "") + "\nDouble-click to rename")
            if let id = row.nodeID, changes.contains(id) { ChangeDot(added: changes.added.contains(id)) }
            if isHeader, !row.sources.isEmpty {
                Text(row.sources.map(\.short).joined(separator: " ")).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1).fixedSize()
                    .help("Started by " + row.sources.map(\.name).joined(separator: ", ") + ". S = scheduler item (with the effect), T = trigger slot (by the game)")
            }
            Spacer(minLength: 0)
            if isHeader {
                fireButton(row)
                stateDot(row)
                if let id = row.nodeID, document.node(id + "/Item")?.actions.contains(where: { $0.title == "Add Item" }) == true {
                    channelIcon("plus", on: true, help: "Add an item to this timeline at the playhead") { addItem(to: row) }
                }
            } else {
                if let enabled = row.enabledField {
                    let value = enabled.read()
                    channelIcon(value == .bool(true) ? "checkmark.square.fill" : "square", on: value == .bool(true), help: "Enabled") {
                        document.commit(enabled, from: value, to: .bool(value != .bool(true)))
                    }
                }
                if let id = row.nodeID, row.clip == nil {
                    let solo = document.soloPreview && document.selectionID == id
                    channelIcon(solo ? "star.fill" : "star", on: solo, tint: Theme.changed, help: "Solo: play only this item") {
                        if solo {
                            document.setSolo(false)
                        } else {
                            document.selectionID = id
                            document.setSolo(true)
                        }
                    }
                } else {
                    Color.clear.frame(width: 18, height: rowHeight)
                }
                if let id = row.nodeID {
                    channelIcon(locked.contains(id) ? "lock.fill" : "lock.open", on: locked.contains(id), help: "Lock: the strip cannot be moved or resized") {
                        if locked.contains(id) { locked.remove(id) } else { locked.insert(id) }
                    }
                }
            }
        }
        .opacity((row.enabledField.map { $0.read() == .bool(true) ? 1 : 0.55 } ?? 1) * (row.started ? 1 : 0.7))
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
        .padding(.leading, 2)
        .padding(.trailing, 4)
        .frame(height: rowHeight)
        .background(selected ? Theme.selection : isHeader ? Theme.gray(0.2) : Color.clear)
        .overlay(Rectangle().fill(Theme.line.opacity(isHeader ? 0.8 : 0.35)).frame(height: 1), alignment: .bottom)
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = row.nodeID }
    }

    private func drawLabel(_ context: inout GraphicsContext, _ text: String, in rect: CGRect, color: Color, weight: Font.Weight = .medium) {
        guard rect.width > 12 else { return }
        let resolved = context.resolve(Text(text).font(.system(size: 10, weight: weight)).foregroundStyle(color))
        context.drawLayer { layer in
            layer.clip(to: Path(rect))
            layer.draw(resolved, at: CGPoint(x: rect.minX, y: rect.midY), anchor: .leading)
        }
    }

    private func drawRow(_ context: inout GraphicsContext, _ row: SequencerRow, top: CGFloat, width: CGFloat, span: Double, end: Double,
                         densityPeak: [String: Float], children: [SequencerRow]) {
        let selected = document.selectionID != nil && document.selectionID == row.nodeID
        let dim = row.started ? 1.0 : 0.4
        let mid = top + rowHeight / 2
        if row.depth == 0 {
            let reach = children.contains(where: \.openEnded) ? max(row.end, end) : row.end
            let bar = CGRect(x: x(row.start, width, span), y: mid - 3, width: max(x(reach, width, span) - x(row.start, width, span), 2), height: 6)
            context.fill(Path(roundedRect: bar, cornerRadius: 2), with: .color(row.tint.color.opacity(0.45 * dim)))
            if collapsed.contains(row.timeline ?? -1) {
                for child in children {
                    let cx = x(child.start, width, span)
                    if child.clip != nil {
                        var diamond = Path()
                        diamond.move(to: CGPoint(x: cx, y: mid - 5))
                        diamond.addLine(to: CGPoint(x: cx + 5, y: mid))
                        diamond.addLine(to: CGPoint(x: cx, y: mid + 5))
                        diamond.addLine(to: CGPoint(x: cx - 5, y: mid))
                        diamond.closeSubpath()
                        context.fill(diamond, with: .color(ClipStyle.color(child.clip?.code ?? "").opacity(dim)))
                    } else {
                        let to = child.openEnded ? max(child.end, end) : child.end
                        context.fill(Path(roundedRect: CGRect(x: cx, y: mid - 2, width: max(x(to, width, span) - cx, 2), height: 4), cornerRadius: 1),
                                     with: .color(child.tint.color.opacity(0.9 * dim)))
                    }
                }
            }
            if let loop = row.loop {
                let from = x(loop.start, width, span), to = x(loop.end, width, span)
                let band = CGRect(x: from, y: top + 2, width: max(to - from, 2), height: rowHeight - 4)
                context.fill(Path(roundedRect: band, cornerRadius: 3), with: .color(SequencerView.loopColor.opacity(0.16 * dim)))
                context.stroke(Path(roundedRect: band, cornerRadius: 3), with: .color(SequencerView.loopColor.opacity(0.85 * dim)), lineWidth: 1)
                drawLabel(&context, "↻ Loop \(stamp(loop.start - row.base))–\(stamp(loop.end - row.base))", in: band.insetBy(dx: 4, dy: 0),
                          color: SequencerView.loopColor.opacity(dim), weight: .semibold)
            }
            if selected { context.stroke(Path(roundedRect: bar.insetBy(dx: -1, dy: -1), cornerRadius: 2), with: .color(Appearance.barSelectedColor), lineWidth: 1) }
            return
        }
        if let clip = row.clip {
            let cx = x(row.start, width, span)
            let color = ClipStyle.color(clip.code)
            if clip.code == "KILL", clip.fade > 0 {
                var wedge = Path()
                let fx = x(row.start + Double(clip.fade), width, span)
                wedge.move(to: CGPoint(x: cx, y: top + 4))
                wedge.addLine(to: CGPoint(x: fx, y: mid))
                wedge.addLine(to: CGPoint(x: cx, y: top + rowHeight - 4))
                wedge.closeSubpath()
                context.fill(wedge, with: .color(color.opacity(0.3 * dim)))
            }
            var diamond = Path()
            diamond.move(to: CGPoint(x: cx, y: top + 4))
            diamond.addLine(to: CGPoint(x: cx + 7, y: mid))
            diamond.addLine(to: CGPoint(x: cx, y: top + rowHeight - 4))
            diamond.addLine(to: CGPoint(x: cx - 7, y: mid))
            diamond.closeSubpath()
            context.fill(diamond, with: .color(color.opacity(dim)))
            if selected { context.stroke(diamond, with: .color(Appearance.barSelectedColor), lineWidth: 1.5) }
            if let id = row.nodeID, locked.contains(id) { context.fill(diamond, with: .color(Color.black.opacity(0.3))) }
            let after = clip.code == "KILL" && clip.fade > 0 ? max(cx + 11, x(row.start + Double(clip.fade), width, span) + 4) : cx + 11
            drawLabel(&context, row.label, in: CGRect(x: after, y: top, width: max(width - after, 0), height: rowHeight), color: color.opacity(dim))
            return
        }
        let reach = row.openEnded ? max(row.end, end) : row.end
        let bar = CGRect(x: x(row.start, width, span), y: top + 3, width: max(x(reach, width, span) - x(row.start, width, span), 3), height: rowHeight - 6)
        let shape = Path(roundedRect: bar, cornerRadius: 3)
        let tint = row.tint == .emitter ? (Appearance.barColor ?? row.tint.color) : row.tint.color
        let enabled = row.enabledField.map { $0.read() == .bool(true) } ?? true
        let strength = (enabled ? 1 : 0.45) * dim
        context.fill(shape, with: .color(tint.opacity((selected ? 0.95 : 0.72) * strength)))
        if !enabled {
            context.drawLayer { layer in
                layer.clip(to: shape)
                var hatch = Path()
                var hx = bar.minX - bar.height
                while hx < bar.maxX {
                    hatch.move(to: CGPoint(x: hx, y: bar.maxY))
                    hatch.addLine(to: CGPoint(x: hx + bar.height, y: bar.minY))
                    hx += 6
                }
                layer.stroke(hatch, with: .color(Color.black.opacity(0.35)), lineWidth: 1)
            }
        }
        var graphed = false
        if showDensity, row.started, let values = document.density[row.densityKey], let peak = densityPeak[row.densityKey], peak > 0 {
            graphed = true
            let area = bar.insetBy(dx: 0, dy: 1)
            let first = max(0, Int(safe: row.start.rounded(.down))), last = min(values.count - 1, Int(safe: reach.rounded(.up)))
            if last > first {
                var fill = Path()
                var line = Path()
                fill.move(to: CGPoint(x: x(Double(first), width, span), y: area.minY))
                for frame in first...last {
                    let point = CGPoint(x: min(max(x(Double(frame), width, span), area.minX), area.maxX), y: area.maxY - CGFloat(values[frame] / peak) * area.height)
                    fill.addLine(to: point)
                    if frame == first { line.move(to: point) } else { line.addLine(to: point) }
                }
                fill.addLine(to: CGPoint(x: min(x(Double(last), width, span), area.maxX), y: area.minY))
                fill.closeSubpath()
                context.drawLayer { layer in
                    layer.clip(to: Path(roundedRect: area, cornerRadius: 3))
                    layer.fill(fill, with: .color(Color.black.opacity(0.42)))
                    layer.stroke(line, with: .color(Color.white.opacity(0.9)), lineWidth: 1)
                }
            }
        }
        if let loop = row.loop {
            let from = max(x(loop.start, width, span), bar.minX), to = min(x(loop.end, width, span), bar.maxX)
            if to > from {
                let band = CGRect(x: from, y: bar.maxY - 4, width: to - from, height: 3)
                context.fill(Path(roundedRect: band, cornerRadius: 1), with: .color(SequencerView.loopColor.opacity(0.95 * strength)))
            }
        }
        if let id = row.nodeID, locked.contains(id) { context.fill(shape, with: .color(Color.black.opacity(0.3))) }
        if row.endField != nil && !row.openEnded && bar.width > 10 {
            context.fill(Path(CGRect(x: bar.maxX - 4, y: bar.minY + 3, width: 1.5, height: bar.height - 6)), with: .color(Color.black.opacity(0.35)))
        }
        if row.startField != nil && bar.width > 14 {
            context.fill(Path(CGRect(x: bar.minX + 2.5, y: bar.minY + 3, width: 1.5, height: bar.height - 6)), with: .color(Color.black.opacity(0.35)))
        }
        var labelRect = bar.insetBy(dx: 7, dy: 0)
        if row.openEnded {
            let infinity = context.resolve(Text("∞").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.black.opacity(0.75)))
            context.draw(infinity, at: CGPoint(x: bar.maxX - 5, y: bar.midY), anchor: .trailing)
            labelRect.size.width -= 14
        }
        if labelRect.width >= 30 {
            drawLabel(&context, row.label, in: labelRect, color: graphed ? Color.white.opacity(0.95) : Color.black.opacity(0.85))
        } else {
            drawLabel(&context, row.label, in: CGRect(x: bar.maxX + 5, y: top, width: max(width - bar.maxX - 5, 0), height: rowHeight), color: Theme.dim)
        }
        if selected { context.stroke(shape, with: .color(Appearance.barSelectedColor), lineWidth: 1.5) }
    }

    var body: some View {
        let allRows = document.sequencerRows
        let rows = visibleRows(allRows)
        let densityPeak = document.density.mapValues { $0.max() ?? 0 }
        let length = effectLength(allRows)
        let end = clock.endFrame ?? length
        let selectedRow = allRows.first { $0.nodeID != nil && $0.nodeID == document.selectionID }
        let highlighted = highlightedTimelines(selectedRow)
        let span = currentSpan(max(end, length))
        VStack(spacing: 0) {
            header(end: end, length: length, rows: allRows)
                .onAppear { if showDensity { document.scheduleDensity() } }
                .onChange(of: document.previewRevision) { _, _ in if showDensity { document.scheduleDensity() } }
                .onChange(of: document.id) { _, _ in
                    locked = []
                    collapsed = []
                    selectedEvent = nil
                    if showDensity { document.scheduleDensity() }
                }
                .onChange(of: allRows.count) { _, _ in locked = [] }
                .onChange(of: clock.events) { _, _ in
                    document.densityRevision = -1
                    if showDensity { document.scheduleDensity() }
                }
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: rulerHeight).background(Theme.gray(0.13))
                        eventsLabel
                        ForEach(rows, id: \.id) { row in
                            rowLabel(row)
                                .background(row.timeline.map { highlighted.contains($0) } == true ? ClipStyle.color(selectedRow?.clip?.code ?? "").opacity(0.16) : Color.clear)
                        }
                    }
                    .frame(width: labelWidth)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    GeometryReader { geometry in
                        Canvas { context, canvasSize in
                            let width = canvasSize.width
                            context.fill(Path(CGRect(x: 0, y: 0, width: width, height: rulerHeight)), with: .color(Theme.gray(0.13)))
                            context.fill(Path(CGRect(x: 0, y: rulerHeight, width: width, height: markerHeight)), with: .color(Theme.gray(0.19)))
                            for (index, row) in rows.enumerated() where row.depth == 0 {
                                let top = bodyTop + CGFloat(index) * rowHeight
                                context.fill(Path(CGRect(x: 0, y: top, width: width, height: rowHeight)), with: .color(Theme.gray(0.2)))
                            }
                            let base: Double = span / viewZoom > 400 ? 50 : span / viewZoom > 160 ? 20 : span / viewZoom > 60 ? 10 : 5
                            let step = span / viewZoom / base > 200 ? (span / viewZoom / 200 / 50).rounded(.up) * 50 : base
                            var t = 0.0
                            while t <= span + viewStart {
                                let px = x(t, width, span)
                                if px >= -40 && px <= width + 40 {
                                    var line = Path()
                                    line.move(to: CGPoint(x: px, y: rulerHeight - 5))
                                    line.addLine(to: CGPoint(x: px, y: canvasSize.height))
                                    context.stroke(line, with: .color(Theme.text.opacity(0.07)), lineWidth: 1)
                                    context.draw(Text(stamp(t)).font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: px, y: rulerHeight / 2 - 1))
                                }
                                t += step
                            }
                            for (index, row) in rows.enumerated() {
                                let top = bodyTop + CGFloat(index) * rowHeight
                                if let timeline = row.timeline, highlighted.contains(timeline) {
                                    context.fill(Path(CGRect(x: 0, y: top, width: width, height: rowHeight)),
                                                 with: .color(ClipStyle.color(selectedRow?.clip?.code ?? "").opacity(0.14)))
                                }
                                if document.selectionID != nil, document.selectionID == row.nodeID {
                                    context.fill(Path(CGRect(x: 0, y: top, width: width, height: rowHeight)), with: .color(Theme.selection.opacity(0.25)))
                                }
                                context.fill(Path(CGRect(x: 0, y: top + rowHeight - 1, width: width, height: 1)), with: .color(Theme.line.opacity(row.depth == 0 ? 0.8 : 0.35)))
                                let children = row.depth == 0 ? allRows.filter { $0.depth > 0 && $0.timeline == row.timeline } : []
                                drawRow(&context, row, top: top, width: width, span: span, end: end, densityPeak: densityPeak, children: children)
                            }
                            for event in clock.events {
                                let frame = eventDrag?.id == event.id ? eventDrag?.frame ?? event.frame : event.frame
                                var line = Path()
                                line.move(to: CGPoint(x: x(frame, width, span), y: bodyTop))
                                line.addLine(to: CGPoint(x: x(frame, width, span), y: canvasSize.height))
                                context.stroke(line, with: .color(eventColor(event.kind).opacity(event.muted ? 0.15 : selectedEvent == event.id ? 0.8 : 0.45)),
                                               style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            }
                            let startX = x(clock.startFrame, width, span), endX = x(end, width, span)
                            context.fill(Path(CGRect(x: endX, y: rulerHeight, width: max(width - endX, 0), height: canvasSize.height - rulerHeight)),
                                         with: .color(Color.black.opacity(0.22)))
                            context.fill(Path(CGRect(x: 0, y: rulerHeight, width: max(startX, 0), height: canvasSize.height - rulerHeight)),
                                         with: .color(Color.black.opacity(0.22)))
                            for edge in clock.startFrame > 0 ? [startX, endX] : [endX] {
                                var line = Path()
                                line.move(to: CGPoint(x: edge, y: 0))
                                line.addLine(to: CGPoint(x: edge, y: canvasSize.height))
                                context.stroke(line, with: .color(SequencerView.rangeColor.opacity(0.7)), lineWidth: 1)
                            }
                            context.fill(Path(CGRect(x: startX, y: rulerHeight - 3, width: max(endX - startX, 0), height: 3)),
                                         with: .color(SequencerView.rangeColor.opacity(0.7)))
                            let px = x(clock.time, width, span)
                            var playhead = Path()
                            playhead.move(to: CGPoint(x: px, y: rulerHeight))
                            playhead.addLine(to: CGPoint(x: px, y: canvasSize.height))
                            context.stroke(playhead, with: .color(Theme.playhead), lineWidth: 2)
                            let label = context.resolve(Text(stamp(clock.time)).font(.system(size: 10, weight: .semibold)).foregroundStyle(.white))
                            let size = label.measure(in: CGSize(width: 200, height: rulerHeight))
                            let box = CGRect(x: px - max(size.width + 10, 26) / 2, y: 2, width: max(size.width + 10, 26), height: rulerHeight - 4)
                            context.fill(Path(roundedRect: box, cornerRadius: 4), with: .color(Theme.playhead))
                            context.draw(label, at: CGPoint(x: box.midX, y: box.midY))
                        }
                        .background(ScrollMonitor(
                            onScroll: { delta, flags, point in
                                if flags.contains(.command) {
                                    zoomTimeline(1 + Double(delta.height) * 0.01, at: point.x, width: geometry.size.width, span: span)
                                } else if abs(delta.width) > abs(delta.height) {
                                    viewStart = max(0, viewStart - Double(delta.width / max(geometry.size.width, 1)) * span / viewZoom)
                                }
                            },
                            onMagnify: { amount, point in zoomTimeline(1 + Double(amount), at: point.x, width: geometry.size.width, span: span) }, passVertical: true))
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            if case .active(let point) = phase { hoverFrame = max(0, time(point.x, geometry.size.width, span).rounded()) }
                        }
                        .gesture(DragGesture(minimumDistance: 0)
                            .updating($pressing) { _, state, _ in state = true }
                            .onChanged { drag in handleDrag(drag, rows: rows, end: end, width: geometry.size.width, span: span) }
                            .onEnded { _ in endDrag() })
                        .onChange(of: pressing) { _, now in if !now { endDrag() } }
                        .contextMenu {
                            Section("Add Game Event at Frame \(Int(safe: hoverFrame))") {
                                eventKindButtons({ addEvent($0, at: hoverFrame) }, current: nil)
                            }
                        }
                        .overlay {
                            ZStack(alignment: .topLeading) {
                                ForEach(clock.events) { event in eventMarker(event, width: geometry.size.width, span: span) }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                        }
                        .clipped()
                        .coordinateSpace(name: "sequencerCanvas")
                    }
                    .frame(height: bodyTop + CGFloat(rows.count) * rowHeight + 8)
                }
            }
            .background(Theme.gray(0.157))
        }
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear { labelWidth = min(max(geometry.size.width * 0.22, 220), 340) }
                .onChange(of: geometry.size.width) { _, width in labelWidth = min(max(width * 0.22, 220), 340) }
        })
    }

    private func highlightedTimelines(_ row: SequencerRow?) -> Set<Int> {
        guard let clip = row?.clip else { return [] }
        if clip.usesTargets {
            let targets = Set(clip.targets)
            guard !targets.isEmpty else { return [] }
            return Set(document.sequencerRows.compactMap { $0.depth == 0 && $0.sources.contains(where: targets.contains) ? $0.timeline : nil })
        }
        let slots = document.triggerSlots
        let range = clip.trigger.map { $0...$0 } ?? clip.range
        guard let range else { return [] }
        return Set(range.compactMap { $0 >= 0 && $0 < slots.count && slots[$0].timeline >= 0 ? slots[$0].timeline : nil })
    }

    private func zoomTimeline(_ factor: Double, at px: CGFloat, width: CGFloat, span: Double) {
        let anchor = time(px, width, span)
        viewZoom = min(max(viewZoom * factor, 1), 40)
        let shifted = time(px, width, span)
        viewStart = viewZoom <= 1.001 ? 0 : max(0, viewStart + anchor - shifted)
    }

    private func handleDrag(_ drag: DragGesture.Value, rows: [SequencerRow], end: Double, width: CGFloat, span liveValue: Double) {
        if dragMode == 0 {
            dragMode = 1
            selectedEvent = nil
            frozenSpan = liveValue
            liveSpan = liveValue
            let index = Int(floor((drag.startLocation.y - bodyTop) / rowHeight))
            if drag.startLocation.y <= rulerHeight {
                if abs(drag.startLocation.x - x(end, width, liveValue)) <= 5 {
                    dragMode = 6
                } else if abs(drag.startLocation.x - x(clock.startFrame, width, liveValue)) <= 5 {
                    dragMode = 5
                }
            }
            if drag.startLocation.y > bodyTop, index >= 0, index < rows.count {
                let row = rows[index]
                document.selectionID = row.nodeID
                if let id = row.nodeID, locked.contains(id) { return }
                let reach = row.openEnded ? max(row.end, end) : row.end
                let left = x(row.start, width, liveValue), right = x(reach, width, liveValue)
                if row.depth > 0, drag.startLocation.x >= left - 7, drag.startLocation.x <= right + 4, row.startField != nil || row.endField != nil {
                    dragRow = row
                    dragStart = row.startField?.read().number ?? 0
                    dragEnd = row.endField?.read().number ?? 0
                    let resizable = row.clip == nil && row.endField != nil && !row.openEnded && dragEnd > dragStart
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
            clock.playing = false
            clock.time = max(0, time(drag.location.x, width, span).rounded())
            return
        }
        if dragMode == 5 || dragMode == 6 {
            let frame = max(0, time(drag.location.x, width, span).rounded())
            if dragMode == 5 { clock.startFrame = min(frame, end - 1) } else { clock.endFrame = max(frame, clock.startFrame + 1) }
            return
        }
        guard let row = dragRow, abs(drag.translation.width) > 2 else { return }
        let delta = (Double(drag.translation.width / max(width, 1)) * span / viewZoom).rounded()
        if dragMode == 2 {
            var shift = max(delta, -dragStart)
            let byStart = snapped(dragStart + shift, row, width, span)
            if byStart != dragStart + shift {
                shift = byStart - dragStart
            } else if !row.openEnded, dragEnd > dragStart {
                shift = snapped(dragEnd + shift, row, width, span) - dragEnd
            }
            shift = max(shift, -dragStart)
            if let start = row.startField { start.write?(fieldValue(start, dragStart + shift)) }
            if let finish = row.endField, !row.openEnded, dragEnd > dragStart { finish.write?(fieldValue(finish, dragEnd + shift)) }
        } else if dragMode == 3, let finish = row.endField {
            finish.write?(fieldValue(finish, max(dragStart + 1, snapped(dragEnd + delta, row, width, span))))
        } else if dragMode == 4, let start = row.startField {
            start.write?(fieldValue(start, min(max(0, snapped(dragStart + delta, row, width, span)), dragEnd - 1)))
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
        let before = fields.map { field, original -> (PropField, FieldValue, FieldValue) in (field, fieldValue(field, original), field.read()) }
        guard before.contains(where: { $0.1 != $0.2 }) else { return }
        document.registerUndo("Move Strip", undo: { before.forEach { $0.0.write?($0.1) } }, redo: { before.forEach { $0.0.write?($0.2) } })
    }
}
