import Foundation

nonisolated enum Crc32 {
    static let table: [UInt32] = (0..<256).map { index -> UInt32 in
        var c = UInt32(index)
        for _ in 0..<8 { c = c & 1 == 1 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    @inline(__always) static func step(_ crc: UInt32, _ byte: UInt8) -> UInt32 {
        table[Int((crc ^ UInt32(byte)) & 0xff)] ^ (crc >> 8)
    }

    static func checksum(_ bytes: [UInt8]) -> UInt32 {
        var c: UInt32 = 0xFFFF_FFFF
        for byte in bytes { c = step(c, byte) }
        return c ^ 0xFFFF_FFFF
    }
}
