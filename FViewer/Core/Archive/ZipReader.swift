import Compression
import Foundation

enum ZipReader {
    struct Entry {
        let path: String
        let method: Int
        let compressedSize: Int
        let size: Int
        let offset: Int
    }

    static func entries(_ bytes: [UInt8]) throws -> [Entry] {
        guard bytes.count >= 22 else { throw AvfxError.malformed("The archive is too small") }
        var end = bytes.count - 22
        while end >= 0, bytes.u32(end) != 0x0605_4b50 { end -= 1 }
        guard end >= 0 else { throw AvfxError.malformed("Not a zip archive") }
        let count = Int(bytes.u16(end + 10))
        var at = Int(bytes.u32(end + 16))
        var result: [Entry] = []
        for _ in 0..<count {
            guard at + 46 <= bytes.count, bytes.u32(at) == 0x0201_4b50 else { break }
            let nameLength = Int(bytes.u16(at + 28)), extra = Int(bytes.u16(at + 30)), comment = Int(bytes.u16(at + 32))
            guard at + 46 + nameLength <= bytes.count else { break }
            let name = String(decoding: bytes[at + 46..<at + 46 + nameLength], as: UTF8.self)
            result.append(Entry(path: name.replacingOccurrences(of: "\\", with: "/"), method: Int(bytes.u16(at + 10)), compressedSize: Int(bytes.u32(at + 20)),
                                size: Int(bytes.u32(at + 24)), offset: Int(bytes.u32(at + 42))))
            at += 46 + nameLength + extra + comment
        }
        return result
    }

    static func data(_ entry: Entry, in bytes: [UInt8]) throws -> [UInt8] {
        let at = entry.offset
        guard at + 30 <= bytes.count, bytes.u32(at) == 0x0403_4b50 else { throw AvfxError.malformed("\(entry.path): bad local header") }
        let start = at + 30 + Int(bytes.u16(at + 26)) + Int(bytes.u16(at + 28))
        guard start + entry.compressedSize <= bytes.count else { throw AvfxError.malformed("\(entry.path): truncated") }
        let raw = Array(bytes[start..<start + entry.compressedSize])
        if entry.method == 0 { return raw }
        guard entry.method == 8 else { throw AvfxError.malformed("\(entry.path): unsupported compression method \(entry.method)") }
        guard entry.size > 0 else { return [] }
        guard entry.size <= 1 << 30, entry.size <= max(raw.count, 1) * 2000 else { throw AvfxError.malformed("\(entry.path): declared size is not plausible") }
        var out = [UInt8](repeating: 0, count: entry.size)
        let written = compression_decode_buffer(&out, entry.size, raw, raw.count, nil, COMPRESSION_ZLIB)
        guard written == entry.size else { throw AvfxError.malformed("\(entry.path): could not be decompressed") }
        return out
    }
}
