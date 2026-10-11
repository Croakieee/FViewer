import Foundation

struct AvfxField {
    let tag: String
    let name: String
    let type: String

    var enumName: String? {
        guard let open = type.firstIndex(of: "<"), type.hasSuffix(">") else { return nil }
        return String(type[type.index(after: open)..<type.index(before: type.endIndex)])
    }
    var baseType: String { type.split(separator: "<").first.map(String.init) ?? type }
}

struct AvfxEnumCase {
    let name: String
    let value: Int
}

final class AvfxCatalog {
    static let shared = AvfxCatalog()

    private(set) var classes: [String: [AvfxField]] = [:]
    private(set) var enums: [String: [AvfxEnumCase]] = [:]
    private var fieldMaps: [String: [String: AvfxField]] = [:]

    init(url: URL? = Bundle.main.url(forResource: "AvfxCatalog", withExtension: "json")) {
        guard let url, let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        for (name, fields) in json["classes"] as? [String: [[String]]] ?? [:] {
            let list = fields.filter { $0.count == 3 }.map {
                AvfxField(tag: $0[0], name: $0[1].replacingOccurrences(of: "##", with: ""), type: $0[2])
            }
            classes[name] = list
            var map: [String: AvfxField] = [:]
            for field in list where map[field.tag] == nil { map[field.tag] = field }
            fieldMaps[name] = map
        }
        for (name, cases) in json["enums"] as? [String: [[Any]]] ?? [:] {
            enums[name] = cases.compactMap {
                guard $0.count == 2, let n = $0[0] as? String, let v = ($0[1] as? NSNumber)?.intValue else { return nil }
                return AvfxEnumCase(name: n, value: v)
            }
        }
        addFields("AvfxLife", [("Val", "Value", "AvfxFloat"), ("ValR", "Random Value", "AvfxFloat"), ("Type", "Random Type", "AvfxEnum<RandomType>")])
        addFields("AvfxEmitter", [("EVT", "Type", "AvfxEnum<EmitterType>")])
        addFields("AvfxParticle", [("PrVT", "Type", "AvfxEnum<ParticleType>")])
        addFields("AvfxEffector", [("EfVT", "Type", "AvfxEnum<EffectorType>")])
        addFields("AvfxBinder", [("BnVr", "Type", "AvfxEnum<BinderType>")])
    }

    private func addFields(_ cls: String, _ fields: [(String, String, String)]) {
        for (tag, name, type) in fields where fieldMaps[cls]?[tag] == nil {
            let field = AvfxField(tag: tag, name: name, type: type)
            classes[cls, default: []].append(field)
            fieldMaps[cls, default: [:]][tag] = field
        }
    }

    static let typeTags: Set<String> = ["EVT", "PrVT", "EfVT", "BnVr"]
    static let countTags: Set<String> = ["ScCn", "TlCn", "EmCn", "PrCn", "EfCn", "BdCn", "TxCn", "MdCn", "KeyC", "ItCn", "TrCn", "TICn", "CpCn"]

    func field(_ cls: String?, _ tag: String) -> AvfxField? {
        guard let cls else { return nil }
        return fieldMaps[cls]?[tag]
    }

    func enumCaseName(_ enumName: String, _ value: Int) -> String? {
        enums[enumName]?.first { $0.value == value }?.name
    }

    private static let top: [String: String] = [
        "Schd": "AvfxScheduler", "TmLn": "AvfxTimeline", "Emit": "AvfxEmitter", "Ptcl": "AvfxParticle",
        "Efct": "AvfxEffector", "Bind": "AvfxBinder", "Tex": "AvfxTexture", "Modl": "AvfxModel",
    ]
    private static let lists: [String: [String: String]] = [
        "AvfxScheduler": ["Item": "AvfxSchedulerItem", "Trgr": "AvfxSchedulerItem"],
        "AvfxTimeline": ["Item": "AvfxTimelineItem"],
        "AvfxEmitter": ["ItPr": "AvfxEmitterItem", "ItEm": "AvfxEmitterItem"],
    ]
    private static let particleParts: [String: String] = [
        "Smpl": "AvfxParticleSimple", "TC1": "AvfxParticleTextureColor1", "TC2": "AvfxParticleTextureColor2",
        "TC3": "AvfxParticleTextureColor2", "TC4": "AvfxParticleTextureColor2", "TD": "AvfxParticleTextureDistortion",
        "TN": "AvfxParticleTextureNormal", "TR": "AvfxParticleTextureReflection", "TP": "AvfxParticleTexturePalette",
        "UvSt": "AvfxParticleUvSet",
    ]
    static let dataTypes: [String: (field: String, enumName: String, prefix: String)] = [
        "AvfxEmitter": ("EVT", "EmitterType", "AvfxEmitterData"),
        "AvfxParticle": ("PrVT", "ParticleType", "AvfxParticleData"),
        "AvfxEffector": ("EfVT", "EffectorType", "AvfxEffectorData"),
        "AvfxBinder": ("BnVr", "BinderType", "AvfxBinderData"),
    ]
    static let curveClasses: Set<String> = ["AvfxCurveData", "AvfxCurve2Axis", "AvfxCurve3Axis", "AvfxCurveColor"]
    private static let structTypes: [String: String] = [
        "AvfxCurve1Axis": "AvfxCurveData", "AvfxCurveData": "AvfxCurveData", "AvfxCurve2Axis": "AvfxCurve2Axis",
        "AvfxCurve3Axis": "AvfxCurve3Axis", "AvfxCurveColor": "AvfxCurveColor", "AvfxCurveDissolve": "AvfxCurveDissolve",
        "AvfxLife": "AvfxLife", "AvfxBinderProperties": "AvfxBinderProperties",
    ]
    private static let colorTags: Set<String> = ["Col", "ColB", "ColE", "ColC", "CoEB", "CoEC", "CoEE", "CEI", "CEO", "StrC", "MidC", "EndC"]

    func classOf(_ block: AvfxBlock, in parent: String?, parentBlock: AvfxBlock?) -> String? {
        if block.tag == "AVFX" && parentBlock == nil { return "AvfxMain" }
        if parent == "AvfxMain" { return AvfxCatalog.top[block.tag] }
        if let parent, let cls = AvfxCatalog.lists[parent]?[block.tag] { return cls }
        if parent == "AvfxParticle", let cls = AvfxCatalog.particleParts[block.tag] { return cls }
        if block.tag == "Data", let parent, let info = AvfxCatalog.dataTypes[parent], let parentBlock {
            let value = parentBlock.int(info.field)
            guard let name = enumCaseName(info.enumName, value)?.replacingOccurrences(of: "_Variable", with: "") else { return nil }
            let cls = info.prefix + name
            return classes[cls] != nil ? cls : nil
        }
        if block.tag == "Life" { return "AvfxLife" }
        if let def = field(parent, block.tag), let cls = AvfxCatalog.structTypes[def.baseType] { return cls }
        if block.child("RGB") != nil || (AvfxCatalog.colorTags.contains(block.tag) && block.children != nil) { return "AvfxCurveColor" }
        if parent == "AvfxCurve2Axis" || parent == "AvfxCurve3Axis" || parent == "AvfxCurveColor" || block.child("Keys") != nil
            || block.child("KeyC") != nil {
            return "AvfxCurveData"
        }
        if block.child("X") != nil || block.child("Y") != nil || block.child("Z") != nil || block.child("ACT") != nil {
            return "AvfxCurve3Axis"
        }
        return nil
    }
}
