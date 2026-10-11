import Combine
import SwiftUI

struct SequencerView: View {
    @ObservedObject var document: EffectDocument
    @State private var playing = false
    @State private var size = CGSize(width: 400, height: 100)

    private let rowHeight: CGFloat = 20
    private let rulerHeight: CGFloat = 18
    private let labelWidth: CGFloat = 170
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    private func x(_ t: Double, _ width: CGFloat) -> CGFloat {
        let span = document.duration * 1.08 + 4
        return CGFloat((t + 2) / span) * width
    }

    private func time(_ px: CGFloat, _ width: CGFloat) -> Double {
        let span = document.duration * 1.08 + 4
        return Double(px / max(width, 1)) * span - 2
    }

    var body: some View {
        let rows = document.sequencerRows
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Spacer()
                HeaderButton(symbol: "backward.end.fill", help: "В начало") { document.time = 0 }
                HeaderButton(symbol: playing ? "pause.fill" : "play.fill", active: playing, help: "Проиграть (Пробел)") { playing.toggle() }
                HeaderButton(symbol: "forward.end.fill", help: "В конец") { document.time = document.duration }
                Spacer()
                NumberField(label: "Кадр", value: document.time, isInteger: true, onLive: { document.time = max(0, $0) },
                            onCommit: { _, next in document.time = max(0, next) })
                    .frame(width: 96)
                Text("Конец \(Int(document.duration)) · 30 fps").font(Theme.small).foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Theme.panel)
            ScrollView {
                HStack(alignment: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: rulerHeight)
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            HStack(spacing: 5) {
                                Color.clear.frame(width: CGFloat(row.depth) * 12)
                                RoundedRectangle(cornerRadius: 2).fill(row.tint.color).frame(width: 8, height: 8)
                                Text(row.label).font(Theme.font).foregroundStyle(document.selectionID == row.nodeID ? .white : Theme.text).lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 6)
                            .frame(height: rowHeight)
                            .background(document.selectionID == row.nodeID ? Theme.selection : index % 2 == 1 ? Color.white.opacity(0.025) : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { document.selectionID = row.nodeID }
                        }
                    }
                    .frame(width: labelWidth)
                    Rectangle().fill(Theme.line).frame(width: 1)
                    GeometryReader { geometry in
                        Canvas { context, canvasSize in
                            let width = canvasSize.width
                            let step: Double = document.duration > 400 ? 50 : document.duration > 160 ? 20 : document.duration > 60 ? 10 : 5
                            var t = 0.0
                            while t <= document.duration * 1.08 + 2 {
                                var line = Path()
                                line.move(to: CGPoint(x: x(t, width), y: rulerHeight))
                                line.addLine(to: CGPoint(x: x(t, width), y: canvasSize.height))
                                context.stroke(line, with: .color(Color.white.opacity(0.06)), lineWidth: 1)
                                context.draw(Text("\(Int(t))").font(Theme.small).foregroundStyle(Theme.dim), at: CGPoint(x: x(t, width) + 3, y: 9), anchor: .leading)
                                t += step
                            }
                            context.fill(Path(CGRect(x: 0, y: 0, width: width, height: rulerHeight)), with: .color(Color.black.opacity(0.25)))
                            for (index, row) in rows.enumerated() {
                                let top = rulerHeight + CGFloat(index) * rowHeight
                                if index % 2 == 1 {
                                    context.fill(Path(CGRect(x: 0, y: top, width: width, height: rowHeight)), with: .color(Color.white.opacity(0.025)))
                                }
                                let bar = CGRect(x: x(row.start, width), y: top + (row.depth == 0 ? 7 : 3), width: max(x(row.end, width) - x(row.start, width), 3),
                                                 height: row.depth == 0 ? 6 : rowHeight - 6)
                                let selected = document.selectionID == row.nodeID
                                let shape = Path(roundedRect: bar, cornerRadius: 3)
                                if row.openEnded {
                                    context.fill(shape, with: .linearGradient(Gradient(colors: [row.tint.color.opacity(0.85), row.tint.color.opacity(0.1)]),
                                                                              startPoint: CGPoint(x: bar.minX, y: 0), endPoint: CGPoint(x: bar.maxX, y: 0)))
                                } else {
                                    context.fill(shape, with: .color(row.tint.color.opacity(row.depth == 0 ? 0.55 : 0.8)))
                                }
                                if selected { context.stroke(shape, with: .color(.white), lineWidth: 1.5) }
                            }
                            let px = x(document.time, width)
                            var playhead = Path()
                            playhead.move(to: CGPoint(x: px, y: 0))
                            playhead.addLine(to: CGPoint(x: px, y: canvasSize.height))
                            context.stroke(playhead, with: .color(Theme.playhead), lineWidth: 1.5)
                            let box = CGRect(x: px - 16, y: 1, width: 32, height: rulerHeight - 2)
                            context.fill(Path(roundedRect: box, cornerRadius: 3), with: .color(Theme.playhead))
                            context.draw(Text("\(Int(document.time.rounded()))").font(Theme.small).foregroundStyle(.white), at: CGPoint(x: px, y: rulerHeight / 2))
                        }
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0).onChanged { drag in
                            let width = geometry.size.width
                            if drag.startLocation.y > rulerHeight && abs(drag.translation.width) < 3 {
                                let index = Int((drag.startLocation.y - rulerHeight) / rowHeight)
                                if index >= 0 && index < rows.count { document.selectionID = rows[index].nodeID }
                            }
                            document.time = min(max(0, time(drag.location.x, width).rounded()), document.duration)
                        })
                    }
                    .frame(height: rulerHeight + CGFloat(rows.count) * rowHeight + 8)
                }
            }
            .background(Color(white: 0.157))
        }
        .onReceive(timer) { _ in
            guard playing else { return }
            document.time = document.time + 1 > document.duration ? 0 : document.time + 1
        }
    }
}
