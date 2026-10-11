import AppKit
import MetalKit
import SwiftUI

enum DebugSnapshot {
    static var wantCapture = false
    static var savePath = ""

    static func arg(_ name: String) -> String? {
        let a = CommandLine.arguments
        guard let f = a.firstIndex(of: name), f + 1 < a.count else { return nil }
        return a[f + 1]
    }

    static func schedule(_ app: AppModel) {
        if let script = arg("--script") { DebugDriver.run(script, app); return }
        guard let path = arg("--snapshot") else { return }
        if let frame = arg("--frame") {
            app.document?.clock.playing = false
            app.document?.clock.time = Double(frame) ?? 0
        }
        if let select = arg("--select") { app.document?.selectionID = select }
        if let curve = arg("--curve") { app.document?.activeCurveID = curve }
        if let tab = arg("--tab") { app.bottomTab = Int(tab) ?? 0 }
        if let shading = arg("--shading") { app.effectShading = Int(shading) ?? 0 }
        if CommandLine.arguments.contains("--emitters") { app.showEmitters = true; app.showBindPoints = true }
        if CommandLine.arguments.contains("--isolate") { app.document?.isolateSelection = true }
        if CommandLine.arguments.contains("--exercise"), let doc = app.document, let root = doc.avfxRoot {
            var log: [String] = []
            func counts() -> String {
                guard let r = doc.avfxRoot else { return "-" }
                let parsed = try? AvfxBlock.parseFile([UInt8](doc.serializedData()))
                let e = parsed?.childrenNamed("Emit") ?? []
                return "E\(r.childrenNamed("Emit").count) P\(r.childrenNamed("Ptcl").count) T\(r.childrenNamed("Tex").count) EmCn=\(parsed?.int("EmCn") ?? -1) PrCn=\(parsed?.int("PrCn") ?? -1) TxCn=\(parsed?.int("TxCn") ?? -1) tl0items=\(parsed?.childrenNamed("TmLn").first?.ownRecords("Item").count ?? -1) e0=\(e.first?.ownRecords("ItPr").count ?? -1)/\(e.first?.ownRecords("ItEm").count ?? -1) reparse=\(parsed != nil)"
            }
            let original = doc.serializedData()
            log.append("start " + counts())
            doc.addTopLevel("Emit"); log.append("addEmit " + counts())
            let newEmitter = (doc.avfxRoot?.childrenNamed("Emit").count ?? 1) - 1
            doc.connect(from: "avfx/TmLn/0", to: "avfx/Emit/\(newEmitter)"); log.append("link tl->emit " + counts())
            doc.connect(from: "avfx/Emit/0", to: "avfx/Emit/\(newEmitter)"); log.append("link e0->emit " + counts())
            doc.connect(from: "avfx/Emit/0", to: "avfx/Ptcl/0"); log.append("link e0->p0 " + counts())
            if let p = doc.avfxRoot?.childrenNamed("Ptcl").first { doc.duplicateTopLevel(p) }; log.append("dup particle " + counts())
            if let t = doc.avfxRoot?.childrenNamed("Tex").first { doc.deleteTopLevel(t) }; log.append("del tex0 " + counts())
            if let n = doc.node("avfx/Emit/0") { for f in doc.sections(for: n).first?.fields.prefix(1) ?? [] { doc.commit(f, from: f.read(), to: .double(2.5)); log.append("transform \(f.label) -> \(f.read())") } }
            if let n = doc.node("avfx/Ptcl/0"), let m = doc.missingCurves(for: n).first { m.create(); log.append("add curve \(m.title): groups \(doc.curveGroups(for: doc.node("avfx/Ptcl/0")!).count)") }
            log.append("graph nodes \(doc.graph.nodes.count) edges \(doc.graph.edges.count)")
            var undos = 0
            while doc.undoManager.canUndo && undos < 50 { doc.undoManager.undo(); undos += 1 }
            log.append("undo x\(undos) " + counts() + " identical=\(doc.serializedData() == original)")
            _ = root
            try? log.joined(separator: "\n").write(toFile: path + ".txt", atomically: true, encoding: .utf8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            func find(_ v: NSView) -> MTKView? {
                if let m = v as? MTKView { return m }
                for s in v.subviews { if let m = find(s) { return m } }
                return nil
            }
            guard let window = NSApp.windows.first(where: { $0.contentView.flatMap(find) != nil }), let view = window.contentView,
                  let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
            view.cacheDisplay(in: view.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            guard let metal = find(view) else { return }
            metal.framebufferOnly = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                savePath = path + ".metal.png"
                wantCapture = true
            }
        }
    }

    static func save(_ texture: MTLTexture) {
        let w = texture.width, h = texture.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        texture.getBytes(&bytes, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        for i in stride(from: 0, to: bytes.count, by: 4) { bytes.swapAt(i, i + 2) }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: provider, decode: nil,
                                  shouldInterpolate: false, intent: .defaultIntent) else { return }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: savePath))
        if DebugDriver.app == nil { NSApp.terminate(nil) }
    }
}

enum DebugDriver {
    static var lines: [String] = []
    static var dir = ""
    static var number = 0
    static weak var app: AppModel?
    static var log: [String] = []

    static var own: NSWindow?
    static var patched: Set<String> = []

    static func run(_ script: String, _ model: AppModel) {
        app = model
        dir = (script as NSString).deletingLastPathComponent
        lines = ((try? String(contentsOfFile: script, encoding: .utf8)) ?? "").split(separator: "\n").map(String.init)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let w = TestWindow(contentRect: NSRect(x: 40, y: 60, width: 1600, height: 950), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
            w.isReleasedWhenClosed = false
            w.contentView = TestHost(rootView: ContentView().environmentObject(model))
            w.setContentSize(NSSize(width: 1600, height: 950))
            w.orderFrontRegardless()
            if CommandLine.arguments.contains("--activate") { NSApp.activate(ignoringOtherApps: true) }
            w.makeKeyAndOrderFront(nil)
            own = w
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { step() }
        }
    }

    static func window() -> NSWindow? { own }

    static func post(_ type: NSEvent.EventType, _ x: Double, _ y: Double, clicks: Int = 1, flags: NSEvent.ModifierFlags = []) {
        guard let w = window(), let content = w.contentView else { return }
        let p = NSPoint(x: x, y: Double(content.bounds.height) - y)
        if type == .leftMouseDown, let target = content.hitTest(content.convert(p, from: nil)) {
            var v: NSView? = target
            while let view = v {
                let cls: AnyClass = Swift.type(of: view)
                let name = NSStringFromClass(cls)
                if !patched.contains(name) {
                    patched.insert(name)
                    let block: @convention(block) (AnyObject, NSEvent?) -> Bool = { _, _ in true }
                    class_replaceMethod(cls, #selector(NSView.acceptsFirstMouse(for:)), imp_implementationWithBlock(block), "c@:@")
                }
                v = view.superview
            }
        }
        number += 1
        if let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: flags, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: w.windowNumber,
                                      context: nil, eventNumber: number, clickCount: clicks, pressure: type == .leftMouseUp ? 0 : 1) {
            NSApp.postEvent(e, atStart: false)
        }
    }

    static func finish() {
        try? log.joined(separator: "\n").write(toFile: dir + "/log.txt", atomically: true, encoding: .utf8)
        exit(0)
    }

    static func dump(_ label: String) {
        guard let doc = app?.document else { log.append("\(label): no document"); return }
        log.append("== \(label) sel=\(doc.selectionID ?? "-") curve=\(doc.activeCurveID ?? "-") t=\(doc.clock.time) playing=\(doc.clock.playing) dirty=\(doc.isDirty) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-") tab=\(app?.bottomTab ?? -1) hidden=\(doc.hidden.count) E=\(doc.avfxRoot?.childrenNamed("Emit").count ?? -1) P=\(doc.avfxRoot?.childrenNamed("Ptcl").count ?? -1) file=\(doc.title) exact=\(String(describing: doc.roundTripExact))")
        if let node = doc.selectedNode {
            for section in doc.sections(for: node) {
                log.append("  [\(section.title)] " + section.fields.prefix(14).map { "\($0.label)=\($0.read())" }.joined(separator: "; "))
            }
            for group in doc.curveGroups(for: node) {
                for channel in group.channels {
                    log.append("  curve \(group.id) \(channel.name): " + channel.read().map { "(\($0.time),\(String(format: "%.3f", $0.value)),i\($0.interpolation),\(String(format: "%.2f/%.2f", $0.tangentOut, $0.tangentIn)))" }.joined(separator: " "))
                }
            }
        }
        log.append("  rows " + doc.sequencerRows.map { "\($0.label):\($0.start)-\($0.end)" }.joined(separator: " | "))
        let d = UserDefaults.standard
        log.append("  layout l=\(d.double(forKey: "layout.left")) r=\(d.double(forKey: "layout.right")) b=\(d.double(forKey: "layout.bottom")) lib=\(d.double(forKey: "layout.library"))")
        log.append("  app windows=\(NSApp.windows.map { "\(type(of: $0)) visible=\($0.isVisible) frame=\($0.frame)" }) active=\(NSApp.isActive) hidden=\(NSApp.isHidden) screens=\(NSScreen.screens.count) policy=\(NSApp.activationPolicy().rawValue)")
        if let w = window() { log.append("  window key=\(w.isKeyWindow) \(w.contentView?.bounds.size ?? .zero) first=\(String(describing: type(of: w.firstResponder as Any)))") }
    }

    static func step() {
        guard !lines.isEmpty else { finish(); return }
        let parts = lines.removeFirst().split(separator: " ").map(String.init)
        guard let cmd = parts.first, !cmd.hasPrefix("#") else { step(); return }
        func n(_ i: Int) -> Double { i < parts.count ? Double(parts[i]) ?? 0 : 0 }
        var delay = 0.12
        var flags: NSEvent.ModifierFlags = []
        if parts.contains("shift") { flags.insert(.shift) }
        if parts.contains("cmd") { flags.insert(.command) }
        switch cmd {
        case "wait": delay = n(1)
        case "move": post(.mouseMoved, n(1), n(2))
        case "down": post(.leftMouseDown, n(1), n(2), flags: flags)
        case "up": post(.leftMouseUp, n(1), n(2), flags: flags)
        case "to": post(.leftMouseDragged, n(1), n(2), flags: flags); delay = 0.05
        case "click":
            let count = max(Int(n(3)), 1)
            var queue: [String] = []
            for c in 1...count {
                queue.append("rawdown \(n(1)) \(n(2)) \(c)")
                queue.append("wait 0.06")
                queue.append("rawup \(n(1)) \(n(2)) \(c)")
                queue.append("wait 0.06")
            }
            queue.append("wait 0.3")
            lines = queue + lines
        case "rawdown": post(.leftMouseDown, n(1), n(2), clicks: Int(n(3)), flags: flags); delay = 0
        case "rawup": post(.leftMouseUp, n(1), n(2), clicks: Int(n(3)), flags: flags); delay = 0
        case "drag":
            let x0 = n(1), y0 = n(2), x1 = n(3), y1 = n(4)
            var queue: [String] = ["down \(x0) \(y0)"]
            let steps = 12
            for i in 1...steps { queue.append("to \(x0 + (x1 - x0) * Double(i) / Double(steps)) \(y0 + (y1 - y0) * Double(i) / Double(steps))") }
            queue.append("wait 0.15")
            queue.append("up \(x1) \(y1)")
            queue.append("wait 0.3")
            lines = queue + lines
        case "type":
            guard let w = window() else { break }
            for ch in parts.dropFirst().joined(separator: " ") {
                let s = ch == "~" ? "\r" : String(ch)
                for type in [NSEvent.EventType.keyDown, .keyUp] {
                    if let e = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: w.windowNumber,
                                                context: nil, characters: s, charactersIgnoringModifiers: s, isARepeat: false, keyCode: ch == "~" ? 36 : 0) { w.sendEvent(e) }
                }
            }
            delay = 0.3
        case "undo": app?.document?.undo(); delay = 0.3
        case "redo": app?.document?.redo(); delay = 0.3
        case "select": app?.document?.selectionID = parts[1]; delay = 0.4
        case "curve": app?.document?.activeCurveID = parts[1]; delay = 0.4
        case "tab": app?.bottomTab = Int(n(1)); delay = 0.5
        case "pause": app?.document?.clock.playing = false; app?.document?.clock.time = n(1)
        case "dump": dump(parts.dropFirst().joined(separator: " "))
        case "metal":
            func find(_ v: NSView) -> MTKView? {
                if let m = v as? MTKView { return m }
                for s in v.subviews { if let m = find(s) { return m } }
                return nil
            }
            if let m = window()?.contentView.flatMap(find) {
                m.framebufferOnly = false
                DebugSnapshot.savePath = dir + "/" + parts[1] + ".png"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { DebugSnapshot.wantCapture = true }
            }
            delay = 0.9
        case "show": if parts[1] == "bind" { app?.showBindPoints = n(2) != 0 } else if parts[1] == "emit" { app?.showEmitters = n(2) != 0 } else if parts[1] == "shading" { app?.effectShading = Int(n(2)) }; delay = 0.3
        case "isolate": app?.document?.isolateSelection = n(1) != 0; delay = 0.3
        case "ids":
            func walk(_ n: OutlineNode, _ d: Int) { log.append(String(repeating: " ", count: d) + n.id + "  [" + n.title + "]"); n.children.forEach { walk($0, d + 1) } }
            app?.document?.outline.forEach { walk($0, 0) }
        case "save": app?.save(); delay = 0.4
        case "openfile": app?.open(URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1])); delay = 0.8
        case "action":
            if let node = app?.document?.selectedNode, let action = node.actions.first(where: { $0.title == parts.dropFirst().joined(separator: " ") }) { action.perform() } else { log.append("no action \(parts)") }
            delay = 0.5
        case "set":
            if let doc = app?.document, let node = doc.selectedNode, let field = doc.sections(for: node).flatMap(\.fields).first(where: { $0.id.hasSuffix(parts[1]) }) {
                let old = field.read()
                let new: FieldValue = { switch old { case .bool: return .bool(n(2) != 0); case .int: return .int(Int(n(2))); default: return .double(n(2)) } }()
                doc.commit(field, from: old, to: new)
            } else { log.append("no field \(parts)") }
            delay = 0.4
        case "verify":
            if let doc = app?.document, let parsed = try? AvfxBlock.parseFile([UInt8](doc.serializedData())) {
                log.append("  reparse ok: TmLn0 clips=\(parsed.childrenNamed("TmLn").first?.childrenNamed("Clip").count ?? -1) CpCn=\(parsed.childrenNamed("TmLn").first?.int("CpCn") ?? -1) items=\(parsed.childrenNamed("TmLn").first?.ownRecords("Item").map { r in r.first { $0.tag == "ClNo" }?.intValue ?? -9 } ?? [])")
            } else { log.append("  REPARSE FAILED") }
        case "missing":
            if let doc = app?.document, let node = doc.selectedNode { log.append("  missing fields: " + doc.missingFields(for: node).map(\.title).joined(separator: ", ")) }
        case "addfield":
            if let doc = app?.document, let node = doc.selectedNode, let item = doc.missingFields(for: node).first(where: { $0.title == parts.dropFirst().joined(separator: " ") }) { item.create() } else { log.append("no missing \(parts)") }
            delay = 0.4
        case "unassign":
            if let doc = app?.document, let node = doc.selectedNode, let field = doc.sections(for: node).flatMap(\.fields).first(where: { $0.label == parts.dropFirst().joined(separator: " ") }), let u = field.unassign { u() } else { log.append("no unassign \(parts)") }
            delay = 0.4
        case "tags":
            if let doc = app?.document, let node = doc.selectedNode, case .avfx(let block, _, _) = node.payload {
                let ok = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                log.append("  tags(\(ok ? "reparse ok" : "REPARSE FAILED")): " + (block.children ?? []).map(\.tag).joined(separator: " "))
            }
        case "shot":
            if let w = window(), let view = w.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                do {
                    guard let data = rep.representation(using: .png, properties: [:]) else { log.append("shot: no png"); break }
                    try data.write(to: URL(fileURLWithPath: dir + "/" + parts[1] + ".png"))
                } catch { log.append("shot error \(error)") }
            } else { log.append("shot: no window/rep, windows=\(NSApp.windows.count)") }
        default: log.append("unknown command \(cmd)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { step() }
    }
}

final class TestHost<V: View>: NSHostingView<V> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class TestWindow: NSWindow {
    override var isKeyWindow: Bool { true }
    override var isMainWindow: Bool { true }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
