import SwiftUI

struct LayerTexturePicker: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let layer: AvfxBlock

    private func available(_ path: String) -> Bool {
        app.textureURL(path) != nil || app.game?.contains(path) == true
    }

    var body: some View {
        let slots = document.textureSlots
        let current = document.layerTexture(layer)
        HStack(spacing: 6) {
            Text("Texture").font(Theme.font).foregroundStyle(Theme.dim).frame(width: 60, alignment: .trailing)
            Menu {
                Button { document.setLayerTexture(layer, index: -1) } label: {
                    if current < 0 { Label("None", systemImage: "checkmark") } else { Text("None") }
                }
                if !slots.isEmpty { Divider() }
                ForEach(Array(slots.enumerated()), id: \.offset) { index, slot in
                    Button { document.setLayerTexture(layer, index: index) } label: {
                        if index == current { Label("\(index) · " + slot.name, systemImage: "checkmark") } else { Text("\(index) · " + slot.name) }
                    }
                }
                Divider()
                Menu("From Library") {
                    ForEach(Array(app.textureLibrary.enumerated()), id: \.offset) { _, entry in
                        Button("★ " + entry.name) { document.setLayerTexture(layer, path: entry.path) }
                    }
                    if !app.textureLibrary.isEmpty { Divider() }
                    ForEach(Array(AppModel.usefulTextures.enumerated()), id: \.offset) { _, entry in
                        Button(entry.name + (available(entry.path) ? "" : " · not found")) { document.setLayerTexture(layer, path: entry.path) }
                    }
                }
                Button("Import Image…") { app.importLayerTexture(layer, in: document) }
            } label: {
                HStack(spacing: 4) {
                    Text(slots.indices.contains(current) ? slots[current].name : "None").lineLimit(1).truncationMode(.middle)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
                }
                .font(Theme.font)
                .foregroundStyle(current < 0 ? Theme.changed : Theme.text)
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.gray(0.24), lineWidth: 1))
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .help("The picture this layer draws. Picking one from the library or an image adds it to the effect's textures")
        }
    }
}
