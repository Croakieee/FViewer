import Combine
import SwiftUI
import simd

struct ModelCapture {
    var draw: [UInt8]?
    var emit: [UInt8]?
    var index: [UInt8]?
}

struct ModelModal {
    var kind: Character
    var start: CGPoint
    var before: ModelCapture
    var axis: Int?
}

final class ModelEditSession: ObservableObject {
    static weak var active: ModelEditSession?

    let document: EffectDocument
    let nodeID: String
    private let fallback: AvfxBlock

    var model: AvfxBlock {
        if case .avfx(let block, _, _)? = document.node(nodeID)?.payload, block.tag == "Modl" { return block }
        return fallback
    }
    @Published var selection: Set<Int> = []
    @Published var emitSelection: Set<Int> = []
    @Published var uvSet = 0
    @Published var showFaces = true
    @Published var showColors = false
    @Published var showNormals = false
    @Published var showEmit = true
    @Published var texturePath = ""
    @Published var status = ""
    @Published var yaw: Float = 0.7
    @Published var pitch: Float = 0.5
    @Published var distance: Float = 3
    @Published var target = SIMD3<Float>(0, 0, 0)
    @Published var uvScale: CGFloat = 300
    @Published var uvOrigin = CGPoint(x: 40, y: 40)
    var framed3D = false
    var framedUV = ""

    init(document: EffectDocument, nodeID: String, model: AvfxBlock) {
        self.document = document
        self.nodeID = nodeID
        fallback = model
    }

    var draw: AvfxBlock? { model.child("VDrw") }
    var emit: AvfxBlock? { model.child("VEmt") }
    var vertexCount: Int { (draw?.data.count ?? 0) / 36 }
    var emitCount: Int { (emit?.data.count ?? 0) / 28 }
    var triangleCount: Int { (model.child("VIdx")?.data.count ?? 0) / 6 }

    var indices: [Int] {
        guard let data = model.child("VIdx")?.data else { return [] }
        return stride(from: 0, to: data.count - 1, by: 2).map { Int(data.u16($0)) }
    }

    private func half(_ data: [UInt8], _ at: Int) -> Float { at + 1 < data.count ? CurveMath.halfToFloat(data.u16(at)) : 0 }

    private func setHalf(_ block: AvfxBlock, _ at: Int, _ value: Float) {
        guard at + 1 < block.data.count else { return }
        let bits = Gltf.floatToHalf(value)
        block.data[at] = UInt8(bits & 0xff)
        block.data[at + 1] = UInt8(bits >> 8)
    }

    func positions(in data: [UInt8]?) -> [SIMD3<Float>] {
        guard let data else { return [] }
        return (0..<data.count / 36).map { SIMD3(half(data, $0 * 36), half(data, $0 * 36 + 2), half(data, $0 * 36 + 4)) }
    }

    func uvs(in data: [UInt8]?, set: Int) -> [SIMD2<Float>] {
        guard let data else { return [] }
        return (0..<data.count / 36).map { SIMD2(half(data, $0 * 36 + 20 + set * 4), half(data, $0 * 36 + 22 + set * 4)) }
    }

    func emitPositions(in data: [UInt8]?) -> [SIMD3<Float>] {
        guard let data else { return [] }
        return (0..<data.count / 28).map { SIMD3(data.f32($0 * 28), data.f32($0 * 28 + 4), data.f32($0 * 28 + 8)) }
    }

    var positions: [SIMD3<Float>] { positions(in: draw?.data) }
    var currentUVs: [SIMD2<Float>] { uvs(in: draw?.data, set: uvSet) }
    var emitPositions: [SIMD3<Float>] { emitPositions(in: emit?.data) }

    func normal(_ index: Int) -> SIMD3<Float> {
        guard let data = draw?.data, index * 36 + 10 < data.count else { return SIMD3(0, 1, 0) }
        let o = index * 36 + 8
        return SIMD3((Float(data[o]) - 128) / 127, (Float(data[o + 1]) - 128) / 127, (Float(data[o + 2]) - 128) / 127)
    }

    func setNormal(_ index: Int, _ value: SIMD3<Float>) {
        guard let block = draw, index * 36 + 10 < block.data.count else { return }
        for axis in 0..<3 { block.data[index * 36 + 8 + axis] = UInt8(min(max((value[axis] * 127 + 128).rounded(), 0), 255)) }
    }

    func color(_ index: Int) -> SIMD4<Double> {
        guard let data = draw?.data, index * 36 + 19 < data.count else { return SIMD4(1, 1, 1, 1) }
        let o = index * 36 + 16
        return SIMD4(Double(data[o]), Double(data[o + 1]), Double(data[o + 2]), Double(data[o + 3])) / 255
    }

    func setColor(_ index: Int, _ value: SIMD4<Double>) {
        guard let block = draw, index * 36 + 19 < block.data.count else { return }
        for c in 0..<4 { block.data[index * 36 + 16 + c] = UInt8(min(max((value[c] * 255).rounded(), 0), 255)) }
    }

    func setPosition(_ index: Int, _ value: SIMD3<Float>) {
        guard let block = draw else { return }
        for axis in 0..<3 { setHalf(block, index * 36 + axis * 2, value[axis]) }
    }

    func setUV(_ index: Int, _ value: SIMD2<Float>) {
        guard let block = draw else { return }
        setHalf(block, index * 36 + 20 + uvSet * 4, value.x)
        setHalf(block, index * 36 + 22 + uvSet * 4, value.y)
    }

    func setEmitPosition(_ index: Int, _ value: SIMD3<Float>) {
        guard let block = emit, index * 28 + 11 < block.data.count else { return }
        for axis in 0..<3 { block.data.setU32(index * 28 + axis * 4, value[axis].bitPattern) }
    }

    func emitNormal(_ index: Int) -> SIMD3<Float> {
        guard let data = emit?.data, index * 28 + 23 < data.count else { return SIMD3(0, 1, 0) }
        return SIMD3(data.f32(index * 28 + 12), data.f32(index * 28 + 16), data.f32(index * 28 + 20))
    }

    func setEmitNormal(_ index: Int, _ value: SIMD3<Float>) {
        guard let block = emit, index * 28 + 23 < block.data.count else { return }
        for axis in 0..<3 { block.data.setU32(index * 28 + 12 + axis * 4, value[axis].bitPattern) }
    }

    func emitColor(_ index: Int) -> SIMD4<Double> {
        guard let data = emit?.data, index * 28 + 27 < data.count else { return SIMD4(1, 1, 1, 1) }
        let o = index * 28 + 24
        return SIMD4(Double(data[o]), Double(data[o + 1]), Double(data[o + 2]), Double(data[o + 3])) / 255
    }

    func setEmitColor(_ index: Int, _ value: SIMD4<Double>) {
        guard let block = emit, index * 28 + 27 < block.data.count else { return }
        for c in 0..<4 { block.data[index * 28 + 24 + c] = UInt8(min(max((value[c] * 255).rounded(), 0), 255)) }
    }

    func capture() -> ModelCapture {
        ModelCapture(draw: draw?.data, emit: emit?.data, index: model.child("VIdx")?.data)
    }

    func restore(_ state: ModelCapture) {
        if let data = state.draw { draw?.data = data }
        if let data = state.emit { emit?.data = data }
        if let data = state.index { model.child("VIdx")?.data = data }
    }

    func commit(_ title: String, from before: ModelCapture) {
        let after = capture()
        guard after.draw != before.draw || after.emit != before.emit || after.index != before.index else {
            document.liveDrag()
            return
        }
        restore(before)
        document.perform(title, { self.restore(after) }, revert: { self.restore(before) })
    }

    func cancel(_ before: ModelCapture) {
        restore(before)
        document.liveDrag()
    }

    func clampSelection() {
        let vertices = vertexCount, points = emitCount
        if selection.contains(where: { $0 >= vertices }) { selection = selection.filter { $0 < vertices } }
        if emitSelection.contains(where: { $0 >= points }) { emitSelection = emitSelection.filter { $0 < points } }
    }

    func selectAll() {
        selection = Set(0..<vertexCount)
        emitSelection = showEmit ? Set(0..<emitCount) : []
    }

    func selectNone() {
        selection = []
        emitSelection = []
    }

    func selectLinked() {
        guard !selection.isEmpty else { return }
        let list = indices
        var grown = selection
        var changed = true
        while changed {
            changed = false
            for t in stride(from: 0, to: list.count - 2, by: 3) {
                let corners = [list[t], list[t + 1], list[t + 2]]
                if corners.contains(where: { grown.contains($0) }), !corners.allSatisfy({ grown.contains($0) }) {
                    corners.forEach { grown.insert($0) }
                    changed = true
                }
            }
        }
        selection = grown
    }

    var selectionCenter: SIMD3<Float>? {
        let all = positions, points = emitPositions
        let picked = selection.filter { $0 < all.count }.map { all[$0] } + emitSelection.filter { $0 < points.count }.map { points[$0] }
        guard !picked.isEmpty else { return nil }
        return picked.reduce(SIMD3<Float>(0, 0, 0), +) / Float(picked.count)
    }

    var uvCenter: SIMD2<Float>? {
        let all = currentUVs
        let picked = selection.filter { $0 < all.count }.map { all[$0] }
        guard !picked.isEmpty else { return nil }
        return picked.reduce(SIMD2<Float>(0, 0), +) / Float(picked.count)
    }

    func bounds(selectedOnly: Bool) -> (low: SIMD3<Float>, high: SIMD3<Float>)? {
        let all = positions, points = showEmit ? emitPositions : []
        var picked: [SIMD3<Float>] = []
        if selectedOnly, !(selection.isEmpty && emitSelection.isEmpty) {
            picked = selection.filter { $0 < all.count }.map { all[$0] } + emitSelection.filter { $0 < points.count }.map { points[$0] }
        } else {
            picked = all + points
        }
        guard var low = picked.first else { return nil }
        var high = low
        for p in picked {
            low = simd_min(low, p)
            high = simd_max(high, p)
        }
        return (low, high)
    }

    func translate(_ delta: SIMD3<Float>) {
        let all = positions, points = emitPositions
        for index in selection where index < all.count { setPosition(index, all[index] + delta) }
        for index in emitSelection where index < points.count { setEmitPosition(index, points[index] + delta) }
    }

    func translateUV(_ delta: SIMD2<Float>) {
        let all = currentUVs
        for index in selection where index < all.count { setUV(index, all[index] + delta) }
    }

    func flipWinding() {
        guard let block = model.child("VIdx"), block.data.count >= 6 else { return }
        let before = capture()
        for t in stride(from: 0, to: block.data.count - 5, by: 6) {
            block.data.swapAt(t + 2, t + 4)
            block.data.swapAt(t + 3, t + 5)
        }
        commit("Flip Winding", from: before)
        status = "Flipped \(triangleCount) triangles"
    }

    func recomputeNormals() {
        let all = positions, list = indices
        guard !all.isEmpty, list.count >= 3 else { return }
        let before = capture()
        var sums = [SIMD3<Float>](repeating: SIMD3(0, 0, 0), count: all.count)
        for t in stride(from: 0, to: list.count - 2, by: 3) {
            let a = list[t], b = list[t + 1], c = list[t + 2]
            guard a < all.count, b < all.count, c < all.count else { continue }
            let face = simd_cross(all[b] - all[a], all[c] - all[a])
            sums[a] += face
            sums[b] += face
            sums[c] += face
        }
        for (index, sum) in sums.enumerated() where simd_length(sum) > 1e-12 { setNormal(index, simd_normalize(sum)) }
        commit("Recompute Normals", from: before)
        status = "Recomputed normals of \(all.count) vertices"
    }

    func addEmitPoints(fromSelection: Bool) {
        let all = positions
        var fresh: [(SIMD3<Float>, SIMD3<Float>)] = []
        if fromSelection {
            for index in selection.sorted() where index < all.count { fresh.append((all[index], normal(index))) }
        } else {
            fresh = [(SIMD3(0, 0, 0), SIMD3(0, 1, 0))]
        }
        guard !fresh.isEmpty else { return }
        let first = emitCount
        document.performStructural(fresh.count == 1 ? "Add Emit Point" : "Add Emit Points") {
            for (offset, entry) in fresh.enumerated() {
                var point: [UInt8] = []
                for value in [entry.0.x, entry.0.y, entry.0.z, entry.1.x, entry.1.y, entry.1.z] { point.appendU32(value.bitPattern) }
                point.append(contentsOf: [255, 255, 255, 255])
                if let block = model.child("VEmt") { block.data.append(contentsOf: point) } else { model.insert(AvfxBlock(tag: "VEmt", data: point), at: 0) }
                var order: [UInt8] = []
                order.appendU16(UInt16(truncatingIfNeeded: first + offset))
                if let block = model.child("VNum") { block.data.append(contentsOf: order) } else { model.insert(AvfxBlock(tag: "VNum", data: order), at: 0) }
            }
        }
        selection = []
        emitSelection = Set(first..<first + fresh.count)
        showEmit = true
        status = "Added \(fresh.count) emit point\(fresh.count == 1 ? "" : "s")"
    }

    func removeSelectedEmitPoints() {
        let doomed = emitSelection.filter { $0 < emitCount }.sorted(by: >)
        guard !doomed.isEmpty else { return }
        document.performStructural(doomed.count == 1 ? "Remove Emit Point" : "Remove Emit Points") {
            for index in doomed {
                if let block = model.child("VEmt"), (index + 1) * 28 <= block.data.count { block.data.removeSubrange(index * 28..<(index + 1) * 28) }
                if let block = model.child("VNum"), block.data.count >= 2 { block.data.removeLast(2) }
            }
        }
        emitSelection = []
        status = "Removed \(doomed.count) emit point\(doomed.count == 1 ? "" : "s")"
    }
}
