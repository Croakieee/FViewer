import Combine
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
        if field.write != nil, !document.siblingNodes(of: nodeID).isEmpty {
            Button("Apply to All \(EffectDocument.linkKind(nodeID))s") {
                let count = document.applyToSiblings(field, in: nodeID)
                AppDelegate.model?.notice = count == 0 ? "Every other \(EffectDocument.linkKind(nodeID).lowercased()) already has this value"
                    : "\(field.label) set on \(count) more"
            }
        }
        if let unassign = field.unassign { Button("Remove from File", role: .destructive, action: unassign) }
    }

    private func label(_ text: String, _ field: PropField?) -> some View {
        let isChanged = field.map(changed) ?? false
        let before = isChanged ? field.flatMap { document.originalValue(of: $0, in: nodeID) } : nil
        var help = field.map { "\($0.label) [\($0.tag)]" } ?? text
        if field?.tag == "SdNo" { help += " · -1 if no sound" }
        if isChanged { help += " · was " + (before.map(document.describe) ?? "not in the file") }
        return HStack(spacing: 4) {
            Spacer(minLength: 0)
            if isChanged { ChangeDot(added: before == nil) }
            Text(text).font(Theme.font).foregroundStyle(isChanged ? Theme.changed : Theme.text).lineLimit(1).minimumScaleFactor(0.75)
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
    @State private var mip = 0

    private var mipImage: (image: CGImage, levels: Int, size: String)? {
        guard let url = app.textureURL(path), url.pathExtension.lowercased() != "png", let data = try? Data(contentsOf: url),
              let decoded = try? Atex.decode([UInt8](data), mip: mip), let image = decoded.makeImage() else { return nil }
        return (image, decoded.mipLevels, "\(decoded.width)×\(decoded.height)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack {
                CheckerBackground()
                if mip > 0, let shown = mipImage {
                    Image(decorative: shown.image, scale: 1).resizable().interpolation(.none).aspectRatio(contentMode: .fit)
                } else if let image = app.image(for: path) {
                    Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo").font(.system(size: 22)).foregroundStyle(Theme.dim)
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            if let levels = app.decodedTexture(for: path)?.mipLevels, levels > 1 {
                HStack(spacing: 4) {
                    Text("Mip").font(Theme.small).foregroundStyle(Theme.dim)
                    ForEach(0..<min(levels, 10), id: \.self) { level in
                        Text("\(level)").font(Theme.small).foregroundStyle(mip == level ? .white : Theme.text)
                            .frame(width: 18, height: 16)
                            .background(RoundedRectangle(cornerRadius: 3).fill(mip == level ? Theme.accent : Theme.field.opacity(0.5)))
                            .contentShape(Rectangle())
                            .onTapGesture { mip = level }
                    }
                    Spacer(minLength: 0)
                    if mip > 0, let shown = mipImage { Text(shown.size).font(Theme.small).foregroundStyle(Theme.dim) }
                }
            }
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
                    tabButton(3, "clock.arrow.circlepath", "Undo History")
                    Spacer()
                }
                .padding(.top, 6)
                .frame(width: 30)
                .background(Theme.gray(0.157))
                ScrollView {
                    VStack(spacing: 6) {
                        if tab == 0 { properties } else if tab == 1 { textures } else if tab == 2 { info } else { history }
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

    private func contentRow(_ child: OutlineNode) -> some View {
        let changes = document.changes
        return HStack(spacing: 6) {
            Image(systemName: child.symbol).font(.system(size: 10)).foregroundStyle(child.tint.color).frame(width: 16)
            Text(child.title).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            if changes.contains(child.id) { ChangeDot(added: changes.added.contains(child.id)) }
            Spacer(minLength: 4)
            Text(child.detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.45)))
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = child.id }
        .contextMenu {
            ForEach(child.actions) { action in Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform) }
        }
    }

    private func actionButton(_ action: NodeAction) -> some View {
        HStack(spacing: 4) {
            Image(systemName: action.symbol).font(.system(size: 9))
            Text(action.title).font(Theme.font)
        }
        .foregroundStyle(action.destructive ? Color(red: 1, green: 0.5, blue: 0.45) : Theme.text)
        .lineLimit(1)
        .fixedSize()
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
                if app.canOpenEditor(node.id) {
                    HeaderButton(symbol: "macwindow", help: "Open the full editor of this item in a separate window") { app.openEditor(for: node.id) }
                }
                HeaderButton(symbol: "doc.on.doc", help: "Copy the parameters and curves of this node") { ParameterClipboard.copy(node, in: document) }
                HeaderButton(symbol: "doc.on.clipboard", help: "Paste the copied parameters into this node, matching fields by name") {
                    ParameterClipboard.paste(into: node, in: document)
                }
                if let key = node.visibility {
                    HeaderButton(symbol: document.hidden.contains(key) ? "eye.slash" : "eye", help: "Show or hide in the viewport") {
                        document.toggleHidden(key)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            if !node.actions.isEmpty {
                FlowLayout(spacing: 4) { ForEach(node.actions) { actionButton($0) } }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let path = texturePath(for: node, sections: sections) {
                Panel(title: "Preview") {
                    TexturePreview(path: path)
                    if case .avfx(let block, _, _) = node.payload, block.tag == "Tex", block.children == nil {
                        FlowLayout(spacing: 2) {
                            ForEach(AppModel.TextureOperation.allCases, id: \.self) { operation in
                                HeaderButton(symbol: operation.symbol, help: operation.rawValue) { app.transformTexture(block, operation) }
                            }
                            HelpBadge(text: "Each operation writes a new texture file next to the effect and points this slot at it. The original file is not changed.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if case .avfx(let block, _, let record) = node.payload, record == nil, block.tag == "UvSt" {
                Panel(title: "UV Preview") { UvSetPreview(document: document, clock: document.clock, uvSet: block) }
            }
            ForEach(sections) { section in
                Panel(title: section.title, trailing: "\(section.fields.count)") {
                    FieldRows(document: document, fields: section.fields, nodeID: node.id)
                }
            }
            if !missingFields.isEmpty {
                Panel(title: "Not Set", trailing: "\(missingFields.count)") { UnsetRows(items: missingFields) }
            }
            if !curves.isEmpty || !missing.isEmpty {
                Panel(title: "Animation", trailing: "\(curves.count) of \(curves.count + missing.count)") {
                    ForEach(curves) { group in curveRow(group) }
                    if !missing.isEmpty { UnsetRows(items: missing) }
                }
            }
            if !node.children.isEmpty {
                Panel(title: "Contents", trailing: "\(node.children.count)") {
                    ForEach(node.children) { child in contentRow(child) }
                }
            }
            if let text = document.jsonText(of: node) {
                JSONTextPanel(document: document, node: node, original: text).id(node.id + "#\(document.revision)")
            }
        }
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
        if document.format == .avfx {
            Panel(title: "Import Settings") {
                HStack(spacing: 8) {
                    Text("Format").font(Theme.font).foregroundStyle(Theme.text).frame(width: 60, alignment: .trailing)
                    ChoiceField(choices: TextureCodec.importFormats.map { FieldChoice(name: $0.name, value: Int($0.format.rawValue)) },
                                value: Int(app.importFormat.rawValue)) { value in
                        UserDefaults.standard.set(value, forKey: "texture.format")
                        app.objectWillChange.send()
                    }
                }
                HStack(spacing: 8) {
                    Text("Mips").font(Theme.font).foregroundStyle(Theme.text).frame(width: 60, alignment: .trailing)
                    NumberField(label: nil, value: Double(app.importMips), isInteger: true,
                                onLive: { _ in },
                                onCommit: { _, next in
                                    UserDefaults.standard.set(Int(min(max(next, 1), 13)), forKey: "texture.mips")
                                    app.objectWillChange.send()
                                })
                    HelpBadge(text: "Used when an image (PNG, JPEG, TIFF) is imported or a texture is transformed. DDS, .atex and .tex files keep their own format.")
                }
                HStack(spacing: 8) {
                    Text("Prefix").font(Theme.font).foregroundStyle(Theme.text).frame(width: 60, alignment: .trailing)
                    TextValueField(value: app.customPrefix) { value in
                        UserDefaults.standard.set(value, forKey: "texture.prefix")
                        app.objectWillChange.send()
                    }
                    HelpBadge(text: "Folder for custom texture paths. Edit → Convert Textures to Custom Paths moves every texture path of the effect under it, so the mod does not replace textures other effects use.")
                }
            }
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
                if let id = slot.nodeID, case .avfx(let block, _, _)? = document.node(id)?.payload,
                   case .avfx(let before, _, _)? = document.original?.node(id)?.payload, before.stringValue != block.stringValue {
                    HStack(spacing: 6) {
                        ChangeDot()
                        Text("Replaced").font(Theme.font).foregroundStyle(Theme.changed)
                        Spacer()
                        SegmentButton(title: "Reset", active: false) {
                            let current = block.stringValue, old = before.stringValue
                            document.perform("Reset Texture", { block.stringValue = old }, revert: { block.stringValue = current })
                        }
                        .help(before.stringValue)
                    }
                }
                if app.textureURL(slot.path) == nil, let id = slot.nodeID, case .avfx(let block, _, _)? = document.node(id)?.payload {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle").font(.system(size: 10)).foregroundStyle(Color.orange)
                        Text("Missing").font(Theme.font).foregroundStyle(Color.orange)
                        Spacer()
                        SegmentButton(title: "Locate…", active: false) { app.replaceTexture(block) }
                    }
                }
            }
        }
    }

    @ViewBuilder private var history: some View {
        let done = document.undoTitles, undone = document.redoTitles
        Panel(title: "Undo History", trailing: "\(done.count)") {
            historyRow("Opened File", active: done.isEmpty, dim: false) { document.jumpHistory(to: 0) }
            ForEach(Array(done.enumerated()), id: \.offset) { index, title in
                historyRow(title, active: index == done.count - 1, dim: false) { document.jumpHistory(to: index + 1) }
            }
            ForEach(Array(undone.reversed().enumerated()), id: \.offset) { index, title in
                historyRow(title, active: false, dim: true) { document.jumpHistory(to: done.count + index + 1) }
            }
        }
    }

    private func pathRow(_ label: String, _ value: String, _ change: @escaping (String) -> Void) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 78, alignment: .trailing)
            TextValueField(value: value, action: change)
            Menu {
                ForEach(app.recentGamePaths, id: \.self) { path in Button(path) { change(path) } }
            } label: {
                Image(systemName: "clock").font(.system(size: 10)).foregroundStyle(Theme.text).frame(width: 22, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .disabled(app.recentGamePaths.isEmpty)
        }
    }

    private func historyRow(_ title: String, active: Bool, dim: Bool, _ action: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Image(systemName: active ? "arrowtriangle.right.fill" : "circle.fill").font(.system(size: active ? 7 : 3)).foregroundStyle(active ? Theme.accent : Theme.dim)
                .frame(width: 12)
            Text(title).font(Theme.font).foregroundStyle(dim ? Theme.dim : Theme.text).lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(RoundedRectangle(cornerRadius: 4).fill(active ? Theme.selection : Theme.field.opacity(0.3)))
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }

    @ViewBuilder private var info: some View {
        if document.format == .avfx {
            Panel(title: "Game Paths") {
                pathRow("Loaded from", document.sourcePath) { document.sourcePath = PenumbraExport.normalized($0) }
                pathRow("Replaces", document.gamePath) {
                    document.gamePath = PenumbraExport.normalized($0)
                    app.rememberGamePath($0)
                }
                FlowLayout(spacing: 4) {
                    SegmentButton(title: "Guess Path", active: false) {
                        if let path = app.guessGamePath(for: document) {
                            document.gamePath = path
                            app.rememberGamePath(path)
                        } else {
                            app.notice = "No file with this name was found under a game folder"
                        }
                    }
                    SegmentButton(title: "Find Timelines Using It…", active: false) { app.findTimelines(using: document) }
                    HelpBadge(text: "Guess Path looks for a file with the same name and size under a vfx folder of the open library. Find Timelines searches a folder of .tmb and .pap files for this effect's name.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        ForEach(Array(document.report.enumerated()), id: \.offset) { _, section in
            Panel(title: section.title) {
                ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                    Text(line).font(Theme.font).foregroundStyle(Theme.text).frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        ClipLogPanel(clock: document.clock)
        if let root = document.avfxRoot {
            Panel(title: "Raw Blocks") { RawBlockRow(block: root, depth: 0) }
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

struct ClipLogPanel: View {
    @ObservedObject var clock: PlaybackClock

    var body: some View {
        if !clock.clipLog.isEmpty {
            Panel(title: "Clip Log", trailing: "\(clock.clipLog.count)") {
                ForEach(Array(clock.clipLog.suffix(40).enumerated()), id: \.offset) { _, line in
                    Text(line).font(Theme.font).foregroundStyle(Theme.text).frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct RawBlockRow: View {
    let block: AvfxBlock
    let depth: Int
    @State private var open = false

    private var summary: String {
        if let children = block.children { return "\(children.count) blocks" }
        let data = block.data
        if data.count == 4 {
            let raw = data.u32(0)
            let float = Float(bitPattern: raw)
            let number = abs(float) > 1e-4 && abs(float) < 1e7 ? String(format: "  %.4g", float) : ""
            return "\(Int32(bitPattern: raw))" + number
        }
        if data.count == 1 { return "\(data[0])" }
        return "\(data.count) bytes  " + data.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    var body: some View {
        let children = block.children ?? []
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Color.clear.frame(width: CGFloat(min(depth, 12)) * 10)
                Image(systemName: children.isEmpty ? "circle.fill" : open ? "chevron.down" : "chevron.right")
                    .font(.system(size: children.isEmpty ? 3 : 7, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 10)
                Text(block.tag).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.text).lineLimit(1)
                Spacer(minLength: 4)
                Text(summary).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1).truncationMode(.tail)
            }
            .frame(height: 18)
            .contentShape(Rectangle())
            .onTapGesture { if !children.isEmpty { open.toggle() } }
            if open {
                ForEach(Array(children.prefix(400).enumerated()), id: \.offset) { _, child in RawBlockRow(block: child, depth: depth + 1) }
            }
        }
    }
}

struct JSONTextPanel: View {
    @ObservedObject var document: EffectDocument
    let node: OutlineNode
    let original: String
    @State private var text = ""
    @State private var problem: String?

    var body: some View {
        Panel(title: "JSON") {
            TextEditor(text: $text)
                .font(.system(size: 11, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundStyle(Theme.text)
                .frame(minHeight: 140, maxHeight: 320)
                .padding(4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            HStack(spacing: 6) {
                if let problem { Text(problem).font(Theme.small).foregroundStyle(Color.orange).lineLimit(2) }
                Spacer(minLength: 0)
                SegmentButton(title: "Revert", active: false) {
                    text = original
                    problem = nil
                }
                SegmentButton(title: "Apply", active: text != original) {
                    do {
                        try document.applyJSON(text, to: node)
                        problem = nil
                    } catch {
                        problem = "\(error)"
                    }
                }
            }
        }
        .onAppear { text = original }
    }
}
