import SwiftUI

struct ExportModSheet: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @AppStorage("mod.author") private var author = ""
    @State private var name = ""
    @State private var version = "1.0.0"
    @State private var details = "Exported from FViewer"
    @State private var gamePath = ""
    @State private var included: Set<String> = []
    @State private var prepared = false

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 110, alignment: .trailing)
            content()
        }
    }

    var body: some View {
        let slots = document.textureSlots
        let problem = PenumbraExport.problem(in: gamePath) ?? (name.trimmingCharacters(in: .whitespaces).isEmpty ? "Give the mod a name" : nil)
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox").foregroundStyle(Theme.text)
                Text("Export Penumbra Mod").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color(white: 0.157))
            ScrollView {
                VStack(spacing: 6) {
                    Panel(title: "Mod") {
                        row("Name") { TextValueField(value: name) { name = $0 } }
                        row("Author") { TextValueField(value: author) { author = $0 } }
                        row("Version") { TextValueField(value: version) { version = $0 } }
                        row("Description") { TextValueField(value: details) { details = $0 } }
                    }
                    Panel(title: "Effect") {
                        row("Replaces") { TextValueField(value: gamePath) { gamePath = $0 } }
                        Text("The game path this effect is loaded from. \(document.title) is written there inside the mod, in its current state.")
                            .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Panel(title: "Textures", trailing: "\(included.count) / \(slots.count)") {
                        if slots.isEmpty { Text("This effect has no textures").font(Theme.font).foregroundStyle(Theme.dim) }
                        ForEach(slots) { slot in
                            let found = app.textureURL(slot.path) != nil
                            HStack(spacing: 6) {
                                CheckBox(isOn: included.contains(slot.path), label: slot.path) { on in
                                    if on, found { included.insert(slot.path) } else { included.remove(slot.path) }
                                }
                                if !found { Text("not found").font(Theme.small).foregroundStyle(Color.orange) }
                            }
                            .opacity(found ? 1 : 0.6)
                        }
                        Text("Tick the textures you changed. Unticked textures keep coming from the game.")
                            .font(Theme.small).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 300, maxHeight: 520)
            HStack(spacing: 8) {
                if let problem { Text(problem).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1) }
                Spacer()
                SegmentButton(title: "Cancel", active: false) { app.modExport = false }
                SegmentButton(title: "Export…", active: problem == nil) {
                    guard problem == nil else { return }
                    let mod = ModDescription(name: name, author: author, version: version, description: details)
                    app.modExport = false
                    app.exportMod(mod, effectPath: gamePath, textures: Array(included))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color(white: 0.157))
        }
        .frame(width: 560)
        .background(Theme.panel)
        .preferredColorScheme(.dark)
        .onAppear {
            guard !prepared else { return }
            prepared = true
            var base = document.url.deletingPathExtension().lastPathComponent
            if document.isEditedCopy { base.removeLast(EffectDocument.editSuffix.count) }
            name = base
            gamePath = PenumbraExport.guessEffectPath(document)
            included = Set(slots.filter { app.isCustomTexture($0.path) }.map(\.path))
        }
    }
}
