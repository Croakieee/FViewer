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

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var used: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if used > 0, used + size.width > width {
                rows.append([])
                used = 0
            }
            rows[rows.count - 1].append((index, size))
            used += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 400
        let layout = rows(subviews, width: width)
        let height = layout.reduce(CGFloat(0)) { $0 + ($1.map(\.size.height).max() ?? 0) } + spacing * CGFloat(max(layout.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            var x = bounds.minX
            let height = row.map(\.size.height).max() ?? 0
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += height + spacing
        }
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
