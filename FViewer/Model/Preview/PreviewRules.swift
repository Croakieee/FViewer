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
        ("dissolve", "Dissolve on the loaded model", "A Dissolve particle cuts the model loaded with File → Game → Load Model where the red of its first texture is below Erosion, and the edge glows in the particle colour. Derived from the field names, not checked in the game."),
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
        ("distortionHalfRange", "Distortion half range", "Texture Distortion shifts the UV by (red, green − 0.5) × Power, as the game's particle shader does."),
        ("paletteChannels", "Palette on every channel", "The Palette layer recolours each channel of the first colour layer and replaces it before the other layers, as the game's particle shader does."),
        ("softQuadratic", "Quadratic soft fade", "Soft particles fade by the square of their distance to the scene, as the game's particle shader does."),
        ("a8BlackRgb", "Alpha-only textures are black", "Textures that store only alpha are read with black colour, as the game samples them."),
        ("textureLessTc1White", "White base without a first layer", "A first colour layer that is off or has no texture is a white base the other layers combine onto."),
        ("tc1OffNoAlpha", "First layer off brings no alpha", "With the first colour layer switched off and another layer on, only the other layers bring alpha."),
        ("tc1MultiplyWhite", "First layer Multiply keeps the colour", "A first colour layer with Multiply leaves the particle colour as it is and gives only its alpha. Works with First layer as luminance."),
        ("blendBeforeClamp", "Blend before clamping", "Blend and Opacity particles are weighted by alpha before bright colour is clamped, so colours above 1 keep their hue."),
        ("depthOffsetView", "Depth offset by distance", "Depth Offset is a share of the distance to the camera, not metres."),
        ("decalNoMipmaps", "Decals without mipmaps", "Decal and Decal Ring textures are read at full size."),
        ("createOnceOwnCount", "Create once ignores emitter count", "An item created once at the emitter start makes its own Create Count; the emitter's Create Count does not multiply it."),
        ("cylinderNoInjection", "Cylinder Model without injection speed", "Particles from a Cylinder Model emitter are not thrown; they move only by their own curves."),
        ("trailWholePath", "Trails keep the whole path", "A Position History trail of a particle with a finite life keeps its whole path since birth."),
        ("polylineAxisFromBase", "Polyline line along the rotation base", "An Axis Order line runs along the particle's Rotation Direction Base axis (X, Y or Z)."),
        ("polylineWidthRevised", "Polyline width by revised scale", "Polyline ribbon width is multiplied by the mean of the effect's Revised Scale X and Y."),
        ("releasedEndlessEnd", "Released endless particles end", "Once released, a particle with endless life ends together with the emitter that made it. While held it stays. Inferred from game files, not checked in the game."),
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

