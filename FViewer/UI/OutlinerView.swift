import SwiftUI

private struct FlatRow: Identifiable {
    let node: OutlineNode
    let depth: Int
    var id: String { node.id }
}

struct OutlinerView: View {
    @ObservedObject var document: EffectDocument
    @State private var collapsed: Set<String> = []
    @State private var filter = ""

    private var rows: [FlatRow] {
        var result: [FlatRow] = []
        let needle = filter.lowercased()
        func matches(_ node: OutlineNode) -> Bool {
            node.title.lowercased().contains(needle) || node.detail.lowercased().contains(needle) || node.children.contains(where: matches)
        }
        func visit(_ node: OutlineNode, _ depth: Int) {
            if !needle.isEmpty && !matches(node) { return }
            result.append(FlatRow(node: node, depth: depth))
            if needle.isEmpty && collapsed.contains(node.id) { return }
            node.children.forEach { visit($0, depth + 1) }
        }
        document.outline.forEach { visit($0, 0) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "list.bullet.indent", title: "Outliner") {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                            rowView(row, striped: index % 2 == 1).id(row.id)
                        }
                    }
                }
                .onAppear { collapseTriggers() }
                .onChange(of: document.id) { _, _ in collapseTriggers() }
                .onChange(of: document.selectionID) { _, id in
                    if let id { withAnimation(.none) { proxy.scrollTo(id) } }
                }
            }
            .background(Color(white: 0.157))
        }
    }

    private func collapseTriggers() {
        func visit(_ node: OutlineNode) {
            if node.id.hasSuffix("/Trgr") { collapsed.insert(node.id) }
            node.children.forEach(visit)
        }
        document.outline.forEach(visit)
    }

    private func rowView(_ row: FlatRow, striped: Bool) -> some View {
        let node = row.node
        let selected = document.selectionID == node.id
        return HStack(spacing: 4) {
            Color.clear.frame(width: CGFloat(row.depth) * 14)
            Group {
                if node.children.isEmpty {
                    Color.clear
                } else {
                    Image(systemName: collapsed.contains(node.id) ? "chevron.right" : "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Theme.dim)
                        .contentShape(Rectangle().inset(by: -5))
                        .onTapGesture {
                            if collapsed.contains(node.id) { collapsed.remove(node.id) } else { collapsed.insert(node.id) }
                        }
                }
            }
            .frame(width: 10)
            Image(systemName: node.symbol).font(.system(size: 10)).foregroundStyle(node.tint.color).frame(width: 16)
            Text(node.title).font(Theme.font).foregroundStyle(selected ? .white : Theme.text).lineLimit(1)
            Spacer(minLength: 4)
            Text(node.detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(selected ? Theme.selection : striped ? Color.white.opacity(0.025) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = node.id }
    }
}

struct LibraryView: View {
    @EnvironmentObject var app: AppModel

    private var groups: [(folder: String, files: [LibraryFile])] {
        Dictionary(grouping: app.files, by: \.folder).map { ($0.key, $0.value) }.sorted { $0.folder < $1.folder }
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "folder", title: "File Browser") {
                Spacer()
                HeaderButton(symbol: "folder.badge.plus", help: "Открыть папку (⇧⌘O)") { app.chooseLibrary() }
                HeaderButton(symbol: "doc.badge.plus", help: "Открыть файл (⌘O)") { app.openFilePanel() }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if app.files.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Откройте папку с эффектами (.avfx, .json) и текстурами.").font(Theme.font).foregroundStyle(Theme.dim)
                            Text("Открыть папку…").font(Theme.font).foregroundStyle(Theme.text)
                                .padding(.horizontal, 10).frame(height: 22)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field))
                                .onTapGesture { app.chooseLibrary() }
                        }
                        .padding(10)
                    }
                    ForEach(groups, id: \.folder) { group in
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill").font(.system(size: 9)).foregroundStyle(Color(red: 0.85, green: 0.7, blue: 0.4))
                            Text(group.folder.isEmpty ? "/" : group.folder).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                                .truncationMode(.head)
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        ForEach(group.files) { file in
                            let selected = app.document?.url == file.url
                            HStack(spacing: 5) {
                                Image(systemName: file.isAvfx ? "sparkles" : "curlybraces").font(.system(size: 9))
                                    .foregroundStyle(file.isAvfx ? NodeTint.particle.color : NodeTint.emitter.color).frame(width: 14)
                                Text(file.name).font(Theme.font).foregroundStyle(selected ? .white : Theme.text).lineLimit(1)
                                Spacer(minLength: 0)
                                if app.isDirty(file.url) { Circle().fill(Theme.text).frame(width: 5, height: 5) }
                            }
                            .padding(.leading, 18)
                            .padding(.trailing, 6)
                            .frame(height: 20)
                            .background(selected ? Theme.selection : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { app.open(file.url) }
                        }
                    }
                }
            }
            .background(Color(white: 0.157))
        }
    }
}
