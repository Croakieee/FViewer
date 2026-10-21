import Foundation
import UniformTypeIdentifiers
import WebKit

final class PlayerSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "avfx"
    static let pageURL = URL(string: "avfx://app/player/host.html")!

    static var folder: URL? { Bundle.main.resourceURL?.appendingPathComponent("Player", isDirectory: true) }

    static var hasPlayer: Bool {
        guard let folder else { return false }
        return FileManager.default.fileExists(atPath: folder.appendingPathComponent("avfx-player.iife.js").path)
    }

    weak var bridge: PlayerBridge?
    private var live: Set<ObjectIdentifier> = []

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        live.insert(ObjectIdentifier(task))
        let parts = url.path.split(separator: "/").map(String.init)
        let rest = parts.dropFirst().joined(separator: "/")
        guard !parts.contains(".."), let area = parts.first else { return answer(task, url, nil, mime: "") }
        switch area {
        case "player":
            load(task, url, Self.folder?.appendingPathComponent(rest))
        case "game":
            serveGame(task, url, rest)
        case "doc":
            answer(task, url, bridge?.documentData(rest), mime: "application/octet-stream")
        default:
            answer(task, url, nil, mime: "")
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {
        live.remove(ObjectIdentifier(task))
    }

    private func serveGame(_ task: WKURLSchemeTask, _ url: URL, _ path: String) {
        if let file = bridge?.libraryFile(path) { return load(task, url, file) }
        guard let game = bridge?.app?.game else { return answer(task, url, nil, mime: "") }
        DispatchQueue.global(qos: .userInitiated).async {
            let data = try? game.read(path)
            DispatchQueue.main.async { self.answer(task, url, data, mime: "application/octet-stream") }
        }
    }

    private func load(_ task: WKURLSchemeTask, _ url: URL, _ file: URL?) {
        guard let file else { return answer(task, url, nil, mime: "") }
        let mime = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        DispatchQueue.global(qos: .userInitiated).async {
            let data = try? Data(contentsOf: file)
            DispatchQueue.main.async { self.answer(task, url, data, mime: mime) }
        }
    }

    private func answer(_ task: WKURLSchemeTask, _ url: URL, _ data: Data?, mime: String) {
        guard live.remove(ObjectIdentifier(task)) != nil else { return }
        guard let data else {
            task.didReceive(HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Cache-Control": "no-store"])!)
            task.didFinish()
            return
        }
        let headers = ["Content-Type": mime, "Content-Length": String(data.count), "Cache-Control": "no-store"]
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!)
        task.didReceive(data)
        task.didFinish()
    }
}
