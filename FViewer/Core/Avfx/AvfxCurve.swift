import Foundation

struct AvfxKey: Equatable {
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
            var bytes: [UInt8] = []
            bytes.reserveCapacity(newValue.count * 16)
            for key in newValue {
                bytes.appendU16(UInt16(bitPattern: Int16(truncatingIfNeeded: key.time)))
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
