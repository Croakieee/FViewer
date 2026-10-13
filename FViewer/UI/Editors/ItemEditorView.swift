import Combine
import SwiftUI

struct ItemEditorView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        Group {
            if let document = app.document, let id = app.itemEditorTarget, document.node(id) != nil {
                ItemEditor(document: document, rootID: id)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.below.rectangle").font(.system(size: 26)).foregroundStyle(Theme.dim)
                    HelpBadge(text: "Double-click a scheduler, timeline, emitter, particle, effector or binder in the Outliner to edit it here.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 980, minHeight: 560)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}

private struct EditorPage: Identifiable {
    let node: OutlineNode
    let depth: Int
    var id: String { node.id }
}

struct ItemEditor: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let rootID: String
    var docked = false
    @State private var collapsed: Set<String> = []
    @State private var curveFraction: CGFloat = 0.38
    @State private var previewWidth: CGFloat = 430
    @State private var showPreview = true
    @State private var showCurves = true

    private var root: OutlineNode? { document.node(rootID) }

    private var pages: [EditorPage] {
        guard let root else { return [] }
        var result: [EditorPage] = []
        func visit(_ node: OutlineNode, _ depth: Int) {
            result.append(EditorPage(node: node, depth: depth))
            if collapsed.contains(node.id) { return }
            node.children.forEach { visit($0, depth + 1) }
        }
        visit(root, 0)
        return result
    }

    private var pageID: String {
        if let selected = document.selectionID, selected == rootID || selected.hasPrefix(rootID + "/"), document.node(selected) != nil { return selected }
        return rootID
    }

    private var kindTitle: String {
        let kind = EffectDocument.linkKind(rootID)
        return kind == "Node" ? "Editor" : kind + " Editor"
    }

    private var siblings: [OutlineNode] {
        var result: [OutlineNode] = []
        func visit(_ node: OutlineNode) {
            if AppModel.itemEditorRoot(node.id) == node.id {
                result.append(node)
            } else {
                node.children.forEach(visit)
            }
        }
        document.outline.forEach(visit)
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            GeometryReader { geometry in
                let size = geometry.size
                let side = min(max(size.width * 0.19, 190), 260)
                let preview = showPreview && !docked ? min(max(previewWidth, 360), max(360, size.width - side - 420)) : 0
                HStack(spacing: 0) {
                    sidebar.frame(width: side)
                    Rectangle().fill(Color.black.opacity(0.5)).frame(width: 1)
                    center(height: size.height).frame(maxWidth: .infinity)
                    if showPreview && !docked {
                        AreaDivider(vertical: true) { x in previewWidth = geometry.frame(in: .global).maxX - x }
                        ViewportPanel(document: document).frame(width: preview)
                    }
                }
            }
        }
        .onAppear {
            if document.selectionID.map({ $0 == rootID || $0.hasPrefix(rootID + "/") }) != true { document.selectionID = rootID }
            if rootID.hasPrefix("avfx/Emit/"), !docked { app.showEmitters = true }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: root?.symbol ?? "square").foregroundStyle(root?.tint.color ?? Theme.text)
            Text(kindTitle).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
            Menu {
                ForEach(siblings) { node in
                    Button {
                        app.itemEditorTarget = node.id
                        document.selectionID = node.id
                    } label: {
                        if node.id == rootID { Label(node.title, systemImage: "checkmark") } else { Text(node.title) }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(root?.title ?? "").font(Theme.font).lineLimit(1)
                    Text(root?.detail ?? "").font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                    Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
                }
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 8)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            if document.changes.contains(rootID) { ChangeDot() }
            Spacer(minLength: 8)
            if let root {
                HeaderButton(symbol: "doc.on.doc", help: "Copy the parameters and curves of this item") { ParameterClipboard.copy(root, in: document) }
                HeaderButton(symbol: "doc.on.clipboard", help: "Paste the copied parameters into this item, matching fields by name") {
                    ParameterClipboard.paste(into: root, in: document)
                }
                if let key = root.visibility {
                    HeaderButton(symbol: document.hidden.contains(key) ? "eye.slash" : "eye", help: "Show or hide in the viewport") { document.toggleHidden(key) }
                }
            }
            HeaderButton(symbol: "scope", active: document.isolateSelection, help: "Play only this item in the preview") { document.isolateSelection.toggle() }
            HeaderButton(symbol: "point.topleft.down.to.point.bottomright.curvepath", active: showCurves, help: "Show the curve editor") { showCurves.toggle() }
            if !docked { HeaderButton(symbol: "play.rectangle", active: showPreview, help: "Show the preview") { showPreview.toggle() } }
            HeaderButton(symbol: "arrow.uturn.backward", help: "Undo") { document.undo() }
            HeaderButton(symbol: "arrow.uturn.forward", help: "Redo") { document.redo() }
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Theme.gray(0.157))
    }

    private var sidebar: some View {
        let changes = document.changes
        let current = pageID
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(pages) { page in pageRow(page, selected: page.id == current, changes: changes) }
            }
            .padding(.vertical, 4)
        }
        .background(Theme.gray(0.157))
    }

    private func pageRow(_ page: EditorPage, selected: Bool, changes: ChangeSet) -> some View {
        let node = page.node
        return HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(page.depth) * 12)
            Group {
                if node.children.isEmpty || page.depth == 0 {
                    Color.clear
                } else {
                    Image(systemName: collapsed.contains(node.id) ? "chevron.right" : "chevron.down").font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Theme.dim).contentShape(Rectangle().inset(by: -5))
                        .onTapGesture { if collapsed.contains(node.id) { collapsed.remove(node.id) } else { collapsed.insert(node.id) } }
                }
            }
            .frame(width: 10)
            Image(systemName: node.symbol).font(.system(size: 10)).foregroundStyle(node.tint.color).frame(width: 16)
            Text(page.depth == 0 ? "Parameters" : node.title).font(Theme.font).foregroundStyle(selected ? .white : Theme.text).lineLimit(1)
            if changes.contains(node.id) { ChangeDot(added: changes.added.contains(node.id)) }
            Spacer(minLength: 4)
            Text(page.depth == 0 ? "" : node.detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(height: 22)
        .background(selected ? Theme.selection : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = node.id }
        .contextMenu {
            ForEach(node.actions) { action in Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform) }
        }
    }

    @ViewBuilder private func center(height: CGFloat) -> some View {
        if let node = document.node(pageID) {
            let hasCurves = !document.curveGroups(for: node).isEmpty
            let curves = showCurves && hasCurves ? min(max(height * curveFraction, 180), height - 160) : 0
            let timed = !hasCurves && showCurves && (rootID.hasPrefix("avfx/TmLn/") || rootID.hasPrefix("avfx/Schd") || rootID.hasPrefix("json/timelines/"))
            VStack(spacing: 0) {
                ItemPage(document: document, node: node).id(node.id).frame(maxHeight: .infinity)
                if timed {
                    AreaDivider(vertical: false) { _ in }
                    SequencerView(document: document, clock: document.clock).frame(height: min(max(height * 0.36, 170), height - 160))
                }
                if curves > 0 {
                    AreaDivider(vertical: false) { _ in }
                    CurveEditorView(document: document, clock: document.clock).frame(height: curves)
                }
            }
        } else {
            Color.clear
        }
    }
}

private struct ItemPage: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let node: OutlineNode
    @State private var search = ""
    @State private var changedOnly = false
    @FocusState private var searching: Bool

    private func filtered(_ sections: [PropSection]) -> [PropSection] {
        let needle = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty || changedOnly else { return sections }
        return sections.compactMap { section in
            var copy = section
            copy.fields = section.fields.filter { field in
                (needle.isEmpty || field.label.lowercased().contains(needle) || field.tag.lowercased().contains(needle))
                    && (!changedOnly || document.isChanged(field, in: node.id))
            }
            return copy.fields.isEmpty ? nil : copy
        }
    }

    private func resetPage() {
        let before = document.snapshot()
        var changed = false
        for field in document.sections(for: node).flatMap(\.fields) where document.isChanged(field, in: node.id) {
            guard let write = field.write, let original = document.originalValue(of: field, in: node.id) else { continue }
            write(original)
            changed = true
        }
        if changed { document.registerUndo("Reset Page", since: before) }
    }

    private var changedCount: Int { document.sections(for: node).flatMap(\.fields).filter { document.isChanged($0, in: node.id) }.count }

    private var isList: Bool {
        guard case .group = node.payload, !node.children.isEmpty else { return false }
        return node.children.allSatisfy { child in
            if case .avfx(_, _, let record) = child.payload { return record != nil }
            return false
        }
    }

    private func texturePath(_ sections: [PropSection]) -> String? {
        let slots = document.textureSlots
        for field in sections.flatMap(\.fields) {
            if field.tag == "TxNo" || field.tag.hasPrefix("TLst") || field.label.hasPrefix("Mask Texture"), case .int(let index) = field.read(), index >= 0,
               index < slots.count {
                return slots[index].path
            }
            if field.tag == "texture", case .text(let name) = field.read() { return name }
        }
        return nil
    }

    private func columns(_ sections: [PropSection], count: Int) -> [[PropSection]] {
        var result = [[PropSection]](repeating: [], count: max(count, 1))
        var loads = [Int](repeating: 0, count: max(count, 1))
        for section in sections {
            let target = loads.indices.min { loads[$0] < loads[$1] } ?? 0
            result[target].append(section)
            loads[target] += section.fields.count + 2
        }
        return result
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    titleRow
                    if !node.actions.isEmpty {
                        FlowLayout(spacing: 4) { ForEach(node.actions) { actionButton($0) } }
                            .padding(.horizontal, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if isList {
                        RecordTable(document: document, group: node)
                    } else {
                        form(width: geometry.size.width)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Theme.panel)
    }

    private var titleRow: some View {
        HStack(spacing: 6) {
            Image(systemName: node.symbol).foregroundStyle(node.tint.color)
            Text(node.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
            Text(node.detail).font(Theme.font).foregroundStyle(Theme.dim).lineLimit(1)
            Spacer(minLength: 8)
            if !isList {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $search).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text).focused($searching)
                    if !search.isEmpty {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 9)).foregroundStyle(Theme.dim).onTapGesture { search = "" }
                    }
                }
                .padding(.horizontal, 6)
                .frame(width: 150, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
                .help("Filter parameters by name or tag")
                HeaderButton(symbol: "circle.lefthalf.filled", active: changedOnly, help: "Show only parameters changed since the file was opened") {
                    changedOnly.toggle()
                }
                presetMenu
                if changedCount > 0 {
                    HeaderButton(symbol: "arrow.counterclockwise", help: "Reset the \(changedCount) changed parameters of this page to the opened file") { resetPage() }
                }
            }
        }
        .padding(.horizontal, 10)
    }

    private var presetMenu: some View {
        let presets = ParameterClipboard.presets(for: node)
        return Menu {
            Button("Save Page as Preset…") {
                guard let name = app.prompt("Save Preset", placeholder: "Name", value: node.title) else { return }
                if ParameterClipboard.savePreset(name, from: node, in: document) != nil { app.notice = "Preset \(name) saved" }
            }
            if !presets.isEmpty { Divider() }
            ForEach(presets, id: \.url) { preset in
                Button(preset.name) {
                    let changed = ParameterClipboard.applyPreset(preset.url, to: node, in: document)
                    app.notice = changed ? "Preset \(preset.name) applied" : "Preset \(preset.name) matches this page already"
                }
            }
            if !presets.isEmpty {
                Divider()
                Menu("Delete Preset") {
                    ForEach(presets, id: \.url) { preset in
                        Button(preset.name, role: .destructive) {
                            try? FileManager.default.trashItem(at: preset.url, resultingItemURL: nil)
                            app.objectWillChange.send()
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "square.stack.3d.down.right").font(.system(size: 11)).foregroundStyle(Theme.text).frame(width: 24, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Presets: save the parameters and curves of this page, or apply a saved set")
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

    @ViewBuilder private func form(width: CGFloat) -> some View {
        let sections = filtered(document.sections(for: node))
        let curves = document.curveGroups(for: node)
        let missingCurves = document.missingCurves(for: node)
        let missingFields = document.missingFields(for: node)
        let count = max(1, min(3, Int(width / 340)))
        let split = columns(sections, count: count)
        if search.isEmpty && !changedOnly {
            VStack(spacing: 6) { ItemTools(document: document, node: node) }
                .frame(maxWidth: min(width, 760), alignment: .leading)
        }
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(split.enumerated()), id: \.offset) { index, list in
                VStack(spacing: 6) {
                    if index == 0 { previews(sections) }
                    ForEach(list) { section in
                        Panel(title: section.title, trailing: "\(section.fields.count)") {
                            FieldRows(document: document, fields: section.fields, nodeID: node.id)
                        }
                    }
                    if index == split.count - 1 {
                        if !missingFields.isEmpty {
                            Panel(title: "Not Set", trailing: "\(missingFields.count)") { UnsetRows(items: missingFields) }
                        }
                        if !curves.isEmpty || !missingCurves.isEmpty {
                            Panel(title: "Animation", trailing: "\(curves.count) of \(curves.count + missingCurves.count)") {
                                ForEach(curves) { group in
                        curveRow(group)
                        if ConstantCurveFields.applies(group) { ConstantCurveFields(document: document, group: group) }
                    }
                                if !missingCurves.isEmpty { UnsetRows(items: missingCurves) }
                            }
                        }
                        if !node.children.isEmpty {
                            Panel(title: "Contents", trailing: "\(node.children.count)") {
                                ForEach(node.children) { child in contentRow(child) }
                            }
                        }
                    }
                }
                .frame(width: width / CGFloat(split.count))
            }
        }
        .environment(\.labelWidth, min(max(width / CGFloat(split.count) * 0.4, 110), 190))
    }

    @ViewBuilder private func previews(_ sections: [PropSection]) -> some View {
        if let path = texturePath(sections) {
            Panel(title: "Texture") { TexturePreview(path: path, height: 130) }
        }
        if case .avfx(let block, _, let record) = node.payload, record == nil, block.tag == "UvSt" {
            Panel(title: "UV Preview") { UvSetPreview(document: document, clock: document.clock, uvSet: block) }
        }
    }

    private func curveRow(_ group: CurveGroup) -> some View {
        let active = document.activeCurveID == group.id
        let keyCount = group.channels.map { $0.read().count }.max() ?? 0
        let changed = document.changes.contains(node.id)
            && group.channels.contains { document.originalKeys(group: group.id, channel: $0.id, in: node.id) != $0.read() }
        return HStack(spacing: 6) {
            HStack(spacing: 1) {
                ForEach(group.channels.prefix(4)) { channel in Rectangle().fill(channel.color).frame(width: 3, height: 12) }
            }
            .frame(width: 18, alignment: .leading)
            Text(group.title).font(Theme.font).foregroundStyle(changed ? Theme.changed : Theme.text).lineLimit(1)
            if changed { ChangeDot() }
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
        .onTapGesture { document.activeCurveID = group.id }
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
    }
}

private struct RecordTable: View {
    @ObservedObject var document: EffectDocument
    let group: OutlineNode

    private func width(_ field: PropField) -> CGFloat {
        switch field.kind {
        case .bool: return 78
        case .choice: return 150
        case .text: return 170
        case .color: return 120
        case .info: return 110
        default: return 92
        }
    }

    private func action(_ node: OutlineNode, _ suffix: String) -> NodeAction? { node.actions.first { $0.id.hasSuffix(suffix) } }

    var body: some View {
        let rows = group.children.map { (node: $0, fields: document.sections(for: $0).flatMap(\.fields)) }
        let columns = rows.first?.fields ?? []
        let changes = document.changes
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("#").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 30, alignment: .leading)
                    if group.id.hasSuffix("/Trgr") { Color.clear.frame(width: 24) }
                    ForEach(columns) { field in
                        Text(field.label).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(2).minimumScaleFactor(0.85)
                            .multilineTextAlignment(.leading)
                            .frame(width: width(field), height: 26, alignment: .bottomLeading).help("\(field.label) [\(field.tag)]")
                    }
                    Color.clear.frame(width: 104)
                }
                .frame(height: 28)
                ForEach(Array(rows.enumerated()), id: \.element.node.id) { index, row in
                    HStack(spacing: 4) {
                        HStack(spacing: 3) {
                            Text("\(index)").font(Theme.font).foregroundStyle(document.selectionID == row.node.id ? .white : Theme.text)
                            if changes.contains(row.node.id) { ChangeDot(added: changes.added.contains(row.node.id)) }
                        }
                        .frame(width: 30, alignment: .leading)
                        if group.id.hasSuffix("/Trgr") {
                            HeaderButton(symbol: "bolt.fill", help: "Fire trigger \(index) in the preview now") {
                                document.clock.playing = true
                                document.clock.trigger(index)
                            }
                        }
                        ForEach(row.fields) { field in
                            cell(field).frame(width: width(field), alignment: .leading)
                        }
                        HStack(spacing: 2) {
                            if let item = action(row.node, "!dup") { HeaderButton(symbol: "plus.square.on.square", help: "Duplicate", action: item.perform) }
                            if let item = action(row.node, "!up") { HeaderButton(symbol: "arrow.up", help: "Move Up", action: item.perform) }
                            if let item = action(row.node, "!down") { HeaderButton(symbol: "arrow.down", help: "Move Down", action: item.perform) }
                            if let item = action(row.node, "!del") { HeaderButton(symbol: "trash", help: "Delete", action: item.perform) }
                        }
                        .frame(width: 104, alignment: .trailing)
                    }
                    .padding(.vertical, 1)
                    .background(index % 2 == 1 ? Color.white.opacity(0.03) : Color.clear)
                }
            }
            .padding(.horizontal, 10)
        }
    }

    @ViewBuilder private func cell(_ field: PropField) -> some View {
        if case .bool = field.kind {
            FieldControl(document: document, field: field, label: "")
        } else {
            FieldControl(document: document, field: field)
        }
    }
}

struct DockedItemEditor: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State private var lastRoot: String?

    var body: some View {
        let root = document.selectionID.flatMap { AppModel.itemEditorRoot($0) }.flatMap { document.node($0) != nil ? $0 : nil }
            ?? lastRoot.flatMap { document.node($0) != nil ? $0 : nil }
        Group {
            if let root {
                ItemEditor(document: document, rootID: root, docked: true).id(root)
            } else {
                HelpBadge(text: "Select a scheduler, timeline, emitter, particle, effector or binder to edit it here.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.panel)
        .onChange(of: root, initial: true) { _, now in if let now { lastRoot = now } }
    }
}
