#if FV_UITEST
import AVFoundation
import AppKit
import MetalKit
import SwiftUI
import VfxCore
import VfxMetal

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
    static var extra: NSWindow?
    static var main: NSWindow?
    static var patched: Set<String> = []
    static var pendingRestore: Data?
    static var menuPath: [String]?
    static var hovered: [NSTrackingArea] = []
    static var menuObserver: NSObjectProtocol?

    static func armMenu(_ path: [String]) {
        menuPath = path
        if menuObserver != nil { return }
        menuObserver = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil) { note in
            guard let root = note.object as? NSMenu, let path = menuPath else { return }
            menuPath = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                var menu = root
                var found: (NSMenu, Int)?
                var trail: [String] = []
                for (depth, name) in path.enumerated() {
                    menu.delegate?.menuNeedsUpdate?(menu)
                    menu.update()
                    trail.append("[" + menu.items.map { $0.isSeparatorItem ? "-" : ($0.title + ($0.state == .on ? "*" : "") + ($0.isEnabled ? "" : "!") + ($0.hasSubmenu ? ">" : "")) }.joined(separator: ", ") + "]")
                    guard let index = menu.items.firstIndex(where: { $0.title == name }) else { break }
                    if depth == path.count - 1 { found = (menu, index) } else if let sub = menu.items[index].submenu { menu = sub } else { break }
                }
                root.cancelTrackingWithoutAnimation()
                log.append("MENU \(path.joined(separator: ">")) \(found == nil ? "not found" : "ok") \(trail.joined(separator: " "))")
                if let (menu, index) = found {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { menu.performActionForItem(at: index) }
                }
            }
        }
    }

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
        if type == .leftMouseDown, let target = content.hitTest(p) {
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
        log.append("== \(label) sel=\(doc.selectionID ?? "-") curve=\(doc.activeCurveID ?? "-") t=\(doc.clock.time) playing=\(doc.clock.playing) dirty=\(doc.isDirty) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-") tab=\(app?.bottomTab ?? -1) changes=\(doc.changes.modified.sorted().prefix(8))+\(doc.changes.added.count) hidden=\(doc.hidden.count) E=\(doc.avfxRoot?.childrenNamed("Emit").count ?? -1) P=\(doc.avfxRoot?.childrenNamed("Ptcl").count ?? -1) file=\(doc.title) notice=\(app?.notice ?? "-") exact=\(String(describing: doc.roundTripExact))")
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
        if parts.contains("alt") { flags.insert(.option) }
        switch cmd {
        case "wait": delay = n(1)
        case "move": post(.mouseMoved, n(1), n(2))
        case "hover":
            if let w = window(), let content = w.contentView {
                w.acceptsMouseMovedEvents = true
                let p = NSPoint(x: n(1), y: Double(content.bounds.height) - n(2))
                let stamp = ProcessInfo.processInfo.systemUptime
                (w as? TestWindow)?.fakeMouse = p
                guard let move = NSEvent.mouseEvent(with: .mouseMoved, location: p, modifierFlags: [], timestamp: stamp, windowNumber: w.windowNumber,
                                                    context: nil, eventNumber: 0, clickCount: 0, pressure: 0) else { break }
                var live: [NSTrackingArea] = []
                func walk(_ view: NSView) {
                    for area in view.trackingAreas {
                        let inside = area.options.contains(.inVisibleRect) ? view.visibleRect.contains(view.convert(p, from: nil)) : area.rect.contains(view.convert(p, from: nil))
                        guard let owner = area.owner as? NSResponder else { continue }
                        let was = hovered.contains { $0 === area }
                        if inside {
                            live.append(area)
                            if !was, let enter = NSEvent.enterExitEvent(with: .mouseEntered, location: p, modifierFlags: [], timestamp: stamp, windowNumber: w.windowNumber, context: nil,
                                                                        eventNumber: 0, trackingNumber: 0, userData: nil) { owner.mouseEntered(with: enter) }
                            if area.options.contains(.mouseMoved) { owner.mouseMoved(with: move) }
                        } else if was, let leave = NSEvent.enterExitEvent(with: .mouseExited, location: p, modifierFlags: [], timestamp: stamp, windowNumber: w.windowNumber, context: nil,
                                                                          eventNumber: 0, trackingNumber: 0, userData: nil) { owner.mouseExited(with: leave) }
                    }
                    view.subviews.forEach(walk)
                }
                walk(content)
                hovered = live
                if parts.contains("log") { log.append("HOVER areas=\(live.count) owners=\(live.map { String(describing: type(of: $0.owner as AnyObject)).prefix(30) }) opts=\(live.map { $0.options.rawValue }) content=\(content.bounds.size) first=\(String(describing: type(of: w.firstResponder as AnyObject)))") }
            }
            delay = 0.15
        case "camstate":
            if let w = DebugDriver.main ?? window(), let content = w.contentView {
                func find(_ v: NSView) -> ViewportMTKView? {
                    if let m = v as? ViewportMTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                if let camera = find(content)?.camera {
                    log.append(String(format: "CAM %@ yaw=%.2f pitch=%.2f dist=%.2f ortho=%@ fov=%.1f", parts.count > 1 ? parts[1] : "", camera.yaw, camera.pitch, camera.distance, camera.ortho ? "true" : "false", camera.fov * 180 / .pi)
                        + " gizmo=\(app?.showGizmo ?? false) highlight=\(app?.highlightSelection ?? false) emitters=\(app?.showEmitters ?? false) bind=\(app?.showBindPoints ?? false) floor=\(app?.showFloor ?? false) lockSeed=\(app?.document?.clock.lockSeed ?? true) seed=\(app?.document?.clock.seed ?? 0) bgColor=\(String(describing: ViewportRenderer.backgroundColor))")
                } else { log.append("CAM none") }
            }
        case "settingswin":
            if let app {
                let w = TestWindow(contentRect: NSRect(x: 80, y: 60, width: 520, height: 900), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.contentView = TestHost(rootView: SettingsView().environmentObject(app))
                w.orderFrontRegardless()
                DebugDriver.extra = w
            }
            delay = 1.0
        case "lookstate":
            let d = UserDefaults.standard
            log.append("LOOK \(parts.count > 1 ? parts[1] : "") " + d.dictionaryRepresentation().filter { $0.key.hasPrefix("look.") || $0.key.hasPrefix("editkey.") || $0.key == "autosave.copies" }.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " "))
        case "keystate":
            if let doc = app?.document, let node = doc.selectedNode, let group = doc.curveGroups(for: node).first(where: { $0.id == doc.activeCurveID }) {
                log.append("KEYS \(parts.count > 1 ? parts[1] : "") " + group.channels.map { c in c.name + ":" + c.read().map { String(format: "%.0f=%.3f/%d(%.2f,%.2f)", $0.time, $0.value, $0.interpolation, $0.tangentOut, $0.tangentIn) }.joined(separator: " ") }.joined(separator: " | ") + " undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-") saved=\(UserDefaults.standard.string(forKey: "curves.saved") ?? "")")
            }
        case "modal":
            if let w = NSApp.modalWindow {
                func walk(_ v: NSView, _ visit: (NSView) -> Void) { visit(v); v.subviews.forEach { walk($0, visit) } }
                var buttons: [NSButton] = []
                var fields: [NSTextField] = []
                if let content = w.contentView {
                    walk(content) { view in
                        if let b = view as? NSButton { buttons.append(b) }
                        if let f = view as? NSTextField, f.isEditable { fields.append(f) }
                    }
                }
                if parts.count > 2, let field = fields.first { field.stringValue = parts[2] == "-" ? "" : parts.dropFirst(2).joined(separator: " ") }
                let title = w.title.isEmpty ? ((w.contentView.map { v -> String in var t = ""; walk(v) { if let f = $0 as? NSTextField, !f.isEditable, t.isEmpty { t = f.stringValue } }; return t }) ?? "") : w.title
                if let button = buttons.first(where: { $0.title.lowercased() == parts[1].lowercased() }) {
                    log.append("MODAL \"\(title)\" buttons=\(buttons.map(\.title)) -> \(button.title)")
                    button.performClick(nil)
                } else {
                    log.append("MODAL \"\(title)\" buttons=\(buttons.map(\.title)) no button \(parts[1])")
                    NSApp.abortModal()
                }
            } else { log.append("MODAL none") }
            delay = 0.5
        case "down": post(.leftMouseDown, n(1), n(2), flags: flags)
        case "up": post(.leftMouseUp, n(1), n(2), flags: flags)
        case "to": post(.leftMouseDragged, n(1), n(2), flags: flags); delay = 0.05
        case "click":
            let count = max(Int(n(3)), 1)
            var queue: [String] = []
            for c in 1...count {
                queue.append("rawdown \(n(1)) \(n(2)) \(c) \(parts.dropFirst(3).joined(separator: " "))")
                queue.append("wait 0.06")
                queue.append("rawup \(n(1)) \(n(2)) \(c) \(parts.dropFirst(3).joined(separator: " "))")
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
        case "savelater":
            let target = app
            let timer = Timer(timeInterval: 0.05, repeats: false) { _ in target?.save() }
            RunLoop.main.add(timer, forMode: .common)
            delay = 0.8
        case "notice": log.append("NOTICE \(app?.notice ?? "-")")
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
        case "export":
            if let doc = app?.document {
                let ids = Set(parts.dropFirst(3))
                let picked = ids.contains("timelines") ? Set(doc.exportableNodes.filter { $0.tag == "TmLn" }.map(\.id)) : ids.contains("lasttimeline") ? Set(doc.exportableNodes.filter { $0.tag == "TmLn" }.suffix(1).map(\.id)) : ids
                let data = doc.exportNodes(picked, withDependencies: n(2) != 0)
                try? data.write(to: URL(fileURLWithPath: dir + "/" + parts[1]))
                log.append("  exported \(data.count) bytes, deps=\(doc.dependencies(of: picked).count)")
            }
        case "import":
            if let doc = app?.document {
                do {
                    let count = try doc.importNodes(Data(contentsOf: URL(fileURLWithPath: dir + "/" + parts[1])), legacy: parts[1].hasSuffix(".vfxedit"))
                    log.append("  imported \(count)")
                } catch { log.append("  IMPORT FAILED \(error)") }
            }
            delay = 0.5
        case "cleanup": log.append("  cleanup removed \(app?.document?.cleanUp() ?? -1)"); delay = 0.4
        case "write": if let doc = app?.document { try? doc.serializedData().write(to: URL(fileURLWithPath: dir + "/" + parts[1])) }
        case "refs":
            if let doc = app?.document, let root = doc.avfxRoot {
                var bad = 0, total = 0
                for tag in ["Schd"] + EffectDocument.exchangeTags {
                    for node in root.childrenNamed(tag) {
                        for r in EffectDocument.nodeReferences(node) { total += 1; let v = r.get(); if v >= root.childrenNamed(r.target).count || v < -1 { bad += 1 } }
                    }
                }
                let reparsed = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                log.append("  refs total=\(total) bad=\(bad) reparse=\(reparsed) unused=\(doc.unusedNodes.map(\.id))")
            }
        case "sheetshot":
            if let sheet = window()?.attachedSheet, let view = sheet.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: dir + "/" + parts[1] + ".png"))
            } else { log.append("no sheet; windows=\(NSApp.windows.count)") }
        case "endframe": app?.document?.clock.endFrame = n(1) > 0 ? n(1) : nil; delay = 0.3
        case "play": app?.document?.clock.playing = true; delay = n(1)
        case "installtex":
            if let app, let doc = app.document, let node = doc.selectedNode, case .avfx(let block, _, _) = node.payload {
                do { let u = try app.installTexture(from: URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1]), for: block, in: doc); log.append("  installed \(u.lastPathComponent) path=\(block.stringValue) info=\(app.image(for: block.stringValue).map { "\($0.width)x\($0.height)" } ?? "nil") \(app.textureDescription(block.stringValue))") } catch { log.append("  INSTALL FAILED \(error)") }
            }
            delay = 0.5
        case "exportpng":
            if let app, let doc = app.document, let node = doc.selectedNode, case .avfx(let block, _, _) = node.payload, let data = app.pngData(for: block.stringValue) { try? data.write(to: URL(fileURLWithPath: dir + "/" + parts[1])); log.append("  png \(data.count) bytes") } else { log.append("  NO PNG") }
        case "check":
            if let app, let doc = app.document {
                var line = "CHECK \(doc.title) exact=\(doc.roundTripExact.map { "\($0)" } ?? "-") status=[\(doc.clock.status)] err=\(app.errorMessage ?? "-") t=\(Int(doc.clock.time)) rows=\(doc.sequencerRows.count) outline=\(doc.outline.count)"
                if let root = doc.avfxRoot {
                    var bad = 0
                    for tag in ["Schd"] + EffectDocument.exchangeTags { for node in root.childrenNamed(tag) { for r in EffectDocument.nodeReferences(node) { let v = r.get(); if v >= root.childrenNamed(r.target).count || v < -1 { bad += 1 } } } }
                    let all = Set(doc.exportableNodes.map(\.id))
                    let exported = doc.exportNodes(all, withDependencies: true)
                    let missingTex = doc.textureSlots.filter { app.textureURL($0.path) == nil }.count
                    var sections = 0, curves = 0
                    func walk(_ n: OutlineNode) { sections += doc.sections(for: n).flatMap(\.fields).count; curves += doc.curveGroups(for: n).count; _ = doc.missingFields(for: n); _ = doc.missingCurves(for: n); n.children.forEach(walk) }
                    doc.outline.forEach(walk)
                    line += " badrefs=\(bad) export=\(exported.count) missingTex=\(missingTex)/\(doc.textureSlots.count) fields=\(sections) curves=\(curves) graph=\(doc.graph.nodes.count)/\(doc.graph.edges.count) same=\(doc.roundTripExact == true ? Data(root.serialized()) == (try? Data(contentsOf: doc.url)) : false)"
                } else {
                    var sections = 0, curves = 0
                    func walk(_ n: OutlineNode) { sections += doc.sections(for: n).flatMap(\.fields).count; curves += doc.curveGroups(for: n).count; n.children.forEach(walk) }
                    doc.outline.forEach(walk)
                    let missing = doc.textureSlots.filter { app.textureURL($0.path) == nil }.map(\.name)
                    line += " fields=\(sections) curves=\(curves) missingTex=\(missing) graph=\(doc.graph.nodes.count)/\(doc.graph.edges.count)"
                }
                log.append(line)
            } else { log.append("CHECK no document err=\(app?.errorMessage ?? "-")") }
        case "selftest":
            if let doc = app?.document {
                func bytes() -> Data { doc.avfxRoot.map { Data($0.serialized()) } ?? Data((doc.jsonRoot?.serialized() ?? "").utf8) }
                let original = bytes()
                let clean = doc.snapshot()
                var ids: [String] = []
                func collect(_ n: OutlineNode) { ids.append(n.id); n.children.forEach(collect) }
                doc.outline.forEach(collect)
                var fields = 0, channels = 0
                var badFields: [String] = [], badChannels: [String] = []
                func reset() { doc.registerUndo("x", since: clean); doc.undo(); doc.rebuildOutline() }
                for id in ids {
                    guard let n = doc.node(id) else { continue }
                    let count = doc.sections(for: n).flatMap(\.fields).count
                    for index in 0..<count {
                        guard let node = doc.node(id) else { break }
                        let list = doc.sections(for: node).flatMap(\.fields)
                        guard index < list.count, let write = list[index].write else { continue }
                        fields += 1
                        let value = list[index].read()
                        write(value)
                        if bytes() != original { badFields.append("\(id) \(list[index].label)=\(value)"); reset() }
                    }
                    let groups = doc.curveGroups(for: n).count
                    for g in 0..<groups {
                        let channelCount = doc.node(id).map { doc.curveGroups(for: $0) }.map { g < $0.count ? $0[g].channels.count : 0 } ?? 0
                        for c in 0..<channelCount {
                            guard let node = doc.node(id) else { break }
                            let all = doc.curveGroups(for: node)
                            guard g < all.count, c < all[g].channels.count else { continue }
                            let channel = all[g].channels[c]
                            channels += 1
                            let keys = channel.read()
                            channel.write(keys)
                            if bytes() != original { badChannels.append("\(all[g].id) \(channel.name) n=\(keys.count)"); reset() }
                        }
                    }
                }
                log.append("SELFTEST \(doc.title) fields=\(fields) channels=\(channels) badFields(\(badFields.count))=\(badFields.prefix(4)) badChannels(\(badChannels.count))=\(badChannels.prefix(4)) clean=\(bytes() == original)")
            }
        case "deeptest":
            if let doc = app?.document, doc.avfxRoot != nil {
                func bytes() -> [UInt8] { doc.avfxRoot?.serialized() ?? [] }
                let original = bytes()
                let clean = doc.snapshot()
                var ids: [(String, String)] = []
                func collect(_ n: OutlineNode) { if case .avfx(_, let cls, _) = n.payload { ids.append((n.id, cls ?? "?")) } else { ids.append((n.id, "?")) }; n.children.forEach(collect) }
                doc.outline.forEach(collect)
                func close(_ a: FieldValue, _ b: FieldValue) -> Bool {
                    switch (a, b) {
                    case (.color(let r, let g, let b1, let a1), .color(let r2, let g2, let b2, let a2)): return abs(r - r2) < 0.006 && abs(g - g2) < 0.006 && abs(b1 - b2) < 0.006 && abs(a1 - a2) < 0.006
                    case (.text(let x), .text(let y)): return x == y
                    case (.bool(let x), .bool(let y)): return x == y
                    default: return abs(a.number - b.number) < 1e-3 * max(1, abs(a.number))
                    }
                }
                func candidates(_ field: PropField, _ old: FieldValue) -> [FieldValue] {
                    switch field.kind {
                    case .choice(let list): return list.filter { $0.value != Int(old.number) }.map { .int($0.value) }
                    case .bool: if case .bool(let on) = old { return [.bool(!on)] }; return [.bool(true)]
                    case .int: return [.int(Int(old.number) + 1), .int(Int(old.number) - 1), .int(0)]
                    case .double: return [.double(old.number + 0.25)]
                    case .angle: return [.double(old.number + 10)]
                    case .color: if case .color(let r, let g, let b, let a) = old { return [.color(r > 0.5 ? r - 0.25 : r + 0.25, g > 0.5 ? g - 0.25 : g + 0.25, b > 0.5 ? b - 0.25 : b + 0.25, a)] }; return []
                    case .text: if case .text(let t) = old { return [.text(t + "x")] }; return []
                    case .info: return []
                    }
                }
                var total = 0, writes = 0
                var readBack: [String: Int] = [:], noFile: [String: Int] = [:], undoBad: [String: Int] = [:], parseBad: [String: Int] = [:], crashGuard = 0
                for (id, cls) in ids {
                    guard let n = doc.node(id) else { continue }
                    let count = doc.sections(for: n).flatMap(\.fields).count
                    for index in 0..<count {
                        guard let node = doc.node(id) else { break }
                        let list = doc.sections(for: node).flatMap(\.fields)
                        guard index < list.count, list[index].write != nil else { continue }
                        let field = list[index]
                        let key = cls + "." + field.label + "[" + field.tag + "]"
                        let old = field.read()
                        total += 1
                        var anyAccepted = false
                        for value in candidates(field, old) {
                            if case .choice = field.kind {} else if anyAccepted { break }
                            guard let live = doc.node(id).map({ doc.sections(for: $0).flatMap(\.fields) }), index < live.count else { break }
                            doc.commit(live[index], from: live[index].read(), to: value)
                            writes += 1
                            let after = doc.node(id).map { doc.sections(for: $0).flatMap(\.fields) }
                            let got = after.flatMap { index < $0.count ? $0[index].read() : nil }
                            let now = bytes()
                            if let got, close(got, value) { anyAccepted = true } else if case .choice = field.kind { readBack[key + "=\(value.number)->\(String(describing: got?.number))", default: 0] += 1 }
                            if now == original { if case .choice = field.kind { noFile[key, default: 0] += 1 } } else {
                                if (try? AvfxBlock.parseFile(now)) == nil { parseBad[key, default: 0] += 1 }
                            }
                            if doc.undoManager.canUndo { doc.undo() }
                            if bytes() != original { undoBad[key, default: 0] += 1; doc.registerUndo("x", since: clean); doc.undo(); doc.rebuildOutline(); crashGuard += 1 }
                            if crashGuard > 40 { break }
                        }
                        if !anyAccepted { readBack[key + " old=\(old)", default: 0] += 1 }
                    }
                }
                func show(_ d: [String: Int]) -> String { d.sorted { $0.key < $1.key }.map { "\($0.key)×\($0.value)" }.joined(separator: " | ") }
                log.append("DEEP \(doc.title) fields=\(total) writes=\(writes) clean=\(bytes() == original)")
                log.append("DEEP readBack(\(readBack.count)): \(show(readBack))")
                log.append("DEEP noFileChange(\(noFile.count)): \(show(noFile))")
                log.append("DEEP undoBad(\(undoBad.count)): \(show(undoBad))")
                log.append("DEEP parseBad(\(parseBad.count)): \(show(parseBad))")
                try? log.joined(separator: "\n").write(toFile: dir + "/partial.txt", atomically: true, encoding: .utf8)
            }
        case "painttest":
            let side = 1024
            let model = TextureEditorModel()
            model.load(TextureImage(width: side, height: side, rgba: [UInt8](repeating: 40, count: side * side * 4)), path: "t", key: "t")
            model.color = SIMD4(1, 0, 0, 1)
            var started = CACurrentMediaTime()
            model.fill(at: CGPoint(x: 10, y: 10))
            let fillTime = CACurrentMediaTime() - started
            let filled = stride(from: 0, to: model.image.rgba.count, by: 4).filter { model.image.rgba[$0] == 255 }.count
            started = CACurrentMediaTime()
            model.checkpoint()
            model.color = SIMD4(0, 1, 0, 1)
            model.stroke(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 900, y: 900), erase: false)
            let strokeTime = CACurrentMediaTime() - started
            let green = model.image.rgba[(500 * side + 500) * 4 + 1]
            model.undo(); model.undo()
            log.append(String(format: "PAINT fill=%.3fs filled=%d/%d stroke=%.3fs green=%d undone=%d", fillTime, filled, side * side, strokeTime, Int(green), Int(model.image.rgba[0])))
        case "namestest":
            if let doc = app?.document, let root = doc.avfxRoot {
                doc.assignNames(["avfx/Ptcl/0": "zero", "avfx/Ptcl/2": "two", "avfx/Ptcl/4": "four", "avfx/Emit/1": "em"])
                let particles = root.childrenNamed("Ptcl")
                doc.deleteTopLevel(particles[1])
                let after = doc.names.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
                doc.undo()
                let undone = doc.names.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
                doc.assignNames(["avfx/Ptcl/0": "", "avfx/Ptcl/2": "", "avfx/Ptcl/4": "", "avfx/Emit/1": ""])
                log.append("NAMES afterDelete=\(after) undone=\(undone) cleared=\(doc.names.count)")
            }
        case "fpsstate":
            if let w = DebugDriver.main ?? window(), let content = w.contentView {
                func find(_ v: NSView) -> MTKView? {
                    if let m = v as? MTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                log.append("FPS \(parts.count > 1 ? parts[1] : "") rate=\(find(content)?.preferredFramesPerSecond ?? -1) playing=\(app?.document?.clock.playing ?? false)")
            }
        case "vnum":
            if let m = ModelEditSession.active {
                let data = m.model.child("VNum")?.data ?? []
                log.append("VNUM \(parts.count > 1 ? parts[1] : "") emit=\(m.emitCount) order=\(stride(from: 0, to: data.count - 1, by: 2).map { Int(data.u16($0)) }) undo=\(m.document.undoManager.canUndo ? m.document.undoManager.undoActionName : "-")")
            }
        case "emitsel":
            if let m = ModelEditSession.active { m.emitSelection = Set(parts.dropFirst().compactMap { Int($0) }) }
        case "emitadd":
            ModelEditSession.active?.addEmitPoints(fromSelection: false)
        case "emitremove":
            ModelEditSession.active?.removeSelectedEmitPoints()
        case "rgbtest":
            if let doc = app?.document, let node = doc.selectedNode, let group = doc.curveGroups(for: node).first(where: { $0.channels.contains { $0.colorComponent != nil } }) {
                let rgb = (0..<3).compactMap { c in group.channels.first { $0.colorComponent == c } }
                func key(_ t: Double, _ v: Double) -> CurveKeyPoint { CurveKeyPoint(time: t, value: v, interpolation: 1, tangentOut: 0, tangentIn: 0) }
                func state() -> String { (0..<3).map { c in rgb[c].read().map { String(format: "%.0f=%.1f", $0.time, $0.value) }.joined(separator: ",") }.joined(separator: " | ") }
                rgb[0].write([key(0, 1), key(10, 0)]); rgb[1].write([key(0, 0), key(10, 0)]); rgb[2].write([key(0, 0), key(10, 1)])
                let start = state()
                var moved = rgb[0].read(); moved[0].time = 15; rgb[0].write(moved)
                log.append("RGB start=[\(start)] movedR0to15=[\(state())]")
            } else { log.append("RGB no colour group") }
        case "origintest":
            if let doc = app?.document, let root = doc.avfxRoot {
                doc.deleteTopLevel(root.childrenNamed("Ptcl")[1])
                let changed = doc.computeChanges()
                let particles = changed.modified.filter { $0.hasPrefix("avfx/Ptcl/") }.sorted()
                doc.undo()
                let back = doc.computeChanges()
                log.append("ORIGIN afterDelete particlesModified=\(particles) added=\(changed.added.sorted().prefix(4)) origins=\(doc.origins) afterUndo modified=\(back.modified.count) origins=\(doc.origins)")
            }
        case "dissolvestate":
            if let sim = ViewportRenderer.main?.player?.simulation {
                let kinds = sim.schema.particles.filter { $0.dissolve != nil }.map { "P\($0.index) target=\($0.dissolve?.target ?? -1) rev=\($0.dissolve?.reverse ?? false) tc1=\($0.tc1?.enabled ?? false)" }
                let live = sim.particles.filter { $0.schema.dissolve != nil }.count
                log.append("DISSOLVE \(parts.count > 1 ? parts[1] : "") schema=\(kinds) live=\(live) state=\(String(describing: sim.dissolve(filter: VisibilityFilter())))")
            } else { log.append("DISSOLVE no simulation") }
        case "setraw":
            if let doc = app?.document, let root = doc.avfxRoot, parts.count >= 6 {
                let owner = root.childrenNamed(parts[1])
                if let index = Int(parts[2]), index < owner.count {
                    let before = doc.snapshot()
                    let holder = parts[3] == "-" ? owner[index] : owner[index].child(parts[3])
                    holder?.child(parts[4])?.intValue = Int(n(5))
                    doc.registerUndo("Raw", since: before)
                }
            }
            delay = 0.4
        case "glbtest":
            if let root = app?.document?.avfxRoot, let model = root.childrenNamed("Modl").first {
                let mesh = Gltf.mesh(from: model)
                var glb = Gltf.glb(mesh, name: "t")
                func bounds(_ m: GltfMesh) -> String {
                    let lo = m.positions.reduce(SIMD3<Float>(repeating: 1e9)) { simd_min($0, $1) }, hi = m.positions.reduce(SIMD3<Float>(repeating: -1e9)) { simd_max($0, $1) }
                    return String(format: "(%.2f,%.2f,%.2f)..(%.2f,%.2f,%.2f) n0=(%.2f,%.2f,%.2f)", lo.x, lo.y, lo.z, hi.x, hi.y, hi.z, m.normals.first?.x ?? 0, m.normals.first?.y ?? 0, m.normals.first?.z ?? 0)
                }
                let plain = URL(fileURLWithPath: dir + "/plain.glb")
                try? Data(glb).write(to: plain)
                let back = try? Gltf.load(plain)
                let jsonLength = Int(glb.u32(12))
                var json = String(decoding: glb[20..<(20 + jsonLength)], as: UTF8.self)
                json = json.replacingOccurrences(of: "\"nodes\":[{\"mesh\":0,", with: "\"nodes\":[{\"mesh\":0,\"translation\":[0,2,0],\"rotation\":[0.7071068,0,0,0.7071068],\"scale\":[2,2,2],")
                var body = Array(json.utf8)
                while body.count % 4 != 0 { body.append(0x20) }
                let rest = Array(glb[(20 + jsonLength)...])
                var out = Array(glb[0..<12])
                out.appendU32(UInt32(body.count)); out.appendU32(0x4E4F534A); out.append(contentsOf: body); out.append(contentsOf: rest)
                out.setU32(8, UInt32(out.count))
                glb = out
                let moved = URL(fileURLWithPath: dir + "/moved.glb")
                try? Data(glb).write(to: moved)
                let turned = try? Gltf.load(moved)
                log.append("GLB source=\(bounds(mesh)) plain=\(back.map(bounds) ?? "FAILED") moved=\(turned.map(bounds) ?? "FAILED") tris=\(mesh.indices.count / 3)/\((back?.indices.count ?? 0) / 3)/\((turned?.indices.count ?? 0) / 3)")
            }
        case "bc1test":
            var pixels: [UInt8] = []
            for y in 0..<4 { for x in 0..<4 { pixels.append(contentsOf: (x + y) % 2 == 0 ? [255, 0, 0, 255] : [0, 255, 0, 255]) } }
            var odd: [UInt8] = []
            for y in 0..<5 { for x in 0..<5 { odd.append(contentsOf: x == 4 || y == 4 ? [0, 0, 255, 255] : [255, 255, 255, 255]) } }
            let small = TextureImage(width: 5, height: 5, rgba: odd).halved()
            let encoded = TextureCodec.encode(TextureImage(width: 4, height: 4, rgba: pixels), format: .bc1, mips: 1)
            if let decoded = try? Atex.decode(encoded) {
                var worst = 0
                for i in 0..<16 { for k in 0..<3 { worst = max(worst, abs(Int(decoded.rgba[i * 4 + k]) - Int(pixels[i * 4 + k]))) } }
                log.append("BC1 redGreen worstError=\(worst) first=\(Array(decoded.rgba.prefix(8))) oddMip=\(small.width)x\(small.height) corner=\(Array(small.rgba.suffix(4)))")
            } else { log.append("BC1 decode failed") }
        case "fuzz":
            if let doc = app?.document {
                var state = UInt64(max(1, n(1))) &* 0x9E3779B97F4A7C15
                func next() -> UInt64 {
                    state &+= 0x9E3779B97F4A7C15
                    var z = state
                    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
                    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
                    return z ^ (z >> 31)
                }
                func pick(_ count: Int) -> Int { count <= 0 ? 0 : Int(next() % UInt64(count)) }
                func bytes() -> Data { doc.avfxRoot.map { Data($0.serialized()) } ?? Data((doc.jsonRoot?.serialized() ?? "").utf8) }
                func nodes() -> [OutlineNode] {
                    var out: [OutlineNode] = []
                    func walk(_ n: OutlineNode) { out.append(n); n.children.forEach(walk) }
                    doc.outline.forEach(walk)
                    return out
                }
                func health() -> String? {
                    if let root = doc.avfxRoot {
                        guard let parsed = try? AvfxBlock.parseFile(root.serialized()) else { return "reparse failed" }
                        let counts = ["TlCn": "TmLn", "EmCn": "Emit", "PrCn": "Ptcl", "EfCn": "Efct", "BdCn": "Bind", "TxCn": "Tex", "MdCn": "Modl"]
                        for (field, tag) in counts where parsed.int(field) != parsed.childrenNamed(tag).count { return "count \(field)=\(parsed.int(field)) vs \(parsed.childrenNamed(tag).count)" }
                        for tag in ["Schd"] + EffectDocument.exchangeTags { for node in root.childrenNamed(tag) { for r in EffectDocument.nodeReferences(node) { let v = r.get(); if v >= root.childrenNamed(r.target).count || v < -1 { return "bad ref \(tag)->\(r.target) \(v)" } } } }
                        let sim = AvfxSimulation(schema: AvfxSchemaReader.read(parsed))
                        sim.restart()
                        for _ in 0..<24 { sim.advance(0.5) }
                        _ = sim.render(camera: CameraState(position: Vec3(0, 2, 8), rotation: simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), fovY: 0.75, viewportHeight: 800))
                    } else if let root = doc.jsonRoot {
                        guard (try? JSONParser.parse(Data(root.serialized().utf8))) != nil else { return "json reparse failed" }
                    }
                    _ = doc.computeChanges()
                    return nil
                }
                let safeActions: Set<String> = ["Duplicate", "Delete", "Move Up", "Move Down", "Add Clip", "Add Item", "Add UV Set", "Delete UV Set", "Remove from File",
                                                "Add Mask Texture", "Add Model Slot", "Delete Clip", "Make Life Infinite", "Hide", "Isolate"]
                let original = bytes()
                var problems: [String] = []
                var tally: [String: Int] = [:]
                let total = max(1, Int(n(2)))
                let baseline = health()
                for step in 0..<total {
                    let all = nodes()
                    guard !all.isEmpty else { break }
                    let node = all[pick(all.count)]
                    var label = ""
                    switch pick(10) {
                    case 0, 1, 2:
                        let fields = doc.sections(for: node).flatMap(\.fields).filter { $0.write != nil }
                        guard !fields.isEmpty else { continue }
                        let field = fields[pick(fields.count)]
                        let old = field.read()
                        var value = old
                        switch field.kind {
                        case .choice(let list): if !list.isEmpty { value = .int(list[pick(list.count)].value) }
                        case .bool: if case .bool(let on) = old { value = .bool(!on) }
                        case .int: value = .int(Int(old.number) + pick(7) - 3)
                        case .double, .angle: value = .double(old.number + Double(pick(200) - 100) / 10)
                        case .color: value = .color(Double(pick(256)) / 255, Double(pick(256)) / 255, Double(pick(256)) / 255, Double(pick(256)) / 255)
                        default: continue
                        }
                        doc.commit(field, from: old, to: value)
                        label = "field \(node.id) \(field.label)"
                    case 3, 4:
                        let groups = doc.curveGroups(for: node)
                        guard !groups.isEmpty else { continue }
                        let group = groups[pick(groups.count)]
                        guard !group.channels.isEmpty else { continue }
                        let channel = group.channels[pick(group.channels.count)]
                        var keys = channel.read()
                        let before = doc.snapshot()
                        switch pick(4) {
                        case 0: keys.append(CurveKeyPoint(time: Double(pick(120)), value: Double(pick(200) - 100) / 20, interpolation: pick(3), tangentOut: 1, tangentIn: 1))
                        case 1: if keys.count > 1 { keys.remove(at: pick(keys.count)) }
                        case 2: if !keys.isEmpty { keys[pick(keys.count)].value += Double(pick(40) - 20) / 10 }
                        default: if !keys.isEmpty { keys[pick(keys.count)].time = Double(pick(120)) }
                        }
                        channel.write(keys)
                        doc.registerUndo("Fuzz Curve", since: before)
                        label = "curve \(group.id) \(channel.name)"
                    case 5:
                        let actions = node.actions.filter { safeActions.contains($0.title) }
                        guard !actions.isEmpty else { continue }
                        let action = actions[pick(actions.count)]
                        action.perform()
                        label = "action \(node.id) \(action.title)"
                    case 6:
                        let missing = doc.missingFields(for: node) + doc.missingCurves(for: node)
                        if !missing.isEmpty, pick(2) == 0 {
                            let item = missing[pick(missing.count)]
                            item.create()
                            label = "create \(node.id) \(item.title)"
                        } else if let field = doc.sections(for: node).flatMap(\.fields).filter({ $0.unassign != nil }).randomElement(), pick(3) == 0 {
                            field.unassign?()
                            label = "unassign \(node.id) \(field.label)"
                        } else { continue }
                    case 7:
                        if doc.avfxRoot != nil, pick(3) == 0 {
                            let tag = ["TmLn", "Emit", "Ptcl", "Efct", "Bind", "Tex"][pick(6)]
                            doc.addTopLevel(tag)
                            label = "add \(tag)"
                        } else if doc.avfxRoot != nil, pick(6) == 0 {
                            label = "cleanup \(doc.cleanUp())"
                        } else { continue }
                    case 8:
                        let count = 1 + pick(3)
                        for _ in 0..<count where doc.undoManager.canUndo { doc.undo() }
                        label = "undo x\(count)"
                    default:
                        let count = 1 + pick(2)
                        for _ in 0..<count where doc.undoManager.canRedo { doc.redo() }
                        label = "redo x\(count)"
                    }
                    tally[String(label.split(separator: " ").first ?? "?"), default: 0] += 1
                    func kind(_ text: String?) -> String { (text ?? "").components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "-"))).joined() }
                    if let problem = health(), kind(problem) != kind(baseline) {
                        problems.append("step \(step) [\(label)]: \(problem)")
                        if problems.count >= 4 { break }
                    }
                }
                var guardCount = 0
                while doc.undoManager.canUndo, guardCount < 2000 { doc.undo(); guardCount += 1 }
                let restored = bytes() == original
                log.append("FUZZ \(doc.title) seed=\(Int(n(1))) ops=\(tally.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }.joined(separator: " ")) undone=\(guardCount) restored=\(restored) problems=\(problems)")
                try? log.joined(separator: "\n").write(toFile: dir + "/partial.txt", atomically: true, encoding: .utf8)
            }
            delay = 0.3
        case "simstate":
            if let sim = ViewportRenderer.main?.player?.simulation, let clock = app?.document?.clock {
                let byTimeline = Dictionary(grouping: sim.emitters, by: \.timeline).mapValues(\.count).sorted { $0.key < $1.key }.map { "T\($0.key):\($0.value)" }
                log.append("SIM \(parts.count > 1 ? parts[1] : "") t=\(String(format: "%.1f", sim.time)) clock=\(String(format: "%.1f", clock.time)) emitters=\(sim.emitters.count) \(byTimeline) particles=\(sim.particles.count) dying=\(sim.emitters.filter { $0.dying != nil }.count)/\(sim.particles.filter { $0.dying != nil }.count) finished=\(sim.finished) held=\(sim.held) default=\(sim.defaultTrigger ?? -1) clips=\(sim.clipLog.map { "\(Int($0.time)):\($0.type)" })")
            } else { log.append("SIM none") }
        case "trigger":
            app?.document?.clock.trigger(Int(n(1)))
        case "matparam":
            if let doc = app?.document, let particle = doc.materialParticleID {
                doc.editMaterial("Param", in: particle) { graph in
                    if let index = graph.nodes.firstIndex(where: { $0.id == parts[1] }) {
                        var params = graph.nodes[index].params ?? [:]
                        params[parts[2]] = n(3)
                        graph.nodes[index].params = params
                    }
                }
            }
        case "markers":
            if let sim = ViewportRenderer.main?.player?.simulation {
                for marker in sim.emitterMarkers().prefix(6) where !marker.points.isEmpty {
                    let reach = marker.points.map { simd_length(SIMD2($0.x, $0.z)) }.max() ?? 0
                    let height = (marker.points.map(\.y).max() ?? 0) - (marker.points.map(\.y).min() ?? 0)
                    log.append(String(format: "MARK %@ E%d radius=%.3f height=%.3f t=%.1f", parts.count > 1 ? parts[1] : "", marker.index, reach, height, sim.time))
                }
            }
        case "stress":
            if let doc = app?.document, doc.avfxRoot != nil {
                func bytes() -> Data { doc.serializedData() }
                func health() -> String? {
                    guard let root = doc.avfxRoot, let parsed = try? AvfxBlock.parseFile([UInt8](bytes())) else { return "reparse failed" }
                    for tag in ["Schd"] + EffectDocument.exchangeTags { for node in root.childrenNamed(tag) { for r in EffectDocument.nodeReferences(node) { let v = r.get(); if v >= root.childrenNamed(r.target).count || v < -1 { return "bad ref \(tag)->\(r.target) \(v)" } } } }
                    let counts = ["TlCn": "TmLn", "EmCn": "Emit", "PrCn": "Ptcl", "EfCn": "Efct", "BdCn": "Bind", "TxCn": "Tex", "MdCn": "Modl"]
                    for (field, tag) in counts where parsed.int(field) != parsed.childrenNamed(tag).count { return "count \(field)=\(parsed.int(field)) vs \(parsed.childrenNamed(tag).count)" }
                    _ = AvfxSimulation(schema: AvfxSchemaReader.read(parsed))
                    return nil
                }
                let original = bytes()
                var problems: [String] = []
                var ops = 0
                for id in doc.exportableNodes.map(\.id) {
                    guard let node = doc.exportableNodes.first(where: { $0.id == id }) else { continue }
                    if node.tag != "Modl" {
                        doc.duplicateTopLevel(node.block); ops += 1
                        if let h = health() { problems.append("dup \(id): \(h)") }
                        doc.undo()
                    }
                    if let fresh = doc.exportableNodes.first(where: { $0.id == id }) {
                        doc.deleteTopLevel(fresh.block); ops += 1
                        if let h = health() { problems.append("del \(id): \(h)") }
                        let sim = AvfxSimulation(schema: AvfxSchemaReader.read(doc.avfxRoot!))
                        sim.restart()
                        for _ in 0..<80 { sim.advance(0.5) }
                        doc.undo()
                    }
                    if bytes() != original { problems.append("undo mismatch after \(id)"); break }
                }
                for tag in ["TmLn", "Emit", "Ptcl", "Efct", "Bind", "Tex"] { doc.addTopLevel(tag); ops += 1; if let h = health() { problems.append("add \(tag): \(h)") } }
                for _ in 0..<6 { doc.undo() }
                log.append("STRESS \(doc.title) ops=\(ops) problems=\(problems.prefix(5)) restored=\(bytes() == original)")
            }
        case "jsonstress":
            if let doc = app?.document, doc.jsonRoot != nil {
                func text() -> String { doc.jsonRoot?.serialized() ?? "" }
                let original = text()
                var ids: [String] = []
                func collect(_ n: OutlineNode) { if !n.actions.isEmpty { ids.append(n.id) }; n.children.forEach(collect) }
                doc.outline.forEach(collect)
                var ops = 0
                var problems: [String] = []
                for id in ids {
                    let titles = doc.node(id)?.actions.map(\.title) ?? []
                    for title in titles {
                        guard let action = doc.node(id)?.actions.first(where: { $0.title == title }) else { continue }
                        let before = doc.undoManager.canUndo
                        action.perform(); ops += 1
                        if (try? JSONParser.parse(Data(text().utf8))) == nil { problems.append("\(id) \(title): invalid json") }
                        if doc.undoManager.canUndo && (!before || doc.undoManager.undoActionName != "") { doc.undo() }
                        if text() != original { problems.append("\(id) \(title): undo mismatch"); doc.undo() }
                        if text() != original { break }
                    }
                    if text() != original { break }
                }
                log.append("JSONSTRESS \(doc.title) nodes=\(ids.count) ops=\(ops) problems=\(problems.prefix(4)) restored=\(text() == original)")
            }
        case "mod":
            if let app, let doc = app.document {
                do {
                    let textures = doc.textureSlots.filter { app.isCustomTexture($0.path) }.map(\.path)
                    let data = try app.modArchive(ModDescription(name: "Test Mod", author: "me"), effectPath: PenumbraExport.guessEffectPath(doc), textures: textures)
                    try data.write(to: URL(fileURLWithPath: dir + "/" + parts[1]))
                    log.append("MOD \(data.count) bytes path=\(PenumbraExport.guessEffectPath(doc)) custom=\(textures)")
                } catch { log.append("MOD FAILED \(error)") }
            }
        case "modsheet": app?.modExport = true; delay = 1.0
        case "cmdkey":
            if let w = window() {
                for type in [NSEvent.EventType.keyDown, .keyUp] {
                    if let e = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [.command], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: w.windowNumber, context: nil, characters: parts[1], charactersIgnoringModifiers: parts[1], isARepeat: false, keyCode: 0) { w.sendEvent(e) }
                }
            }
            delay = 0.4
        case "speed": app?.document?.clock.speed = n(1)
        case "settype":
            if let doc = app?.document, let node = doc.selectedNode,
               let field = doc.sections(for: node).flatMap(\.fields).first(where: { $0.label == "Type" || $0.id.hasSuffix("VT") }) {
                let old = field.read()
                doc.commit(field, from: old, to: .int(Int(n(1))))
                log.append("SETTYPE \(field.id) \(old) -> \(field.read())")
            } else { log.append("SETTYPE no type field") }
            delay = 0.5
        case "repeattest":
            if let app, let doc = app.document, let timeline = doc.avfxRoot?.childrenNamed("TmLn").first {
                let before = doc.serializedData()
                let count = timeline.ownRecords("Item").count, span = doc.timelineSpan(timeline)
                let added = doc.repeatItems(timeline, copies: 2, period: span)
                let after = timeline.ownRecords("Item")
                let ends = after.compactMap { r in r.first { $0.tag == "EdTm" }?.intValue }
                let reparsed = (try? AvfxBlock.parseFile([UInt8](doc.serializedData())))?.childrenNamed("TmLn").first?.ownRecords("Item").count ?? -1
                doc.undo()
                log.append("REPEAT items \(count)->\(after.count) added=\(added) span=\(span) maxEnd=\(ends.max() ?? 0) reparsed=\(reparsed) undo=\(doc.serializedData() == before)")
                let out = URL(fileURLWithPath: dir + "/alltex")
                try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
                let exported = app.exportAllTextures(of: doc, into: out)
                log.append("ALLTEX written=\(exported.written) missing=\(exported.missing.count) files=\((try? FileManager.default.contentsOfDirectory(atPath: out.path).count) ?? -1)")
                log.append("DROP handled=\(app.openDropped([URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/m0050/eff/m0050cr_01c0t.avfx")])) current=\(app.document?.title ?? "-")")
            }
        case "original": app?.document?.showOriginal = n(1) != 0; delay = 0.5
        case "seed": app?.document?.clock.seed = Int(n(1)); delay = 0.5
        case "cliplog": log.append("CLIPLOG \(app?.document?.clock.clipLog ?? [])")
        case "clipsim":
            if let source = app?.document?.avfxRoot {
                let root = source.deepCopy()
                var enabledBefore = 0
                for timeline in root.childrenNamed("TmLn") {
                    let records = timeline.ownRecords("Item")
                    for record in records { if let flag = record.first(where: { $0.tag == "bEna" }) { enabledBefore += flag.intValue != 0 ? 1 : 0; flag.intValue = 1 } }
                    timeline.setOwnRecords("Item", records)
                }
                log.append("CLIPSIM enabledBefore=\(enabledBefore)")
                let simulation = AvfxSimulation(schema: AvfxSchemaReader.read(root))
                simulation.restart()
                for frame in 0..<200 {
                    if frame == 5 { for t in 0..<simulation.schema.triggers.count { simulation.trigger(t) } }
                    if frame == 100 { simulation.release() }
                    simulation.advance(1)
                }
                log.append("CLIPSIM timelines=\(simulation.schema.timelines.map { "items \($0.items.map { "\($0.enabled ? "on" : "off")/clip\($0.clip)/em\($0.emitter)/st\($0.start)" }) clips \($0.clips.map(\.type))" }) sched=\(simulation.schema.scheduler.map { "\($0.enabled)/\($0.timeline)/\($0.start)" }) trg=\(simulation.schema.triggers.map { "\($0.enabled)/\($0.timeline)" })")
                log.append("CLIPSIM triggers=\(simulation.schema.triggers.count) log=\(simulation.clipLog.map { "\(Int($0.time)):\($0.type)" })")
            }
        case "mergetest":
            if let app, let doc = app.document, let root = doc.avfxRoot {
                let before = doc.serializedData()
                func counts() -> [Int] { ["TmLn", "Emit", "Ptcl", "Tex", "Modl"].map { root.childrenNamed($0).count } + [root.child("Schd")?.ownRecords("Item").count ?? -1] }
                let was = counts()
                do {
                    let other = try EffectDocument(url: URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1]))
                    let result = try doc.mergeEffect(other)
                    let reparsed = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                    let bad = doc.outline.isEmpty
                    let now = counts()
                    doc.undo()
                    log.append("MERGE nodes=\(result.nodes) timelines=\(result.timelines) counts \(was)->\(now) reparsed=\(reparsed) outlineEmpty=\(bad) undo=\(doc.serializedData() == before)")
                } catch { log.append("MERGE FAILED \(error.localizedDescription)") }
            }
        case "linktest":
            if let doc = app?.document, let root = doc.avfxRoot {
                let before = doc.serializedData()
                var lines: [String] = []
                func titles(_ a: String, _ b: String) -> String { let r = doc.linkOptions(a, b); return "\(r.options.map(\.title)) \(r.problem ?? "")" }
                lines.append("ptcl1>tex2 " + titles("avfx/Ptcl/1", "avfx/Tex/2"))
                lines.append("tex2>ptcl1 " + titles("avfx/Tex/2", "avfx/Ptcl/1"))
                lines.append("schd>ptcl " + titles("avfx/Schd/0", "avfx/Ptcl/0"))
                lines.append("emit>modl " + titles("avfx/Emit/0", "avfx/Modl/0"))
                lines.append("tmln>bind " + titles("avfx/TmLn/0", "avfx/Bind/0"))
                lines.append("ptcl>modl " + titles("avfx/Ptcl/0", "avfx/Modl/0"))
                let particle = root.childrenNamed("Ptcl")[1]
                let had = particle.child("TC1") != nil
                let problem = doc.connect(from: "avfx/Tex/2", to: "avfx/Ptcl/1")
                let layer = particle.child("TC1")
                lines.append("linked had=\(had) problem=\(problem ?? "-") TxNo=\(layer?.child("TxNo")?.intValue ?? -9) bEna=\(layer?.int("bEna") ?? -9) edges=\(doc.graph.edges.filter { $0.from == "avfx/Ptcl/1" }.map(\.to)) reparse=\((try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil)")
                doc.undo()
                lines.append("undo=\(doc.serializedData() == before)")
                for line in lines { log.append("LINK " + line) }
            }
        case "pixiprint":
            if let doc = app?.document, doc.jsonRoot != nil {
                final class Recorder {
                    var hash: UInt64 = 1469598103934665603
                    var calls = 0
                    func mix(_ text: String) { calls += 1; for b in text.utf8 { hash = (hash ^ UInt64(b)) &* 1099511628211 } }
                }
                final class RecView: ParticleView {
                    let recorder: Recorder
                    init(_ r: Recorder) { recorder = r }
                    func setPlacement(_ m: Affine3, perspective: Double) { recorder.mix("\(m)") }
                    func setColor(_ color: Rgb, brightness: Double, alpha: Double) { recorder.mix("\(color)\(brightness)\(alpha)") }
                    func setUv(_ slot: UvSlot, scaleX: Double, scaleY: Double, scrollX: Double, scrollY: Double, rotation: Double) {}
                    func setNineSlice(borderX: Double, borderY: Double, stretchX: Double, stretchY: Double) {}
                    func setDistortPower(_ power: Double) {}
                    func geometryChanged() {}
                    func destroy() {}
                }
                final class RecFactory: ViewFactory {
                    let recorder: Recorder
                    init(_ r: Recorder) { recorder = r }
                    func hasTexture(_ name: String) -> Bool { true }
                    func textureSize(_ name: String) -> (width: Double, height: Double) { (64, 64) }
                    func createParticleView(_ spec: ParticleViewSpec) -> ParticleView { recorder.mix("new"); return RecView(recorder) }
                }
                let recorder = Recorder()
                let factory = RecFactory(recorder)
                let frames = Int(n(1))
                let start = CACurrentMediaTime()
                if let core = try? EffectCore(json: doc.pixiData(filter: VisibilityFilter()), options: EffectCoreOptions(views: factory, models: [:], seed: 7)) {
                    core.play()
                    for _ in 0..<frames { core.update(1.0 / core.fps) }
                    log.append("PIXIPRINT frames=\(frames) calls=\(recorder.calls) hash=\(String(recorder.hash, radix: 16)) counts=\(core.particleCounts().values.reduce(0, +)) ms=\(Int((CACurrentMediaTime() - start) * 1000))")
                } else { log.append("PIXIPRINT core failed") }
            }
        case "curveset":
            if let doc = app?.document, let node = doc.selectedNode {
                let before = doc.snapshot()
                var hit: [String] = []
                if parts.count > 3, let missing = doc.missingCurves(for: node).first(where: { $0.title == parts[3] }) { missing.create(); hit.append("created") }
                for holder in [node] + node.children {
                    for group in doc.curveGroups(for: holder) where group.tag == parts[1] {
                        for channel in group.channels {
                            channel.write([CurveKeyPoint(time: 0, value: n(2), interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0)])
                            hit.append(channel.name)
                        }
                    }
                }
                doc.registerUndo("Curve", since: before)
                log.append("CURVESET \(parts[1]) \(hit)")
            }
            delay = 0.4
        case "texstats":
            if let app, let doc = app.document {
                for slot in doc.textureSlots {
                    guard let t = app.decodedTexture(for: slot.path) else { log.append("TEXSTATS \(slot.path) nil"); continue }
                    var sum = SIMD4<Double>(0, 0, 0, 0), chroma = 0.0
                    let count = t.width * t.height
                    for i in 0..<count {
                        let r = Double(t.rgba[i * 4]), g = Double(t.rgba[i * 4 + 1]), b = Double(t.rgba[i * 4 + 2]), a = Double(t.rgba[i * 4 + 3])
                        sum += SIMD4(r, g, b, a)
                        chroma += max(r, g, b) - min(r, g, b)
                    }
                    let mean = sum / Double(max(count, 1))
                    log.append("TEXSTATS \(slot.path) \(t.width)x\(t.height) alphaOnly=\(t.alphaOnly) mean=\(Int(mean.x)),\(Int(mean.y)),\(Int(mean.z)),\(Int(mean.w)) chroma=\(Int(chroma / Double(max(count, 1))))")
                }
            }
        case "fieldids":
            if let doc = app?.document, let node = doc.selectedNode {
                log.append("FIELDIDS " + doc.sections(for: node).flatMap(\.fields).map { "\($0.id)=\($0.read())" }.joined(separator: " | "))
            }
        case "looptest":
            if let doc = app?.document {
                let base = doc.format == .avfx ? "avfx/Emit/" : "json/emitters/"
                let ids = parts.dropFirst().map { base + $0 }
                let before = doc.serializedData()
                var out: [String] = []
                func problem(_ a: String, _ b: String) -> String { let r = doc.linkOptions(a, b); return r.options.isEmpty ? "BLOCKED(\(r.problem ?? "-"))" : "ok\(r.options.map(\.title))" }
                out.append("pre \(ids[0])>\(ids[1]) " + problem(ids[0], ids[1]))
                out.append("connect01=\(doc.connect(from: ids[0], to: ids[1]) ?? "done")")
                out.append("connect12=\(doc.connect(from: ids[1], to: ids[2]) ?? "done")")
                out.append("back20 " + problem(ids[2], ids[0]))
                out.append("back10 " + problem(ids[1], ids[0]))
                out.append("self00 " + problem(ids[0], ids[0]))
                out.append("forward02 " + problem(ids[0], ids[2]))
                if let edge = doc.graph.edges.first(where: { $0.from == ids[1] && $0.to == ids[2] }) {
                    out.append("retarget12to0=\(doc.canRetarget(edge, to: ids[0]))")
                }
                if let edge = doc.graph.edges.first(where: { $0.from == ids[0] && $0.to == ids[1] }) {
                    out.append("retarget01to2=\(doc.canRetarget(edge, to: ids[2]))")
                }
                doc.undo(); doc.undo()
                out.append("undo=\(doc.serializedData() == before)")
                for line in out { log.append("LOOP " + line) }
            }
        case "itemwin":
            if let app {
                app.itemEditorTarget = AppModel.itemEditorRoot(parts[1])
                app.document?.selectionID = parts[1]
                let w = TestWindow(contentRect: NSRect(x: 40, y: 60, width: n(2) > 0 ? n(2) : 1320, height: n(3) > 0 ? n(3) : 820), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.contentView = TestHost(rootView: ItemEditorView().environmentObject(app))
                w.orderFrontRegardless()
                DebugDriver.extra = w
                log.append("ITEMWIN root=\(app.itemEditorTarget ?? "-") canOpen=\(app.canOpenEditor(parts[1])) tex=\(app.canOpenEditor("avfx/Tex/0")) info=\(app.canOpenEditor("avfx/AVFX"))")
            }
            delay = 1.2
        case "masscheck":
            let folder = URL(fileURLWithPath: ((dir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent + "/" + parts[1])
            let files = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "avfx" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }.dropFirst(Int(n(2))).prefix(Int(n(3)) > 0 ? Int(n(3)) : 100000)
            let started = CACurrentMediaTime()
            var parseFail: [String] = [], inexact: [String] = [], types: [Int: Int] = [:], unknown: [String: Int] = [:], simulated = 0, drawn = 0
            let catalog = AvfxCatalog.shared
            let progress = URL(fileURLWithPath: dir + "/mass_progress.txt")
            let camera = CameraState(position: Vec3(0, 2, 8), rotation: simd_quatf(angle: 0, axis: Vec3(0, 1, 0)), fovY: 0.75, viewportHeight: 800)
            for (index, url) in files.enumerated() {
                guard let data = try? Data(contentsOf: url) else { continue }
                if index % 50 == 0 { try? "\(index) \(url.lastPathComponent)".write(to: progress, atomically: true, encoding: .utf8) }
                let bytes = [UInt8](data)
                guard let root = try? AvfxBlock.parseFile(bytes) else { parseFail.append(url.lastPathComponent); continue }
                let out = root.serialized()
                if out != bytes { inexact.append(url.lastPathComponent) }
                func walk(_ block: AvfxBlock, _ cls: String?, _ parent: AvfxBlock?) {
                    for child in block.children ?? [] {
                        let childClass = catalog.classOf(child, in: cls, parentBlock: block)
                        if let cls, catalog.classes[cls] != nil, catalog.field(cls, child.tag) == nil, childClass == nil, child.children == nil { unknown[cls + "." + child.tag, default: 0] += 1 }
                        if child.children != nil, childClass != nil { walk(child, childClass, block) }
                    }
                }
                walk(root, "AvfxMain", nil)
                let schema = AvfxSchemaReader.read(root)
                for particle in schema.particles { types[particle.type, default: 0] += 1 }
                if index % Int(max(n(4), 1)) == 0 {
                    let simulation = AvfxSimulation(schema: schema)
                    simulation.restart()
                    for frame in 0..<60 {
                        simulation.advance(1)
                        if frame % 20 == 19 { drawn += simulation.render(camera: camera).count }
                    }
                    simulated += 1
                }
            }
            log.append("MASS files=\(files.count) parseFail(\(parseFail.count))=\(parseFail.prefix(5)) inexact(\(inexact.count))=\(inexact.prefix(5)) simulated=\(simulated) draws=\(drawn)")
            log.append("MASS types=\(types.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" })")
            log.append("MASS unknownFields(\(unknown.count))=\(unknown.sorted { $0.value > $1.value }.prefix(40).map { "\($0.key)×\($0.value)" })")
        case "picktest":
            if let app, let doc = app.document, let w = window(), let content = w.contentView {
                func find(_ v: NSView) -> MTKView? {
                    if let m = v as? MTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                if let view = find(content), let renderer = view.delegate as? ViewportRenderer {
                    doc.selectionID = nil
                    var hits: [String] = []
                    for fx in stride(from: 0.2, through: 0.8, by: 0.1) {
                        for fy in stride(from: 0.2, through: 0.8, by: 0.1) {
                            doc.selectionID = nil
                            renderer.pick(at: CGPoint(x: view.bounds.width * fx, y: view.bounds.height * fy), in: view.bounds.size)
                            if let id = doc.selectionID, !hits.contains(id) { hits.append(id) }
                        }
                    }
                    doc.selectionID = nil
                    renderer.pick(at: CGPoint(x: 2, y: 2), in: view.bounds.size)
                    log.append("PICK hits=\(hits) corner=\(doc.selectionID ?? "none")")
                }
            }
        case "filtertest":
            if let doc = app?.document, let node = doc.node(parts[1]) {
                let fields = doc.sections(for: node).flatMap(\.fields)
                let target = fields.first { if case .double = $0.kind { return $0.write != nil }; return false }
                if let target {
                    let old = target.read()
                    doc.commit(target, from: old, to: .double(old.number + 1.5))
                    let changed = fields.filter { doc.isChanged($0, in: node.id) }.map(\.label)
                    log.append("FILTER changed=\(changed) of \(fields.count) field=\(target.label)")
                }
            }
        case "applyall":
            if let doc = app?.document, let node = doc.node(parts[1]) {
                let before = doc.serializedData()
                let fields = doc.sections(for: node).flatMap(\.fields)
                if let field = fields.first(where: { $0.tag == parts[2] }) {
                    let old = field.read()
                    doc.commit(field, from: old, to: .int(Int(n(3))))
                    let count = doc.applyToSiblings(field, in: node.id)
                    let values = ([node] + doc.siblingNodes(of: node.id)).map { n in doc.sections(for: n).flatMap(\.fields).first { $0.tag == parts[2] }?.read().number ?? -99 }
                    doc.undo()
                    doc.undo()
                    log.append("APPLYALL \(field.label) siblings=\(doc.siblingNodes(of: node.id).count) set=\(count) values=\(values) undo=\(doc.serializedData() == before)")
                } else { log.append("APPLYALL no field") }
            }
        case "sel":
            let item = app?.document?.avfxRoot?.childrenNamed("Emit").first?.ownRecords("ItPr").first?.first { $0.tag == "bEnb" }
            log.append("SEL \(app?.document?.selectionID ?? "-") enabled0=\(item?.intValue ?? -9) window=\(DebugDriver.own?.contentView?.bounds.size ?? .zero)")
        case "itemmain":
            if let app, let w = DebugDriver.own {
                app.itemEditorTarget = AppModel.itemEditorRoot(parts[1])
                app.document?.selectionID = parts[1]
                w.contentView = TestHost(rootView: ItemEditorView().environmentObject(app))
            }
            delay = 1.5
        case "expand": app?.bottomExpanded = n(1) != 0; delay = 0.6
        case "hit":
            if let w = window(), let content = w.contentView {
                let p = NSPoint(x: n(1), y: Double(content.bounds.height) - n(2))
                var chain: [String] = []
                var v = content.hitTest(p)
                while let view = v { chain.append("\(NSStringFromClass(Swift.type(of: view)).suffix(28))[\(Int(view.frame.width))x\(Int(view.frame.height))]"); v = view.superview }
                log.append("HITCHAIN \(parts[1]),\(parts[2]): " + chain.prefix(7).joined(separator: " < "))
            }
        case "gizmo":
            if let doc = app?.document, let w = window(), let content = w.contentView {
                func find(_ v: NSView) -> MTKView? {
                    if let m = v as? MTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                if let view = find(content), let renderer = view.delegate as? ViewportRenderer {
                    let origin = view.convert(NSPoint.zero, to: nil)
                    func screen(_ p: Vec3) -> String {
                        let clip = renderer.lastViewProjection * SIMD4<Float>(p.x, p.y, p.z, 1)
                        let x = Double((clip.x / clip.w) * 0.5 + 0.5) * Double(view.bounds.width) + Double(origin.x)
                        let y = Double((clip.y / clip.w) * 0.5 + 0.5) * Double(view.bounds.height) + Double(origin.y)
                        return "\(Int(x)),\(Int(Double(content.bounds.height) - y))"
                    }
                    let list = renderer.gizmo.handles.map { h in "k\(h.kind)a\(h.axis)@\(screen(h.points[h.points.count / 2 == 0 ? 0 : h.points.count - 1]))/mid@\(screen((h.points[0] + h.points[h.points.count - 1]) * 0.5))" }
                    let node = doc.node(renderer.gizmo.rootID ?? "")
                    let values = node.map { n in doc.sections(for: n).flatMap(\.fields).filter { $0.id.contains("#transform") }.map { String(format: "%.3f", $0.read().number) } } ?? []
                    var radius: [String] = []
                    if let n = node {
                        for child in n.children { for g in doc.curveGroups(for: child) where ["RB", "RE", "WID", "Rads", "Rad", "IjA", "Len"].contains(g.tag) { radius.append("\(g.tag)=\(g.channels.first?.read().map { String(format: "%.3f", $0.value) } ?? [])") } }
                    }
                    log.append("GIZMO radius=\(radius)")
                    log.append("GIZMO root=\(renderer.gizmo.rootID ?? "-") handles=\(list) transform=\(values) dirty=\(doc.isDirty)")
                    let index = Int(renderer.gizmo.rootID?.split(separator: "/").last ?? "") ?? -1
                    let body = renderer.lastDraws.first { $0.particle == index && !$0.isSprite }.map { screen(Math3D.position($0.model)) } ?? "-"
                    log.append("GIZMO origin@\(screen(renderer.gizmo.origin)) body@\(body)")
                    if parts.count >= 3, let handle = renderer.gizmo.handles.first(where: { $0.kind == (parts.count > 4 ? Int(n(4)) : 0) && $0.axis == Int(n(1)) }) {
                        let a = screen(handle.points[0]).split(separator: ",").compactMap { Double($0) }
                        let b = screen(handle.points[handle.points.count - 1]).split(separator: ",").compactMap { Double($0) }
                        let dx = b[0] - a[0], dy = b[1] - a[1], len = max(1, hypot(dx, dy))
                        let grab = parts.count > 3 ? n(3) : 0.92
                        let sx = a[0] + dx * grab, sy = a[1] + dy * grab
                        let local = view.convert(NSPoint(x: sx, y: Double(content.bounds.height) - sy), from: nil)
                        let hit = renderer.gizmoHandle(at: CGPoint(x: local.x, y: local.y)).map { "k\($0.kind)a\($0.axis)" } ?? "none"
                        log.append("GIZMO drag axis \(Int(n(1))) dir=\(String(format: "%.2f,%.2f", dx / len, dy / len)) hit=\(hit)")
                        lines = ["drag \(sx) \(sy) \(sx + dx / len * n(2)) \(sy + dy / len * n(2))"] + lines
                    }
                }
            }
        case "presettest":
            if let doc = app?.document, let node = doc.node(parts[1]), let other = doc.node(parts[2]) {
                let before = doc.serializedData()
                let url = ParameterClipboard.savePreset("ztest", from: node, in: doc)
                let listed = ParameterClipboard.presets(for: other).map(\.name)
                let changed = url.map { ParameterClipboard.applyPreset($0, to: other, in: doc) } ?? false
                let same = ParameterClipboard.presets(for: node).first.map { ParameterClipboard.applyPreset($0.url, to: node, in: doc) } ?? true
                let fieldsA = doc.sections(for: node).flatMap(\.fields).filter { $0.write != nil }, fieldsB = doc.sections(for: other).flatMap(\.fields)
                var equal = 0, total = 0
                for f in fieldsA { let tail = String(f.id.dropFirst(node.id.count)); if let g = fieldsB.first(where: { $0.id == other.id + tail }) { total += 1; if g.read() == f.read() { equal += 1 } } }
                doc.undo()
                if let url { try? FileManager.default.removeItem(at: url) }
                log.append("PRESET listed=\(listed) appliedChanged=\(changed) selfChanged=\(same) equal=\(equal)/\(total) undo=\(doc.serializedData() == before)")
            }
        case "histtest":
            if let app, let doc = app.document, let node = doc.node("avfx/Ptcl/0") {
                let before = doc.serializedData()
                let fields = doc.sections(for: node).flatMap(\.fields).filter { if case .double = $0.kind { return $0.write != nil }; return false }
                for field in fields.prefix(3) { doc.commit(field, from: field.read(), to: .double(field.read().number + 1)) }
                let after3 = doc.serializedData()
                let titles = doc.undoTitles
                doc.jumpHistory(to: 1)
                let mid = (doc.undoTitles.count, doc.redoTitles.count)
                doc.jumpHistory(to: 3)
                let back = doc.serializedData() == after3
                doc.jumpHistory(to: 0)
                log.append("HISTORY titles=\(titles) mid=\(mid) redoRestores=\(back) zero=\(doc.serializedData() == before) redo=\(doc.redoTitles.count)")
                var mips: [String] = []
                if let slot = doc.textureSlots.first, let url = app.textureURL(slot.path), let data = try? Data(contentsOf: url) {
                    for level in 0..<4 { if let d = try? Atex.decode([UInt8](data), mip: level) { mips.append("\(d.width)x\(d.height)") } }
                }
                PreviewRules.set("trails", false)
                let off = PreviewRules.isOn("trails")
                PreviewRules.set("trails", true)
                log.append("MIPS \(mips) ruleOff=\(off) ruleOn=\(PreviewRules.isOn("trails")) thumb=\(app.thumbnailURL(for: doc.url)?.lastPathComponent ?? "-") exists=\(app.thumbnail(for: doc.url) != nil)")
            }
        case "settingswin":
            if let app {
                let w = TestWindow(contentRect: NSRect(x: 40, y: 60, width: 520, height: 620), styleMask: [.titled], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.contentView = TestHost(rootView: SettingsView().environmentObject(app))
                w.orderFrontRegardless()
                DebugDriver.extra = w
            }
            delay = 1.2
        case "browser": UserDefaults.standard.set(Int(n(1)), forKey: "browser.mode"); delay = 0.6
        case "stagedtest":
            if let app, let doc = app.document {
                var lines: [String] = []
                let names = ["glow", "smoke", "ring", "quarter_ring", "star", "fire", "noise", "white", "unknown_xyz"]
                lines.append("placeholders=\(names.map { "\($0):\(PlaceholderTextures.url(for: $0) != nil)" })")
                if let root = doc.avfxRoot, let model = root.childrenNamed("Modl").first {
                    let data = app.flatModelJSON(model)
                    let json = try? JSONParser.parse(data)
                    let mesh = json.map { MeshData.fromPixiModel($0) }
                    let source = MeshData.fromAvfx(model)
                    lines.append("flat bytes=\(data.count) vertices=\(mesh?.vertices.count ?? -1)/\(source.vertices.count) indices=\(mesh?.indices.count ?? -1)/\(source.indices.count)")
                }
                lines.append("assets textures=\(app.textureAssets.count) models=\(app.modelAssets.count) thumb=\(app.textureAssets.first.map { app.assetImage($0.url) != nil } ?? false)")
                if doc.avfxRoot != nil, let asset = app.textureAssets.first(where: { $0.relative.contains("m0050") }) {
                    let before = doc.serializedData(), count = doc.textureSlots.count
                    let index = app.addTextureAsset(asset.url, to: doc)
                    lines.append("addAsset index=\(index ?? -1) count \(count)->\(doc.textureSlots.count) path=\(doc.textureSlots.last?.path ?? "-")")
                    doc.undo()
                    lines.append("undo=\(doc.serializedData() == before)")
                }
                if doc.jsonRoot != nil, let node = doc.outline.first?.children.first?.children.first ?? doc.outline.first, let text = doc.jsonText(of: node) {
                    let before = doc.serializedData()
                    let bad = (try? doc.applyJSON("{ broken", to: node)) == nil
                    try? doc.applyJSON(text, to: node)
                    lines.append("json node=\(node.id) chars=\(text.count) badRejected=\(bad) sameAfterApply=\(doc.serializedData() == before) params=\(doc.effectParams.map(\.name))")
                }
                for line in lines { log.append("STAGED " + line) }
            }
        case "stageetest":
            if let app, let doc = app.document {
                var lines: [String] = []
                do {
                    let data = try app.workspaceArchive()
                    let archive = URL(fileURLWithPath: dir + "/ws.zip")
                    try data.write(to: archive)
                    let out = URL(fileURLWithPath: dir + "/wsout")
                    try? FileManager.default.removeItem(at: out)
                    let count = try app.extractWorkspaceArchive(archive, into: out)
                    let relative = String(doc.url.standardizedFileURL.path.dropFirst((app.libraryRoot?.standardizedFileURL.path.count ?? 0) + 1))
                    let copy = try? Data(contentsOf: out.appendingPathComponent(relative))
                    lines.append("workspace bytes=\(data.count) extracted=\(count) effectSame=\(copy == doc.serializedData()) hasList=\(FileManager.default.fileExists(atPath: out.path + "/workspace.fvworkspace"))")
                    let modRoot = URL(fileURLWithPath: dir + "/mods")
                    try FileManager.default.createDirectory(at: modRoot.appendingPathComponent("My Mod/vfx/x/eff"), withIntermediateDirectories: true)
                    try Data("{\"Name\":\"My Mod\",\"Author\":\"me\"}".utf8).write(to: modRoot.appendingPathComponent("My Mod/meta.json"))
                    try doc.serializedData().write(to: modRoot.appendingPathComponent("My Mod/vfx/x/eff/a.avfx"))
                    lines.append("mods=\(app.penumbraMods(in: modRoot).map { "\($0.name)/\($0.author)/\($0.effects)" })")
                } catch { lines.append("FAILED \(error.localizedDescription)") }
                doc.sourcePath = "vfx/test/eff/src.avfx"
                app.rememberGamePath("VFX\\Test\\eff\\Src.avfx")
                let meta = (try? String(contentsOf: doc.url.deletingPathExtension().appendingPathExtension("fvmeta.json"), encoding: .utf8)) ?? "-"
                lines.append("paths recent=\(app.recentGamePaths.prefix(1)) meta=\(meta.prefix(120))")
                doc.sourcePath = ""
                for line in lines { log.append("STAGEE " + line) }
            }
        case "gamefile":
            if let app {
                let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles")
                var lines: [String] = []
                for name in ["vfx_sample.tmb", "instrument02_end.tmb", "vfx_sample.pap", "material.pap", "eid_m0598b0001.eid"] {
                    guard let file = try? GameFileDocument(url: root.appendingPathComponent(name)) else { lines.append("\(name): missing"); continue }
                    switch file.kind {
                    case .tmb, .pap:
                        let blocks = file.tmbBlocks
                        let covered = blocks.reduce(0) { $0 + $1.items.reduce(12) { $0 + $1.size } }
                        var text = "\(name): blocks=\(blocks.count) items=\(blocks.map { $0.items.count }) magics=\(Set(blocks.flatMap { $0.items.map(\.magic) }).sorted().prefix(12)) anims=\(GameFiles.papAnimations(file.bytes).map(\.name))"
                        if let block = blocks.first(where: { $0.items.contains { $0.magic == "C012" } }), let item = block.items.first(where: { $0.magic == "C012" }),
                           let path = GameFiles.offsetString(file.bytes, item: item, field: 20) {
                            let shorter = String(path.text.dropLast(2)) + "x"
                            file.setPath(item: item, field: 20, to: shorter)
                            let after = GameFiles.offsetString(file.bytes, item: item, field: 20)?.text ?? "-"
                            file.setPath(item: item, field: 20, to: path.text + "_too_long")
                            let longer = GameFiles.offsetString(file.bytes, item: item, field: 20)?.text ?? "-"
                            let grown = file.tmbBlocks.first.map { $0.size == file.bytes.count && $0.items.count == block.items.count } ?? false
                            text += " longer=\(longer == path.text + "_too_long") grownValid=\(grown) bytes=\(file.original.count)->\(file.bytes.count)"
                            if file.kind == .tmb { file.revert(); file.setPath(item: item, field: 20, to: shorter) }
                            let refused = file.note != nil
                            file.setInt(item.offset + 12, 77)
                            let reparsed = file.tmbBlocks.first { $0.id == block.id }?.items.count == block.items.count
                            text += " c012=\(path.text) dur=\(GameFiles.i32(file.original, item.offset + 12)) edited=\(after) refusedLong=\(refused) reparsed=\(reparsed) sameSize=\(file.bytes.count == file.original.count) dirty=\(file.dirty)"
                            if let copy = try? app.writeGameFileCopy(file) {
                                text += " copy=\(copy.lastPathComponent) originalIntact=\((try? Data(contentsOf: file.url)).map { [UInt8]($0) == file.original } ?? false)"
                                try? FileManager.default.removeItem(at: copy)
                            }
                            file.revert()
                        }
                        lines.append(text + " headerCovered=\(covered)")
                    case .eid:
                        if let parsed = GameFiles.eidPoints(file.bytes) {
                            let same = GameFiles.eidBytes(parsed.points, new: parsed.new, header: file.original) == file.original
                            var list = parsed.points
                            list[0].position.x += 1
                            file.setPoints(list, new: parsed.new)
                            let back = GameFiles.eidPoints(file.bytes)?.points.first?.position.x ?? -99
                            lines.append("\(name): new=\(parsed.new) points=\(parsed.points.count) first=\(parsed.points[0].pointID)/\(parsed.points[0].bone) roundTrip=\(same) editedX=\(back - parsed.points[0].position.x)")
                        }
                    default: lines.append("\(name): strings=\(GameFiles.strings(file.bytes).count)")
                    }
                }
                for line in lines { log.append("GAMEFILE " + line) }
            }
        case "gamefilewin":
            if let app {
                app.gameFile = try? GameFileDocument(url: URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles/" + parts[1]))
                let w = TestWindow(contentRect: NSRect(x: 40, y: 60, width: 1000, height: 640), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.contentView = TestHost(rootView: GameFileView().environmentObject(app))
                w.orderFrontRegardless()
                DebugDriver.extra = w
                if parts.count > 2 { app.gameFile?.selection = Int(n(2)) }
            }
            delay = 1.2
        case "skeleton":
            if let app {
                do {
                    let result = try app.loadSkeleton(URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles/" + parts[1]))
                    let points = AvfxSimulation.bindPoints
                    let heights = AvfxSimulation.skeletonLines.map { max($0.0.y, $0.1.y) }
                    log.append("SKELETON bones=\(result.bones) points=\(result.points) lines=\(AvfxSimulation.skeletonLines.count) top=\(String(format: "%.2f", heights.max() ?? 0)) sample=\(points.sorted { $0.key < $1.key }.prefix(4).map { "\($0.key):(\(String(format: "%.2f,%.2f,%.2f", $0.value.x, $0.value.y, $0.value.z)))" })")
                    app.showBindPoints = true
                } catch { log.append("SKELETON FAILED \(error.localizedDescription)") }
            }
            delay = 0.8
        case "rawsummary":
            let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles")
            if let m = try? Data(contentsOf: root.appendingPathComponent("sample.mtrl")), let summary = GameFiles.mtrlSummary([UInt8](m)) {
                var copy = [UInt8](m)
                if let at = GameFiles.mtrlStringOffset(copy, slot: 0), let old = summary.textures.first {
                    let ok = GameFiles.setString(&copy, at: at, old: old, new: String(old.dropLast(5)) + "x.tex")
                    let long = GameFiles.setString(&copy, at: at, old: old, new: old + "zz")
                    log.append("MTRLEDIT ok=\(ok) long=\(long) now=\(GameFiles.mtrlSummary(copy)?.textures.first ?? "-") others=\(GameFiles.mtrlSummary(copy)?.textures.dropFirst() == summary.textures.dropFirst()) size=\(copy.count == m.count)")
                }
                log.append("MTRL shader=\(summary.shader) textures=\(summary.textures.count) first=\(summary.textures.first ?? "-") uv=\(summary.uvSets) color=\(summary.colorSets)")
            }
            if let m = try? Data(contentsOf: root.appendingPathComponent("sample.mdl")), let summary = GameFiles.mdlSummary([UInt8](m)) {
                log.append("MDL \(summary.map { "\($0.label)=\($0.value.replacingOccurrences(of: "\n", with: ";"))" }.joined(separator: " ").prefix(420))")
            }
        case "shapetest":
            if let doc = app?.document, doc.jsonRoot != nil {
                let before = doc.serializedData()
                var added: [String] = []
                for index in EffectDocument.shapeTemplates.indices { if let id = doc.addShapeParticle(index) { added.append(id) } }
                doc.connect(from: "json/emitters/0", to: doc.selectionID ?? "")
                log.append("SHAPES added=\(added) particles=\(doc.jsonRoot?["particles"]?.elements?.count ?? -1)")
                DebugDriver.pendingRestore = before
            }
            delay = 1.5
        case "shapedone":
            if let doc = app?.document { log.append("SHAPES status=\(doc.clock.status)"); while doc.undoManager.canUndo { doc.undo() }; log.append("SHAPES undo=\(DebugDriver.pendingRestore == doc.serializedData())") }
        case "pathtest":
            if let app, let doc = app.document {
                let folder = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles")
                let result = AppModel.timelines(containing: Array("cmcn_shoot1c.avfx".utf8), in: folder)
                log.append("PATHS guess=\(app.guessGamePath(for: doc) ?? "-") timelineHits=\(result.hits.map(\.lastPathComponent)) scanned=\(result.scanned)")
            }
        case "tmbmass":
            let folder = URL(fileURLWithPath: ((dir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent + "/" + parts[1])
            let files = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "tmb" }
            var total = 0, unknown: [String: Int] = [:], sizeMismatch: [String: Int] = [:], clean = 0, duplicated = 0, removed = 0, created = 0, bad: [String] = []
            for url in files {
                guard let data = try? Data(contentsOf: url) else { continue }
                let bytes = [UInt8](data)
                guard let block = GameFiles.tmbBlocks(bytes).first, block.offset == 0 else { bad.append("noblock " + url.lastPathComponent); continue }
                total += 1
                for item in block.items {
                    if let type = TmbCatalog.types[item.magic] { if type.size != item.size { sizeMismatch[item.magic, default: 0] += 1 } } else { unknown[item.magic, default: 0] += 1 }
                }
                if !TmbCatalog.problems(bytes).isEmpty { bad.append("orig " + url.lastPathComponent + " " + (TmbCatalog.problems(bytes).first ?? "")); continue }
                clean += 1
                guard TmbCatalog.canRestructure(bytes, block) == nil, let entry = block.items.first(where: { $0.magic.hasPrefix("C") }) else { continue }
                guard let grown = TmbCatalog.duplicate(bytes, block: block, index: entry.id), let grownBlock = GameFiles.tmbBlocks(grown).first else { bad.append("dup " + url.lastPathComponent); continue }
                if !TmbCatalog.problems(grown).isEmpty || grownBlock.items.count != block.items.count + 1 || grownBlock.size != grown.count { bad.append("dupcheck " + url.lastPathComponent + " " + (TmbCatalog.problems(grown).first ?? "count")); continue }
                duplicated += 1
                guard let copy = grownBlock.items.first(where: { $0.offset == entry.offset + entry.size }), let back = TmbCatalog.remove(grown, block: grownBlock, index: copy.id),
                      let backBlock = GameFiles.tmbBlocks(back).first else { bad.append("rem " + url.lastPathComponent); continue }
                let sameItems = backBlock.items.map { "\($0.magic)#\($0.itemID)@\($0.offset)" } == block.items.map { "\($0.magic)#\($0.itemID)@\($0.offset)" }
                var sameStrings = true
                for (a, c) in zip(block.items, backBlock.items) {
                    for field in TmbCatalog.types[a.magic]?.fields ?? [] where field.type == "OffsetString" {
                        if GameFiles.offsetString(bytes, item: a, field: field.at)?.text != GameFiles.offsetString(back, item: c, field: field.at)?.text { sameStrings = false }
                    }
                    for field in TmbCatalog.types[a.magic]?.fields ?? [] where field.type == "OffsetTimeline" {
                        if TmbCatalog.idList(bytes, item: a, field: field.at).ids != TmbCatalog.idList(back, item: c, field: field.at).ids { sameStrings = false }
                    }
                }
                if !TmbCatalog.problems(back).isEmpty || !sameItems || !sameStrings { bad.append("remcheck " + url.lastPathComponent); continue }
                removed += 1
                if let track = block.items.first(where: { $0.magic == "TMTR" }) {
                    var made = 0
                    for magic in ["C012", "C010", "C063", "C094"] {
                        if let next = TmbCatalog.create(bytes, block: block, magic: magic, track: track.id), let nextBlock = GameFiles.tmbBlocks(next).first,
                           TmbCatalog.problems(next).isEmpty, nextBlock.items.count == block.items.count + 1, nextBlock.size == next.count,
                           nextBlock.items.last?.magic == magic { made += 1 }
                    }
                    if made == 4 { created += 1 } else { bad.append("create " + url.lastPathComponent) }
                }
            }
            var containers = 0
            for url in files {
                guard let data = try? Data(contentsOf: url) else { continue }
                let bytes = [UInt8](data)
                guard let block = GameFiles.tmbBlocks(bytes).first, block.offset == 0, TmbCatalog.problems(bytes).isEmpty, TmbCatalog.canRestructure(bytes, block) == nil,
                      let list = block.items.first(where: { $0.magic == "TMAL" }) else { continue }
                guard let one = TmbCatalog.createContainer(bytes, block: block, parent: list.id), let oneBlock = GameFiles.tmbBlocks(one).first, TmbCatalog.problems(one).isEmpty,
                      let actor = oneBlock.items.last(where: { $0.magic == "TMAC" }), TmbCatalog.isEmptyContainer(one, actor),
                      let two = TmbCatalog.createContainer(one, block: oneBlock, parent: actor.id), let twoBlock = GameFiles.tmbBlocks(two).first, TmbCatalog.problems(two).isEmpty,
                      let track = twoBlock.items.last(where: { $0.magic == "TMTR" }), TmbCatalog.isEmptyContainer(two, track),
                      let three = TmbCatalog.create(two, block: twoBlock, magic: "C012", track: track.id), let threeBlock = GameFiles.tmbBlocks(three).first, TmbCatalog.problems(three).isEmpty,
                      threeBlock.items.count == block.items.count + 3, threeBlock.size == three.count,
                      let entry = threeBlock.items.last, let back1 = TmbCatalog.remove(three, block: threeBlock, index: entry.id), let b1 = GameFiles.tmbBlocks(back1).first,
                      let t1 = b1.items.last(where: { $0.magic == "TMTR" }), let back2 = TmbCatalog.remove(back1, block: b1, index: t1.id), let b2 = GameFiles.tmbBlocks(back2).first,
                      let a1 = b2.items.last(where: { $0.magic == "TMAC" }), let back3 = TmbCatalog.remove(back2, block: b2, index: a1.id), let b3 = GameFiles.tmbBlocks(back3).first,
                      TmbCatalog.problems(back3).isEmpty, b3.items.map({ "\($0.magic)#\($0.itemID)@\($0.offset)" }) == block.items.map({ "\($0.magic)#\($0.itemID)@\($0.offset)" })
                else { bad.append("container " + url.lastPathComponent); continue }
                containers += 1
            }
            log.append("TMBMASS containers=\(containers)")
            log.append("TMBMASS created=\(created)")
            log.append("TMBMASS files=\(total) clean=\(clean) duplicated=\(duplicated) removedBack=\(removed) unknown=\(unknown.sorted { $0.value > $1.value }.prefix(8).map { "\($0.key)×\($0.value)" }) sizeMismatch=\(sizeMismatch) bad(\(bad.count))=\(bad.prefix(5))")
        case "gfpoke":
            if let file = app?.gameFile {
                let at = Int(n(1))
                var edited = file.bytes
                if at < edited.count { edited[at] ^= 0xFF }
                file.bytes = edited
                log.append("GFPOKE dirty=\(file.dirty) changed=\(file.changedBytes) unsaved=\(file.unsaved)")
            }
        case "gfundo":
            if let file = app?.gameFile { file.undo(); log.append("GFUNDO dirty=\(file.dirty) changed=\(file.changedBytes)") }
        case "gfstate":
            if let file = app?.gameFile { log.append("GFSTATE items=\(file.tmbBlocks.first?.items.map(\.magic) ?? []) sel=\(file.selection) bytes=\(file.bytes.count) dirty=\(file.dirty) problems=\(TmbCatalog.problems(file.bytes).count) note=\(file.note ?? "-")") }
        case "papmass":
            let folder = URL(fileURLWithPath: ((dir as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent + "/" + parts[1])
            let files = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "pap" }
            var total = 0, identity = 0, edited = 0, bad: [String] = [], noBlocks = 0
            for url in files {
                guard let data = try? Data(contentsOf: url) else { continue }
                let bytes = [UInt8](data)
                let blocks = GameFiles.tmbBlocks(bytes)
                total += 1
                guard let first = blocks.first else { noBlocks += 1; continue }
                guard GameFiles.papReplacing(bytes, block: first, with: Array(bytes[first.offset..<(first.offset + first.size)])) == bytes else { bad.append("identity " + url.lastPathComponent); continue }
                identity += 1
                guard let target = blocks.last, let entry = target.items.first(where: { $0.magic.hasPrefix("C") }) else { continue }
                guard let grown = TmbCatalog.duplicate(bytes, block: target, index: entry.id) else { bad.append("dup " + url.lastPathComponent); continue }
                let grownBlocks = GameFiles.tmbBlocks(grown)
                guard grownBlocks.count == blocks.count, TmbCatalog.problems(grown).isEmpty, let grownTarget = grownBlocks.last, grownTarget.items.count == target.items.count + 1,
                      GameFiles.papAnimations(grown).map(\.name) == GameFiles.papAnimations(bytes).map(\.name) else { bad.append("dupcheck " + url.lastPathComponent); continue }
                guard let copy = grownTarget.items.first(where: { $0.itemID == (target.items.map(\.itemID).max() ?? 0) + 1 }),
                      let back = TmbCatalog.remove(grown, block: grownTarget, index: copy.id), TmbCatalog.problems(back).isEmpty,
                      GameFiles.tmbBlocks(back).map({ $0.items.count }) == blocks.map({ $0.items.count }) else { bad.append("rem " + url.lastPathComponent); continue }
                if blocks.count > 1, let firstEntry = blocks[0].items.first(where: { $0.magic.hasPrefix("C") }) {
                    guard let mid = TmbCatalog.duplicate(bytes, block: blocks[0], index: firstEntry.id), GameFiles.tmbBlocks(mid).count == blocks.count,
                          TmbCatalog.problems(mid).isEmpty else { bad.append("mid " + url.lastPathComponent); continue }
                }
                edited += 1
            }
            log.append("PAPMASS files=\(total) noTimelines=\(noBlocks) identity=\(identity) edited=\(edited) bad(\(bad.count))=\(bad.prefix(5))")
        case "floor": app?.showFloor = n(1) != 0; delay = 0.4
        case "lights":
            if let app, let doc = app.document, let root = doc.avfxRoot {
                let schema = AvfxSchemaReader.read(root)
                let simulation = AvfxSimulation(schema: schema)
                var peak = 0, total = 0
                for _ in 0..<120 { simulation.advance(1); let l = simulation.lights(); peak = max(peak, l.count); total += l.count }
                log.append("LIGHTS effectors=\(schema.effectors.map(\.type)) links=\(schema.emitterEffectors) peak=\(peak) frames=\(total) soft=\(schema.particles.filter(\.softParticle).count) range=\(schema.softFadeRange) usc=\(schema.particles.filter { $0.tc1?.screenCopy == true }.count) poly=\(schema.particles.filter { $0.polyline != nil }.count)")
            }
        case "posttest":
            if let app, let doc = app.document, let root = doc.avfxRoot {
                let schema = AvfxSchemaReader.read(root)
                let simulation = AvfxSimulation(schema: schema)
                var peak = 0, frames = 0, quake: Float = 0, kinds = Set<Int>(), strongest: ScreenEffect?
                for _ in 0..<240 {
                    simulation.advance(1)
                    let r = simulation.screenEffects(camera: Vec3(0, 2, 8))
                    peak = max(peak, r.effects.count); if !r.effects.isEmpty { frames += 1 }
                    quake = max(quake, r.quake)
                    for e in r.effects { kinds.insert(e.kind); if e.strength > (strongest?.strength ?? 0) { strongest = e } }
                }
                log.append("POST effectors=\(schema.effectors.map(\.type)) links=\(schema.emitterEffectors) peak=\(peak) frames=\(frames) kinds=\(kinds.sorted()) quake=\(quake) strongest=\(strongest.map { "s=\($0.strength) len=\($0.length) in=\($0.inner) out=\($0.outer) ang=\($0.angle)" } ?? "-")")
            }
        case "catalog":
            if let app {
                let counts = GameCatalog.kinds.map { "\($0.key)=\(GameCatalog.lines($0.key).count)" }
                let found = GameCatalog.search("npc", "m0016 avfx")
                let local = GameCatalog.lines("npc").compactMap { $0.split(separator: "\t").last.map(String.init) }.first { $0.hasSuffix(".avfx") && app.locateGameFile($0) != nil }
                if let local { app.openCatalogPath(local) }
                app.openCatalogPath("vfx/none/eff/none.avfx")
                log.append("CATALOG \(counts) m0016=\(found.total) first=\(found.rows.first?.path ?? "-") localHit=\(local ?? "-") opened=\(app.document?.url.lastPathComponent ?? "-") gamePath=\(app.document?.gamePath ?? "-") missNote=\(app.catalogNote ?? "-")")
            }
        case "catalogsheet": app?.showCatalog = n(1) != 0; delay = 0.8
        case "mdlmass":
            let root = URL(fileURLWithPath: parts[1])
            var total = 0, ok = 0, bad: [String] = [], triangles = 0, odd = 0
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker where url.pathExtension == "mdl" {
                    if total >= Int(n(2)) { break }
                    guard let data = try? Data(contentsOf: url) else { continue }
                    total += 1
                    if let parsed = GameModel.parse([UInt8](data)) {
                        ok += 1; triangles += parsed.mesh.indices.count / 3
                        if let box = parsed.mesh.bounds, simd_length(box.max - box.min) > 200 || !(box.min.x.isFinite && box.max.x.isFinite) { odd += 1 }
                    } else if bad.count < 6 { bad.append(url.lastPathComponent) }
                }
            }
            log.append("MDLMASS files=\(total) parsed=\(ok) triangles=\(triangles) oddBounds=\(odd) failed=\(bad)")
        case "tablemass":
            let root = URL(fileURLWithPath: parts[1])
            var atch = 0, atchExact = 0, atchStable = 0, mtrl = 0, mtrlOK = 0, tables = 0, keys = 0, constants = 0, samplers = 0, bad: [String] = [], skl = 0, sklOK = 0
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker {
                    guard ["atch", "mtrl", "sklb"].contains(url.pathExtension), let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data)
                    if url.pathExtension == "atch" {
                        atch += 1
                        guard let table = AtchTable.parse(b) else { bad.append(url.lastPathComponent); continue }
                        let out = table.serialized()
                        if out == b { atchExact += 1 }
                        if let again = AtchTable.parse(out), again.serialized() == out, again.entries.map(\.name) == table.entries.map(\.name),
                           again.entries.map({ $0.states.map(\.bone) }) == table.entries.map({ $0.states.map(\.bone) }) { atchStable += 1 } else { bad.append("re " + url.lastPathComponent) }
                    } else if url.pathExtension == "mtrl" {
                        mtrl += 1
                        guard let layout = MtrlLayout.parse(b) else { bad.append(url.lastPathComponent); continue }
                        mtrlOK += 1; if layout.rows > 0 { tables += 1 }; keys += layout.keys.count; constants += layout.constants.count; samplers += layout.samplers.count
                        if Int(b.u16(4)) != b.count, bad.count < 8 { bad.append("size " + url.lastPathComponent) }
                    } else {
                        skl += 1; if GameSkeleton.parse(b) != nil { sklOK += 1 }
                    }
                }
            }
            var halfBad = 0
            for raw in stride(from: 0, to: 0x7C00, by: 7) { if CurveMath.floatToHalf(CurveMath.halfToFloat(UInt16(raw))) != UInt16(raw) { halfBad += 1 } }
            log.append("TABLEMASS atch=\(atch) exact=\(atchExact) stable=\(atchStable) mtrl=\(mtrl) parsed=\(mtrlOK) withTable=\(tables) keys=\(keys) constants=\(constants) samplers=\(samplers) sklb=\(skl)/\(sklOK) halfBad=\(halfBad) bad(\(bad.count))=\(bad.prefix(6))")
        case "recordmass":
            let root = URL(fileURLWithPath: parts[1])
            var phyb = 0, phybOK = 0, phybEmpty = 0, phybRecords = 0, skp = 0, skpOK = 0, skpRecords = 0, bad: [String] = [], names = 0, badNames = 0, sections: [String: Int] = [:]
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker {
                    guard ["phyb", "skp"].contains(url.pathExtension), let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data)
                    let records = url.pathExtension == "phyb" ? GameRecords.phyb(b) : GameRecords.skp(b)
                    if url.pathExtension == "phyb" { phyb += 1 } else { skp += 1 }
                    guard let records else { if bad.count < 8 { bad.append(url.lastPathComponent) }; continue }
                    if url.pathExtension == "phyb" { phybOK += 1; phybRecords += records.count; if records.isEmpty { phybEmpty += 1 } } else { skpOK += 1; skpRecords += records.count }
                    for record in records {
                        sections[record.title.split(separator: " ").first.map(String.init) ?? "", default: 0] += 1
                        for field in record.fields {
                            if case .text(let length, _) = field.kind {
                                names += 1
                                let text = GameFiles.string(b, field.at, max: length)
                                if text.utf8.contains(where: { $0 < 0x20 || $0 > 0x7E }) { badNames += 1 }
                            }
                        }
                    }
                }
            }
            log.append("RECORDMASS phyb=\(phyb) parsed=\(phybOK) empty=\(phybEmpty) records=\(phybRecords) skp=\(skp) parsed=\(skpOK) records=\(skpRecords) names=\(names) badNames=\(badNames) kinds=\(sections.sorted { $0.value > $1.value }.prefix(14).map { "\($0.key)×\($0.value)" }) bad(\(bad.count))=\(bad)")
        case "imcmass":
            let root = URL(fileURLWithPath: parts[1])
            var total = 0, ok = 0, exactSize = 0, withVfx = 0, records = 0, bad: [String] = []
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker where url.pathExtension == "imc" {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data); total += 1
                    guard let list = GameRecords.imc(b) else { if bad.count < 6 { bad.append(url.lastPathComponent) }; continue }
                    ok += 1; records += list.count
                    if 4 + list.count * 6 == b.count { exactSize += 1 }
                    if list.contains(where: { $0.title.contains("vfx") }) { withVfx += 1 }
                }
            }
            log.append("IMCMASS files=\(total) parsed=\(ok) sizeMatches=\(exactSize) withVfx=\(withVfx) records=\(records) bad=\(bad)")
        case "imcopen":
            if let app {
                let table = URL(fileURLWithPath: parts[1])
                let found = app.variantEffect(of: table, number: Int(n(2)))
                app.openVariantEffect(of: table, number: Int(n(2)))
                log.append("IMCOPEN found=\(found?.lastPathComponent ?? "-") doc=\(app.document?.url.lastPathComponent ?? "-") miss=\(app.variantEffect(of: table, number: 77)?.lastPathComponent ?? "none")")
            }
            delay = 1
        case "rebuildmass":
            let root = URL(fileURLWithPath: parts[1])
            var phyb = 0, phybModel = 0, phybExact = 0, phybOps = 0, mtrl = 0, mtrlExact = 0, mtrlOps = 0, imc = 0, imcOps = 0, bad: [String] = []
            func note(_ text: String) { if bad.count < 10 { bad.append(text) } }
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker {
                    guard ["phyb", "mtrl", "imc"].contains(url.pathExtension), let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data)
                    switch url.pathExtension {
                    case "phyb":
                        phyb += 1
                        guard let model = PhybModel.parse(b) else { if b.count > 16 { note("parse " + url.lastPathComponent) }; continue }
                        phybModel += 1
                        guard model.serialized() == b else { note("exact " + url.lastPathComponent); continue }
                        phybExact += 1
                        guard let records = GameRecords.phyb(b) else { note("records " + url.lastPathComponent); continue }
                        var fine = true
                        for record in records {
                            guard let slot = record.slot else { continue }
                            guard let grown = GameRecords.phybDuplicate(b, slot), let grownRecords = GameRecords.phyb(grown), grownRecords.count > records.count,
                                  let back = GameRecords.phybRemove(grown, slot), back == b else { fine = false; note("dup \(record.title) " + url.lastPathComponent); break }
                        }
                        let additions: [PhybAddition] = [.shape(0), .shape(1), .shape(2), .shape(3), .shape(4), .simulator]
                        for addition in additions {
                            guard let grown = GameRecords.phybAdd(b, addition, near: nil), let list = GameRecords.phyb(grown), list.count == records.count + 1 else { fine = false; note("add " + url.lastPathComponent); break }
                        }
                        if let one = GameRecords.phybAdd(b, .simulator, near: nil), let m = PhybModel.parse(one) {
                            let s = RecordSlot.parameters(simulator: m.simulators.count - 1)
                            var current = one
                            for list in 0..<8 { if let next = GameRecords.phybAdd(current, .item(list), near: s) { current = next } else { fine = false } }
                            let c = RecordSlot.chain(simulator: m.simulators.count - 1, index: 0)
                            for addition in [PhybAddition.chainCollision, .node, .node] { if let next = GameRecords.phybAdd(current, addition, near: c) { current = next } else { fine = false } }
                            if let list = GameRecords.phyb(current), list.count == records.count + 1 + 8 + 3, PhybModel.parse(current)?.serialized() == current,
                               let removed = GameRecords.phybRemove(current, s), removed == (model.hasSimulation ? b : removed), GameRecords.phyb(removed)?.count == records.count {} else { fine = false; note("build " + url.lastPathComponent) }
                        } else { fine = false }
                        if fine { phybOps += 1 }
                    case "mtrl":
                        mtrl += 1
                        guard let model = MtrlModel.parse(b) else { note("mparse " + url.lastPathComponent); continue }
                        guard model.serialized() == b else { note("mexact " + url.lastPathComponent); continue }
                        mtrlExact += 1
                        var grown = model
                        grown.textures.append(("chara/common/texture/a_very_long_new_texture_path_for_testing_d.tex", 0))
                        grown.keys.append((0x1234, 0x5678)); grown.constants.append((0xABCD, [Float(1).bitPattern, Float(2).bitPattern])); grown.samplers.append([UInt8](repeating: 1, count: 12))
                        let out = grown.serialized()
                        if let again = MtrlModel.parse(out), again.serialized() == out, again.textures.count == model.textures.count + 1, again.textures.last?.path == grown.textures.last?.path,
                           again.constants.last?.values.count == 2, again.shader == model.shader, again.data == model.data, MtrlLayout.parse(out) != nil, Int(out.u16(4)) == out.count {
                            var back = again; back.textures.removeLast(); back.keys.removeLast(); back.constants.removeLast(); back.samplers.removeLast()
                            if back.serialized() == b { mtrlOps += 1 } else { note("mback " + url.lastPathComponent) }
                        } else { note("mgrow " + url.lastPathComponent) }
                    default:
                        imc += 1
                        let count = Int(b.u16(0))
                        if let grown = GameRecords.imcAdd(b, after: count), Int(grown.u16(0)) == count + 1, GameRecords.imc(grown)?.count == (GameRecords.imc(b)?.count ?? -9) + GameRecords.imcParts(b),
                           let back = GameRecords.imcRemove(grown, variant: count + 1), back == b, GameRecords.imcRemove(b, variant: 0) == nil { imcOps += 1 } else { note("imc " + url.lastPathComponent) }
                    }
                }
            }
            log.append("REBUILDMASS phyb=\(phyb) model=\(phybModel) exact=\(phybExact) ops=\(phybOps) mtrl=\(mtrl) exact=\(mtrlExact) ops=\(mtrlOps) imc=\(imc) ops=\(imcOps) bad(\(bad.count))=\(bad)")
        case "skpmass":
            let root = URL(fileURLWithPath: parts[1])
            var total = 0, model = 0, exact = 0, ops = 0, atch = 0, atchOps = 0, bad: [String] = []
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data)
                    if url.pathExtension == "skp" {
                        total += 1
                        guard let m = SkpModel.parse(b) else { if bad.count < 8 { bad.append("parse " + url.lastPathComponent) }; continue }
                        model += 1
                        guard m.serialized() == b else { if bad.count < 8 { bad.append("exact " + url.lastPathComponent) }; continue }
                        exact += 1
                        var fine = true
                        for record in GameRecords.skp(b) ?? [] {
                            guard let slot = record.skp else { continue }
                            guard let grown = GameRecords.skpEdit(b, slot, remove: false), grown.count > b.count, (GameRecords.skp(grown)?.count ?? 0) > (GameRecords.skp(b)?.count ?? 0),
                                  let back = GameRecords.skpEdit(grown, slot, remove: true), back == b else { fine = false; break }
                        }
                        if !m.groups.isEmpty, let grown = GameRecords.skpAddElement(b, group: 0), GameRecords.skp(grown)?.count != (GameRecords.skp(b)?.count ?? 0) + 1 { fine = false }
                        if fine { ops += 1 } else if bad.count < 8 { bad.append("ops " + url.lastPathComponent) }
                    } else if url.pathExtension == "atch", var table = AtchTable.parse(b) {
                        atch += 1
                        table.addEntry(after: 0)
                        let grown = table.serialized()
                        if var again = AtchTable.parse(grown), again.entries.count == table.entries.count, again.entries[1].name == "new" {
                            again.removeEntry(1)
                            if again.serialized() == b { atchOps += 1 }
                        }
                    }
                }
            }
            log.append("SKPMASS skp=\(total) model=\(model) exact=\(exact) ops=\(ops) atch=\(atch) ops=\(atchOps) bad(\(bad.count))=\(bad)")
        case "physics":
            if let app {
                let url = URL(fileURLWithPath: parts[1])
                if let file = try? GameFileDocument(url: url) { app.togglePhysics(file); log.append("PHYSICS lines=\(AvfxSimulation.physicsLines.count) shown=\(app.physicsShown?.lastPathComponent ?? "-") note=\(file.note ?? "-") skeleton=\(app.loadedSkeleton?.names.count ?? -1)") }
            }
            delay = 0.8
        case "batchtest":
            if let app {
                let root = (dir as NSString).deletingLastPathComponent + "/gamefiles/"
                if let file = try? GameFileDocument(url: URL(fileURLWithPath: root + "vfx_sample.tmb")) {
                    let original = file.bytes
                    file.setShort(20, 77); let one = file.bytes
                    file.setShort(22, 55)
                    file.undo(); let u1 = file.bytes == one
                    file.undo(); let u2 = file.bytes == original
                    file.redo(); let r1 = file.bytes == one
                    file.revert(); file.undo()
                    var moved = "-"
                    let source = original
                    if let first = GameFiles.tmbBlocks(source).first, let entry0 = first.items.first(where: { $0.magic.hasPrefix("C") }),
                       let original = TmbCatalog.duplicate(source, block: first, index: entry0.id), let block = GameFiles.tmbBlocks(original).first, let listAt = TmbCatalog.listField("TMTR") {
                        for track in block.items where track.magic == "TMTR" {
                            let ids = TmbCatalog.idList(original, item: track, field: listAt).ids
                            guard ids.count >= 2, let entry = block.items.first(where: { $0.itemID == ids[0] }) else { continue }
                            if let down = TmbCatalog.move(original, block: block, index: entry.id, by: 1), let b2 = GameFiles.tmbBlocks(down).first, let t2 = b2.items.first(where: { $0.offset == track.offset }) {
                                let after = TmbCatalog.idList(down, item: t2, field: listAt).ids
                                let back = TmbCatalog.move(down, block: b2, index: entry.id, by: -1)
                                moved = "\(ids)→\(after) back=\(back == original) edge=\(TmbCatalog.move(original, block: block, index: entry.id, by: -1) == nil) problems=\(TmbCatalog.problems(down).count)"
                            }
                            break
                        }
                    }
                    let archive = try? app.gameFileModArchive(file, gamePath: "chara/action/test/vfx_sample.tmb")
                    let bad = (try? app.gameFileModArchive(file, gamePath: "")) == nil
                    log.append("BATCH undo=\(u1),\(u2) redo=\(r1) canUndo=\(file.canUndo) move=\(moved) mod=\(archive?.count ?? -1) zip=\(archive.map { $0.prefix(2).elementsEqual([0x50, 0x4B]) } ?? false) emptyPathRejected=\(bad)")
                }
                if let pap = try? GameFileDocument(url: URL(fileURLWithPath: root + "vfx_sample.pap")), let at = GameFiles.papAnimationOffset(pap.bytes, index: 0) {
                    let before = GameFiles.papAnimations(pap.bytes)
                    let raw = Array("renamed_anim".utf8); for slot in 0..<32 { pap.bytes[at + slot] = slot < raw.count ? raw[slot] : 0 }
                    pap.setShort(at + 32, 3)
                    let after = GameFiles.papAnimations(pap.bytes)
                    log.append("PAPEDIT before=\(before.first?.name ?? "-")/\(before.first?.type ?? -1) after=\(after.first?.name ?? "-")/\(after.first?.type ?? -1) count=\(before.count)=\(after.count) timelines=\(GameFiles.tmbBlocks(pap.bytes).count) size=\(pap.bytes.count == pap.original.count)")
                }
                log.append("GAMEFILES listed=\(app.gameFiles.count) kinds=\(Dictionary(grouping: app.gameFiles, by: { $0.url.pathExtension }).mapValues(\.count).sorted { $0.key < $1.key }.map { "\($0.key)×\($0.value)" })")
            }
        case "findtest":
            if let app {
                let effects = app.files.filter(\.isAvfx).map(\.url)
                var name = "-"
                if let doc = app.document, let root = doc.avfxRoot, let tex = root.childrenNamed("Tex").first { name = (tex.stringValue as NSString).lastPathComponent }
                let hits = AppModel.files(containing: Array(name.lowercased().utf8), among: effects)
                let none = AppModel.files(containing: Array("zz_not_there.atex".utf8), among: effects)
                app.findFiles(containing: name, effects: true)
                log.append("FIND name=\(name) effects=\(effects.count) hits=\(hits.count) includesOpen=\(hits.contains(app.document?.url ?? URL(fileURLWithPath: "/"))) none=\(none.count)")
            }
            delay = 2.5
        case "findstate": if let app { log.append("FINDSTATE title=\(app.timelineHitsTitle) hits=\(app.timelineHits?.count ?? -1) notice=\(app.notice ?? "-")"); app.timelineHits = nil }
        case "kdbmass":
            let root = URL(fileURLWithPath: parts[1])
            var total = 0, ok = 0, records = 0, hashes = 0, named = 0, covered = 0, size = 0, kinds: [String: Int] = [:], bad: [String] = [], sane = 0, doubles = 0
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker where url.pathExtension == "kdb" {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data); total += 1
                    guard let list = GameRecords.kdb(b) else { if bad.count < 8 { bad.append(url.lastPathComponent) }; continue }
                    ok += 1; records += list.count; size += b.count
                    var used = [Bool](repeating: false, count: b.count)
                    for record in list {
                        if record.section == "Nodes" || record.section == "Connections" { let words = record.title.split(separator: " ").dropFirst().prefix(3).joined(separator: " "); if !words.hasSuffix("Data"), !words.hasPrefix("Bone"), !words.hasPrefix("Weight"), !words.hasPrefix("Offset"), !words.hasPrefix("Value"), !words.hasPrefix("Expression") { kinds[String(words.prefix(18)), default: 0] += 1 } }
                        for field in record.fields {
                            for i in field.at..<min(b.count, field.at + RecordBuilder.size(field.kind)) { used[i] = true }
                            switch field.kind {
                            case .hash: if field.name == "Bone" || field.name == "Link" { hashes += 1; if b.u32(field.at) == 0 || !GameRecords.hashText(b.u32(field.at)).hasPrefix("0x") { named += 1 } }
                            case .double, .doubles:
                                let count = RecordBuilder.size(field.kind) / 8
                                for k in 0..<count { doubles += 1; let v = Double(bitPattern: UInt64(b.u32(field.at + k * 8)) | UInt64(b.u32(field.at + k * 8 + 4)) << 32); if v.isFinite, abs(v) < 1e6, v == 0 || abs(v) > 1e-9 { sane += 1 } }
                            default: break
                            }
                        }
                    }
                    covered += used.filter { $0 }.count
                }
            }
            log.append("KDBMASS files=\(total) parsed=\(ok) records=\(records) hashes=\(hashes) named=\(named) doubles=\(doubles) sane=\(sane) covered=\(covered)/\(size) kinds=\(kinds.sorted { $0.value > $1.value }.prefix(14).map { "\($0.key)×\($0.value)" }) bad(\(bad.count))=\(bad)")
        case "kdbrebuild":
            let root = URL(fileURLWithPath: parts[1])
            var total = 0, model = 0, exact = 0, ops = 0, bad: [String] = []
            if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                for case let url as URL in walker where url.pathExtension == "kdb" {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let b = [UInt8](data); total += 1
                    guard let m = KdbModel.parse(b) else { if bad.count < 8 { bad.append("parse " + url.lastPathComponent) }; continue }
                    model += 1
                    let again = m.serialized()
                    guard again == b else { if bad.count < 8 { let d = zip(again, b).enumerated().first { $0.element.0 != $0.element.1 }?.offset ?? -1; bad.append("exact \(url.lastPathComponent) diff@\(d) sizes \(again.count)/\(b.count) nodes=\(m.nodes.count) B=\(m.itemsB.count / 112)@\(m.tableB) E=\(m.itemsE.count / 20) F=\(m.itemsF.count / 8)") }; continue }
                    exact += 1
                    var fine = true
                    let before = GameRecords.kdb(b)?.count ?? -1
                    for index in stride(from: 0, to: m.nodes.count, by: max(1, m.nodes.count / 12)) {
                        guard let grown = GameRecords.kdbDuplicate(b, node: index), let g = KdbModel.parse(grown), g.nodes.count == m.nodes.count + 1, g.serialized() == grown,
                              (GameRecords.kdb(grown)?.count ?? -1) > before else { fine = false; break }
                        let copy = m.isConnection(index) ? index + 1 : m.nodes.count
                        guard let back = GameRecords.kdbRemove(grown, node: copy), let r = KdbModel.parse(back), r.nodes.map(\.head) == m.nodes.map(\.head), r.nodes.map(\.body) == m.nodes.map(\.body),
                              r.itemsB == m.itemsB, r.itemsF == m.itemsF, back.count == b.count || !m.aligned || m.gap.isEmpty else { fine = false; break }
                        if !m.isConnection(index), let cut = GameRecords.kdbRemove(b, node: index), let c = KdbModel.parse(cut) {
                            let limit = c.nodes.count
                            for slot in c.nodes.indices where c.isConnection(slot) { if Int(c.nodes[slot].body.u32(8)) >= limit || Int(c.nodes[slot].body.u32(28)) >= limit { fine = false } }
                            if GameRecords.kdb(cut) == nil || c.nodes.count >= m.nodes.count { fine = false }
                        }
                    }
                    if fine { ops += 1 } else if bad.count < 8 { bad.append("ops " + url.lastPathComponent) }
                }
            }
            log.append("KDBREBUILD files=\(total) model=\(model) exact=\(exact) ops=\(ops) bad(\(bad.count))=\(bad)")
        case "ordertest":
            let p = Vec3(1, 2, 3), s = Vec3(2, 3, 4), q = Math3D.euler(Vec3(0.3, -0.7, 1.1), order: 0), v = Vec3(0.5, -1, 2)
            func scaled(_ x: Vec3) -> Vec3 { x * s }
            func turned(_ x: Vec3) -> Vec3 { q.act(x) }
            func moved(_ x: Vec3) -> Vec3 { x + p }
            let expected: [Vec3] = [moved(turned(scaled(v))), turned(scaled(moved(v))), scaled(moved(turned(v))), scaled(turned(moved(v))), turned(moved(scaled(v))), moved(scaled(turned(v)))]
            var worst: Float = 0
            for order in 0..<6 { worst = max(worst, simd_length(Math3D.point(Math3D.compose(p, q, s, order: order), v) - expected[order])) }
            let same = Math3D.compose(p, q, s, order: 0) == Math3D.compose(p, q, s)
            var orders: [Int: Int] = [:]
            var particleOrders: [Int: Int] = [:]
            if let root = app?.document?.avfxRoot { let r = AvfxSchemaReader.read(root); for e in r.emitters { orders[e.coordOrder, default: 0] += 1 }; for q in r.particles { particleOrders[q.coordOrder, default: 0] += 1 } }
            log.append("ORDER worst=\(worst) defaultSame=\(same) emitterOrders=\(orders.sorted { $0.key < $1.key }) particleOrders=\(particleOrders.sorted { $0.key < $1.key }) rules=\(PreviewRules.all.count)")
        case "density":
            if let doc = app?.document {
                let d = doc.density
                log.append("DENSITY rev=\(doc.densityRevision)/\(doc.revision) keys=\(d.keys.sorted()) frames=\(d["*"]?.count ?? 0) peak=\(d.mapValues { Int($0.max() ?? 0) }.sorted { $0.key < $1.key }.map { "\($0.key):\($0.value)" }) rows=\(doc.sequencerRows.map { $0.densityKey })")
            }
        case "perf":
            if let app {
                let start = CACurrentMediaTime()
                for _ in 0..<200 { _ = app.recentFiles; _ = app.favorites; _ = Theme.light; _ = app.libraryGroups(filter: "", category: "") }
                log.append("PERF 200 rounds of top-bar getters and browser groups: \(String(format: "%.1f", (CACurrentMediaTime() - start) * 1000)) ms, files=\(app.files.count)")
            }
        case "fullshot":
            if let w = window(), let view = w.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                func find(_ v: NSView) -> MTKView? {
                    if let m = v as? MTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                let size = view.bounds.size
                let base = NSImage(size: size); base.addRepresentation(rep)
                let out = NSImage(size: size)
                out.lockFocus()
                base.draw(in: NSRect(origin: .zero, size: size))
                if let m = find(view), let metal = NSImage(contentsOfFile: dir + "/" + parts[2] + ".png") {
                    var rect = m.convert(m.bounds, to: view)
                    if view.isFlipped { rect.origin.y = size.height - rect.maxY }
                    metal.draw(in: rect)
                }
                out.unlockFocus()
                if let tiff = out.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) { try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: dir + "/" + parts[1] + ".png")) }
            }
        case "manykeys":
            if let doc = app?.document, let node = doc.selectedNode, let group = doc.curveGroups(for: node).first(where: { $0.tag == parts[1] }), let channel = group.channels.first {
                let before = doc.snapshot()
                channel.write((0..<Int(n(2))).map { CurveKeyPoint(time: Double($0 * 2), value: Double($0 % 7) * 0.1, interpolation: CurveKeyPoint.linear, tangentOut: 0, tangentIn: 0) })
                doc.registerUndo("Keys", since: before)
                doc.activeCurveID = group.id
                log.append("MANYKEYS \(group.id) \(channel.read().count)")
            }
            delay = 0.5
        case "curveids":
            if let doc = app?.document {
                func walk(_ n: OutlineNode) { for g in doc.curveGroups(for: n) { let keys = g.channels.map { $0.read().count }.max() ?? 0; if keys >= 4 { log.append("CURVE \(n.id) | \(g.id) | \(g.title) keys=\(keys) channels=\(g.channels.count)") } }; n.children.forEach(walk) }
                doc.outline.forEach(walk)
            }
        case "hikey":
            if let doc = app?.document {
                var lines: [String] = []
                for id in parts.dropFirst() { lines.append("\(id)=\(String(describing: doc.visibilityKey(forNodeID: id)))") }
                log.append("HIKEY " + lines.joined(separator: "  "))
            }
        case "axistest":
            if let doc = app?.document {
                let before = doc.serializedData()
                var report: [String] = []
                func walk(_ n: OutlineNode) -> (OutlineNode, CurveGroup)? {
                    for g in doc.curveGroups(for: n) where !g.missing.isEmpty && g.channels.count >= 1 && g.missing.count <= 5 && g.tag != "Col" { return (n, g) }
                    for c in n.children { if let hit = walk(c) { return hit } }
                    return nil
                }
                if let (node, group) = doc.outline.lazy.compactMap({ walk($0) }).first {
                    report.append("\(node.id) \(group.title) has=\(group.channels.map(\.name)) missing=\(group.missing.map(\.title))")
                    let wanted = group.missing.count
                    for entry in group.missing { entry.create() }
                    doc.rebuildOutline()
                    if let again = doc.node(node.id).flatMap({ n in doc.curveGroups(for: n).first { $0.id == group.id } }) {
                        report.append("after add: channels=\(again.channels.map(\.name)) missing=\(again.missing.count) keys=\(again.channels.map { $0.read().count })")
                        let health = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                        report.append("reparse=\(health)")
                        for _ in 0..<wanted { doc.undo() }
                        report.append("undo exact=\(doc.serializedData() == before)")
                        for _ in 0..<wanted { doc.redo() }
                        doc.rebuildOutline()
                        if let third = doc.node(node.id).flatMap({ n in doc.curveGroups(for: n).first { $0.id == group.id } }), let last = third.channels.last, let drop = third.unassign[last.id] {
                            drop(); doc.rebuildOutline()
                            let fourth = doc.node(node.id).flatMap { n in doc.curveGroups(for: n).first { $0.id == group.id } }
                            report.append("after remove \(last.name): channels=\(fourth?.channels.map(\.name) ?? []) missing=\(fourth?.missing.map(\.title) ?? [])")
                        }
                        while doc.undoManager.canUndo { doc.undo() }
                        report.append("final exact=\(doc.serializedData() == before)")
                    }
                } else { report.append("no group with missing channels") }
                log.append("AXIS " + report.joined(separator: " | "))
            }
        case "assigncoverage":
            if let doc = app?.document {
                var gaps: [String: Int] = [:], offered = 0, absent = 0, nodes = 0, noClass: [String: Int] = [:]
                func walk(_ n: OutlineNode) {
                    if case .avfx(let block, let cls, let record) = n.payload, record == nil, block.children != nil {
                        nodes += 1
                        if let cls, let fields = doc.catalog.classes[cls] {
                            let have = Set((block.children ?? []).map(\.tag))
                            let offers = Set(doc.missingFields(for: n).map { String(String($0.id.split(separator: "+").last ?? "").dropFirst()) } + doc.missingCurves(for: n).map { String($0.id.split(separator: "+").last ?? "") })
                            for field in fields where !have.contains(field.tag) {
                                absent += 1
                                if offers.contains(field.tag) { offered += 1 } else { gaps["\(cls).\(field.tag) (\(field.baseType))", default: 0] += 1 }
                            }
                        } else { noClass[block.tag, default: 0] += 1 }
                    }
                    n.children.forEach(walk)
                }
                doc.outline.forEach(walk)
                log.append("ASSIGN nodes=\(nodes) absentMembers=\(absent) offered=\(offered) gaps=\(gaps.sorted { $0.value > $1.value }.prefix(40).map { "\($0.key)×\($0.value)" }) noClass=\(noClass)")
            }
        case "chanstate":
            if let doc = app?.document, let node = doc.selectedNode {
                let group = doc.curveGroups(for: node).first { $0.id == doc.activeCurveID }
                log.append("CHAN \(parts.count > 1 ? parts[1] : "") active=\(doc.activeCurveID ?? "-") channels=\(group?.channels.map(\.name) ?? []) missing=\(group?.missing.map(\.title) ?? []) dirty=\(doc.isDirty) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
            }
        case "fieldstate":
            if let doc = app?.document, let node = doc.selectedNode {
                let fields = doc.sections(for: node).flatMap(\.fields)
                let wanted = parts.dropFirst(2)
                let values = wanted.map { tag -> String in
                    guard let field = fields.first(where: { $0.tag == tag }) else { return tag + "=?" }
                    if case .bool(let on) = field.read() { return tag + "=" + (on ? "1" : "0") }
                    return tag + "=" + String(Int(field.read().number.rounded()))
                }
                log.append("FIELDS \(parts.count > 1 ? parts[1] : "") \(values) active=\(RecipeRows.recipes(for: String(node.id.split(separator: "/").dropLast().last ?? "")).filter { RecipeRows.matches($0.values, fields) }.map(\.name)) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
            }
        case "revstate":
            if let doc = app?.document {
                log.append("REV \(parts.count > 1 ? parts[1] : "") revision=\(doc.revision) preview=\(doc.previewRevision) synced=\(doc.revision == doc.previewRevision) dirty=\(doc.isDirty) playing=\(doc.clock.playing) tab=\(app?.bottomTab ?? -1) time=\(Int(doc.clock.time))")
            }
        case "livedrag":
            app?.document?.liveDrag()
        case "playon":
            app?.document?.clock.playing = true
        case "modelstate":
            if let m = ModelEditSession.active {
                let sel = m.selection.sorted(), all = m.positions, uv = m.currentUVs
                let first = sel.first.map { i in String(format: "v%d pos=(%.3f,%.3f,%.3f) uv=(%.3f,%.3f) col=%@", i, all[i].x, all[i].y, all[i].z, uv[i].x, uv[i].y, "\(m.color(i))") } ?? "-"
                let n0 = m.vertexCount > 0 ? m.normal(0) : SIMD3<Float>(0, 0, 0)
                let us = uv.map(\.x), vs = uv.map(\.y)
                let b = m.bounds(selectedOnly: false)
                log.append("MODELRANGE uv=(\(us.min() ?? 0),\(vs.min() ?? 0))..(\(us.max() ?? 0),\(vs.max() ?? 0)) bounds=\(String(describing: b))")
                log.append("MODEL \(parts.count > 1 ? parts[1] : "") verts=\(m.vertexCount) tris=\(m.triangleCount) emit=\(m.emitCount) sel=\(sel.count) emitSel=\(m.emitSelection.sorted()) first=\(first) idx0=\(Array(m.indices.prefix(3))) n0=\(String(format: "(%.2f,%.2f,%.2f)", n0.x, n0.y, n0.z)) status=\(m.status) undo=\(m.document.undoManager.canUndo ? m.document.undoManager.undoActionName : "-")")
            } else { log.append("MODEL no session") }
        case "scroll":
            if let w = window(), let content = w.contentView {
                let p = NSPoint(x: n(1), y: Double(content.bounds.height) - n(2))
                var view: NSView? = content.hitTest(p)
                while let v = view, !(v is NSScrollView) { view = v.superview }
                if let scroll = view as? NSScrollView {
                    var origin = scroll.contentView.bounds.origin
                    origin.y = max(0, origin.y + n(3))
                    scroll.contentView.scroll(to: origin)
                    scroll.reflectScrolledClipView(scroll.contentView)
                    log.append("SCROLL to \(origin.y)")
                } else { log.append("SCROLL no scroll view") }
            }
            delay = 0.5
        case "windows":
            log.append("WINDOWS " + NSApp.windows.filter(\.isVisible).map { "\(String(describing: type(of: $0))) \(Int($0.frame.width))x\(Int($0.frame.height))" }.joined(separator: " | "))
        case "focuspopover":
            if let pop = NSApp.windows.last(where: { $0.isVisible && String(describing: type(of: $0)).contains("Popover") }) {
                if DebugDriver.main == nil { DebugDriver.main = DebugDriver.own }
                DebugDriver.own = pop
                log.append("POPOVER \(Int(pop.frame.width))x\(Int(pop.frame.height))")
            } else { log.append("POPOVER none") }
        case "popshot":
            if let view = DebugDriver.own?.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: dir + "/" + parts[1] + ".png"))
            }
        case "previewstate":
            let b = ViewportRenderer.bloom
            log.append("PREVIEW \(parts.count > 1 ? parts[1] : "") bloom=\(b.on) threshold=\(b.threshold) intensity=\(b.intensity) color=\(String(describing: ViewportRenderer.backgroundColor)) image=\(ViewportRenderer.backgroundImage != nil) doc=\(app?.document?.url.lastPathComponent ?? "-") bg=\(app?.viewportBackground ?? -1)")
        case "matstate":
            if let doc = app?.document, let particle = doc.materialParticleID {
                if let graph = doc.materialGraph(particle) {
                    let compiled = graph.compile()
                    log.append("MAT \(parts.count > 1 ? parts[1] : "") nodes=\(graph.nodes.map { $0.id + "@" + String(Int($0.x ?? 0)) + "," + String(Int($0.y ?? 0)) }) links=\(graph.links.map { $0.from + "." + $0.out + ">" + $0.to + "." + $0.input }) blend=\(doc.materialBlend(particle)) use=\(doc.materialUse(particle) ?? "-") shared=\(doc.sharedMaterialNames) overrides=\(doc.materialOverrides(particle).keys.sorted()) names=\(graph.nodes.compactMap { n in n.name.map { n.id + "=" + $0 } }) textures=\(compiled.textures) problems=\(compiled.problems) lines=\(compiled.code.split(separator: "\n").count) shader=\(MTLCreateSystemDefaultDevice().flatMap { MetalRenderer.shaderProblem(graph, device: $0) } ?? "ok") undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
                } else { log.append("MAT \(parts.count > 1 ? parts[1] : "") none particle=\(particle)") }
            } else { log.append("MAT no particle") }
        case "matshare":
            if let doc = app?.document, let particle = doc.materialParticleID { doc.shareMaterial(parts[1], in: particle) }
        case "matuse":
            if let doc = app?.document, let particle = doc.materialParticleID { doc.useSharedMaterial(parts[1], in: particle) }
        case "matname":
            if let doc = app?.document, let particle = doc.materialParticleID {
                doc.editMaterial("Rename Node", in: particle) { graph in
                    if let index = graph.nodes.firstIndex(where: { $0.id == parts[1] }) { graph.nodes[index].name = parts[2] }
                }
            }
        case "matcreate":
            if let doc = app?.document, let particle = doc.materialParticleID { doc.createMaterial(in: particle); log.append("MATCREATE \(doc.materialGraph(particle)?.nodes.map(\.id) ?? [])") }
        case "matadd":
            if let doc = app?.document, let particle = doc.materialParticleID { log.append("MATADD \(doc.addMaterialNode(parts[1], at: CGPoint(x: n(2), y: n(3)), in: particle) ?? "-")") }
        case "layerstate":
            if let doc = app?.document, let id = doc.selectionID {
                let root = id.split(separator: "/").prefix(3).joined(separator: "/")
                var out: [String] = []
                for child in doc.node(root)?.children ?? [] {
                    guard case .avfx(let block, _, let record) = child.payload, record == nil, ["TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP"].contains(block.tag) else { continue }
                    let list = (block.child("TLst")?.data ?? []).map { Int($0) }
                    out.append("\(block.tag):on=\(block.int("bEna") != 0) tx=\(block.child("TxNo")?.intValue ?? -9) list=\(list)" + (parts.contains("full") ? " id=\(child.id) tags=\((block.children ?? []).map(\.tag)) missing=\(doc.missingFields(for: child).map(\.title))" : ""))
                }
                log.append("LAYERS \(parts.count > 1 ? parts[1] : "") sel=\(id) \(out) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
            }
        case "matconnect":
            if let doc = app?.document, let particle = doc.materialParticleID, parts.count > 4 {
                doc.connectMaterial(from: parts[1], out: parts[2], to: parts[3], input: parts[4], in: particle)
            }
        case "tintcode":
            for (type, wire) in [("particleColor", true), ("vertexColor", true), ("noise", true), ("particleColor", false)] {
                var links = [MaterialLink]()
                if wire { links.append(MaterialLink(from: "t", out: type == "noise" ? "out" : "rgb", to: "o", input: "color")) }
                let graph = MaterialGraph(nodes: [MaterialNode(id: "t", type: type), MaterialNode(id: "o", type: "output")], links: links)
                let code = graph.compile().code
                let problem = MTLCreateSystemDefaultDevice().flatMap { MetalRenderer.shaderProblem(graph, device: $0) } ?? "-"
                log.append("TINT \(type) wired=\(wire) particleOff=\(code.contains("particleTint = float4(1.0)")) vertexOff=\(code.contains("vertexTint = float4(1.0)")) problem=\(problem)")
            }
        case "cpugpu":
            let half = SIMD4<Float>(0.5, 0.5, 0.5, 0.5)
            func run(_ graph: MaterialGraph) -> SIMD4<Float> {
                graph.evaluator(node: "o", output: nil) { name, _ in name == "d" ? SIMD4(0.2, 0.2, 0.2, 1) : SIMD4(0.8, 0.8, 0.8, 1) }(MaterialGraph.Sample(uv: SIMD2(0.5, 0.5), age: 0, life: 0, random: 0, layers: SIMD4(1, 1, 1, 1), particle: half))
            }
            let particle = MaterialGraph(nodes: [MaterialNode(id: "t", type: "particleColor"), MaterialNode(id: "o", type: "output")], links: [MaterialLink(from: "t", out: "rgb", to: "o", input: "color")])
            let plain = MaterialGraph(nodes: [MaterialNode(id: "t", type: "color", params: ["r": 1, "g": 1, "b": 1, "a": 1]), MaterialNode(id: "o", type: "output")], links: [MaterialLink(from: "t", out: "rgb", to: "o", input: "color")])
            var nodes = [MaterialNode(id: "o", type: "output"), MaterialNode(id: "m", type: "multiply")]
            for (i, name) in ["a", "b", "c", "d"].enumerated() { nodes.append(MaterialNode(id: "t\(i)", type: "texture", texture: name)) }
            let four = MaterialGraph(nodes: nodes, links: [MaterialLink(from: "t3", out: "rgb", to: "o", input: "color"), MaterialLink(from: "t0", out: "rgb", to: "m", input: "a"),
                                                         MaterialLink(from: "t1", out: "rgb", to: "m", input: "b"), MaterialLink(from: "t2", out: "rgb", to: "o", input: "emissive")])
            log.append("CPUGPU particle=\(run(particle)) plain=\(run(plain)) fourth=\(run(four)) textures=\(four.textures) gpuProblems=\(four.compile().problems)")
        case "matall":
            if let device = MTLCreateSystemDefaultDevice() {
                var failures: [String] = []
                var count = 0
                for kind in MaterialGraph.kinds where kind.type != "output" {
                    for out in kind.outputs {
                        var nodes = [MaterialNode(id: "t", type: kind.type, texture: kind.texture ? "any" : nil), MaterialNode(id: "o", type: "output")]
                        var links = [MaterialLink(from: "t", out: out, to: "o", input: "color"), MaterialLink(from: "t", out: out, to: "o", input: "alpha"),
                                     MaterialLink(from: "t", out: out, to: "o", input: "emissive"), MaterialLink(from: "t", out: out, to: "o", input: "opacityMask")]
                        for (index, input) in kind.inputs.enumerated() {
                            nodes.append(MaterialNode(id: "s\(index)", type: "noise"))
                            links.append(MaterialLink(from: "s\(index)", out: "out", to: "t", input: input))
                        }
                        let graph = MaterialGraph(nodes: nodes, links: links)
                        count += 1
                        if let problem = MetalRenderer.shaderProblem(graph, device: device) { failures.append(kind.type + "." + out + ": " + problem) }
                        let bare = MaterialGraph(nodes: Array(nodes.prefix(2)), links: Array(links.prefix(1)))
                        if let problem = MetalRenderer.shaderProblem(bare, device: device) { failures.append(kind.type + "." + out + " bare: " + problem) }
                        let value = graph.evaluator(node: "t", output: out) { _, _ in SIMD4(repeating: 0.5) }(MaterialGraph.Sample(uv: SIMD2(0.3, 0.6), age: 1, life: 0.5, random: 0.2, layers: SIMD4(1, 1, 1, 1), particle: SIMD4(1, 1, 1, 1)))
                        if !(value.x.isFinite && value.w.isFinite) { failures.append(kind.type + "." + out + " cpu not finite") }
                    }
                }
                let inner = MaterialGraph(nodes: [MaterialNode(id: "c", type: "color", params: ["r": 1, "g": 0, "b": 0, "a": 0.5]), MaterialNode(id: "o", type: "output")],
                                          links: [MaterialLink(from: "c", out: "rgb", to: "o", input: "color")])
                let outer = MaterialGraph(nodes: [MaterialNode(id: "s", type: "subgraph", graph: "Inner"), MaterialNode(id: "o", type: "output")],
                                          links: [MaterialLink(from: "s", out: "rgb", to: "o", input: "color"), MaterialLink(from: "s", out: "a", to: "o", input: "alpha")])
                let flat = outer.resolved(shared: ["Inner": inner])
                let red = flat.evaluator(node: "o", output: nil) { _, _ in SIMD4(repeating: 1) }(MaterialGraph.Sample(uv: SIMD2(0.5, 0.5), age: 0, life: 0, random: 0, layers: SIMD4(0.2, 0.2, 0.2, 0.7), particle: SIMD4(1, 1, 1, 1)))
                if flat.nodes.contains(where: { $0.type == "subgraph" }) || red.x != 1 || red.y != 0 || abs(red.w - 0.7) > 1e-4 { failures.append("subgraph expansion \(flat.nodes.map(\.id)) \(red)") }
                if let problem = MetalRenderer.shaderProblem(flat, device: device) { failures.append("subgraph shader: " + problem) }
                let tuned = MaterialGraph(nodes: [], links: [], use: "P", overrides: ["Power": .number(0.25)])
                    .resolved(shared: ["P": MaterialGraph(nodes: [MaterialNode(id: "f", type: "float", name: "Power", params: ["value": 1]), MaterialNode(id: "o", type: "output")],
                                                          links: [MaterialLink(from: "f", out: "out", to: "o", input: "alpha")])])
                if tuned.nodes.first?.params?["value"] != 0.25 { failures.append("override not applied") }
                log.append("MATALL kinds=\(MaterialGraph.kinds.count) cases=\(count) failures=\(failures)")
            }
        case "unsetstate":
            if let doc = app?.document, let node = doc.selectedNode {
                log.append("UNSET \(parts.count > 1 ? parts[1] : "") node=\(node.id) fields=\(doc.sections(for: node).flatMap(\.fields).count) unsetFields=\(doc.missingFields(for: node).map(\.title)) curves=\(doc.curveGroups(for: node).count) unsetCurves=\(doc.missingCurves(for: node).count) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
            }
        case "tlstate":
            if let doc = app?.document {
                let c = doc.clock
                log.append("TL \(parts.count > 1 ? parts[1] : "") speed=\(c.speed) triggers=\(c.triggers.map(\.index)) released=\(c.releaseTime != nil) loop=\(c.loop) time=\(c.time) playing=\(c.playing) start=\(c.startFrame) end=\(c.endFrame.map { "\($0)" } ?? "-") solo=\(doc.soloPreview) sel=\(doc.selectionID ?? "-") rows=\(doc.sequencerRows.map { "\($0.label):\(Int($0.start))-\(Int($0.end))" }) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")")
            }
        case "menu":
            let path = parts.dropFirst(4).joined(separator: " ").components(separatedBy: ">")
            guard let w = window(), let content = w.contentView else { break }
            let p = NSPoint(x: n(2), y: Double(content.bounds.height) - n(3))
            let right = parts[1] == "right"
            guard let event = NSEvent.mouseEvent(with: right ? .rightMouseDown : .leftMouseDown, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                                 windowNumber: w.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1) else { break }
            var view = content.hitTest(p)
            var chain: [String] = []
            var root: NSMenu?
            while let v = view, root == nil {
                chain.append(String(describing: type(of: v)))
                if right { root = v.menu(for: event) }
                view = v.superview
            }
            guard let root else { armMenu(path)
                let screen = w.convertPoint(toScreen: p)
                var element = content.accessibilityHitTest(screen) as? NSObject
                var names: [String] = []
                var shown = false
                while let e = element, !shown, names.count < 12 {
                    let role = (e as? NSAccessibilityElementProtocol).flatMap { _ in e.value(forKey: "accessibilityRole") as? String } ?? "?"
                    let actions = (e.perform(NSSelectorFromString("accessibilityActionNames"))?.takeUnretainedValue() as? [String]) ?? []
                    names.append("\(role)\(actions)")
                    if right, actions.contains("AXShowMenu") { _ = e.perform(NSSelectorFromString("accessibilityPerformAction:"), with: "AXShowMenu"); shown = true }
                    if !right, actions.contains("AXPress") { _ = e.perform(NSSelectorFromString("accessibilityPerformAction:"), with: "AXPress"); shown = true }
                    element = e.perform(NSSelectorFromString("accessibilityParent"))?.takeUnretainedValue() as? NSObject
                }
                if !shown { post(right ? .rightMouseDown : .leftMouseDown, n(2), n(3)); post(right ? .rightMouseUp : .leftMouseUp, n(2), n(3)) }
                delay = 1.2; break }
            var menu = root
            var found: (NSMenu, Int)?
            var trail: [String] = []
            for (depth, name) in path.enumerated() {
                menu.delegate?.menuNeedsUpdate?(menu)
                menu.update()
                trail.append("[" + menu.items.map { $0.isSeparatorItem ? "-" : ($0.title + ($0.state == .on ? "*" : "") + ($0.isEnabled ? "" : "!") + ($0.hasSubmenu ? ">" : "")) }.joined(separator: ", ") + "]")
                guard let index = menu.items.firstIndex(where: { $0.title == name }) else { break }
                if depth == path.count - 1 { found = (menu, index) } else if let sub = menu.items[index].submenu { menu = sub } else { break }
            }
            log.append("MENU \(path.joined(separator: ">")) \(found == nil ? "not found" : "ok") \(trail.joined(separator: " "))")
            if let (menu, index) = found { menu.performActionForItem(at: index) }
            delay = 0.5
        case "texnames":
            log.append("TEXNAMES slots=\(app?.document?.textureSlots.map(\.name) ?? []) assets=\(app?.textureAssets.count ?? -1) png=\(app?.textureAssets.filter { $0.url.pathExtension.lowercased() == "png" }.prefix(5).map(\.name) ?? [])")
        case "lightstate":
            if let doc = app?.document { let l = doc.materialLight; log.append("LIGHT \(parts.count > 1 ? parts[1] : "") dir=\(l.direction ?? []) color=\(l.color ?? []) ambient=\(l.ambient ?? []) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")") }
        case "rightclick":
            post(.rightMouseDown, n(1), n(2)); post(.rightMouseUp, n(1), n(2)); delay = 0.5
        case "clipboard":
            log.append("CLIP \(parts.count > 1 ? parts[1] : "") pasteboard=\(NSPasteboard.general.string(forType: .string) ?? "-") notice=\(app?.notice ?? "-") frontApp=\(NSWorkspace.shared.frontmostApplication?.localizedName ?? "-")")
        case "curvestate":
            if let doc = app?.document, let node = doc.selectedNode {
                let groups = doc.curveGroups(for: node)
                let active = groups.first { $0.id == doc.activeCurveID }
                log.append("CURVESTATE \(parts.count > 1 ? parts[1] : "") active=\(active?.title ?? "-") keys=\(active?.channels.map { c in c.name + ":" + c.read().map { String(format: "%.0f=%.2f", $0.time, $0.value) }.joined(separator: ",") } ?? []) constants=\(groups.filter { (CurveValueRows.mode($0) == "Constant" && !$0.channels.contains { $0.colorComponent != nil }) }.map { g in g.title + "=" + g.channels.map { String(format: "%.3f", $0.read().first?.value ?? 0) }.joined(separator: "/") }) undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-") ms=\(doc.clock.frameMilliseconds)")
            }
        case "mdlauto":
            if let app { app.loadModelForEffect(); log.append("MDLAUTO code=\(app.document.flatMap { app.monsterCode(for: $0) } ?? "-") model=\(app.referenceModelName ?? "-") textured=\(app.referenceTextured) skeleton=\(app.skeletonName ?? "-") notice=\(app.notice ?? "-") error=\(app.errorMessage ?? "-")"); app.errorMessage = nil }
            delay = 0.8
        case "mdlload":
            if let app {
                do { let r = try app.loadReferenceModel(URL(fileURLWithPath: parts[1])); log.append("MDL loaded \(r) textured=\(app.referenceTextured)/\(ViewportRenderer.referenceParts.count) tex=\(ViewportRenderer.referenceParts.first?.texture.map { "\($0.width)x\($0.height) \($0.formatName)" } ?? "-") bounds=\(String(describing: ViewportRenderer.referenceMesh?.bounds))") } catch { log.append("MDL FAILED \(error.localizedDescription)") }
            }
            delay = 0.6
        case "catalogopen":
            if let app {
                let hit = GameCatalog.lines(parts[1]).compactMap { $0.split(separator: "\t").last.map(String.init) }.first { app.locateGameFile($0) != nil }
                if let hit { app.openCatalogPath(hit) }
                log.append("CATALOGOPEN \(parts[1]) hit=\(hit ?? "-") doc=\(app.document?.url.lastPathComponent ?? "-") gamePath=\(app.document?.gamePath ?? "-") inspector=\(app.gameFile?.url.lastPathComponent ?? "-") note=\(app.catalogNote ?? "-")")
            }
            delay = 1
        case "theme":
            Theme.setLight(n(1) != 0); app?.themeToken += 1; app?.document?.liveChanged(); delay = 1.2
        case "rule": PreviewRules.set(parts[1], n(2) != 0); delay = 0.4
        case "atexhash":
            let folder = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1])
            let files = ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "atex" }.sorted { $0.path < $1.path }
            var byFormat: [String: (count: Int, hash: UInt64, time: Double)] = [:]
            var failed = 0
            for file in files {
                guard let data = try? Data(contentsOf: file) else { continue }
                let start = CACurrentMediaTime()
                guard let decoded = try? Atex.decode([UInt8](data)) else { failed += 1; continue }
                let spent = CACurrentMediaTime() - start
                var hash: UInt64 = 1469598103934665603
                for byte in decoded.rgba { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
                var entry = byFormat[decoded.formatName] ?? (0, 0, 0)
                entry.count += 1
                entry.hash = entry.hash &* 31 &+ hash
                entry.time += spent
                byFormat[decoded.formatName] = entry
            }
            for (name, entry) in byFormat.sorted(by: { $0.key < $1.key }) { log.append("ATEX \(name) n=\(entry.count) hash=\(String(entry.hash, radix: 16)) ms=\(Int(entry.time * 1000))") }
            log.append("ATEX failed=\(failed)")
        case "rebuilds":
            if let w = window(), let content = w.contentView {
                func find(_ v: NSView) -> MTKView? {
                    if let m = v as? MTKView { return m }
                    for s in v.subviews { if let m = find(s) { return m } }
                    return nil
                }
                if let renderer = find(content)?.delegate as? ViewportRenderer, let player = renderer.player {
                    log.append("REBUILDS \(parts.count > 1 ? parts[1] : "") \(player.rebuilds) particles=\(player.simulation?.particles.count ?? -1) revision=\(app?.document?.revision ?? -1)")
                }
            }
        case "bloom":
            ViewportRenderer.bloom = (n(1) != 0, 0.2, 2.5, 0.05)
            delay = 0.4
        case "namestate":
            if let doc = app?.document { log.append("NAMES \(parts.count > 1 ? parts[1] : "") \(doc.names.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }) hidden=\(doc.hidden.map { "\($0)" }.sorted()) sel=\(doc.selectionID ?? "-")") }
        case "hide":
            if let doc = app?.document {
                let i = Int(n(2))
                doc.toggleHidden(parts[1] == "emitter" ? .emitter(i) : parts[1] == "particle" ? .particle(i) : .timeline(i))
            }
        case "doccount":
            if let app { log.append("DOCS \(app.openDocuments.count) dirty=\(app.dirtyDocuments.map(\.title)) current=\(app.document?.title ?? "-")") }
        case "skpusers":
            if let data = try? Data(contentsOf: URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles/look.skp")) {
                let b = [UInt8](data)
                if let model = SkpModel.parse(b) {
                    let refs = model.groups.flatMap { $0.elements.map { Int($0[1]) } }
                    let params = model.parameters.map { Int($0[52]) }
                    let users = (0..<model.parameters.count).map { GameRecords.skpParameterUsers(b, parameter: $0).map { "\($0.index):\($0.users)" } ?? "-" }
                    let dup = GameRecords.skpEdit(b, .parameter(0), remove: false).flatMap(SkpModel.parse)
                    log.append("SKP params=\(params) elementRefs=\(refs) users=\(users) duplicateIndex=\(dup.map { $0.parameters.map { Int($0[52]) } } ?? [])")
                } else { log.append("SKP parse failed") }
            }
        case "phyblimit":
            if let data = try? Data(contentsOf: URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/gamefiles/cloth.phyb")) {
                var bytes = [UInt8](data)
                var added = 0, refused = false
                let start = PhybModel.parse(bytes)?.simulators.first?.lists[0].count ?? -1
                for _ in 0..<300 {
                    guard let next = GameRecords.phybAdd(bytes, .item(0), near: .parameters(simulator: 0)) else { refused = true; break }
                    bytes = next
                    added += 1
                }
                let model = PhybModel.parse(bytes)
                log.append("PHYBLIMIT start=\(start) added=\(added) refused=\(refused) final=\(model?.simulators.first?.lists[0].count ?? -1) reparse=\(model != nil) exact=\(model?.serialized() == bytes)")
            }
        case "halftest":
            var worst: Float = 0, bad = 0
            var x: Float = 6.1e-5
            while x < 65000 {
                for v in [x, -x] {
                    let back = CurveMath.halfToFloat(CurveMath.floatToHalf(v))
                    let error = abs(back - v) / abs(v)
                    worst = max(worst, error)
                    if error > 0.0005 { bad += 1 }
                }
                x *= 1.0137
            }
            let edges = [Float(0), -0.0, 1e9, -1e9, .infinity, .nan, 65504, 65520, 1e-9, 0.5].map { String(format: "%04x", CurveMath.floatToHalf($0)) }
            var allHalves = 0
            for raw in 0...0xffff where (raw >> 10) & 0x1f != 31 {
                if CurveMath.floatToHalf(CurveMath.halfToFloat(UInt16(raw))) != UInt16(raw) { allHalves += 1 }
            }
            log.append("HALF worst=\(worst) bad=\(bad) edges=\(edges) roundtripMismatches=\(allHalves)")
            log.append("CRC zip=\(String(Crc32.checksum(Array("123456789".utf8)), radix: 16)) jam=\(String(SqPackHash.key("chara/monster/m0016/obj/body/b0001/VM0001.avfx"), radix: 16))")
        case "scdmarker":
            var tone = [Int16]()
            for i in 0..<44100 { tone.append(Int16(sin(Double(i) * 0.05) * 8000)) }
            var aux = Array("MARK".utf8)
            aux.appendU32(32); aux.appendU32(44100); aux.appendU32(88200); aux.appendU32(2); aux.appendU32(22050); aux.appendU32(66150)
            while aux.count % 16 != 0 { aux.append(0) }
            var entry = GameFiles.scdEntry(samples: tone, channels: 1, rate: 44100, flags: 1, aux: aux)
            GameFiles.put32(&entry, 16, 44100)
            GameFiles.put32(&entry, 20, 88200)
            var file = Array("SEDBSSCF".utf8)
            file.appendU32(3); file.append(contentsOf: [0, 4]); file.appendU16(0x30); file.appendU32(0)
            while file.count < 0x30 { file.append(0) }
            file.appendU16(0); file.appendU16(0); file.appendU16(1); file.appendU16(0)
            file.appendU32(0x50); file.appendU32(0x50); file.appendU32(0); file.appendU32(0); file.appendU32(0); file.appendU32(0)
            let table = file.count
            file.appendU32(0)
            while file.count % 16 != 0 { file.append(0) }
            GameFiles.put32(&file, table, UInt32(file.count))
            file.append(contentsOf: entry)
            while file.count % 16 != 0 { file.append(0) }
            GameFiles.put32(&file, 0x10, UInt32(file.count))
            func describe(_ b: [UInt8]) -> String {
                guard let audio = GameFiles.scdAudio(b).first else { return "no audio" }
                let size = GameFiles.scdAux(b, audio)
                let at = audio.offset + 0x20
                let marker = size >= 20 ? (0..<(2 + 1 + GameFiles.i32(b, at + 16))).map { GameFiles.i32(b, at + 8 + $0 * 4) } : []
                return "rate=\(audio.sampleRate) loop=\(audio.loopStart)-\(audio.loopEnd) flags=\(GameFiles.i32(b, audio.offset + 28)) aux=\(size) marker=\(marker) samples=\(GameFiles.scdSamples(b, audio).count)"
            }
            log.append("SCDMARK before " + describe(file))
            if let audio = GameFiles.scdAudio(file).first {
                let half = stride(from: 0, to: tone.count, by: 2).map { tone[$0] }
                let size = GameFiles.scdAux(file, audio)
                let kept = GameFiles.scdMarker(Array(file[(audio.offset + 0x20)..<(audio.offset + 0x20 + size)]), from: audio.sampleRate, to: 22050)
                let fresh = GameFiles.scdEntry(samples: half, channels: 1, rate: 22050, flags: UInt32(GameFiles.i32(file, audio.offset + 28)), aux: kept)
                if let next = GameFiles.scdReplacing(file, index: audio.id, entry: fresh) { log.append("SCDMARK after " + describe(next)) } else { log.append("SCDMARK replace failed") }
            }
        case "scdtest":
            let source = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1])
            if let data = try? Data(contentsOf: source) {
                let entry = [UInt8](data)
                func build(_ entries: [[UInt8]]) -> [UInt8] {
                    var b = Array("SEDBSSCF".utf8)
                    b.appendU32(3); b.append(contentsOf: [0, 4]); b.appendU16(0x30); b.appendU32(0)
                    while b.count < 0x30 { b.append(0) }
                    b.appendU16(0); b.appendU16(0); b.appendU16(UInt16(entries.count)); b.appendU16(0)
                    b.appendU32(0x50); b.appendU32(0x50); b.appendU32(0); b.appendU32(0); b.appendU32(0); b.appendU32(0)
                    let table = b.count
                    for _ in entries { b.appendU32(0) }
                    while b.count % 16 != 0 { b.append(0) }
                    for (i, e) in entries.enumerated() { GameFiles.put32(&b, table + i * 4, UInt32(b.count)); b.append(contentsOf: e); while b.count % 16 != 0 { b.append(0) } }
                    GameFiles.put32(&b, 0x10, UInt32(b.count))
                    return b
                }
                let file = build([entry, entry])
                let list = GameFiles.scdAudio(file)
                let decoded = list.first.map { GameFiles.scdSamples(file, $0) } ?? []
                let playable = list.first.flatMap { GameFiles.scdWave(file, $0) }.map { (try? AVAudioPlayer(data: Data($0))) != nil } ?? false
                var reference: [Int16] = []
                if let first = list.first, let wave = GameFiles.scdWave(file, first) {
                    let url = URL(fileURLWithPath: dir + "/ref.wav"); try? Data(wave).write(to: url)
                    reference = (try? GameFiles.pcm(from: url))?.samples ?? []
                }
                var diff = 0.0; let common = min(reference.count, decoded.count)
                for i in 0..<common { diff += abs(Double(reference[i]) - Double(decoded[i])) }
                log.append("SCD entries=\(list.map { "\($0.formatName) \($0.channels)ch \($0.sampleRate) len=\($0.dataLength) hdr=\($0.headerSize)" }) decoded=\(decoded.count) system=\(reference.count) meanDiff=\(common > 0 ? diff / Double(common) : -1) playable=\(playable)")
                for channels in [1, 2] {
                    var tone = [Int16](); let frames = 22050
                    for i in 0..<frames { for c in 0..<channels { tone.append(Int16(9000 * sin(Double(i) * (c == 0 ? 0.05 : 0.11)) + 4000 * sin(Double(i) * 0.31))) } }
                    let toneURL = URL(fileURLWithPath: dir + "/tone\(channels).wav")
                    try? Data(GameFiles.wave(samples: tone, channels: channels, rate: 22050)).write(to: toneURL)
                    let doc = GameFileDocument(url: URL(fileURLWithPath: dir + "/sound.scd"), bytes: file, kind: .scd)
                    doc.replaceAudio(list[0], from: toneURL)
                    let after = GameFiles.scdAudio(doc.bytes)
                    let back = after.first.map { GameFiles.scdSamples(doc.bytes, $0) } ?? []
                    var noise = 0.0, signal = 0.0
                    for i in 0..<min(tone.count, back.count) { let d = Double(tone[i]) - Double(back[i]); noise += d * d; signal += Double(tone[i]) * Double(tone[i]) }
                    let second = after.count > 1 ? GameFiles.scdSamples(doc.bytes, after[1]) : []
                    let systemOK = after.first.flatMap { GameFiles.scdWave(doc.bytes, $0) }.map { wave -> Int in
                        let url = URL(fileURLWithPath: dir + "/enc\(channels).wav"); try? Data(wave).write(to: url)
                        let pcm = (try? GameFiles.pcm(from: url))?.samples ?? []
                        var d = 0.0; let m = min(pcm.count, back.count); for i in 0..<m { d += abs(Double(pcm[i]) - Double(back[i])) }
                        return m > 0 ? Int(d / Double(m)) : -1
                    } ?? -2
                    log.append("SCDREPLACE ch=\(channels) note=\(doc.note ?? "-") entries=\(after.map { "\($0.channels)ch \($0.sampleRate) len=\($0.dataLength) @\($0.offset)" }) snr=\(String(format: "%.1f", 10 * log10(signal / max(noise, 1)))) secondIntact=\(second == decoded) sizeField=\(GameFiles.i32(doc.bytes, 0x10)) total=\(doc.bytes.count) systemDiff=\(systemOK) peaks=\(doc.peaks(after[0]).count)")
                }
            } else { log.append("SCD no sample") }
        case "background": app?.viewportBackground = Int(n(1)); delay = 0.4
        case "clip": log.append("  clipboard=\(KeyClipboard.entries.map { "\($0.name):\($0.keys.map(\.time))" })")
        case "rewirestress":
            if let doc = app?.document {
                func bytes() -> Data { doc.avfxRoot != nil ? doc.serializedData() : Data((doc.jsonRoot?.serialized() ?? "").utf8) }
                let original = bytes()
                var ops = 0, skipped = 0
                var problems: [String] = []
                for id in doc.graph.edges.map(\.id) {
                    let graph = doc.graph
                    guard let edge = graph.edges.first(where: { $0.id == id }) else { continue }
                    guard let target = graph.nodes.first(where: { doc.canRetarget(edge, to: $0.id) })?.id else { skipped += 1; continue }
                    doc.retarget(edge, to: target); ops += 1
                    let after = doc.graph
                    if !after.edges.contains(where: { $0.from == edge.from && $0.to == target }) { problems.append("\(id) -> \(target): edge missing") }
                    if doc.avfxRoot != nil {
                        if (try? AvfxBlock.parseFile([UInt8](bytes()))) == nil { problems.append("\(id): reparse failed") }
                    } else if (try? JSONParser.parse(bytes())) == nil { problems.append("\(id): invalid json") }
                    doc.undo()
                    if bytes() != original { problems.append("\(id): undo mismatch"); break }
                }
                log.append("REWIRE \(doc.title) edges=\(doc.graph.edges.count) ops=\(ops) skipped=\(skipped) problems=\(problems.prefix(4)) restored=\(bytes() == original)")
            }
        case "solo":
            if let doc = app?.document { doc.setSolo(n(1) != 0); log.append("  solo=\(doc.soloPreview) range=\(doc.clock.startFrame)…\(String(describing: doc.clock.endFrame)) isolate=\(doc.isolateSelection) t=\(doc.clock.time) playing=\(doc.clock.playing)") }
            delay = 0.4
        case "time": if let doc = app?.document { log.append("  t=\(doc.clock.time) range=\(doc.clock.startFrame)…\(String(describing: doc.clock.endFrame))") }
        case "highlight": app?.highlightSelection = n(1) != 0; delay = 0.3
        case "edges": if let doc = app?.document { log.append("  edges: " + doc.graph.edges.filter { $0.from.hasPrefix(parts[1]) }.map { "\($0.from)>\($0.to)" }.joined(separator: " ") + " undo=\(doc.undoManager.canUndo ? doc.undoManager.undoActionName : "-")") }
        case "gltftest":
            if let doc = app?.document, let root = doc.avfxRoot {
                var lines: [String] = []
                for (i, model) in root.childrenNamed("Modl").enumerated() {
                    let before = (model.child("VDrw")?.data ?? [], model.child("VIdx")?.data ?? [])
                    let mesh = Gltf.mesh(from: model)
                    let url = URL(fileURLWithPath: dir + "/model\(i).glb")
                    do {
                        try Data(Gltf.glb(mesh, name: "Model \(i)")).write(to: url)
                        let loaded = try Gltf.load(url)
                        let data = Gltf.vertexData(loaded)
                        var vertexDiff = 0, worst = 0
                        if data.vertices.count == before.0.count { for k in data.vertices.indices where data.vertices[k] != before.0[k] { vertexDiff += 1; worst = max(worst, abs(Int(data.vertices[k]) - Int(before.0[k]))) } } else { vertexDiff = -1 }
                        lines.append("m\(i): v=\(mesh.positions.count) tri=\(mesh.indices.count / 3) vertexBytesDiff=\(vertexDiff)/\(before.0.count) worst=\(worst) indicesSame=\(data.indices == before.1) notes=\(loaded.notes)")
                        if i == 0 {
                            try doc.applyMesh(loaded, to: model, emitPoints: false)
                            try doc.applyMesh(loaded, to: model, emitPoints: true)
                            let ok = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                            lines.append("apply: reparse=\(ok) tags=\((model.children ?? []).map(\.tag)) emit=\((model.child("VEmt")?.data.count ?? 0) / 28)")
                            doc.undo(); doc.undo()
                        }
                    } catch { lines.append("m\(i): FAILED \(error)") }
                }
                log.append("GLTF \(doc.title) " + lines.joined(separator: " | "))
            }
        case "gltfload":
            do {
                let mesh = try Gltf.load(URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1]))
                log.append("GLTFLOAD \(parts[1]) v=\(mesh.positions.count) idx=\(mesh.indices) n0=\(mesh.normals.first ?? .zero) t0=\(mesh.tangents.first ?? .zero) uv=\(mesh.uvs[0]) notes=\(mesh.notes)")
                if let doc = app?.document, let root = doc.avfxRoot {
                    doc.addTopLevel("Modl")
                    if let model = root.childrenNamed("Modl").last { try doc.applyMesh(mesh, to: model, emitPoints: false); log.append("  applied: models=\(root.childrenNamed("Modl").count) bytes=\(model.child("VDrw")?.data.count ?? 0) reparse=\((try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil) MdCn=\((try? AvfxBlock.parseFile([UInt8](doc.serializedData())))?.int("MdCn") ?? -1)") }
                }
            } catch { log.append("GLTFLOAD FAILED \(error)") }
        case "survey":
            if let doc = app?.document {
                func walk(_ n: OutlineNode) {
                    let fields = doc.sections(for: n).flatMap(\.fields)
                    let info = fields.filter { $0.write == nil }
                    let curves = doc.curveGroups(for: n).count
                    let generic = n.id.split(separator: "/").map { Int($0) == nil ? String($0.filter { !$0.isNumber }) : "#" }.joined(separator: "/")
                    if fields.count - info.count == 0 && curves == 0 {
                        log.append("EMPTY \(generic) [\(n.title.filter { !$0.isNumber })] actions=\(n.actions.map(\.title)) children=\(n.children.count) info=\(info.map(\.label).prefix(5))")
                    } else if !info.isEmpty {
                        log.append("INFO \(generic) \(info.map { "\($0.label)[\($0.tag)]" })")
                    }
                    n.children.forEach(walk)
                }
                doc.outline.forEach(walk)
            }
        case "resize": window()?.setContentSize(NSSize(width: n(1), height: n(2))); delay = 0.8
        case "modelwin":
            if let app {
                app.modelEditorTarget = parts[1]; app.modelEditorCount = app.document?.avfxRoot?.childrenNamed("Modl").count ?? 0
                let w = TestWindow(contentRect: NSRect(x: 60, y: 80, width: 980, height: 620), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                let host = NSHostingView(rootView: ModelEditorView().environmentObject(app))
                w.contentView = host
                w.orderFrontRegardless()
                DebugDriver.extra = w
            }
            delay = 1.0
        case "extrashot":
            if let view = DebugDriver.extra?.contentView, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: dir + "/" + parts[1] + ".png"))
            }
        case "freshcheck":
            if let doc = app?.document, let root = doc.avfxRoot {
                var issues: [String] = []
                var checked = 0
                func ordered(_ file: [String], _ fresh: [String]) -> Bool {
                    var at = 0
                    for tag in file { guard let found = fresh[at...].firstIndex(of: tag) else { return false }; at = found + 1 }
                    return true
                }
                for (cls, info) in AvfxCatalog.dataTypes {
                    let tag = ["AvfxEmitter": "Emit", "AvfxParticle": "Ptcl", "AvfxEffector": "Efct", "AvfxBinder": "Bind"][cls] ?? ""
                    for (i, node) in root.childrenNamed(tag).enumerated() {
                        guard let data = node.child("Data"), let name = doc.catalog.enumCaseName(info.enumName, node.int(info.field))?.replacingOccurrences(of: "_Variable", with: "") else { continue }
                        guard let fresh = doc.catalog.freshData(info.prefix + name) else { issues.append("\(tag)\(i) \(name): no class"); continue }
                        checked += 1
                        let fileTags = (data.children ?? []).map(\.tag), freshTags = (fresh.children ?? []).map(\.tag)
                        if !ordered(fileTags, freshTags) { issues.append("\(tag)\(i) \(name): file=\(fileTags) fresh=\(freshTags)") }

                    }
                }
                let lists: [(String, String, String)] = [("Schd", "Item", "AvfxSchedulerItem"), ("TmLn", "Item", "AvfxTimelineItem"), ("Emit", "ItPr", "AvfxEmitterItem"), ("Emit", "ItEm", "AvfxEmitterItem")]
                for (tag, list, cls) in lists {
                    for (i, node) in root.childrenNamed(tag).enumerated() {
                        for record in node.ownRecords(list) {
                            checked += 1
                            let fileTags = record.map(\.tag), freshTags = doc.defaultRecord(cls).map(\.tag)
                            if fileTags != freshTags && !(cls == "AvfxTimelineItem" && fileTags.filter({ $0 != "ClNo" }) == freshTags) { issues.append("\(tag)\(i).\(list): file=\(fileTags) fresh=\(freshTags)") }
                            let fresh = doc.defaultRecord(cls)
                            _ = fresh
                        }
                    }
                }
                log.append("FRESH \(doc.title) checked=\(checked) issues(\(issues.count))=\(Array(Set(issues)).sorted().prefix(4))")
            }
        case "coverage":
            if let doc = app?.document {
                var lines: [String: Int] = [:]
                var total = 0, covered = 0
                func walk(_ n: OutlineNode) {
                    if case .avfx(let block, let cls, let record) = n.payload, record == nil {
                        let childIDs = Set(n.children.compactMap { child -> ObjectIdentifier? in if case .avfx(let b, _, _) = child.payload { return ObjectIdentifier(b) }; return nil })
                        let curveTags = Set(doc.curveGroups(for: n).map(\.tag))
                        let listTags = Set(AvfxBlock.cumulativeTags[block.tag] ?? [])
                        for child in block.children ?? [] {
                            total += 1
                            if AvfxCatalog.countTags.contains(child.tag) || listTags.contains(child.tag) { covered += 1; continue }
                            if child.children != nil {
                                if childIDs.contains(ObjectIdentifier(child)) || curveTags.contains(child.tag) || child.tag == "Life" { covered += 1 } else { lines["container \(cls ?? "?").\(child.tag)", default: 0] += 1 }
                            } else if let field = doc.avfxField(child, cls: cls, id: "x") {
                                if field.write == nil { lines["readonly \(cls ?? "?").\(child.tag) [\(child.data.count)b]", default: 0] += 1 } else { covered += 1 }
                            } else if EffectDocument.indexListTarget(child, cls: cls) != nil || ["Keys", "Cols", "Frms", "Clip", "VDrw", "VIdx", "VEmt", "VNum", "Life"].contains(child.tag) || (child.tag == "Tex" && cls == "AvfxMain") {
                                covered += 1
                            } else {
                                lines["hidden \(cls ?? "?").\(child.tag) [\(child.data.count)b]", default: 0] += 1
                            }
                        }
                    }
                    n.children.forEach(walk)
                }
                doc.outline.forEach(walk)
                log.append("COVERAGE \(doc.title) \(covered)/\(total) " + lines.sorted { $0.value > $1.value }.map { "\($0.key)×\($0.value)" }.joined(separator: " | "))
            }
        case "codec":
            do {
                let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent)
                var files: [URL] = []
                if let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) { for case let u as URL in walker where u.pathExtension == "atex" && !u.lastPathComponent.hasPrefix("a") { files.append(u) } }
                var ddsSame = 0, ddsTotal = 0
                var worst: [String: Double] = [:]
                var identity = 0, identityTotal = 0
                for url in files {
                    let bytes = [UInt8](try Data(contentsOf: url))
                    guard let decoded = try? Atex.decode(bytes) else { continue }
                    ddsTotal += 1
                    if let dds = try? TextureCodec.dds(fromAtex: bytes), let back = try? TextureCodec.atex(fromDDS: dds), let again = try? Atex.decode(back), again.rgba == decoded.rgba, again.width == decoded.width { ddsSame += 1 }
                    let image = TextureImage(width: decoded.width, height: decoded.height, rgba: decoded.rgba)
                    for format in [TexFormat.bc3, .bc1, .b8g8r8a8, .a8] {
                        let encoded = TextureCodec.encode(image, format: format, mips: 9)
                        guard let result = try? Atex.decode(encoded) else { worst["\(format.name)", default: 0] = 999; continue }
                        var sum = 0.0
                        var count = 0
                        for i in stride(from: 0, to: image.rgba.count, by: 4) {
                            for k in (format == .a8 ? [3] : format == .bc1 ? [0, 1, 2] : [0, 1, 2, 3]) {
                                if format == .bc1 && image.rgba[i + 3] < 128 { continue }
                                let d = Double(image.rgba[i + k]) - Double(result.rgba[i + k]); sum += d * d; count += 1
                            }
                        }
                        worst[format.name] = max(worst[format.name, default: 0], count > 0 ? (sum / Double(count)).squareRoot() : 0)
                    }
                    identityTotal += 1
                    let r4 = image.rotated(clockwise: true).rotated(clockwise: true).rotated(clockwise: true).rotated(clockwise: true)
                    let f2 = image.flipped(horizontal: true).flipped(horizontal: true).flipped(horizontal: false).flipped(horizontal: false)
                    let lr = image.rotated(clockwise: true).rotated(clockwise: false)
                    if r4.rgba == image.rgba && f2.rgba == image.rgba && lr.rgba == image.rgba { identity += 1 }
                }
                log.append("CODEC textures=\(files.count) ddsRoundTrip=\(ddsSame)/\(ddsTotal) worstRMS=\(worst.map { "\($0.key):\(String(format: "%.1f", $0.value))" }.sorted()) transformsIdentity=\(identity)/\(identityTotal)")
            } catch { log.append("CODEC FAILED \(error)") }
        case "paramcopy":
            if let doc = app?.document, let a = doc.node(parts[1]), let b = doc.node(parts[2]) {
                let original = doc.serializedData()
                ParameterClipboard.copy(a, in: doc)
                ParameterClipboard.paste(into: b, in: doc)
                let fa = Dictionary(uniqueKeysWithValues: doc.sections(for: doc.node(parts[1])!).flatMap(\.fields).filter { $0.write != nil }.map { (String($0.id.dropFirst(parts[1].count)), $0.read()) })
                var same = 0, differ: [String] = []
                for f in doc.sections(for: doc.node(parts[2])!).flatMap(\.fields) where f.write != nil { if let v = fa[String(f.id.dropFirst(parts[2].count))] { if v == f.read() { same += 1 } else { differ.append(f.label) } } }
                let ok = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                doc.undo()
                log.append("PARAMCOPY same=\(same) differ=\(differ.prefix(6)) reparse=\(ok) undoRestores=\(doc.serializedData() == original)")
            }
        case "texwin":
            if let app {
                app.textureEditorTarget = parts[1]
                let w = TestWindow(contentRect: NSRect(x: 60, y: 80, width: 1100, height: 720), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
                w.isReleasedWhenClosed = false
                w.contentView = TestHost(rootView: TextureEditorView().environmentObject(app))
                w.orderFrontRegardless()
                DebugDriver.extra = w
            }
            delay = 1.2
        case "focusextra": if let e = DebugDriver.extra { DebugDriver.main = DebugDriver.own; DebugDriver.own = e }
        case "focusmain": if let m = DebugDriver.main { DebugDriver.own = m }
        case "extract":
            if let app {
                let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent)
                let out = URL(fileURLWithPath: dir + "/extracted")
                try? FileManager.default.removeItem(at: out)
                do { let n = try app.extractMod(root.appendingPathComponent(parts[1]), into: out); log.append("EXTRACT \(n) files") } catch { log.append("EXTRACT FAILED \(error)") }
            }
        case "convert":
            if let app, let doc = app.document { app.convertTextures(); log.append("CONVERT " + doc.textureSlots.map(\.path).prefix(3).joined(separator: " | ") + " custom=\(doc.textureSlots.filter { app.isCustomTexture($0.path) }.count) notice=\(app.notice ?? "-")") }
            delay = 0.3
        case "rename":
            if let doc = app?.document { doc.setName(parts.dropFirst(2).joined(separator: " "), for: parts[1]); log.append("RENAME title=\(doc.node(parts[1])?.title ?? "?") detail=\(doc.node(parts[1])?.detail ?? "?") file=\(FileManager.default.fileExists(atPath: doc.url.deletingPathExtension().appendingPathExtension("names.json").path))") }
        case "autosave":
            if let app, let doc = app.document {
                let n = app.autosaveNow()
                let files = ((try? FileManager.default.contentsOfDirectory(at: app.autosaveFolder!, includingPropertiesForKeys: nil)) ?? []).filter { $0.lastPathComponent.hasPrefix(doc.url.deletingPathExtension().lastPathComponent + "-") }
                let same = files.last.flatMap { try? Data(contentsOf: $0) } == doc.serializedData()
                log.append("AUTOSAVE wrote=\(n) files=\(files.count) identical=\(same)")
                files.forEach { try? FileManager.default.removeItem(at: $0) }
            }
        case "nodeinfo":
            if let doc = app?.document, let n = doc.node(parts[1]) {
                log.append("NODE \(parts[1]) children=\(n.children.map(\.title)) curves=\(doc.curveGroups(for: n).map { "\($0.title)(\($0.channels.count))" }) fields=\(doc.sections(for: n).flatMap(\.fields).map(\.label))")
                for c in n.children { log.append("   child \(c.id) curves=\(doc.curveGroups(for: c).map { "\($0.title)(\($0.channels.count))" }) children=\(c.children.map(\.title))") }
            } else { log.append("NODE \(parts[1]) missing") }
        case "libtest":
            if let app, let doc = app.document {
                do {
                    doc.setName("Splash Ring", for: "avfx/Ptcl/0")
                    let url = try app.saveToNodeLibrary("avfx/Ptcl/0", name: "Test/Splash Ring")
                    let items = app.nodeLibraryItems.map(\.name)
                    let before = doc.avfxRoot?.childrenNamed("Ptcl").count ?? 0
                    let count = try doc.importNodes(Data(contentsOf: url), legacy: false)
                    let after = doc.avfxRoot?.childrenNamed("Ptcl").count ?? 0
                    let newName = doc.node("avfx/Ptcl/\(after - 1)")?.title ?? "?"
                    let ok = (try? AvfxBlock.parseFile([UInt8](doc.serializedData()))) != nil
                    doc.undo()
                    doc.setName("", for: "avfx/Ptcl/0")
                    doc.setName("", for: "avfx/Ptcl/\(after - 1)")
                    try? FileManager.default.removeItem(at: url)
                    log.append("LIBRARY items=\(items) imported=\(count) particles \(before)->\(after) importedName=\(newName) reparse=\(ok)")
                } catch { log.append("LIBRARY FAILED \(error)") }
            }
        case "wstest":
            if let app {
                do {
                    let url = try app.saveWorkspace(named: "testws")
                    let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                    let files = app.openDocuments.map(\.title)
                    log.append("WORKSPACE saved open=\(files) listed=\(app.workspaceFiles.map(\.lastPathComponent)) json=\(text.replacingOccurrences(of: "\n", with: " ").prefix(220))")
                    app.openWorkspace(url)
                    log.append("WORKSPACE reopened current=\(app.document?.title ?? "-") notice=\(app.notice ?? "-")")
                    let other = app.files.first { $0.isAvfx && !files.contains($0.name) }
                    if let other { app.open(other.url) }
                    app.openWorkspace(url, append: true)
                    log.append("WORKSPACE appended open=\(app.openDocuments.count) current=\(app.document?.title ?? "-") kept=\(app.document?.url == other?.url)")
                    app.openWorkspace(url)
                    log.append("WORKSPACE replaced open=\(app.openDocuments.map(\.title)) current=\(app.document?.title ?? "-")")
                    try? FileManager.default.removeItem(at: url)
                } catch { log.append("WORKSPACE FAILED \(error)") }
            }
        case "multimod":
            if let app {
                do {
                    let effects = app.openDocuments.filter { $0.format == .avfx }.map { (document: $0, path: PenumbraExport.guessEffectPath($0)) }
                    let data = try app.modArchive(ModDescription(name: "Multi", author: "me"), effects: effects, textures: [])
                    try data.write(to: URL(fileURLWithPath: dir + "/multi.pmp"))
                    log.append("MULTIMOD effects=\(effects.map(\.path)) bytes=\(data.count)")
                    if effects.count >= 2 {
                        var group = ModGroup(name: "Colour Set", multi: false, options: ["Blue", "Red"])
                        group.effects = [effects[0].document.id: 1, effects[1].document.id: 2]
                        let same = effects.prefix(2).map { (document: $0.document, path: "vfx/shared/eff/one.avfx") } + effects.dropFirst(2)
                        let texture = effects[0].document.textureSlots.map(\.path).first { app.textureURL($0)?.pathExtension.lowercased() == "atex" }
                        if let texture { group.textures[texture] = 2 }
                        let grouped = try app.modArchive(ModDescription(name: "Grouped", author: "me"), effects: same, textures: texture.map { [$0] } ?? [], group: group)
                        try grouped.write(to: URL(fileURLWithPath: dir + "/grouped.pmp"))
                        let clash = (try? app.modArchive(ModDescription(name: "Clash"), effects: same, textures: [])) == nil
                        log.append("GROUPMOD bytes=\(grouped.count) texture=\(texture ?? "-") clashWithoutGroup=\(clash)")
                    }
                } catch { log.append("MULTIMOD FAILED \(error)") }
            }
        case "sqround":
            if let app, let root = app.libraryRoot, let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) {
                var total = 0, bad: [String] = []
                for case let url as URL in walker where ["avfx", "atex", "tex"].contains(url.pathExtension.lowercased()) {
                    guard let data = try? Data(contentsOf: url) else { continue }
                    let bytes = [UInt8](data)
                    total += 1
                    if (try? SqPackDat.read(Data(TexToolsExport.standardEntry(bytes)), at: 0)) != data { bad.append("std " + url.lastPathComponent) }
                    if url.pathExtension.lowercased() != "avfx" {
                        if let entry = TexToolsExport.textureEntry(bytes) {
                            if (try? SqPackDat.read(Data(entry), at: 0)) != data { bad.append("tex " + url.lastPathComponent) }
                        } else { bad.append("noentry " + url.lastPathComponent) }
                    }
                }
                log.append("SQROUND files=\(total) bad(\(bad.count))=\(bad.prefix(6))")
            }
        case "game":
            if let app {
                do {
                    try app.setGameFolder(URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent + "/" + parts[1]))
                    let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent)
                    var index = 2
                    while index + 1 < parts.count {
                        let read = try app.game?.read(parts[index])
                        let source = try Data(contentsOf: root.appendingPathComponent(parts[index + 1]))
                        log.append("GAME read \(parts[index]) bytes=\(read?.count ?? -1) same=\(read == source)")
                        index += 2
                    }
                    if let game = app.game {
                        let found = DispatchQueue.global().sync { game.available(["vfx/sqtest/eff/sq_a.avfx", "vfx/sqtest/eff/none.avfx", "vfx/sqtest/texture/sq_big.atex"]) }
                        log.append("GAME background available=\(found.sorted())")
                    }
                    log.append("GAME contains missing=\(app.game?.contains("vfx/sqtest/eff/none.avfx") ?? true) error=\((try? app.game?.read("vfx/sqtest/eff/none.avfx")) == nil)")
                    try app.openFromGame("VFX\\sqtest\\eff\\sq_a.avfx")
                    log.append("GAME opened=\(app.document?.url.path.hasSuffix("vfx/sqtest/eff/sq_a.avfx") ?? false) gamePath=\(app.document?.gamePath ?? "-") notice=\(app.notice ?? "-")")
                    if let doc = app.document, let tex = doc.avfxRoot?.childrenNamed("Tex").first {
                        tex.stringValue = "vfx/sqtest/texture/sq_big.atex"
                        let before = app.missingTextures(in: doc)
                        let result = app.fetchTextures(for: doc)
                        let image = app.image(for: "vfx/sqtest/texture/sq_big.atex")
                        log.append("GAME missingBefore=\(before) fetched=\(result.fetched) stillMissing=\(result.missing) image=\(image.map { "\($0.width)x\($0.height)" } ?? "nil")")
                        tex.stringValue = "vfx/sqtest/texture/absent.atex"
                        let second = app.fetchTextures(for: doc)
                        log.append("GAME absent fetched=\(second.fetched) missing=\(second.missing)")
                    }
                } catch { log.append("GAME FAILED \(error.localizedDescription)") }
            }
        case "ttmp":
            if let app {
                do {
                    let effects = app.openDocuments.filter { $0.format == .avfx }.map { (document: $0, path: PenumbraExport.guessEffectPath($0)) }
                    let textures = effects.flatMap { $0.document.textureSlots.map(\.path) }.filter { app.textureURL($0)?.pathExtension.lowercased() == "atex" }
                    let data = try app.texToolsArchive(ModDescription(name: "TT \"quoted\"", author: "me"), effects: effects, textures: textures)
                    try data.write(to: URL(fileURLWithPath: dir + "/test.ttmp2"))
                    for effect in effects { try effect.document.serializedData().write(to: URL(fileURLWithPath: dir + "/" + (effect.path as NSString).lastPathComponent)) }
                    log.append("TTMP effects=\(effects.map(\.path)) textures=\(Set(textures).count) bytes=\(data.count)")
                } catch { log.append("TTMP FAILED \(error)") }
            }
        case "libmeta":
            if let app, let doc = app.document {
                do {
                    let url = try app.saveToNodeLibrary(parts[1], name: "ZTest/Entry A")
                    guard let entry = app.libraryEntry(for: url) else { log.append("LIBMETA no entry"); break }
                    app.setLibraryColor(entry, 4)
                    app.setLibraryNote(entry, "A test note")
                    let stored = app.libraryEntry(for: url)
                    let moved = try app.moveLibraryEntry(stored ?? entry, to: "ZOther/Entry B")
                    let after = app.nodeLibraryEntries.first { $0.id == moved }
                    let before = doc.avfxRoot?.childrenNamed("Ptcl").count ?? 0
                    if let after { app.importFromNodeLibrary(after.url) }
                    log.append("LIBMETA stored=\(stored?.color ?? -1)/\(stored?.note ?? "-") moved=\(moved) kept=\(after?.color ?? -1)/\(after?.note ?? "-") folder=\(after?.folder ?? "-") oldGone=\(app.libraryEntry(for: url) == nil) folders=\(app.nodeLibraryFolders.filter { $0.hasPrefix("Z") }) imported=\((doc.avfxRoot?.childrenNamed("Ptcl").count ?? 0) - before)")
                    doc.undo()
                    if let after { try app.removeLibraryEntry(after) }
                    app.removeLibraryFolder("ZTest")
                    app.removeLibraryFolder("ZOther")
                    log.append("LIBMETA cleaned entries=\(app.nodeLibraryEntries.filter { $0.id.hasPrefix("Z") }.count) folders=\(app.nodeLibraryFolders.filter { $0.hasPrefix("Z") }) meta=\(app.nodeLibraryMeta.keys.filter { $0.hasPrefix("Z") })")
                } catch { log.append("LIBMETA FAILED \(error.localizedDescription)") }
            }
        case "imgconvert":
            if let app {
                let root = URL(fileURLWithPath: (dir as NSString).deletingLastPathComponent)
                let out = URL(fileURLWithPath: dir + "/converted")
                let source = root.appendingPathComponent(parts[1])
                var lines: [String] = []
                do {
                    let png = try app.convertImage(source, to: .png, into: out, reencode: false)
                    let dds = try app.convertImage(source, to: .dds, into: out, reencode: false)
                    let back = try app.convertImage(dds, to: .atex, into: out, reencode: false)
                    let fromPng = try app.convertImage(png, to: .tex, into: out, reencode: false)
                    let again = try app.convertImage(source, to: .atex, into: out, reencode: true)
                    let original = try Data(contentsOf: source)
                    let a = try Atex.decode([UInt8](original)), b = try Atex.decode([UInt8](try Data(contentsOf: fromPng))), c = try Atex.decode([UInt8](try Data(contentsOf: again)))
                    func rms(_ x: [UInt8], _ y: [UInt8]) -> Double {
                        guard x.count == y.count, !x.isEmpty else { return -1 }
                        var sum = 0.0
                        for i in x.indices { let d = Double(x[i]) - Double(y[i]); sum += d * d }
                        return (sum / Double(x.count)).squareRoot()
                    }
                    lines.append("png=\(NSImage(contentsOf: png).map { "\(Int($0.representations.first?.pixelsWide ?? 0))" } ?? "nil") ddsRoundTrip=\(try Data(contentsOf: back) == original)")
                    lines.append("fromPng=\(b.formatName) \(b.width)x\(b.height) mips=\(b.mipLevels) rms=\(String(format: "%.2f", rms(a.rgba, b.rgba)))")
                    lines.append("reencoded=\(c.formatName) mips=\(c.mipLevels) rms=\(String(format: "%.2f", rms(a.rgba, c.rgba))) names=\([png, dds, back, fromPng, again].map(\.lastPathComponent))")
                    let bad = app.convertImages([root.appendingPathComponent("m0016/eff/m0016cr_01t0t.avfx")], to: .png, into: out, reencode: false)
                    lines.append("bad failures=\(bad.failures.count) written=\(bad.written.count)")
                    app.errorMessage = nil
                } catch { lines.append("FAILED \(error.localizedDescription)") }
                log.append("IMGCONVERT " + lines.joined(separator: " | "))
            }
        case "tmbtest":
            var blob = Data([0x54, 0x4D, 0x4C, 0x42, 0, 0, 0, 1])
            for text in ["vfx/common/eff/abc_01.avfx", "junk", "VFX/Monster/m0016/eff/m0016cr_01t0t.avfx", "vfx/common/eff/abc_01.avfx", "sound/vfx/se.scd", "vfx/x.atex"] {
                blob.append(contentsOf: [1, 0, 0])
                blob.append(Data(text.utf8))
                blob.append(0)
            }
            log.append("TMB paths=\(AppModel.effectPaths(in: blob))")
            app?.listEffects(of: blob, title: "test.tmb")
            delay = 0.8
        case "libseed":
            if let app {
                if let a = try? app.saveToNodeLibrary("avfx/Ptcl/0", name: "ZShots/Glow ring with a rather long entry name"), let entry = app.libraryEntry(for: a) {
                    app.setLibraryColor(entry, 5)
                    app.setLibraryNote(entry, "Soft ring used by the charge-up")
                }
                if let b = try? app.saveToNodeLibrary("avfx/Emit/0", name: "ZShots/Burst"), let entry = app.libraryEntry(for: b) { app.setLibraryColor(entry, 2) }
                _ = try? app.saveToNodeLibrary("avfx/Tex/0", name: "ZLoose")
            }
            delay = 0.6
        case "libclean":
            if let app {
                for entry in app.nodeLibraryEntries where entry.id.hasPrefix("Z") { try? app.removeLibraryEntry(entry) }
                app.removeLibraryFolder("ZShots")
                log.append("LIBCLEAN left=\(app.nodeLibraryEntries.filter { $0.id.hasPrefix("Z") }.count)")
            }
        case "convertsheet": app?.convertImages = true; delay = 1.0
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
    var fakeMouse: NSPoint?
    override var mouseLocationOutsideOfEventStream: NSPoint { fakeMouse ?? super.mouseLocationOutsideOfEventStream }
    override var isKeyWindow: Bool { true }
    override var isMainWindow: Bool { true }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
#endif
