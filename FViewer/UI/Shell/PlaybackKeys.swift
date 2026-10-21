import AppKit
import SwiftUI

final class PlaybackKeysView: NSView {
    weak var app: AppModel?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let window = self.window, event.window === window, window.attachedSheet == nil,
                  !(window.firstResponder is NSText), let document = self.app?.document else { return event }
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard modifiers.isEmpty || modifiers == .shift else { return event }
            let clock = document.clock
            let last = clock.endFrame ?? max(document.duration, clock.lastEventFrame + 10)
            let events = document.selectedEvents.filter { id in clock.events.contains { $0.id == id } }
            if !events.isEmpty {
                switch event.keyCode {
                case 51 where modifiers.isEmpty, 117 where modifiers.isEmpty, 7 where modifiers.isEmpty:
                    document.removeEvents(events)
                    return nil
                case 46 where modifiers.isEmpty:
                    document.toggleEventsMuted(events)
                    return nil
                case 2 where modifiers == .shift:
                    document.duplicateEvents(events)
                    return nil
                case 53:
                    document.selectedEvents = []
                    return nil
                default: break
                }
            }
            switch event.keyCode {
            case 49 where modifiers.isEmpty:
                clock.playing.toggle()
            case 123:
                clock.playing = false
                clock.time = modifiers == .shift ? clock.startFrame : max(0, (clock.time - 1).rounded())
            case 124:
                clock.playing = false
                clock.time = modifiers == .shift ? last : (clock.time + 1).rounded()
            default:
                return event
            }
            return nil
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

struct PlaybackKeys: NSViewRepresentable {
    let app: AppModel

    func makeNSView(context: Context) -> PlaybackKeysView {
        let view = PlaybackKeysView()
        view.app = app
        return view
    }

    func updateNSView(_ view: PlaybackKeysView, context: Context) { view.app = app }
}
