import Foundation

extension EffectDocument {
    func events(of kind: PreviewEvent.Kind) -> [PreviewEvent] { clock.events.filter { $0.kind == kind } }

    @discardableResult
    func addEvent(_ kind: PreviewEvent.Kind, at frame: Double? = nil) -> UUID {
        let event = PreviewEvent(frame: max(0, (frame ?? clock.time).rounded(.down)), kind: kind)
        editEvents("Add " + EffectDocument.eventShort(kind)) { $0.append(event) }
        selectedEvents = [event.id]
        return event.id
    }

    @discardableResult
    func placeEvent(_ kind: PreviewEvent.Kind, at frame: Double? = nil) -> UUID {
        let target = max(0, (frame ?? clock.time).rounded(.down))
        let existing = events(of: kind)
        guard let keep = existing.first(where: { !$0.muted }) ?? existing.first else { return addEvent(kind, at: target) }
        editEvents("Move " + EffectDocument.eventShort(kind)) { list in
            guard let index = list.firstIndex(where: { $0.id == keep.id }) else { return }
            list[index].frame = target
            list[index].muted = false
        }
        selectedEvents = [keep.id]
        return keep.id
    }

    func moveEvents(_ ids: Set<UUID>, by delta: Double) {
        guard !ids.isEmpty, delta != 0 else { return }
        let lowest = clock.events.filter { ids.contains($0.id) }.map(\.frame).min() ?? 0
        let step = max(delta.rounded(), -lowest)
        guard step != 0 else { return }
        editEvents(ids.count == 1 ? "Move Event" : "Move Events") { list in
            for index in list.indices where ids.contains(list[index].id) { list[index].frame += step }
        }
    }

    func setEventFrame(_ id: UUID, _ frame: Double) {
        editEvents("Move Event") { list in
            guard let index = list.firstIndex(where: { $0.id == id }) else { return }
            list[index].frame = max(0, frame.rounded())
        }
    }

    func setEventKind(_ ids: Set<UUID>, _ kind: PreviewEvent.Kind) {
        editEvents("Change Event") { list in
            for index in list.indices where ids.contains(list[index].id) { list[index].kind = kind }
        }
    }

    func setEventsMuted(_ ids: Set<UUID>, _ muted: Bool) {
        editEvents(muted ? "Mute Event" : "Unmute Event") { list in
            for index in list.indices where ids.contains(list[index].id) { list[index].muted = muted }
        }
    }

    func toggleEventsMuted(_ ids: Set<UUID>) {
        let all = clock.events.filter { ids.contains($0.id) }
        guard !all.isEmpty else { return }
        setEventsMuted(ids, !all.allSatisfy(\.muted))
    }

    func removeEvents(_ ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        editEvents(ids.count == 1 ? "Delete Event" : "Delete Events") { list in list.removeAll { ids.contains($0.id) } }
        selectedEvents.subtract(ids)
    }

    func duplicateEvents(_ ids: Set<UUID>, to frame: Double? = nil) {
        let picked = clock.events.filter { ids.contains($0.id) }
        guard let first = picked.map(\.frame).min() else { return }
        let shift = max(0, (frame ?? clock.time).rounded(.down)) - first
        let copies = picked.map { event -> PreviewEvent in
            var copy = PreviewEvent(frame: max(0, event.frame + shift), kind: event.kind)
            copy.muted = event.muted
            return copy
        }
        editEvents(copies.count == 1 ? "Duplicate Event" : "Duplicate Events") { $0.append(contentsOf: copies) }
        selectedEvents = Set(copies.map(\.id))
    }

    func clearEvents() {
        editEvents("Delete All Events") { $0.removeAll() }
        selectedEvents = []
    }

    func resetEvents() {
        editEvents("Reset Events") { $0 = defaultEvents }
        selectedEvents = []
    }
}
