import SwiftUI

struct LifecycleLink: View {
    let symbol: String
    let tint: Color
    let title: String
    let detail: String
    var help = ""
    var button: (symbol: String, help: String, action: () -> Void)?
    let open: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(tint).frame(width: 16)
            Text(title).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            Spacer(minLength: 4)
            Text(detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            if let button { HeaderButton(symbol: button.symbol, help: button.help, action: button.action) }
            Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 6)
        .frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.45)))
        .contentShape(Rectangle())
        .pressable(perform: open)
        .help(help)
    }
}

struct TimelineLifecycleRows: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    let timeline: Int

    private func slotID(_ source: TimelineSource) -> String {
        switch source {
        case .scheduler(let index): return "avfx/Schd/0/Item/\(index)"
        case .trigger(let index): return "avfx/Schd/0/Trgr/\(index)"
        }
    }

    private func addButton(_ source: TimelineSource) -> (symbol: String, help: String, action: () -> Void)? {
        guard case .trigger(let index) = source else { return nil }
        return ("plus", "Add Trigger \(index) to the Events track at the playhead", {
            clock.addEvent(.trigger(index))
            clock.playing = true
        })
    }

    var body: some View {
        let sources = document.sources(of: timeline)
        let stoppers = document.clipsTargeting(timeline)
        VStack(alignment: .leading, spacing: 3) {
            Text("Started by").font(Theme.small).foregroundStyle(Theme.dim)
            if sources.isEmpty {
                Text("Nothing starts this timeline: link it to a scheduler item or a trigger").font(Theme.small).foregroundStyle(Theme.changed)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(sources) { slot in
                let isTrigger: Bool = { if case .trigger = slot.source { return true }; return false }()
                LifecycleLink(symbol: isTrigger ? "bolt.fill" : "calendar", tint: isTrigger ? Theme.accent : NodeTint.timeline.color,
                              title: slot.source.name + (slot.enabled ? "" : " · off"),
                              detail: isTrigger ? "+\(slot.start) after the event" : "frame \(slot.start)",
                              help: isTrigger ? "The game fires this slot on an event. Add it to the Events track to play it here" : "Starts with the effect",
                              button: addButton(slot.source)) {
                    document.selectionID = slotID(slot.source)
                }
            }
            Text("Stopped by").font(Theme.small).foregroundStyle(Theme.dim).padding(.top, 4)
            if stoppers.isEmpty {
                Text("No clip ends it; it plays out by itself").font(Theme.small).foregroundStyle(Theme.dim)
            }
            ForEach(Array(stoppers.enumerated()), id: \.offset) { _, entry in
                LifecycleLink(symbol: ClipStyle.symbol(entry.summary.code), tint: ClipStyle.color(entry.summary.code),
                              title: document.timelineName(entry.timeline) + " · " + entry.summary.name,
                              detail: entry.summary.code == "KILL" && entry.summary.fade > 0 ? "fade \(entry.summary.fade)" : "",
                              help: EffectDocument.clipHelp(entry.summary.code)) {
                    document.selectionID = "avfx/TmLn/\(entry.timeline)/Clip\(entry.clip)"
                }
            }
        }
    }
}

enum ClipStyle {
    static func color(_ code: String) -> Color {
        switch code {
        case "KILL": return Color(red: 0.95, green: 0.42, blue: 0.38)
        case "END ": return Color(red: 0.98, green: 0.62, blue: 0.3)
        case "ULLP": return Color(red: 1, green: 0.8, blue: 0.3)
        case "TRG ", "RTRG": return Color(red: 0.42, green: 0.66, blue: 1)
        default: return Color(white: 0.7)
        }
    }

    static func symbol(_ code: String) -> String {
        switch code {
        case "KILL": return "xmark.octagon.fill"
        case "END ": return "stop.fill"
        case "ULLP": return "lock.open.fill"
        case "TRG ": return "bolt.fill"
        case "RTRG": return "shuffle"
        case "REST": return "arrow.counterclockwise"
        default: return "diamond.fill"
        }
    }
}
