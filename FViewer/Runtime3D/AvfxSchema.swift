import Foundation
import simd

struct RCurve {
    var keys: [AvfxKey]
    var pre: Int
    var post: Int
    var random: Int
    var color: Bool
}

struct RCurve3 {
    var x: RCurve?
    var y: RCurve?
    var z: RCurve?
    var rx: RCurve?
    var ry: RCurve?
    var rz: RCurve?
    var connect = 0
    var connectRandom = 0
}

struct RColor {
    var rgb: RCurve?
    var a: RCurve?
    var sclR: RCurve?
    var sclG: RCurve?
    var sclB: RCurve?
    var sclA: RCurve?
    var bri: RCurve?
    var ranBri: RCurve?
}

struct RLife {
    var value: Float = -1
    var random: Float = 0
}

struct RSchedulerItem {
    var enabled: Bool
    var start: Int
    var timeline: Int
}

struct RTimelineItem {
    var enabled: Bool
    var start: Int
    var end: Int
    var binder: Int
    var emitter: Int
    var clip: Int
}

struct RClip {
    var type: String
    var ints: [Int]
}

struct RTimeline {
    var binder: Int
    var items: [RTimelineItem]
    var clips: [RClip]
}

struct REmitterItem {
    var index: Int
    var enabled: Bool
    var target: Int
    var createTime: Int
    var createCount: Int
    var probability: Int
    var influenceCoord: Int
    var influenceColor: Int
    var inheritScale: Bool
    var inheritRotation: Bool
    var inheritPosition: Bool
    var overrideLife: Bool
    var overrideLifeValue: Float
    var overrideLifeRandom: Float
    var generateDelay: Int
    var generateDelayByOne: Bool
    var injectionAngle: Vec3
}

struct REmitter {
    var index: Int
    var type: Int
    var loopStart: Int
    var loopEnd: Int
    var childLimit: Int
    var rotationBase: Int
    var rotationOrder: Int
    var life: RLife
    var createCount: RCurve?
    var createCountRandom: RCurve?
    var createInterval: RCurve?
    var createIntervalRandom: RCurve?
    var gravity: RCurve?
    var airResistance: RCurve?
    var color: RColor
    var position: RCurve3
    var rotation: RCurve3
    var scale: RCurve3
    var particleItems: [REmitterItem]
    var emitterItems: [REmitterItem]
    var modelIndex: Int
    var generateMethod: Int
    var injectionSpeed: RCurve?
    var injectionSpeedRandom: RCurve?
    var divideX: Int
    var divideY: Int
    var radius: RCurve?
    var length: RCurve?
    var coneAngle: RCurve?
    var coneAngleRandom: RCurve?
    var coneRotation: [RCurve?] = [nil, nil, nil]
    var dataRotationOrder = 0
}

struct RUvSet {
    var scale: RCurve3
    var scroll: RCurve3
    var rotation: RCurve?
}

struct RTextureLayer {
    var enabled: Bool
    var colorToAlpha: Bool
    var uvSet: Int
    var borderU: Int
    var borderV: Int
    var calcColor: Int
    var calcAlpha: Int
    var textures: [Int]
    var texN: RCurve?
    var texNRandom: RCurve?
    var targets: [Bool] = [false, false, false, false]
    var power: RCurve?
    var screenCopy = false
}

struct RPalette {
    var enabled: Bool
    var border: Int
    var texture: Int
    var offset: RCurve?
    var offsetRandom: RCurve?
}

struct RSimple {
    var injectionPosition: Int
    var injectionModel: Int
    var createNewAfterDeath: Bool
    var lineLength: SIMD2<Float>
    var createCount: Int
    var createArea: Vec3
    var gravity: Vec3
    var scaleStart: SIMD2<Float>
    var scaleEnd: SIMD2<Float>
    var scaleCurve: Float
    var scaleRandomX: SIMD2<Float>
    var scaleRandomY: SIMD2<Float>
    var scaleRandomLink: Bool
    var scaleByParent: Bool
    var bindParent: Bool
    var flatteryRate: Float
    var coordAccuracy: Vec3
    var rotStart: Float
    var rotRandom: Float
    var rotVelocity: Float
    var blockCount: Int
    var velocityMin: Float
    var velocityMax: Float
    var uvCellsU: Int
    var uvCellsV: Int
    var uvInterval: Int
    var uvRandom: Int
    var pivot: SIMD2<Float>
    var interval: Int
    var intervalRandom: Int
    var intervalCount: Int
    var life: Float
    var colors: [Vec4]
    var frames: [Float]
}

struct RDisc {
    var countU: Int
    var countV: Int
    var curves: [String: RCurve]
    var colorInner: RColor?
    var colorOuter: RColor?
}

struct RPolyline {
    var createType: Int
    var pointCount: Int
    var pointCountCenter: Int
    var useEdge: Bool
    var width: RCurve?
    var widthBegin: RCurve?
    var widthCenter: RCurve?
    var widthEnd: RCurve?
    var length: RCurve?
    var colorBegin: RColor?
    var colorCenter: RColor?
    var colorEnd: RColor?
    var colorEdgeBegin: RColor?
    var colorEdgeCenter: RColor?
    var colorEdgeEnd: RColor?
}

struct RParticle {
    var index: Int
    var type: Int
    var loopStart: Int
    var loopEnd: Int
    var rotationBase: Int
    var rotationOrder: Int
    var drawMode: Int
    var culling: Int
    var depthTest: Bool
    var depthWrite: Bool
    var depthOffset: Float
    var drawPriority: Int
    var life: RLife
    var gravity: RCurve?
    var gravityRandom: RCurve?
    var airResistance: RCurve?
    var airResistanceRandom: RCurve?
    var scale: RCurve3
    var rotation: RCurve3
    var position: RCurve3
    var rotVelX: RCurve?
    var rotVelY: RCurve?
    var rotVelZ: RCurve?
    var color: RColor
    var uvSets: [RUvSet]
    var tc1: RTextureLayer?
    var tc2: RTextureLayer?
    var tc3: RTextureLayer?
    var tc4: RTextureLayer?
    var palette: RPalette?
    var distortion: RTextureLayer?
    var modelIndex: Int
    var colorBegin: RColor?
    var colorEnd: RColor?
    var lineLength: RCurve?
    var lineLengthRandom: RCurve?
    var laserWidth: RCurve?
    var laserWidthRandom: RCurve?
    var fresnelType: Int
    var windmillUvType: Int
    var ringWidth: RCurve?
    var ringWidthRandom: RCurve?
    var ringFan: Float
    var simple: RSimple?
    var disc: RDisc?
    var polyline: RPolyline?
    var softParticle = false
}

struct RBinder {
    var type = 0
    var distance: Float = 0
    var bindTargetPoint: Int
    var bindPointId: Int
}

struct REffector {
    var index: Int
    var type: Int
    var loopStart: Int
    var loopEnd: Int
    var color: RColor
    var distance: RCurve?
    var attenuation: Int
    var position: RCurve3
}

struct REffectSchema {
    var revisedPosition: Vec3
    var revisedRotation: Vec3
    var revisedScale: Vec3
    var revisedColor: Vec3
    var scheduler: [RSchedulerItem]
    var triggers: [RSchedulerItem]
    var timelines: [RTimeline]
    var emitters: [REmitter]
    var particles: [RParticle]
    var binders: [RBinder]
    var models: [AvfxBlock]
    var textureCount: Int
    var effectors: [REffector] = []
    var emitterEffectors: [Int] = []
    var softFadeRange: Float = 0.5
}

private extension Array where Element == AvfxBlock {
    func int(_ tag: String, _ fallback: Int = 0) -> Int { first { $0.tag == tag }?.intValue ?? fallback }
    func float(_ tag: String, _ fallback: Float = 0) -> Float { first { $0.tag == tag }?.floatValue ?? fallback }
    func bool(_ tag: String) -> Bool { int(tag) != 0 }
}

private extension AvfxBlock {
    func bool(_ tag: String) -> Bool { int(tag) != 0 }
    func byteFlag(_ tag: String, _ fallback: UInt8 = 0) -> Bool { (child(tag)?.data.first ?? fallback) != 0 }
    func lastRecords(_ tag: String) -> [[AvfxBlock]] {
        children?.last { $0.tag == tag && $0.children != nil }?.records() ?? []
    }
}

enum AvfxSchemaReader {
    static func curve(_ block: AvfxBlock?, color: Bool = false) -> RCurve? {
        guard let block, block.children != nil else { return nil }
        let keys = block.curveKeys.sorted { $0.time < $1.time }
        if keys.isEmpty { return nil }
        return RCurve(keys: keys, pre: block.int("BvPr"), post: block.int("BvPo"), random: block.int("RanT"), color: color)
    }

    static func curve3(_ block: AvfxBlock?) -> RCurve3 {
        guard let block else { return RCurve3() }
        return RCurve3(x: curve(block.child("X")), y: curve(block.child("Y")), z: curve(block.child("Z")), rx: curve(block.child("XR")),
                       ry: curve(block.child("YR")), rz: curve(block.child("ZR")), connect: block.int("ACT"), connectRandom: block.int("ACTR"))
    }

    static func color(_ block: AvfxBlock?) -> RColor {
        guard let block else { return RColor() }
        return RColor(rgb: curve(block.child("RGB"), color: true), a: curve(block.child("A")), sclR: curve(block.child("SclR")),
                      sclG: curve(block.child("SclG")), sclB: curve(block.child("SclB")), sclA: curve(block.child("SclA")),
                      bri: curve(block.child("Bri")), ranBri: curve(block.child("RBri")))
    }

    static func optionalColor(_ block: AvfxBlock?) -> RColor? { block == nil ? nil : color(block) }

    static func life(_ block: AvfxBlock?) -> RLife {
        guard let block else { return RLife() }
        if block.children == nil { return RLife(value: Float(block.intValue), random: 0) }
        return RLife(value: block.float("Val", -1), random: block.float("ValR"))
    }

    static func emitterItem(_ r: [AvfxBlock], index: Int) -> REmitterItem {
        REmitterItem(index: index, enabled: r.bool("bEnb"), target: r.int("TgtB"), createTime: r.int("CrTm"), createCount: r.int("CrCn", 1),
                     probability: r.int("CrPr", 100), influenceCoord: r.int("PICd"), influenceColor: r.int("PICo"), inheritScale: r.bool("ICbS"),
                     inheritRotation: r.bool("ICbR"), inheritPosition: r.bool("ICbP"), overrideLife: r.bool("bOvr"),
                     overrideLifeValue: Float(r.int("OvrV")), overrideLifeRandom: Float(r.int("OvrR")), generateDelay: r.int("GenD"),
                     generateDelayByOne: r.bool("bGD"), injectionAngle: Vec3(r.float("BIAX"), r.float("BIAY"), r.float("BIAZ")))
    }

    static func layer(_ block: AvfxBlock?) -> RTextureLayer? {
        guard let block, block.children != nil else { return nil }
        var textures: [Int] = []
        if let index = block.child("TxNo") { textures.append(index.intValue) }
        if let list = block.child("TLst") { textures.append(contentsOf: list.data.map { $0 == 255 ? -1 : Int($0) }) }
        return RTextureLayer(enabled: block.bool("bEna"), colorToAlpha: block.bool("bC2A"), uvSet: block.int("UvSN"), borderU: block.int("TBUT"),
                             borderV: block.int("TBVT"), calcColor: block.int("TCCT"), calcAlpha: block.int("TCAT"),
                             textures: textures.filter { $0 >= 0 }, texN: curve(block.child("TxN")), texNRandom: curve(block.child("TxNR")),
                             targets: [block.bool("bT1"), block.bool("bT2"), block.bool("bT3"), block.bool("bT4")], power: curve(block.child("DPow")),
                             screenCopy: block.bool("bUSC"))
    }

    static func simple(_ block: AvfxBlock?) -> RSimple? {
        guard let block, block.children != nil else { return nil }
        var colors: [Vec4] = []
        if let data = block.child("Cols")?.data {
            for o in stride(from: 0, to: data.count - 3, by: 4) {
                colors.append(Vec4(Float(data[o]), Float(data[o + 1]), Float(data[o + 2]), Float(data[o + 3])) / 255)
            }
        }
        var frames: [Float] = []
        if let data = block.child("Frms")?.data {
            for o in stride(from: 0, to: data.count - 1, by: 2) { frames.append(Float(Int16(bitPattern: data.u16(o)))) }
        }
        func f(_ tag: String, _ fallback: Float = 0) -> Float { block.float(tag, fallback) }
        func i(_ tag: String, _ fallback: Int = 0) -> Int { block.int(tag, fallback) }
        return RSimple(
            injectionPosition: i("SIPT"), injectionModel: i("IJMN", -1), createNewAfterDeath: block.byteFlag("bCrN"),
            lineLength: SIMD2(f("LLin"), f("LLax")), createCount: i("CCnt", 1), createArea: Vec3(f("CrAX"), f("CrAY"), f("CrAZ")),
            gravity: Vec3(f("CGX"), f("CGY"), f("CGZ")), scaleStart: SIMD2(f("SBX", 1), f("SBY", 1)), scaleEnd: SIMD2(f("SEX", 1), f("SEY", 1)),
            scaleCurve: f("SC", 1), scaleRandomX: SIMD2(f("SRX0", 1), f("SRX1", 1)), scaleRandomY: SIMD2(f("SRY0", 1), f("SRY1", 1)),
            scaleRandomLink: block.byteFlag("bSRL"), scaleByParent: block.byteFlag("bSnP"), bindParent: block.byteFlag("bBnP", 255),
            flatteryRate: f("FltR"), coordAccuracy: Vec3(f("CAX", 1), f("CAY", 1), f("CAZ", 1)), rotStart: f("RIZ"), rotRandom: f("RBZ"),
            rotVelocity: f("RVZ"), blockCount: max(1, i("BlkN", 1)), velocityMin: f("VMin"), velocityMax: f("VMax"),
            uvCellsU: max(1, i("UvCU", 1)), uvCellsV: max(1, i("UvCV", 1)), uvInterval: i("UvIv", 1), uvRandom: i("UvNR"),
            pivot: SIMD2(f("PvtX"), f("PvtY")), interval: i("CrI", 1), intervalRandom: i("CrIR"), intervalCount: max(1, i("CrIC", 1)),
            life: Float(max(1, i("CrIL", 1))), colors: colors, frames: frames)
    }

    static func disc(_ block: AvfxBlock?) -> RDisc? {
        guard let block, block.children != nil else { return nil }
        var curves: [String: RCurve] = [:]
        for tag in ["Ang", "AngR", "HBI", "HBIR", "HEI", "HEIR", "HBO", "HBOR", "HEO", "HEOR", "WB", "WBR", "WE", "WER", "RB", "RBR", "RE", "RER"] {
            curves[tag] = curve(block.child(tag))
        }
        return RDisc(countU: block.int("PCnU", 2), countV: block.int("PCnV", 2), curves: curves, colorInner: optionalColor(block.child("CEI")),
                     colorOuter: optionalColor(block.child("CEO")))
    }

    static func polyline(_ block: AvfxBlock?) -> RPolyline? {
        guard let block, block.children != nil else { return nil }
        return RPolyline(createType: block.int("LnCT"), pointCount: block.int("PnC", 2), pointCountCenter: block.int("PnCC"), useEdge: block.bool("bEdg"),
                         width: curve(block.child("Wd")), widthBegin: curve(block.child("WdB")), widthCenter: curve(block.child("WdC")),
                         widthEnd: curve(block.child("WdE")), length: curve(block.child("Len")), colorBegin: optionalColor(block.child("ColB")),
                         colorCenter: optionalColor(block.child("ColC")), colorEnd: optionalColor(block.child("ColE")),
                         colorEdgeBegin: optionalColor(block.child("CoEB")), colorEdgeCenter: optionalColor(block.child("CoEC")),
                         colorEdgeEnd: optionalColor(block.child("CoEE")))
    }

    static func read(_ root: AvfxBlock) -> REffectSchema {
        let schedulerBlock = root.child("Schd")
        let scheduler = (schedulerBlock?.lastRecords("Item") ?? []).map {
            RSchedulerItem(enabled: $0.bool("bEna"), start: $0.int("StTm"), timeline: $0.int("TlNo"))
        }
        let triggers = (schedulerBlock?.lastRecords("Trgr") ?? []).dropFirst(scheduler.count).map {
            RSchedulerItem(enabled: $0.bool("bEna"), start: $0.int("StTm"), timeline: $0.int("TlNo", -1))
        }
        let timelines = root.childrenNamed("TmLn").map { t in
            RTimeline(binder: t.int("BnNo", -1),
                      items: t.lastRecords("Item").map {
                          RTimelineItem(enabled: $0.bool("bEna"), start: $0.int("StTm"), end: $0.int("EdTm"), binder: $0.int("BdNo", -1),
                                        emitter: $0.int("EmNo", -1), clip: $0.int("ClNo", -1))
                      },
                      clips: t.childrenNamed("Clip").map { clip in
                          let d = clip.data
                          let type = d.count >= 4 ? String(decoding: d.prefix(4).reversed(), as: UTF8.self) : ""
                          let ints = (0..<4).map { d.count >= 8 + $0 * 4 ? Int(Int32(bitPattern: d.u32(4 + $0 * 4))) : 0 }
                          return RClip(type: type, ints: ints)
                      })
        }
        let emitters = root.childrenNamed("Emit").enumerated().map { index, e -> REmitter in
            let particleRecords = e.lastRecords("ItPr")
            let emitterRecords = e.lastRecords("ItEm").dropFirst(particleRecords.count)
            let data = e.child("Data")
            return REmitter(
                index: index, type: e.int("EVT"), loopStart: e.int("LpSt"), loopEnd: e.int("LpEd"), childLimit: e.int("ClCn"),
                rotationBase: e.int("RBDT"), rotationOrder: e.int("ROT"), life: life(e.child("Life")), createCount: curve(e.child("CrC")),
                createCountRandom: curve(e.child("CrCR")), createInterval: curve(e.child("CrI")), createIntervalRandom: curve(e.child("CrIR")),
                gravity: curve(e.child("Gra")), airResistance: curve(e.child("ARs")), color: color(e.child("Col")),
                position: curve3(e.child("Pos")), rotation: curve3(e.child("Rot")), scale: curve3(e.child("Scl")),
                particleItems: particleRecords.enumerated().map { emitterItem($0.element, index: $0.offset) },
                emitterItems: emitterRecords.enumerated().map { emitterItem($0.element, index: $0.offset) },
                modelIndex: data?.int("MdNo", -1) ?? -1, generateMethod: data?.int("GeMT") ?? 0, injectionSpeed: curve(data?.child("IjS")),
                injectionSpeedRandom: curve(data?.child("IjSR")), divideX: data?.int("DivX", 1) ?? 1, divideY: data?.int("DivY", 1) ?? 1,
                radius: curve(data?.child("Rad")) ?? curve(data?.child("Rads")), length: curve(data?.child("Len")),
                coneAngle: curve(data?.child("IjA")), coneAngleRandom: curve(data?.child("IjAR")),
                coneRotation: [curve(data?.child("AnX")), curve(data?.child("AnY")), curve(data?.child("AnZ"))],
                dataRotationOrder: data?.int("ROT") ?? 0)
        }
        let particles = root.childrenNamed("Ptcl").enumerated().map { index, p -> RParticle in
            let data = p.child("Data")
            let type = p.int("PrVT") == 9 && PreviewRules.isOn("polygonAsQuad") ? 8 : p.int("PrVT")
            var palette: RPalette?
            if let tp = p.child("TP"), tp.children != nil {
                palette = RPalette(enabled: tp.bool("bEna"), border: tp.int("TBT"), texture: tp.int("TxNo", -1), offset: curve(tp.child("POff")),
                                   offsetRandom: curve(tp.child("POfR")))
            }
            var modelIndex = data?.int("MNO", -1) ?? -1
            if let list = data?.child("MdNo"), let first = list.data.first { modelIndex = first == 255 ? -1 : Int(first) }
            return RParticle(
                index: index, type: type, loopStart: p.int("LpSt"), loopEnd: p.int("LpEd"), rotationBase: p.int("RBDT"),
                rotationOrder: p.int("RoOT"), drawMode: p.int("RMT"), culling: p.int("CulT"), depthTest: p.bool("DsDt"),
                depthWrite: p.bool("DsDw"), depthOffset: p.float("DpOf"), drawPriority: p.int("DwPr"), life: life(p.child("Life")),
                gravity: curve(p.child("Gra")), gravityRandom: curve(p.child("GraR")), airResistance: curve(p.child("ARs")),
                airResistanceRandom: curve(p.child("ARsR")), scale: curve3(p.child("Scl")), rotation: curve3(p.child("Rot")),
                position: curve3(p.child("Pos")), rotVelX: curve(p.child("VRX")), rotVelY: curve(p.child("VRY")), rotVelZ: curve(p.child("VRZ")),
                color: color(p.child("Col")),
                uvSets: p.childrenNamed("UvSt").map { RUvSet(scale: curve3($0.child("Scl")), scroll: curve3($0.child("Scr")), rotation: curve($0.child("Rot"))) },
                tc1: layer(p.child("TC1")), tc2: layer(p.child("TC2")), tc3: layer(p.child("TC3")), tc4: layer(p.child("TC4")),
                palette: palette, distortion: layer(p.child("TD")), modelIndex: modelIndex, colorBegin: optionalColor(data?.child("ColB")),
                colorEnd: optionalColor(data?.child("ColE")), lineLength: curve(data?.child("Len")), lineLengthRandom: curve(data?.child("LenR")),
                laserWidth: curve(data?.child("Wdt")), laserWidthRandom: curve(data?.child("WdtR")), fresnelType: data?.int("FrsT") ?? 0,
                windmillUvType: data?.int("WUvT") ?? 0, ringWidth: curve(data?.child("WID")), ringWidthRandom: curve(data?.child("WIDR")),
                ringFan: data?.float("RF", 1) ?? 1, simple: p.bool("bSCt") ? simple(p.child("Smpl")) : nil, disc: type == 12 ? disc(data) : nil,
                polyline: type == 6 ? polyline(data) : nil, softParticle: p.bool("DsSp"))
        }
        let binders = root.childrenNamed("Bind").map { b -> RBinder in
            let props = b.child("PrpS")
            return RBinder(type: b.int("BnVr"), distance: b.child("Data")?.float("Dst") ?? 0, bindTargetPoint: props?.int("BPTP") ?? 0,
                           bindPointId: props?.int("BPID", -1) ?? -1)
        }
        var result = REffectSchema(
            revisedPosition: Vec3(root.float("RvPx"), root.float("RvPy"), root.float("RvPz")),
            revisedRotation: Vec3(root.float("RvRx"), root.float("RvRy"), root.float("RvRz")),
            revisedScale: Vec3(root.float("RvSx", 1), root.float("RvSy", 1), root.float("RvSz", 1)),
            revisedColor: Vec3(root.float("RvR", 1), root.float("RvG", 1), root.float("RvB", 1)),
            scheduler: scheduler, triggers: Array(triggers), timelines: timelines, emitters: emitters, particles: particles, binders: binders,
            models: root.childrenNamed("Modl"), textureCount: root.childrenNamed("Tex").count)
        result.effectors = root.childrenNamed("Efct").enumerated().map { index, block in
            let data = block.child("Data")
            return REffector(index: index, type: block.int("EfVT"), loopStart: block.int("LpSt"), loopEnd: block.int("LpEd"),
                             color: color(data?.child("Col")), distance: curve(data?.child("DstS")), attenuation: data?.int("Attn") ?? 0,
                             position: curve3(data?.child("Pos")))
        }
        result.emitterEffectors = root.childrenNamed("Emit").map { $0.int("EfNo", -1) }
        if let range = root.child("SPFR"), range.children == nil, range.data.count >= 4 { result.softFadeRange = max(0.001, root.float("SPFR", 0.5)) }
        return result
    }
}
