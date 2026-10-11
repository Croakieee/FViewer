import SwiftUI

struct BottomEditors: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument

    var body: some View {
        VStack(spacing: 0) {
            EditorHeader(symbol: app.bottomTab == 0 ? "timeline.selection" : "point.topleft.down.to.point.bottomright.curvepath",
                         title: app.bottomTab == 0 ? "Timeline" : "Graph Editor") {
                HStack(spacing: 1) {
                    tab(0, "Timeline")
                    tab(1, "Graph Editor")
                }
                Spacer()
            }
            if app.bottomTab == 0 {
                SequencerView(document: document)
            } else {
                CurveEditorView(document: document)
            }
        }
    }

    private func tab(_ index: Int, _ title: String) -> some View {
        Text(title)
            .font(Theme.font)
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 10)
            .frame(height: 20)
            .background(RoundedRectangle(cornerRadius: 4).fill(app.bottomTab == index ? Theme.accent : Color(white: 0.22)))
            .contentShape(Rectangle())
            .onTapGesture { app.bottomTab = index }
    }
}

struct TopBar: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles").foregroundStyle(NodeTint.particle.color)
            Text("FViewer").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
            menuButton("Файл") {
                Button("Открыть файл…") { app.openFilePanel() }
                Button("Открыть папку…") { app.chooseLibrary() }
                Divider()
                Button("Сохранить") { app.save() }.disabled(app.document == nil)
                Button("Сохранить как…") { app.saveAs() }.disabled(app.document == nil)
            }
            menuButton("Правка") {
                Button("Отменить") { app.document?.undo() }.disabled(app.document?.undoManager.canUndo != true)
                Button("Повторить") { app.document?.redo() }.disabled(app.document?.undoManager.canRedo != true)
            }
            Spacer()
            if let document = app.document {
                Text(document.format == .avfx ? "AVFX" : "JSON").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(document.format == .avfx ? NodeTint.particle.color : NodeTint.emitter.color))
                Text(document.title + (document.isDirty ? " •" : "")).font(Theme.font).foregroundStyle(Theme.text)
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

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            HSplitView {
                VSplitView {
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
                    .frame(minHeight: 160)
                    LibraryView().frame(minHeight: 120, idealHeight: 260)
                }
                .frame(minWidth: 200, idealWidth: 270, maxWidth: 480)
                Group {
                    if let document = app.document {
                        VSplitView {
                            ViewportPanel(document: document).frame(minHeight: 200)
                            BottomEditors(document: document).frame(minHeight: 140, idealHeight: 280)
                        }
                    } else {
                        welcome
                    }
                }
                .frame(minWidth: 420)
                .layoutPriority(1)
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
                .frame(minWidth: 280, idealWidth: 340, maxWidth: 560)
            }
            statusBar
        }
        .background(Theme.window)
        .preferredColorScheme(.dark)
        .alert("Ошибка", isPresented: Binding(get: { app.errorMessage != nil }, set: { if !$0 { app.errorMessage = nil } })) {
            Button("OK") { app.errorMessage = nil }
        } message: {
            Text(app.errorMessage ?? "")
        }
    }

    private var welcome: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(NodeTint.particle.color)
            Text("FViewer").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.text)
            Text("Редактор эффектов FFXIV: .avfx и JSON").font(Theme.font).foregroundStyle(Theme.dim)
            HStack(spacing: 8) {
                welcomeButton("Открыть папку…", "folder") { app.chooseLibrary() }
                welcomeButton("Открыть файл…", "doc") { app.openFilePanel() }
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
            hint("ЛКМ", "вращение")
            hint("⇧ + ЛКМ", "сдвиг")
            hint("Прокрутка / щипок", "вращение / масштаб")
            hint("Перетаскивание поля", "изменить значение, ⇧ — точно")
            Spacer()
            if let document = app.document {
                Text(document.undoManager.canUndo ? "Отмена: \(document.undoManager.undoActionName)" : "").font(Theme.small).foregroundStyle(Theme.dim)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 20)
        .background(Color(white: 0.094))
    }

    private func hint(_ key: String, _ text: String) -> some View {
        HStack(spacing: 4) {
            Text(key).font(.system(size: 9, weight: .semibold)).foregroundStyle(Theme.text)
            Text(text).font(Theme.small).foregroundStyle(Theme.dim)
        }
    }
}
