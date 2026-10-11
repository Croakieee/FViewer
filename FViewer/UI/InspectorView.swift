import SwiftUI

private enum FieldRowItem: Identifiable {
    case single(PropField)
    case vector(String, [PropField])

    var id: String {
        switch self {
        case .single(let field): return field.id
        case .vector(_, let fields): return fields[0].id + "+"
        }
    }

    static func group(_ fields: [PropField]) -> [FieldRowItem] {
        var result: [FieldRowItem] = []
        var i = 0
        func numeric(_ field: PropField) -> Bool {
            switch field.kind {
            case .double, .angle, .int: return true
            default: return false
            }
        }
        func split(_ label: String) -> (String, String)? {
            for axis in ["X", "Y", "Z"] where label.hasSuffix(" " + axis) {
                return (String(label.dropLast(2)), axis)
            }
            return nil
        }
        while i < fields.count {
            if numeric(fields[i]), let (prefix, axis) = split(fields[i].label), axis == "X" {
                var run = [fields[i]]
                for (offset, next) in ["Y", "Z"].enumerated() where i + offset + 1 < fields.count {
                    let candidate = fields[i + offset + 1]
                    guard run.count == offset + 1, numeric(candidate), let (p, a) = split(candidate.label), p == prefix, a == next else { break }
                    run.append(candidate)
                }
                if run.count > 1 {
                    result.append(.vector(prefix, run))
                    i += run.count
                    continue
                }
            }
            result.append(.single(fields[i]))
            i += 1
        }
        return result
    }
}

struct FieldControl: View {
    @ObservedObject var document: EffectDocument
    let field: PropField
    var label: String?
    var roundTop = true
    var roundBottom = true

    var body: some View {
        let value = field.read()
        switch field.kind {
        case .int:
            NumberField(label: label, value: value.number, isInteger: true, roundTop: roundTop, roundBottom: roundBottom,
                        onLive: { document.setLive(field, .int(Int($0))) },
                        onCommit: { old, new in
                            field.write?(.int(Int(old)))
                            document.commit(field, from: .int(Int(old)), to: .int(Int(new)))
                        })
        case .double, .angle:
            let angle: Bool = { if case .angle = field.kind { return true }; return false }()
            NumberField(label: label, value: value.number, suffix: angle ? "°" : "", step: angle ? 0.5 : 0.01, roundTop: roundTop,
                        roundBottom: roundBottom,
                        onLive: { document.setLive(field, .double($0)) },
                        onCommit: { old, new in
                            field.write?(.double(old))
                            document.commit(field, from: .double(old), to: .double(new))
                        })
        case .bool:
            let unset: Bool = { if case .int = value { return true }; return false }()
            CheckBox(isOn: value == .bool(true), label: label ?? "", mixed: unset) { _ in
                let next: FieldValue = unset ? .bool(true) : value == .bool(true) ? .bool(false) : field.triState ? .int(255) : .bool(true)
                document.commit(field, from: value, to: next)
            }
            .help(unset ? "Not set in the file. Click cycles: not set → on → off" : field.triState ? "Click cycles: on → off → not set" : "")
        case .choice(let choices):
            ChoiceField(choices: choices, value: Int(value.number)) { document.commit(field, from: value, to: .int($0)) }
        case .text:
            TextValueField(value: { if case .text(let s) = value { return s }; return "" }()) {
                document.commit(field, from: value, to: .text($0))
            }
        case .color(let alpha):
            let current: SIMD4<Double> = { if case .color(let r, let g, let b, let a) = value { return SIMD4(r, g, b, a) }; return SIMD4(1, 1, 1, 1) }()
            ColorField(color: current, alpha: alpha,
                       onLive: { document.setLive(field, .color($0.x, $0.y, $0.z, $0.w)) },
                       onCommit: { old, new in
                           field.write?(.color(old.x, old.y, old.z, old.w))
                           document.commit(field, from: .color(old.x, old.y, old.z, old.w), to: .color(new.x, new.y, new.z, new.w))
                       })
        case .info:
            Text({ if case .text(let s) = value { return s }; return "\(value.number)" }())
                .font(Theme.font).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
        }
    }
}

struct FieldRows: View {
    @ObservedObject var document: EffectDocument
    let fields: [PropField]
    var nodeID = ""
    @Environment(\.labelWidth) private var labelWidth

    private func changed(_ field: PropField) -> Bool { !nodeID.isEmpty && document.isChanged(field, in: nodeID) }

    @ViewBuilder private func resetMenu(_ field: PropField) -> some View {
        if changed(field), let before = document.originalValue(of: field, in: nodeID) {
            Button("Reset to Original (\(document.describe(before)))") { document.commit(field, from: field.read(), to: before) }
        }
        if let unassign = field.unassign { Button("Remove from File", role: .destructive, action: unassign) }
    }

    private func label(_ text: String, _ field: PropField?) -> some View {
        let isChanged = field.map(changed) ?? false
        let before = isChanged ? field.flatMap { document.originalValue(of: $0, in: nodeID) } : nil
        var help = field.map { "\($0.label) [\($0.tag)]" } ?? text
        if isChanged { help += " · was " + (before.map(document.describe) ?? "not in the file") }
        return HStack(spacing: 4) {
            Spacer(minLength: 0)
            if isChanged { ChangeDot(added: before == nil) }
            Text(text).font(Theme.font).foregroundStyle(isChanged ? Theme.changed : Theme.text).lineLimit(1)
        }
        .frame(width: labelWidth, height: 20)
        .help(help)
        .contentShape(Rectangle())
        .contextMenu { if let field { resetMenu(field) } }
    }

    var body: some View {
        ForEach(FieldRowItem.group(fields)) { item in
            switch item {
            case .single(let field):
                HStack(spacing: 8) {
                    if case .bool = field.kind {
                        label("", field)
                        FieldControl(document: document, field: field, label: field.label)
                    } else {
                        label(field.label, field)
                        FieldControl(document: document, field: field)
                    }
                    if let animate = field.animate {
                        Image(systemName: "diamond").font(.system(size: 9)).foregroundStyle(Theme.dim)
                            .frame(width: 14, height: 20).contentShape(Rectangle())
                            .onTapGesture(perform: animate).help("Animate this value with keyframes")
                    }
                }
            case .vector(let prefix, let parts):
                HStack(alignment: .top, spacing: 8) {
                    label(prefix, nil)
                    VStack(spacing: 1) {
                        ForEach(Array(parts.enumerated()), id: \.element.id) { index, field in
                            HStack(spacing: 4) {
                                FieldControl(document: document, field: field, label: String(field.label.suffix(1)), roundTop: index == 0,
                                             roundBottom: index == parts.count - 1)
                                if changed(field) {
                                    ChangeDot().frame(width: 10, height: 20).contentShape(Rectangle()).contextMenu { resetMenu(field) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CheckerBackground: View {
    var body: some View {
        Canvas { context, size in
            let cell: CGFloat = 8
            for row in 0...Int(size.height / cell) {
                for column in 0...Int(size.width / cell) {
                    let dark = (row + column) % 2 == 0
                    context.fill(Path(CGRect(x: CGFloat(column) * cell, y: CGFloat(row) * cell, width: cell, height: cell)),
                                 with: .color(Color(white: dark ? 0.16 : 0.22)))
                }
            }
        }
    }
}

struct TexturePreview: View {
    @EnvironmentObject var app: AppModel
    let path: String
    var height: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                CheckerBackground()
                if let image = app.image(for: path) {
                    Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo").font(.system(size: 22)).foregroundStyle(Theme.dim)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            Text((path as NSString).lastPathComponent).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            Text(app.textureDescription(path)).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(2)
        }
    }
}

struct InspectorView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var tab = 0

    private func texturePath(for node: OutlineNode, sections: [PropSection]) -> String? {
        let slots = document.textureSlots
        if let slot = slots.first(where: { $0.nodeID == node.id }) { return slot.path }
        for field in sections.flatMap(\.fields) {
            if field.tag == "TxNo", case .int(let index) = field.read(), index >= 0, index < slots.count { return slots[index].path }
            if field.tag == "texture", case .text(let name) = field.read() { return name }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "slider.horizontal.3", title: "Properties") { Spacer() }
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    tabButton(0, "wrench.adjustable", "Properties")
                    tabButton(1, "photo", "Textures")
                    tabButton(2, "info.circle", "Effect Info")
                    Spacer()
                }
                .padding(.top, 6)
                .frame(width: 30)
                .background(Color(white: 0.157))
                ScrollView {
                    VStack(spacing: 6) {
                        if tab == 0 { properties } else if tab == 1 { textures } else { info }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                }
                .background(Theme.panel)
            }
        }
    }

    private func tabButton(_ index: Int, _ symbol: String, _ help: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 12))
            .foregroundStyle(tab == index ? Color.white : Theme.dim)
            .frame(width: 26, height: 24)
            .background(RoundedRectangle(cornerRadius: 4).fill(tab == index ? Theme.panel : Color.clear))
            .contentShape(Rectangle())
            .onTapGesture { tab = index }
            .help(help)
    }

    private func actionButton(_ action: NodeAction) -> some View {
        HStack(spacing: 4) {
            Image(systemName: action.symbol).font(.system(size: 9))
            Text(action.title).font(Theme.font)
        }
        .foregroundStyle(action.destructive ? Color(red: 1, green: 0.5, blue: 0.45) : Theme.text)
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.6)))
        .contentShape(Rectangle())
        .onTapGesture(perform: action.perform)
    }

    @ViewBuilder private var properties: some View {
        if let node = document.selectedNode {
            let sections = document.sections(for: node)
            let curves = document.curveGroups(for: node)
            let missing = document.missingCurves(for: node)
            let missingFields = document.missingFields(for: node)
            HStack(spacing: 6) {
                Image(systemName: node.symbol).foregroundStyle(node.tint.color)
                Text(node.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                Text(node.detail).font(Theme.font).foregroundStyle(Theme.dim).lineLimit(1)
                Spacer()
                if let key = node.visibility {
                    HeaderButton(symbol: document.hidden.contains(key) ? "eye.slash" : "eye", help: "Show or hide in the viewport") {
                        document.toggleHidden(key)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            if !node.actions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) { ForEach(node.actions) { actionButton($0) } }.padding(.horizontal, 8)
                }
            }
            if let path = texturePath(for: node, sections: sections) {
                Panel(title: "Preview") { TexturePreview(path: path) }
            }
            ForEach(sections) { section in
                Panel(title: section.title, trailing: "\(section.fields.count)") {
                    FieldRows(document: document, fields: section.fields, nodeID: node.id)
                }
            }
            if !missingFields.isEmpty {
                addMenu("Add Field", missingFields).padding(.horizontal, 14)
            }
            if !curves.isEmpty || !missing.isEmpty {
                Panel(title: "Animation", trailing: "\(curves.count)") {
                    ForEach(curves) { group in curveRow(group) }
                    if !missing.isEmpty { addMenu("Add Curve", missing) }
                }
            }
            if sections.isEmpty && curves.isEmpty && missing.isEmpty && node.actions.isEmpty {
                Text("This node has no fields of its own. Select one of its children.").font(Theme.font).foregroundStyle(Theme.dim)
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("Nothing selected").font(Theme.font).foregroundStyle(Theme.dim).padding(10)
        }
    }

    private func addMenu(_ title: String, _ items: [MissingCurve]) -> some View {
        Menu {
            ForEach(items) { item in Button(item.title) { item.create() } }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 9, weight: .bold))
                Text(title).font(Theme.font)
                Spacer()
                Text("\(items.count) available").font(Theme.small).foregroundStyle(Theme.dim)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.16)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
    }

    private func curveChanged(_ group: CurveGroup) -> Bool {
        guard let id = document.selectionID, document.changes.contains(id) else { return false }
        return group.channels.contains { channel in document.originalKeys(group: group.id, channel: channel.id, in: id) != channel.read() }
    }

    private func curveRow(_ group: CurveGroup) -> some View {
        let active = document.activeCurveID == group.id
        let keyCount = group.channels.map { $0.read().count }.max() ?? 0
        return HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(group.channels.prefix(4)) { channel in
                    Rectangle().fill(channel.color).frame(width: 3, height: 12)
                }
            }
            .frame(width: 18, alignment: .leading)
            Text(group.title).font(Theme.font).foregroundStyle(curveChanged(group) ? Theme.changed : Theme.text).lineLimit(1)
            if curveChanged(group) { ChangeDot() }
            Spacer(minLength: 4)
            Text("\(keyCount) keys").font(Theme.small).foregroundStyle(Theme.dim)
            if let remove = group.remove {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim)
                    .frame(width: 14, height: 20).contentShape(Rectangle())
                    .onTapGesture(perform: remove).help("Remove this curve from the file")
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.selection : Theme.field.opacity(0.45)))
        .contentShape(Rectangle())
        .onTapGesture {
            document.activeCurveID = group.id
            app.bottomTab = 1
        }
    }

    @ViewBuilder private var textures: some View {
        let slots = document.textureSlots
        if slots.isEmpty {
            Text("This effect has no textures").font(Theme.font).foregroundStyle(Theme.dim).padding(10)
        }
        ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
            Panel(title: "\(index) · \(slot.name)") {
                TexturePreview(path: slot.path, height: 110)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let id = slot.nodeID {
                            document.selectionID = id
                            tab = 0
                        }
                    }
            }
        }
    }

    @ViewBuilder private var info: some View {
        ForEach(Array(document.report.enumerated()), id: \.offset) { _, section in
            Panel(title: section.title) {
                ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(Theme.font).foregroundStyle(Theme.text).frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        Panel(title: "Textures") {
            ForEach(document.textureSlots) { slot in
                HStack(spacing: 6) {
                    Image(systemName: app.textureURL(slot.path) == nil ? "exclamationmark.triangle" : "checkmark.circle").font(.system(size: 10))
                        .foregroundStyle(app.textureURL(slot.path) == nil ? Color.orange : Color.green)
                    Text(slot.path).font(Theme.small).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.head)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}
