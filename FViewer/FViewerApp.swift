import SwiftUI

@main
struct FViewerApp: App {
    @StateObject private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(app)
                .frame(minWidth: 1100, minHeight: 680)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Открыть файл…") { app.openFilePanel() }.keyboardShortcut("o")
                Button("Открыть папку…") { app.chooseLibrary() }.keyboardShortcut("o", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Сохранить") { app.save() }.keyboardShortcut("s").disabled(app.document == nil)
                Button("Сохранить как…") { app.saveAs() }.keyboardShortcut("s", modifiers: [.command, .shift]).disabled(app.document == nil)
            }
            CommandGroup(replacing: .undoRedo) {
                Button("Отменить") { app.document?.undo() }.keyboardShortcut("z")
                Button("Повторить") { app.document?.redo() }.keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}
