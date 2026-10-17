import Combine
import Foundation
import QuartzCore

nonisolated struct PreviewEvent: Identifiable, Codable, Equatable {
    enum Kind: Codable, Hashable {
        case trigger(Int)
        case release
        case stop
    }

    var id = UUID()
    var frame: Double
    var kind: Kind
    var muted = false

    init(frame: Double, kind: Kind) {
        self.frame = frame
        self.kind = kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        frame = try container.decode(Double.self, forKey: .frame)
        kind = try container.decode(Kind.self, forKey: .kind)
        muted = try container.decodeIfPresent(Bool.self, forKey: .muted) ?? false
    }
}

final class PlaybackClock: ObservableObject {
    private var storedTime: Double = 0
    private var lastPublished: Double = 0
    var time: Double {
        get { storedTime }
        set {
            objectWillChange.send()
            lastPublished = CACurrentMediaTime()
            storedTime = newValue
        }
    }
    @Published var playing = true { didSet { if playing, !oldValue { resumed = true } } }
    private var resumed = false
    @Published var loop = true
    @Published var status = ""
    @Published var endFrame: Double?
    @Published var startFrame: Double = 0
    @Published var speed: Double = 1
    var rate: Double = 30
    @Published var seed = 1
    @Published var clipLog: [String] = []
    @Published var frameMilliseconds: Double = 0
    @Published var framesPerSecond: Double = 0
    @Published var lockSeed = true
    @Published var events: [PreviewEvent] = [] { didSet {
        guard events != oldValue else { return }
        eventsRevision += 1
        if !loadingEvents { onEventsEdited?() }
    } }
    private var loadingEvents = false
    private(set) var eventsRevision = 0
    var onEventsEdited: (() -> Void)?
    var endingTest: ((PreviewEvent.Kind) -> Bool)?

    func isEnding(_ kind: PreviewEvent.Kind) -> Bool { endingTest?(kind) ?? { if case .trigger = kind { return false }; return true }() }

    func isPlayed(_ event: PreviewEvent) -> Bool { !event.muted }

    var playedEvents: [PreviewEvent] { events.filter(isPlayed) }
    @Published var timelineStates: [Int: String] = [:]
    var restartToken = 0
    private var lastTick: Double = 0

    func rewind() {
        if !lockSeed { seed = Int.random(in: 1...9999) }
        time = startFrame
        restartToken += 1
    }

    var lastEventFrame: Double { events.map(\.frame).max() ?? 0 }

    func hasEvents(after frame: Double) -> Bool { playedEvents.contains { $0.frame > frame } }

    @discardableResult
    func addEvent(_ kind: PreviewEvent.Kind, at frame: Double? = nil) -> PreviewEvent {
        let event = PreviewEvent(frame: max(0, (frame ?? time).rounded(.down)), kind: kind)
        events = (events + [event]).sorted { $0.frame < $1.frame }
        return event
    }

    func setMuted(_ id: UUID, _ muted: Bool) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }
        events[index].muted = muted
    }

    func moveEvent(_ id: UUID, to frame: Double) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }
        var next = events
        next[index].frame = max(0, frame.rounded())
        next.sort { $0.frame < $1.frame }
        events = next
    }

    func setEventKind(_ id: UUID, _ kind: PreviewEvent.Kind) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }
        events[index].kind = kind
    }

    func removeEvent(_ id: UUID) { events.removeAll { $0.id == id } }

    func loadEvents(_ list: [PreviewEvent]) {
        loadingEvents = true
        events = list.sorted { $0.frame < $1.frame }
        loadingEvents = false
    }

    func advance(_ seconds: Double, duration: Double, finished: Bool, held: Bool) {
        let now = CACurrentMediaTime()
        let sinceLast = lastTick == 0 ? seconds : now - lastTick
        lastTick = now
        guard playing else { return }
        let fresh = resumed
        resumed = false
        let next = time + min(seconds, sinceLast, 0.1) * rate * speed
        let ended = endFrame == nil && finished && next > 2 && !held
        let overrun = next >= (endFrame ?? max(duration, 1))
        if ended || overrun {
            if loop || fresh {
                rewind()
            } else {
                playing = false
            }
            return
        }
        if now - lastPublished >= 1.0 / 24 {
            objectWillChange.send()
            lastPublished = now
        }
        storedTime = next
    }
}
