import Foundation

struct TmbFieldDef: Decodable {
    let at: Int
    let size: Int
    let type: String
    let name: String
    let cases: [[TmbCase]]?
    let value: Double?
    let text: String?

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
        if block.offset != 0 || block.size != b.count {
            guard GameFiles.papReplacing(b, block: block, with: Array(b[block.offset..<(block.offset + block.size)])) == b else {
                return "The timelines in this file are laid out in a way this app cannot rebuild"
            }
        }
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

    static func restructure(_ file: [UInt8], block: TmbBlock, _ change: ([UInt8], TmbBlock) -> [UInt8]?) -> [UInt8]? {
        guard canRestructure(file, block) == nil else { return nil }
        let slice = Array(file[block.offset..<(block.offset + block.size)])
        guard let local = GameFiles.tmbBlock(slice, at: 0, id: block.id), let changed = change(slice, local) else { return nil }
        if block.offset == 0, block.size == file.count { return changed }
        return GameFiles.papReplacing(file, block: block, with: changed)
    }

    static func remove(_ file: [UInt8], block: TmbBlock, index: Int) -> [UInt8]? {
        restructure(file, block: block) { bytes, local in index < local.items.count ? removeLocal(bytes, block: local, entry: local.items[index]) : nil }
    }

    static func duplicate(_ file: [UInt8], block: TmbBlock, index: Int) -> [UInt8]? {
        restructure(file, block: block) { bytes, local in index < local.items.count ? duplicateLocal(bytes, block: local, entry: local.items[index]) : nil }
    }

    static func create(_ file: [UInt8], block: TmbBlock, magic: String, track: Int) -> [UInt8]? {
        restructure(file, block: block) { bytes, local in track < local.items.count ? createLocal(bytes, block: local, magic: magic, track: local.items[track]) : nil }
    }

    static func createContainer(_ file: [UInt8], block: TmbBlock, parent: Int) -> [UInt8]? {
        restructure(file, block: block) { bytes, local in parent < local.items.count ? containerLocal(bytes, block: local, parent: local.items[parent]) : nil }
    }

    static func childKind(_ magic: String) -> String? {
        switch magic {
        case "TMAL": return "TMAC"
        case "TMAC": return "TMTR"
        default: return nil
        }
    }

    static func isEmptyContainer(_ b: [UInt8], _ item: TmbItem) -> Bool {
        guard item.magic == "TMAC" || item.magic == "TMTR", let field = listField(item.magic) else { return false }
        return idList(b, item: item, field: field).ids.isEmpty
    }

    private static func containerLocal(_ b: [UInt8], block: TmbBlock, parent: TmbItem) -> [UInt8]? {
        guard let kind = childKind(parent.magic), let type = types[kind], let listAt = listField(parent.magic) else { return nil }
        let anchor = block.items.last { $0.magic == kind } ?? block.items.last { $0.magic == parent.magic || $0.magic == "TMAL" }
        guard let anchor else { return nil }
        let fresh = (block.items.map(\.itemID).max() ?? 0) + 1
        var item = [UInt8](repeating: 0, count: type.size)
        for (slot, byte) in Array(kind.utf8).enumerated() { item[slot] = byte }
        GameFiles.put32(&item, 4, UInt32(type.size))
        GameFiles.put16(&item, 8, fresh)
        var out = b
        let position = anchor.offset + anchor.size
        shiftPointers(&out, items: block.items, before: position, by: type.size)
        out.insert(contentsOf: item, at: position)
        let parentStart = parent.offset < position ? parent.offset : parent.offset + type.size
        var ids = idList(out, item: TmbItem(id: parent.id, offset: parentStart, magic: parent.magic, size: parent.size, itemID: parent.itemID, time: parent.time), field: listAt).ids
        ids.append(fresh)
        appendList(&out, ids: ids, trackStart: parentStart, listAt: listAt)
        GameFiles.put32(&out, 4, UInt32(out.count))
        GameFiles.put32(&out, 8, UInt32(block.items.count + 1))
        return out
    }

    static func setString(_ file: [UInt8], block: TmbBlock, index: Int, field: Int, text: String) -> [UInt8]? {
        restructure(file, block: block) { bytes, local in
            guard index < local.items.count else { return nil }
            let item = local.items[index]
            var out = bytes
            let offset = out.count - (item.offset + 8)
            out.append(contentsOf: Array(text.utf8) + [0])
            while out.count % 4 != 0 { out.append(0) }
            GameFiles.put32(&out, item.offset + field, UInt32(offset))
            GameFiles.put32(&out, 4, UInt32(out.count))
            return out
        }
    }

    static var entryTypes: [(magic: String, name: String)] {
        types.filter { $0.key.hasPrefix("C") }.map { ($0.key, $0.value.name) }.sorted { $0.magic < $1.magic }
    }

    private static func appendList(_ out: inout [UInt8], ids: [Int], trackStart: Int, listAt: Int) {
        let listPosition = out.count
        for id in ids {
            out.append(UInt8(id & 0xFF))
            out.append(UInt8(id >> 8 & 0xFF))
        }
        while out.count % 4 != 0 { out.append(0) }
        GameFiles.put32(&out, trackStart + listAt, UInt32(listPosition - (trackStart + 8)))
        GameFiles.put32(&out, trackStart + listAt + 4, UInt32(ids.count))
    }

    private static func createLocal(_ b: [UInt8], block: TmbBlock, magic: String, track: TmbItem) -> [UInt8]? {
        guard let type = types[magic], magic.hasPrefix("C"), track.magic == "TMTR", let listAt = listField("TMTR"), let last = block.items.last else { return nil }
        let fresh = (block.items.map(\.itemID).max() ?? 0) + 1
        var item = [UInt8](repeating: 0, count: type.size)
        for (slot, byte) in Array(magic.utf8).prefix(4).enumerated() { item[slot] = byte }
        GameFiles.put32(&item, 4, UInt32(type.size))
        GameFiles.put16(&item, 8, fresh)
        for field in type.fields where !field.isPointer {
            guard let value = field.value else { continue }
            switch (field.type, field.size) {
            case ("Float", _): GameFiles.put32(&item, field.at, Float(value).bitPattern)
            case (_, 1): item[field.at] = UInt8(bitPattern: Int8(truncatingIfNeeded: Int(value)))
            case (_, 2): GameFiles.put16(&item, field.at, Int(value))
            default: GameFiles.put32(&item, field.at, UInt32(bitPattern: Int32(truncatingIfNeeded: Int(value))))
            }
        }
        var out = b
        let position = last.offset + last.size
        shiftPointers(&out, items: block.items, before: position, by: type.size)
        out.insert(contentsOf: item, at: position)
        for field in type.fields where field.isPointer {
            let target = out.count - (position + 8)
            switch field.type {
            case "OffsetString":
                let text = field.text ?? (magic == "C012" && field.name == "Path" ? "vfx/replace_me.avfx" : "")
                out.append(contentsOf: Array(text.utf8) + [0])
                while out.count % 4 != 0 { out.append(0) }
                GameFiles.put32(&out, position + field.at, UInt32(target))
            case "OffsetFloat3", "OffsetAngle3", "OffsetFloat4":
                let count = field.type == "OffsetFloat4" ? 4 : 3
                for _ in 0..<count { out.appendU32(Float(field.value ?? 0).bitPattern) }
                GameFiles.put32(&out, position + field.at, UInt32(target))
                GameFiles.put32(&out, position + field.at + 4, UInt32(count))
            default: break
            }
        }
        let trackStart = track.offset < position ? track.offset : track.offset + type.size
        var ids = idList(out, item: TmbItem(id: track.id, offset: trackStart, magic: "TMTR", size: track.size, itemID: track.itemID, time: track.time), field: listAt).ids
        ids.append(fresh)
        appendList(&out, ids: ids, trackStart: trackStart, listAt: listAt)
        GameFiles.put32(&out, 4, UInt32(out.count))
        GameFiles.put32(&out, 8, UInt32(block.items.count + 1))
        return out
    }

    private static func removeLocal(_ b: [UInt8], block: TmbBlock, entry: TmbItem) -> [UInt8]? {
        guard entry.magic.hasPrefix("C") || isEmptyContainer(b, entry) else { return nil }
        var out = b
        for item in block.items {
            guard let field = listField(item.magic) else { continue }
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

    private static func duplicateLocal(_ b: [UInt8], block: TmbBlock, entry: TmbItem) -> [UInt8]? {
        guard entry.magic.hasPrefix("C"), let listAt = listField("TMTR") else { return nil }
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
