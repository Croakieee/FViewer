import AppKit
import Combine
import simd
import WebKit

final class PlayerMessageProxy: NSObject, WKScriptMessageHandler {
    weak var bridge: PlayerBridge?

    init(_ bridge: PlayerBridge) {
        self.bridge = bridge
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        bridge?.receive(message.body)
    }
}

final class PlayerBridge: NSObject, ObservableObject, WKNavigationDelegate {
    static let protocolVersion = 1
    static weak var main: PlayerBridge?
    private static let drivers = NSMapTable<NSString, PlayerBridge>.strongToWeakObjects()

    @Published private(set) var failure: String?
    @Published private(set) var missing: [String] = []
    @Published private(set) var warnings: [String] = []
    @Published private(set) var particles = 0
    @Published private(set) var emitters = 0
    @Published private(set) var fov = 45.0
    @Published private(set) var build = ""
    @Published private(set) var loading = true

    weak var webView: WKWebView?
    weak var app: AppModel?
    private weak var document: EffectDocument?
    private var ready = false
    private var clockBindings: Set<AnyCancellable> = []
    private var documents: [(key: String, data: Data)] = []
    private var docCounter = 0
    private var openedDocument: UUID?
    private var loadedSource = ""
    private var loadedBytes: Data?
    private var openedPaths: [String] = []
    private var applied: [String: String] = [:]
    private var reloadWork: DispatchWorkItem?
    private var reportedFrame = 0.0
    private var restartToken = 0
    private var seekToken = 0
    private var seekTarget: (frame: Double, play: Bool)?
    private var seeking = false
    private var libraryToken = -1
    private var schemaCache: (revision: Int, schema: REffectSchema)?
    private var pushQueued = false
    private var outbox: [(object: String, method: String, args: [Any])] = []
    private var pumping = false

    func attach(_ webView: WKWebView) {
        self.webView = webView
        webView.navigationDelegate = self
        PlayerBridge.main = self
    }

    func sync(document: EffectDocument, app: AppModel) {
        self.app = app
        PlayerBridge.main = self
        if document !== self.document {
            self.document = document
            openedDocument = nil
            bindClock(document.clock)
        }
        if PlayerBridge.drivers.object(forKey: document.id.uuidString as NSString) == nil {
            PlayerBridge.drivers.setObject(self, forKey: document.id.uuidString as NSString)
        }
        push()
    }

    private var isDriver: Bool {
        guard let document else { return false }
        return PlayerBridge.drivers.object(forKey: document.id.uuidString as NSString) === self
    }

    private func bindClock(_ clock: PlaybackClock) {
        clockBindings = []
        clock.$playing.dropFirst().removeDuplicates().sink { [weak self] playing in
            DispatchQueue.main.async { self?.setPlaying(playing) }
        }.store(in: &clockBindings)
        let refresh: () -> Void = { [weak self] in self?.queuePush() }
        clock.$events.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$startFrame.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$endFrame.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$loop.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$lockSeed.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$seed.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.$speed.dropFirst().sink { _ in refresh() }.store(in: &clockBindings)
        clock.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async { self?.checkTime() }
        }.store(in: &clockBindings)
    }

    private func queuePush() {
        guard !pushQueued else { return }
        pushQueued = true
        DispatchQueue.main.async { [weak self] in
            self?.pushQueued = false
            self?.push()
        }
    }

    private func push() {
        guard ready, let document, let app, document.format == .avfx else { return }
        let clock = document.clock
        apply("fvHost", "setSeed", [clock.seed])
        apply("avfxHost", "setView", [viewSettings(app)])
        apply("avfxHost", "setStage", [stageSettings(app)])
        apply("avfxHost", "setHidden", [hidden(document)])
        apply("avfxHost", "setSpeed", [min(max(clock.speed, 0), 2)])
        apply("fvHost", "setEvents", [clock.events.map(PlayerBridge.event)])
        let end = clock.endFrame ?? max(document.duration, clock.lastEventFrame + 1)
        apply("fvHost", "setPlayback", [["start": clock.startFrame, "end": end, "loop": clock.loop, "lockSeed": clock.lockSeed]])
        if openedDocument != document.id {
            libraryToken = app.libraryToken
            open(document)
            return
        }
        if app.libraryToken != libraryToken {
            libraryToken = app.libraryToken
            enqueue("avfxHost", "invalidate", [openedPaths])
        }
        if source(document) != loadedSource { scheduleReload() }
    }

    private func source(_ document: EffectDocument) -> String { "\(document.previewRevision)|\(document.showOriginal)" }

    private func viewSettings(_ app: AppModel) -> [String: Any] {
        let look = PreviewSettings.look
        let shade = AppModel.backgrounds[min(max(app.viewportBackground, 0), AppModel.backgrounds.count - 1)].value
        let color = PreviewSettings.backgroundColor ?? SIMD3(shade, shade, shade)
        let hex = String(format: "#%02x%02x%02x", Int((min(max(color.x, 0), 1) * 255).rounded()),
                         Int((min(max(color.y, 0), 1) * 255).rounded()), Int((min(max(color.z, 0), 1) * 255).rounded()))
        return ["background": hex, "toneMapping": look.toneMap, "exposure": Double(look.exposure), "lightIntensity": Double(look.lightIntensity),
                "floor": app.showFloor, "relief": app.showRelief, "grid": app.showFloor, "loop": false, "wireframe": app.effectShading != 0, "emitters": app.showEmitters]
    }

    private func stageSettings(_ app: AppModel) -> [String: Any] {
        let stage = PreviewSettings.stage
        func mover(_ m: StageMover) -> [String: Any] {
            ["motion": m.motion.playerName, "amp": Double(m.amplitude), "period": Double(m.period), "jump": m.jump,
                    "jumpHeight": Double(m.jumpHeight), "jumpPeriod": Double(m.jumpPeriod)]
        }
        return ["showCaster": app.showBindPoints, "bindMarkers": app.showBindPoints, "showTarget": stage.showTarget, "distance": Double(stage.distance),
                "side": Double(stage.side), "face": stage.faceEachOther, "casterMotion": mover(stage.caster), "targetMotion": mover(stage.target)]
    }

    private nonisolated static func event(_ event: PreviewEvent) -> [String: Any] {
        switch event.kind {
        case .trigger(let index): return ["frame": event.frame, "kind": "trigger", "index": index, "muted": event.muted]
        case .release: return ["frame": event.frame, "kind": "release", "index": 0, "muted": event.muted]
        case .stop: return ["frame": event.frame, "kind": "stop", "index": 0, "muted": event.muted]
        }
    }

    private func schema(_ document: EffectDocument) -> REffectSchema? {
        if let cached = schemaCache, cached.revision == document.previewRevision { return cached.schema }
        guard let root = document.avfxRoot else { return nil }
        let schema = AvfxSchemaReader.read(root)
        schemaCache = (document.previewRevision, schema)
        return schema
    }

    private func hidden(_ document: EffectDocument) -> [String: Any] {
        let filter = document.visibilityFilter
        guard !filter.isEmpty else { return [:] }
        var particles = Set<Int>(), emitters = Set<Int>(), timelines = Set<Int>()
        for key in filter.hidden {
            switch key {
            case .particle(let index): particles.insert(index)
            case .emitter(let index): emitters.insert(index)
            case .timeline(let index): timelines.insert(index)
            }
        }
        if let isolated = filter.isolated, let schema = schema(document) {
            switch isolated {
            case .particle(let index):
                particles.formUnion(schema.particles.indices.filter { $0 != index })
            case .timeline(let index):
                timelines.formUnion(schema.timelines.indices.filter { $0 != index })
            case .emitter(let index):
                func children(_ i: Int) -> [Int] {
                    guard schema.emitters.indices.contains(i) else { return [] }
                    return schema.emitters[i].emitterItems.map(\.target).filter { schema.emitters.indices.contains($0) }
                }
                var subtree: Set<Int> = []
                var stack = [index]
                while let next = stack.popLast() {
                    if subtree.insert(next).inserted { stack.append(contentsOf: children(next)) }
                }
                var ancestors: Set<Int> = []
                var grew = true
                while grew {
                    grew = false
                    for i in schema.emitters.indices where !ancestors.contains(i) && !subtree.contains(i) {
                        if children(i).contains(where: { subtree.contains($0) || ancestors.contains($0) }) {
                            ancestors.insert(i)
                            grew = true
                        }
                    }
                }
                emitters.formUnion(schema.emitters.indices.filter { !subtree.contains($0) && !ancestors.contains($0) })
                let own = Set(subtree.flatMap { schema.emitters[$0].particleItems.map(\.target) })
                particles.formUnion(ancestors.flatMap { schema.emitters[$0].particleItems.map(\.target) }.filter { !own.contains($0) })
            }
        }
        return ["particles": particles.sorted(), "emitters": emitters.sorted(), "timelines": timelines.sorted()]
    }

    static func bytes(of document: EffectDocument) -> Data? {
        guard let root = (document.showOriginal ? document.original?.avfxRoot : nil) ?? document.avfxRoot else { return nil }
        let copy = root.deepCopy()
        copy.updateCounts()
        copy.syncCumulativeLists()
        return Data(copy.serialized())
    }

    private func register(_ data: Data) -> String {
        docCounter += 1
        let key = "\(docCounter).avfx"
        documents.append((key, data))
        if documents.count > 4 { documents.removeFirst(documents.count - 4) }
        return "\(PlayerSchemeHandler.scheme)://app/doc/\(key)"
    }

    func documentData(_ key: String) -> Data? { documents.last { $0.key == key }?.data }

    func libraryFile(_ path: String) -> URL? {
        guard let url = app?.textureURL(path), url.pathExtension.lowercased() != "png" else { return nil }
        return url
    }

    private func open(_ document: EffectDocument) {
        openedDocument = document.id
        loadedSource = source(document)
        reloadWork?.cancel()
        missing = []
        warnings = []
        failure = nil
        guard let data = PlayerBridge.bytes(of: document) else { return }
        loadedBytes = data
        openedPaths = document.textureSlots.map(\.path)
        reportedFrame = 0
        let clock = document.clock
        restartToken = clock.restartToken
        seekToken = clock.seekToken
        loading = true
        enqueue("avfxHost", "open", [register(data), document.url.lastPathComponent])
        enqueue("fvHost", "frame", [])
        if clock.time > 0.5 || !clock.playing { seek(clock.time, play: clock.playing) }
    }

    private func scheduleReload() {
        reloadWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.reload() }
        reloadWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func reload() {
        guard ready, let document, openedDocument == document.id else { return }
        loadedSource = source(document)
        guard let data = PlayerBridge.bytes(of: document), data != loadedBytes else { return }
        loadedBytes = data
        openedPaths = document.textureSlots.map(\.path)
        enqueue("avfxHost", "reload", [register(data)])
    }

    private func setPlaying(_ playing: Bool) {
        guard ready, openedDocument != nil else { return }
        if playing { enqueue("fvHost", "play", []) } else { enqueue("avfxHost", "pause", []) }
    }

    private func checkTime() {
        guard ready, let document, openedDocument == document.id else { return }
        let clock = document.clock
        if clock.restartToken != restartToken {
            restartToken = clock.restartToken
            push()
        }
        if clock.seekToken != seekToken {
            seekToken = clock.seekToken
            seek(clock.seekFrame, play: clock.playing)
        } else if !isDriver, !clock.playing, abs(clock.time - reportedFrame) > 0.01 {
            seek(clock.time, play: false)
        }
    }

    private func seek(_ frame: Double, play: Bool) {
        reportedFrame = frame
        seekTarget = (frame, play)
        guard !seeking else { return }
        seeking = true
        pump()
    }

    private func apply(_ object: String, _ method: String, _ args: [Any]) {
        let key = object + "." + method
        guard let json = try? JSONSerialization.data(withJSONObject: args, options: [.sortedKeys]), let text = String(data: json, encoding: .utf8) else { return }
        guard applied[key] != text else { return }
        applied[key] = text
        enqueue(object, method, args)
    }

    private func enqueue(_ object: String, _ method: String, _ args: [Any]) {
        outbox.append((object, method, args))
        pump()
    }

    private func pump() {
        guard !pumping else { return }
        pumping = true
        Task { @MainActor [weak self] in
            while let self {
                if !self.outbox.isEmpty {
                    let next = self.outbox.removeFirst()
                    await self.perform(next.object, next.method, next.args)
                } else if let target = self.seekTarget {
                    self.seekTarget = nil
                    await self.perform("fvHost", "seekTo", [target.frame, target.play])
                    if self.seekTarget == nil { self.seeking = false }
                } else {
                    self.pumping = false
                    return
                }
            }
        }
    }

    private func perform(_ object: String, _ method: String, _ args: [Any]) async {
        do {
            _ = try await call(object, method, args)
        } catch {
            if method == "open" || method == "reload" { loading = false }
            failure = "\(method): \(error.localizedDescription)"
        }
    }

    @discardableResult
    func call(_ object: String, _ method: String, _ args: [Any] = []) async throws -> Any? {
        guard let webView else { return nil }
        return try await webView.callAsyncJavaScript("return await window[object][method](...args)",
                                                     arguments: ["object": object, "method": method, "args": args], contentWorld: .page)
    }

    func receive(_ body: Any) {
        guard let event = body as? [String: Any], let type = event["type"] as? String else { return }
        if let version = event["v"] as? Int, version != PlayerBridge.protocolVersion {
            failure = "The preview player speaks protocol \(version), FViewer speaks \(PlayerBridge.protocolVersion). Update both to the same version."
            return
        }
        switch type {
        case "ready":
            ready = true
            build = event["build"] as? String ?? ""
            applied = [:]
            openedDocument = nil
            failure = nil
            push()
        case "frame":
            receiveFrame(event)
        case "ended":
            if isDriver { document?.clock.playing = false }
        case "loaded":
            loading = false
            failure = nil
            warnings = event["warnings"] as? [String] ?? []
        case "warnings":
            warnings = event["warnings"] as? [String] ?? []
        case "missing":
            if let path = event["path"] as? String, !missing.contains(path) { missing.append(path) }
        case "camera":
            if let value = event["fov"] as? Double { fov = value }
        case "error":
            let message = event["message"] as? String ?? "Unknown error"
            loading = false
            if message == "webglcontextlost" { return restartPage() }
            failure = message
        default:
            break
        }
    }

    private func receiveFrame(_ event: [String: Any]) {
        let particles = event["particles"] as? Int ?? 0
        let emitters = event["emitters"] as? Int ?? 0
        if self.particles != particles { self.particles = particles }
        if self.emitters != emitters { self.emitters = emitters }
        guard !seeking, isDriver, let frame = event["frame"] as? Double, let clock = document?.clock, clock.seekToken == seekToken else { return }
        reportedFrame = frame
        clock.follow(frame, publish: !(event["playing"] as? Bool ?? true))
    }

    func restartPage() {
        ready = false
        loading = true
        applied = [:]
        outbox = []
        seekTarget = nil
        seeking = false
        openedDocument = nil
        webView?.load(URLRequest(url: PlayerSchemeHandler.pageURL))
    }

    private var crashes: [Double] = []

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let now = CACurrentMediaTime()
        crashes = crashes.filter { now - $0 < 10 } + [now]
        guard crashes.count <= 3 else {
            loading = false
            failure = "The preview stopped working: its web process quit \(crashes.count) times in a row."
            return
        }
        restartPage()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        failure = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        failure = error.localizedDescription
    }

    func resetCamera() {
        enqueue("fvHost", "frame", [])
        fov = 45
    }

    func setFov(_ value: Double) {
        fov = min(max(value, 8), 90)
        enqueue("avfxHost", "setCamera", [["fov": fov]])
    }

    func look(from direction: SIMD3<Double>) {
        Task { @MainActor in
            guard let state = try? await call("avfxHost", "getCamera") as? [String: Any],
                  let position = state["position"] as? [Double], let target = state["target"] as? [Double], position.count == 3, target.count == 3 else { return }
            let from = SIMD3(position[0], position[1], position[2]), to = SIMD3(target[0], target[1], target[2])
            let distance = max(simd_length(from - to), 0.5)
            let next = to + simd_normalize(direction) * distance
            enqueue("avfxHost", "setCamera", [["position": [next.x, next.y, next.z], "target": target]])
        }
    }

    func snapshot(_ done: @escaping (CGImage?) -> Void) {
        Task { @MainActor in
            guard let url = try? await call("avfxHost", "snapshot") as? String, let comma = url.firstIndex(of: ","),
                  let data = Data(base64Encoded: String(url[url.index(after: comma)...])),
                  let source = CGImageSourceCreateWithData(data as CFData, nil) else { return done(nil) }
            done(CGImageSourceCreateImageAtIndex(source, 0, nil))
        }
    }
}
