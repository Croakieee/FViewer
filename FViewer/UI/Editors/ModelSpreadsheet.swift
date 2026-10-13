import SwiftUI

struct ModelSpreadsheet: View {
    @ObservedObject var document: EffectDocument
    let model: AvfxBlock
    @State private var tab = 0
    @State private var page = 0

    private let pageSize = 200

    private var vertexCount: Int { (model.child("VDrw")?.data.count ?? 0) / 36 }
    private var emitCount: Int { (model.child("VEmt")?.data.count ?? 0) / 28 }
    private var orderCount: Int { (model.child("VNum")?.data.count ?? 0) / 2 }

    private func removeEmitPoint(_ index: Int) {
        document.performStructural("Remove Emit Point") {
            if let block = model.child("VEmt"), (index + 1) * 28 <= block.data.count { block.data.removeSubrange(index * 28..<(index + 1) * 28) }
            if let block = model.child("VNum"), block.data.count >= 2 { block.data.removeLast(2) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                SegmentButton(title: "Vertices", active: tab == 0) {
                    tab = 0
                    page = 0
                }
                SegmentButton(title: "Emit Points", active: tab == 1) {
                    tab = 1
                    page = 0
                }
                SegmentButton(title: "Vertex Order", active: tab == 2) {
                    tab = 2
                    page = 0
                }
                Spacer()
                let total = tab == 0 ? vertexCount : tab == 1 ? emitCount : orderCount
                let pages = max(1, (total + pageSize - 1) / pageSize)
                if pages > 1 {
                    HeaderButton(symbol: "chevron.left", help: "Previous page") { page = max(0, page - 1) }
                    Text("\(page + 1) / \(pages)").font(Theme.small).foregroundStyle(Theme.dim).frame(minWidth: 44)
                    HeaderButton(symbol: "chevron.right", help: "Next page") { page = min(pages - 1, page + 1) }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 28)
            table.id(document.revision / 1_000_000)
        }
    }

    private func cell(_ title: String, _ value: Double, step: Double = 0.01, write: @escaping (Double) -> Void) -> some View {
        NumberField(label: title, value: value, step: step, digits: 3,
                    onLive: { next in
                        write(next)
                        document.liveDrag()
                    },
                    onCommit: { old, next in
                        write(old)
                        document.perform("Edit Model", { write(next) }, revert: { write(old) })
                    })
            .frame(minWidth: 62)
    }

    private func header(_ titles: [String]) -> some View {
        HStack(spacing: 4) {
            Text("#").frame(width: 38, alignment: .trailing)
            ForEach(titles, id: \.self) { Text($0).frame(maxWidth: .infinity) }
        }
        .font(Theme.small)
        .foregroundStyle(Theme.dim)
        .padding(.horizontal, 8)
        .frame(height: 18)
    }

    @ViewBuilder private var table: some View {
        if tab == 0 {
            if vertexCount == 0 {
                Color.clear
            } else {
                header(["Position", "UV 1", "Color"])
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array((page * pageSize)..<min(vertexCount, (page + 1) * pageSize)), id: \.self) { index in vertexRow(index) }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        } else if tab == 2 {
            if orderCount == 0 {
                Color.clear
            } else {
                header(["Emit Point Index"])
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array((page * pageSize)..<min(orderCount, (page + 1) * pageSize)), id: \.self) { index in orderRow(index) }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        } else {
            if emitCount == 0 {
                Color.clear
            } else {
                header(["Position", "Normal", "Color"])
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array((page * pageSize)..<min(emitCount, (page + 1) * pageSize)), id: \.self) { index in emitRow(index) }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
            }
        }
    }


    private func half(_ block: AvfxBlock, _ at: Int) -> Double {
        at + 1 < block.data.count ? Double(CurveMath.halfToFloat(block.data.u16(at))) : 0
    }

    private func setHalf(_ block: AvfxBlock, _ at: Int, _ value: Double) {
        guard at + 1 < block.data.count else { return }
        let bits = Gltf.floatToHalf(Float(value))
        block.data[at] = UInt8(bits & 0xff)
        block.data[at + 1] = UInt8(bits >> 8)
    }

    private func swatch(_ block: AvfxBlock, _ at: Int) -> some View {
        let d = block.data
        let ok = at + 3 < d.count
        return RoundedRectangle(cornerRadius: 3)
            .fill(Color(.sRGB, red: ok ? Double(d[at]) / 255 : 1, green: ok ? Double(d[at + 1]) / 255 : 1, blue: ok ? Double(d[at + 2]) / 255 : 1,
                        opacity: 1))
            .overlay(Text(ok ? "α \(d[at + 3])" : "").font(Theme.small)
                .foregroundStyle(ok && Double(d[at]) * 0.3 + Double(d[at + 1]) * 0.59 + Double(d[at + 2]) * 0.11 > 140 ? Color.black : Color.white))
            .frame(maxWidth: .infinity)
            .frame(height: 20)
    }

    private func vertexRow(_ index: Int) -> some View {
        let o = index * 36
        return HStack(spacing: 4) {
            Text("\(index)").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 38, alignment: .trailing)
            if let block = model.child("VDrw") {
                ForEach(0..<3, id: \.self) { axis in
                    cell(["X", "Y", "Z"][axis], half(block, o + axis * 2)) { setHalf(block, o + axis * 2, $0) }
                }
                ForEach(0..<2, id: \.self) { axis in
                    cell(["U", "V"][axis], half(block, o + 20 + axis * 2)) { setHalf(block, o + 20 + axis * 2, $0) }
                }
                swatch(block, o + 16)
            }
        }
    }

    private func orderRow(_ index: Int) -> some View {
        HStack(spacing: 4) {
            Text("\(index)").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 38, alignment: .trailing)
            if let block = model.child("VNum") {
                NumberField(label: nil, value: index * 2 + 1 < block.data.count ? Double(block.data.u16(index * 2)) : 0, isInteger: true,
                            onLive: { _ in },
                            onCommit: { old, next in
                                func write(_ value: Double) {
                                    guard index * 2 + 1 < block.data.count else { return }
                                    let v = UInt16(Int(safe: value, in: 0...65535))
                                    block.data[index * 2] = UInt8(v & 0xff)
                                    block.data[index * 2 + 1] = UInt8(v >> 8)
                                }
                                document.perform("Edit Vertex Order", { write(next) }, revert: { write(old) })
                            })
            }
        }
    }

    private func emitRow(_ index: Int) -> some View {
        let o = index * 28
        return HStack(spacing: 4) {
            Text("\(index)").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 38, alignment: .trailing)
            if let block = model.child("VEmt") {
                ForEach(0..<6, id: \.self) { slot in
                    cell(["X", "Y", "Z", "Nx", "Ny", "Nz"][slot], o + slot * 4 + 3 < block.data.count ? Double(block.data.f32(o + slot * 4)) : 0) { value in
                        if o + slot * 4 + 3 < block.data.count { block.data.setU32(o + slot * 4, Float(value).bitPattern) }
                    }
                }
                swatch(block, o + 24)
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 16, height: 20)
                    .contentShape(Rectangle()).onTapGesture { removeEmitPoint(index) }.help("Remove this emit point")
            }
        }
    }
}
