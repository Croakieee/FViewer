import Foundation

nonisolated enum TimelineSource: Hashable {
    case scheduler(Int)
    case trigger(Int)

    init?(target value: Int) {
        if value > 0 {
            self = .scheduler(value - 1)
        } else if value < 0 {
            self = .trigger(-value - 1)
        } else {
            return nil
        }
    }

    var target: Int {
        switch self {
        case .scheduler(let index): return index + 1
        case .trigger(let index): return -(index + 1)
        }
    }

    var name: String {
        switch self {
        case .scheduler(let index): return "Scheduler Item \(index)"
        case .trigger(let index): return EffectDocument.triggerName(index)
        }
    }

    var short: String {
        switch self {
        case .scheduler(let index): return "S\(index)"
        case .trigger(let index): return "T\(index)"
        }
    }
}

nonisolated struct LifecycleSlot: Identifiable {
    let source: TimelineSource
    let enabled: Bool
    let start: Int
    let timeline: Int
    var id: TimelineSource { source }
}

nonisolated struct ClipSummary {
    let code: String
    let name: String
    let fade: Int
    let targets: [TimelineSource]
    let trigger: Int?
    let range: ClosedRange<Int>?
    var endsEffect = false

    var usesTargets: Bool { ["KILL", "REST", "FADI"].contains(code) }
    var stops: Bool { code == "KILL" || code == "ULLP" || code == "END " }
}

extension EffectDocument {
    static func clipName(_ code: String) -> String {
        clipTypes.first { $0.code == code }?.name ?? code.trimmingCharacters(in: .whitespaces)
    }

    nonisolated static let triggerMeanings: [Int: String] = [0: "End of Animation", 1: "Interrupted", 2: "Mount Landing", 3: "Mount Takeoff", 4: "Weapon Sheathe",
                                                 5: "Weapon Draw", 8: "Crafting / Gathering", 9: "Crafting / Gathering", 10: "Mount", 11: "Dismount"]

    nonisolated static func triggerName(_ index: Int) -> String {
        "Trigger \(index)" + (triggerMeanings[index].map { " · " + $0 } ?? "")
    }

    static func eventShort(_ kind: PreviewEvent.Kind) -> String {
        switch kind {
        case .trigger(let index): return "T\(index)"
        case .release: return "Release"
        case .stop: return "Remove"
        }
    }

    static func eventSymbol(_ kind: PreviewEvent.Kind) -> String {
        switch kind {
        case .trigger: return "bolt.fill"
        case .release: return "lock.open.fill"
        case .stop: return "xmark"
        }
    }

    static func clipHelp(_ code: String) -> String {
        switch code {
        case "KILL": return "Fades out what its targets started (a scheduler item or every run of a trigger) over Fade frames; those runs do nothing more. With Allow Show off the whole effect ends after Fade frames, the rest cut off at once. No target and Allow Show on: nothing (measured in the game)"
        case "END ": return "The whole effect disappears at once, endless particles too, and nothing more is created (measured in the game)"
        case "ULLP": return "Releases every loop of the effect, particles, emitters and timelines, whatever its targets, so everything plays to its end (measured in the game)"
        case "TRG ": return "Fires a trigger slot, as if the game sent it"
        case "RTRG": return "Fires one random trigger slot from the range"
        case "REST": return "Restarts the timelines its targets point to from their first frame. No targets: the whole effect"
        case "FADI": return "Fades in the timelines its targets point to over its duration in frames. No targets: everything"
        default: return ""
        }
    }

    static func clipSummary(_ block: AvfxBlock) -> ClipSummary? {
        guard block.tag == "Clip", block.data.count >= 36 else { return nil }
        let code = String(decoding: block.data.prefix(4).reversed(), as: UTF8.self)
        let ints = (0..<4).map { Int(Int32(bitPattern: block.data.u32(4 + $0 * 4))) }
        switch code {
        case "KILL":
            return ClipSummary(code: code, name: clipName(code), fade: max(0, ints[0]), targets: ints.dropFirst().compactMap(TimelineSource.init(target:)),
                               trigger: nil, range: nil, endsEffect: block.data.f32(20) != 0)
        case "ULLP", "REST":
            return ClipSummary(code: code, name: clipName(code), fade: 0, targets: ints.dropFirst().compactMap(TimelineSource.init(target:)),
                               trigger: nil, range: nil)
        case "FADI":
            return ClipSummary(code: code, name: clipName(code), fade: max(0, ints[0]), targets: ints.dropFirst().compactMap(TimelineSource.init(target:)),
                               trigger: nil, range: nil)
        case "TRG ":
            return ClipSummary(code: code, name: clipName(code), fade: 0, targets: [], trigger: ints[0], range: nil)
        case "RTRG":
            return ClipSummary(code: code, name: clipName(code), fade: 0, targets: [], trigger: nil, range: min(ints[0], ints[1])...max(ints[0], ints[1]))
        default:
            return ClipSummary(code: code, name: clipName(code), fade: 0, targets: [], trigger: nil, range: nil)
        }
    }

    func clipLabel(_ block: AvfxBlock) -> String {
        guard let clip = EffectDocument.clipSummary(block) else { return "Clip" }
        var text = clip.name
        if clip.usesTargets {
            var seen = Set<TimelineSource>()
            let unique = clip.targets.filter { seen.insert($0).inserted }
            if !unique.isEmpty {
                text += " → " + unique.map(\.name).joined(separator: ", ")
            } else if clip.code == "KILL" {
                text += clip.endsEffect ? "" : " · no target"
            } else {
                text += " · everything"
            }
        }
        if clip.code == "ULLP" { text += " · every loop" }
        if clip.code == "KILL", clip.fade > 0 { text += " · fade \(clip.fade)" }
        if clip.code == "KILL", clip.endsEffect { text += " · ends the effect" }
        if clip.code == "FADI", clip.fade > 0 { text += " · fade in \(clip.fade)" }
        if let trigger = clip.trigger { text += " → Trigger \(trigger)" }
        if let range = clip.range { text += " → Trigger \(range.lowerBound)…\(range.upperBound)" }
        return text
    }

    private func slots(_ tag: String) -> [LifecycleSlot] {
        guard let scheduler = avfxRoot?.child("Schd") else { return [] }
        return scheduler.ownRecords(tag).enumerated().map { index, record in
            func value(_ field: String, _ fallback: Int) -> Int { record.first { $0.tag == field }?.intValue ?? fallback }
            return LifecycleSlot(source: tag == "Item" ? .scheduler(index) : .trigger(index), enabled: value("bEna", 1) != 0,
                                 start: value("StTm", 0), timeline: value("TlNo", -1))
        }
    }

    var schedulerSlots: [LifecycleSlot] { slots("Item") }
    var triggerSlots: [LifecycleSlot] { slots("Trgr") }

    func timelineName(_ index: Int) -> String {
        names["avfx/TmLn/\(index)"] ?? "Timeline \(index)"
    }

    func slotTitle(_ slot: LifecycleSlot) -> String {
        guard slot.timeline >= 0 else { return slot.source.name + " · empty" }
        return slot.source.name + " → " + timelineName(slot.timeline) + (slot.enabled ? "" : " · off")
    }

    func sources(of timeline: Int) -> [LifecycleSlot] {
        (schedulerSlots + triggerSlots).filter { $0.timeline == timeline }
    }

    func clipTargetChoices(current: Int) -> [FieldChoice] {
        var choices = [FieldChoice(name: "—", value: 0)]
        for slot in schedulerSlots + triggerSlots {
            let name = slot.source.short + (slot.timeline >= 0 ? " → " + timelineName(slot.timeline) : " · empty") + (slot.enabled ? "" : " · off")
            choices.append(FieldChoice(name: name, value: slot.source.target))
        }
        if !choices.contains(where: { $0.value == current }) {
            choices.append(FieldChoice(name: (TimelineSource(target: current)?.name ?? "\(current)") + " · missing", value: current))
        }
        return choices
    }

    func triggerChoices(current: Int) -> [FieldChoice] {
        var choices = triggerSlots.map { FieldChoice(name: slotTitle($0), value: { if case .trigger(let i) = $0.source { return i }; return 0 }($0)) }
        if !choices.contains(where: { $0.value == current }) { choices.append(FieldChoice(name: "Trigger \(current) · missing", value: current)) }
        return choices
    }

    func clipsTargeting(_ timeline: Int) -> [(timeline: Int, clip: Int, summary: ClipSummary)] {
        guard let root = avfxRoot else { return [] }
        let mine = Set(sources(of: timeline).map(\.source))
        var result: [(timeline: Int, clip: Int, summary: ClipSummary)] = []
        for (t, block) in root.childrenNamed("TmLn").enumerated() {
            for (c, clip) in block.childrenNamed("Clip").enumerated() {
                guard let summary = EffectDocument.clipSummary(clip), summary.stops else { continue }
                let reaches: Bool
                switch summary.code {
                case "KILL": reaches = summary.targets.contains(where: mine.contains) || (summary.endsEffect && t != timeline)
                default: reaches = t != timeline
                }
                if reaches { result.append((t, c, summary)) }
            }
        }
        return result
    }

    func isEnding(_ kind: PreviewEvent.Kind) -> Bool {
        guard case .trigger(let index) = kind else { return true }
        guard let root = avfxRoot, index >= 0, index < triggerSlots.count else { return false }
        let timelines = root.childrenNamed("TmLn")
        let slot = triggerSlots[index]
        guard slot.timeline >= 0, slot.timeline < timelines.count else { return false }
        let timeline = timelines[slot.timeline]
        let clips = timeline.childrenNamed("Clip")
        for record in timeline.ownRecords("Item") where (record.first { $0.tag == "bEna" }?.intValue ?? 1) != 0 {
            let clip = record.first { $0.tag == "ClNo" }?.intValue ?? -1
            guard clip >= 0, clip < clips.count, let summary = EffectDocument.clipSummary(clips[clip]) else { continue }
            switch summary.code {
            case "ULLP", "END ": return true
            case "KILL" where summary.endsEffect || summary.targets.contains(where: { if case .scheduler = $0 { return true }; return false }): return true
            default: continue
            }
        }
        return false
    }

    var endingKind: PreviewEvent.Kind {
        for (index, slot) in triggerSlots.enumerated() where slot.enabled && isEnding(.trigger(index)) { return .trigger(index) }
        guard let root = avfxRoot else { return .release }
        let endless = root.childrenNamed("Emit").contains { emitter in
            let life = emitter.child("Life")
            return life?.children == nil || (life?.child("Val")?.floatValue ?? -1) < 0
        }
        return endless ? .stop : .release
    }

    var defaultEvents: [PreviewEvent] {
        guard let root = avfxRoot, !schedulerSlots.contains(where: { $0.enabled && $0.timeline >= 0 }) else { return [] }
        let timelines = root.childrenNamed("TmLn")
        var best: (index: Int, items: Int)?
        for slot in triggerSlots where slot.enabled && slot.timeline >= 0 && slot.timeline < timelines.count {
            guard case .trigger(let index) = slot.source else { continue }
            let items = timelines[slot.timeline].ownRecords("Item").filter { record in
                (record.first { $0.tag == "bEna" }?.intValue ?? 1) != 0 && (record.first { $0.tag == "EmNo" }?.intValue ?? -1) >= 0
            }.count
            if items > (best?.items ?? 0) { best = (index, items) }
        }
        guard let best else { return [] }
        return [PreviewEvent(frame: 0, kind: .trigger(best.index))]
    }

    func timelineBlock(_ index: Int) -> AvfxBlock? {
        guard let timelines = avfxRoot?.childrenNamed("TmLn"), index >= 0, index < timelines.count else { return nil }
        return timelines[index]
    }

    func clipItems(of timeline: Int) -> [(item: Int, clip: Int, start: Int, enabled: Bool, summary: ClipSummary)] {
        guard let block = timelineBlock(timeline) else { return [] }
        let clips = block.childrenNamed("Clip")
        return block.ownRecords("Item").enumerated().compactMap { index, record in
            func value(_ tag: String, _ fallback: Int) -> Int { record.first { $0.tag == tag }?.intValue ?? fallback }
            let clip = value("ClNo", -1)
            guard value("EmNo", -1) < 0, clip >= 0, clip < clips.count, let summary = EffectDocument.clipSummary(clips[clip]) else { return nil }
            return (index, clip, value("StTm", 0), value("bEna", 1) != 0, summary)
        }
        .sorted { $0.start < $1.start }
    }

    func addClipItem(to timeline: Int, code: String, at frame: Int) {
        guard let block = timelineBlock(timeline) else { return }
        var bytes = Array(code.utf8.reversed())
        bytes.append(contentsOf: [UInt8](repeating: 0, count: 160))
        let clip = AvfxBlock(tag: "Clip", data: bytes)
        let index = block.childrenNamed("Clip").count
        let record = defaultRecord("AvfxTimelineItem")
        for field in record {
            switch field.tag {
            case "bEna": field.data = [1] + [UInt8](repeating: 0, count: max(field.data.count - 1, 0))
            case "StTm": field.intValue = max(0, frame)
            case "EdTm": field.intValue = max(0, frame) + 1
            case "ClNo": field.intValue = index
            case "EmNo", "BdNo", "EfNo": field.intValue = -1
            default: break
            }
        }
        var records = block.ownRecords("Item")
        records.append(record)
        performStructural("Add " + EffectDocument.clipName(code)) {
            let list = block.children ?? []
            block.insert(clip, at: (list.lastIndex { $0.tag == "Clip" }).map { $0 + 1 } ?? list.count)
            block.setOwnRecords("Item", records)
        }
        selectionID = "avfx/TmLn/\(timeline)/Item/\(records.count - 1)"
    }

    func deleteClipItem(in timeline: Int, item: Int) {
        guard let block = timelineBlock(timeline) else { return }
        var records = block.ownRecords("Item")
        guard item >= 0, item < records.count else { return }
        let clip = records[item].first { $0.tag == "ClNo" }?.intValue ?? -1
        records.remove(at: item)
        let clips = block.childrenNamed("Clip")
        let shared = records.contains { record in record.first { $0.tag == "ClNo" }?.intValue == clip }
        let prefix = "avfx/TmLn/\(timeline)"
        performStructural("Delete " + (clip >= 0 && clip < clips.count ? EffectDocument.clipSummary(clips[clip])?.name ?? "Clip" : "Clip")) {
            renumberIDs(prefix: prefix + "/Item/") { $0 == item ? nil : $0 > item ? $0 - 1 : $0 }
            if !shared, clip >= 0, clip < clips.count {
                renumberIDs(prefix: prefix + "/Clip") { $0 == clip ? nil : $0 > clip ? $0 - 1 : $0 }
                block.remove(clips[clip])
                for record in records {
                    for field in record where field.tag == "ClNo" { field.remapReference("ClNo", removed: clip) }
                }
            }
            block.setOwnRecords("Item", records)
        }
        if selectionID?.hasPrefix(prefix + "/Item/") == true { selectionID = prefix }
    }
}
