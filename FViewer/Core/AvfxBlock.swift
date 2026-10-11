import Foundation

enum AvfxError: LocalizedError {
    case malformed(String)

    var errorDescription: String? {
        switch self {
        case .malformed(let message): return message
        }
    }
}

final class AvfxBlock: Identifiable {
    let rawTag: [UInt8]
    let tag: String
    var data: [UInt8]
    var children: [AvfxBlock]?
    weak var parent: AvfxBlock?

    static let binaryLeafTags: Set<String> = ["Keys", "Cols", "Frms", "VDrw", "VIdx", "VEmt", "VNum", "Clip"]

    init(rawTag: [UInt8], data: [UInt8] = [], children: [AvfxBlock]? = nil) {
        self.rawTag = rawTag
        self.tag = AvfxBlock.decodeTag(rawTag)
        self.data = data
        self.children = children
        children?.forEach { $0.parent = self }
    }

    convenience init(tag: String, data: [UInt8] = [], children: [AvfxBlock]? = nil) {
        self.init(rawTag: AvfxBlock.encodeTag(tag), data: data, children: children)
    }

    static func decodeTag(_ raw: [UInt8]) -> String {
        String(decoding: raw.reversed().filter { $0 != 0 }, as: UTF8.self)
    }

    static func encodeTag(_ tag: String) -> [UInt8] {
        var out = Array(tag.utf8.prefix(4).reversed())
        while out.count < 4 { out.append(0) }
        return out
    }

    static func parseFile(_ bytes: [UInt8]) throws -> AvfxBlock {
        let top = try parse(bytes, 0, bytes.count)
        guard let root = top.first(where: { $0.tag == "AVFX" }), root.children != nil else {
            throw AvfxError.malformed("The file has no AVFX root block")
        }
        return root
    }

    static func parse(_ buf: [UInt8], _ start: Int, _ end: Int) throws -> [AvfxBlock] {
        var out: [AvfxBlock] = []
        var p = start
        while p + 8 <= end {
            let raw = Array(buf[p..<p + 4])
            let size = Int(buf.u32(p + 4))
            guard p + 8 + size <= end else {
                throw AvfxError.malformed("Block \(decodeTag(raw)) at offset \(p) overruns its parent")
            }
            let tag = decodeTag(raw)
            if !binaryLeafTags.contains(tag), looksLikeBlocks(buf, p + 8, p + 8 + size) {
                out.append(AvfxBlock(rawTag: raw, children: try parse(buf, p + 8, p + 8 + size)))
            } else {
                out.append(AvfxBlock(rawTag: raw, data: Array(buf[p + 8..<p + 8 + size])))
            }
            p += 8 + align4(size)
        }
        return out
    }

    private static func isTagByte(_ b: UInt8) -> Bool {
        b == 0 || b == 0x20 || (b >= 0x30 && b <= 0x39) || (b >= 0x41 && b <= 0x5a) || (b >= 0x61 && b <= 0x7a)
    }

    private static func looksLikeBlocks(_ buf: [UInt8], _ start: Int, _ end: Int) -> Bool {
        if end - start < 8 { return false }
        var p = start
        while p < end {
            if p + 8 > end { return false }
            var letters = 0
            for i in 0..<4 {
                let b = buf[p + i]
                if !isTagByte(b) { return false }
                if b != 0 && b != 0x20 { letters += 1 }
            }
            if letters == 0 { return false }
            let size = Int(buf.u32(p + 4))
            if p + 8 + size > end { return false }
            p = min(p + 8 + align4(size), end)
        }
        return p == end
    }

    static func align4(_ n: Int) -> Int { (n + 3) & ~3 }

    func serialize(into out: inout [UInt8]) {
        out.append(contentsOf: rawTag)
        let sizeAt = out.count
        out.append(contentsOf: [0, 0, 0, 0])
        if let children {
            for child in children { child.serialize(into: &out) }
        } else {
            out.append(contentsOf: data)
        }
        let size = out.count - sizeAt - 4
        out.setU32(sizeAt, UInt32(size))
        while (out.count - sizeAt - 4) % 4 != 0 { out.append(0) }
    }

    func serialized() -> [UInt8] {
        var out: [UInt8] = []
        serialize(into: &out)
        return out
    }

    func deepCopy() -> AvfxBlock {
        AvfxBlock(rawTag: rawTag, data: data, children: children?.map { $0.deepCopy() })
    }

    func child(_ tag: String) -> AvfxBlock? { children?.first { $0.tag == tag } }
    func childrenNamed(_ tag: String) -> [AvfxBlock] { children?.filter { $0.tag == tag } ?? [] }
    var isLeaf: Bool { children == nil }

    func insert(_ block: AvfxBlock, at index: Int) {
        block.parent = self
        var list = children ?? []
        list.insert(block, at: min(index, list.count))
        children = list
    }

    var intValue: Int {
        get {
            if data.count >= 4 { return Int(Int32(bitPattern: data.u32(0))) }
            if data.count >= 2 { return Int(Int16(bitPattern: UInt16(data[0]) | UInt16(data[1]) << 8)) }
            return data.first.map(Int.init) ?? 0
        }
        set {
            if data.count >= 4 {
                data.setU32(0, UInt32(bitPattern: Int32(truncatingIfNeeded: newValue)))
            } else if data.count >= 2 {
                let v = UInt16(bitPattern: Int16(truncatingIfNeeded: newValue))
                data[0] = UInt8(v & 0xff)
                data[1] = UInt8(v >> 8)
            } else if data.count == 1 {
                data[0] = UInt8(truncatingIfNeeded: newValue)
            }
        }
    }

    var floatValue: Float {
        get { data.count >= 4 ? Float(bitPattern: data.u32(0)) : 0 }
        set { if data.count >= 4 { data.setU32(0, newValue.bitPattern) } }
    }

    var stringValue: String {
        get { String(decoding: data.prefix { $0 != 0 }, as: UTF8.self) }
        set { data = Array(newValue.utf8) + [0] }
    }

    func int(_ tag: String, _ fallback: Int = 0) -> Int { child(tag)?.intValue ?? fallback }
    func float(_ tag: String, _ fallback: Float = 0) -> Float { child(tag)?.floatValue ?? fallback }

    static let cumulativeTags: [String: [String]] = [
        "Schd": ["Item", "Trgr"], "TmLn": ["Item"], "Emit": ["ItPr", "ItEm"],
    ]

    func records() -> [[AvfxBlock]] {
        guard let children, let first = children.first?.tag else { return [] }
        var out: [[AvfxBlock]] = []
        for child in children {
            if child.tag == first || out.isEmpty { out.append([]) }
            out[out.count - 1].append(child)
        }
        return out
    }

    static let cumulativePrefixSource: [String: String] = ["Trgr": "Item", "ItEm": "ItPr"]

    func syncCumulativeLists() {
        guard let children else { return }
        for (dependent, source) in AvfxBlock.cumulativePrefixSource {
            guard let target = children.last(where: { $0.tag == dependent && $0.children != nil }),
                  let origin = children.last(where: { $0.tag == source && $0.children != nil }) else { continue }
            let prefix = origin.records()
            let own = target.records()
            guard own.count >= prefix.count else { continue }
            let merged = (prefix.flatMap { $0 }.map { $0.deepCopy() }) + own.dropFirst(prefix.count).flatMap { $0 }
            merged.forEach { $0.parent = target }
            target.children = merged
        }
        for listTag in AvfxBlock.cumulativeTags[tag] ?? [] {
            let blocks = children.filter { $0.tag == listTag && $0.children != nil }
            guard let last = blocks.last, blocks.count > 1 else { continue }
            let records = last.records()
            for (k, block) in blocks.dropLast().enumerated() {
                let keep = records.count - (blocks.count - 1 - k)
                guard keep > 0 else { continue }
                let copies = records.prefix(keep).flatMap { $0 }.map { $0.deepCopy() }
                copies.forEach { $0.parent = block }
                block.children = copies
            }
        }
        for child in children { child.syncCumulativeLists() }
    }
}

extension Array where Element == UInt8 {
    func u16(_ at: Int) -> UInt16 { UInt16(self[at]) | UInt16(self[at + 1]) << 8 }
    func u32(_ at: Int) -> UInt32 {
        UInt32(self[at]) | UInt32(self[at + 1]) << 8 | UInt32(self[at + 2]) << 16 | UInt32(self[at + 3]) << 24
    }
    func f32(_ at: Int) -> Float { Float(bitPattern: u32(at)) }
    mutating func setU32(_ at: Int, _ v: UInt32) {
        self[at] = UInt8(v & 0xff)
        self[at + 1] = UInt8((v >> 8) & 0xff)
        self[at + 2] = UInt8((v >> 16) & 0xff)
        self[at + 3] = UInt8(v >> 24)
    }
    mutating func appendU32(_ v: UInt32) {
        append(UInt8(v & 0xff)); append(UInt8((v >> 8) & 0xff)); append(UInt8((v >> 16) & 0xff)); append(UInt8(v >> 24))
    }
    mutating func appendU16(_ v: UInt16) { append(UInt8(v & 0xff)); append(UInt8(v >> 8)) }
}
