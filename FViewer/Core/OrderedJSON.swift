import Foundation

indirect enum JSONValue {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONNode])
    case object([JSONMember])
}

struct JSONMember {
    var key: String
    var node: JSONNode
}

final class JSONNode: Identifiable {
    var value: JSONValue

    init(_ value: JSONValue) { self.value = value }

    var members: [JSONMember]? { if case .object(let m) = value { return m }; return nil }
    var elements: [JSONNode]? { if case .array(let a) = value { return a }; return nil }
    var number: Double? { if case .number(let n) = value { return n }; return nil }
    var string: String? { if case .string(let s) = value { return s }; return nil }
    var bool: Bool? { if case .bool(let b) = value { return b }; return nil }
    var isScalar: Bool {
        switch value {
        case .array, .object: return false
        default: return true
        }
    }

    subscript(key: String) -> JSONNode? { members?.first { $0.key == key }?.node }

    func set(_ key: String, _ node: JSONNode) {
        guard var m = members else { return }
        if let i = m.firstIndex(where: { $0.key == key }) { m[i].node = node } else { m.append(JSONMember(key: key, node: node)) }
        value = .object(m)
    }

    func deepCopy() -> JSONNode {
        switch value {
        case .array(let a): return JSONNode(.array(a.map { $0.deepCopy() }))
        case .object(let m): return JSONNode(.object(m.map { JSONMember(key: $0.key, node: $0.node.deepCopy()) }))
        default: return JSONNode(value)
        }
    }

    func serialized() -> String {
        var out = ""
        write(into: &out, indent: 0)
        out += "\n"
        return out
    }

    private func write(into out: inout String, indent: Int) {
        let pad = String(repeating: "  ", count: indent + 1)
        let close = String(repeating: "  ", count: indent)
        switch value {
        case .null: out += "null"
        case .bool(let b): out += b ? "true" : "false"
        case .number(let n): out += JSONNode.format(n)
        case .string(let s): out += JSONNode.quote(s)
        case .array(let items):
            if items.isEmpty { out += "[]"; return }
            let inline = compact()
            if inline.count + indent * 2 <= 100 { out += inline; return }
            out += "[\n"
            for (i, item) in items.enumerated() {
                out += pad
                item.write(into: &out, indent: indent + 1)
                out += i == items.count - 1 ? "\n" : ",\n"
            }
            out += close + "]"
        case .object(let members):
            if members.isEmpty { out += "{}"; return }
            let inline = compact()
            if indent > 0, inline.count + indent * 2 <= 100 { out += inline; return }
            out += "{\n"
            for (i, member) in members.enumerated() {
                out += pad + JSONNode.quote(member.key) + ": "
                member.node.write(into: &out, indent: indent + 1)
                out += i == members.count - 1 ? "\n" : ",\n"
            }
            out += close + "}"
        }
    }

    private func compact() -> String {
        switch value {
        case .null: return "null"
        case .bool(let b): return b ? "true" : "false"
        case .number(let n): return JSONNode.format(n)
        case .string(let s): return JSONNode.quote(s)
        case .array(let items): return "[" + items.map { $0.compact() }.joined(separator: ", ") + "]"
        case .object(let members):
            if members.isEmpty { return "{}" }
            return "{ " + members.map { JSONNode.quote($0.key) + ": " + $0.node.compact() }.joined(separator: ", ") + " }"
        }
    }

    static func format(_ n: Double) -> String {
        if n.isFinite, n == n.rounded(), abs(n) < 1e15 { return String(Int64(n)) }
        var s = String(n)
        if s.hasSuffix(".0") { s.removeLast(2) }
        return s
    }

    private static func quote(_ s: String) -> String {
        var out = "\""
        for u in s.unicodeScalars {
            switch u {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if u.value < 0x20 { out += String(format: "\\u%04x", u.value) } else { out.unicodeScalars.append(u) }
            }
        }
        return out + "\""
    }
}

enum JSONParseError: LocalizedError {
    case syntax(String, Int)
    var errorDescription: String? {
        switch self {
        case .syntax(let message, let offset): return "JSON: \(message) (позиция \(offset))"
        }
    }
}

struct JSONParser {
    private let s: [UInt8]
    private var p = 0

    static func parse(_ data: Data) throws -> JSONNode {
        var parser = JSONParser(s: [UInt8](data))
        let node = try parser.value()
        parser.skipSpace()
        if parser.p != parser.s.count { throw JSONParseError.syntax("лишние данные после значения", parser.p) }
        return node
    }

    private init(s: [UInt8]) { self.s = s }

    private mutating func skipSpace() {
        while p < s.count, s[p] == 0x20 || s[p] == 0x0a || s[p] == 0x0d || s[p] == 0x09 { p += 1 }
    }

    private mutating func expect(_ c: UInt8) throws {
        skipSpace()
        guard p < s.count, s[p] == c else {
            throw JSONParseError.syntax("ожидался символ «\(Character(UnicodeScalar(c)))»", p)
        }
        p += 1
    }

    private mutating func literal(_ text: String) -> Bool {
        let bytes = Array(text.utf8)
        guard p + bytes.count <= s.count, Array(s[p..<p + bytes.count]) == bytes else { return false }
        p += bytes.count
        return true
    }

    private mutating func value() throws -> JSONNode {
        skipSpace()
        guard p < s.count else { throw JSONParseError.syntax("неожиданный конец", p) }
        switch s[p] {
        case UInt8(ascii: "{"):
            p += 1
            var members: [JSONMember] = []
            skipSpace()
            if p < s.count, s[p] == UInt8(ascii: "}") { p += 1; return JSONNode(.object([])) }
            while true {
                skipSpace()
                let key = try string()
                try expect(UInt8(ascii: ":"))
                members.append(JSONMember(key: key, node: try value()))
                skipSpace()
                if p < s.count, s[p] == UInt8(ascii: ",") { p += 1; continue }
                try expect(UInt8(ascii: "}"))
                return JSONNode(.object(members))
            }
        case UInt8(ascii: "["):
            p += 1
            var items: [JSONNode] = []
            skipSpace()
            if p < s.count, s[p] == UInt8(ascii: "]") { p += 1; return JSONNode(.array([])) }
            while true {
                items.append(try value())
                skipSpace()
                if p < s.count, s[p] == UInt8(ascii: ",") { p += 1; continue }
                try expect(UInt8(ascii: "]"))
                return JSONNode(.array(items))
            }
        case UInt8(ascii: "\""):
            return JSONNode(.string(try string()))
        default:
            if literal("true") { return JSONNode(.bool(true)) }
            if literal("false") { return JSONNode(.bool(false)) }
            if literal("null") { return JSONNode(.null) }
            let start = p
            while p < s.count, "+-0123456789.eE".utf8.contains(s[p]) { p += 1 }
            guard p > start, let n = Double(String(decoding: s[start..<p], as: UTF8.self)) else {
                throw JSONParseError.syntax("неверное значение", start)
            }
            return JSONNode(.number(n))
        }
    }

    private mutating func string() throws -> String {
        guard p < s.count, s[p] == UInt8(ascii: "\"") else { throw JSONParseError.syntax("ожидалась строка", p) }
        p += 1
        var bytes: [UInt8] = []
        while p < s.count, s[p] != UInt8(ascii: "\"") {
            if s[p] == UInt8(ascii: "\\"), p + 1 < s.count {
                p += 1
                switch s[p] {
                case UInt8(ascii: "n"): bytes.append(0x0a)
                case UInt8(ascii: "t"): bytes.append(0x09)
                case UInt8(ascii: "r"): bytes.append(0x0d)
                case UInt8(ascii: "b"): bytes.append(0x08)
                case UInt8(ascii: "f"): bytes.append(0x0c)
                case UInt8(ascii: "u"):
                    guard p + 4 < s.count, let code = UInt32(String(decoding: s[p + 1...p + 4], as: UTF8.self), radix: 16),
                          let scalar = UnicodeScalar(code) else { throw JSONParseError.syntax("неверная \\u-последовательность", p) }
                    bytes.append(contentsOf: Array(String(Character(scalar)).utf8))
                    p += 4
                default: bytes.append(s[p])
                }
            } else {
                bytes.append(s[p])
            }
            p += 1
        }
        guard p < s.count else { throw JSONParseError.syntax("строка не закрыта", p) }
        p += 1
        return String(decoding: bytes, as: UTF8.self)
    }
}
