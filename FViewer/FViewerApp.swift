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
        .commands {
            CommandGroup(replacing: .newItem) {
                Menu("New Effect") {
                    Button("Blank…") { app.newEffect(template: "blank") }.keyboardShortcut("n")
                    Button("Weapon…") { app.newEffect(template: "weapon") }
                }
                Button("Open File…") { app.openFilePanel() }.keyboardShortcut("o")
                Button("Open Folder…") { app.chooseLibrary() }.keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { app.save() }.keyboardShortcut("s").disabled(app.document == nil)
                Button("Save As…") { app.saveAs() }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(app.document == nil)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { app.document?.undo() }.keyboardShortcut("z")
                Button("Redo") { app.document?.redo() }.keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}
