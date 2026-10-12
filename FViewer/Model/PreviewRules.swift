import SwiftUI

enum PreviewRules {
    static let all: [(key: String, title: String, help: String)] = [
        ("softParticles", "Soft particles", "Particles with Soft Particle fade out near the floor."),
        ("screenCopy", "Screen copy", "Layers with Use Screen Copy show the scene behind the particle."),
        ("distortion", "Texture distortion", "The Distortion layer shifts the UV of the layers it targets."),
        ("lights", "Effector lights", "Point light effectors light the floor and the models."),
        ("trails", "Polyline trails", "Polyline particles are drawn as trails."),
        ("coneEmitters", "Cone emitters", "Cone and Cone Model emitters throw particles inside their angle."),
        ("cameraBinder", "Camera binder", "Binders of type Camera pin the effect in front of the camera."),
        ("spriteDamping", "Sprite damping", "Simple Animation sprites slow down by Coord Accuracy."),
        ("uvRotationReversed", "Reversed UV rotation", "UV Set rotation turns the opposite way to its sign."),
        ("paletteAlpha", "Palette alpha", "The Palette layer scales alpha by the first colour layer."),
        ("revisedColor", "Revised colour", "The effect header colour multiplies every particle."),
        ("polygonAsQuad", "Polygon as quad", "Polygon particles are drawn as a quad with the whole texture."),
        ("axisConnectRandom", "Separate random axis link", "Random offsets of X, Y and Z follow their own Axis Connect Random setting."),
        ("tc1Luminance", "First layer as luminance", "A first colour layer with Multiply is read as brightness, not as colour."),
        ("softDepthOffset", "Soft fade after depth offset", "The soft particle fade is measured from the depth the particle is drawn at."),
        ("directionalLights", "Directional lights", "Directional light effectors light the floor and the models from their direction."),
        ("modelSkin", "Model Skin on the loaded model", "Model Skin particles are drawn over the model loaded with File → Game → Load Model."),
        ("postEffects", "Screen effectors", "Radial, directional and Gaussian blur and chromatic aberration effectors change the whole picture."),
        ("cameraQuake", "Camera quake", "Camera Quake effectors shake the view while they are in reach."),
        ("emitterMarkers", "Emitter shapes", "The selected emitter shows its shape and its create points."),
        ("bindPointNumbers", "Bind point numbers", "Bind points of the loaded skeleton show their numbers."),
        ("loopEffectors", "Effector loop", "Effectors repeat between Loop Start and Loop End until the effect is released."),
    ]

    private static var cache: [String: Bool] = [:]
    static private(set) var token = 0

    static func isOn(_ key: String) -> Bool {
        if let cached = cache[key] { return cached }
        let value = UserDefaults.standard.object(forKey: "rule." + key) as? Bool ?? true
        cache[key] = value
        return value
    }

    static func set(_ key: String, _ value: Bool) {
        UserDefaults.standard.set(value, forKey: "rule." + key)
        cache[key] = value
        token += 1
    }

    static func bump() { token += 1 }

    static func curveColors() -> [Color]? {
        guard let stored = UserDefaults.standard.stringArray(forKey: "curve.colors"), stored.count == 3 else { return nil }
        var list = EffectDocument.defaultChannelColors
        for (index, text) in stored.enumerated() {
            let parts = text.split(separator: ",").compactMap { Double($0) }
            if parts.count == 3 { list[index] = Color(red: parts[0], green: parts[1], blue: parts[2]) }
        }
        return list
    }

    static func setCurveColor(_ index: Int, _ color: Color) {
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
        token += 1
    }

    static func resetCurveColors() {
        UserDefaults.standard.removeObject(forKey: "curve.colors")
        token += 1
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
