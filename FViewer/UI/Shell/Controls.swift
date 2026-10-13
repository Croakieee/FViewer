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
    @State private var dragStart: Double?
    @State private var moved = false
    @State private var live: Double?
    @GestureState private var pressing = false
    @FocusState private var focused: Bool

    private var formatted: String {
        if isInteger { return String(Int(value.rounded())) }
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
                    .onSubmit { finishEditing() }
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
            editing = true
        }
        dragStart = nil
        live = nil
        moved = false
    }

    private func finishEditing() {
        editing = false
        let cleaned = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let parsed = Double(cleaned) else { return }
        let next = isInteger ? parsed.rounded() : parsed
        if next != value { onCommit(value, next) }
    }
}

struct CheckBox: View {
    let isOn: Bool
    let label: String
    var mixed = false
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
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture { action(!isOn) }
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
            .onAppear { text = value }
            .onChange(of: value) { _, next in if !focused { text = next } }
            .onSubmit { if text != value { action(text) } }
            .onChange(of: focused) { _, isFocused in if !isFocused && text != value { action(text) } }
    }
}

struct ColorField: View {
    let color: SIMD4<Double>
    let alpha: Bool
    let onLive: (SIMD4<Double>) -> Void
    let onCommit: (SIMD4<Double>, SIMD4<Double>) -> Void
    @State private var origin: SIMD4<Double>?
    @State private var pending: DispatchWorkItem?

    private var hex: String {
        String(format: "#%02X%02X%02X", Int((min(max(color.x, 0), 1) * 255).rounded()), Int((min(max(color.y, 0), 1) * 255).rounded()),
               Int((min(max(color.z, 0), 1) * 255).rounded()))
    }

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                CheckerBackground()
                Color(.sRGB, red: color.x, green: color.y, blue: color.z, opacity: alpha ? color.w : 1)
                Text(hex + (alpha ? String(format: "  %.0f%%", color.w * 100) : "")).font(Theme.small).monospacedDigit()
                    .foregroundStyle(color.x * 0.3 + color.y * 0.59 + color.z * 0.11 > 0.55 ? Color.black : Color.white)
            }
            .frame(height: 20)
            .clipShape(RoundedRectangle(cornerRadius: 4))
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

struct ConstantCurveFields: View {
    @ObservedObject var document: EffectDocument
    let group: CurveGroup

    static func applies(_ group: CurveGroup) -> Bool {
        !group.channels.isEmpty && group.channels.allSatisfy { $0.colorComponent == nil && $0.read().count == 1 }
    }

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(group.channels) { channel in
                let key = channel.read().first
                NumberField(label: group.channels.count == 1 ? "Value" : channel.name.replacingOccurrences(of: "Random ", with: "± "),
                            value: key?.value ?? 0, suffix: group.isAngle ? "°" : "", step: group.isAngle ? 1 : 0.01, onLive: { _ in },
                            onCommit: { _, next in
                                guard var point = channel.read().first, point.value != next else { return }
                                let before = document.snapshot()
                                point.value = channel.clampUnit ? min(max(next, 0), 1) : next
                                channel.write([point])
                                document.registerUndo("Set " + group.title + (channel.name == group.title ? "" : " " + channel.name), since: before)
                            })
                    .frame(width: 104)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 24)
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
                .onTapGesture { item.create() }
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

    static func recipes(for tag: String) -> [(name: String, help: String, values: [(String, Int)])] {
        tag == "Ptcl" ? particle : tag == "Emit" ? emitter : []
    }

    private func field(_ tag: String) -> PropField? { fields.first { $0.tag == tag && $0.write != nil } }

    private func value(_ field: PropField) -> Int {
        switch field.read() {
        case .bool(let on): return on ? 1 : 0
        default: return Int(field.read().number.rounded())
        }
    }

    static func matches(_ values: [(String, Int)], _ fields: [PropField]) -> Bool {
        values.allSatisfy { entry in
            guard let field = fields.first(where: { $0.tag == entry.0 && $0.write != nil }) else { return false }
            if case .bool(let on) = field.read() { return (on ? 1 : 0) == entry.1 }
            return Int(field.read().number.rounded()) == entry.1
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
                    .onTapGesture { apply(recipe) }
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
            .onTapGesture { shown.toggle() }
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
            .onTapGesture(perform: action)
    }
}

struct Panel<Content: View>: View {
    let title: String
    var trailing: String = ""
    @State private var open = true
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: open ? "chevron.down" : "chevron.right").font(.system(size: 8, weight: .bold)).frame(width: 10)
                Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1)
                Spacer()
                Text(trailing).font(Theme.small).foregroundStyle(Theme.dim)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .contentShape(Rectangle())
            .onTapGesture { open.toggle() }
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
            .onTapGesture(perform: action)
            .help(help)
    }
}

final class ScrollMonitorView: NSView {
    var onScroll: ((CGSize, NSEvent.ModifierFlags, CGPoint) -> Void)?
    var onMagnify: ((CGFloat, CGPoint) -> Void)?
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

    func makeNSView(context: Context) -> ScrollMonitorView {
        let view = ScrollMonitorView()
        view.onScroll = onScroll
        view.onMagnify = onMagnify
        return view
    }

    func updateNSView(_ view: ScrollMonitorView, context: Context) {
        view.onScroll = onScroll
        view.onMagnify = onMagnify
    }
}
