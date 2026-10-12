import Foundation

enum RecordKind {
    case text(length: Int, fill: UInt8)
    case float
    case angle
    case floats(Int)
    case angles(Int)
    case short
    case int
    case byte
    case choice([String])
    case flags([String])
}

struct RecordField: Identifiable {
    let id: Int
    let name: String
    let at: Int
    let kind: RecordKind
}

struct GameRecord: Identifiable {
    let id: Int
    let section: String
    let title: String
    let fields: [RecordField]
    var slot: RecordSlot? = nil
    var skp: SkpSlot? = nil
}

struct RecordBuilder {
    let bytes: [UInt8]
    var records: [GameRecord] = []
    var valid = true

    static func size(_ kind: RecordKind) -> Int {
        switch kind {
        case .text(let length, _): return length
        case .float, .angle, .int, .choice: return 4
        case .floats(let count), .angles(let count): return count * 4
        case .short: return 2
        case .byte, .flags: return 1
        }
    }

    @discardableResult mutating func add(_ section: String, _ title: String, at start: Int, _ layout: [(String, RecordKind)], nameField: Int? = nil,
                                         slot: RecordSlot? = nil, skp: SkpSlot? = nil) -> Int {
        var fields: [RecordField] = []
        var at = start
        for (index, item) in layout.enumerated() {
            let size = RecordBuilder.size(item.1)
            if at < 0 || at + size > bytes.count {
                valid = false
                return at
            }
            if !item.0.isEmpty { fields.append(RecordField(id: index, name: item.0, at: at, kind: item.1)) }
            at += size
        }
        var name = title
        if let nameField, nameField < fields.count, case .text(let length, _) = fields[nameField].kind {
            let text = GameFiles.string(bytes, fields[nameField].at, max: length)
            if !text.isEmpty { name = title + "  " + text }
        }
        records.append(GameRecord(id: records.count, section: section, title: name, fields: fields, slot: slot, skp: skp))
        return at
    }

    func u32(_ at: Int) -> Int { at >= 0 && at + 4 <= bytes.count ? Int(bytes.u32(at)) : -1 }
    func u16(_ at: Int) -> Int { at >= 0 && at + 2 <= bytes.count ? Int(bytes.u16(at)) : -1 }
    func u8(_ at: Int) -> Int { at >= 0 && at < bytes.count ? Int(bytes[at]) : -1 }
}

enum GameRecords {
    private static func name(_ label: String) -> (String, RecordKind) { (label, .text(length: 32, fill: 0xFE)) }
    private static func skip(_ count: Int) -> [(String, RecordKind)] { (0..<count).map { _ in ("", RecordKind.byte) } }

    static func phyb(_ b: [UInt8]) -> [GameRecord]? {
        guard b.count >= 12 else { return nil }
        var builder = RecordBuilder(bytes: b)
        let version = builder.u32(0)
        if version == 0 { return [] }
        guard b.count >= 16 else { return nil }
        let collision = builder.u32(8), simulation = builder.u32(12)
        guard collision >= 16, collision <= simulation, simulation <= b.count else { return nil }
        if collision != simulation {
            let counts = (0..<5).map { builder.u8(collision + $0) }
            var at = collision + 8
            let shapes: [(String, [(String, RecordKind)])] = [
                ("Capsule", [name("Name"), name("Start Bone"), name("End Bone"), ("Start Offset", .floats(3)), ("End Offset", .floats(3)), ("Radius", .float)]),
                ("Ellipsoid", [name("Name"), name("Bone"), ("Bone Offset 1", .floats(3)), ("Bone Offset 2", .floats(3)), ("Bone Offset 3", .floats(3)),
                               ("Bone Offset 4", .floats(3)), ("Radius", .float)]),
                ("Normal Plane", [name("Name"), name("Bone"), ("Bone Offset", .floats(3)), ("Normal", .floats(3)), ("Thickness", .float)]),
                ("Three-Point Plane", [name("Name"), name("Bone"), ("Unknown 1", .floats(4)), ("Unknown 2", .floats(4)), ("Unknown 3", .floats(4)),
                                       ("Unknown 4", .floats(4)), ("Bone Offset", .floats(3)), ("Unknown 5", .floats(3)), ("Unknown 6", .floats(3)), ("Thickness", .float)]),
                ("Sphere", [name("Name"), name("Bone"), ("Bone Offset", .floats(3)), ("Thickness", .float)]),
            ]
            for (index, shape) in shapes.enumerated() {
                for item in 0..<max(0, counts[index]) { at = builder.add("Collision", shape.0, at: at, shape.1, nameField: 0, slot: .shape(kind: index, index: item)) }
            }
            if at > simulation { return nil }
        }
        guard simulation + 4 <= b.count else { return builder.valid ? builder.records : nil }
        let simulators = builder.u32(simulation)
        guard simulators >= 0, simulators <= 64, simulation + 4 + simulators * 72 <= b.count else { return builder.valid ? builder.records : nil }
        let collisionData: [(String, RecordKind)] = [name("Collision Name"), ("Collision Type", .choice(["Both", "Outside", "Inside"]))]
        for index in 0..<simulators {
            let head = simulation + 4 + index * 72
            let section = "Simulator \(index)"
            let counts = (0..<8).map { builder.u8(head + $0) }
            builder.add(section, "Parameters", at: head + 8, [
                ("Gravity", .floats(3)), ("Wind", .floats(3)), ("Constraint Loop", .short), ("Collision Loop", .short),
                ("Flags", .flags(["Simulating", "Collisions Handled", "Continuous Collisions", "Using Ground Plane", "Fixed Length"])), ("Group", .byte),
            ], slot: .parameters(simulator: index))
            func place(_ slot: Int) -> Int {
                let offset = builder.u32(head + 40 + slot * 4)
                return offset == 0xCCCC_CCCC ? simulation + 4 : simulation + offset + 4
            }
            var at = place(0)
            for item in 0..<counts[0] { at = builder.add(section, "Collision Object", at: at, collisionData, nameField: 0, slot: .item(simulator: index, list: 0, index: item)) }
            at = place(1)
            for item in 0..<counts[1] { at = builder.add(section, "Collision Connector", at: at, collisionData, nameField: 0, slot: .item(simulator: index, list: 1, index: item)) }
            at = place(2)
            for chain in 0..<counts[2] {
                let collisions = builder.u16(at), nodes = builder.u16(at + 2)
                let next = builder.add(section, "Chain \(chain)", at: at + 4, [
                    ("Dampening", .float), ("Max Speed", .float), ("Friction", .float), ("Collision Dampening", .float), ("Repulsion Strength", .float),
                    ("Last Bone Offset", .floats(3)), ("Type", .choice(["Sphere", "Capsule"])),
                ], slot: .chain(simulator: index, index: chain))
                guard collisions >= 0, nodes >= 0, collisions < 256, nodes < 1024 else { return nil }
                var inner = simulation + builder.u32(next) + 4
                for item in 0..<collisions { inner = builder.add(section, "Chain \(chain) Collision", at: inner, collisionData, nameField: 0, slot: .chainCollision(simulator: index, chain: chain, index: item)) }
                inner = simulation + builder.u32(next + 4) + 4
                for node in 0..<nodes {
                    inner = builder.add(section, "Chain \(chain) Node \(node)", at: inner, [
                        name("Bone Name"), ("Collision Radius", .float), ("Attract by Animation", .float), ("Wind Scale", .float), ("Gravity Scale", .float),
                        ("Cone Max Angle", .angle), ("Cone Axis Offset", .floats(3)), ("Constraint Plane Normal", .floats(3)), ("Collision Flags", .int),
                        ("Continuous Collision Flags", .int),
                    ], nameField: 0, slot: .node(simulator: index, chain: chain, index: node))
                }
                at = next + 8
            }
            at = place(3)
            for item in 0..<counts[3] {
                at = builder.add(section, "Connector \(item)", at: at, [
                    ("Chain Id 1", .short), ("Chain Id 2", .short), ("Node Id 1", .short), ("Node Id 2", .short), ("Collision Radius", .float), ("Friction", .float),
                    ("Dampening", .float), ("Repulsion", .float), ("Collision Flags", .int), ("Continuous Collision Flags", .int),
                ], slot: .item(simulator: index, list: 3, index: item))
            }
            at = place(4)
            for item in 0..<counts[4] {
                at = builder.add(section, "Attract \(item)", at: at, [name("Bone Name"), ("Bone Offset", .floats(3)), ("Chain Id", .short), ("Node Id", .short),
                                                                       ("Stiffness", .float)], nameField: 0, slot: .item(simulator: index, list: 4, index: item))
            }
            at = place(5)
            for item in 0..<counts[5] {
                at = builder.add(section, "Pin \(item)", at: at, [name("Bone Name"), ("Bone Offset", .floats(3)), ("Chain Id", .short), ("Node Id", .short)], nameField: 0, slot: .item(simulator: index, list: 5, index: item))
            }
            at = place(6)
            for item in 0..<counts[6] {
                at = builder.add(section, "Spring \(item)", at: at, [("Chain Id 1", .short), ("Chain Id 2", .short), ("Node Id 1", .short), ("Node Id 2", .short),
                                                                      ("Stretch Stiffness", .float), ("Compress Stiffness", .float)], slot: .item(simulator: index, list: 6, index: item))
            }
            at = place(7)
            for item in 0..<counts[7] {
                at = builder.add(section, "Post Alignment \(item)", at: at, [name("Collision Name"), ("Chain Id", .short), ("Node Id", .short)], nameField: 0, slot: .item(simulator: index, list: 7, index: item))
            }
        }
        return builder.valid ? builder.records : nil
    }

    static func imc(_ b: [UInt8]) -> [GameRecord]? {
        guard b.count >= 4 else { return nil }
        var builder = RecordBuilder(bytes: b)
        let variants = builder.u16(0), mask = builder.u16(2)
        let parts = max(1, mask.nonzeroBitCount)
        guard 4 + (variants + 1) * parts * 6 <= b.count else { return nil }
        let layout: [(String, RecordKind)] = [("Material Id", .byte), ("Decal Id", .byte), ("Attributes and Sound", .short), ("VFX Id", .byte), ("Material Animation Id", .byte)]
        var at = 4
        for variant in 0...variants {
            for part in 0..<parts {
                let effect = builder.u8(at + 4)
                let title = (parts > 1 ? "Part \(part)" : "Entry") + (effect > 0 ? "  vfx \(effect)" : "")
                at = builder.add(variant == 0 ? "Default" : "Variant \(variant)", title, at: at, layout, slot: .variant(variant))
            }
        }
        return builder.valid ? builder.records : nil
    }

    static func skp(_ b: [UInt8]) -> [GameRecord]? {
        guard b.count >= 0x1C, b[0] == 0x70, b[1] == 0x6C, b[2] == 0x6B, b[3] == 0x73 else { return nil }
        var builder = RecordBuilder(bytes: b)
        let version = Int(String(String(decoding: b[4..<8], as: UTF8.self).reversed())) ?? 0
        builder.add("File", "Activated", at: 8, [("Parts", .flags(["Animation", "Look At", "CCD", "Feet", "Slope"]))])
        let lookAt = builder.u32(16)
        if b[8] & 0x02 != 0, lookAt > 0, lookAt + 2 <= b.count {
            let parameters = builder.u8(lookAt), groups = builder.u8(lookAt + 1)
            let sizes = (0..<groups).map { builder.u8(lookAt + 2 + $0) }
            var at = lookAt + 2 + groups
            for index in 0..<parameters {
                at = builder.add("Look At", "Parameters \(index)", at: at, [
                    ("Limit Angles", .angles(4)), ("Forward Rotation", .floats(3)), ("Limit Angle", .angle), ("Eye Positions", .floats(3)), ("Flags", .int),
                    ("Gain", .float), ("Index", .byte),
                ] + skip(3), skp: .parameter(index))
            }
            for index in 0..<groups {
                let start = at
                at = builder.add("Look At", "Group \(index)", at: at, [("Id", .text(length: 32, fill: 0))] + skip(1), nameField: 0, skp: .group(index))
                let count = builder.u8(start + 32)
                guard count >= 0, count == sizes[index] else { return nil }
                for element in 0..<count {
                    at = builder.add("Look At", "Group \(index) Element \(element)", at: at, [
                        ("Priority", .byte), ("Setup Parameters Index", .byte), ("Bone Name", .text(length: 32, fill: 0)), ("Parent Bone Name", .text(length: 32, fill: 0)),
                    ], nameField: 2, skp: .element(group: index, index: element))
                }
            }
        }
        let slope = version > 1000 ? builder.u32(28) : 0
        if version > 1000, b[8] & 0x10 != 0, slope > 0, slope + 32 <= b.count {
            builder.add("Slope", "Settings", at: slope + 8, [("Unknown 1", .int), ("Unknown 2", .int), ("Center Offset", .floats(3))])
            let points = builder.u32(slope + 28)
            guard points >= 0, points < 4096 else { return nil }
            for index in 0..<points { builder.add("Slope", "Point \(index)", at: slope + 32 + index * 12, [("Position", .floats(3))], skp: .point(index)) }
        }
        return builder.valid ? builder.records : nil
    }
}
