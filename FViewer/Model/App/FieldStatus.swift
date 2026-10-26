import Foundation

enum FieldStatus {
    enum Kind {
        case measured, inferred, guess, unsure, notYet, noEffect, unread, read

        var symbol: String? {
            switch self {
            case .measured: return "checkmark"
            case .notYet, .unread: return "eye.slash"
            case .noEffect: return "minus.circle"
            case .guess, .unsure, .read: return "questionmark"
            case .inferred: return nil
            }
        }

        var hidden: Bool { self == .notYet || self == .unread || self == .noEffect }

        var title: String {
            switch self {
            case .measured: return "Checked against the game"
            case .inferred: return "By analogy"
            case .guess, .unsure, .read: return "Not confirmed"
            case .notYet, .unread: return "Not in the preview yet"
            case .noEffect: return "No visible effect"
            }
        }

        var text: String {
            switch self {
            case .measured: return "Preview: checked against the game"
            case .inferred: return "Preview: drawn from game data or one observation, not disproven"
            case .guess: return "Preview: a guess, not checked against the game"
            case .unsure: return "Preview: worked out on an unreliable effect, to be checked again"
            case .notYet: return "Preview: not drawn yet, though the game uses it"
            case .noEffect: return "No visible effect: the preview leaves it out on purpose"
            case .unread: return "Preview: not read yet, not sorted out"
            case .read: return "Preview: read, not checked against the game"
            }
        }
    }

    private static let sections: [String: String] = [
        "Заголовок эффекта (AvfxMain)": "AvfxMain", "Scheduler": "AvfxScheduler", "Scheduler: элемент / триггер": "AvfxSchedulerItem",
        "Timeline": "AvfxTimeline", "Timeline: элемент": "AvfxTimelineItem", "Emitter": "AvfxEmitter",
        "Emitter: элемент (ItPr / ItEm)": "AvfxEmitterItem", "Particle (общие поля)": "AvfxParticle",
        "Particle: Simple Animation (Smpl)": "AvfxParticleSimple", "Particle: UV Set": "AvfxParticleUvSet",
        "Texture Color 1 (TC1)": "AvfxParticleTextureColor1", "Texture Color 2/3/4 (TC2…)": "AvfxParticleTextureColor2",
        "Texture Distortion (TD)": "AvfxParticleTextureDistortion", "Texture Normal (TN)": "AvfxParticleTextureNormal",
        "Texture Palette (TP)": "AvfxParticleTexturePalette", "Texture Reflection (TR)": "AvfxParticleTextureReflection",
        "Binder": "AvfxBinder", "Binder: Properties (PrpS / Prp1 / Prp2 / PrpG)": "AvfxBinderProperties", "Effector": "AvfxEffector",
        "Кривая 2 оси": "AvfxCurve2Axis", "Кривая 3 оси": "AvfxCurve3Axis", "Кривая цвета": "AvfxCurveColor",
        "Кривая (общие поля)": "AvfxCurveData", "Кривая: AvfxCurveDissolve": "AvfxCurveDissolve", "Life": "AvfxLife",
        "Texture__AvfxTexture": "AvfxTexture",
    ]
    private static let prefixed: [(String, String)] = [
        ("Emitter Data: ", "AvfxEmitterData"), ("Particle Data: ", "AvfxParticleData"), ("Binder Data: ", "AvfxBinderData"),
        ("Effector Data: ", "AvfxEffectorData"),
    ]

    static var url: URL? { Bundle.main.resourceURL?.appendingPathComponent("Player/properties.md") }

    private static var table: [String: Kind]?

    private static var loaded: [String: Kind] {
        if let table { return table }
        var result: [String: Kind] = [:]
        if let url, let text = try? String(contentsOf: url, encoding: .utf8) {
            var cls: String?
            for line in text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
                if line.hasPrefix("## ") {
                    let title = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                    cls = sections[title] ?? prefixed.first { title.hasPrefix($0.0) }.map { $0.1 + title.dropFirst($0.0.count).replacingOccurrences(of: " ", with: "") }
                    continue
                }
                guard let cls, line.hasPrefix("| `") else { continue }
                let cells = line.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                    .components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                guard cells.count >= 3, let kind = kind(status: cells[2], note: cells.count > 3 ? cells[3] : "") else { continue }
                for tag in cells[0].components(separatedBy: "`").enumerated().filter({ $0.offset % 2 == 1 }).map(\.element) {
                    result[cls + "." + tag] = kind
                }
            }
        }
        table = result
        return result
    }

    private static func kind(status: String, note: String) -> Kind? {
        if status.contains("✅") { return .measured }
        if status.contains("🔶") { return .inferred }
        if status.contains("❓") { return .guess }
        if status.contains("⚠") { return .unsure }
        if status.contains("🚫") { return .noEffect }
        if status.contains("⬜") { return .notYet }
        if status.contains("—") { return nil }
        let lower = note.lowercased()
        if lower.contains("не читается") { return .unread }
        if lower.contains("читается") { return .read }
        return nil
    }

    static func of(_ key: String?) -> Kind? { key.flatMap { loaded[$0] } }
}
