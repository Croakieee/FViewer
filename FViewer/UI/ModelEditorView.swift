import SwiftUI

struct ModelEditorView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        Group {
            if let document = app.document, let id = app.modelEditorTarget, case .avfx(let block, _, _)? = document.node(id)?.payload, block.tag == "Modl" {
                ModelEditorContent(document: document, model: block, title: document.node(id)?.title ?? "Model")
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 760, minHeight: 460)
        .background(Theme.panel)
        .preferredColorScheme(.dark)
    }
}

private struct ModelEditorContent: View {
    @ObservedObject var document: EffectDocument
    let model: AvfxBlock
    let title: String
    @State private var uvSet = 0
    @State private var tab = 0
    @State private var page = 0

    private let pageSize = 200

    private var vertexCount: Int { (model.child("VDrw")?.data.count ?? 0) / 36 }
    private var emitCount: Int { (model.child("VEmt")?.data.count ?? 0) / 28 }
    private var orderCount: Int { (model.child("VNum")?.data.count ?? 0) / 2 }

    private func addEmitPoint() {
        document.performStructural("Add Emit Point") {
            var point: [UInt8] = []
            for value in [Float(0), 0, 0, 0, 1, 0] { point.appendU32(value.bitPattern) }
            point.append(contentsOf: [255, 255, 255, 255])
            let count = emitCount
            if let block = model.child("VEmt") { block.data.append(contentsOf: point) } else { model.insert(AvfxBlock(tag: "VEmt", data: point), at: 0) }
            var order: [UInt8] = []
            order.appendU16(UInt16(truncatingIfNeeded: count))
            if let block = model.child("VNum") { block.data.append(contentsOf: order) } else { model.insert(AvfxBlock(tag: "VNum", data: order), at: 0) }
        }
    }

    private func removeEmitPoint(_ index: Int) {
        document.performStructural("Remove Emit Point") {
            if let block = model.child("VEmt"), (index + 1) * 28 <= block.data.count { block.data.removeSubrange(index * 28..<(index + 1) * 28) }
            if let block = model.child("VNum"), block.data.count >= 2 { block.data.removeLast(2) }
        }
    }

    var body: some View {
        let mesh = Gltf.mesh(from: model)
        VStack(spacing: 0) {
            EditorHeader(symbol: "cube", title: "Model Editor · " + title) {
                Text("\(mesh.positions.count) vertices · \(mesh.indices.count / 3) triangles · \(emitCount) emit points").font(Theme.small).foregroundStyle(Theme.dim)
                Spacer()
            }
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Text("UV Set").font(Theme.font).foregroundStyle(Theme.text)
                        ForEach(0..<4, id: \.self) { index in SegmentButton(title: "\(index + 1)", active: uvSet == index) { uvSet = index } }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 28)
                    uvCanvas(mesh).padding(8)
                }
                .frame(minWidth: 300)
                Rectangle().fill(Theme.line).frame(width: 1)
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
                        if tab == 1 {
                            HeaderButton(symbol: "plus", help: "Add an emit point") { addEmitPoint() }
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
                .frame(minWidth: 420)
            }
        }
    }

    private func uvCanvas(_ mesh: GltfMesh) -> some View {
        Canvas { context, size in
            let all = mesh.uvs[uvSet]
            let low = min(0, all.map(\.x).min() ?? 0, all.map(\.y).min() ?? 0), high = max(1, all.map(\.x).max() ?? 1, all.map(\.y).max() ?? 1)
            let extent = CGFloat(max(high - low, 1e-6))
            let fitted = min(size.width, size.height)
            let side = fitted / extent
            let origin = CGPoint(x: (size.width - fitted) / 2 - CGFloat(low) * side, y: (size.height - fitted) / 2 - CGFloat(low) * side)
            let frame = CGRect(x: origin.x, y: origin.y, width: side, height: side)
            context.fill(Path(frame), with: .color(Color(white: 0.12)))
            for step in 1..<4 {
                let offset = side * CGFloat(step) / 4
                var line = Path()
                line.move(to: CGPoint(x: origin.x + offset, y: origin.y))
                line.addLine(to: CGPoint(x: origin.x + offset, y: origin.y + side))
                line.move(to: CGPoint(x: origin.x, y: origin.y + offset))
                line.addLine(to: CGPoint(x: origin.x + side, y: origin.y + offset))
                context.stroke(line, with: .color(Color.white.opacity(0.06)), lineWidth: 1)
            }
            context.stroke(Path(frame), with: .color(Color.white.opacity(0.3)), lineWidth: 1)
            let uvs = mesh.uvs[uvSet]
            func point(_ index: Int) -> CGPoint? {
                guard index < uvs.count else { return nil }
                return CGPoint(x: origin.x + CGFloat(uvs[index].x) * side, y: origin.y + CGFloat(uvs[index].y) * side)
            }
            var wires = Path()
            for t in stride(from: 0, to: mesh.indices.count - 2, by: 3) {
                guard let a = point(Int(mesh.indices[t])), let b = point(Int(mesh.indices[t + 1])), let c = point(Int(mesh.indices[t + 2])) else { continue }
                wires.move(to: a)
                wires.addLine(to: b)
                wires.addLine(to: c)
                wires.closeSubpath()
            }
            context.clip(to: Path(CGRect(origin: .zero, size: size)))
            context.fill(wires, with: .color(NodeTint.model.color.opacity(0.12)))
            context.stroke(wires, with: .color(NodeTint.model.color.opacity(0.9)), lineWidth: 0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cell(_ title: String, _ value: Double, step: Double = 0.01, write: @escaping (Double) -> Void) -> some View {
        NumberField(label: title, value: value, step: step, digits: 3,
                    onLive: { next in
                        write(next)
                        document.liveChanged()
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
                                    let v = UInt16(max(0, min(65535, value)))
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
