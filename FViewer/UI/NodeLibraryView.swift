import Combine
import SwiftUI

struct BrowserPanel: View {
    @AppStorage("browser.mode") private var mode = 0

    var body: some View {
        if mode == 0 { LibraryView(mode: $mode) } else { NodeLibraryView(mode: $mode) }
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
            .background(Color(white: 0.157))
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
            .background(Color(white: 0.157))
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
            .background(Color(white: 0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(.dark)
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
            .background(Color(white: 0.157))
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
            .background(Color(white: 0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(.dark)
    }
}
