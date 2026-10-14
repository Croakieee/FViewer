import SwiftUI

struct AvfxMaterialView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let particleID: String
    @State private var pan = CGSize(width: 24, height: 16)
    @State private var wire: (texture: Int, end: CGPoint)?

    private static let order = ["TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP"]
    private static let layerTitles: Set<String> = ["Texture Color 1", "Texture Color 2", "Texture Color 3", "Texture Color 4", "Texture Normal",
                                                   "Texture Reflection", "Texture Distortion", "Texture Palette"]
    private static let textureWidth: CGFloat = 168
    private static let textureHeight: CGFloat = 84
    private static let layerWidth: CGFloat = 250
    private static let layerHeight: CGFloat = 112
    private static let outputWidth: CGFloat = 220
    private static let header: CGFloat = 24
    private static let orange = Color(red: 1, green: 0.63, blue: 0.16)

    private struct Layer {
        let node: OutlineNode
        let tag: String
        let fields: [PropField]
    }

    private var particle: OutlineNode? { document.node(particleID) }

    private func layers(_ particle: OutlineNode) -> [Layer] {
        var result: [Layer] = []
        for tag in AvfxMaterialView.order {
            for child in particle.children {
                if case .avfx(let block, _, let record) = child.payload, record == nil, block.tag == tag {
                    result.append(Layer(node: child, tag: tag, fields: document.sections(for: child).flatMap(\.fields)))
                }
            }
        }
        return result
    }

    private func field(_ layer: Layer, _ tag: String) -> PropField? { layer.fields.first { $0.tag == tag } }

    private func textureFields(_ layer: Layer) -> [PropField] {
        layer.fields.filter { $0.tag == "TxNo" || $0.tag.hasPrefix("TLst") || $0.label.hasPrefix("Mask Texture") }
    }

    private func textureIndices(_ layer: Layer) -> [Int] { textureFields(layer).map { Int(safe: $0.read().number.rounded()) }.filter { $0 >= 0 } }

    private func textureIndex(_ layer: Layer) -> Int { textureIndices(layer).first ?? -1 }

    private func isOn(_ layer: Layer) -> Bool { field(layer, "bEna")?.read() == .bool(true) }

    private func texturePoint(_ index: Int) -> CGPoint { CGPoint(x: pan.width, y: pan.height + CGFloat(index) * (AvfxMaterialView.textureHeight + 14)) }

    private func layerPoint(_ index: Int) -> CGPoint {
        CGPoint(x: pan.width + AvfxMaterialView.textureWidth + 90, y: pan.height + CGFloat(index) * (AvfxMaterialView.layerHeight + 14))
    }

    private func outputPoint() -> CGPoint {
        CGPoint(x: pan.width + AvfxMaterialView.textureWidth + 90 + AvfxMaterialView.layerWidth + 90, y: pan.height)
    }

    private func curve(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        let reach = max(40, abs(b.x - a.x) * 0.5)
        path.move(to: a)
        path.addCurve(to: b, control1: CGPoint(x: a.x + reach, y: a.y), control2: CGPoint(x: b.x - reach, y: b.y))
        return path
    }

    private func layerAt(_ point: CGPoint, _ list: [Layer]) -> Int? {
        list.indices.first { index in
            CGRect(origin: layerPoint(index), size: CGSize(width: AvfxMaterialView.layerWidth, height: AvfxMaterialView.layerHeight)).insetBy(dx: -10, dy: -4).contains(point)
        }
    }

    private func setTexture(_ layer: Layer, _ index: Int) {
        if let field = textureFields(layer).first {
            document.commit(field, from: field.read(), to: .int(index))
            return
        }
        guard index >= 0 else { return }
        if let add = layer.node.actions.first(where: { $0.title == "Add Mask Texture" }) {
            add.perform()
        } else if let create = document.missingFields(for: layer.node).first(where: { $0.title == "Texture Index" }) {
            create.create()
        } else {
            return
        }
        if let fresh = particle.flatMap({ layers($0).first { $0.node.id == layer.node.id } }), let field = textureFields(fresh).first {
            field.write?(.int(index))
            document.amendLastUndo()
        }
    }

    private func textureNode(_ index: Int, _ slot: TextureSlot, used: Bool) -> some View {
        let chosen = document.selectionID == slot.nodeID
        return VStack(spacing: 0) {
            HStack(spacing: 5) {
                Text("Texture \(index)").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.white).lineLimit(1)
                Spacer(minLength: 0)
                Circle().fill(Color(red: 0.95, green: 0.55, blue: 0.75)).frame(width: 10, height: 10)
                    .contentShape(Rectangle().inset(by: -8))
                    .gesture(DragGesture(minimumDistance: 1, coordinateSpace: .named("avfxMaterial"))
                        .onChanged { drag in wire = (index, drag.location) }
                        .onEnded { drag in
                            if let particle, let hit = layerAt(drag.location, layers(particle)) { setTexture(layers(particle)[hit], index) }
                            wire = nil
                        })
                    .help("Drag onto a layer to make it use this texture")
                    .offset(x: 13)
            }
            .padding(.horizontal, 9)
            .frame(height: AvfxMaterialView.header)
            .background(Color(red: 0.30, green: 0.50, blue: 0.80).opacity(used ? 0.9 : 0.45))
            HStack(spacing: 6) {
                ZStack {
                    CheckerBackground()
                    if let image = app.image(for: slot.path) { Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit) }
                }
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                VStack(alignment: .leading, spacing: 2) {
                    Text(slot.name).font(Theme.small).foregroundStyle(Theme.text).lineLimit(2).truncationMode(.middle)
                    Text(used ? "used here" : "not used by this particle").font(.system(size: 9)).foregroundStyle(Theme.dim)
                }
                Spacer(minLength: 0)
            }
            .padding(6)
        }
        .frame(width: AvfxMaterialView.textureWidth, height: AvfxMaterialView.textureHeight, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.gray(0.19)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(chosen ? AvfxMaterialView.orange : Color.black.opacity(0.55), lineWidth: chosen ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture { if let id = slot.nodeID { document.selectionID = id } }
        .help(slot.path)
    }

    private func summary(_ label: String, _ field: PropField?) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.small).foregroundStyle(Theme.dim).frame(width: 96, alignment: .trailing)
            if let field {
                FieldControl(document: document, field: field)
            } else {
                Text("—").font(Theme.small).foregroundStyle(Theme.dim)
                Spacer(minLength: 0)
            }
        }
        .frame(height: 20)
    }

    private func layerNode(_ index: Int, _ layer: Layer, textures: Int) -> some View {
        let chosen = document.selectionID == layer.node.id
        let on = isOn(layer)
        let wired = textureIndex(layer)
        let rows: [(String, String)] = layer.tag.hasPrefix("TC") ? [("Color", "TCCT"), ("Alpha", "TCAT"), ("UV Set", "UvSN")]
            : layer.tag == "TD" ? [("UV Set", "UvSN"), ("Filter", "TFT"), ("Border U", "TBUT")]
            : layer.tag == "TR" ? [("Color", "TCCT"), ("Filter", "TFT")]
            : layer.tag == "TP" ? [("Filter", "TFT"), ("Border", "TBT")]
            : [("UV Set", "UvSN"), ("Filter", "TFT"), ("Border U", "TBUT")]
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(wired >= 0 && wired < textures ? Color(red: 0.95, green: 0.55, blue: 0.75) : Theme.gray(0.14))
                    .overlay(Circle().stroke(Color(red: 0.95, green: 0.55, blue: 0.75), lineWidth: 1.5))
                    .frame(width: 10, height: 10)
                    .contentShape(Rectangle().inset(by: -8))
                    .onTapGesture { if wired >= 0 { setTexture(layer, -1) } }
                    .help(wired >= 0 ? "Click to stop using a texture here" : "Drag a texture here")
                    .offset(x: -13)
                Text(layer.node.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.white).lineLimit(1)
                Spacer(minLength: 0)
                if let enabled = field(layer, "bEna") {
                    Image(systemName: on ? "checkmark.square.fill" : "square").font(.system(size: 11)).foregroundStyle(Color.white)
                        .contentShape(Rectangle().inset(by: -4))
                        .onTapGesture { document.commit(enabled, from: enabled.read(), to: .bool(!on)) }
                        .help("Enabled")
                }
            }
            .padding(.horizontal, 9)
            .frame(height: AvfxMaterialView.header)
            .background((layer.tag.hasPrefix("TC") ? Color(red: 0.30, green: 0.62, blue: 0.45) : Color(red: 0.55, green: 0.42, blue: 0.75)).opacity(on ? 0.9 : 0.4))
            VStack(spacing: 2) {
                ForEach(rows, id: \.1) { row in summary(row.0, field(layer, row.1)) }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .opacity(on ? 1 : 0.5)
            Spacer(minLength: 0)
        }
        .frame(width: AvfxMaterialView.layerWidth, height: AvfxMaterialView.layerHeight, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.gray(0.19)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(chosen ? AvfxMaterialView.orange : Color.black.opacity(0.55), lineWidth: chosen ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = layer.node.id }
        .help("Click to see every field of this layer in Properties")
    }

    private func outputNode(_ particle: OutlineNode, _ list: [Layer]) -> some View {
        let fields = document.sections(for: particle).flatMap(\.fields)
        let chosen = document.selectionID == particle.id
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(particle.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.white).lineLimit(1)
                Text(particle.detail).font(.system(size: 9)).foregroundStyle(Color.white.opacity(0.7)).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(height: AvfxMaterialView.header)
            .background(Color(red: 0.85, green: 0.52, blue: 0.25).opacity(0.9))
            VStack(spacing: 0) {
                ForEach(Array(list.enumerated()), id: \.offset) { _, layer in
                    HStack(spacing: 5) {
                        Circle().fill(isOn(layer) ? Color(white: 0.8) : Theme.gray(0.14)).overlay(Circle().stroke(Color(white: 0.8), lineWidth: 1.5))
                            .frame(width: 9, height: 9).offset(x: -13)
                        Text(layer.node.title).font(Theme.small).foregroundStyle(isOn(layer) ? Theme.text : Theme.dim)
                        Spacer(minLength: 0)
                    }
                    .frame(height: 20)
                }
                Rectangle().fill(Theme.line).frame(height: 1).padding(.vertical, 4)
                ForEach([("Draw Mode", "RMT"), ("Culling", "CulT")], id: \.1) { row in
                    HStack(spacing: 6) {
                        Text(row.0).font(Theme.small).foregroundStyle(Theme.dim).frame(width: 64, alignment: .trailing)
                        if let field = fields.first(where: { $0.tag == row.1 }) { FieldControl(document: document, field: field) }
                    }
                    .frame(height: 22)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
        }
        .frame(width: AvfxMaterialView.outputWidth, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 7).fill(Theme.gray(0.19)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(chosen ? AvfxMaterialView.orange : Color.black.opacity(0.55), lineWidth: chosen ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture { document.selectionID = particle.id }
    }

    private func drawWires(_ context: inout GraphicsContext, _ list: [Layer], _ slots: [TextureSlot]) {
        let pink = Color(red: 0.95, green: 0.55, blue: 0.75)
        for (index, layer) in list.enumerated() {
            let input = CGPoint(x: layerPoint(index).x, y: layerPoint(index).y + AvfxMaterialView.header / 2)
            for from in textureIndices(layer) where from < slots.count {
                let start = CGPoint(x: texturePoint(from).x + AvfxMaterialView.textureWidth, y: texturePoint(from).y + AvfxMaterialView.header / 2)
                let path = curve(start, input)
                context.stroke(path, with: .color(Color.black.opacity(0.45)), lineWidth: 4)
                context.stroke(path, with: .color(pink.opacity(isOn(layer) ? 1 : 0.35)), lineWidth: 2)
            }
            let out = CGPoint(x: layerPoint(index).x + AvfxMaterialView.layerWidth, y: layerPoint(index).y + AvfxMaterialView.header / 2)
            let target = CGPoint(x: outputPoint().x, y: outputPoint().y + AvfxMaterialView.header + 5 + CGFloat(index) * 20 + 10)
            let path = curve(out, target)
            context.stroke(path, with: .color(Color.black.opacity(0.45)), lineWidth: 4)
            context.stroke(path, with: .color(Color(white: 0.8).opacity(isOn(layer) ? 1 : 0.25)), style: StrokeStyle(lineWidth: 2, dash: isOn(layer) ? [] : [5, 4]))
        }
        if let wire, wire.texture < slots.count {
            let start = CGPoint(x: texturePoint(wire.texture).x + AvfxMaterialView.textureWidth, y: texturePoint(wire.texture).y + AvfxMaterialView.header / 2)
            let hit = layerAt(wire.end, list) != nil
            context.stroke(curve(start, wire.end), with: .color(hit ? AvfxMaterialView.orange : Color.white.opacity(0.75)),
                           style: StrokeStyle(lineWidth: 2, dash: hit ? [] : [5, 4]))
        }
    }

    var body: some View {
        let _ = document.revision
        if let particle {
            let list = layers(particle)
            let slots = document.textureSlots
            let used = Set(list.flatMap(textureIndices))
            let absent = document.missingFields(for: particle).filter { AvfxMaterialView.layerTitles.contains($0.title) }
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle").font(.system(size: 10)).foregroundStyle(Theme.dim)
                    Text("How \(particle.title) is drawn: each layer reads one texture, the layers combine into the particle. Drag from a texture to a layer to change its texture. Click a node to edit all its fields in Properties.")
                        .font(Theme.small).foregroundStyle(Theme.dim).lineLimit(2)
                    Spacer(minLength: 4)
                    ForEach(absent) { item in
                        HStack(spacing: 3) {
                            Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                            Text(item.title).font(Theme.small).lineLimit(1)
                        }
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(RoundedRectangle(cornerRadius: 4).stroke(Theme.dim.opacity(0.5), lineWidth: 1))
                        .contentShape(Rectangle())
                        .onTapGesture { item.create() }
                        .help("This layer is not in the file yet. Click to add it")
                    }
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Theme.panel)
                ZStack(alignment: .topLeading) {
                    Canvas { context, _ in drawWires(&context, list, slots) }
                    ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                        textureNode(index, slot, used: used.contains(index)).offset(x: texturePoint(index).x, y: texturePoint(index).y)
                    }
                    ForEach(Array(list.enumerated()), id: \.offset) { index, layer in
                        layerNode(index, layer, textures: slots.count).offset(x: layerPoint(index).x, y: layerPoint(index).y)
                    }
                    outputNode(particle, list).offset(x: outputPoint().x, y: outputPoint().y)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Theme.gray(0.125))
                .clipped()
                .coordinateSpace(name: "avfxMaterial")
                .background(ScrollMonitor(onScroll: { delta, _, _ in pan = CGSize(width: pan.width + delta.width, height: pan.height + delta.height) },
                                          onMagnify: { _, _ in }))
                HStack(spacing: 14) {
                    Text("TEXTURES \(slots.count)").foregroundStyle(Theme.dim)
                    Text("LAYERS \(list.filter(isOn).count) ON OF \(list.count)").foregroundStyle(Theme.dim)
                    Spacer(minLength: 4)
                    Text("These are the particle's real fields; the game has no custom shaders for effects.").foregroundStyle(Theme.dim)
                }
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 22)
                .background(Theme.header)
            }
        }
    }
}
