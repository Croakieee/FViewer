import SwiftUI

struct LayerPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let layer: EffectLayer

    private static let types: [(String, Int)] = [("Quad", 8), ("Powder", 1), ("Disc", 12), ("Model", 5), ("Polyline", 6), ("Decal", 10), ("Decal Ring", 11),
                                                 ("Laser", 4), ("Windmill", 2), ("Line", 3)]
    private static let blends: [(String, Int)] = [("Blend", 0), ("Add", 2), ("Screen", 4), ("Multiply", 1), ("Subtract", 3)]
    private static let facings: [(String, Int, String)] = [
        ("Camera", 6, "Turns its face to the camera"), ("Screen", 5, "Lies parallel to the screen"),
        ("Upright", 2, "Stands up, facing the effect's +Z"), ("Flat", 1, "Lies flat on the ground"),
        ("Motion", 3, "Points along its motion; a particle that does not move is not drawn"),
    ]
    private static let follows: [(String, Int, String)] = [
        ("Follow", 2, "The particle moves with its emitter all the time"), ("Stay", 3, "The particle stays where it was born"),
        ("Birth Spot", 0, "Takes only the emitter's position at birth, not its turn or size"),
        ("Options", 1, "Follows what the item's Influence on Position / Rotation / Scale pick"),
    ]
    private static let aims: [(String, Int, String)] = [
        ("Forward", 0, "Along the effect's +Z, where the character faces"), ("Up", -90, "Straight up: Rotation X −90°"), ("Down", 90, "Straight down: Rotation X 90°"),
    ]

    private func row<Content: View>(_ label: String, _ help: String = "", @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 92, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.8)
            content()
        }
        .help(help)
    }

    private func chips(_ items: [(String, Int, String)], current: Int?, _ action: @escaping (Int) -> Void) -> some View {
        FlowLayout(spacing: 3) {
            ForEach(items, id: \.1) { item in
                SegmentButton(title: item.0, active: current == item.1) { action(item.1) }.help(item.2)
            }
        }
    }

    private func number(_ value: Double, suffix: String = "", step: Double, digits: Int? = nil, isInteger: Bool = false, _ commit: @escaping (Double) -> Void) -> some View {
        NumberField(label: nil, value: value, isInteger: isInteger, suffix: suffix, step: step, digits: digits,
                    onLive: { next in
                        document.withoutUndo { commit(next) }
                        document.liveChanged()
                    },
                    onCommit: { old, next in
                        document.withoutUndo { commit(old) }
                        commit(next)
                    })
    }

    private func color(_ value: SIMD4<Double>, _ commit: @escaping (SIMD4<Double>) -> Void) -> some View {
        ColorField(color: value, alpha: true,
                   onLive: { next in
                       document.withoutUndo { commit(next) }
                       document.liveChanged()
                   },
                   onCommit: { old, next in
                       document.withoutUndo { commit(old) }
                       commit(next)
                   })
    }

    private func openCurve(_ nodeID: String, _ tag: String) {
        document.selectionID = nodeID
        document.activeCurveID = "\(nodeID)~\(tag)0"
        CurvePanel.shared.show(app)
    }

    private func customCurve(_ nodeID: String, _ tag: String) -> some View {
        SegmentButton(title: "Custom Curve…", active: false) { openCurve(nodeID, tag) }
            .help("This curve has more than two keys. Edit it in the Graph Editor")
    }

    private var span: Double { document.layerLife(layer.particle) ?? 60 }

    private func dataCurve(_ tag: String) -> AvfxBlock? { layer.emitter?.child("Data")?.child(tag) }

    private func constant(_ curve: AvfxBlock?) -> Double? {
        guard case .values(let start, let end)? = document.curveEnds(curve), start == end else { return nil }
        return start
    }

    private func setConstant(_ owner: AvfxBlock, cls: String, _ tag: String, _ value: Double, title: String) {
        document.setCurveEnds(owner, cls: cls, tag: tag, axes: nil, start: value, end: value, over: 1, title: title)
    }

    @ViewBuilder private var look: some View {
        let particle = layer.particle
        let type = particle.int("PrVT")
        Text("Look").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Type", "What the particle is. Changing it drops the settings of the old type (Undo brings them back)") {
            ChoiceField(choices: LayerPanel.types.map { FieldChoice(name: $0.0, value: $0.1) }, value: type) { value in
                document.setParticleType(particle, value)
            }
        }
        if let layerTexture = particle.child("TC1") {
            LayerTexturePicker(document: document, layer: layerTexture).padding(.leading, 32)
        }
        row("Blend", "How the particle mixes with what is behind it") {
            chips(LayerPanel.blends.map { ($0.0, $0.1, "Draw Mode " + $0.0) }, current: particle.int("RMT")) { value in
                document.setLayerField(particle, "RMT", value, title: "Set Draw Mode")
            }
        }
        row("Facing", "Which way the particle faces") {
            chips(LayerPanel.facings, current: particle.int("RBDT")) { value in
                document.setLayerField(particle, "RBDT", value, title: "Set Facing")
            }
        }
        row("Axes", "The effect's +Z is where the character faces; with the camera behind the character, +X is on the left. Markers show each live emitter's axes, the corner shows the world's") {
            Text("+Z forward · +X left · +Y up").font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
            SegmentButton(title: "Show", active: app.showEmitters && app.showWorldAxes) {
                let on = !(app.showEmitters && app.showWorldAxes)
                app.showEmitters = on
                app.showWorldAxes = on
            }
        }
        row("Color", "Colour and alpha at birth → at the end of its life") {
            if let ends = document.colorEnds(particle) {
                color(ends.start) { next in document.setColorEnds(particle, start: next, end: ends.start == ends.end ? next : ends.end, over: span) }
                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundStyle(Theme.dim)
                color(ends.end) { next in document.setColorEnds(particle, start: ends.start, end: next, over: span) }
            } else if particle.child("Col") != nil {
                customCurve(layer.particleID, "Col")
            }
        }
        row("Size", "Size at birth → at the end of its life; 1 is one metre for a Quad") {
            switch document.curveEnds(particle.child("Scl")?.child("X")) {
            case .custom?:
                customCurve(layer.particleID, "Scl")
            case .values(let start, let end)?:
                number(start, step: 0.01, digits: 2) { next in
                    document.setCurveEnds(particle, cls: "AvfxParticle", tag: "Scl", axes: ["X", "Y", "Z"], start: next, end: start == end ? next : end, over: span, title: "Set Size")
                }
                Image(systemName: "arrow.right").font(.system(size: 8)).foregroundStyle(Theme.dim)
                number(end, step: 0.01, digits: 2) { next in
                    document.setCurveEnds(particle, cls: "AvfxParticle", tag: "Scl", axes: ["X", "Y", "Z"], start: start, end: next, over: span, title: "Set Size")
                }
            case nil:
                number(1, step: 0.01, digits: 2) { next in
                    document.setCurveEnds(particle, cls: "AvfxParticle", tag: "Scl", axes: ["X", "Y", "Z"], start: next, end: next, over: span, title: "Set Size")
                }
            }
        }
        row("Life", "How many frames a particle lives (30 frames = 1 second). Forever keeps it until the effect is released") {
            let life = document.layerLife(particle)
            if let life { number(life, suffix: " fr", step: 1, isInteger: true) { document.setLayerLife(particle, max(1, $0), title: "Set Particle Life") } }
            CheckBox(isOn: life == nil, label: "Forever") { on in document.setLayerLife(particle, on ? nil : 40, title: "Set Particle Life") }.fixedSize()
        }
    }

    private func dataNumber(_ particle: AvfxBlock, _ tag: String, _ label: String, _ help: String, scale: Double = 1, suffix: String, step: Double, digits: Int) -> some View {
        let data = particle.child("Data")
        let curve = data?.child(tag)
        let cls = document.particleDataClass(particle) ?? ""
        return row(label, help) {
            if case .custom? = document.curveEnds(curve) {
                customCurve(layer.particleID, tag)
            } else if let data {
                number((constant(curve) ?? 0) * scale, suffix: suffix, step: step, digits: digits) { next in
                    document.setCurveEnds(data, cls: cls, tag: tag, axes: nil, start: next / scale, end: next / scale, over: 1, title: "Set " + label)
                }
            }
        }
    }

    private func dataInt(_ particle: AvfxBlock, _ tag: String, _ label: String, _ help: String, range: ClosedRange<Int>) -> some View {
        row(label, help) {
            if let data = particle.child("Data"), let field = data.child(tag) {
                number(Double(field.intValue), step: 1, isInteger: true) { next in
                    document.setLayerField(data, tag, min(max(Int(next), range.lowerBound), range.upperBound), title: "Set " + label)
                }
            }
        }
    }

    @ViewBuilder private var shapeRows: some View {
        let particle = layer.particle
        switch particle.int("PrVT") {
        case 6:
            Text("Ribbon").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            row("Kind", "Trail: the path the particle flew. Line: a straight line along the particle's own axis") {
                chips([("Trail", 1, "Position History"), ("Line", 0, "Axis Order")], current: particle.child("Data")?.int("LnCT")) { value in
                    if let data = particle.child("Data") { document.setLayerField(data, "LnCT", value, title: "Set Create Line Type") }
                }
            }
            dataNumber(particle, "Wd", "Width", "Half the ribbon's width in metres", suffix: " m", step: 0.01, digits: 3)
            dataNumber(particle, "Len", "Length", "The trail is at most this long along its path, in metres", suffix: " m", step: 0.1, digits: 2)
            dataInt(particle, "PnC", "Points", "Points in the chain, one per game frame: the trail covers the last Points − 1 frames. More than 64 crashed the game", range: 2...64)
            dataNumber(particle, "WdB", "Head Width", "Multiplies the width at the head", suffix: "×", step: 0.05, digits: 2)
            dataNumber(particle, "WdE", "Tail Width", "Multiplies the width at the tail; 0 makes it a point", suffix: "×", step: 0.05, digits: 2)
        case 12:
            Text("Disc").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            dataNumber(particle, "RB", "Radius", "Radius of the band's middle, metres per unit of Size", suffix: " m", step: 0.05, digits: 2)
            dataNumber(particle, "WB", "Band", "Half the band's width; equal to the radius makes a full disc", suffix: " m", step: 0.05, digits: 2)
            dataNumber(particle, "Ang", "Arc", "How much of the circle is drawn, from +X", scale: 180 / .pi, suffix: "°", step: 5, digits: 0)
        case 11:
            Text("Decal Ring").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            dataNumber(particle, "WID", "Ring Width", "Radii 0.5 ± this per unit of Size; 0.5 is a full disc", suffix: "", step: 0.01, digits: 3)
            row("Arc", "How much of the ring is drawn") {
                if let data = particle.child("Data"), let fan = data.child("RF") {
                    let arc = 2 * acos(max(-1, min(1, 1 - 2 * Double(fan.floatValue)))) * 180 / .pi
                    number(arc, suffix: "°", step: 5, digits: 0) { next in
                        let value = Float((1 - cos(min(max(next, 0), 360) * .pi / 360)) / 2)
                        guard value != fan.floatValue else { return }
                        document.batch("Set Ring Fan") { fan.floatValue = value }
                    }
                }
            }
        case 4:
            Text("Laser").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
            dataNumber(particle, "Len", "Length", "The beam runs this many metres along the particle's facing axis", suffix: " m", step: 0.1, digits: 2)
            dataNumber(particle, "Wdt", "Width", "Half the beam's width in metres", suffix: " m", step: 0.01, digits: 3)
        default:
            EmptyView()
        }
    }

    @ViewBuilder private func emission(_ emitter: AvfxBlock) -> some View {
        let shape = emitter.int("EVT")
        let mode = document.itemValue(emitter, list: "ItPr", index: layer.item, "CrTm") ?? 1
        Text("Emission").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Shape", "Where particles are born: one point, or spread over a cone, sphere or cylinder") {
            chips(EffectDocument.layerShapes.map { ($0.title, $0.type, $0.title) }, current: shape) { document.setEmitterShape(emitter, $0) }
        }
        if shape != 0 {
            let aim = document.emitterAim(emitter).map { Int(($0 * 180 / .pi).rounded()) }
            row("Aim", "Which way the shape throws particles") {
                if let aim {
                    chips(LayerPanel.aims, current: aim) { document.setEmitterAim(emitter, Double($0) * .pi / 180) }
                } else { customCurve(layer.emitterID, "Rot") }
            }
        }
        if let speed = constant(dataCurve("IjS")) {
            row("Speed", "How fast particles fly away from the shape") {
                number(speed * 30, suffix: " m/s", step: 0.1, digits: 2) { setConstant(emitter.child("Data")!, cls: "AvfxEmitterData", "IjS", $0 / 30, title: "Set Speed") }
            }
        }
        if shape == 1, let angle = constant(dataCurve("IjA")) {
            row("Spread", "Half-angle of the cone around the emitter's +Z") {
                number(angle * 180 / .pi, suffix: "°", step: 1, digits: 0) { setConstant(emitter.child("Data")!, cls: "AvfxEmitterDataCone", "IjA", $0 * .pi / 180, title: "Set Spread") }
            }
        }
        if let tag = ["Rads", "Rad"].first(where: { dataCurve($0) != nil }), let radius = constant(dataCurve(tag)) {
            row("Radius") {
                number(radius, suffix: " m", step: 0.05, digits: 2) { setConstant(emitter.child("Data")!, cls: "AvfxEmitterData", tag, $0, title: "Set Radius") }
            }
        }
        row("Mode", "Stream: a new one every few frames while the emitter lives. Once: a batch when it starts") {
            chips([("Stream", 0, "Create Time 0"), ("Once", 1, "Create Time 1")], current: mode) { value in
                document.setItemField(emitter, list: "ItPr", index: layer.item, "CrTm", value, title: "Set Create Time")
            }
        }
        if mode == 0 {
            row("Every", "Frames between births") {
                if let every = constant(emitter.child("CrI")) {
                    number(every, suffix: " fr", step: 1, digits: 1) { setConstant(emitter, cls: "AvfxEmitter", "CrI", max(0.1, $0), title: "Set Interval") }
                } else { customCurve(layer.emitterID, "CrI") }
            }
            row("Count", "Particles born each time") {
                if let count = constant(emitter.child("CrC")) {
                    number(count, step: 1, digits: 0) { setConstant(emitter, cls: "AvfxEmitter", "CrC", max(0, $0.rounded()), title: "Set Count") }
                } else { customCurve(layer.emitterID, "CrC") }
            }
        } else {
            row("Count", "Particles born at once") {
                number(Double(document.itemValue(emitter, list: "ItPr", index: layer.item, "CrCn") ?? 1), step: 1, isInteger: true) { value in
                    document.setItemField(emitter, list: "ItPr", index: layer.item, "CrCn", max(0, Int(value)), title: "Set Create Count")
                }
            }
        }
        row("Particles", "How particles follow the emitter after they are born") {
            chips(LayerPanel.follows, current: document.itemValue(emitter, list: "ItPr", index: layer.item, "PICd")) { value in
                document.setItemField(emitter, list: "ItPr", index: layer.item, "PICd", value, title: "Set Influence on Child")
            }
        }
        row("Gravity", "Pull on the particles in metres per second²; negative falls down") {
            if let gravity = constant(layer.particle.child("Gra")) ?? (layer.particle.child("Gra") == nil ? 0 : nil) {
                number(gravity * 900, suffix: " m/s²", step: 0.1, digits: 2) { setConstant(layer.particle, cls: "AvfxParticle", "Gra", $0 / 900, title: "Set Gravity") }
            } else { customCurve(layer.particleID, "Gra") }
        }
    }

    @ViewBuilder private func timing(_ timeline: AvfxBlock) -> some View {
        let start = document.itemValue(timeline, list: "Item", index: layer.timelineItem, "StTm") ?? 0
        let end = document.itemValue(timeline, list: "Item", index: layer.timelineItem, "EdTm") ?? 0
        Text("Timing").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Starts", "Frame of Timeline \(layer.timelineIndex) the emitter starts on") {
            number(Double(start), suffix: " fr", step: 1, isInteger: true) { value in
                document.setItemField(timeline, list: "Item", index: layer.timelineItem, "StTm", max(0, Int(value)), title: "Set Start Time")
            }
        }
        row("Ends", "Frame the emitter stops on; Until Released keeps it running until the effect is released") {
            if end >= 0 {
                number(Double(end), suffix: " fr", step: 1, isInteger: true) { value in
                    document.setItemField(timeline, list: "Item", index: layer.timelineItem, "EdTm", max(start + 1, Int(value)), title: "Set End Time")
                }
            }
            CheckBox(isOn: end < 0, label: "Until Released") { on in
                document.batch("Set End Time") {
                    document.setItemField(timeline, list: "Item", index: layer.timelineItem, "EdTm", on ? -1 : start + 60, title: "Set End Time")
                    if let emitter = layer.emitter { document.setLayerLife(emitter, on ? nil : 60, title: "Set Emitter Life") }
                }
            }.fixedSize()
        }
    }

    @ViewBuilder private func attach(_ timeline: AvfxBlock) -> some View {
        let binders = document.avfxRoot?.childrenNamed("Bind") ?? []
        let current = document.itemValue(timeline, list: "Item", index: layer.timelineItem, "BdNo") ?? -1
        Text("Attach").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
        row("Binder", "What the layer is attached to. Spawned on a character, items without a binder are not drawn; spawned on the ground, items with one are not") {
            ChoiceField(choices: [FieldChoice(name: "None", value: -1)] + binders.indices.map { FieldChoice(name: "Binder \($0)", value: $0) }, value: current) { value in
                document.setItemField(timeline, list: "Item", index: layer.timelineItem, "BdNo", value, title: "Set Binder")
            }
        }
        if binders.indices.contains(current), binders[current].int("BnVr") == 0 {
            let binder = binders[current]
            row("Point", "The character's bind point the binder follows") {
                ChoiceField(choices: [FieldChoice(name: "Origin (feet)", value: -1)] + EffectDocument.bindPointNames.map { FieldChoice(name: "\($0.id) · \($0.name)", value: $0.id) },
                            value: document.binderPoint(binder) ?? -1) { value in
                    document.setBinderPoint(binder, value < 0 ? nil : value)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            row("Preset", "Sets the whole layer — look, emission and timing — to a ready recipe. Undo brings the old values back") {
                FlowLayout(spacing: 3) {
                    ForEach(LayerPreset.all, id: \.name) { preset in
                        SegmentButton(title: preset.name, active: false) { document.applyPreset(preset, to: layer) }.help(preset.help)
                    }
                }
            }
            Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
            look
            if [6, 12, 11, 4].contains(layer.particle.int("PrVT")) {
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                shapeRows
            }
            if let emitter = layer.emitter {
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                emission(emitter)
            }
            if let timeline = layer.timeline, layer.timelineItem >= 0 {
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                timing(timeline)
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 2)
                attach(timeline)
            }
            HStack(spacing: 4) {
                SegmentButton(title: "Particle", active: document.selectionID == layer.particleID) { document.selectionID = layer.particleID }
                if layer.emitter != nil { SegmentButton(title: "Emitter", active: document.selectionID == layer.emitterID) { document.selectionID = layer.emitterID } }
                if layer.timelineItem >= 0 {
                    let id = "avfx/TmLn/\(layer.timelineIndex)/Item/\(layer.timelineItem)"
                    SegmentButton(title: "Timeline Item", active: document.selectionID == id) { document.selectionID = id }
                }
            }
            .padding(.top, 2)
            .help("All fields of each part of the layer")
        }
    }
}
