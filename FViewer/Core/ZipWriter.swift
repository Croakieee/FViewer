import Foundation

enum ZipWriter {
    private static let table: [UInt32] = (0..<256).map { index -> UInt32 in
        var c = UInt32(index)
        for _ in 0..<8 { c = c & 1 == 1 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func crc32(_ bytes: [UInt8]) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for byte in bytes { c = table[Int((c ^ UInt32(byte)) & 0xff)] ^ (c >> 8) }
        return c ^ 0xFFFF_FFFF
    }

    static func archive(_ entries: [(path: String, data: [UInt8])]) -> [UInt8] {
        var out: [UInt8] = []
        var central: [UInt8] = []
        for entry in entries {
            let name = Array(entry.path.utf8)
            let crc = crc32(entry.data)
            let offset = out.count
            out.appendU32(0x0403_4b50)
            out.appendU16(20)
            out.appendU16(0x0800)
            out.appendU16(0)
            out.appendU16(0)
            out.appendU16(0x21)
            out.appendU32(crc)
            out.appendU32(UInt32(entry.data.count))
            out.appendU32(UInt32(entry.data.count))
            out.appendU16(UInt16(name.count))
            out.appendU16(0)
            out.append(contentsOf: name)
            out.append(contentsOf: entry.data)
            central.appendU32(0x0201_4b50)
            central.appendU16(20)
            central.appendU16(20)
            central.appendU16(0x0800)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0x21)
            central.appendU32(crc)
            central.appendU32(UInt32(entry.data.count))
            central.appendU32(UInt32(entry.data.count))
            central.appendU16(UInt16(name.count))
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU16(0)
            central.appendU32(0)
            central.appendU32(UInt32(offset))
            central.append(contentsOf: name)
        }
        let start = out.count
        out.append(contentsOf: central)
        out.appendU32(0x0605_4b50)
        out.appendU16(0)
        out.appendU16(0)
        out.appendU16(UInt16(entries.count))
        out.appendU16(UInt16(entries.count))
        out.appendU32(UInt32(central.count))
        out.appendU32(UInt32(start))
        out.appendU16(0)
        return out
    }
}
