import Foundation

struct TmbFieldDef: Decodable {
    let at: Int
    let size: Int
    let type: String
    let name: String
    let cases: [[TmbCase]]?

    struct TmbCase: Decodable {
        let text: String?
        let number: Int?

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            text = try? c.decode(String.self)
            number = try? c.decode(Int.self)
        }
    }

    var isPointer: Bool { type.hasPrefix("Offset") }
    var choices: [FieldChoice] {
        (cases ?? []).compactMap { pair in
            guard pair.count == 2, let name = pair[0].text, let value = pair[1].number else { return nil }
            return FieldChoice(name: name, value: value)
        }
    }
}

struct TmbTypeDef: Decodable {
    let name: String
    let size: Int
    let fields: [TmbFieldDef]
}

enum TmbCatalog {
    static let types: [String: TmbTypeDef] = {
        guard let url = Bundle.main.url(forResource: "TmbCatalog", withExtension: "json"), let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: TmbTypeDef].self, from: data) else { return [:] }
        return decoded
    }()

    static func name(_ magic: String) -> String { types[magic]?.name ?? GameFiles.tmbNames[magic] ?? "" }

    static func pointers(_ item: TmbItem) -> [Int]? {
        guard let type = types[item.magic], type.size == item.size else { return nil }
        return type.fields.filter(\.isPointer).map(\.at)
    }

    static func idList(_ b: [UInt8], item: TmbItem, field: Int) -> (ids: [Int], at: Int) {
        let offset = GameFiles.i32(b, item.offset + field), count = GameFiles.i32(b, item.offset + field + 4)
        guard offset > 0, count >= 0, count < 4096 else { return ([], 0) }
        let at = item.offset + 8 + offset
        guard at + count * 2 <= b.count else { return ([], 0) }
        return ((0..<count).map { GameFiles.i16(b, at + $0 * 2) }, at)
    }

    static func listField(_ magic: String) -> Int? { types[magic]?.fields.first { $0.type == "OffsetTimeline" }?.at }

    static func canRestructure(_ b: [UInt8], _ block: TmbBlock) -> String? {
        guard block.offset == 0, block.size == b.count else { return "Entries can only be added or removed in a standalone .tmb file" }
        for item in block.items where pointers(item) == nil { return "\(item.magic) has a layout this app does not know, so the file cannot be restructured" }
        return nil
    }

    private static func shiftPointers(_ b: inout [UInt8], items: [TmbItem], before limit: Int, by delta: Int) {
        for item in items where item.offset < limit {
            for field in pointers(item) ?? [] {
                let value = GameFiles.i32(b, item.offset + field)
                if value != 0 { GameFiles.put32(&b, item.offset + field, UInt32(bitPattern: Int32(truncatingIfNeeded: value + delta))) }
            }
        }
    }

    static func remove(_ b: [UInt8], block: TmbBlock, entry: TmbItem) -> [UInt8]? {
        guard canRestructure(b, block) == nil, entry.magic.hasPrefix("C") else { return nil }
        var out = b
        for item in block.items where item.magic == "TMTR" {
            guard let field = listField("TMTR") else { continue }
            let list = idList(out, item: item, field: field)
            guard let index = list.ids.firstIndex(of: entry.itemID) else { continue }
            var ids = list.ids
            ids.remove(at: index)
            for (slot, id) in ids.enumerated() { GameFiles.put16(&out, list.at + slot * 2, id) }
            GameFiles.put16(&out, list.at + ids.count * 2, 0)
            GameFiles.put32(&out, item.offset + field + 4, UInt32(ids.count))
        }
        shiftPointers(&out, items: block.items, before: entry.offset, by: -entry.size)
        out.removeSubrange(entry.offset..<(entry.offset + entry.size))
        GameFiles.put32(&out, 4, UInt32(out.count))
        GameFiles.put32(&out, 8, UInt32(block.items.count - 1))
        return out
    }

    static func duplicate(_ b: [UInt8], block: TmbBlock, entry: TmbItem) -> [UInt8]? {
        guard canRestructure(b, block) == nil, entry.magic.hasPrefix("C"), let listAt = listField("TMTR") else { return nil }
        guard let track = block.items.first(where: { $0.magic == "TMTR" && idList(b, item: $0, field: listAt).ids.contains(entry.itemID) }) else { return nil }
        let fresh = (block.items.map(\.itemID).max() ?? 0) + 1
        var copy = Array(b[entry.offset..<(entry.offset + entry.size)])
        GameFiles.put16(&copy, 8, fresh)
        var ids = idList(b, item: track, field: listAt).ids
        ids.insert(fresh, at: (ids.firstIndex(of: entry.itemID) ?? ids.count - 1) + 1)
        var out = b
        let position = entry.offset + entry.size
        shiftPointers(&out, items: block.items, before: position, by: entry.size)
        out.insert(contentsOf: copy, at: position)
        let trackStart = track.offset < position ? track.offset : track.offset + entry.size
        let listPosition = out.count
        for id in ids {
            out.append(UInt8(id & 0xFF))
            out.append(UInt8(id >> 8 & 0xFF))
        }
        while out.count % 4 != 0 { out.append(0) }
        GameFiles.put32(&out, trackStart + listAt, UInt32(listPosition - (trackStart + 8)))
        GameFiles.put32(&out, trackStart + listAt + 4, UInt32(ids.count))
        GameFiles.put32(&out, 4, UInt32(out.count))
        GameFiles.put32(&out, 8, UInt32(block.items.count + 1))
        return out
    }

    static func problems(_ b: [UInt8]) -> [String] {
        var result: [String] = []
        for block in GameFiles.tmbBlocks(b) {
            let known = Set(block.items.map(\.itemID))
            for item in block.items {
                guard let type = types[item.magic], type.size == item.size else { continue }
                for field in type.fields where field.isPointer {
                    let value = GameFiles.i32(b, item.offset + field.at)
                    if value == 0 { continue }
                    let target = item.offset + 8 + value
                    if target < block.offset + 12 || target > block.offset + block.size { result.append("\(item.magic)#\(item.itemID) \(field.name) points outside") }
                    if field.type == "OffsetTimeline" {
                        for id in idList(b, item: item, field: field.at).ids where !known.contains(id) { result.append("\(item.magic)#\(item.itemID) lists missing id \(id)") }
                    }
                }
            }
        }
        return result
    }
}
