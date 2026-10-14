import Foundation

struct AvfxKey: Hashable {
    var time: Int
    var type: Int
    var x: Float
    var y: Float
    var z: Float
}

extension AvfxBlock {
    var curveKeys: [AvfxKey] {
        get {
            guard let data = child("Keys")?.data else { return [] }
            return stride(from: 0, to: data.count - 15, by: 16).map { o in
                AvfxKey(time: Int(Int16(bitPattern: data.u16(o))), type: Int(Int16(bitPattern: data.u16(o + 2))),
                        x: data.f32(o + 4), y: data.f32(o + 8), z: data.f32(o + 12))
            }
        }
        set {
            var kept: [AvfxKey: [UInt8]] = [:]
            if let data = child("Keys")?.data {
                for (index, key) in curveKeys.enumerated() {
                    let o = index * 16
                    let raw = [data.u32(o + 4), data.u32(o + 8), data.u32(o + 12)].map { Float(bitPattern: $0) }
                    if raw != [key.x, key.y, key.z] { kept[key] = Array(data[o..<o + 16]) }
                }
            }
            var bytes: [UInt8] = []
            bytes.reserveCapacity(newValue.count * 16)
            for key in newValue {
                if let raw = kept[key] {
                    bytes.append(contentsOf: raw)
                    continue
                }
                bytes.appendU16(UInt16(bitPattern: Int16(truncatingIfNeeded: min(max(key.time, -32768), 32767))))
                bytes.appendU16(UInt16(bitPattern: Int16(truncatingIfNeeded: key.type)))
                bytes.appendU32(key.x.bitPattern)
                bytes.appendU32(key.y.bitPattern)
                bytes.appendU32(key.z.bitPattern)
            }
            if let keys = child("Keys") {
                keys.data = bytes
            } else {
                insert(AvfxBlock(tag: "Keys", data: bytes), at: children?.count ?? 0)
            }
            if let count = child("KeyC") {
                count.intValue = newValue.count
            } else {
                var four: [UInt8] = []
                four.appendU32(UInt32(newValue.count))
                insert(AvfxBlock(tag: "KeyC", data: four), at: 0)
            }
        }
    }
}
