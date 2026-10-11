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
    @FocusState private var searching: Bool

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
                if document.format == .avfx {
                    Menu {
                        ForEach(EffectDocument.addableKinds, id: \.tag) { kind in
                            Button(kind.title) { document.addTopLevel(kind.tag) }
                        }
                        Divider()
                        Menu("Texture from Library") {
                            ForEach(Array((AppDelegate.model?.textureLibrary ?? []).enumerated()), id: \.offset) { _, entry in
                                Button("★ " + entry.name) { document.addTexture(path: entry.path) }
                            }
                            if !(AppDelegate.model?.textureLibrary ?? []).isEmpty { Divider() }
                            ForEach(Array(AppModel.usefulTextures.enumerated()), id: \.offset) { _, entry in
                                Button(entry.name) { document.addTexture(path: entry.path) }
                            }
                        }
                        Menu("Node from Library") {
                            ForEach(Array((AppDelegate.model?.nodeLibraryItems ?? []).enumerated()), id: \.offset) { _, item in
                                Button(item.name) { AppDelegate.model?.importFromNodeLibrary(item.url) }
                            }
                            Divider()
                            Button("Show Library Folder") { AppDelegate.model?.revealNodeLibrary() }
                        }
                    } label: {
                        Image(systemName: "plus").font(.system(size: 11)).foregroundStyle(Theme.text).frame(width: 24, height: 20)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.22)))
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Add")
                }
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text).focused($searching)
                        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { searching = false } }
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
        let changes = document.changes
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
            if changes.contains(node.id) { ChangeDot(added: changes.added.contains(node.id)) }
            Spacer(minLength: 4)
            Text(node.detail).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            if let key = node.visibility {
                let hidden = document.hidden.contains(key)
                Image(systemName: hidden ? "eye.slash" : "eye").font(.system(size: 9))
                    .foregroundStyle(hidden ? Theme.dim.opacity(0.6) : Theme.text)
                    .frame(width: 18, height: 20).contentShape(Rectangle())
                    .onTapGesture { document.toggleHidden(key) }
                    .help("Show or hide in the viewport")
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 20)
        .background(selected ? Theme.selection : striped ? Color.white.opacity(0.025) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = node.id }
        .contextMenu {
            if let key = node.visibility {
                Button(document.hidden.contains(key) ? "Show" : "Hide") { document.toggleHidden(key) }
                Button("Isolate") {
                    document.selectionID = node.id
                    document.isolateSelection = true
                }
                Divider()
            }
            ForEach(node.actions) { action in
                Button(action.title, role: action.destructive ? .destructive : nil, action: action.perform)
            }
            Divider()
            Button("Rename…") { AppDelegate.model?.renameNode(node.id) }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject var app: AppModel

    private var groups: [(folder: String, files: [LibraryFile])] {
        let favorites = app.favorites
        var result = Dictionary(grouping: app.files, by: \.folder).map { (folder: $0.key, files: $0.value) }.sorted { $0.folder < $1.folder }
        let starred = app.files.filter { favorites.contains($0.url.path) }
        if !starred.isEmpty { result.insert((folder: "★ Favorites", files: starred), at: 0) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "folder", title: "File Browser") {
                Spacer()
                HeaderButton(symbol: "folder.badge.plus", help: "Open Folder (⇧⌘O)") { app.chooseLibrary() }
                HeaderButton(symbol: "doc.badge.plus", help: "Open File (⌘O)") { app.openFilePanel() }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if app.files.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open Folder…").font(Theme.font).foregroundStyle(Theme.text)
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
                                if app.favorites.contains(file.url.path) {
                                    Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(Theme.changed)
                                }
                                if app.isDirty(file.url) { Circle().fill(Theme.text).frame(width: 5, height: 5) }
                            }
                            .padding(.leading, 18)
                            .padding(.trailing, 6)
                            .frame(height: 20)
                            .background(selected ? Theme.selection : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { app.open(file.url) }
                            .contextMenu {
                                Button(app.favorites.contains(file.url.path) ? "Remove from Favorites" : "Add to Favorites") { app.toggleFavorite(file.url) }
                            }
                        }
                    }
                }
            }
            .background(Color(white: 0.157))
        }
    }
}
