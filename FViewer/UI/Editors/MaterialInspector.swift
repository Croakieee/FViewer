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

    @ViewBuilder private func preview(_ graph: MaterialGraph) -> some View {
        let chosen = selection.count == 1 ? graph.nodes.first { selection.contains($0.id) } : nil
        let target = chosen ?? graph.nodes.first { $0.type == "output" }
        if let target, let kind = MaterialGraph.kind(of: target.type) {
            let pin = kind.outputs.isEmpty ? nil : (previewPin.flatMap { kind.outputs.contains($0) ? $0 : nil } ?? kind.outputs[0])
            Panel(title: "Preview", trailing: target.type == "output" ? "final" : kind.title, memory: "material.preview") {
                MaterialPreviewImage(graph: graph, node: target.id, pin: pin, base: document.materialBaseTexture(particle), side: 88)
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
            row("Blend") {
                HStack(spacing: 1) {
                    ForEach([("normal", "Normal"), ("add", "Add"), ("screen", "Screen")], id: \.0) { entry in
                        SegmentButton(title: entry.1, active: blend == entry.0) { document.setMaterialBlend(entry.0, in: particle) }
                    }
                    Spacer(minLength: 0)
                }
            }
            if let output = graph.nodes.first(where: { $0.type == "output" }) {
                let masked = graph.links.contains { $0.to == output.id && $0.input == "opacityMask" }
                row("Mask Clip") {
                    NumberField(label: nil, value: value(output, "clip"), step: 0.005, digits: 3, onLive: { _ in },
                                onCommit: { _, next in setParams(output, ["clip": min(max(next, 0), 1)], "Set Mask Clip") })
                }
                .opacity(masked ? 1 : 0.4)
                .help(masked ? "Pixels whose opacity mask is below this value are cut out" : "Wire the Output's opacityMask input to cut pixels out")
            }
            FlowLayout(spacing: 4) {
                SegmentButton(title: "Copy", active: false) { MaterialLibrary.copiedMaterial = graph }
                SegmentButton(title: "Save…", active: false) { saveToLibrary(graph) }
                SegmentButton(title: "Remove", active: false) {
                    document.removeMaterial(in: particle)
                    selection = []
                }
                HelpBadge(text: "Copy keeps the whole graph so it can be pasted onto another particle. Save… stores it in the material library. Remove returns the particle to its plain texture and layers.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
        Panel(title: "Parameters", trailing: "\(named.count)", memory: "material.parameters") {
            if named.isEmpty {
                Text("Give a Constant, Color or Texture Sample node a name to list it here for quick tuning.")
                    .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
            }
            ForEach(named, id: \.id) { node in
                row(node.name ?? "") {
                    if node.type == "float" {
                        NumberField(label: nil, value: value(node, "value"), step: 0.01, onLive: { _ in },
                                    onCommit: { _, next in setParams(node, ["value": next], "Set " + (node.name ?? "Parameter")) })
                    } else if node.type == "color" {
                        ColorField(color: SIMD4(value(node, "r"), value(node, "g"), value(node, "b"), value(node, "a")), alpha: true, onLive: { _ in },
                                   onCommit: { _, next in setParams(node, ["r": next.x, "g": next.y, "b": next.z, "a": next.w], "Set " + (node.name ?? "Parameter")) })
                    } else {
                        Text(node.texture ?? "—").font(Theme.small).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.middle)
                        Spacer(minLength: 0)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { selection = [node.id] }
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
