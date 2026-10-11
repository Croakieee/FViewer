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
            CheckBox(isOn: value == .bool(true), label: label ?? "") { document.commit(field, from: value, to: .bool($0)) }
        case .choice(let choices):
            ChoiceField(choices: choices, value: Int(value.number)) { document.commit(field, from: value, to: .int($0)) }
        case .text:
            TextValueField(value: { if case .text(let s) = value { return s }; return "" }()) {
                document.commit(field, from: value, to: .text($0))
            }
        case .info:
            Text({ if case .text(let s) = value { return s }; return "\(value.number)" }())
                .font(Theme.font).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
        }
    }
}

struct FieldRows: View {
    @ObservedObject var document: EffectDocument
    let fields: [PropField]

    var body: some View {
        ForEach(FieldRowItem.group(fields)) { item in
            switch item {
            case .single(let field):
                HStack(spacing: 8) {
                    if case .bool = field.kind {
                        Color.clear.frame(width: 110, height: 1)
                        FieldControl(document: document, field: field, label: field.label)
                    } else {
                        Text(field.label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                            .frame(width: 110, alignment: .trailing).help("\(field.label) [\(field.tag)]")
                        FieldControl(document: document, field: field)
                    }
                }
            case .vector(let prefix, let parts):
                HStack(alignment: .top, spacing: 8) {
                    Text(prefix).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                        .frame(width: 110, height: 20, alignment: .trailing)
                    VStack(spacing: 1) {
                        ForEach(Array(parts.enumerated()), id: \.element.id) { index, field in
                            FieldControl(document: document, field: field, label: String(field.label.suffix(1)), roundTop: index == 0,
                                         roundBottom: index == parts.count - 1)
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
                    tabButton(0, "wrench.adjustable", "Свойства")
                    tabButton(1, "photo", "Текстуры")
                    Spacer()
                }
                .padding(.top, 6)
                .frame(width: 30)
                .background(Color(white: 0.157))
                ScrollView {
                    VStack(spacing: 6) {
                        if tab == 0 { properties } else { textures }
                    }
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

    @ViewBuilder private var properties: some View {
        if let node = document.selectedNode {
            let sections = document.sections(for: node)
            let curves = document.curveGroups(for: node)
            HStack(spacing: 6) {
                Image(systemName: node.symbol).foregroundStyle(node.tint.color)
                Text(node.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                Text(node.detail).font(Theme.font).foregroundStyle(Theme.dim).lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            if let path = texturePath(for: node, sections: sections) {
                Panel(title: "Preview") { TexturePreview(path: path) }
            }
            ForEach(sections) { section in
                Panel(title: section.title, trailing: "\(section.fields.count)") {
                    FieldRows(document: document, fields: section.fields)
                }
            }
            if !curves.isEmpty {
                Panel(title: "Animation", trailing: "\(curves.count)") {
                    ForEach(curves) { group in curveRow(group) }
                }
            }
            if sections.isEmpty && curves.isEmpty {
                Text("У этого узла нет собственных полей — выберите вложенный элемент.").font(Theme.font).foregroundStyle(Theme.dim)
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("Ничего не выбрано").font(Theme.font).foregroundStyle(Theme.dim).padding(10)
        }
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
            Text(group.title).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            Spacer(minLength: 4)
            Text("\(keyCount) кл.").font(Theme.small).foregroundStyle(Theme.dim)
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath").font(.system(size: 9)).foregroundStyle(Theme.dim)
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
            Text("В эффекте нет текстур").font(Theme.font).foregroundStyle(Theme.dim).padding(10)
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
}
