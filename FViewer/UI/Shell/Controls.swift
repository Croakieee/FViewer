import AppKit
import SwiftUI

struct JoinedShape: Shape {
    var top: Bool
    var bottom: Bool
    var radius: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        let t = top ? radius : 0
        let b = bottom ? radius : 0
        return Path(roundedRect: rect, cornerRadii: RectangleCornerRadii(topLeading: t, bottomLeading: b, bottomTrailing: b, topTrailing: t))
    }
}

struct NumberField: View {
    let label: String?
    let value: Double
    var isInteger = false
    var suffix = ""
    var step: Double = 0.01
    var roundTop = true
    var roundBottom = true
    var digits: Int?
    let onLive: (Double) -> Void
    let onCommit: (Double, Double) -> Void

    @State private var hovering = false
    @State private var editing = false
    @State private var text = ""
    @State private var editBase = 0.0
    @State private var dragStart: Double?
    @State private var moved = false
    @State private var live: Double?
    @GestureState private var pressing = false
    @FocusState private var focused: Bool

    private var formatted: String {
        if isInteger { return String(Int(safe: value.rounded())) }
        let digits = self.digits ?? (abs(value) >= 100 ? 2 : abs(value) >= 1 ? 3 : 4)
        return String(format: "%.\(digits)f", value)
    }

    var body: some View {
        ZStack {
            JoinedShape(top: roundTop, bottom: roundBottom)
                .fill(editing ? Theme.fieldDark : hovering ? Theme.field.opacity(1.25) : Theme.field)
            if editing {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .font(Theme.font)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .padding(.horizontal, 6)
                    .onSubmit { finishEditing(submitted: true) }
                    .onExitCommand { editing = false }
                    .onAppear { DispatchQueue.main.async { focused = true } }
                    .onChange(of: focused) { old, isFocused in if old && !isFocused && editing { finishEditing() } }
            } else {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left").font(.system(size: 7, weight: .bold)).opacity(hovering ? 0.7 : 0)
                    if let label {
                        Text(label).lineLimit(1).layoutPriority(-1)
                        Spacer(minLength: 2)
                        Text(formatted + suffix).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                    } else {
                        Spacer(minLength: 0)
                        Text(formatted + suffix).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                    }
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).opacity(hovering ? 0.7 : 0)
                }
                .font(Theme.font)
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 4)
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .pointerStyle(editing ? .default : .columnResize)
        .gesture(DragGesture(minimumDistance: 0)
            .updating($pressing) { _, state, _ in state = true }
            .onChanged { drag in
                guard !editing else { return }
                if dragStart == nil {
                    dragStart = value
                    moved = false
                }
                if abs(drag.translation.width) > 3 { moved = true }
                guard moved, let origin = dragStart else { return }
                let flags = NSEvent.modifierFlags
                let magnitude = max(1, pow(10, floor(log10(max(abs(origin), 1)))))
                var unit = isInteger ? max(1.0 / 6, magnitude / 60) : step * magnitude
                if flags.contains(.shift) { unit *= 0.1 }
                var next = origin + Double(drag.translation.width) * unit
                if isInteger { next = next.rounded() }
                if flags.contains(.control) && !isInteger {
                    let snap = step * magnitude * 10
                    next = (next / snap).rounded() * snap
                }
                guard next != live else { return }
                live = next
                onLive(next)
            }
            .onEnded { _ in finishDrag(cancelled: false) })
        .onChange(of: pressing) { _, now in if !now { DispatchQueue.main.async { finishDrag(cancelled: true) } } }
    }

    private func finishDrag(cancelled: Bool) {
        guard !editing, let origin = dragStart else { return }
        if moved {
            onCommit(origin, live ?? value)
        } else if !cancelled {
            text = formatted
            editBase = value
            editing = true
        }
        dragStart = nil
        live = nil
        moved = false
    }

    private func finishEditing(submitted: Bool = false) {
        editing = false
        guard submitted || value == editBase || (value.isNaN && editBase.isNaN) else { return }
        let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let parsed = Double(cleaned), parsed.isFinite else { return }
        let next = isInteger ? min(max(parsed.rounded(), -2_000_000_000), 2_000_000_000) : min(max(parsed, -1e9), 1e9)
        if next != value { onCommit(value, next) }
    }
}

struct CheckBox: View {
    let isOn: Bool
    let label: String
    var mixed = false
    var dimmed = false
    let action: (Bool) -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(isOn ? Theme.accent : hovering ? Theme.field.opacity(1.25) : Theme.field)
                if isOn { Image(systemName: "checkmark").font(.system(size: 8, weight: .heavy)).foregroundStyle(.white) }
                if mixed { Image(systemName: "minus").font(.system(size: 8, weight: .heavy)).foregroundStyle(Theme.dim) }
            }
            .frame(width: 14, height: 14)
            Text(label).font(Theme.font).foregroundStyle(dimmed ? Theme.dim : Theme.text).lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .pressable { action(!isOn) }
    }
}

struct ChoiceField: View {
    let choices: [FieldChoice]
    let value: Int
    let action: (Int) -> Void

    var body: some View {
        Menu {
            ForEach(choices, id: \.self) { choice in
                Button {
                    action(choice.value)
                } label: {
                    if choice.value == value { Label(choice.name, systemImage: "checkmark") } else { Text(choice.name) }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(choices.first { $0.value == value }?.name ?? "\(value)").lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
            }
            .font(Theme.font)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.16)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.gray(0.24), lineWidth: 1))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }
}

struct TextValueField: View {
    let value: String
    let action: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var base = ""

    private func commit() {
        guard value == base else {
            text = value
            base = value
            return
        }
        if text != value { action(text) }
    }

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .font(Theme.font)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(focused ? Theme.accent : Theme.gray(0.24), lineWidth: 1))
            .focused($focused)
            .onAppear {
                text = value
                base = value
            }
            .onChange(of: value) { _, next in if !focused { text = next } }
            .onSubmit { if text != value { action(text) } }
            .onChange(of: focused) { _, isFocused in
                if isFocused {
                    base = value
                } else {
                    commit()
                }
            }
    }
}

struct ColorField: View {
    let color: SIMD4<Double>
    let alpha: Bool
    let onLive: (SIMD4<Double>) -> Void
    let onCommit: (SIMD4<Double>, SIMD4<Double>) -> Void
    @State private var origin: SIMD4<Double>?
    @State private var pending: DispatchWorkItem?
    @State private var editing = false
    @State private var text = ""
    @FocusState private var focused: Bool

    private func parsed(_ raw: String) -> SIMD4<Double>? {
        let digits = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
        guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else { return nil }
        if digits.count == 6 {
            return SIMD4(Double((value >> 16) & 0xff) / 255, Double((value >> 8) & 0xff) / 255, Double(value & 0xff) / 255, color.w)
        }
        return SIMD4(Double((value >> 24) & 0xff) / 255, Double((value >> 16) & 0xff) / 255, Double((value >> 8) & 0xff) / 255,
                     alpha ? Double(value & 0xff) / 255 : color.w)
    }

    private func finishEditing() {
        guard editing else { return }
        editing = false
        if let next = parsed(text), next != color { onCommit(color, next) }
    }

    private var hex: String {
        String(format: "#%02X%02X%02X", Int(safe: (min(max(color.x, 0), 1) * 255).rounded()), Int(safe: (min(max(color.y, 0), 1) * 255).rounded()),
               Int(safe: (min(max(color.z, 0), 1) * 255).rounded()))
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                CheckerBackground()
                Color(.sRGB, red: color.x, green: color.y, blue: color.z, opacity: alpha ? color.w : 1)
                if editing {
                    TextField("", text: $text)
                        .textFieldStyle(.plain)
                        .font(Theme.small)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(color.x * 0.3 + color.y * 0.59 + color.z * 0.11 > 0.55 ? Color.black : Color.white)
                        .focused($focused)
                        .onSubmit { finishEditing() }
                        .onExitCommand { editing = false }
                        .onAppear { DispatchQueue.main.async { focused = true } }
                        .onChange(of: focused) { old, now in if old && !now { finishEditing() } }
                } else {
                    Text(hex + (alpha ? String(format: "  %.0f%%", color.w * 100) : "")).font(Theme.small).monospacedDigit()
                        .foregroundStyle(color.x * 0.3 + color.y * 0.59 + color.z * 0.11 > 0.55 ? Color.black : Color.white)
                }
            }
            .frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .contentShape(Rectangle())
            .pressable {
                guard !editing else { return }
                text = ""
                editing = true
            }
            .help("Click to type a hex colour: RRGGBB, or RRGGBBAA where alpha applies")
            ColorPicker("", selection: Binding(
                get: { Color(.sRGB, red: color.x, green: color.y, blue: color.z, opacity: color.w) },
                set: { picked in
                    guard let c = NSColor(picked).usingColorSpace(.sRGB) else { return }
                    let next = SIMD4(Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent), alpha ? Double(c.alphaComponent) : color.w)
                    if origin == nil { origin = color }
                    onLive(next)
                    pending?.cancel()
                    let work = DispatchWorkItem {
                        if let start = origin { onCommit(start, next) }
                        origin = nil
                    }
                    pending = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
                }), supportsOpacity: alpha)
                .labelsHidden()
                .scaleEffect(0.62)
                .frame(width: 28, height: 20)
                .clipped()
        }
    }
}

final class ClickCatcherView: NSView {
    var onLeft: () -> Void = {}
    var onRight: () -> Void = {}

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { onRight() } else { onLeft() }
    }

    override func rightMouseDown(with event: NSEvent) { onRight() }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

struct ClickCatcher: NSViewRepresentable {
    let onLeft: () -> Void
    let onRight: () -> Void

    func makeNSView(context: Context) -> ClickCatcherView {
        let view = ClickCatcherView()
        view.onLeft = onLeft
        view.onRight = onRight
        return view
    }

    func updateNSView(_ view: ClickCatcherView, context: Context) {
        view.onLeft = onLeft
        view.onRight = onRight
    }
}

struct CurveSparkline: View {
    let keys: [CurveKeyPoint]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard let first = keys.first, let last = keys.last, last.time > first.time else { return }
            let steps = 48
            let values = (0...steps).map { CurveMath.sample(keys, at: first.time + (last.time - first.time) * Double($0) / Double(steps)) }
            let low = values.min() ?? 0, high = values.max() ?? 1
            let span = max(high - low, 1e-9)
            var line = Path()
            for (index, value) in values.enumerated() {
                let point = CGPoint(x: size.width * CGFloat(index) / CGFloat(steps),
                                    y: high - low < 1e-9 ? size.height / 2 : 2 + (size.height - 4) * CGFloat(1 - (value - low) / span))
                if index == 0 { line.move(to: point) } else { line.addLine(to: point) }
            }
            var area = line
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.addLine(to: CGPoint(x: 0, y: size.height))
            area.closeSubpath()
            context.fill(area, with: .color(color.opacity(0.18)))
            context.stroke(line, with: .color(color), lineWidth: 1.2)
            for key in keys {
                let x = size.width * CGFloat((key.time - first.time) / (last.time - first.time))
                context.fill(Path(CGRect(x: x - 0.5, y: size.height - 3, width: 1, height: 3)), with: .color(Color.white.opacity(0.55)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.fieldDark.opacity(0.6)))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct CurveGradientStrip: View {
    let group: CurveGroup

    var body: some View {
        Canvas { context, size in
            let channels = (0..<3).map { c in group.channels.first { $0.colorComponent == c }?.read() ?? [] }
            let times = channels.flatMap { $0.map(\.time) }
            guard let first = times.min(), let last = times.max() else { return }
            var x: CGFloat = 0
            while x < size.width {
                let t = last > first ? first + (last - first) * Double(x / size.width) : first
                let color = Color(.sRGB, red: CurveMath.sample(channels[0], at: t), green: CurveMath.sample(channels[1], at: t),
                                  blue: CurveMath.sample(channels[2], at: t))
                context.fill(Path(CGRect(x: x, y: 0, width: 2, height: size.height)), with: .color(color))
                x += 2
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.4), lineWidth: 1))
    }
}

struct CurveValueRows: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let group: CurveGroup
    let changed: Bool
    var random: CurveGroup?
    var addRandom: MissingCurve?
    var floats = true
    @State private var floating = false

    private func open() {
        document.activeCurveID = group.id
        if floats { floating = true }
    }

    static func pairs(_ curves: [CurveGroup], _ missing: [MissingCurve]) -> (rows: [(group: CurveGroup, random: CurveGroup?, add: MissingCurve?)], rest: [MissingCurve]) {
        let titles = Set(curves.map(\.title))
        var used: Set<String> = []
        var rows: [(group: CurveGroup, random: CurveGroup?, add: MissingCurve?)] = []
        for group in curves {
            if group.title.hasSuffix(" Random"), titles.contains(String(group.title.dropLast(7))) { continue }
            let partner = group.title + " Random"
            let add = missing.first { $0.title == partner }
            if let add { used.insert(add.id) }
            rows.append((group, curves.first { $0.title == partner }, add))
        }
        return (rows, missing.filter { !used.contains($0.id) })
    }

    private func float(_ target: CurveGroup) {
        document.activeCurveID = target.id
        if floats { floating = true }
    }

    private var colorChannels: [CurveChannel] { group.channels.filter { $0.colorComponent != nil } }
    private var valueChannels: [CurveChannel] { group.channels.filter { $0.colorComponent == nil } }

    static func mode(_ group: CurveGroup) -> String {
        let counts = group.channels.map { $0.read().count }
        guard let most = counts.max(), most > 0 else { return "Empty" }
        if group.channels.contains(where: { $0.colorComponent != nil }) { return most > 1 ? "Gradient" : "Constant" }
        if most == 1 { return "Constant" }
        return counts.allSatisfy { $0 > 1 } ? "Curve" : "Mixed"
    }

    private func label(_ channel: CurveChannel) -> String {
        channel.name.replacingOccurrences(of: "Random ", with: "± ")
    }

    private func span() -> Double {
        max(1, (document.clock.endFrame ?? document.sequencerRows.map(\.end).max() ?? 30).rounded())
    }

    private func makeConstant(_ channels: [CurveChannel]) {
        let before = document.snapshot()
        let time = document.clock.time
        let values = channels.map { channel -> Double in
            let keys = channel.read()
            return keys.isEmpty ? (channel.clampUnit ? 1 : 0) : keys.count == 1 ? keys[0].value : CurveMath.sample(keys, at: time)
        }
        for (channel, value) in zip(channels, values) {
            channel.write([CurveKeyPoint(time: 0, value: value, interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0)])
        }
        document.registerUndo("Make " + group.title + " Constant", since: before)
    }

    private func makeCurve(_ channels: [CurveChannel]) {
        let before = document.snapshot()
        let end = span()
        for channel in channels {
            let keys = channel.read()
            guard keys.count < 2 else { continue }
            let value = keys.first?.value ?? (channel.clampUnit ? 1 : 0)
            channel.write([CurveKeyPoint(time: 0, value: value, interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0),
                           CurveKeyPoint(time: end, value: value, interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0)])
        }
        document.registerUndo("Make " + group.title + " Curve", since: before)
        open()
    }

    private func modeChip(_ title: String, _ active: Bool, _ help: String, _ action: @escaping () -> Void) -> some View {
        Text(title).font(Theme.small).foregroundStyle(active ? Color.white : Theme.dim).lineLimit(1).fixedSize()
            .padding(.horizontal, 6)
            .frame(height: 16)
            .background(RoundedRectangle(cornerRadius: 3).fill(active ? Theme.accent : Theme.gray(0.2)))
            .contentShape(Rectangle())
            .pressable(perform: action)
            .help(help)
    }

    private func modeMenu(_ channels: [CurveChannel], _ current: String) -> some View {
        let gradient = channels.contains { $0.colorComponent != nil }
        return HStack(spacing: 1) {
            modeChip("Constant", current == "Constant", "One value for the whole life. A curve becomes the value it has at the playhead") { makeConstant(channels) }
            modeChip(gradient ? "Gradient" : "Curve", current == "Curve" || current == "Gradient" || current == "Mixed",
                     "A value that changes over time. Opens the curve in the Graph Editor") {
                if current == "Curve" || current == "Gradient" { open() } else { makeCurve(channels) }
            }
        }
    }

    private func constantField(_ channel: CurveChannel, _ title: String?, in owner: CurveGroup? = nil) -> some View {
        let group = owner ?? self.group
        return NumberField(label: title, value: channel.read().first?.value ?? 0, suffix: group.isAngle ? "°" : "", step: group.isAngle ? 1 : 0.01, onLive: { _ in },
                    onCommit: { _, next in
                        guard var point = channel.read().first, point.value != next else { return }
                        let before = document.snapshot()
                        point.value = channel.clampUnit ? min(max(next, 0), 1) : next
                        channel.write([point])
                        document.registerUndo("Set " + group.title + (channel.name == group.title ? "" : " " + channel.name), since: before)
                    })
    }

    @ViewBuilder private func editor(_ channel: CurveChannel, title: String?, in owner: CurveGroup? = nil) -> some View {
        let keys = channel.read()
        if keys.isEmpty {
            Text("no keys").font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
        } else if keys.count == 1 {
            constantField(channel, title, in: owner)
        } else {
            HStack(spacing: 4) {
                if let title { Text(title).font(Theme.small).foregroundStyle(Theme.dim).frame(width: 30, alignment: .leading) }
                CurveSparkline(keys: keys, color: channel.color).frame(height: 18).contentShape(Rectangle()).pressable { float(owner ?? group) }
                    .help("\(keys.count) keys, \(String(format: "%.3g", keys.map(\.value).min() ?? 0)) … \(String(format: "%.3g", keys.map(\.value).max() ?? 0)). Click to edit the curve")
            }
        }
    }

    @ViewBuilder private var randomLine: some View {
        if let random, let channel = random.channels.first {
            HStack(spacing: 4) {
                if channel.read().count == 1 { constantField(channel, "± Random", in: random) } else { editor(channel, title: "±", in: random) }
                if channel.read().count == 1 {
                    Image(systemName: "waveform.path").font(.system(size: 9)).foregroundStyle(Theme.dim).frame(width: 14, height: 18).contentShape(Rectangle())
                        .pressable { makeCurve(random.channels) }.help("Turn the random range into a curve")
                }
                if let remove = random.remove {
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 14, height: 18)
                        .contentShape(Rectangle()).pressable(perform: remove).help("Remove the random range from the file")
                }
            }
            .padding(.leading, 24)
            .padding(.trailing, 6)
        } else if let addRandom {
            HStack(spacing: 3) {
                Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                Text("± Random").font(Theme.small)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Theme.dim)
            .padding(.leading, 30)
            .frame(height: 14)
            .contentShape(Rectangle())
            .pressable { addRandom.create() }
            .help("Add a random range: each particle or emitter gets its own value within ± this amount")
        }
    }

    private var unseen: Bool { document.format == .avfx && PreviewCoverage.ignoresCurve(group.tag) }

    private var header: some View {
        let active = document.activeCurveID == group.id
        return HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(group.channels.prefix(4)) { channel in Rectangle().fill(channel.color).frame(width: 3, height: 12) }
            }
            .frame(width: 18, alignment: .leading)
            Text(group.title).font(Theme.font).foregroundStyle(changed ? Theme.changed : unseen ? Theme.dim : Theme.text).lineLimit(1).minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                .help(unseen ? group.title + " [" + group.tag + "]\n" + PreviewCoverage.note : group.title + " [" + group.tag + "]")
            if changed { ChangeDot() }
            modeMenu(group.channels, CurveValueRows.mode(group))
            if let remove = group.remove {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim)
                    .frame(width: 14, height: 20).contentShape(Rectangle())
                    .pressable(perform: remove).help("Remove this curve from the file")
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.selection : Theme.field.opacity(0.45)))
        .contentShape(Rectangle())
        .pressable(perform: open)
    }

    var body: some View {
        VStack(spacing: 2) {
            header
            if group.channels.count == 1, let single = group.channels.first, !single.read().isEmpty {
                Group {
                    if single.read().count == 1 { constantField(single, "Value") } else { editor(single, title: nil) }
                }
                .padding(.leading, 24)
                .padding(.trailing, 6)
            }
            if group.channels.count > 1 {
                VStack(spacing: 2) {
                    if colorChannels.count == 3 {
                        HStack(spacing: 4) {
                            Text("RGB").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 30, alignment: .leading)
                            CurveGradientStrip(group: group).frame(height: 16).contentShape(Rectangle()).pressable { float(group) }
                                .help("Colour over time. Click to edit here")
                        }
                    }
                    ForEach(valueChannels) { channel in
                        let keys = channel.read()
                        if keys.count == 1 { constantField(channel, label(channel)) } else { editor(channel, title: label(channel)) }
                    }
                }
                .padding(.leading, 24)
                .padding(.trailing, 6)
            }
            randomLine
        }
        .popover(isPresented: $floating, arrowEdge: .leading) {
            CurveEditorView(document: document, clock: document.clock)
                .environmentObject(app)
                .frame(width: 820, height: 420)
                .background(Theme.panel)
                .preferredColorScheme(Theme.scheme)
        }
    }
}

struct UnsetRows: View {
    let items: [MissingCurve]

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(items) { item in
                HStack(spacing: 3) {
                    Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                    Text(item.title).font(Theme.small).lineLimit(1)
                }
                .foregroundStyle(Theme.dim)
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.dim.opacity(0.45), lineWidth: 1))
                .contentShape(Rectangle())
                .pressable { item.create() }
                .help("Not in the file yet. Click to add it with its default value")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecipeRows: View {
    @ObservedObject var document: EffectDocument
    let fields: [PropField]
    let recipes: [(name: String, help: String, values: [(String, Int)])]

    static let particle: [(name: String, help: String, values: [(String, Int)])] = [
        ("Additive Glow", "Draw Mode Add, depth test on, depth write off, no culling", [("RMT", 2), ("DsDt", 1), ("DsDw", 0), ("CulT", 0)]),
        ("Alpha Blend", "Draw Mode Blend, depth test on, depth write off", [("RMT", 0), ("DsDt", 1), ("DsDw", 0)]),
        ("Screen", "Draw Mode Screen, depth test on, depth write off", [("RMT", 4), ("DsDt", 1), ("DsDw", 0)]),
        ("Solid", "Draw Mode Opacity with depth test and depth write on", [("RMT", 8), ("DsDt", 1), ("DsDw", 1)]),
        ("On Top", "Depth test and depth write off, so nothing hides the particle", [("DsDt", 0), ("DsDw", 0)]),
        ("Soft Edges", "Soft Particle on with depth test on", [("DsSp", 1), ("DsDt", 1)]),
        ("Two Sided", "Culling Type None", [("CulT", 0)]),
        ("Cull Back", "Culling Type Back", [("CulT", 2)]),
        ("Unlit", "Tone map and fog off", [("bATM", 0), ("bAFg", 0)]),
        ("Scene Lit", "Tone map and fog on", [("bATM", 1), ("bAFg", 1)]),
        ("No Loop", "Loop Start and Loop End 0", [("LpSt", 0), ("LpEd", 0)]),
    ]

    static let emitter: [(name: String, help: String, values: [(String, Int)])] = [
        ("Point", "Type Point", [("EVT", 0)]),
        ("Cone", "Type Cone", [("EVT", 1)]),
        ("Any Direction", "Any Direction on", [("bAD", 1)]),
        ("Fixed Direction", "Any Direction off", [("bAD", 0)]),
        ("No Effector", "Effector Select None", [("EfNo", -1)]),
        ("No Sound", "Sound Index -1", [("SdNo", -1)]),
        ("No Loop", "Loop Start and Loop End 0", [("LpSt", 0), ("LpEd", 0)]),
    ]

    static let effector: [(name: String, help: String, values: [(String, Int)])] = [
        ("This Effect Only", "Affect Other VFX and Affect Game off", [("bAOV", 0), ("bAGm", 0)]),
        ("Affect Other VFX", "Affect Other VFX on", [("bAOV", 1)]),
        ("Affect Game", "Affect Game on", [("bAGm", 1)]),
        ("No Loop", "Loop Start and Loop End 0", [("LpSt", 0), ("LpEd", 0)]),
    ]

    static let binder: [(name: String, help: String, values: [(String, Int)])] = [
        ("Follow Target", "Following Target Orientation on", [("bFTO", 1)]),
        ("Keep Orientation", "Following Target Orientation off", [("bFTO", 0)]),
        ("Scale with VFX", "VFX Scale on", [("bVSc", 1)]),
        ("Scale with Target", "Transform Scale on", [("bTSc", 1)]),
        ("No Scaling", "VFX Scale and Transform Scale off", [("bVSc", 0), ("bTSc", 0)]),
        ("Adjust to Screen", "Adjust to Screen on", [("bATS", 1)]),
    ]

    static let timeline: [(name: String, help: String, values: [(String, Int)])] = [
        ("No Loop", "Loop Start and Loop End 0", [("LpSt", 0), ("LpEd", 0)]),
        ("No Binder", "Binder Index -1", [("BnNo", -1)]),
    ]

    static func recipes(for tag: String) -> [(name: String, help: String, values: [(String, Int)])] {
        switch tag {
        case "Ptcl": return particle
        case "Emit": return emitter
        case "Efct": return effector
        case "Bind": return binder
        case "TmLn": return timeline
        default: return []
        }
    }

    private func field(_ tag: String) -> PropField? { fields.first { $0.tag == tag && $0.write != nil } }

    private func value(_ field: PropField) -> Int {
        switch field.read() {
        case .bool(let on): return on ? 1 : 0
        default: return Int(safe: field.read().number.rounded())
        }
    }

    static func matches(_ values: [(String, Int)], _ fields: [PropField]) -> Bool {
        values.allSatisfy { entry in
            guard let field = fields.first(where: { $0.tag == entry.0 && $0.write != nil }) else { return false }
            if case .bool(let on) = field.read() { return (on ? 1 : 0) == entry.1 }
            return Int(safe: field.read().number.rounded()) == entry.1
        }
    }

    private func apply(_ recipe: (name: String, help: String, values: [(String, Int)])) {
        let before = document.snapshot()
        var changed = false
        for entry in recipe.values {
            guard let field = field(entry.0), value(field) != entry.1 else { continue }
            if case .bool = field.read() { field.write?(.bool(entry.1 != 0)) } else { field.write?(.int(entry.1)) }
            changed = true
        }
        if changed { document.registerUndo("Recipe " + recipe.name, since: before) }
    }

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(Array(recipes.enumerated()), id: \.offset) { _, recipe in
                let usable = recipe.values.contains { field($0.0) != nil }
                let active = RecipeRows.matches(recipe.values, fields)
                Text(recipe.name).font(Theme.small).foregroundStyle(usable ? Theme.text : Theme.dim).lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(height: 18)
                    .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.accent : Theme.gray(0.22)))
                    .contentShape(Rectangle())
                    .pressable { apply(recipe) }
                    .help(recipe.help)
            }
            HelpBadge(text: "A recipe sets several fields of this node at once. A highlighted recipe already matches the node. Fields that are not in the file are left alone.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TransportButtons: View {
    @ObservedObject var clock: PlaybackClock

    var body: some View {
        HStack(spacing: 2) {
            HeaderButton(symbol: "backward.end.fill", help: "Jump to start") { clock.rewind() }
            HeaderButton(symbol: clock.playing ? "pause.fill" : "play.fill", active: clock.playing, help: "Play / Pause") { clock.playing.toggle() }
        }
    }
}

struct HelpBadge: View {
    let text: String
    var symbol = "questionmark.circle"
    var tint = Theme.dim
    @State private var shown = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11))
            .foregroundStyle(shown ? Theme.text : tint)
            .frame(width: 20, height: 20)
            .contentShape(Rectangle())
            .pressable { shown.toggle() }
            .popover(isPresented: $shown, arrowEdge: .bottom) {
                Text(text).font(Theme.font).foregroundStyle(Theme.text).lineSpacing(2)
                    .frame(width: 280, alignment: .leading).fixedSize(horizontal: false, vertical: true).padding(12)
                    .preferredColorScheme(Theme.scheme)
            }
    }
}

struct SegmentButton: View {
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(Theme.font)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.accent : Theme.gray(0.22)))
            .contentShape(Rectangle())
            .pressable(perform: action)
    }
}

struct Panel<Content: View>: View {
    let title: String
    var trailing: String = ""
    var badge: String = ""
    var memory: String = ""
    @State private var open = true
    @ViewBuilder let content: () -> Content

    private var key: String { "panel.closed." + memory }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: open ? "chevron.down" : "chevron.right").font(.system(size: 8, weight: .bold)).frame(width: 10)
                Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                Spacer()
                if !badge.isEmpty {
                    Text(badge).font(.system(size: 9, design: .monospaced)).foregroundStyle(Theme.changed)
                        .padding(.horizontal, 5).frame(height: 14)
                        .background(Capsule().stroke(Theme.changed.opacity(0.6), lineWidth: 1))
                }
                Text(trailing).font(Theme.small).foregroundStyle(Theme.dim)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .contentShape(Rectangle())
            .pressable {
                open.toggle()
                if !memory.isEmpty { UserDefaults.standard.set(!open, forKey: key) }
            }
            .onAppear { if !memory.isEmpty { open = !UserDefaults.standard.bool(forKey: key) } }
            if open {
                VStack(spacing: 3) { content() }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.gray(0.24)))
        .padding(.horizontal, 6)
    }
}

struct EditorHeader<Content: View>: View {
    let symbol: String
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 11)).foregroundStyle(Theme.text)
                .frame(width: 24, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.16)))
            Text(title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            content()
        }
        .padding(.horizontal, 6)
        .frame(height: 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panel)
        .overlay(Rectangle().fill(Theme.line).frame(height: 1), alignment: .bottom)
    }
}

struct HeaderButton: View {
    let symbol: String
    var active = false
    var help = ""
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 11))
            .foregroundStyle(Theme.text)
            .frame(width: 24, height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.accent : hovering ? Theme.field : Theme.gray(0.22)))
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .pressable(perform: action)
            .help(help)
            .accessibilityLabel(help.isEmpty ? symbol : help)
    }
}

final class ScrollMonitorView: NSView {
    var onScroll: ((CGSize, NSEvent.ModifierFlags, CGPoint) -> Void)?
    var onMagnify: ((CGFloat, CGPoint) -> Void)?
    var passVertical = false
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        guard window != nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .magnify]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            let local = self.convert(event.locationInWindow, from: nil)
            guard self.bounds.contains(local) else { return event }
            let point = CGPoint(x: local.x, y: self.bounds.height - local.y)
            if event.type == .magnify {
                self.onMagnify?(event.magnification, point)
            } else {
                let precise = event.hasPreciseScrollingDeltas
                let delta = CGSize(width: event.scrollingDeltaX * (precise ? 1 : 8), height: event.scrollingDeltaY * (precise ? 1 : 8))
                if self.passVertical, !event.modifierFlags.contains(.command), abs(delta.height) >= abs(delta.width) { return event }
                self.onScroll?(delta, event.modifierFlags, point)
            }
            return nil
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

struct ScrollMonitor: NSViewRepresentable {
    let onScroll: (CGSize, NSEvent.ModifierFlags, CGPoint) -> Void
    let onMagnify: (CGFloat, CGPoint) -> Void
    var passVertical = false

    func makeNSView(context: Context) -> ScrollMonitorView {
        let view = ScrollMonitorView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        view.passVertical = passVertical
        return view
    }

    func updateNSView(_ view: ScrollMonitorView, context: Context) {
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        view.passVertical = passVertical
    }
}
