import AppKit
import SwiftUI

private struct CurvePanelRoot: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        Group {
            if let document = app.document {
                CurveEditorView(document: document, clock: document.clock).id(ObjectIdentifier(document))
            } else {
                Theme.panel
            }
        }
        .frame(minWidth: 480, minHeight: 240)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
        .id(app.themeToken)
    }
}

final class CurvePanel: NSObject, NSWindowDelegate {
    static let shared = CurvePanel()
    private var panel: NSPanel?

    func show(_ app: AppModel) {
        if panel == nil { panel = make(app) }
        guard let panel else { return }
        panel.appearance = NSAppearance(named: Theme.light ? .aqua : .darkAqua)
        if !panel.isVisible, !panel.setFrameUsingName("CurveEditorPanel") {
            let anchor = NSApp.keyWindow ?? NSApp.mainWindow
            if let frame = anchor?.frame {
                panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.minY + 60))
            } else {
                panel.center()
            }
        }
        panel.orderFront(nil)
        panel.makeKey()
    }

    private func make(_ app: AppModel) -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 820, height: 420),
                            styleMask: [.titled, .closable, .resizable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "Curve Editor"
        panel.titleVisibility = .visible
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.minSize = NSSize(width: 480, height: 260)
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.backgroundColor = NSColor(Theme.panel)
        panel.delegate = self
        let host = NSHostingView(rootView: CurvePanelRoot().environmentObject(app))
        host.sizingOptions = []
        panel.contentView = host
        panel.setFrameAutosaveName("CurveEditorPanel")
        return panel
    }
}
