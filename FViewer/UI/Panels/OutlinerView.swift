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
                        Button("Layer") { document.addLayer() }
                            .help("A particle, an emitter that creates it and a timeline item that runs the emitter, ready to see")
                        Divider()
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
                            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.22)))
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
            .background(Theme.gray(0.157))
            .dropDestination(for: URL.self) { urls, _ in
                let nodes = urls.filter { ["vfxedit", "vfxedit2"].contains($0.pathExtension.lowercased()) }
                let images = urls.filter { AppModel.imageSourceTypes.contains($0.pathExtension.lowercased()) }
                guard document.format == .avfx, !nodes.isEmpty || !images.isEmpty else { return false }
                nodes.forEach { AppDelegate.model?.importFromNodeLibrary($0) }
                for image in images {
                    if let index = AppDelegate.model?.addTextureAsset(image, to: document) { document.selectionID = "avfx/Tex/\(index)" }
                }
                return true
            }
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
            if let warning = node.warning {
                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 9)).foregroundStyle(Theme.changed).help(warning)
            }
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
        .onTapGesture(count: 2) {
            document.selectionID = node.id
            AppDelegate.model?.openEditor(for: node.id)
        }
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
            if AppDelegate.model?.canOpenEditor(node.id) == true {
                Button("Open Editor…") { AppDelegate.model?.openEditor(for: node.id) }
            }
            Divider()
            Button("Rename…") { AppDelegate.model?.renameNode(node.id) }
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject var app: AppModel
    @Binding var mode: Int
    @State private var filter = ""
    @State private var category = ""

    private var categories: [String] {
        var seen: [String] = []
        for file in app.files {
            let top = String(file.folder.split(separator: "/").first ?? "")
            if !top.isEmpty, !seen.contains(top) { seen.append(top) }
            if seen.count > 60 { break }
        }
        return seen.sorted()
    }

    private var groups: [(folder: String, files: [LibraryFile])] { app.libraryGroups(filter: filter, category: category) }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "folder", title: "File Browser") {
                Spacer(minLength: 0)
                HeaderButton(symbol: "photo.on.rectangle", help: "Show the textures and models of the open folder") { mode = 3 }
                HeaderButton(symbol: "doc.text.magnifyingglass", help: "Show the other game files of the open folder") { mode = 4 }
                HeaderButton(symbol: "clock", help: "Show the history of opened effects") { mode = 2 }
                HeaderButton(symbol: "shippingbox", help: "Show the Node Library") { mode = 1 }
                HeaderButton(symbol: "folder.badge.plus", help: "Open Folder (⇧⌘O)") { app.chooseLibrary() }
                HeaderButton(symbol: "doc.badge.plus", help: "Open File (⌘O)") { app.openFilePanel() }
            }
            .onChange(of: app.libraryRoot) { _, _ in
                filter = ""
                category = ""
            }
            if app.libraryScanning {
                Text("Reading the folder…").font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8)
            }
            if app.files.count > 12 {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                    if !filter.isEmpty { Image(systemName: "xmark.circle.fill").font(.system(size: 9)).foregroundStyle(Theme.dim).onTapGesture { filter = "" } }
                    Text("\(app.files.count)").font(Theme.small).foregroundStyle(Theme.dim)
                    if categories.count > 1 {
                        Menu {
                            Button("All Folders") { category = "" }
                            Divider()
                            ForEach(categories, id: \.self) { name in Button(name) { category = name } }
                        } label: {
                            Text(category.isEmpty ? "All" : category).font(Theme.small).foregroundStyle(Theme.text).lineLimit(1)
                                .padding(.horizontal, 5).frame(height: 16).background(RoundedRectangle(cornerRadius: 3).fill(Theme.field.opacity(0.6)))
                        }
                        .menuStyle(.button)
                        .buttonStyle(.plain)
                        .menuIndicator(.hidden)
                        .fixedSize()
                        .help("Show only one top folder")
                    }
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(Theme.fieldDark)
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
            .background(Theme.gray(0.157))
        }
    }
}
