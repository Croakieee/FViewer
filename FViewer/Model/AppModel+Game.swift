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
        if document.sourcePath.isEmpty { document.sourcePath = path }
        rememberGamePath(path)
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

    var recentGamePaths: [String] { UserDefaults.standard.stringArray(forKey: "recent.gamepaths") ?? [] }

    func rememberGamePath(_ path: String) {
        let clean = PenumbraExport.normalized(path)
        guard !clean.isEmpty else { return }
        var list = recentGamePaths.filter { $0 != clean }
        list.insert(clean, at: 0)
        UserDefaults.standard.set(Array(list.prefix(20)), forKey: "recent.gamepaths")
    }

    struct PenumbraMod: Identifiable {
        let id: URL
        let name: String
        let author: String
        let effects: Int
    }

    func penumbraMods(in folder: URL) -> [PenumbraMod] {
        var result: [PenumbraMod] = []
        for entry in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [] {
            let meta = entry.appendingPathComponent("meta.json")
            guard let data = try? Data(contentsOf: meta), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            var effects = 0
            if let walker = FileManager.default.enumerator(at: entry, includingPropertiesForKeys: nil) {
                for case let file as URL in walker where file.pathExtension.lowercased() == "avfx" { effects += 1 }
            }
            result.append(PenumbraMod(id: entry, name: json["Name"] as? String ?? entry.lastPathComponent, author: json["Author"] as? String ?? "", effects: effects))
        }
        return result.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func choosePenumbraFolder() {
        let panel = NSOpenPanel()
        panel.title = "Penumbra Mods Folder"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = "Use Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if let bookmark = try? url.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: "penumbraBookmark") }
        showPenumbraMods(url)
    }

    func showPenumbraMods(_ folder: URL) {
        let mods = penumbraMods(in: folder)
        guard !mods.isEmpty else {
            errorMessage = "No mods with a meta.json in \(folder.lastPathComponent)"
            return
        }
        modList = mods
    }

    func browsePenumbraMods() {
        if let bookmark = UserDefaults.standard.data(forKey: "penumbraBookmark") {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) {
                _ = url.startAccessingSecurityScopedResource()
                showPenumbraMods(url)
                return
            }
        }
        choosePenumbraFolder()
    }

    func workspaceArchive() throws -> Data {
        guard let root = libraryRoot, let workspace = workspaceData() else { throw AvfxError.malformed("Open a folder first") }
        let base = root.standardizedFileURL.path
        var entries: [(path: String, data: [UInt8])] = []
        var seen: Set<String> = []
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        entries.append(("workspace.fvworkspace", [UInt8](try encoder.encode(workspace))))
        for document in openDocuments {
            let path = document.url.standardizedFileURL.path
            guard path.hasPrefix(base + "/") else { continue }
            let relative = String(path.dropFirst(base.count + 1))
            if seen.insert(relative).inserted { entries.append((relative, [UInt8](document.serializedData()))) }
            let meta = document.url.deletingPathExtension().appendingPathExtension("fvmeta.json")
            if let data = try? Data(contentsOf: meta) { entries.append(((relative as NSString).deletingPathExtension + ".fvmeta.json", [UInt8](data))) }
            for slot in document.textureSlots {
                guard let url = textureURL(slot.path), url.standardizedFileURL.path.hasPrefix(base + "/") else { continue }
                let texture = String(url.standardizedFileURL.path.dropFirst(base.count + 1))
                if seen.insert(texture).inserted, let data = try? Data(contentsOf: url) { entries.append((texture, [UInt8](data))) }
            }
        }
        return Data(ZipWriter.archive(entries))
    }

    func saveWorkspaceArchive() {
        do {
            let data = try workspaceArchive()
            let panel = NSSavePanel()
            panel.title = "Save Workspace Archive"
            panel.nameFieldStringValue = (libraryRoot?.lastPathComponent ?? "workspace") + ".fvworkspace.zip"
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try data.write(to: url, options: .atomic)
            notice = "Workspace archive written: \(openDocuments.count) effect\(openDocuments.count == 1 ? "" : "s") with their textures"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult func extractWorkspaceArchive(_ archive: URL, into folder: URL) throws -> Int {
        let bytes = [UInt8](try Data(contentsOf: archive))
        var count = 0
        for entry in try ZipReader.entries(bytes) where !entry.path.hasSuffix("/") {
            let parts = entry.path.split(separator: "/").map(String.init)
            guard !parts.contains(".."), !entry.path.hasPrefix("/") else { continue }
            let destination = parts.reduce(folder) { $0.appendingPathComponent($1) }
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) { continue }
            try Data(try ZipReader.data(entry, in: bytes)).write(to: destination, options: .atomic)
            count += 1
        }
        return count
    }

    func openWorkspaceArchive() {
        let panel = NSOpenPanel()
        panel.title = "Open Workspace Archive"
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        guard panel.runModal() == .OK, let archive = panel.url, let folder = chooseFolder("Extract Workspace Into") else { return }
        do {
            let count = try extractWorkspaceArchive(archive, into: folder)
            if let bookmark = try? folder.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: "libraryBookmark") }
            setLibrary(folder)
            let file = folder.appendingPathComponent("workspace.fvworkspace")
            if FileManager.default.fileExists(atPath: file.path) { openWorkspace(file) }
            notice = "Workspace extracted: \(count) new file\(count == 1 ? "" : "s")"
        } catch {
            errorMessage = "\(archive.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func inspectGameFile(_ url: URL) {
        do {
            gameFile = try GameFileDocument(url: url)
            openGameFileWindow?()
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func inspectGameFilePanel() {
        let panel = NSOpenPanel()
        panel.title = "Inspect Game File"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = []
        panel.allowsOtherFileTypes = true
        panel.prompt = "Inspect"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        inspectGameFile(url)
    }

    func inspectGameFileByPath() {
        guard let game, let entered = prompt("Inspect File by Game Path", placeholder: "chara/action/…/name.tmb") else { return }
        let path = PenumbraExport.normalized(entered)
        do {
            let data = try game.read(path)
            guard let folder = gameExtractFolder else { return }
            let destination = path.split(separator: "/").reduce(folder) { $0.appendingPathComponent(String($1)) }
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: destination.path) { try data.write(to: destination, options: .atomic) }
            inspectGameFile(destination)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult func writeGameFileCopy(_ file: GameFileDocument) throws -> URL {
        let directory = file.url.deletingLastPathComponent()
        let base = file.url.deletingPathExtension().lastPathComponent
        let target = freeURL(directory, base, file.url.pathExtension)
        try Data(file.bytes).write(to: target, options: .atomic)
        return target
    }

    func saveGameFile(_ file: GameFileDocument) {
        do {
            let target = try writeGameFileCopy(file)
            notice = "Saved as \(target.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportScdStream(_ file: GameFileDocument, _ audio: ScdAudio) {
        let wave = GameFiles.scdWave(file.bytes, audio)
        let data = wave ?? GameFiles.scdStream(file.bytes, audio)
        guard !data.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export Sound"
        panel.nameFieldStringValue = file.url.deletingPathExtension().lastPathComponent + "_\(audio.id)." + (wave != nil ? "wav" : audio.format == 0x06 ? "ogg" : "bin")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? Data(data).write(to: url, options: .atomic)
    }

    func locateGameFile(_ gamePath: String) -> URL? {
        let path = PenumbraExport.normalized(gamePath)
        if game != nil, let url = try? fetchFromGame(path) { return url }
        guard let root = libraryRoot else { return nil }
        let parts = path.split(separator: "/").map(String.init)
        var candidates: [URL] = []
        for start in 0..<parts.count { candidates.append(parts[start...].reduce(root) { $0.appendingPathComponent($1) }) }
        candidates.append(parts.reduce(root.deletingLastPathComponent()) { $0.appendingPathComponent($1) })
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    func openEffect(gamePath: String) {
        guard let url = locateGameFile(gamePath) else {
            errorMessage = "\(gamePath) was not found in the open folder" + (game == nil ? " (no game folder is set)" : " or the game archives")
            return
        }
        open(url)
        if let document, document.url == url, document.gamePath.isEmpty { document.gamePath = PenumbraExport.normalized(gamePath) }
    }
}
