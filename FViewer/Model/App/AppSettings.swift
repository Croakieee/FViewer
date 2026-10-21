import SwiftUI

enum CurveColors {
    static func stored() -> [Color]? {
        guard let stored = UserDefaults.standard.stringArray(forKey: "curve.colors"), stored.count == 3 else { return nil }
        var list = EffectDocument.defaultChannelColors
        for (index, text) in stored.enumerated() {
            let parts = text.split(separator: ",").compactMap { Double($0) }
            if parts.count == 3 { list[index] = Color(red: parts[0], green: parts[1], blue: parts[2]) }
        }
        return list
    }

    static func set(_ index: Int, _ color: Color) {
        var stored = UserDefaults.standard.stringArray(forKey: "curve.colors") ?? []
        if stored.count != 3 {
            stored = EffectDocument.defaultChannelColors.prefix(3).map { color in
                let c = NSColor(color).usingColorSpace(.sRGB) ?? .white
                return "\(c.redComponent),\(c.greenComponent),\(c.blueComponent)"
            }
        }
        let c = NSColor(color).usingColorSpace(.sRGB) ?? .white
        stored[index] = "\(c.redComponent),\(c.greenComponent),\(c.blueComponent)"
        UserDefaults.standard.set(stored, forKey: "curve.colors")
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: "curve.colors")
    }
}

enum AppShortcuts {
    static let commands: [(key: String, title: String, fallback: String, shift: Bool)] = [
        ("new", "New Effect", "n", false), ("open", "Open File", "o", false), ("openFolder", "Open Folder", "o", true), ("save", "Save", "s", false),
        ("saveAs", "Save As", "s", true), ("undo", "Undo", "z", false), ("redo", "Redo", "z", true),
    ]

    static func key(_ command: String) -> KeyEquivalent {
        let fallback = commands.first { $0.key == command }?.fallback ?? "?"
        let stored = UserDefaults.standard.string(forKey: "shortcut." + command) ?? fallback
        return KeyEquivalent(stored.lowercased().first ?? Character(fallback))
    }
}

extension AppShortcuts {
    static let editorKeys: [(key: String, title: String, fallback: String)] = [
        ("grab", "Move", "g"), ("scale", "Scale", "s"), ("rotate", "Rotate", "r"), ("delete", "Delete", "x"), ("selectAll", "Select All", "a"),
        ("linked", "Select Linked", "l"), ("frame", "Frame Selected", "."), ("fill", "Fill Face", "f"), ("merge", "Merge Vertices", "m"),
        ("extrude", "Extrude", "e"), ("insertKey", "Insert Keyframe", "i"), ("interpolation", "Cycle Interpolation", "t"),
    ]

    static func editorKey(_ command: String) -> String {
        let fallback = editorKeys.first { $0.key == command }?.fallback ?? ""
        return UserDefaults.standard.string(forKey: "editkey." + command) ?? fallback
    }

    static func canonical(_ characters: String) -> String {
        guard characters.count == 1 else { return characters }
        for command in editorKeys where editorKey(command.key) == characters { return command.fallback }
        if editorKeys.contains(where: { $0.fallback == characters && editorKey($0.key) != characters }) { return "" }
        return characters
    }
}

enum Appearance {
    static func number(_ key: String, _ fallback: Double) -> Double {
        UserDefaults.standard.object(forKey: "look." + key) == nil ? fallback : UserDefaults.standard.double(forKey: "look." + key)
    }

    static func setNumber(_ key: String, _ value: Double) { UserDefaults.standard.set(value, forKey: "look." + key) }

    static func rgb(_ key: String, _ fallback: SIMD3<Double>) -> SIMD3<Double> {
        guard let parts = UserDefaults.standard.string(forKey: "look." + key)?.split(separator: ",").compactMap({ Double($0) }), parts.count == 3 else { return fallback }
        return SIMD3(parts[0], parts[1], parts[2])
    }

    static func setRGB(_ key: String, _ value: SIMD3<Double>?) {
        if let value {
            UserDefaults.standard.set("\(value.x),\(value.y),\(value.z)", forKey: "look." + key)
        } else {
            UserDefaults.standard.removeObject(forKey: "look." + key)
        }
    }

    static func isSet(_ key: String) -> Bool { UserDefaults.standard.object(forKey: "look." + key) != nil }

    static func reset() {
        for key in UserDefaults.standard.dictionaryRepresentation().keys where key.hasPrefix("look.") { UserDefaults.standard.removeObject(forKey: key) }
    }

    static let selectedDefault = SIMD3<Double>(1, 0.63, 0.16)
    static let barSelectedDefault = SIMD3<Double>(1, 1, 1)

    static var curveWidth: CGFloat { CGFloat(number("curve.width", 1.6)) }
    static var pointSize: CGFloat { CGFloat(number("curve.point", 3.5)) }
    static var selectedSize: CGFloat { CGFloat(number("curve.selected", 4.5)) }
    static var grabDistance: CGFloat { CGFloat(number("curve.grab", 9)) }
    static var selectedColor: Color {
        let c = rgb("curve.selectedColor", selectedDefault)
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
    static var barColor: Color? {
        guard isSet("timeline.bar") else { return nil }
        let c = rgb("timeline.bar", SIMD3(0.44, 0.457, 0.492))
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
    static var barSelectedColor: Color {
        let c = rgb("timeline.selected", barSelectedDefault)
        return Color(.sRGB, red: c.x, green: c.y, blue: c.z)
    }
}

