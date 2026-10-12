import Combine
import SwiftUI

struct BrowserPanel: View {
    @AppStorage("browser.mode") private var mode = 0

    var body: some View {
        if mode == 0 { LibraryView(mode: $mode) } else if mode == 1 { NodeLibraryView(mode: $mode) } else if mode == 2 { HistoryView(mode: $mode) } else { AssetsView(mode: $mode) }
    }
}

struct NodeLibraryView: View {
    @EnvironmentObject var app: AppModel
    @Binding var mode: Int
    @State private var collapsed: Set<String> = []
    @State private var target: String?

    static let colors: [(name: String, color: Color)] = [
        ("None", Color(white: 0.45)), ("Red", Color(red: 0.86, green: 0.33, blue: 0.31)), ("Orange", Color(red: 0.9, green: 0.56, blue: 0.25)),
        ("Yellow", Color(red: 0.88, green: 0.78, blue: 0.3)), ("Green", Color(red: 0.42, green: 0.75, blue: 0.42)),
        ("Blue", Color(red: 0.36, green: 0.58, blue: 0.9)), ("Purple", Color(red: 0.66, green: 0.47, blue: 0.86)),
    ]

    private var groups: [(folder: String, entries: [NodeLibraryEntry])] {
        let entries = app.nodeLibraryEntries
        var folders = Set(app.nodeLibraryFolders)
        folders.insert("")
        entries.forEach { folders.insert($0.folder) }
        return folders.sorted().map { folder in (folder, entries.filter { $0.folder == folder }) }
    }

    private func accept(_ urls: [URL], into folder: String) -> Bool {
        let entries = urls.compactMap { app.libraryEntry(for: $0) }.filter { $0.folder != folder }
        entries.forEach { app.moveLibraryEntry($0, toFolder: folder) }
        return !entries.isEmpty
    }

    private func folderRow(_ folder: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: collapsed.contains(folder) ? "chevron.right" : "chevron.down").font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.dim)
                .frame(width: 10)
            Image(systemName: "folder.fill").font(.system(size: 9)).foregroundStyle(Color(red: 0.85, green: 0.7, blue: 0.4))
            Text(folder.isEmpty ? "/" : folder).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1).truncationMode(.head)
            Spacer(minLength: 0)
            Text("\(count)").font(Theme.small).foregroundStyle(Theme.dim)
        }
        .padding(.horizontal, 6)
        .frame(height: 18)
        .background(target == folder ? Theme.selection.opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { if collapsed.contains(folder) { collapsed.remove(folder) } else { collapsed.insert(folder) } }
        .dropDestination(for: URL.self) { urls, _ in accept(urls, into: folder) } isTargeted: { inside in
            if inside { target = folder } else if target == folder { target = nil }
        }
        .contextMenu {
            if !folder.isEmpty { Button("Remove Empty Folder") { app.removeLibraryFolder(folder) } }
        }
    }

    private func entryRow(_ entry: NodeLibraryEntry) -> some View {
        HStack(spacing: 5) {
            Circle().fill(NodeLibraryView.colors[min(max(entry.color, 0), NodeLibraryView.colors.count - 1)].color).frame(width: 7, height: 7).frame(width: 14)
            Text(entry.name).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
            Spacer(minLength: 0)
            if !entry.note.isEmpty { HelpBadge(text: entry.note) }
        }
        .padding(.leading, 18)
        .padding(.trailing, 6)
        .frame(height: 20)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { app.importFromNodeLibrary(entry.url) }
        .draggable(entry.url)
        .contextMenu {
            Button("Import into Effect") { app.importFromNodeLibrary(entry.url) }.disabled(app.document?.format != .avfx)
            Divider()
            Button("Rename…") { app.renameLibraryEntry(entry) }
            Button("Description…") { app.editLibraryNote(entry) }
            Menu("Colour") {
                ForEach(Array(NodeLibraryView.colors.enumerated()), id: \.offset) { index, item in
                    Button {
                        app.setLibraryColor(entry, index)
                    } label: {
                        if entry.color == index { Label(item.name, systemImage: "checkmark") } else { Text(item.name) }
                    }
                }
            }
            Menu("Move to Folder") {
                ForEach(groups.map(\.folder).filter { $0 != entry.folder }, id: \.self) { folder in
                    Button(folder.isEmpty ? "/" : folder) { app.moveLibraryEntry(entry, toFolder: folder) }
                }
            }
            Divider()
            Button("Move to Trash", role: .destructive) { app.deleteLibraryEntry(entry) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: "shippingbox", title: "Node Library") {
                Spacer(minLength: 0)
                HeaderButton(symbol: "photo.on.rectangle", help: "Show the textures and models of the open folder") { mode = 3 }
                HeaderButton(symbol: "folder", help: "Show the File Browser") { mode = 0 }
                HeaderButton(symbol: "folder.badge.plus", help: "New Library Folder") { app.newLibraryFolder() }
                HeaderButton(symbol: "arrow.up.forward.square", help: "Show the Library Folder in Finder") { app.revealNodeLibrary() }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groups, id: \.folder) { group in
                        folderRow(group.folder, count: group.entries.count)
                        if !collapsed.contains(group.folder) {
                            ForEach(group.entries) { entry in entryRow(entry) }
                        }
                    }
                }
            }
            .background(Theme.gray(0.157))
        }
    }
}

struct EffectListSheet: View {
    @EnvironmentObject var app: AppModel
    let list: EffectList

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").foregroundStyle(Theme.text)
                Text(list.title).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.head)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Theme.gray(0.157))
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(list.paths, id: \.self) { path in
                        let available = app.game?.contains(path) ?? false
                        HStack(spacing: 6) {
                            Text(path).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.head).textSelection(.enabled)
                            Spacer(minLength: 4)
                            HeaderButton(symbol: "doc.on.doc", help: "Copy the path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(path, forType: .string)
                            }
                            SegmentButton(title: "Open", active: available) {
                                guard available else { return }
                                app.effectList = nil
                                do { try app.openFromGame(path) } catch { app.errorMessage = error.localizedDescription }
                            }
                            .opacity(available ? 1 : 0.4)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 24)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 120, maxHeight: 420)
            HStack(spacing: 8) {
                if app.gameRoot == nil { HelpBadge(text: "Choose the game folder in File → Game to open these effects straight from the archives.") }
                Spacer()
                SegmentButton(title: "Close", active: false) { app.effectList = nil }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.gray(0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}

struct ConvertImagesSheet: View {
    @EnvironmentObject var app: AppModel
    @State private var sources: [URL] = []
    @State private var folder: URL?
    @AppStorage("convert.target") private var target = 0
    @AppStorage("convert.reencode") private var reencode = false

    private var kind: ImageTarget { ImageTarget(rawValue: target) ?? .png }

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 110, alignment: .trailing)
            content()
        }
    }

    private var problem: String? {
        if sources.isEmpty { return "Add images to convert" }
        if folder == nil { return "Choose the output folder" }
        return nil
    }

    var body: some View {
        let issue = problem
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle").foregroundStyle(Theme.text)
                Text("Convert Images").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Theme.gray(0.157))
            ScrollView {
                VStack(spacing: 6) {
                    Panel(title: "Output") {
                        row("Type") {
                            ForEach(ImageTarget.allCases, id: \.rawValue) { item in
                                SegmentButton(title: item.title, active: target == item.rawValue) { target = item.rawValue }
                            }
                            Spacer()
                        }
                        if kind != .png {
                            row("Format") {
                                ChoiceField(choices: TextureCodec.importFormats.map { FieldChoice(name: $0.name, value: Int($0.format.rawValue)) },
                                            value: Int(app.importFormat.rawValue)) { value in
                                    UserDefaults.standard.set(value, forKey: "texture.format")
                                    app.objectWillChange.send()
                                }
                            }
                            row("Mips") {
                                NumberField(label: nil, value: Double(app.importMips), isInteger: true, onLive: { _ in },
                                            onCommit: { _, next in
                                                UserDefaults.standard.set(Int(min(max(next, 1), 13)), forKey: "texture.mips")
                                                app.objectWillChange.send()
                                            })
                                    .frame(width: 90)
                                Spacer()
                            }
                            row("") {
                                CheckBox(isOn: reencode, label: "Re-encode game textures") { reencode = $0 }
                                Spacer()
                                HelpBadge(text: "Off: .dds, .atex and .tex sources keep their pixel format and mips. On: they are decoded and encoded again with the format and mips above.")
                            }
                        }
                        row("Folder") {
                            Text(folder?.path ?? "").font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.head)
                            Spacer(minLength: 4)
                            SegmentButton(title: "Choose…", active: false) { if let url = app.chooseFolder("Output Folder") { folder = url } }
                        }
                    }
                    Panel(title: "Images", trailing: "\(sources.count)") {
                        ForEach(sources, id: \.self) { url in
                            HStack(spacing: 6) {
                                Text(url.lastPathComponent).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.middle)
                                Spacer(minLength: 4)
                                HeaderButton(symbol: "minus", help: "Remove from the list") { sources.removeAll { $0 == url } }
                            }
                        }
                        HStack(spacing: 6) {
                            SegmentButton(title: "Add…", active: false) {
                                for url in app.chooseImages() where !sources.contains(url) { sources.append(url) }
                                if folder == nil { folder = sources.first?.deletingLastPathComponent() }
                            }
                            Spacer()
                            HelpBadge(text: "PNG, JPEG, TGA, BMP, TIFF, DDS, .atex and .tex. Existing files are never replaced: a converted file that would collide gets an F added to its name.")
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 260, maxHeight: 520)
            HStack(spacing: 8) {
                if let issue { Text(issue).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1) }
                Spacer()
                SegmentButton(title: "Close", active: false) { app.convertImages = false }
                SegmentButton(title: "Convert", active: issue == nil) {
                    guard issue == nil, let folder else { return }
                    let result = app.convertImages(sources, to: kind, into: folder, reencode: reencode)
                    if result.failures.isEmpty { app.convertImages = false }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.gray(0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}

struct HistoryView: View {
    @EnvironmentObject var app: AppModel
    @Binding var mode: Int
    @State private var filter = ""

    var body: some View {
        let favorites = app.favorites
        let needle = filter.lowercased()
        let files = app.recentFiles.filter { needle.isEmpty || $0.lastPathComponent.lowercased().contains(needle) || app.note(for: $0).lowercased().contains(needle) }
        VStack(spacing: 0) {
            EditorHeader(symbol: "clock", title: "History") {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
                HeaderButton(symbol: "folder", help: "Show the File Browser") { mode = 0 }
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(files, id: \.self) { file in
                        let selected = app.document?.url == file
                        let note = app.note(for: file)
                        HStack(spacing: 6) {
                            ZStack {
                                Theme.gray(0.1)
                                if let image = app.thumbnail(for: file) {
                                    Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Image(systemName: "sparkles").font(.system(size: 11)).foregroundStyle(Theme.dim)
                                }
                            }
                            .frame(width: 64, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(file.lastPathComponent).font(Theme.font).foregroundStyle(selected ? .white : Theme.text).lineLimit(1).truncationMode(.middle)
                                    if favorites.contains(file.path) { Image(systemName: "star.fill").font(.system(size: 8)).foregroundStyle(Theme.changed) }
                                }
                                Text(note.isEmpty ? file.deletingLastPathComponent().lastPathComponent : note).font(Theme.small)
                                    .foregroundStyle(note.isEmpty ? Theme.dim : Theme.changed).lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selected ? Theme.selection : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { app.openRecent(file) }
                        .contextMenu {
                            Button(favorites.contains(file.path) ? "Remove from Favorites" : "Add to Favorites") { app.toggleFavorite(file) }
                            Button("Note…") { app.editNote(for: file) }
                            Divider()
                            Button("Remove from History", role: .destructive) { app.forgetRecent(file) }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .background(Theme.gray(0.157))
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var app: AppModel
    @AppStorage("autosave.minutes") private var autosave = 5
    @AppStorage("itemEditor.skipQuestion") private var skipQuestion = false
    @State private var refresh = 0

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 150, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                general
                colours
                shortcuts
                rules
            }
            .padding(.vertical, 8)
            .id(refresh)
        }
        .frame(width: 520, height: 620)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }

    private var general: some View {
        Panel(title: "General") {
            row("Autosave every") {
                NumberField(label: nil, value: Double(autosave), isInteger: true, onLive: { _ in }, onCommit: { _, next in
                    autosave = Int(min(max(next, 1), 120))
                    app.startAutosave()
                })
                .frame(width: 80)
                Text("minutes").font(Theme.font).foregroundStyle(Theme.dim)
            }
            row("") { CheckBox(isOn: !skipQuestion, label: "Ask before opening an editor window") { skipQuestion = !$0 } }
            row("") {
                CheckBox(isOn: Theme.light, label: "Light theme") { on in
                    UserDefaults.standard.set(on, forKey: "theme.light")
                    refresh += 1
                    app.objectWillChange.send()
                    app.document?.liveChanged()
                }
                HelpBadge(text: "Windows that are already open pick the theme up fully after they are reopened.")
            }
            row("Game folder") {
                Text(app.gameRoot?.path ?? "not set").font(Theme.font).foregroundStyle(Theme.dim).lineLimit(1).truncationMode(.head)
                SegmentButton(title: "Choose…", active: false) { app.chooseGameFolder() }
            }
        }
    }

    private var colours: some View {
        Panel(title: "Curve Colours") {
            ForEach(0..<3, id: \.self) { index in
                row(["X / Value", "Y", "Z"][index]) {
                    ColorPicker("", selection: Binding(get: { EffectDocument.channelColors[index] }, set: { color in
                        PreviewRules.setCurveColor(index, color)
                        refresh += 1
                        app.document?.liveChanged()
                    }), supportsOpacity: false).labelsHidden()
                }
            }
            row("") {
                SegmentButton(title: "Reset Colours", active: false) {
                    PreviewRules.resetCurveColors()
                    refresh += 1
                    app.document?.liveChanged()
                }
            }
        }
    }

    private var shortcuts: some View {
        Panel(title: "Shortcuts") {
            ForEach(AppShortcuts.commands, id: \.key) { command in
                row(command.title) {
                    Text(command.shift ? "⇧⌘" : "⌘").font(Theme.font).foregroundStyle(Theme.dim)
                    TextValueField(value: (UserDefaults.standard.string(forKey: "shortcut." + command.key) ?? command.fallback).uppercased()) { text in
                        let letter = text.trimmingCharacters(in: .whitespaces).lowercased().prefix(1)
                        UserDefaults.standard.set(letter.isEmpty ? command.fallback : String(letter), forKey: "shortcut." + command.key)
                        refresh += 1
                    }
                    .frame(width: 40)
                }
            }
            HStack {
                Spacer()
                HelpBadge(text: "One letter or digit per command. A changed shortcut works after the app is started again.")
            }
        }
    }

    private var rules: some View {
        Panel(title: "Preview Rules") {
            ForEach(PreviewRules.all, id: \.key) { rule in
                HStack(spacing: 6) {
                    CheckBox(isOn: PreviewRules.isOn(rule.key), label: rule.title) { on in
                        PreviewRules.set(rule.key, on)
                        refresh += 1
                        app.document?.liveChanged()
                    }
                    HelpBadge(text: rule.help)
                }
            }
        }
    }
}

struct AssetsView: View {
    @EnvironmentObject var app: AppModel
    @Binding var mode: Int
    @State private var filter = ""

    var body: some View {
        let needle = filter.lowercased()
        let all = app.textureAssets
        let textures = Array(all.filter { needle.isEmpty || $0.relative.contains(needle) }.prefix(300))
        let models = app.modelAssets.filter { needle.isEmpty || $0.name.contains(needle) }
        VStack(spacing: 0) {
            EditorHeader(symbol: "photo.on.rectangle", title: "Assets") {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
                HeaderButton(symbol: "folder", help: "Show the File Browser") { mode = 0 }
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Textures  \(textures.count) / \(all.count)").font(Theme.small).foregroundStyle(Theme.dim)
                        Spacer()
                        HelpBadge(text: "Drag a texture onto the Outliner to add it to the effect, or onto a layer in the Item Editor to use it there. Double-click adds it to the effect.")
                    }
                    .padding(.horizontal, 6)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 4)], spacing: 4) {
                        ForEach(textures, id: \.url) { asset in
                            VStack(spacing: 1) {
                                ZStack {
                                    CheckerBackground()
                                    if let image = app.assetImage(asset.url) {
                                        Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                                    }
                                }
                                .frame(height: 54)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                                Text(asset.name).font(.system(size: 8)).foregroundStyle(Theme.dim).lineLimit(1).truncationMode(.middle)
                            }
                            .help(asset.relative)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                if let document = app.document, let index = app.addTextureAsset(asset.url, to: document) { document.selectionID = "avfx/Tex/\(index)" }
                            }
                            .draggable(asset.url)
                        }
                    }
                    .padding(.horizontal, 6)
                    if !models.isEmpty {
                        Text("Models  \(models.count)").font(Theme.small).foregroundStyle(Theme.dim).padding(.horizontal, 6).padding(.top, 4)
                        ForEach(models, id: \.url) { model in
                            HStack(spacing: 5) {
                                Image(systemName: "cube").font(.system(size: 9)).foregroundStyle(NodeTint.model.color).frame(width: 14)
                                Text(model.name).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 18)
                            .draggable(model.url)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .background(Theme.gray(0.157))
        }
    }
}

struct ModListSheet: View {
    @EnvironmentObject var app: AppModel
    @State private var filter = ""

    var body: some View {
        let needle = filter.lowercased()
        let mods = (app.modList ?? []).filter { needle.isEmpty || $0.name.lowercased().contains(needle) || $0.author.lowercased().contains(needle) }
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox").foregroundStyle(Theme.text)
                Text("Penumbra Mods").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    TextField("", text: $filter).textFieldStyle(.plain).font(Theme.font).foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 6)
                .frame(width: 180, height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.fieldDark))
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Theme.gray(0.157))
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(mods) { mod in
                        HStack(spacing: 6) {
                            Text(mod.name).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                            Text(mod.author).font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(mod.effects) effects").font(Theme.small).foregroundStyle(Theme.dim)
                            SegmentButton(title: "Open", active: mod.effects > 0) {
                                app.modList = nil
                                app.setLibrary(mod.id)
                                app.notice = "Opened the mod \(mod.name)"
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 24)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 160, maxHeight: 460)
            HStack(spacing: 8) {
                SegmentButton(title: "Other Folder…", active: false) {
                    app.modList = nil
                    app.choosePenumbraFolder()
                }
                Spacer()
                SegmentButton(title: "Close", active: false) { app.modList = nil }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.gray(0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}
