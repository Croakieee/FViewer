import SwiftUI

struct LifecycleEditorView: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    @State private var timeline = 0

    private static let addable: [String] = ["KILL", "END ", "ULLP", "TRG ", "RTRG", "REST", "FADI"]

    private func fields(_ id: String) -> [PropField] {
        guard let node = document.node(id) else { return [] }
        return document.sections(for: node).flatMap(\.fields)
    }

    private func field(_ list: [PropField], tag: String) -> PropField? { list.first { $0.tag == tag } }
    private func field(_ list: [PropField], suffix: String) -> PropField? { list.first { $0.id.hasSuffix("#" + suffix) } }

    private func title(_ text: String, _ note: String) -> some View {
        HStack(spacing: 6) {
            Text(text).font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text)
            Text(note).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: 22)
    }

    private func chip(_ text: String, _ color: Color, help: String) -> some View {
        Text(text).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.black.opacity(0.8))
            .padding(.horizontal, 5)
            .frame(height: 14)
            .background(Capsule().fill(color))
            .help(help)
    }

    private func slotRow(_ slot: LifecycleSlot) -> some View {
        let id: String
        let label: String
        let isTrigger: Bool
        switch slot.source {
        case .scheduler(let index):
            id = "avfx/Schd/0/Item/\(index)"
            label = "Item \(index)"
            isTrigger = false
        case .trigger(let index):
            id = "avfx/Schd/0/Trgr/\(index)"
            label = "T\(index)"
            isTrigger = true
        }
        let list = fields(id)
        let ending: Bool = { if case .trigger(let index) = slot.source { return slot.timeline >= 0 && document.isEnding(.trigger(index)) }; return false }()
        return HStack(spacing: 6) {
            if let enabled = field(list, tag: "bEna") { FieldControl(document: document, field: enabled).frame(width: 16) }
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 38, alignment: .leading)
            if let target = field(list, tag: "TlNo") { FieldControl(document: document, field: target).frame(minWidth: 90, maxWidth: 130) }
            if let start = field(list, tag: "StTm") {
                FieldControl(document: document, field: start, label: isTrigger ? "Delay" : "Frame").frame(width: 88)
                    .help(isTrigger ? "Frames between the game event and the start of the timeline" : "Frame at which the timeline starts")
            }
            if slot.timeline >= 0 {
                if isTrigger {
                    chip(ending ? "ends" : "starts", ending ? Color(red: 0.95, green: 0.42, blue: 0.38) : Color(red: 0.42, green: 0.66, blue: 1),
                         help: ending ? "Its timeline releases loops or kills what the scheduler started: the game sends it to end the effect"
                             : "Its timeline starts something: the game sends it to switch the effect into a state")
                }
                if let state = clock.timelineStates[slot.timeline] { LifecycleBadge(state: state) }
            } else {
                Text("empty").font(Theme.small).foregroundStyle(Theme.dim)
            }
            Spacer(minLength: 0)
            if slot.timeline >= 0 {
                HeaderButton(symbol: "arrow.right.circle", active: slot.timeline == timeline, help: "Show the clips of \(document.timelineName(slot.timeline)) on the right") {
                    timeline = slot.timeline
                    document.selectionID = "avfx/TmLn/\(slot.timeline)"
                }
            }
            if case .trigger(let index) = slot.source, slot.timeline >= 0 {
                HeaderButton(symbol: "bolt.fill", help: "Add Trigger \(index) to the Events row at the playhead and play") {
                    clock.addEvent(.trigger(index))
                    clock.playing = true
                }
            }
            if !isTrigger, let remove = document.node(id)?.actions.first(where: { $0.id.hasSuffix("!del") }) {
                HeaderButton(symbol: "trash", help: "Delete this scheduler item", action: remove.perform)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.35)))
        .opacity(slot.enabled ? 1 : 0.6)
    }

    private var startColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Preview").font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.text)
                    Text(clock.events.isEmpty ? "no events" : clock.events.map { event -> String in
                        EffectDocument.eventShort(event.kind) + " @ \(Int(safe: event.frame))" + (clock.isPlayed(event) ? "" : " (muted)")
                    }.joined(separator: ", "))
                    .font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                    .help("Game events on the Events row of the Timeline. Drag them there to change when they happen")
                    Spacer(minLength: 0)
                }
                .frame(height: 24)
                HStack(spacing: 6) {
                    title("Scheduler", "starts timelines with the effect")
                    if let add = document.node("avfx/Schd/0/Item")?.actions.first(where: { $0.title == "Add Item" }) {
                        HeaderButton(symbol: "plus", help: "Add a scheduler item", action: add.perform)
                    }
                }
                let scheduled = document.schedulerSlots
                if scheduled.isEmpty {
                    Text("Nothing starts with the effect: it waits for a trigger from the game").font(Theme.small).foregroundStyle(Theme.changed)
                }
                ForEach(scheduled) { slotRow($0) }
                title("Triggers", "fired by the game: end of a cast, an object changing state").padding(.top, 6)
                ForEach(document.triggerSlots) { slotRow($0) }
            }
            .padding(8)
        }
    }

    private func clipCard(_ entry: (item: Int, clip: Int, start: Int, enabled: Bool, summary: ClipSummary)) -> some View {
        let id = "avfx/TmLn/\(timeline)/Item/\(entry.item)"
        let list = fields(id)
        let code = entry.summary.code
        let selected = document.selectionID == id
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: ClipStyle.symbol(code)).font(.system(size: 10)).foregroundStyle(ClipStyle.color(code)).frame(width: 14)
                if let enabled = field(list, tag: "bEna") { FieldControl(document: document, field: enabled).frame(width: 16) }
                if let type = field(list, suffix: "type") { FieldControl(document: document, field: type).frame(width: 140) }
                if let start = field(list, tag: "StTm") { FieldControl(document: document, field: start, label: "Frame").frame(width: 96) }
                if code == "KILL" || code == "FADI", let fade = field(list, suffix: "fade") {
                    FieldControl(document: document, field: fade, label: code == "KILL" ? "Fade" : "Fade In").frame(width: 100)
                        .help(code == "KILL" ? "Frames over which the targets fade out" : "Frames over which the targets fade in")
                }
                if code == "TRG ", let trigger = field(list, suffix: "trigger") { FieldControl(document: document, field: trigger).frame(width: 190) }
                if code == "RTRG" {
                    if let low = field(list, suffix: "min") { FieldControl(document: document, field: low).frame(width: 150) }
                    if let high = field(list, suffix: "max") { FieldControl(document: document, field: high).frame(width: 150) }
                }
                Spacer(minLength: 0)
                HeaderButton(symbol: "scope", help: "Select it in the Timeline and Properties") { document.selectionID = id }
                HeaderButton(symbol: "trash", help: "Delete this clip") { document.deleteClipItem(in: timeline, item: entry.item) }
            }
            if entry.summary.usesTargets {
                HStack(spacing: 6) {
                    Text("Targets").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 36, alignment: .trailing)
                    ForEach(1...3, id: \.self) { k in
                        if let target = field(list, suffix: "target\(k)") { FieldControl(document: document, field: target).frame(maxWidth: 200) }
                    }
                    if entry.summary.targets.isEmpty {
                        Text("all empty: everything alive").font(Theme.small).foregroundStyle(Theme.changed).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            Text(EffectDocument.clipHelp(code)).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(2).padding(.leading, 20)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.field.opacity(selected ? 0.7 : 0.35)))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(selected ? Theme.accent : Color.clear, lineWidth: 1))
        .opacity(entry.enabled ? 1 : 0.6)
    }

    private var addClipMenu: some View {
        Menu {
            Section("Add at frame \(max(0, Int(safe: clock.time.rounded(.down))))") {
                ForEach(LifecycleEditorView.addable, id: \.self) { code in
                    Button(EffectDocument.clipName(code)) {
                        let base = document.sequencerRows.first { $0.depth == 0 && $0.timeline == timeline }?.base ?? 0
                        document.addClipItem(to: timeline, code: code, at: max(0, Int(safe: (clock.time - base).rounded(.down))))
                    }
                    .help(EffectDocument.clipHelp(code))
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold))
                Text("Add Clip").font(Theme.small)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 7)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Add a clip to this timeline at the playhead: Kill, End, Unlock Loop Point, Trigger, Random Trigger, Reset or Fade In")
    }

    private var timelineColumn: some View {
        let count = document.avfxRoot?.childrenNamed("TmLn").count ?? 0
        let current = min(max(timeline, 0), max(count - 1, 0))
        let sources = document.sources(of: current)
        let stoppers = document.clipsTargeting(current)
        let clips = document.clipItems(of: current)
        return ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ChoiceField(choices: (0..<count).map { FieldChoice(name: document.timelineName($0), value: $0) }, value: current) {
                        timeline = $0
                        document.selectionID = "avfx/TmLn/\($0)"
                    }
                    .frame(width: 150)
                    if let state = clock.timelineStates[current] { LifecycleBadge(state: state) }
                    Spacer(minLength: 0)
                    if count > 0 { addClipMenu }
                }
                .frame(height: 24)
                HStack(spacing: 4) {
                    Text("Started by").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 64, alignment: .leading)
                    if sources.isEmpty { Text("nothing").font(Theme.small).foregroundStyle(Theme.changed) }
                    ForEach(sources) { slot in
                        chip(slot.source.name + (slot.enabled ? "" : " · off"), slot.enabled ? NodeTint.timeline.color : Theme.gray(0.5), help: document.slotTitle(slot))
                    }
                    Spacer(minLength: 0)
                }
                HStack(spacing: 4) {
                    Text("Ended by").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 64, alignment: .leading)
                    if stoppers.isEmpty { Text("plays out by itself").font(Theme.small).foregroundStyle(Theme.dim) }
                    ForEach(Array(stoppers.enumerated()), id: \.offset) { _, entry in
                        chip(document.timelineName(entry.timeline) + " · " + entry.summary.name, ClipStyle.color(entry.summary.code), help: EffectDocument.clipHelp(entry.summary.code))
                            .onTapGesture { timeline = entry.timeline }
                    }
                    Spacer(minLength: 0)
                }
                title("Clips", "run once at their frame each time this timeline starts").padding(.top, 4)
                if clips.isEmpty {
                    Text("No clips. Add one to end, release or chain this timeline").font(Theme.small).foregroundStyle(Theme.dim)
                }
                ForEach(clips, id: \.item) { clipCard($0) }
            }
            .padding(8)
        }
    }

    var body: some View {
        Group {
            if document.avfxRoot == nil {
                Text("Scheduler, triggers and clips exist only in .avfx effects").font(Theme.font).foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    startColumn.frame(minWidth: 380, idealWidth: 520, maxWidth: 620)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    timelineColumn.frame(maxWidth: .infinity)
                }
            }
        }
        .background(Theme.gray(0.157))
        .onAppear { follow(document.selectionID) }
        .onChange(of: document.selectionID) { _, id in follow(id) }
    }

    private func follow(_ id: String?) {
        guard let id, id.hasPrefix("avfx/TmLn/") else { return }
        let part = id.dropFirst("avfx/TmLn/".count).prefix { $0.isNumber }
        if let index = Int(part) { timeline = index }
    }
}
