import Foundation

enum GameFileKind: String {
    case tmb, pap, eid, scd, atch, phyb, skp, imc, kdb, other
}

struct TmbItem: Identifiable {
    let id: Int
    let offset: Int
    let magic: String
    let size: Int
    let itemID: Int
    let time: Int
}

struct TmbBlock: Identifiable {
    let id: Int
    let offset: Int
    let size: Int
    let items: [TmbItem]
}

struct EidPoint: Identifiable, Equatable {
    let id: Int
    var bone: String
    var pointID: Int
    var position: SIMD3<Float>
    var rotation: SIMD3<Float>
}

struct PapAnimation: Identifiable {
    let id: Int
    let name: String
    let type: Int
    let havokIndex: Int
    let face: Bool
}

struct ScdAudio: Identifiable {
    let id: Int
    let offset: Int
    let dataLength: Int
    let channels: Int
    let sampleRate: Int
    let format: Int
    let loopStart: Int
    let loopEnd: Int
    let headerSize: Int

    var formatName: String {
        switch format {
        case 0x01: return "PCM"
        case 0x06: return "Vorbis"
        case 0x0C: return "MS ADPCM"
        case 0x1A: return "HCA"
        case -1: return "Empty"
        default: return String(format: "0x%02X", format)
        }
    }
}

enum GameFiles {
    static let tmbNames: [String: String] = [
        "TMDH": "Header", "TMPP": "Face Library", "TMAL": "Actor List", "TMAC": "Actor", "TMTR": "Track", "TMFC": "F-Curve", "C002": "Timeline Call",
        "C006": "Animation Lock", "C009": "Animation (PAP)", "C010": "Animation", "C011": "Motion Line", "C012": "VFX", "C013": "Camera Shake",
        "C014": "Weapon Position", "C015": "Weapon Size", "C031": "Summon Animation", "C033": "Enable Trails", "C034": "Trail", "C042": "Footstep",
        "C043": "Weapon Visibility", "C053": "Voice Line", "C063": "Sound", "C067": "Flinch", "C075": "Terrain VFX", "C083": "Hide Weapon",
        "C093": "Fade", "C094": "Invisibility", "C107": "Blend", "C117": "Lemure Visibility", "C120": "Summon Weapon", "C124": "Lemure Animation",
        "C125": "Animation Cancelled by Movement", "C131": "Start Positioning", "C144": "Aetherflow Stacks", "C173": "VFX (new)", "C174": "Furniture Animation",
        "C175": "Flying Text", "C197": "Voice Line (new)", "C198": "Stance Lock", "C202": "Model Colour", "C203": "Actor Scaling", "C204": "Clear Scaling",
        "C211": "VFX Trigger",
    ]

    static func kind(of url: URL, bytes: [UInt8]) -> GameFileKind {
        switch url.pathExtension.lowercased() {
        case "tmb": return .tmb
        case "pap": return .pap
        case "eid": return .eid
        case "scd": return .scd
        case "atch": return .atch
        case "phyb": return .phyb
        case "skp": return .skp
        case "imc": return .imc
        case "kdb": return .kdb
        default:
            if bytes.count >= 4, bytes[0] == 0x54, bytes[1] == 0x4D, bytes[2] == 0x4C, bytes[3] == 0x42 { return .tmb }
            return .other
        }
    }

    static func i16(_ b: [UInt8], _ at: Int) -> Int { at + 2 <= b.count ? Int(Int16(bitPattern: b.u16(at))) : 0 }
    static func i32(_ b: [UInt8], _ at: Int) -> Int { at + 4 <= b.count ? Int(Int32(bitPattern: b.u32(at))) : 0 }
    static func f32(_ b: [UInt8], _ at: Int) -> Float { at + 4 <= b.count ? Float(bitPattern: b.u32(at)) : 0 }

    static func put32(_ b: inout [UInt8], _ at: Int, _ value: UInt32) {
        guard at + 4 <= b.count else { return }
        b[at] = UInt8(value & 0xFF)
        b[at + 1] = UInt8(value >> 8 & 0xFF)
        b[at + 2] = UInt8(value >> 16 & 0xFF)
        b[at + 3] = UInt8(value >> 24)
    }

    static func put16(_ b: inout [UInt8], _ at: Int, _ value: Int) {
        guard at + 2 <= b.count else { return }
        let raw = UInt16(bitPattern: Int16(truncatingIfNeeded: value))
        b[at] = UInt8(raw & 0xFF)
        b[at + 1] = UInt8(raw >> 8)
    }

    static func stringBytes(_ b: [UInt8], _ at: Int, max: Int = 512) -> Int {
        guard at >= 0, at < b.count else { return 0 }
        var end = at
        while end < b.count, end - at < max, b[end] != 0 { end += 1 }
        return end - at
    }

    static func string(_ b: [UInt8], _ at: Int, max: Int = 512) -> String {
        guard at >= 0, at < b.count else { return "" }
        var end = at
        while end < b.count, end - at < max, b[end] != 0 { end += 1 }
        return String(decoding: b[at..<end], as: UTF8.self)
    }

    static func tmbBlock(_ b: [UInt8], at start: Int, id: Int) -> TmbBlock? {
        guard start + 12 <= b.count, b[start] == 0x54, b[start + 1] == 0x4D, b[start + 2] == 0x4C, b[start + 3] == 0x42 else { return nil }
        let size = i32(b, start + 4), count = i32(b, start + 8)
        guard size >= 12, start + size <= b.count, count >= 0, count < 100_000 else { return nil }
        var items: [TmbItem] = []
        var at = start + 12
        for index in 0..<count {
            guard at + 8 <= start + size else { break }
            let magic = String(decoding: b[at..<at + 4], as: UTF8.self)
            let length = i32(b, at + 4)
            guard length >= 8, at + length <= start + size else { break }
            let hasID = magic != "TMAL" && magic != "TMPP" && length >= 12
            let hasTime = hasID && magic != "TMDH"
            items.append(TmbItem(id: index, offset: at, magic: magic, size: length, itemID: hasID ? i16(b, at + 8) : -1, time: hasTime ? i16(b, at + 10) : 0))
            at += length
        }
        return TmbBlock(id: id, offset: start, size: size, items: items)
    }

    static func tmbBlocks(_ b: [UInt8]) -> [TmbBlock] {
        var result: [TmbBlock] = []
        var at = 0
        while at + 12 <= b.count {
            if b[at] == 0x54, b[at + 1] == 0x4D, b[at + 2] == 0x4C, b[at + 3] == 0x42, let block = tmbBlock(b, at: at, id: result.count) {
                result.append(block)
                at += max(block.size, 4)
            } else {
                at += 1
            }
        }
        return result
    }

    static func offsetString(_ b: [UInt8], item: TmbItem, field: Int) -> (text: String, at: Int)? {
        let offset = i32(b, item.offset + field)
        guard offset > 0 else { return nil }
        let at = item.offset + 8 + offset
        guard at < b.count else { return nil }
        return (string(b, at), at)
    }

    static func setString(_ b: inout [UInt8], at: Int, old: String, new: String) -> Bool {
        let fresh = Array(new.utf8), limit = old.utf8.count
        guard fresh.count <= limit, at + limit <= b.count else { return false }
        for i in 0..<limit { b[at + i] = i < fresh.count ? fresh[i] : 0 }
        return true
    }

    static func eidPoints(_ b: [UInt8]) -> (points: [EidPoint], new: Bool)? {
        guard b.count >= 16, b[0] == 0x64, b[1] == 0x69, b[2] == 0x65 else { return nil }
        let new = b.u16(4) == 0x3132
        let count = i32(b, 8)
        let size = new ? 64 : 44
        guard count >= 0, 16 + count * size <= b.count else { return nil }
        var points: [EidPoint] = []
        for index in 0..<count {
            let at = 16 + index * size
            if new {
                points.append(EidPoint(id: index, bone: string(b, at, max: 32), pointID: i32(b, at + 32),
                                       position: SIMD3(f32(b, at + 36), f32(b, at + 40), f32(b, at + 44)),
                                       rotation: SIMD3(f32(b, at + 48), f32(b, at + 52), f32(b, at + 56)) * (180 / .pi)))
            } else {
                points.append(EidPoint(id: index, bone: string(b, at + 28, max: 12), pointID: i32(b, at),
                                       position: SIMD3(f32(b, at + 4), f32(b, at + 8), f32(b, at + 12)),
                                       rotation: SIMD3(f32(b, at + 16), f32(b, at + 20), f32(b, at + 24))))
            }
        }
        return (points, new)
    }

    static func eidBytes(_ points: [EidPoint], new: Bool, header: [UInt8]) -> [UInt8] {
        var out = Array(header.prefix(16))
        while out.count < 16 { out.append(0) }
        put32(&out, 8, UInt32(points.count))
        let size = new ? 64 : 44
        let before = eidPoints(header)?.points ?? []
        for point in points {
            if point.id >= 0, point.id < before.count, before[point.id] == point, 16 + (point.id + 1) * size <= header.count {
                out.append(contentsOf: header[(16 + point.id * size)..<(16 + (point.id + 1) * size)])
                continue
            }
            var name = Array(point.bone.utf8.prefix(new ? 31 : 11))
            while name.count < (new ? 32 : 12) { name.append(0) }
            let rotation = new ? point.rotation * (.pi / 180) : point.rotation
            if new { out.append(contentsOf: name) }
            out.appendU32(UInt32(bitPattern: Int32(truncatingIfNeeded: point.pointID)))
            for value in [point.position.x, point.position.y, point.position.z, rotation.x, rotation.y, rotation.z] { out.appendU32(value.bitPattern) }
            if !new { out.append(contentsOf: name) }
            out.appendU32(0)
        }
        return out
    }

    static func papAnimations(_ b: [UInt8]) -> [PapAnimation] {
        guard b.count >= 0x1A, b[0] == 0x70, b[1] == 0x61, b[2] == 0x70 else { return [] }
        let count = i16(b, 8), havok = i32(b, 0x12)
        guard count > 0, count < 4096, havok > 0x1A, havok <= b.count else { return [] }
        let size = (havok - 0x1A) / count
        guard size >= 36 else { return [] }
        return (0..<count).map { index in
            let at = 0x1A + index * size
            return PapAnimation(id: index, name: string(b, at, max: 32), type: i16(b, at + 32), havokIndex: i16(b, at + 34), face: at + 36 < b.count && b[at + 36] != 0)
        }
    }

    static func papAnimationOffset(_ b: [UInt8], index: Int) -> Int? {
        guard b.count >= 0x1A, b[0] == 0x70, b[1] == 0x61, b[2] == 0x70 else { return nil }
        let count = i16(b, 8), havok = i32(b, 0x12)
        guard count > 0, index >= 0, index < count, havok > 0x1A, havok <= b.count else { return nil }
        let size = (havok - 0x1A) / count
        guard size >= 37 else { return nil }
        return 0x1A + index * size
    }

    static func scdAudio(_ b: [UInt8]) -> [ScdAudio] {
        guard b.count >= 0x50, string(b, 0, max: 8) == "SEDBSSCF" else { return [] }
        let header = i16(b, 0x0E)
        guard header > 0, header + 0x20 <= b.count else { return [] }
        let soundCount = i16(b, header), trackCount = i16(b, header + 2), audioCount = i16(b, header + 4)
        guard soundCount >= 0, trackCount >= 0, audioCount >= 0, audioCount < 4096 else { return [] }
        func padded(_ count: Int) -> Int { (count * 4 + 15) / 16 * 16 }
        let table = header + 0x20 + padded(soundCount) + padded(trackCount)
        var result: [ScdAudio] = []
        for index in 0..<audioCount {
            let offset = i32(b, table + index * 4)
            guard offset > 0, offset + 0x20 <= b.count else { continue }
            result.append(ScdAudio(id: index, offset: offset, dataLength: i32(b, offset), channels: i32(b, offset + 4), sampleRate: i32(b, offset + 8),
                                   format: i32(b, offset + 12), loopStart: i32(b, offset + 16), loopEnd: i32(b, offset + 20), headerSize: i32(b, offset + 24)))
        }
        return result
    }

    static func scdStream(_ b: [UInt8], _ audio: ScdAudio) -> [UInt8] {
        let start = audio.offset + 0x20 + audio.headerSize
        guard audio.dataLength > 0, start >= 0, start + audio.dataLength <= b.count else { return [] }
        return Array(b[start..<start + audio.dataLength])
    }

    static func scdWave(_ b: [UInt8], _ audio: ScdAudio) -> [UInt8]? {
        let data = scdStream(b, audio)
        guard !data.isEmpty else { return nil }
        var format: [UInt8] = []
        if audio.format == 0x0C {
            let aux = scdAux(b, audio)
            let at = audio.offset + 0x20 + aux
            guard audio.headerSize - aux >= 16, at + audio.headerSize - aux <= b.count else { return nil }
            format = Array(b[at..<at + audio.headerSize - aux])
        } else if audio.format == 0x01 {
            let channels = min(max(audio.channels, 1), 8), rate = min(max(audio.sampleRate, 1), 384_000)
            format.append(contentsOf: [1, 0, UInt8(channels), 0])
            format.appendU32(UInt32(rate))
            format.appendU32(UInt32(rate * channels * 2))
            format.append(contentsOf: [UInt8(channels * 2), 0, 16, 0])
        } else {
            return nil
        }
        var out = Array("RIFF".utf8)
        out.appendU32(UInt32(4 + 8 + format.count + 8 + data.count))
        out.append(contentsOf: Array("WAVEfmt ".utf8))
        out.appendU32(UInt32(format.count))
        out.append(contentsOf: format)
        out.append(contentsOf: Array("data".utf8))
        out.appendU32(UInt32(data.count))
        out.append(contentsOf: data)
        return out
    }

    static func strings(_ b: [UInt8], minimum: Int = 5, limit: Int = 600) -> [(offset: Int, text: String)] {
        var result: [(Int, String)] = []
        var start = -1
        for (index, byte) in b.enumerated() {
            if byte >= 0x20, byte < 0x7F {
                if start < 0 { start = index }
            } else {
                if start >= 0, index - start >= minimum { result.append((start, String(decoding: b[start..<index], as: UTF8.self))) }
                start = -1
                if result.count >= limit { break }
            }
        }
        return result
    }

    static func mtrlSummary(_ b: [UInt8]) -> (shader: String, textures: [String], uvSets: [String], colorSets: [String])? {
        guard b.count >= 16 else { return nil }
        let tableSize = Int(b.u16(8)), shader = Int(b.u16(10))
        let textures = Int(b[12]), uvSets = Int(b[13]), colorSets = Int(b[14])
        let table = 16 + (textures + uvSets + colorSets) * 4
        guard table + tableSize <= b.count, tableSize > 0 else { return nil }
        func name(_ slot: Int) -> String { string(b, table + Int(b.u16(16 + slot * 4)), max: 260) }
        return (string(b, table + shader, max: 64), (0..<textures).map(name), (textures..<(textures + uvSets)).map(name),
                ((textures + uvSets)..<(textures + uvSets + colorSets)).map(name))
    }

    static func mtrlStringOffset(_ b: [UInt8], slot: Int) -> Int? {
        guard b.count >= 16 else { return nil }
        let count = Int(b[12]) + Int(b[13]) + Int(b[14])
        let table = 16 + count * 4
        if slot < 0 { return table + Int(b.u16(10)) }
        guard slot < count else { return nil }
        return table + Int(b.u16(16 + slot * 4))
    }

    static func mdlSummary(_ b: [UInt8]) -> [(label: String, value: String)]? {
        guard b.count >= 0x48 else { return nil }
        let declarations = Int(b.u16(12)), materials = Int(b.u16(14))
        let stringsAt = 0x44 + declarations * 136
        guard stringsAt + 8 <= b.count else { return nil }
        let stringCount = Int(b.u16(stringsAt)), stringSize = Int(b.u32(stringsAt + 4))
        guard stringsAt + 8 + stringSize <= b.count else { return nil }
        var names: [String] = []
        var at = stringsAt + 8
        let end = at + stringSize
        while at < end, names.count < stringCount {
            let text = string(b, at, max: 260)
            names.append(text)
            at += stringBytes(b, at, max: 260) + 1
        }
        let paths = names.filter { $0.contains("/") }, bones = names.filter { $0.hasPrefix("j_") || $0.hasPrefix("n_") }
        return [("Version", String(format: "0x%08X", b.u32(0))), ("Vertex Declarations", "\(declarations)"), ("Materials", "\(materials)"), ("LODs", "\(b[0x40])"),
                ("Names", "\(names.count)"), ("Bones", "\(bones.count)"), ("Material Paths", paths.joined(separator: "\n"))]
    }

    static func papReplacing(_ file: [UInt8], block: TmbBlock, with fresh: [UInt8]) -> [UInt8]? {
        guard file.count >= 0x1A, file[0] == 0x70, file[1] == 0x61, file[2] == 0x70 else { return nil }
        let footer = i32(file, 0x16)
        guard footer > 0, footer <= file.count else { return nil }
        let blocks = tmbBlocks(file).filter { $0.offset >= footer }.sorted { $0.offset < $1.offset }
        guard !blocks.isEmpty, blocks[0].offset == footer else { return nil }
        let remainder = footer % 4
        var out = Array(file[..<footer])
        var cursor = footer
        for (index, item) in blocks.enumerated() {
            guard item.offset == cursor else { return nil }
            out.append(contentsOf: item.offset == block.offset ? fresh : Array(file[item.offset..<(item.offset + item.size)]))
            cursor = item.offset + item.size
            if index < blocks.count - 1 {
                let over = (cursor - remainder) % 4
                if over != 0 { cursor += 4 - over }
                let overOut = (out.count - remainder) % 4
                if overOut != 0 { out.append(contentsOf: [UInt8](repeating: 0, count: 4 - overOut)) }
            }
        }
        if cursor < file.count { out.append(contentsOf: file[cursor...]) }
        return out
    }
}
