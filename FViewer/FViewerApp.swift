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
                .id(app.themeToken)
                .environmentObject(app)
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultLaunchBehavior(.presented)
        Window("Texture Editor", id: "texture") {
            TextureEditorView().id(app.themeToken).environmentObject(app)
        }
        .defaultSize(width: 1100, height: 720)
        .defaultLaunchBehavior(.suppressed)
        Window("File Inspector", id: "gamefile") {
            GameFileView().id(app.themeToken).environmentObject(app)
        }
        .defaultSize(width: 1000, height: 640)
        .defaultLaunchBehavior(.suppressed)
        Window("Settings", id: "settings") {
            SettingsView().environmentObject(app)
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
        Window("Item Editor", id: "item") {
            ItemEditorView().id(app.themeToken).environmentObject(app)
        }
        .defaultSize(width: 1320, height: 820)
        .defaultLaunchBehavior(.suppressed)
        Window("Model Editor", id: "model") {
            ModelEditorView().id(app.themeToken).environmentObject(app)
        }
        .defaultSize(width: 1280, height: 760)
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
                Button("Undo") { if let text = NSApp.keyWindow?.firstResponder as? NSTextView, text.undoManager?.canUndo == true { text.undoManager?.undo() } else if NSApp.keyWindow?.title == "File Inspector" { app.gameFile?.undo() } else { app.document?.undo() } }.keyboardShortcut(AppShortcuts.key("undo"))
                Button("Redo") { if let text = NSApp.keyWindow?.firstResponder as? NSTextView, text.undoManager?.canRedo == true { text.undoManager?.redo() } else if NSApp.keyWindow?.title == "File Inspector" { app.gameFile?.redo() } else { app.document?.redo() } }
                    .keyboardShortcut(AppShortcuts.key("redo"), modifiers: [.command, .shift])
            }
        }
    }
}
