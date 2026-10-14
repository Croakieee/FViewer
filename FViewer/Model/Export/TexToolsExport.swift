import Compression
import Foundation

enum TexToolsExport {
    static let partSize = 16000

    static func deflate(_ bytes: [UInt8]) -> [UInt8] {
        guard !bytes.isEmpty else { return [] }
        var out = [UInt8](repeating: 0, count: bytes.count + 1024)
        let written = compression_encode_buffer(&out, out.count, bytes, bytes.count, nil, COMPRESSION_ZLIB)
        return written > 0 ? Array(out[..<written]) : []
    }

    private static func appendU16(_ value: Int, to out: inout [UInt8]) {
        out.append(UInt8(value & 0xFF))
        out.append(UInt8(value >> 8 & 0xFF))
    }

    private static func block(_ part: [UInt8], aligned: Bool) -> [UInt8] {
        let packed = deflate(part)
        let stored = packed.isEmpty || (!aligned && packed.count > part.count)
        let body = stored ? part : packed
        var out: [UInt8] = []
        out.appendU32(16)
        out.appendU32(0)
        out.appendU32(stored ? 32000 : UInt32(body.count))
        out.appendU32(UInt32(part.count))
        out.append(contentsOf: body)
        let padding = 128 - (aligned ? (body.count + 16) % 128 : body.count % 128)
        out.append(contentsOf: [UInt8](repeating: 0, count: padding))
        return out
    }

    private static func parts(_ bytes: ArraySlice<UInt8>) -> [[UInt8]] {
        var result: [[UInt8]] = []
        var at = bytes.startIndex
        while at < bytes.endIndex {
            let end = min(at + partSize, bytes.endIndex)
            result.append(Array(bytes[at..<end]))
            at = end
        }
        return result
    }

    static func standardEntry(_ file: [UInt8]) -> [UInt8] {
        var header: [UInt8] = []
        var body: [UInt8] = []
        let chunks = parts(file[...])
        header.appendU32(128)
        header.appendU32(2)
        header.appendU32(UInt32(file.count))
        header.appendU32(0)
        header.appendU32(0)
        header.appendU32(UInt32(chunks.count))
        for chunk in chunks {
            let packed = block(chunk, aligned: true)
            header.appendU32(UInt32(body.count))
            appendU16(packed.count, to: &header)
            appendU16(chunk.count, to: &header)
            body.append(contentsOf: packed)
        }
        let units = UInt32(body.count / 128)
        for (offset, byte) in (units.bytes + units.bytes).enumerated() { header[12 + offset] = byte }
        if header.count % 128 != 0 { header.append(contentsOf: [UInt8](repeating: 0, count: 128 - header.count % 128)) }
        let size = UInt32(header.count)
        for (offset, byte) in size.bytes.enumerated() { header[offset] = byte }
        return header + body
    }

    static func textureEntry(_ file: [UInt8]) -> [UInt8]? {
        guard file.count > 80 else { return nil }
        let mipCount = Int(file[0x0E] & 0x7F)
        guard mipCount >= 1, mipCount <= 13 else { return nil }
        var starts: [Int] = []
        for i in 0..<mipCount { starts.append(Int(file.u32(0x1C + i * 4))) }
        starts.append(file.count)
        guard starts[0] == 80, zip(starts, starts.dropFirst()).allSatisfy({ $0 < $1 }) else { return nil }
        var body: [UInt8] = []
        var sizes: [Int] = []
        var lods: [(offset: Int, packed: Int, raw: Int, first: Int, count: Int)] = []
        for i in 0..<mipCount {
            let chunks = parts(file[starts[i]..<starts[i + 1]])
            let offset = 80 + body.count
            let first = sizes.count
            for chunk in chunks {
                let packed = block(chunk, aligned: false)
                sizes.append(packed.count)
                body.append(contentsOf: packed)
            }
            lods.append((offset, 80 + body.count - offset, starts[i + 1] - starts[i], first, chunks.count))
        }
        guard sizes.allSatisfy({ $0 <= 0xFFFF }) else { return nil }
        let headerSize = 24 + mipCount * 20 + sizes.count * 2
        let padding = 128 - headerSize % 128
        var out: [UInt8] = []
        out.appendU32(UInt32(headerSize + padding))
        out.appendU32(4)
        out.appendU32(UInt32(file.count))
        out.appendU32(0)
        out.appendU32(0)
        out.appendU32(UInt32(mipCount))
        for lod in lods {
            out.appendU32(UInt32(lod.offset))
            out.appendU32(UInt32(lod.packed))
            out.appendU32(UInt32(lod.raw))
            out.appendU32(UInt32(lod.first))
            out.appendU32(UInt32(lod.count))
        }
        for size in sizes { appendU16(size, to: &out) }
        out.append(contentsOf: [UInt8](repeating: 0, count: padding))
        out.append(contentsOf: file[..<80])
        out.append(contentsOf: body)
        return out
    }

    static func datFile(_ gamePath: String) -> String? {
        let parts = gamePath.split(separator: "/").map(String.init)
        guard parts.count >= 2 else { return nil }
        func expansion() -> String {
            let digits = parts[1].replacingOccurrences(of: "ex", with: "")
            return String(repeating: "0", count: max(0, 2 - digits.count)) + digits
        }
        switch parts[0] {
        case "vfx": return "080000"
        case "bgcommon": return "010000"
        case "chara": return "040000"
        case "shader": return "050000"
        case "ui": return "060000"
        case "sound": return "070000"
        case "cut": return parts[1] == "ffxiv" ? "030000" : "03" + expansion() + "00"
        case "music": return parts[1] == "ffxiv" ? "0c0000" : "0c" + expansion() + "00"
        case "bg":
            if parts[1] == "ffxiv" { return "020000" }
            guard parts.count >= 3 else { return nil }
            let zone = String(parts[2].split(separator: "_").first ?? "")
            return "02" + expansion() + String(repeating: "0", count: max(0, 2 - zone.count)) + zone
        default: return nil
        }
    }

    static func archive(_ mod: ModDescription, files: [(gamePath: String, data: [UInt8])]) throws -> [UInt8] {
        func text(_ value: String) -> JSONNode { JSONNode(.string(value)) }
        var payload: [UInt8] = []
        var list: [JSONNode] = []
        for file in files {
            let path = PenumbraExport.normalized(file.gamePath)
            guard let dat = datFile(path) else { throw AvfxError.malformed("\(path) does not belong to a known game archive") }
            let entry = path.hasSuffix(".tex") || path.hasSuffix(".atex") ? (textureEntry(file.data) ?? standardEntry(file.data)) : standardEntry(file.data)
            list.append(JSONNode(.object([
                JSONMember(key: "Name", node: text((path as NSString).lastPathComponent)),
                JSONMember(key: "Category", node: text("Raw File Import")),
                JSONMember(key: "FullPath", node: text(path)),
                JSONMember(key: "IsDefault", node: JSONNode(.bool(false))),
                JSONMember(key: "ModOffset", node: JSONNode(.number(Double(payload.count)))),
                JSONMember(key: "ModSize", node: JSONNode(.number(Double(entry.count)))),
                JSONMember(key: "DatFile", node: text(dat)),
                JSONMember(key: "ModPackEntry", node: JSONNode(.null)),
            ])))
            payload.append(contentsOf: entry)
        }
        let manifest = JSONNode(.object([
            JSONMember(key: "TTMPVersion", node: text("1.3s")),
            JSONMember(key: "Name", node: text(mod.name)),
            JSONMember(key: "Author", node: text(mod.author)),
            JSONMember(key: "Version", node: text(mod.version)),
            JSONMember(key: "Description", node: text(mod.description)),
            JSONMember(key: "ModPackPages", node: JSONNode(.null)),
            JSONMember(key: "SimpleModsList", node: JSONNode(.array(list))),
        ]))
        let line = manifest.serialized().split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.joined()
        return ZipWriter.archive([("TTMPD.mpd", payload), ("TTMPL.mpl", Array(line.utf8))])
    }
}

private extension UInt32 {
    var bytes: [UInt8] { [UInt8(self & 0xFF), UInt8(self >> 8 & 0xFF), UInt8(self >> 16 & 0xFF), UInt8(self >> 24)] }
}
