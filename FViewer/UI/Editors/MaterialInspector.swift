import SwiftUI
import VfxCore

struct MaterialInspector: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let particle: String
    let graph: MaterialGraph?
    @Binding var selection: Set<String>
    @Binding var previewPin: String?
    @State private var libraryToken = 0

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 6) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).minimumScaleFactor(0.8).frame(width: 62, alignment: .trailing)
            content()
        }
    }

    private func value(_ node: MaterialNode, _ name: String) -> Double {
        node.params?[name] ?? MaterialGraph.kind(of: node.type)?.params.first { $0.name == name }?.value ?? 0
    }

    private func setParams(_ node: MaterialNode, _ values: [String: Double], _ title: String) {
        document.editMaterial(title, in: particle) { graph in
            guard let index = graph.nodes.firstIndex(where: { $0.id == node.id }) else { return }
            var params = graph.nodes[index].params ?? [:]
            for (name, value) in values { params[name] = value }
            graph.nodes[index].params = params
        }
    }

    private func saveToLibrary(_ graph: MaterialGraph) {
        let alert = NSAlert()
        alert.messageText = "Save Material"
        alert.informativeText = "The graph is saved under this name and can be applied to any particle of a 2D effect."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 22))
        field.stringValue = document.node(particle)?.title ?? "Material"
        alert.accessoryView = field
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        MaterialLibrary.save(graph, name: field.stringValue)
        libraryToken += 1
    }

    private func share() {
        let alert = NSAlert()
        alert.messageText = "Share Material"
        alert.informativeText = "The graph becomes a material of this effect. Other particles can use it and keep their own parameter values."
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 22))
        var name = document.node(particle)?.title ?? "Material"
        var index = 2
        while document.sharedMaterialNames.contains(name) {
            name = (document.node(particle)?.title ?? "Material") + " \(index)"
            index += 1
        }
        field.stringValue = name
        alert.accessoryView = field
        alert.addButton(withTitle: "Share")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        document.shareMaterial(field.stringValue, in: particle)
    }

    private func resetButton(_ name: String) -> some View {
        Image(systemName: "arrow.uturn.backward").font(.system(size: 9, weight: .bold)).foregroundStyle(Theme.changed).frame(width: 16, height: 18)
            .contentShape(Rectangle()).onTapGesture { document.setMaterialOverride(name, nil, in: particle) }.help("Reset to the material's own value")
    }

    @ViewBuilder private func preview(_ graph: MaterialGraph) -> some View {
        let chosen = selection.count == 1 ? graph.nodes.first { selection.contains($0.id) } : nil
        let target = chosen ?? graph.nodes.first { $0.type == "output" }
        if let target, let kind = MaterialGraph.kind(of: target.type) {
            let pin = kind.outputs.isEmpty ? nil : (previewPin.flatMap { kind.outputs.contains($0) ? $0 : nil } ?? kind.outputs[0])
            Panel(title: "Preview", trailing: target.type == "output" ? "final" : kind.title, memory: "material.preview") {
                let resolved = document.resolvedMaterial(particle)
                MaterialPreviewImage(graph: resolved?.nodes.contains(where: { $0.id == target.id }) == true ? resolved ?? graph : graph, node: target.id, pin: pin,
                                     base: document.materialBaseTexture(particle), layers: document.materialLayers(particle), light: document.materialLight, side: 88)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 190)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.5), lineWidth: 1))
                if kind.outputs.count > 1 {
                    HStack(spacing: 2) {
                        ForEach(kind.outputs, id: \.self) { name in
                            SegmentButton(title: name, active: pin == name) { previewPin = name }
                        }
                        Spacer(minLength: 0)
                    }
                }
                Text(target.type == "output" ? "Select a node to preview what it outputs." : "Showing the output of the selected node.")
                    .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private func settings(_ graph: MaterialGraph) -> some View {
        let blend = document.materialBlend(particle)
        Panel(title: "Material", trailing: document.node(particle)?.title ?? "", memory: "material.settings") {
            HStack(spacing: 1) {
                Text("Blend").font(Theme.font).foregroundStyle(Theme.text).padding(.trailing, 5)
                ForEach([("normal", "Normal"), ("add", "Add"), ("screen", "Screen"), ("opaque", "Opaque")], id: \.0) { entry in
                    Text(entry.1).font(Theme.small).foregroundStyle(blend == entry.0 ? Color.white : Theme.text).lineLimit(1).fixedSize()
                        .padding(.horizontal, 6).frame(height: 20)
                        .background(RoundedRectangle(cornerRadius: 4).fill(blend == entry.0 ? Theme.accent : Theme.gray(0.26)))
                        .contentShape(Rectangle())
                        .onTapGesture { document.setMaterialBlend(entry.0, in: particle) }
                }
                Spacer(minLength: 0)
            }
            .help("How the particle is mixed with what is behind it. Opaque ignores alpha; combine it with an opacity mask for cut-outs")
            if let output = graph.nodes.first(where: { $0.type == "output" }) {
                let masked = graph.links.contains { $0.to == output.id && $0.input == "opacityMask" }
                row("Mask Clip") {
                    NumberField(label: nil, value: value(output, "clip"), step: 0.005, digits: 3, onLive: { _ in },
                                onCommit: { _, next in setParams(output, ["clip": min(max(next, 0), 1)], "Set Mask Clip") })
                }
                .opacity(masked ? 1 : 0.4)
                .help(masked ? "Pixels whose opacity mask is below this value are cut out" : "Wire the Output's opacityMask input to cut pixels out")
            }
            if let shared = document.materialUse(particle) {
                row("Shared") {
                    Text(shared).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                    Text("× \(document.materialUsers(shared).count)").font(Theme.small).foregroundStyle(Theme.dim)
                    Spacer(minLength: 0)
                }
            }
            FlowLayout(spacing: 4) {
                if document.materialUse(particle) == nil {
                    SegmentButton(title: "Share…", active: false) { share() }
                } else {
                    SegmentButton(title: "Make Unique", active: false) { document.makeMaterialUnique(in: particle) }
                }
                SegmentButton(title: "Copy", active: false) { MaterialLibrary.copiedMaterial = document.resolvedMaterial(particle) ?? graph }
                SegmentButton(title: "Save…", active: false) { saveToLibrary(graph) }
                SegmentButton(title: "Remove", active: false) {
                    document.removeMaterial(in: particle)
                    selection = []
                }
                HelpBadge(text: "Share… turns the graph into a material of this effect that several particles can use; each keeps its own parameter values. Make Unique gives this particle its own copy again. Copy keeps the graph for pasting onto another particle, Save… stores it in the library, Remove returns the particle to its plain texture and layers.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private func sceneLight(_ graph: MaterialGraph) -> some View {
        if document.resolvedMaterial(particle)?.usesLighting == true {
            let light = document.materialLight
            let direction = light.directionVector, tint = light.colorVector, fill = light.ambientVector
            let azimuth = Double(atan2(direction.x, direction.z)) * 180 / .pi
            let elevation = Double(asin(min(max(-direction.y, -1), 1))) * 180 / .pi
            Panel(title: "Scene Light", trailing: "effect", memory: "material.light") {
                row("Azimuth") {
                    NumberField(label: nil, value: azimuth, suffix: "°", step: 1, digits: 0, onLive: { _ in },
                                onCommit: { _, next in setDirection(azimuth: next, elevation: elevation) })
                }
                row("Elevation") {
                    NumberField(label: nil, value: elevation, suffix: "°", step: 1, digits: 0, onLive: { _ in },
                                onCommit: { _, next in setDirection(azimuth: azimuth, elevation: min(max(next, -89), 89)) })
                }
                row("Color") {
                    ColorField(color: SIMD4(Double(tint.x), Double(tint.y), Double(tint.z), 1), alpha: false, onLive: { _ in },
                               onCommit: { _, next in document.setMaterialLight("color", [next.x, next.y, next.z], title: "Set Light Color") })
                }
                row("Ambient") {
                    ColorField(color: SIMD4(Double(fill.x), Double(fill.y), Double(fill.z), 1), alpha: false, onLive: { _ in },
                               onCommit: { _, next in document.setMaterialLight("ambient", [next.x, next.y, next.z], title: "Set Ambient Color") })
                }
                Text("One light for the whole effect, read by the Lighting nodes. Azimuth turns it around the screen, elevation lifts it above.")
                    .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func setDirection(azimuth: Double, elevation: Double) {
        let a = azimuth * .pi / 180, e = elevation * .pi / 180
        document.setMaterialLight("direction", [sin(a) * cos(e), -sin(e), cos(a) * cos(e)], title: "Set Light Direction")
    }

    @ViewBuilder private func node(_ graph: MaterialGraph) -> some View {
        if selection.count == 1, let node = graph.nodes.first(where: { selection.contains($0.id) }), let kind = MaterialGraph.kind(of: node.type), node.type != "output" {
            Panel(title: "Node", trailing: kind.title, memory: "material.node") {
                row("Name") {
                    TextValueField(value: node.name ?? "") { next in
                        let clean = next.trimmingCharacters(in: .whitespaces)
                        document.editMaterial(clean.isEmpty ? "Clear Node Name" : "Rename Node", in: particle) { graph in
                            if let index = graph.nodes.firstIndex(where: { $0.id == node.id }) { graph.nodes[index].name = clean.isEmpty ? nil : clean }
                        }
                    }
                }
                Text(kind.help + (["float", "color", "texture", "gradient"].contains(node.type) ? "\nA named constant, colour, gradient or texture is listed under Parameters." : ""))
                    .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func parameters(_ graph: MaterialGraph) -> some View {
        let named = graph.nodes.filter { $0.name?.isEmpty == false && ["float", "color", "texture"].contains($0.type) }
        let instance = document.materialUse(particle) != nil
        let overrides = instance ? document.materialOverrides(particle) : [:]
        let live = graph.applying(overrides)
        Panel(title: "Parameters", trailing: instance && !overrides.isEmpty ? "\(overrides.count) of \(named.count) overridden" : "\(named.count)", memory: "material.parameters") {
            if named.isEmpty {
                Text("Give a Constant, Color or Texture Sample node a name to list it here for quick tuning.")
                    .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            } else if instance {
                Text("Values set here belong to this particle only.").font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(named, id: \.id) { original in
                let node = live.nodes.first { $0.id == original.id } ?? original
                let name = node.name ?? ""
                row(name) {
                    if node.type == "float" {
                        NumberField(label: nil, value: value(node, "value"), step: 0.01, onLive: { _ in },
                                    onCommit: { _, next in
                                        if instance {
                                            document.setMaterialOverride(name, JSONNode(.number(next)), in: particle)
                                        } else {
                                            setParams(node, ["value": next], "Set " + name)
                                        }
                                    })
                    } else if node.type == "color" {
                        ColorField(color: SIMD4(value(node, "r"), value(node, "g"), value(node, "b"), value(node, "a")), alpha: true, onLive: { _ in },
                                   onCommit: { _, next in
                                       if instance {
                                           document.setMaterialOverride(name, JSONNode(.array([next.x, next.y, next.z, next.w].map { JSONNode(.number($0)) })), in: particle)
                                       } else {
                                           setParams(node, ["r": next.x, "g": next.y, "b": next.z, "a": next.w], "Set " + name)
                                       }
                                   })
                    } else {
                        Menu {
                            ForEach(document.textureSlots.map(\.name), id: \.self) { texture in
                                Button(texture) {
                                    if instance {
                                        document.setMaterialOverride(name, JSONNode(.object([JSONMember(key: "texture", node: JSONNode(.string(texture)))])), in: particle)
                                    } else {
                                        document.editMaterial("Set " + name, in: particle) { graph in
                                            if let index = graph.nodes.firstIndex(where: { $0.id == node.id }) { graph.nodes[index].texture = texture }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(node.texture ?? "—").font(Theme.small).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.middle)
                        }
                        .menuStyle(.borderlessButton)
                    }
                    if instance, overrides[name] != nil { resetButton(name) }
                }
            }
        }
    }

    private var library: some View {
        let _ = libraryToken
        let saved = MaterialLibrary.saved
        return Panel(title: "Library", trailing: "\(saved.count)", memory: "material.library") {
            if let copied = MaterialLibrary.copiedMaterial {
                SegmentButton(title: "Paste Copied Material", active: false) {
                    document.setMaterial(copied, title: "Paste Material", in: particle)
                    selection = []
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            let shared = document.sharedMaterialNames
            if !shared.isEmpty {
                Text("IN THIS EFFECT").font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
                ForEach(shared, id: \.self) { name in
                    let current = document.materialUse(particle) == name
                    HStack(spacing: 6) {
                        Image(systemName: current ? "checkmark" : "link").font(.system(size: 9)).foregroundStyle(current ? Theme.text : Theme.dim)
                        Text(name).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                        Spacer(minLength: 0)
                        Text("× \(document.materialUsers(name).count)").font(Theme.small).foregroundStyle(Theme.dim)
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(current ? Theme.selection : Theme.field.opacity(0.45)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        document.useSharedMaterial(name, in: particle)
                        selection = []
                    }
                    .help("Use this shared material on the selected particle")
                }
                Text("SAVED").font(.system(size: 9, weight: .medium)).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
            }
            if saved.isEmpty {
                Text("Saved materials appear here and can be applied to any particle.").font(Theme.small).foregroundStyle(Theme.dim)
                    .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(saved, id: \.url) { entry in
                HStack(spacing: 6) {
                    Image(systemName: "circle.hexagongrid").font(.system(size: 9)).foregroundStyle(Theme.dim)
                    Text(entry.name).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(Theme.dim).frame(width: 14, height: 18).contentShape(Rectangle())
                        .onTapGesture {
                            try? FileManager.default.trashItem(at: entry.url, resultingItemURL: nil)
                            libraryToken += 1
                        }
                        .help("Move this saved material to the Trash")
                }
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.45)))
                .contentShape(Rectangle())
                .onTapGesture {
                    if let loaded = MaterialLibrary.load(entry.url) {
                        document.setMaterial(loaded, title: "Apply Material " + entry.name, in: particle)
                        selection = []
                    }
                }
                .help("Apply this material to the selected particle")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                if let graph {
                    preview(graph)
                    settings(graph)
                    sceneLight(graph)
                    node(graph)
                    parameters(graph)
                }
                library
            }
            .padding(.vertical, 8)
        }
        .frame(width: 244)
        .background(Theme.panel)
    }
}
