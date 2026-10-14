import Foundation

nonisolated struct JsonKind: Sendable {
    let size: Int
    let date: Date
    let effect: Bool
}

nonisolated struct LibraryScan: Sendable {
    var files: [LibraryFile] = []
    var others: [LibraryFile] = []
    var textureFiles: [String: URL] = [:]
    var texturePaths: [String: URL] = [:]
    var modelFiles: [String: URL] = [:]
    var textureAddress: [String: (u: String, v: String)] = [:]
    var jsonKinds: [String: JsonKind] = [:]

    static let skipped: Set<String> = ["node_modules", ".git", ".idea", "reference", "Dalamud-VFXEditor-main"]
    static let gameExtensions: Set<String> = ["tmb", "pap", "eid", "scd", "mdl", "mtrl", "sklb", "skp", "phyb", "kdb", "pbd", "atch", "shpk", "shcd", "uld", "imc"]

    static func run(_ root: URL, known: [String: JsonKind]) -> LibraryScan {
        var scan = LibraryScan()
        scan.jsonKinds = known
        let rootPath = root.standardizedFileURL.path
        guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return scan }
        for case let url as URL in walker {
            if skipped.contains(url.lastPathComponent) {
                walker.skipDescendants()
                continue
            }
            let ext = url.pathExtension.lowercased()
            let relative = String(url.standardizedFileURL.path.dropFirst(rootPath.count + 1))
            let folder = (relative as NSString).deletingLastPathComponent
            let base = url.deletingPathExtension().lastPathComponent.lowercased()
            switch ext {
            case "avfx":
                scan.files.append(LibraryFile(url: url, folder: folder))
            case "atex", "tex":
                scan.textureFiles[url.lastPathComponent.lowercased()] = url
                scan.texturePaths[relative.lowercased()] = url
            case "png":
                if scan.textureFiles[base] == nil { scan.textureFiles[base] = url }
            case "json":
                if url.lastPathComponent == "game-textures.json" {
                    scan.readTextureManifest(url)
                } else if url.deletingLastPathComponent().lastPathComponent == "models" {
                    scan.modelFiles[base] = url
                } else if scan.isEffectJSON(url) {
                    scan.files.append(LibraryFile(url: url, folder: folder))
                }
            case _ where gameExtensions.contains(ext):
                scan.others.append(LibraryFile(url: url, folder: folder))
            default:
                let name = url.lastPathComponent.lowercased()
                if name.hasPrefix("~"), name.count >= 9, scan.textureFiles[name] == nil { scan.textureFiles[name] = url }
            }
        }
        scan.files.sort { ($0.folder, $0.name) < ($1.folder, $1.name) }
        scan.others.sort { ($0.folder, $0.name) < ($1.folder, $1.name) }
        return scan
    }

    private mutating func isEffectJSON(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let size = values?.fileSize ?? 0, date = values?.contentModificationDate ?? .distantPast
        guard size > 0, size < 2_000_000 else { return false }
        if let known = jsonKinds[url.path], known.size == size, known.date == date { return known.effect }
        var effect = false
        if let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) {
            effect = text.contains("\"emitters\"") && text.contains("\"particles\"")
        }
        jsonKinds[url.path] = JsonKind(size: size, date: date, effect: effect)
        return effect
    }

    private mutating func readTextureManifest(_ url: URL) {
        guard let data = try? Data(contentsOf: url), let manifest = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else { return }
        for (name, entry) in manifest {
            if let mode = entry["address"] as? String {
                textureAddress[name.lowercased()] = (mode, mode)
            } else if let modes = entry["address"] as? [String: String] {
                textureAddress[name.lowercased()] = (modes["u"] ?? "repeat", modes["v"] ?? "repeat")
            }
        }
    }
}
