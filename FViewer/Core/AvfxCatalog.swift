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
    private var defaultValues: [String: [String: Double]] = [:]
    private var fieldSizes: [String: [String: Int]] = [:]
    private var optionalData: Set<String> = []
    private var angleFields: [String: Set<String>] = [:]

    func isAngle(_ cls: String?, _ tag: String) -> Bool { cls.map { angleFields[$0]?.contains(tag) ?? false } ?? false }

    func defaultValue(_ cls: String, _ tag: String) -> Double { defaultValues[cls]?[tag] ?? 0 }
    func fieldSize(_ cls: String, _ tag: String) -> Int { fieldSizes[cls]?[tag] ?? 4 }
    func isOptionalData(_ cls: String) -> Bool { optionalData.contains(cls) }

    func freshLeaf(_ field: AvfxField, in cls: String) -> AvfxBlock? {
        let value = defaultValue(cls, field.tag)
        switch field.baseType {
        case "AvfxBool":
            var bytes = [UInt8](repeating: 0, count: max(fieldSize(cls, field.tag), 1))
            bytes[0] = value != 0 ? 1 : 0
            return AvfxBlock(tag: field.tag, data: bytes)
        case "AvfxInt", "AvfxEnum", "AvfxFlag":
            let size = fieldSize(cls, field.tag)
            if size == 1 { return AvfxBlock(tag: field.tag, data: [UInt8(truncatingIfNeeded: Int(value))]) }
            return AvfxBlock.leaf(field.tag, int: Int(value))
        case "AvfxFloat", "AvfxRadians": return AvfxBlock.leaf(field.tag, float: Float(value))
        case "AvfxIntList": return AvfxBlock(tag: field.tag, data: [value < 0 ? 255 : UInt8(truncatingIfNeeded: Int(value))])
        default: return nil
        }
    }

    static func freshCurve(_ tag: String, color: Bool = false) -> AvfxBlock {
        var children = [AvfxBlock.leaf("KeyC", int: 0), AvfxBlock.leaf("BvPr", int: 0), AvfxBlock.leaf("BvPo", int: 0)]
        if !color { children.append(AvfxBlock.leaf("RanT", int: 0)) }
        children.append(AvfxBlock(tag: "Keys", data: []))
        return AvfxBlock(tag: tag, children: children)
    }

    func freshBlock(_ field: AvfxField, in cls: String) -> AvfxBlock? {
        switch field.baseType {
        case "AvfxCurve1Axis", "AvfxCurveData": return AvfxCatalog.freshCurve(field.tag)
        case "AvfxCurve2Axis", "AvfxCurve3Axis":
            let axes = field.baseType == "AvfxCurve2Axis" ? ["X", "Y", "RX", "RY"] : ["X", "Y", "Z", "RX", "RY", "RZ"]
            return AvfxBlock(tag: field.tag, children: [AvfxBlock.leaf("ACT", int: 0), AvfxBlock.leaf("ACTR", int: 0)] + axes.map { AvfxCatalog.freshCurve($0) })
        case "AvfxCurveColor":
            let parts = (classes["AvfxCurveColor"] ?? []).map { AvfxCatalog.freshCurve($0.tag, color: $0.tag == "RGB") }
            return AvfxBlock(tag: field.tag, children: parts)
        default:
            if let leaf = freshLeaf(field, in: cls) { return leaf }
            guard let fields = classes[field.baseType], field.baseType != cls else { return nil }
            return AvfxBlock(tag: field.tag, children: fields.compactMap { freshBlock($0, in: field.baseType) })
        }
    }

    func freshData(_ cls: String) -> AvfxBlock? {
        guard let fields = classes[cls] else { return nil }
        return AvfxBlock(tag: "Data", children: fields.compactMap { freshBlock($0, in: cls) })
    }

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
        if let url = Bundle.main.url(forResource: "AvfxDefaults", withExtension: "json"), let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (cls, values) in json["defaults"] as? [String: [String: NSNumber]] ?? [:] { defaultValues[cls] = values.mapValues(\.doubleValue) }
            for (cls, values) in json["sizes"] as? [String: [String: NSNumber]] ?? [:] { fieldSizes[cls] = values.mapValues(\.intValue) }
            optionalData = Set(json["optional"] as? [String] ?? [])
            for (cls, tags) in json["angles"] as? [String: [String]] ?? [:] { angleFields[cls] = Set(tags) }
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
    static let particleParts: [String: String] = [
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
