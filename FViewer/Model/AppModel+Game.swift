import AppKit
import Foundation

extension AppModel {
    static let gameBookmarkKey = "gameBookmark"

    func chooseGameFolder() {
        let panel = NSOpenPanel()
        panel.title = "Game Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        panel.directoryURL = gameRoot
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try setGameFolder(url)
            if let bookmark = try? url.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: AppModel.gameBookmarkKey) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setGameFolder(_ url: URL) throws {
        let archive = try GameArchive(root: url)
        game = archive
        gameRoot = archive.root
        notice = "Game archives: \(archive.archiveCount) in \(archive.root.lastPathComponent)"
    }

    func restoreGameFolder() {
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--game"), flag + 1 < arguments.count {
            try? setGameFolder(URL(fileURLWithPath: arguments[flag + 1]))
            return
        }
        guard let bookmark = UserDefaults.standard.data(forKey: AppModel.gameBookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) else { return }
        _ = url.startAccessingSecurityScopedResource()
        try? setGameFolder(url)
        notice = nil
    }

    var gameExtractFolder: URL? {
        if let libraryRoot { return libraryRoot }
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        return base.appendingPathComponent("FViewer/Game")
    }

    func fetchFromGame(_ gamePath: String) throws -> URL {
        guard let game else { throw AvfxError.malformed("Choose the game folder first") }
        let path = PenumbraExport.normalized(gamePath)
        if let problem = PenumbraExport.problem(in: path) { throw AvfxError.malformed(problem) }
        guard let folder = gameExtractFolder else { throw AvfxError.malformed("No folder to extract into") }
        let destination = path.split(separator: "/").reduce(folder) { $0.appendingPathComponent(String($1)) }
        if FileManager.default.fileExists(atPath: destination.path) { return destination }
        let data = try game.read(path)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
        return destination
    }

    func missingTextures(in document: EffectDocument) -> [String] {
        var seen: Set<String> = []
        return document.textureSlots.map(\.path).filter { !$0.isEmpty && seen.insert($0).inserted && textureURL($0) == nil }
    }

    @discardableResult func fetchTextures(for document: EffectDocument) -> (fetched: Int, missing: [String]) {
        var fetched = 0
        var missing: [String] = []
        for path in missingTextures(in: document) {
            if (try? fetchFromGame(path)) != nil { fetched += 1 } else { missing.append(path) }
        }
        if fetched > 0, let folder = gameExtractFolder { setLibrary(folder) }
        return (fetched, missing)
    }

    func fetchMissingTextures() {
        guard let document else { return }
        let wanted = missingTextures(in: document)
        guard !wanted.isEmpty else {
            notice = "No textures are missing"
            return
        }
        let result = fetchTextures(for: document)
        notice = "Fetched \(result.fetched) of \(wanted.count) missing texture\(wanted.count == 1 ? "" : "s")"
        if !result.missing.isEmpty { errorMessage = "Not in the game archives:\n" + result.missing.joined(separator: "\n") }
    }

    func openFromGame(_ gamePath: String) throws {
        let path = PenumbraExport.normalized(gamePath)
        let url = try fetchFromGame(path)
        if let folder = gameExtractFolder { setLibrary(folder) }
        open(url)
        guard let document, document.url == url else { return }
        if document.gamePath.isEmpty { document.gamePath = path }
        let result = fetchTextures(for: document)
        notice = "Opened \(path): \(result.fetched) texture\(result.fetched == 1 ? "" : "s") fetched" + (result.missing.isEmpty ? "" : ", \(result.missing.count) not found")
    }

    func openFromGamePrompt() {
        guard let path = prompt("Open Effect by Game Path", placeholder: "vfx/…/eff/name.avfx") else { return }
        do {
            try openFromGame(path)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func extractFromGamePrompt() {
        guard let game, let entered = prompt("Extract File by Game Path", placeholder: "vfx/…/texture/name.atex") else { return }
        let path = PenumbraExport.normalized(entered)
        do {
            let data = try game.read(path)
            let panel = NSSavePanel()
            panel.title = "Extract File"
            panel.nameFieldStringValue = (path as NSString).lastPathComponent
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            notice = "Extracted \(path): \(data.count) bytes"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
