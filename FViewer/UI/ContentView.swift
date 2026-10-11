import SwiftUI

struct BottomEditors: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument

    private static let editors: [(title: String, symbol: String)] = [
        ("Timeline", "timeline.selection"), ("Graph Editor", "point.topleft.down.to.point.bottomright.curvepath"),
        ("Node Editor", "point.3.connected.trianglepath.dotted"),
    ]

    var body: some View {
        let current = min(max(app.bottomTab, 0), BottomEditors.editors.count - 1)
        VStack(spacing: 0) {
            EditorHeader(symbol: BottomEditors.editors[current].symbol, title: BottomEditors.editors[current].title) {
                HStack(spacing: 1) {
                    ForEach(Array(BottomEditors.editors.enumerated()), id: \.offset) { index, editor in
                        SegmentButton(title: editor.title, active: current == index) { app.bottomTab = index }
                    }
                }
                Spacer()
                HeaderButton(symbol: app.bottomExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                             active: app.bottomExpanded, help: "Maximize this editor over the viewport") { app.bottomExpanded.toggle() }
            }
            switch current {
            case 0: SequencerView(document: document, clock: document.clock)
            case 1: CurveEditorView(document: document, clock: document.clock)
            default: NodeGraphView(document: document).coordinateSpace(name: "graph")
            }
        }
    }
}

struct TopBar: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(NodeTint.particle.color)
            Text("FViewer").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
            menuButton("File") {
                Menu("New Effect") {
                    Button("Blank…") { app.newEffect(template: "blank") }
                    Button("Weapon…") { app.newEffect(template: "weapon") }
                }
                Button("Open File…") { app.openFilePanel() }
                Button("Open Folder…") { app.chooseLibrary() }
                Menu("Game") {
                    Button(app.gameRoot == nil ? "Choose Game Folder…" : "Change Game Folder…") { app.chooseGameFolder() }
                    Button("Open Effect by Game Path…") { app.openFromGamePrompt() }.disabled(app.gameRoot == nil)
                    Button("Extract File by Game Path…") { app.extractFromGamePrompt() }.disabled(app.gameRoot == nil)
                    Button("Fetch Missing Textures") { app.fetchMissingTextures() }.disabled(app.gameRoot == nil || app.document == nil)
                    Divider()
                    Button("Effects of Timeline by Game Path…") { app.listEffectsOfGamePath() }.disabled(app.gameRoot == nil)
                    Button("Effects of Timeline File (.tmb, .pap)…") { app.listEffectsOfFile() }
                }
                Menu("Open Recent") {
                    ForEach(app.recentFiles, id: \.self) { url in Button(url.lastPathComponent) { app.openRecent(url) } }
                }
                Divider()
                Button("Save") { app.save() }.disabled(app.document == nil)
                Button("Save As…") { app.saveAs() }.disabled(app.document == nil)
                Divider()
                Button("Save Workspace…") { app.saveWorkspace() }.disabled(app.libraryRoot == nil)
                Menu("Open Workspace") {
                    ForEach(app.workspaceFiles, id: \.self) { url in Button(url.deletingPathExtension().lastPathComponent) { app.openWorkspace(url) } }
                }
                .disabled(app.workspaceFiles.isEmpty)
                Menu("Append Workspace") {
                    ForEach(app.workspaceFiles, id: \.self) { url in Button(url.deletingPathExtension().lastPathComponent) { app.openWorkspace(url, append: true) } }
                }
                .disabled(app.workspaceFiles.isEmpty)
                Divider()
                Button("Reload from Disk") { app.reloadDocument() }.disabled(app.document == nil)
                Button("Show Autosaves") { app.revealAutosaves() }
                Divider()
                Button("Import Penumbra Mod (.pmp)…") { app.importPenumbraMod() }
                Button("Import Nodes…") { app.importNodesPanel() }.disabled(app.document?.format != .avfx)
                Button("Export Nodes…") { app.document?.exportRequest = [] }.disabled(app.document?.format != .avfx)
                Button("Export Mod…") { app.modExport = true }.disabled(app.document?.format != .avfx)
            }
            menuButton("Edit") {
                Button("Undo") { app.document?.undo() }.disabled(app.document?.undoManager.canUndo != true)
                Button("Redo") { app.document?.redo() }.disabled(app.document?.undoManager.canRedo != true)
                Divider()
                Button("Clean Up Unused Nodes") { app.cleanUp() }.disabled(app.document?.format != .avfx)
                Button("Convert Textures to Custom Paths") { app.convertTextures() }.disabled(app.document?.format != .avfx)
                Button("Convert Images…") { app.convertImages = true }
            }
            Spacer()
            if let document = app.document {
                Text(document.format == .avfx ? "AVFX" : "JSON").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(document.format == .avfx ? NodeTint.particle.color : NodeTint.emitter.color))
                Text(document.title + (document.isDirty ? " •" : "")).font(Theme.font).foregroundStyle(Theme.text)
                if let exact = document.roundTripExact {
                    HStack(spacing: 3) {
                        Image(systemName: exact ? "checkmark.seal.fill" : "exclamationmark.triangle.fill").font(.system(size: 9))
                        Text(exact ? "Verified" : "Not byte-exact").font(Theme.small)
                    }
                    .foregroundStyle(exact ? Color(red: 0.45, green: 0.8, blue: 0.45) : Color.orange)
                    .help(exact ? "The file was re-encoded right after loading and matched the original byte for byte, so saving cannot damage untouched data"
                          : "Re-encoding this file does not reproduce it byte for byte. Keep a backup: saving may change data you did not edit")
                }
            }
            Spacer()
            if let root = app.libraryRoot {
                Image(systemName: "folder").font(.system(size: 10)).foregroundStyle(Theme.dim)
                Text(root.lastPathComponent).font(Theme.small).foregroundStyle(Theme.dim)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(Color(white: 0.094))
    }

    private func menuButton<Items: View>(_ title: String, @ViewBuilder items: () -> Items) -> some View {
        Menu(content: items) {
            Text(title).font(Theme.font).foregroundStyle(Theme.text).padding(.horizontal, 6).frame(height: 20)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}

struct ContentView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.openWindow) private var openWindow
    @AppStorage("layout.left") private var leftFraction = 0.17
    @AppStorage("layout.right") private var rightFraction = 0.22
    @AppStorage("layout.bottom") private var bottomFraction = 0.4
    @AppStorage("layout.library") private var libraryFraction = 0.36

    private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double { min(max(value, low), high) }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            GeometryReader { geometry in
                let size = geometry.size
                let origin = geometry.frame(in: .global).origin
                let left = max(180, size.width * leftFraction)
                let right = max(260, size.width * rightFraction)
                let center = max(200, size.width - left - right - AreaDivider.thickness * 2)
                let bottom = max(120, size.height * bottomFraction)
                let library = max(90, size.height * libraryFraction)
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Group {
                            if let document = app.document {
                                OutlinerView(document: document)
                            } else {
                                VStack(spacing: 0) {
                                    EditorHeader(symbol: "list.bullet.indent", title: "Outliner") { Spacer() }
                                    Color(white: 0.157)
                                }
                            }
                        }
                        .frame(height: max(100, size.height - library - AreaDivider.thickness))
                        AreaDivider(vertical: false) { y in libraryFraction = clamp(1 - Double((y - origin.y) / size.height), 0.1, 0.8) }
                        BrowserPanel().frame(height: library)
                    }
                    .frame(width: left)
                    AreaDivider(vertical: true) { x in leftFraction = clamp(Double((x - origin.x) / size.width), 0.1, 0.35) }
                    Group {
                        if let document = app.document {
                            if app.bottomExpanded {
                                BottomEditors(document: document)
                            } else {
                                VStack(spacing: 0) {
                                    ViewportPanel(document: document).frame(height: max(120, size.height - bottom - AreaDivider.thickness))
                                    AreaDivider(vertical: false) { y in bottomFraction = clamp(1 - Double((y - origin.y) / size.height), 0.15, 0.8) }
                                    BottomEditors(document: document).frame(height: bottom)
                                }
                            }
                        } else {
                            welcome
                        }
                    }
                    .frame(width: center)
                    AreaDivider(vertical: true) { x in rightFraction = clamp(1 - Double((x - origin.x) / size.width), 0.14, 0.4) }
                    Group {
                        if let document = app.document {
                            InspectorView(document: document)
                        } else {
                            VStack(spacing: 0) {
                                EditorHeader(symbol: "slider.horizontal.3", title: "Properties") { Spacer() }
                                Theme.panel
                            }
                        }
                    }
                    .frame(width: right)
                    .environment(\.labelWidth, min(max(right * 0.36, 96), 220))
                }
            }
            statusBar
        }
        .background(Theme.window)
        .background(WindowConfigurator())
        .onAppear {
            app.openModelWindow = { openWindow(id: "model") }
            app.openTextureWindow = { openWindow(id: "texture") }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: Binding(get: { app.document?.exportRequest != nil }, set: { if !$0 { app.document?.exportRequest = nil } })) {
            if let document = app.document { ExportNodesSheet(document: document, selected: document.exportRequest ?? []) }
        }
        .sheet(isPresented: $app.convertImages) { ConvertImagesSheet().environmentObject(app) }
        .sheet(item: $app.effectList) { list in EffectListSheet(list: list).environmentObject(app) }
        .sheet(isPresented: $app.modExport) {
            if let document = app.document { ExportModSheet(document: document).environmentObject(app) }
        }
        .alert("Error", isPresented: Binding(get: { app.errorMessage != nil }, set: { if !$0 { app.errorMessage = nil } })) {
            Button("OK") { app.errorMessage = nil }
        } message: {
            Text(app.errorMessage ?? "")
        }
    }

    private var welcome: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(NodeTint.particle.color)
            Text("FViewer").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.text)
            HStack(spacing: 8) {
                welcomeButton("Open Folder…", "folder") { app.chooseLibrary() }
                welcomeButton("Open File…", "doc") { app.openFilePanel() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.24))
    }

    private func welcomeButton(_ title: String, _ symbol: String, _ action: @escaping () -> Void) -> some View {
        Label(title, systemImage: symbol)
            .font(Theme.font)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.field))
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    private var statusBar: some View {
        HStack(spacing: 14) {
            HelpBadge(text: "Drag a number field to change it, ⇧ for precision, ⌃ to snap; click it to type.\nRight-click a field label to reset it or remove it from the file.\nAn amber dot marks anything changed since the file was opened.")
            Spacer()
            if let notice = app.notice { Text(notice).font(Theme.small).foregroundStyle(Theme.text) }
            if let document = app.document {
                Text(document.undoManager.canUndo ? "Undo: \(document.undoManager.undoActionName)" : "").font(Theme.small).foregroundStyle(Theme.dim)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 20)
        .background(Color(white: 0.094))
    }

}
