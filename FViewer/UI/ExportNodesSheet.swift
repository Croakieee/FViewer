import SwiftUI

struct ExportNodesSheet: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @State var selected: Set<String>
    @State private var withDependencies = true

    var body: some View {
        let nodes = document.exportableNodes
        let included = withDependencies ? document.dependencies(of: selected) : selected
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.text)
                Text("Export Nodes").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Text("\(included.count) of \(nodes.count)").font(Theme.small).foregroundStyle(Theme.dim)
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color(white: 0.157))
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(EffectDocument.exchangeTags, id: \.self) { tag in
                        let group = nodes.filter { $0.tag == tag }
                        if !group.isEmpty {
                            Panel(title: (EffectDocument.kindTitles[tag] ?? tag) + "s", trailing: "\(group.filter { included.contains($0.id) }.count) / \(group.count)") {
                                ForEach(group) { node in
                                    let picked = selected.contains(node.id)
                                    let implied = !picked && included.contains(node.id)
                                    HStack(spacing: 6) {
                                        CheckBox(isOn: picked || implied, label: node.title) { on in
                                            if on { selected.insert(node.id) } else { selected.remove(node.id) }
                                        }
                                        if implied { Text("dependency").font(Theme.small).foregroundStyle(Theme.dim) }
                                    }
                                    .opacity(implied ? 0.7 : 1)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 260, maxHeight: 460)
            HStack(spacing: 8) {
                CheckBox(isOn: withDependencies, label: "Export Dependencies") { withDependencies = $0 }
                    .frame(width: 170)
                    .help("Also export everything the selected nodes use, such as the textures of a particle. Indices inside the file are renumbered so it can be imported into any effect")
                SegmentButton(title: "All", active: false) { selected = Set(nodes.map(\.id)) }
                SegmentButton(title: "None", active: false) { selected = [] }
                Spacer()
                SegmentButton(title: "Cancel", active: false) { document.exportRequest = nil }
                SegmentButton(title: "Export…", active: !selected.isEmpty) {
                    let ids = included
                    document.exportRequest = nil
                    app.exportNodes(ids, withDependencies: withDependencies)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color(white: 0.157))
        }
        .frame(width: 440)
        .background(Theme.panel)
        .preferredColorScheme(.dark)
    }
}
