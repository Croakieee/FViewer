import Foundation

extension AvfxBlock {
    static let topOrder = ["Schd", "TmLn", "Emit", "Ptcl", "Efct", "Bind", "Tex", "Modl"]
    private static let rootCounts: [String: String] = [
        "ScCn": "Schd", "TlCn": "TmLn", "EmCn": "Emit", "PrCn": "Ptcl", "EfCn": "Efct", "BdCn": "Bind", "TxCn": "Tex", "MdCn": "Modl",
    ]

    static func leaf(_ tag: String, int value: Int) -> AvfxBlock {
        var bytes: [UInt8] = []
        bytes.appendU32(UInt32(bitPattern: Int32(truncatingIfNeeded: value)))
        return AvfxBlock(tag: tag, data: bytes)
    }

    static func leaf(_ tag: String, float value: Float) -> AvfxBlock {
        var bytes: [UInt8] = []
        bytes.appendU32(value.bitPattern)
        return AvfxBlock(tag: tag, data: bytes)
    }

    static func template(_ name: String) -> AvfxBlock? {
        guard let url = Bundle.main.url(forResource: "default_" + name, withExtension: "vfxedit"), let data = try? Data(contentsOf: url),
              let blocks = try? AvfxBlock.parse([UInt8](data), 0, data.count) else { return nil }
        return blocks.first
    }

    func remove(_ block: AvfxBlock) {
        children?.removeAll { $0 === block }
    }

    func ownRecords(_ tag: String) -> [[AvfxBlock]] {
        guard let last = children?.last(where: { $0.tag == tag && $0.children != nil }) else { return [] }
        var records = last.records()
        if let source = AvfxBlock.cumulativePrefixSource[tag] {
            records = Array(records.dropFirst(ownRecords(source).count))
        }
        return records
    }

    func setOwnRecords(_ tag: String, _ records: [[AvfxBlock]]) {
        var dependents: [(String, [[AvfxBlock]])] = []
        for (dependent, source) in AvfxBlock.cumulativePrefixSource where source == tag {
            if children?.contains(where: { $0.tag == dependent }) == true { dependents.append((dependent, ownRecords(dependent))) }
        }
        writeRecords(tag, records)
        for (dependent, own) in dependents { writeRecords(dependent, own) }
    }

    private func writeRecords(_ tag: String, _ records: [[AvfxBlock]]) {
        guard var list = children else { return }
        var prefix: [[AvfxBlock]] = []
        if let source = AvfxBlock.cumulativePrefixSource[tag] { prefix = ownRecords(source) }
        var position = list.firstIndex { $0.tag == tag }
        list.removeAll { $0.tag == tag }
        if position == nil {
            if let source = AvfxBlock.cumulativePrefixSource[tag], let after = list.lastIndex(where: { $0.tag == source }) {
                position = after + 1
            } else {
                position = list.firstIndex { $0.tag == "Data" || $0.tag == "Clip" } ?? list.count
            }
        }
        var blocks: [AvfxBlock] = []
        for k in 0..<records.count {
            let fields = (prefix + records.prefix(k + 1)).flatMap { $0 }.map { $0.deepCopy() }
            blocks.append(AvfxBlock(tag: tag, children: fields))
        }
        blocks.forEach { $0.parent = self }
        list.insert(contentsOf: blocks, at: min(position ?? list.count, list.count))
        children = list
    }

    func updateCounts() {
        guard let children else { return }
        func set(_ tag: String, _ value: Int) {
            if let block = child(tag), block.children == nil, block.data.count == 4, block.intValue != value { block.intValue = value }
        }
        switch tag {
        case "AVFX":
            for (count, target) in AvfxBlock.rootCounts { set(count, childrenNamed(target).count) }
        case "Emit":
            set("PrCn", ownRecords("ItPr").count)
            set("EmCn", ownRecords("ItEm").count)
        case "TmLn":
            set("TICn", ownRecords("Item").count)
            set("CpCn", childrenNamed("Clip").count)
        case "Schd":
            set("ItCn", ownRecords("Item").count)
            set("TrCn", ownRecords("Trgr").count)
        case "Ptcl":
            set("UvSN", childrenNamed("UvSt").count)
        default: break
        }
        for child in children where child.children != nil { child.updateCounts() }
    }

    func insertTopLevel(_ block: AvfxBlock) {
        guard var list = children else { return }
        let rank = AvfxBlock.topOrder.firstIndex(of: block.tag) ?? AvfxBlock.topOrder.count
        var position = list.count
        if let last = list.lastIndex(where: { (AvfxBlock.topOrder.firstIndex(of: $0.tag) ?? -1) >= 0 && (AvfxBlock.topOrder.firstIndex(of: $0.tag) ?? 0) <= rank }) {
            position = last + 1
        } else if let first = list.firstIndex(where: { AvfxBlock.topOrder.contains($0.tag) }) {
            position = first
        }
        block.parent = self
        list.insert(block, at: position)
        children = list
    }

    static func curveData(tag: String, value: Float) -> AvfxBlock {
        let block = AvfxBlock(tag: tag, children: [leaf("KeyC", int: 0), leaf("BvPr", int: 0), leaf("BvPo", int: 0), leaf("RanT", int: 0)])
        block.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: value)]
        return block
    }

    static func curveAxes(tag: String, axes: [String], value: Float) -> AvfxBlock {
        AvfxBlock(tag: tag, children: [leaf("ACT", int: 0), leaf("ACTR", int: 0)] + axes.map { curveData(tag: $0, value: value) })
    }

    static func curveColor(tag: String) -> AvfxBlock {
        let rgb = AvfxBlock(tag: "RGB", children: [leaf("KeyC", int: 0), leaf("BvPr", int: 0), leaf("BvPo", int: 0)])
        rgb.curveKeys = [AvfxKey(time: 0, type: 1, x: 1, y: 1, z: 1)]
        return AvfxBlock(tag: tag, children: [rgb, curveData(tag: "A", value: 1)])
    }

    func remapReference(_ fieldTag: String, removed: Int) {
        guard data.count >= 4 else { return }
        let value = intValue
        if value == removed {
            intValue = -1
        } else if value > removed {
            intValue = value - 1
        }
    }
}
