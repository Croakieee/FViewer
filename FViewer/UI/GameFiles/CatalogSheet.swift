import SwiftUI

enum GameCatalog {
    static let kinds: [(key: String, title: String)] = [
        ("vfx", "Effects"), ("tmb", "Timelines"), ("pap", "Animations"), ("uld", "Interface"), ("npc", "Monsters"),
    ]

    private static var cache: [String: [String]] = [:]

    static func lines(_ key: String) -> [String] {
        if let cached = cache[key] { return cached }
        var result: [String] = []
        if let url = Bundle.main.url(forResource: "catalog_" + key, withExtension: "txt"), let text = try? String(contentsOf: url, encoding: .utf8) {
            result = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        cache[key] = result
        return result
    }

    static func search(_ key: String, _ query: String, limit: Int = 300) -> (rows: [(group: String, path: String)], total: Int) {
        let words = query.lowercased().split(separator: " ").map(String.init)
        var rows: [(String, String)] = []
        var total = 0
        for line in lines(key) {
            if !words.isEmpty {
                let lowered = line.lowercased()
                if !words.allSatisfy({ lowered.contains($0) }) { continue }
            }
            total += 1
            if rows.count < limit {
                if let tab = line.firstIndex(of: "\t") {
                    rows.append((String(line[..<tab]), String(line[line.index(after: tab)...])))
                } else {
                    rows.append(("", line))
                }
            }
        }
        return (rows, total)
    }
}

struct CatalogSheet: View {
    @EnvironmentObject var app: AppModel
    @State private var kind = "vfx"
    @State private var query = ""

    var body: some View {
        let found = GameCatalog.search(kind, query)
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "books.vertical").foregroundStyle(Theme.text)
                Text("Game Catalog").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                ForEach(GameCatalog.kinds, id: \.key) { item in
                    SegmentButton(title: item.title, active: kind == item.key) { kind = item.key }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Theme.gray(0.157))
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 10)).foregroundStyle(Theme.dim)
                TextField("", text: $query, prompt: Text(kind == "npc" ? "m0078, sp01…" : "Search").foregroundStyle(Theme.dim))
                    .textFieldStyle(.plain)
                    .font(Theme.font)
                    .foregroundStyle(Theme.text)
                Text(found.total > found.rows.count ? "\(found.rows.count) of \(found.total)" : "\(found.total)").font(Theme.small).foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 12)
            .frame(height: 28)
            .background(Theme.field.opacity(0.5))
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(found.rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 6) {
                            if !row.group.isEmpty {
                                Text(row.group).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.changed).frame(width: 46, alignment: .leading)
                            }
                            Text(row.path).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.head).textSelection(.enabled)
                            Spacer(minLength: 4)
                            HeaderButton(symbol: "doc.on.doc", help: "Copy the path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(row.path, forType: .string)
                            }
                            SegmentButton(title: row.path.hasSuffix(".avfx") ? "Open" : "Inspect", active: true) { app.openCatalogPath(row.path) }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 24)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(height: 420)
            HStack(spacing: 8) {
                HelpBadge(text: "Paths the VFXEditor plugin ships as its common lists, and the effect, timeline and animation files of each monster model. A file is taken from the open folder or, when the game folder is set in File → Game, from the game archives.")
                if let note = app.catalogNote { Text(note).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1).truncationMode(.middle) }
                Spacer()
                SegmentButton(title: "Close", active: false) { app.showCatalog = false }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.gray(0.157))
        }
        .frame(width: 760)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}
