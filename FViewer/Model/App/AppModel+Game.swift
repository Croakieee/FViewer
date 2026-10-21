import AppKit
import Foundation
import UniformTypeIdentifiers

extension AppModel {
    static var searchToken = 0

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
        Log.game.info("Game archives: \(archive.archiveCount) in \(archive.root.path)")
        notice = "Game archives: \(archive.archiveCount) in \(archive.root.lastPathComponent)"
    }

    func restoreGameFolder() {
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--game"), flag + 1 < arguments.count {
            do { try setGameFolder(URL(fileURLWithPath: arguments[flag + 1])) } catch { notice = "The game folder could not be opened: \(error.localizedDescription)" }
            return
        }
        guard let bookmark = UserDefaults.standard.data(forKey: AppModel.gameBookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) else { return }
        _ = url.startAccessingSecurityScopedResource()
        do {
            try setGameFolder(url)
            notice = nil
        } catch {
            notice = "The game folder \(url.lastPathComponent) could not be opened again: \(error.localizedDescription). Choose it once more in the Game Catalog"
        }
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

    func confirmDiscardingGameFile() -> Bool {
        guard let file = gameFile, file.unsaved else { return true }
        let alert = NSAlert()
        alert.messageText = "Save changes to \(file.url.lastPathComponent)?"
        alert.informativeText = "The File Inspector has changes that were not saved as a copy."
        alert.addButton(withTitle: "Save Copy")
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Don't Save")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            do {
                try writeGameFileCopy(file)
                return true
            } catch {
                errorMessage = error.localizedDescription
                return false
            }
        case .alertThirdButtonReturn: return true
        default: return false
        }
    }

    func inspectGameFile(_ url: URL) {
        guard confirmDiscardingGameFile() else { return }
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
        let target = file.savedCopy ?? freeURL(directory, base, file.url.pathExtension)
        try Data(file.bytes).write(to: target, options: .atomic)
        file.savedCopy = target
        file.savedBytes = file.bytes
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
        let data = wave ?? GameFiles.scdOgg(file.bytes, audio) ?? GameFiles.scdStream(file.bytes, audio)
        guard !data.isEmpty else { return }
        let panel = NSSavePanel()
        panel.title = "Export Sound"
        panel.nameFieldStringValue = file.url.deletingPathExtension().lastPathComponent + "_\(audio.id)." + (wave != nil ? "wav" : audio.format == 0x06 ? "ogg" : "bin")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try Data(data).write(to: url, options: .atomic)
            notice = "Exported \(url.lastPathComponent)"
        } catch {
            errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func replaceScdSound(_ file: GameFileDocument, _ audio: ScdAudio) {
        let panel = NSOpenPanel()
        panel.title = "Replace Sound"
        panel.allowedContentTypes = [.audio]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        file.replaceAudio(audio, from: url)
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

    func locateSound(_ gamePath: String) -> URL? {
        if let found = locateGameFile(gamePath) { return found }
        let parts = PenumbraExport.normalized(gamePath).split(separator: "/").map(String.init)
        var folder = document?.url.deletingLastPathComponent()
        while let current = folder, current.pathComponents.count > 1 {
            let candidate = parts.reduce(current) { $0.appendingPathComponent($1) }
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            folder = current.deletingLastPathComponent()
        }
        return nil
    }

    func variantEffect(of table: URL, number: Int) -> URL? {
        let folder = table.deletingLastPathComponent().appendingPathComponent("vfx").appendingPathComponent("eff")
        let wanted = String(format: "%04d", number)
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "avfx" && $0.deletingPathExtension().lastPathComponent.hasSuffix(wanted) }.sorted { $0.lastPathComponent < $1.lastPathComponent }.first
    }

    func openVariantEffect(of table: URL, number: Int) {
        guard let url = variantEffect(of: table, number: number) else {
            errorMessage = "No effect numbered \(number) was found in vfx/eff next to \(table.lastPathComponent)"
            return
        }
        open(url)
    }

    func gameFileModArchive(_ file: GameFileDocument, gamePath: String) throws -> Data {
        if let problem = PenumbraExport.problem(in: gamePath) { throw AvfxError.malformed(problem) }
        var mod = ModDescription()
        mod.name = file.url.deletingPathExtension().lastPathComponent
        mod.author = UserDefaults.standard.string(forKey: "mod.author") ?? ""
        return Data(PenumbraExport.archive(mod, files: [(PenumbraExport.normalized(gamePath), file.bytes, 0)]))
    }

    func exportGameFileMod(_ file: GameFileDocument) {
        guard let path = prompt("Game Path of This File", placeholder: "chara/…/name." + file.url.pathExtension, value: gamePath(forAsset: file.url) ?? "") else { return }
        let panel = NSSavePanel()
        panel.title = "Export Mod"
        panel.nameFieldStringValue = file.url.deletingPathExtension().lastPathComponent + ".pmp"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try gameFileModArchive(file, gamePath: path).write(to: url, options: .atomic)
            notice = "Exported \(url.lastPathComponent)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openCatalogPath(_ gamePath: String) {
        guard let url = locateGameFile(gamePath) else {
            catalogNote = "Not found in the open folder" + (game == nil ? "; no game folder is set" : " or the game archives")
            return
        }
        catalogNote = nil
        showCatalog = false
        if gamePath.hasSuffix(".avfx") {
            open(url)
            if let document, document.url == url, document.gamePath.isEmpty { document.gamePath = PenumbraExport.normalized(gamePath) }
        } else {
            inspectGameFile(url)
        }
    }

    func openEffect(gamePath: String) {
        guard let url = locateGameFile(gamePath) else {
            errorMessage = "\(gamePath) was not found in the open folder" + (game == nil ? " (no game folder is set)" : " or the game archives")
            return
        }
        open(url)
        guard let document, document.url == url else { return }
        if document.gamePath.isEmpty { document.gamePath = PenumbraExport.normalized(gamePath) }
        guard game != nil, document.avfxRoot != nil else { return }
        rememberGamePath(PenumbraExport.normalized(gamePath))
        let result = fetchTextures(for: document)
        if result.fetched > 0 || !result.missing.isEmpty {
            notice = "\(result.fetched) texture\(result.fetched == 1 ? "" : "s") fetched" + (result.missing.isEmpty ? "" : ", \(result.missing.count) not found")
        }
    }

    func guessGamePath(for document: EffectDocument) -> String? {
        let name = document.url.lastPathComponent.lowercased()
        let size = (try? document.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
        var base = document.url.deletingPathExtension().lastPathComponent.lowercased()
        if document.isEditedCopy, base.hasSuffix(EffectDocument.editSuffix.lowercased()) { base.removeLast(EffectDocument.editSuffix.count) }
        let wanted = [name, base + "." + document.url.pathExtension.lowercased()]
        if let direct = gamePath(forAsset: document.url), direct.hasPrefix("vfx/") {
            let folder = (direct as NSString).deletingLastPathComponent
            return folder + "/" + base + "." + document.url.pathExtension.lowercased()
        }
        var fallback: String?
        for file in files where wanted.contains(file.name.lowercased()) && file.url != document.url {
            guard let path = gamePath(forAsset: file.url) else { continue }
            if (try? file.url.resourceValues(forKeys: [.fileSizeKey]).fileSize) == size { return path }
            fallback = fallback ?? path
        }
        if let tex = document.textureSlots.first?.path.lowercased(), let cut = tex.range(of: "/texture/") {
            fallback = fallback ?? String(tex[..<cut.lowerBound]) + "/eff/" + wanted[1]
        }
        return fallback
    }

    nonisolated static func timelines(containing needle: [UInt8], in folder: URL) -> (hits: [URL], scanned: Int) {
        var hits: [URL] = []
        var scanned = 0
        let pattern = Data(needle)
        if let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) {
            for case let url as URL in walker {
                let ext = url.pathExtension.lowercased()
                guard ext == "tmb" || ext == "pap", let data = try? Data(contentsOf: url, options: .alwaysMapped) else { continue }
                scanned += 1
                if data.range(of: pattern) != nil { hits.append(url) }
                if hits.count >= 400 { break }
            }
        }
        return (hits, scanned)
    }

    nonisolated static func files(containing needle: [UInt8], among urls: [URL]) -> [URL] {
        var hits: [URL] = []
        let pattern = Data(needle)
        guard !needle.isEmpty else { return hits }
        for url in urls {
            guard let data = try? Data(contentsOf: url, options: .alwaysMapped) else { continue }
            if data.range(of: pattern) != nil { hits.append(url) }
            if hits.count >= 400 { break }
        }
        return hits
    }

    func findFiles(containing text: String, effects: Bool) {
        let needle = Array(text.lowercased().utf8)
        let urls = effects ? files.filter(\.isAvfx).map(\.url) : gameFiles.filter { ["tmb", "pap", "mtrl", "mdl"].contains($0.url.pathExtension.lowercased()) }.map(\.url)
        guard !needle.isEmpty, !urls.isEmpty else {
            notice = urls.isEmpty ? "The open folder has no files to search" : nil
            return
        }
        notice = "Searching \(urls.count) files for \(text)…"
        AppModel.searchToken += 1
        let token = AppModel.searchToken
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let hits = AppModel.files(containing: needle, among: urls)
            DispatchQueue.main.async {
                guard let self, token == AppModel.searchToken else { return }
                self.notice = "\(hits.count) file\(hits.count == 1 ? "" : "s") mention \(text) (\(urls.count) searched)"
                self.timelineHitsTitle = (effects ? "Effects" : "Files") + " Using " + text
                self.timelineHits = hits.isEmpty ? nil : hits
            }
        }
    }

    func findEffectsPrompt() {
        guard let text = prompt("Find Effects Using a Texture or Model", placeholder: "fire007bm.atex") else { return }
        findFiles(containing: text.trimmingCharacters(in: .whitespaces), effects: true)
    }

    func listEffects(of url: URL, data given: Data? = nil) {
        guard let data = given ?? (try? Data(contentsOf: url)) else { return }
        let paths = AppModel.effectPaths(in: data)
        if paths.isEmpty {
            notice = "\(url.lastPathComponent) starts no effects"
        } else {
            effectList = EffectList(title: url.lastPathComponent, paths: paths)
        }
    }

    func findTimelines(using document: EffectDocument) {
        if gameFiles.contains(where: { ["tmb", "pap"].contains($0.url.pathExtension.lowercased()) }) {
            var base = document.url.deletingPathExtension().lastPathComponent.lowercased()
            if document.isEditedCopy, base.hasSuffix(EffectDocument.editSuffix.lowercased()) { base.removeLast(EffectDocument.editSuffix.count) }
            timelineHitsTitle = "Timelines Using This Effect"
            let needle = Array((base + ".avfx").utf8)
            let urls = gameFiles.filter { ["tmb", "pap"].contains($0.url.pathExtension.lowercased()) }.map(\.url)
            notice = "Searching \(urls.count) timelines for \(base).avfx…"
            AppModel.searchToken += 1
            let token = AppModel.searchToken
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let hits = AppModel.files(containing: needle, among: urls)
                DispatchQueue.main.async {
                    guard let self, token == AppModel.searchToken else { return }
                    self.notice = "\(hits.count) timeline\(hits.count == 1 ? "" : "s") use \(base).avfx (\(urls.count) files searched)"
                    self.timelineHits = hits.isEmpty ? nil : hits
                }
            }
            return
        }
        timelineHitsTitle = "Timelines Using This Effect"
        guard let folder = chooseFolder("Folder with .tmb and .pap Files") else { return }
        var base = document.url.deletingPathExtension().lastPathComponent.lowercased()
        if document.isEditedCopy, base.hasSuffix(EffectDocument.editSuffix.lowercased()) { base.removeLast(EffectDocument.editSuffix.count) }
        let needle = Array((base + ".avfx").utf8)
        notice = "Searching timelines for \(base).avfx…"
        AppModel.searchToken += 1
        let token = AppModel.searchToken
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = AppModel.timelines(containing: needle, in: folder)
            let hits = result.hits, scanned = result.scanned
            let found = hits, total = scanned
            DispatchQueue.main.async {
                guard let self, token == AppModel.searchToken else { return }
                self.notice = "\(found.count) timeline\(found.count == 1 ? "" : "s") use \(base).avfx (\(total) files searched)"
                self.timelineHits = found.isEmpty ? nil : found
            }
        }
    }
}
