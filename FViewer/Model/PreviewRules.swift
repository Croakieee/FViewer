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
        ("textureFilter", "Texture filter level", "Texture Filter set to High and above samples the texture with anisotropic filtering."),
        ("uvRotationRandom", "Random UV rotation", "UV Set Rotation Random turns each particle's texture by its own amount."),
        ("rotationVelocityRandom", "Random rotation velocity", "Rotation Velocity Random gives each particle its own spin."),
        ("clipDistance", "Clip by distance", "Enable Clip Near and Enable Clip Far fade the particle out by its distance from the camera or the caster."),
        ("coordComputeOrder", "Coordinate compute order", "Emitters and particles combine scale, rotation and position in the order their Coord Compute Order names."),
        ("emitterCameraBillboard", "Emitter camera billboard", "Emitters with Camera Billboard Axis Y turn to face the camera around the vertical axis."),
        ("infiniteOnce", "Endless particles once", "A particle with endless life is created once per emitter instead of on every creation."),
        ("heldOnce", "Held particles once", "A particle held in its loop section is created once per emitter."),
        ("injectionAnglePerCreation", "Injection angle continues", "The injection angle keeps counting across creations instead of restarting each time."),
        ("childLimit", "Child limit", "An emitter keeps no more live particles than its Child Limit."),
        ("cylinderPointFrame", "Cylinder point frame", "Cylinder Model emitters turn each child to face along the outward normal of its point."),
        ("gravityRandom", "Random gravity", "Gravity Random gives each particle its own gravity."),
        ("treeBillboardFixed", "Tree billboard quads", "Quads with Tree Billboard keep their own rotation fixed."),
        ("moveDirectionStreaks", "Move direction streaks", "Move Direction Billboard particles stretch along their motion on screen."),
        ("blendAfterAdditive", "Blend after additive", "Inside one draw priority, alpha blended particles are drawn after additive ones."),
        ("plainUv", "Plain UV for windmill and powder", "Windmill and plain Powder particles use only the first texture layer without UV motion."),
        ("periodicCurves", "Adding curves ignore the loop", "Curves that keep adding after their last key run on the total age while the particle is held in its loop."),
        ("addAlphaOnly", "Add of alpha-only texture", "An Add layer with an alpha-only texture leaves the colour as it is."),
        ("calcColorFive", "Calculate Color 5", "A layer with Calculate Color 5 leaves the colour as it is."),
        ("modelFresnel", "Model fresnel colours", "Models with a Fresnel Type blend Color Begin and Color End by the view angle."),
        ("lineGradient", "Line colour along length", "Line particles blend Color Begin and Color End along their length."),
        ("cullingWinding", "Culling by D3D winding", "Front and Back culling follow the game's clockwise front faces."),
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
