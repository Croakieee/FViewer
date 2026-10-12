import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var model: AppModel?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let model = AppDelegate.model else { return .terminateNow }
        return model.confirmDiscardingChanges() ? .terminateNow : .terminateCancel
    }
}

@main
struct FViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var app = AppModel()

    var body: some Scene {
        Window("FViewer", id: "main") {
            ContentView()
                .environmentObject(app)
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultLaunchBehavior(.presented)
        Window("Texture Editor", id: "texture") {
            TextureEditorView().environmentObject(app)
        }
        .defaultSize(width: 1100, height: 720)
        .defaultLaunchBehavior(.suppressed)
        Window("File Inspector", id: "gamefile") {
            GameFileView().environmentObject(app)
        }
        .defaultSize(width: 1000, height: 640)
        .defaultLaunchBehavior(.suppressed)
        Window("Settings", id: "settings") {
            SettingsView().environmentObject(app)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        Window("Item Editor", id: "item") {
            ItemEditorView().environmentObject(app)
        }
        .defaultSize(width: 1320, height: 820)
        .defaultLaunchBehavior(.suppressed)
        Window("Model Editor", id: "model") {
            ModelEditorView().environmentObject(app)
        }
        .defaultSize(width: 980, height: 620)
        .defaultLaunchBehavior(.suppressed)
        .commands {
            CommandGroup(replacing: .newItem) {
                Menu("New Effect") {
                    Button("Blank…") { app.newEffect(template: "blank") }.keyboardShortcut(AppShortcuts.key("new"))
                    Button("Weapon…") { app.newEffect(template: "weapon") }
                }
                Button("Open File…") { app.openFilePanel() }.keyboardShortcut(AppShortcuts.key("open"))
                Button("Open Folder…") { app.chooseLibrary() }.keyboardShortcut(AppShortcuts.key("openFolder"), modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { app.save() }.keyboardShortcut(AppShortcuts.key("save")).disabled(app.document == nil)
                Button("Save As…") { app.saveAs() }.keyboardShortcut(AppShortcuts.key("saveAs"), modifiers: [.command, .shift]).disabled(app.document == nil)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { app.document?.undo() }.keyboardShortcut(AppShortcuts.key("undo"))
                Button("Redo") { app.document?.redo() }.keyboardShortcut(AppShortcuts.key("redo"), modifiers: [.command, .shift])
            }
        }
    }
}
