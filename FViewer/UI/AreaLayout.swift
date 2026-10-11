import AppKit
import SwiftUI

private struct LabelWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = 110
}

extension EnvironmentValues {
    var labelWidth: CGFloat {
        get { self[LabelWidthKey.self] }
        set { self[LabelWidthKey.self] = newValue }
    }
}

struct AreaDivider: View {
    static let thickness: CGFloat = 5
    let vertical: Bool
    let onDrag: (CGFloat) -> Void
    @State private var hovering = false
    @State private var dragging = false

    var body: some View {
        ZStack {
            Theme.window
            Rectangle()
                .fill(hovering || dragging ? Theme.accent : Theme.line)
                .frame(width: vertical ? (hovering || dragging ? 3 : 1) : nil, height: vertical ? nil : (hovering || dragging ? 3 : 1))
        }
        .frame(width: vertical ? AreaDivider.thickness : nil, height: vertical ? nil : AreaDivider.thickness)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .pointerStyle(vertical ? .columnResize : .rowResize)
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { drag in
                dragging = true
                onDrag(vertical ? drag.location.x : drag.location.y)
            }
            .onEnded { _ in dragging = false })
    }
}

struct WindowConfigurator: NSViewRepresentable {
    final class Coordinator {
        var done = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view, context.coordinator) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { configure(view, context.coordinator) }
    }

    private func configure(_ view: NSView, _ coordinator: Coordinator) {
        guard !coordinator.done, let window = view.window else { return }
        coordinator.done = true
        if let screen = window.screen ?? NSScreen.main { window.setFrame(screen.visibleFrame, display: true) }
    }
}
