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
