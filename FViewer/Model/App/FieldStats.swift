import Foundation

struct FieldStat {
    struct Value {
        let raw: String
        let files: Int
        let example: String

        var text: String { FieldStats.display(raw) }
    }

    let files: Int
    let other: Int
    let animated: Int?
    let values: [Value]
    let example: String
}

enum FieldStats {
    private static var table: (total: Int, fields: [String: FieldStat])?

    static var url: URL? { Bundle.main.resourceURL?.appendingPathComponent("Player/field_stats.json") }

    private static var loaded: (total: Int, fields: [String: FieldStat]) {
        if let table { return table }
        var fields: [String: FieldStat] = [:]
        var total = 0
        if let url, let data = try? Data(contentsOf: url), let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            total = root["files"] as? Int ?? 0
            for (key, value) in root["fields"] as? [String: Any] ?? [:] {
                guard let entry = value as? [String: Any] else { continue }
                let values = (entry["values"] as? [[Any]] ?? []).compactMap { row -> FieldStat.Value? in
                    guard row.count >= 3, let raw = row[0] as? String, let files = row[1] as? Int, let example = row[2] as? String else { return nil }
                    return FieldStat.Value(raw: raw, files: files, example: example)
                }
                fields[key] = FieldStat(files: entry["files"] as? Int ?? 0, other: entry["other"] as? Int ?? 0, animated: entry["animated"] as? Int,
                                        values: values, example: entry["example"] as? String ?? "")
            }
        }
        table = (total, fields)
        return (total, fields)
    }

    static var total: Int { loaded.total }

    static func stat(_ key: String?) -> FieldStat? {
        guard let key, let stat = loaded.fields[key], stat.files > 0 else { return nil }
        return stat
    }

    static func display(_ raw: String) -> String {
        switch raw {
        case "нет ключей": return "no keys"
        case "анимация": return "animated"
        default: return raw.hasPrefix("= ") ? String(raw.dropFirst(2)) : raw
        }
    }

    static func matches(_ raw: String, _ value: FieldValue, kind: FieldKind) -> Bool {
        guard let other = self.value(raw, for: kind) else { return false }
        if case .double(let a) = other, case .double(let b) = value { return abs(a - b) <= 1e-4 * max(1, abs(b)) }
        return other == value
    }

    static func value(_ raw: String, for kind: FieldKind) -> FieldValue? {
        switch kind {
        case .bool: return raw == "1" ? .bool(true) : raw == "0" ? .bool(false) : nil
        case .int, .choice: return Int(raw).map { .int($0) }
        case .double: return Double(raw).map { .double($0) }
        case .angle: return Double(raw).map { .double($0 * 180 / .pi) }
        case .text: return .text(raw)
        default: return nil
        }
    }

    static func name(_ raw: String, kind: FieldKind) -> String {
        switch kind {
        case .bool: return raw == "1" ? "On" : raw == "0" ? "Off" : raw
        case .choice(let choices): return Int(raw).flatMap { number in choices.first { $0.value == number }?.name } ?? raw
        case .angle: return Double(raw).map { String(format: "%g°", ($0 * 180 / .pi * 100).rounded() / 100) } ?? raw
        default: return display(raw)
        }
    }

    static func percent(_ files: Int, of all: Int) -> String {
        guard all > 0 else { return "" }
        let share = Double(files) / Double(all) * 100
        return share >= 1 ? String(format: "%.0f %%", share) : share >= 0.1 ? String(format: "%.1f %%", share) : "<0.1 %"
    }

    static func summary(_ stat: FieldStat, current: FieldValue? = nil, kind: FieldKind = .info) -> String {
        var lines = ["In the game: \(stat.files.formatted()) of \(total.formatted()) effects have it"]
        if let animated = stat.animated, animated > 0 { lines.append("Animated in \(animated.formatted()) of them") }
        let common = stat.values.prefix(3).map { "\(name($0.raw, kind: kind)) — \(percent($0.files, of: stat.files))" }
        if !common.isEmpty { lines.append("Most common, share of those effects: " + common.joined(separator: ", ")) }
        if let current, value(stat.values.first?.raw ?? "", for: kind) != nil {
            if let hit = stat.values.first(where: { matches($0.raw, current, kind: kind) }) {
                lines.append("This value: \(hit.files.formatted()) effects (\(percent(hit.files, of: stat.files)))")
            } else {
                lines.append("This value is rarer than the \(stat.values.count) most common")
            }
        }
        return lines.joined(separator: "\n")
    }
}
