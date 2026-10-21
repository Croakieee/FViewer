import SwiftUI
import WebKit

final class PlayerWebView: WKWebView {
    weak var bridge: PlayerBridge?

    override func keyDown(with event: NSEvent) {
        guard let bridge, event.modifierFlags.intersection([.command, .option, .control]).isEmpty, let key = event.charactersIgnoringModifiers else {
            return super.keyDown(with: event)
        }
        switch key {
        case "1": bridge.look(from: SIMD3(0, 0, 1))
        case "3": bridge.look(from: SIMD3(1, 0, 0))
        case "7": bridge.look(from: SIMD3(0, 1, 0.001))
        case ".": bridge.resetCamera()
        default: super.keyDown(with: event)
        }
    }
}

struct PlayerViewport: NSViewRepresentable {
    let bridge: PlayerBridge
    let document: EffectDocument
    let app: AppModel
    let revision: Int

    func makeNSView(context: Context) -> PlayerWebView {
        let config = WKWebViewConfiguration()
        let handler = PlayerSchemeHandler()
        handler.bridge = bridge
        config.setURLSchemeHandler(handler, forURLScheme: PlayerSchemeHandler.scheme)
        config.userContentController.add(PlayerMessageProxy(bridge), name: "avfx")
        let webView = PlayerWebView(frame: .zero, configuration: config)
        webView.bridge = bridge
        webView.underPageBackgroundColor = .black
        #if DEBUG
        webView.isInspectable = true
        #endif
        bridge.attach(webView)
        bridge.app = app
        webView.load(URLRequest(url: PlayerSchemeHandler.pageURL))
        return webView
    }

    func updateNSView(_ webView: PlayerWebView, context: Context) {
        bridge.sync(document: document, app: app)
    }

    static func dismantleNSView(_ webView: PlayerWebView, coordinator: ()) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "avfx")
    }
}

struct PlayerStatus: View {
    @ObservedObject var bridge: PlayerBridge

    var body: some View {
        Group {
            if !PlayerSchemeHandler.hasPlayer {
                note("The preview player was not built into the app. Build ffxiv-docs/dev_ffxiv_avfx_preview with yarn build:player, then build FViewer again.")
            } else if let failure = bridge.failure {
                note(failure)
            } else if bridge.loading {
                Text("Loading preview…").font(Theme.small).foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(10)
        .allowsHitTesting(bridge.failure != nil)
    }

    private func note(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color(red: 1, green: 0.75, blue: 0.3))
            Text(text).font(Theme.small).foregroundStyle(Theme.text).textSelection(.enabled)
            if bridge.failure != nil {
                Text("Reload").font(Theme.small).underline().foregroundStyle(Theme.text).pressable { bridge.restartPage() }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.panel.opacity(0.92)))
    }
}

struct PlayerFooter: View {
    @ObservedObject var bridge: PlayerBridge
    @ObservedObject var clock: PlaybackClock
    @State private var showMissing = false

    private func readout(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundStyle(Theme.dim)
            Text(value).foregroundStyle(Theme.text)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            readout("effect", "\(bridge.emitters) emitters · \(bridge.particles) particles")
            readout("time", String(format: "%.2f s · frame %d", clock.time / 30, Int(safe: clock.time.rounded())))
            if !bridge.missing.isEmpty {
                Text("\(bridge.missing.count) missing")
                    .foregroundStyle(Color(red: 1, green: 0.75, blue: 0.3))
                    .pressable { showMissing.toggle() }
                    .help("Game files the preview asked for and could not find")
                    .popover(isPresented: $showMissing, arrowEdge: .top) { missingList }
            }
            Spacer(minLength: 4)
            if !bridge.build.isEmpty {
                Text("player " + String(bridge.build.prefix(7))).foregroundStyle(Theme.dim)
                    .help("Build of the preview player in this app (commit of dev_ffxiv_avfx_preview)")
            }
            HeaderButton(symbol: "arrow.counterclockwise", help: "Reset View: the default angle") { bridge.resetCamera() }
            HStack(spacing: 4) {
                Text("FOV").foregroundStyle(Theme.dim)
                NumberField(label: nil, value: bridge.fov, suffix: "°", step: 0.5, digits: 0,
                            onLive: { bridge.setFov($0) }, onCommit: { _, next in bridge.setFov(next) })
                    .frame(width: 56)
            }
            CheckBox(isOn: clock.lockSeed, label: "lock seed") { clock.lockSeed = $0 }.fixedSize()
                .help("On: every replay uses the same random seed. Off: each loop picks up where the random draws left off, so replays vary")
        }
        .font(.system(size: 10, design: .monospaced))
        .lineLimit(1)
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(Theme.header)
    }

    private var missingList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Not found in the library or the game").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(bridge.missing, id: \.self) { Text($0).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.text).textSelection(.enabled) }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .frame(width: 420)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}
