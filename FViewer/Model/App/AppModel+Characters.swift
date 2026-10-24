import AppKit
import Combine
import Foundation

extension AppModel {
    static let modelsBookmarkKey = "models.bookmark"
    private static let modelSearchDepth = 3
    private static let modelFolderNames: Set<String> = ["monster", "human", "demihuman", "models", "glb"]

    func restoreModelsFolder() {
        guard let bookmark = UserDefaults.standard.data(forKey: AppModel.modelsBookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) else { return }
        _ = url.startAccessingSecurityScopedResource()
        useModelsFolder(url)
    }

    func chooseModelsFolder() {
        let panel = NSOpenPanel()
        panel.title = "Character Models Folder"
        panel.message = "Pick the folder that holds the .glb models of ffxiv_mdls (for example the drive with _glb, _models and chara)"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use Folder"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        _ = url.startAccessingSecurityScopedResource()
        if let bookmark = try? url.bookmarkData(options: .withSecurityScope) { UserDefaults.standard.set(bookmark, forKey: AppModel.modelsBookmarkKey) }
        useModelsFolder(url)
        notice = PreviewSettings.models.isEmpty ? "No .glb models in \(url.lastPathComponent)" : "\(PreviewSettings.models.count) character models in \(url.lastPathComponent)"
    }

    func useModelsFolder(_ url: URL) {
        PreviewSettings.modelsFolder = url
        PreviewSettings.models = AppModel.characterModels(in: url)
        PreviewSettings.token += 1
        objectWillChange.send()
    }

    func setCharacter(_ change: (inout PreviewCharacter) -> Void) {
        var character = PreviewSettings.character
        change(&character)
        character.poseFrame = max(0, character.poseFrame.rounded())
        guard character != PreviewSettings.character else { return }
        if character.model != PreviewSettings.character.model { character.pose = "" }
        PreviewSettings.character = character
        PreviewSettings.token += 1
        if let data = try? JSONEncoder().encode(character) { UserDefaults.standard.set(data, forKey: "preview.character") }
        objectWillChange.send()
    }

    func setFacing(_ degrees: Float) {
        let value = degrees.isFinite ? degrees.truncatingRemainder(dividingBy: 360) : 0
        guard value != PreviewSettings.facing else { return }
        PreviewSettings.facing = value
        PreviewSettings.token += 1
        UserDefaults.standard.set(Double(value), forKey: "preview.facing")
        objectWillChange.send()
    }

    func loadCharacterSettings() {
        PreviewSettings.facing = Float(UserDefaults.standard.double(forKey: "preview.facing"))
        if let data = UserDefaults.standard.data(forKey: "preview.character"), let character = try? JSONDecoder().decode(PreviewCharacter.self, from: data) {
            PreviewSettings.character = character
        }
        restoreModelsFolder()
    }

    static func characterModels(in folder: URL) -> [CharacterModelEntry] {
        let manager = FileManager.default
        var found: [URL] = []
        var queue: [(URL, Int)] = [(folder, 0)]
        while let (dir, depth) = queue.first {
            queue.removeFirst()
            let items = (try? manager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
            for item in items {
                let isDirectory = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                if !isDirectory {
                    if item.pathExtension.lowercased() == "glb" { found.append(item) }
                    continue
                }
                let name = item.lastPathComponent.lowercased()
                let worthEntering = name.hasPrefix("_") || modelFolderNames.contains(name) || characterID(name) != nil
                if depth < modelSearchDepth, worthEntering { queue.append((item, depth + 1)) }
            }
        }
        return found.sorted { $0.lastPathComponent < $1.lastPathComponent }.map { file in
            let name = file.deletingPathExtension().lastPathComponent
            return CharacterModelEntry(name: name, file: file, eid: skeletonBindPoints(for: name, near: folder))
        }
    }

    static func characterID(_ name: String) -> (kind: String, id: String)? {
        let lower = name.lowercased()
        guard lower.count >= 5 else { return nil }
        let id = String(lower.prefix(5))
        guard id.dropFirst().allSatisfy(\.isNumber) else { return nil }
        switch id.first {
        case "c": return ("human", id)
        case "m": return ("monster", id)
        case "d": return ("demihuman", id)
        default: return nil
        }
    }

    static func skeletonBindPoints(for name: String, near folder: URL) -> URL? {
        guard let (kind, id) = characterID(name) else { return nil }
        let manager = FileManager.default
        var roots = [folder]
        var parent = folder
        for _ in 0..<2 {
            parent = parent.deletingLastPathComponent()
            roots.append(parent)
        }
        for root in roots {
            let base = root.appendingPathComponent("chara/\(kind)/\(id)/skeleton/base", isDirectory: true)
            let bodies = ((try? manager.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)) ?? []).sorted { $0.lastPathComponent < $1.lastPathComponent }
            for body in bodies {
                let files = (try? manager.contentsOfDirectory(at: body, includingPropertiesForKeys: nil)) ?? []
                if let eid = files.first(where: { $0.pathExtension.lowercased() == "eid" }) { return eid }
            }
        }
        return nil
    }
}
