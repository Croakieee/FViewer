import Foundation

struct EffectLayer {
    let particle: AvfxBlock
    let particleIndex: Int
    let emitter: AvfxBlock?
    let emitterIndex: Int
    let item: Int
    let timeline: AvfxBlock?
    let timelineIndex: Int
    let timelineItem: Int

    var particleID: String { "avfx/Ptcl/\(particleIndex)" }
    var emitterID: String { "avfx/Emit/\(emitterIndex)" }
}

enum LayerEnd {
    case values(Double, Double)
    case custom
}

extension EffectDocument {
    func layer(for nodeID: String) -> EffectLayer? {
        guard let root = avfxRoot else { return nil }
        let parts = nodeID.split(separator: "/").map(String.init)
        guard parts.count >= 3, parts[0] == "avfx", let index = Int(parts[2]) else { return nil }
        let particles = root.childrenNamed("Ptcl"), emitters = root.childrenNamed("Emit")
        func int(_ record: [AvfxBlock], _ tag: String) -> Int { record.first { $0.tag == tag }?.intValue ?? -1 }
        func build(particle: Int, emitter: Int, item: Int) -> EffectLayer? {
            guard particles.indices.contains(particle) else { return nil }
            var timelineIndex = -1, timelineItem = -1
            for (t, timeline) in root.childrenNamed("TmLn").enumerated() {
                if let k = timeline.ownRecords("Item").firstIndex(where: { int($0, "EmNo") == emitter && emitter >= 0 }) {
                    timelineIndex = t
                    timelineItem = k
                    break
                }
            }
            let timelines = root.childrenNamed("TmLn")
            return EffectLayer(particle: particles[particle], particleIndex: particle,
                               emitter: emitters.indices.contains(emitter) ? emitters[emitter] : nil, emitterIndex: emitter, item: item,
                               timeline: timelines.indices.contains(timelineIndex) ? timelines[timelineIndex] : nil,
                               timelineIndex: timelineIndex, timelineItem: timelineItem)
        }
        func emitterOf(particle: Int) -> (Int, Int) {
            for (e, emitter) in emitters.enumerated() {
                if let k = emitter.ownRecords("ItPr").firstIndex(where: { int($0, "TgtB") == particle }) { return (e, k) }
            }
            return (-1, -1)
        }
        switch parts[1] {
        case "Ptcl":
            let (e, k) = emitterOf(particle: index)
            return build(particle: index, emitter: e, item: k)
        case "Emit":
            guard emitters.indices.contains(index) else { return nil }
            let records = emitters[index].ownRecords("ItPr")
            guard let first = records.first else { return nil }
            return build(particle: int(first, "TgtB"), emitter: index, item: 0)
        case "TmLn":
            guard parts.count >= 5, parts[3] == "Item", let k = Int(parts[4]) else { return nil }
            let timelines = root.childrenNamed("TmLn")
            guard timelines.indices.contains(index) else { return nil }
            let records = timelines[index].ownRecords("Item")
            guard records.indices.contains(k) else { return nil }
            let emitter = int(records[k], "EmNo")
            guard emitters.indices.contains(emitter), let first = emitters[emitter].ownRecords("ItPr").first else { return nil }
            return build(particle: int(first, "TgtB"), emitter: emitter, item: 0)
        default:
            return nil
        }
    }

    func layerLife(_ owner: AvfxBlock) -> Double? {
        guard let life = owner.child("Life") else { return nil }
        if life.children == nil { return life.intValue < 0 ? nil : Double(life.intValue) }
        let value = Double(life.float("Val"))
        return value < 0 ? nil : value
    }

    func setLayerLife(_ owner: AvfxBlock, _ frames: Double?, title: String) {
        guard let life = owner.child("Life") else { return }
        let old = layerLife(owner)
        batch(title) {
            if let old, let frames, owner.tag == "Ptcl" { stretchLookCurves(owner, from: old, to: frames) }
            if let frames {
                if life.children == nil { makeLifeFinite(life, in: owner) }
                owner.child("Life")?.child("Val")?.floatValue = Float(max(1, frames.rounded()))
            } else if life.children != nil {
                makeLifeInfinite(life, in: owner)
            }
        }
    }

    private func stretchLookCurves(_ particle: AvfxBlock, from old: Double, to new: Double) {
        let curves = ["X", "Y", "Z"].compactMap { particle.child("Scl")?.child($0) } + ["RGB", "A"].compactMap { particle.child("Col")?.child($0) }
        let span = max(1, Int(new.rounded()))
        for curve in curves {
            var keys = curve.curveKeys
            guard keys.count == 2, keys[0].time == 0, keys[1].time == Int(old.rounded()) else { continue }
            keys[1].time = span
            curve.curveKeys = keys
        }
    }

    func emitterAim(_ emitter: AvfxBlock) -> Double? {
        guard let rotation = emitter.child("Rot") else { return 0 }
        let axes = ["X", "Y", "Z"].map { rotation.child($0)?.curveKeys ?? [] }
        guard axes.allSatisfy({ $0.count <= 1 }), (axes[1].first?.z ?? 0) == 0, (axes[2].first?.z ?? 0) == 0 else { return nil }
        return Double(axes[0].first?.z ?? 0)
    }

    func setEmitterAim(_ emitter: AvfxBlock, _ radians: Double) {
        batch("Set Emitter Aim") {
            if emitter.child("Rot") == nil { putCurve(AvfxBlock.curveAxes(tag: "Rot", axes: ["X", "Y", "Z"], value: 0), into: emitter, cls: "AvfxEmitter") }
            guard let rotation = emitter.child("Rot") else { return }
            if rotation.child("X") == nil { rotation.insert(AvfxBlock.curveData(tag: "X", value: 0), at: 2) }
            rotation.child("X")?.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: Float(radians))]
        }
    }

    func curveEnds(_ curve: AvfxBlock?) -> LayerEnd? {
        guard let curve else { return nil }
        let keys = curve.curveKeys
        switch keys.count {
        case 0: return nil
        case 1: return .values(Double(keys[0].z), Double(keys[0].z))
        case 2: return .values(Double(keys[0].z), Double(keys[1].z))
        default: return .custom
        }
    }

    func layerKeys(_ start: Double, _ end: Double, over frames: Double) -> [AvfxKey] {
        if start == end { return [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: Float(start))] }
        return [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: Float(start)), AvfxKey(time: max(1, Int(frames.rounded())), type: 1, x: 1, y: 1, z: Float(end))]
    }

    func setCurveEnds(_ owner: AvfxBlock, cls: String, tag: String, axes: [String]?, start: Double, end: Double, over frames: Double, title: String) {
        batch(title) {
            if owner.child(tag) == nil {
                putCurve(axes.map { AvfxBlock.curveAxes(tag: tag, axes: $0, value: 0) } ?? AvfxBlock.curveData(tag: tag, value: 0), into: owner, cls: cls)
            }
            guard let curve = owner.child(tag) else { return }
            for target in axes.map({ $0.compactMap { curve.child($0) } }) ?? [curve] {
                target.curveKeys = layerKeys(start, end, over: frames)
            }
        }
    }

    func colorEnds(_ particle: AvfxBlock) -> (start: SIMD4<Double>, end: SIMD4<Double>)? {
        guard let color = particle.child("Col"), let rgb = color.child("RGB")?.curveKeys, let alpha = color.child("A")?.curveKeys,
              (1...2).contains(rgb.count), (1...2).contains(alpha.count) else { return nil }
        let first = rgb[0], last = rgb[rgb.count - 1]
        return (SIMD4(Double(first.x), Double(first.y), Double(first.z), Double(alpha[0].z)),
                SIMD4(Double(last.x), Double(last.y), Double(last.z), Double(alpha[alpha.count - 1].z)))
    }

    func setColorEnds(_ particle: AvfxBlock, start: SIMD4<Double>, end: SIMD4<Double>, over frames: Double) {
        batch("Set Color") {
            if particle.child("Col") == nil { putCurve(AvfxBlock.curveColor(tag: "Col"), into: particle, cls: "AvfxParticle") }
            guard let color = particle.child("Col") else { return }
            if color.child("RGB") == nil { color.insert(AvfxBlock.curveColor(tag: "Col").child("RGB")!, at: 0) }
            if color.child("A") == nil { color.insert(AvfxBlock.curveData(tag: "A", value: 1), at: 1) }
            let span = max(1, Int(frames.rounded()))
            let sameColor = start.x == end.x && start.y == end.y && start.z == end.z
            color.child("RGB")?.curveKeys = sameColor ? [AvfxKey(time: 0, type: 1, x: Float(start.x), y: Float(start.y), z: Float(start.z))]
                : [AvfxKey(time: 0, type: 1, x: Float(start.x), y: Float(start.y), z: Float(start.z)),
                   AvfxKey(time: span, type: 1, x: Float(end.x), y: Float(end.y), z: Float(end.z))]
            color.child("A")?.curveKeys = layerKeys(start.w, end.w, over: frames)
        }
    }

    func setLayerField(_ owner: AvfxBlock, _ tag: String, _ value: Int, title: String) {
        guard let field = owner.child(tag), field.intValue != value else { return }
        batch(title) { field.intValue = value }
    }

    func setItemField(_ owner: AvfxBlock, list: String, index: Int, _ tag: String, _ value: Int, title: String) {
        let records = owner.ownRecords(list)
        guard records.indices.contains(index), let field = records[index].first(where: { $0.tag == tag }), field.intValue != value else { return }
        batch(title) {
            field.intValue = value
            owner.setOwnRecords(list, records)
        }
    }

    func itemValue(_ owner: AvfxBlock?, list: String, index: Int, _ tag: String) -> Int? {
        guard let owner else { return nil }
        let records = owner.ownRecords(list)
        guard records.indices.contains(index), let field = records[index].first(where: { $0.tag == tag }) else { return nil }
        return field.intValue
    }

    static let layerShapes: [(title: String, type: Int)] = [("Point", 0), ("Cone", 1), ("Sphere", 3), ("Cylinder", 4)]

    func setEmitterShape(_ emitter: AvfxBlock, _ type: Int) {
        guard let typeField = emitter.child("EVT"), typeField.intValue != type else { return }
        batch("Set Emitter Shape") {
            applyType(typeField, ownerClass: "AvfxEmitter", value: type)
            guard let data = emitter.child("Data") else { return }
            func put(_ tag: String, _ value: Float) {
                if let curve = data.child(tag) { curve.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: value)] }
            }
            func whole(_ tag: String, _ value: Int) { data.child(tag)?.intValue = value }
            switch type {
            case 1:
                put("IjA", 0.5)
                put("IjS", 0.05)
                put("OuS", 0)
            case 3:
                put("Rads", 0.5)
                put("IjS", 0.03)
                whole("DivX", 8)
                whole("DivY", 4)
            case 4:
                put("Rad", 0.5)
                put("Len", 1)
                put("IjS", 0.03)
                whole("DivX", 8)
                whole("DivY", 2)
            default:
                break
            }
        }
    }

    func binderPoint(_ binder: AvfxBlock) -> Int? {
        guard let properties = binder.child("PrpS"), properties.int("BPTP") == 3 else { return nil }
        return properties.int("BPID")
    }

    func setBinderPoint(_ binder: AvfxBlock, _ point: Int?) {
        guard let properties = binder.child("PrpS") else { return }
        batch("Set Bind Point") {
            properties.child("BPTP")?.intValue = point == nil ? 0 : 3
            if let point { properties.child("BPID")?.intValue = point }
        }
    }
}

struct LayerPreset {
    let name: String
    let help: String
    let texture: String
    let blend: Int
    let facing: Int
    let colorStart: SIMD4<Double>
    let colorEnd: SIMD4<Double>
    let sizeStart: Double
    let sizeEnd: Double
    let life: Double?
    let shape: Int
    let aim: Double
    let speed: Double
    let spread: Double
    let stream: Bool
    let every: Double
    let count: Double
    let follow: Int
    let gravity: Double
    var point: Int? = nil
    var textureColor = 0
    var colorToAlpha = false
    var type = 8
    var data: [(String, Double)] = []
    var ints: [(String, Int)] = []

    static let all: [LayerPreset] = [
        LayerPreset(name: "Glow", help: "A soft light that stays on the bind point until the effect is released", texture: "vfx/common/texture/glow006fc.atex",
                    blend: 2, facing: 6, colorStart: SIMD4(1, 0.85, 0.55, 1), colorEnd: SIMD4(1, 0.85, 0.55, 1), sizeStart: 1, sizeEnd: 1, life: nil,
                    shape: 0, aim: 0, speed: 0, spread: 0, stream: false, every: 1, count: 1, follow: 2, gravity: 0),
        LayerPreset(name: "Sparks", help: "Small bright sparks thrown up that fall and fade", texture: "vfx/common/texture/glow001bf.atex",
                    blend: 2, facing: 6, colorStart: SIMD4(1, 0.8, 0.35, 1), colorEnd: SIMD4(1, 0.25, 0.05, 0), sizeStart: 0.35, sizeEnd: 0.05, life: 24,
                    shape: 1, aim: -90, speed: 4, spread: 35, stream: true, every: 2, count: 2, follow: 3, gravity: -6),
        LayerPreset(name: "Fire", help: "Flames rising from the point", texture: "vfx/common/texture/glow001f.atex",
                    blend: 2, facing: 6, colorStart: SIMD4(1, 0.9, 0.5, 1), colorEnd: SIMD4(1, 0.3, 0.05, 0), sizeStart: 0.9, sizeEnd: 0.3, life: 25,
                    shape: 1, aim: -90, speed: 1.2, spread: 10, stream: true, every: 1, count: 1, follow: 3, gravity: 0),
        LayerPreset(name: "Smoke", help: "Slow grey puffs that rise, grow and fade", texture: "vfx/common/texture/smoke004_e2.atex",
                    blend: 0, facing: 6, colorStart: SIMD4(0.55, 0.55, 0.55, 0.6), colorEnd: SIMD4(0.4, 0.4, 0.4, 0), sizeStart: 0.5, sizeEnd: 1.5, life: 60,
                    shape: 1, aim: -90, speed: 0.6, spread: 15, stream: true, every: 6, count: 1, follow: 3, gravity: 0, textureColor: 1, colorToAlpha: true),
        LayerPreset(name: "Burst", help: "One burst of sparks flying out in every direction, falling and fading", texture: "vfx/common/texture/glow001bf.atex",
                    blend: 2, facing: 6, colorStart: SIMD4(1, 0.95, 0.7, 1), colorEnd: SIMD4(1, 0.4, 0.1, 0), sizeStart: 0.4, sizeEnd: 0.05, life: 30,
                    shape: 3, aim: 0, speed: 5, spread: 0, stream: false, every: 1, count: 24, follow: 3, gravity: -4),
        LayerPreset(name: "Trail", help: "Glowing ribbons that streak up and arc down", texture: "vfx/common/texture/glow001f.atex",
                    blend: 2, facing: 6, colorStart: SIMD4(0.6, 0.85, 1, 1), colorEnd: SIMD4(0.3, 0.5, 1, 0), sizeStart: 1, sizeEnd: 1, life: 30,
                    shape: 1, aim: -90, speed: 4, spread: 40, stream: true, every: 6, count: 1, follow: 3, gravity: -5,
                    type: 6, data: [("Wd", 0.04), ("Len", 1.5), ("WdB", 1), ("WdC", 1), ("WdE", 0)], ints: [("LnCT", 1), ("PnC", 16), ("PnCC", 8)]),
        LayerPreset(name: "Beam", help: "A straight beam from the bind point along the character's facing", texture: "vfx/common/texture/glow001f.atex",
                    blend: 2, facing: 2, colorStart: SIMD4(0.5, 0.9, 1, 1), colorEnd: SIMD4(0.5, 0.9, 1, 1), sizeStart: 1, sizeEnd: 1, life: nil,
                    shape: 0, aim: 0, speed: 0, spread: 0, stream: false, every: 1, count: 1, follow: 2, gravity: 0,
                    type: 4, data: [("Len", 4), ("Wdt", 0.15)]),
        LayerPreset(name: "Ground Mark", help: "A ring painted on the ground at the feet, held until the effect is released", texture: "vfx/common/texture/glow006fc.atex",
                    blend: 2, facing: 2, colorStart: SIMD4(1, 0.6, 0.2, 1), colorEnd: SIMD4(1, 0.6, 0.2, 1), sizeStart: 3, sizeEnd: 3, life: nil,
                    shape: 0, aim: 0, speed: 0, spread: 0, stream: false, every: 1, count: 1, follow: 2, gravity: 0, point: -1,
                    type: 11, data: [("WID", 0.08)], ints: []),
        LayerPreset(name: "Ring", help: "A ring on the ground at the feet that grows and fades, again every second", texture: "vfx/common/texture/ring04a_c.atex",
                    blend: 2, facing: 1, colorStart: SIMD4(0.6, 0.85, 1, 1), colorEnd: SIMD4(0.6, 0.85, 1, 0), sizeStart: 0.2, sizeEnd: 3, life: 30,
                    shape: 0, aim: 0, speed: 0, spread: 0, stream: true, every: 30, count: 1, follow: 3, gravity: 0, point: -1),
    ]
}

extension EffectDocument {
    func applyPreset(_ preset: LayerPreset, to layer: EffectLayer) {
        let particle = layer.particle
        batch("Apply " + preset.name) {
            setParticleType(particle, preset.type)
            if let data = particle.child("Data") {
                for (tag, value) in preset.data {
                    if data.child(tag) == nil { putCurve(AvfxBlock.curveData(tag: tag, value: 0), into: data, cls: particleDataClass(particle) ?? "") }
                    data.child(tag)?.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: Float(value))]
                }
                for (tag, value) in preset.ints { data.child(tag)?.intValue = value }
            }
            particle.child("RMT")?.intValue = preset.blend
            particle.child("RBDT")?.intValue = preset.facing
            particle.child("CulT")?.intValue = 0
            if let layerTexture = particle.child("TC1") {
                setLayerTexture(layerTexture, path: preset.texture)
                layerTexture.child("TCCT")?.intValue = preset.textureColor
                layerTexture.child("bC2A")?.intValue = preset.colorToAlpha ? 1 : 0
            }
            setLayerLife(particle, preset.life, title: "Set Particle Life")
            let span = preset.life ?? 60
            setColorEnds(particle, start: preset.colorStart, end: preset.colorEnd, over: span)
            setCurveEnds(particle, cls: "AvfxParticle", tag: "Scl", axes: ["X", "Y", "Z"], start: preset.sizeStart, end: preset.sizeEnd, over: span, title: "Set Size")
            setCurveEnds(particle, cls: "AvfxParticle", tag: "Gra", axes: nil, start: preset.gravity / 900, end: preset.gravity / 900, over: 1, title: "Set Gravity")
            guard let emitter = layer.emitter else { return }
            setEmitterShape(emitter, preset.shape)
            setEmitterAim(emitter, preset.aim * .pi / 180)
            if let data = emitter.child("Data") {
                for (tag, value) in [("IjS", preset.speed / 30), ("IjA", preset.spread * .pi / 180)] where data.child(tag) != nil {
                    data.child(tag)?.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: Float(value))]
                }
            }
            setItemField(emitter, list: "ItPr", index: layer.item, "CrTm", preset.stream ? 0 : 1, title: "Set Create Time")
            setItemField(emitter, list: "ItPr", index: layer.item, "PICd", preset.follow, title: "Set Influence on Child")
            if preset.stream {
                setCurveEnds(emitter, cls: "AvfxEmitter", tag: "CrI", axes: nil, start: preset.every, end: preset.every, over: 1, title: "Set Interval")
                setCurveEnds(emitter, cls: "AvfxEmitter", tag: "CrC", axes: nil, start: preset.count, end: preset.count, over: 1, title: "Set Count")
            } else {
                setItemField(emitter, list: "ItPr", index: layer.item, "CrCn", Int(preset.count), title: "Set Create Count")
            }
            if let point = preset.point, let timeline = layer.timeline, layer.timelineItem >= 0 {
                setItemField(timeline, list: "Item", index: layer.timelineItem, "BdNo", binder(atPoint: point < 0 ? nil : point), title: "Set Binder")
            }
            if preset.life == nil, let timeline = layer.timeline, layer.timelineItem >= 0 {
                setItemField(timeline, list: "Item", index: layer.timelineItem, "EdTm", -1, title: "Set End Time")
                setLayerLife(emitter, nil, title: "Set Emitter Life")
            }
        }
    }

    func particleDataClass(_ particle: AvfxBlock) -> String? {
        guard let name = catalog.enumCaseName("ParticleType", particle.int("PrVT"))?.replacingOccurrences(of: "_Variable", with: "") else { return nil }
        return "AvfxParticleData" + name
    }

    func setParticleType(_ particle: AvfxBlock, _ type: Int) {
        guard let field = particle.child("PrVT"), field.intValue != type else { return }
        batch("Set Particle Type") {
            applyType(field, ownerClass: "AvfxParticle", value: type)
            guard let data = particle.child("Data") else { return }
            func put(_ tag: String, _ value: Float) {
                if let curve = data.child(tag), curve.curveKeys.isEmpty { curve.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: value)] }
            }
            func whole(_ tag: String, _ value: Int) { if let field = data.child(tag), field.intValue == 0 { field.intValue = value } }
            switch type {
            case 6:
                whole("LnCT", 1)
                whole("PnC", 16)
                whole("PnCC", 8)
                put("Wd", 0.05)
                put("Len", 2)
                for tag in ["WdB", "WdC", "WdE"] { put(tag, 1) }
            case 12:
                whole("PrtC", 1)
                whole("PCnU", 32)
                whole("PCnV", 2)
                put("RB", 1)
                put("RE", 1)
                put("WB", 0.2)
                put("WE", 0.2)
                put("Ang", Float.pi * 2)
            case 11:
                put("WID", 0.1)
                if let fan = data.child("RF"), fan.floatValue == 0 { fan.floatValue = 1 }
            case 4:
                put("Len", 3)
                put("Wdt", 0.1)
            default:
                break
            }
        }
    }

    func addCastEnd(trigger: Int = 0, fade: Int = 15) {
        guard let root = avfxRoot, let schedule = root.child("Schd"), let timeline = freshTopLevel("TmLn") else { return }
        var index = 0
        batch("Add Cast End") {
            index = insertFresh(timeline, into: root)
            var clip = Array("KILL".utf8.reversed())
            clip.append(contentsOf: [UInt8](repeating: 0, count: 160))
            clip.setU32(4, UInt32(fade))
            clip.setU32(8, 1)
            clip.setU32(20, Float(-1).bitPattern)
            timeline.insert(AvfxBlock(tag: "Clip", data: clip), at: timeline.children?.count ?? 0)
            let item = defaultRecord("AvfxTimelineItem")
            if let field = item.first(where: { $0.tag == "bEna" }) { field.intValue = 1 }
            if let field = item.first(where: { $0.tag == "ClNo" }) { field.intValue = 0 }
            if let field = item.first(where: { $0.tag == "EdTm" }) { field.intValue = 1 }
            timeline.setOwnRecords("Item", [item])
            let triggers = schedule.ownRecords("Trgr")
            if triggers.indices.contains(trigger) {
                triggers[trigger].first { $0.tag == "TlNo" }?.intValue = index
                triggers[trigger].first { $0.tag == "bEna" }?.intValue = 1
                schedule.setOwnRecords("Trgr", triggers)
            }
            for timeline in root.childrenNamed("TmLn").prefix(index) {
                let records = timeline.ownRecords("Item")
                for record in records where (record.first { $0.tag == "EmNo" }?.intValue ?? -1) >= 0 {
                    record.first { $0.tag == "EdTm" }?.intValue = -1
                }
                timeline.setOwnRecords("Item", records)
            }
            for emitter in root.childrenNamed("Emit") {
                if let life = emitter.child("Life"), life.children != nil { makeLifeInfinite(life, in: emitter) }
            }
        }
        if !clock.events.contains(where: { $0.kind == .trigger(trigger) }) { addEvent(.trigger(trigger), at: 60) }
        selectionID = "avfx/TmLn/\(index)"
    }

    func binder(atPoint point: Int?) -> Int {
        guard let root = avfxRoot else { return -1 }
        let binders = root.childrenNamed("Bind")
        if let found = binders.firstIndex(where: { $0.int("BnVr") == 0 && binderPoint($0) == point }) { return found }
        guard let fresh = freshTopLevel("Bind") else { return -1 }
        let index = insertFresh(fresh, into: root)
        if let properties = fresh.child("PrpS") {
            properties.child("BPTP")?.intValue = point == nil ? 0 : 3
            if let point { properties.child("BPID")?.intValue = point }
        }
        return index
    }

    func addLayer(preset: LayerPreset, to timeline: Int? = nil) {
        batch("Add " + preset.name) {
            addLayer(to: timeline)
            if let selected = selectionID, let layer = layer(for: selected) { applyPreset(preset, to: layer) }
        }
    }
}
