import Compression
import Foundation

enum SqPackError: Error, LocalizedError {
    case outOfBounds(Int)
    case notSqPack(String)
    case noArchives(String)
    case notFound(String)
    case missingDatFile(String)
    case collision(String)
    case unsupportedEntry(UInt32)
    case corrupt(String)

    var errorDescription: String? {
        switch self {
        case let .outOfBounds(offset): "Read past the end of the archive at 0x\(String(offset, radix: 16))"
        case let .notSqPack(name): "\(name) is not a SqPack file"
        case let .noArchives(path): "No *.win32.index files in \(path)"
        case let .notFound(path): "\(path) is not in the game archives"
        case let .missingDatFile(name): "The data file \(name) is missing"
        case let .collision(path): "\(path) is stored under a colliding hash"
        case let .unsupportedEntry(type): "Unknown archive entry type \(type)"
        case let .corrupt(path): "\(path) is damaged in the archive"
        }
    }
}

extension Data {
    func sqLE<T: FixedWidthInteger>(_ offset: Int, as _: T.Type = T.self) throws -> T {
        let size = MemoryLayout<T>.size
        guard offset >= 0, offset <= count - size else { throw SqPackError.outOfBounds(offset) }
        return withUnsafeBytes { T(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: T.self)) }
    }
}

enum SqPackHash {
    private static let table: [UInt32] = (0..<256).map { i in
        var c = UInt32(i)
        for _ in 0..<8 { c = c & 1 != 0 ? 0xEDB8_8320 ^ (c >> 1) : c >> 1 }
        return c
    }

    static func jam(_ text: Substring) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in text.utf8 {
            let lower = byte &- 65 < 26 ? byte | 0x20 : byte
            crc = table[Int((crc ^ UInt32(lower)) & 0xFF)] ^ (crc >> 8)
        }
        return crc
    }

    static func key(_ path: String) -> UInt64 {
        guard let slash = path.lastIndex(of: "/") else { return UInt64(jam(path[...])) }
        return UInt64(jam(path[..<slash])) << 32 | UInt64(jam(path[path.index(after: slash)...]))
    }
}

enum SqPackCategory {
    static let ids: [String: UInt8] = [
        "common": 0x00, "bgcommon": 0x01, "bg": 0x02, "cut": 0x03, "chara": 0x04,
        "shader": 0x05, "ui": 0x06, "sound": 0x07, "vfx": 0x08, "ui_script": 0x09,
        "exd": 0x0A, "game_script": 0x0B, "music": 0x0C, "sqpack_test": 0x12, "debug": 0x13,
    ]

    static func classify(_ path: String) -> (category: UInt8, expansion: UInt8)? {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count >= 2, let category = ids[String(parts[0])] else { return nil }
        guard parts.count >= 3, parts[1].hasPrefix("ex"), let expansion = UInt8(parts[1].dropFirst(2)) else { return (category, 0) }
        return (category, expansion)
    }
}

struct SqPackEntry {
    let raw: UInt32
    var isSynonym: Bool { raw & 1 != 0 }
    var dataFile: Int { Int(raw >> 1 & 0b111) }
    var offset: Int { Int(raw & ~0xF) * 8 }
}

final class GameArchive {
    let root: URL
    private var indexFiles: [String: URL] = [:]
    private var indexes: [String: [UInt64: SqPackEntry]] = [:]
    private var indexes2: [String: [UInt32: SqPackEntry]] = [:]
    private var datFiles: [URL: Data] = [:]

    init(root: URL) throws {
        let fm = FileManager.default
        var root = root.standardizedFileURL
        for sub in ["sqpack", "game/sqpack"] where fm.fileExists(atPath: root.appending(path: sub).path) {
            root = root.appending(path: sub)
            break
        }
        if root.deletingLastPathComponent().lastPathComponent == "sqpack" { root = root.deletingLastPathComponent() }
        let repositories = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for repository in repositories where repository.lastPathComponent == "ffxiv" || repository.lastPathComponent.hasPrefix("ex") {
            let files = (try? fm.contentsOfDirectory(at: repository, includingPropertiesForKeys: nil)) ?? []
            for file in files where file.lastPathComponent.hasSuffix(".win32.index") {
                indexFiles[String(file.lastPathComponent.dropLast(".win32.index".count))] = file
            }
        }
        guard !indexFiles.isEmpty else { throw SqPackError.noArchives(root.path) }
        self.root = root
    }

    var archiveCount: Int { indexFiles.count }

    private func stems(for path: String) -> [String] {
        guard let place = SqPackCategory.classify(path) else { return [] }
        let prefix = String(format: "%02x%02x", place.category, place.expansion)
        return indexFiles.keys.filter { $0.hasPrefix(prefix) }.sorted()
    }

    private func index(_ stem: String) throws -> [UInt64: SqPackEntry] {
        if let cached = indexes[stem] { return cached }
        guard let url = indexFiles[stem] else { return [:] }
        let data = try Data(contentsOf: url, options: .alwaysMapped)
        guard data.count >= 0x400, data.prefix(6) == Data("SqPack".utf8) else { throw SqPackError.notSqPack(url.lastPathComponent) }
        let header = Int(try data.sqLE(0x0C, as: UInt32.self))
        let tableOffset = Int(try data.sqLE(header + 0x08, as: UInt32.self))
        let count = Int(try data.sqLE(header + 0x0C, as: UInt32.self)) / 16
        var table: [UInt64: SqPackEntry] = [:]
        table.reserveCapacity(min(count, 4_000_000))
        for i in 0..<count {
            let at = tableOffset + i * 16
            table[try data.sqLE(at, as: UInt64.self)] = SqPackEntry(raw: try data.sqLE(at + 8, as: UInt32.self))
        }
        indexes[stem] = table
        return table
    }

    private func index2(_ stem: String) throws -> [UInt32: SqPackEntry] {
        if let cached = indexes2[stem] { return cached }
        guard let first = indexFiles[stem] else { return [:] }
        let url = first.deletingLastPathComponent().appending(path: "\(stem).win32.index2")
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        let data = try Data(contentsOf: url, options: .alwaysMapped)
        guard data.count >= 0x400, data.prefix(6) == Data("SqPack".utf8) else { throw SqPackError.notSqPack(url.lastPathComponent) }
        let header = Int(try data.sqLE(0x0C, as: UInt32.self))
        let tableOffset = Int(try data.sqLE(header + 0x08, as: UInt32.self))
        let count = Int(try data.sqLE(header + 0x0C, as: UInt32.self)) / 8
        var table: [UInt32: SqPackEntry] = [:]
        table.reserveCapacity(min(count, 4_000_000))
        for i in 0..<count {
            let at = tableOffset + i * 8
            table[try data.sqLE(at, as: UInt32.self)] = SqPackEntry(raw: try data.sqLE(at + 4, as: UInt32.self))
        }
        indexes2[stem] = table
        return table
    }

    private func dat(_ stem: String, _ number: Int) throws -> Data {
        guard let indexURL = indexFiles[stem] else { throw SqPackError.missingDatFile(stem) }
        let url = indexURL.deletingLastPathComponent().appending(path: "\(stem).win32.dat\(number)")
        if let cached = datFiles[url] { return cached }
        guard FileManager.default.fileExists(atPath: url.path) else { throw SqPackError.missingDatFile(url.lastPathComponent) }
        let data = try Data(contentsOf: url, options: .alwaysMapped)
        datFiles[url] = data
        return data
    }

    func contains(_ gamePath: String) -> Bool {
        let path = PenumbraExport.normalized(gamePath)
        let key = SqPackHash.key(path)
        return stems(for: path).contains { ((try? index($0)) ?? [:])[key] != nil }
    }

    func read(_ gamePath: String) throws -> Data {
        let path = PenumbraExport.normalized(gamePath)
        let key = SqPackHash.key(path)
        for stem in stems(for: path) {
            guard var entry = try index(stem)[key] else { continue }
            if entry.isSynonym {
                guard let other = try index2(stem)[SqPackHash.jam(path[...])], !other.isSynonym else { throw SqPackError.collision(path) }
                entry = other
            }
            do {
                return try SqPackDat.read(try dat(stem, entry.dataFile), at: entry.offset)
            } catch SqPackError.outOfBounds {
                throw SqPackError.corrupt(path)
            }
        }
        throw SqPackError.notFound(path)
    }
}

enum SqPackDat {
    static func read(_ d: Data, at off: Int) throws -> Data {
        let headerSize = Int(try d.sqLE(off, as: UInt32.self))
        let type = try d.sqLE(off + 4, as: UInt32.self)
        let rawSize = Int(try d.sqLE(off + 8, as: UInt32.self))
        var out = Data()
        out.reserveCapacity(min(rawSize, 256 << 20))
        switch type {
        case 1: return Data()
        case 2: try readStandard(d, off, headerSize, &out)
        case 3: try readModel(d, off, headerSize, &out)
        case 4: try readTexture(d, off, headerSize, &out)
        default: throw SqPackError.unsupportedEntry(type)
        }
        guard out.count == rawSize else { throw SqPackError.outOfBounds(off) }
        return out
    }

    @discardableResult
    private static func readBlock(_ d: Data, at pos: Int, into out: inout Data) throws -> Int {
        let headerSize = Int(try d.sqLE(pos, as: UInt32.self))
        let compressed = Int(try d.sqLE(pos + 8, as: UInt32.self))
        let size = Int(try d.sqLE(pos + 12, as: UInt32.self))
        let src = pos + headerSize
        if compressed == 32000 {
            guard src >= 0, size >= 0, src + size <= d.count else { throw SqPackError.outOfBounds(src) }
            out.append(d.subdata(in: src..<src + size))
            return size
        }
        guard src >= 0, compressed >= 0, src + compressed <= d.count else { throw SqPackError.outOfBounds(src) }
        guard size > 0 else { return 0 }
        let start = out.count
        out.count += size
        let written = out.withUnsafeMutableBytes { target in
            d.withUnsafeBytes { source in
                compression_decode_buffer(target.baseAddress!.advanced(by: start).assumingMemoryBound(to: UInt8.self), size,
                                          source.baseAddress!.advanced(by: src).assumingMemoryBound(to: UInt8.self), compressed,
                                          nil, COMPRESSION_ZLIB)
            }
        }
        guard written == size else { throw SqPackError.outOfBounds(pos) }
        return size
    }

    private static func readStandard(_ d: Data, _ off: Int, _ headerSize: Int, _ out: inout Data) throws {
        let blockCount = Int(try d.sqLE(off + 20, as: UInt32.self))
        for i in 0..<blockCount {
            let blockOffset = Int(try d.sqLE(off + 24 + i * 8, as: UInt32.self))
            try readBlock(d, at: off + headerSize + blockOffset, into: &out)
        }
    }

    private static func readTexture(_ d: Data, _ off: Int, _ headerSize: Int, _ out: inout Data) throws {
        let lodCount = Int(try d.sqLE(off + 20, as: UInt32.self))
        var lods: [(offset: Int, blocks: Int)] = []
        for i in 0..<lodCount {
            let at = off + 24 + i * 20
            lods.append((Int(try d.sqLE(at, as: UInt32.self)), Int(try d.sqLE(at + 16, as: UInt32.self))))
        }
        var sizeTable = off + 24 + lodCount * 20
        if let first = lods.first, first.offset > 0 {
            let start = off + headerSize
            guard start + first.offset <= d.count else { throw SqPackError.outOfBounds(start) }
            out.append(d.subdata(in: start..<start + first.offset))
        }
        for lod in lods where lod.blocks > 0 {
            var pos = off + headerSize + lod.offset
            try readBlock(d, at: pos, into: &out)
            for _ in 1..<lod.blocks {
                pos += Int(try d.sqLE(sizeTable, as: UInt16.self))
                sizeTable += 2
                try readBlock(d, at: pos, into: &out)
            }
            sizeTable += 2
        }
    }

    private static func readModel(_ d: Data, _ off: Int, _ headerSize: Int, _ out: inout Data) throws {
        func blockCount(_ k: Int) throws -> Int { Int(try d.sqLE(off + 178 + k * 2, as: UInt16.self)) }
        func section(_ k: Int) throws -> Int {
            let start = Int(try d.sqLE(off + 112 + k * 4, as: UInt32.self))
            let first = Int(try d.sqLE(off + 156 + k * 2, as: UInt16.self))
            var pos = off + headerSize + start
            var total = 0
            for j in 0..<(try blockCount(k)) {
                total += try readBlock(d, at: pos, into: &out)
                pos += Int(try d.sqLE(off + 208 + (first + j) * 2, as: UInt16.self))
            }
            return total
        }
        out.append(Data(count: 0x44))
        let stackSize = try section(0)
        let runtimeSize = try section(1)
        var vertexOffsets = [UInt32](repeating: 0, count: 3)
        var vertexSizes = [UInt32](repeating: 0, count: 3)
        var indexOffsets = [UInt32](repeating: 0, count: 3)
        var indexSizes = [UInt32](repeating: 0, count: 3)
        for lod in 0..<3 {
            if try blockCount(2 + lod) > 0 {
                vertexOffsets[lod] = UInt32(out.count)
                vertexSizes[lod] = UInt32(try section(2 + lod))
            }
            if try blockCount(5 + lod) > 0 { _ = try section(5 + lod) }
            if try blockCount(8 + lod) > 0 {
                indexOffsets[lod] = UInt32(out.count)
                indexSizes[lod] = UInt32(try section(8 + lod))
            }
        }
        var header: [UInt8] = []
        header.appendU32(try d.sqLE(off + 20, as: UInt32.self))
        header.appendU32(UInt32(stackSize))
        header.appendU32(UInt32(runtimeSize))
        for field in [200, 202] {
            let value = try d.sqLE(off + field, as: UInt16.self)
            header.append(UInt8(value & 0xFF))
            header.append(UInt8(value >> 8))
        }
        (vertexOffsets + indexOffsets + vertexSizes + indexSizes).forEach { header.appendU32($0) }
        header.append(try d.sqLE(off + 204, as: UInt8.self))
        header.append(try d.sqLE(off + 205, as: UInt8.self))
        header.append(try d.sqLE(off + 206, as: UInt8.self))
        header.append(0)
        out.replaceSubrange(0..<header.count, with: header)
    }
}
