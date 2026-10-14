import SwiftUI

struct ExportModSheet: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    @AppStorage("mod.author") private var author = ""
    @AppStorage("mod.name") private var name = ""
    @State private var version = "1.0.0"
    @State private var details = "Exported from FViewer"
    @State private var paths: [UUID: String] = [:]
    @State private var effects: Set<UUID> = []
    @State private var included: Set<String> = []
    @State private var prepared = false
    @AppStorage("mod.format") private var format = 0
    @AppStorage("mod.grouped") private var grouped = false
    @State private var group = ModGroup(name: "Variant", options: ["Option 1", "Option 2"])

    private var placements: [FieldChoice] {
        [FieldChoice(name: "Always", value: 0)] + group.options.enumerated().map { FieldChoice(name: $0.element, value: $0.offset + 1) }
    }

    private var usesGroup: Bool { grouped && format == 0 }

    @ViewBuilder private var groupPanel: some View {
        Panel(title: "Options") {
            HStack(spacing: 6) {
                CheckBox(isOn: grouped, label: "Option group") { grouped = $0 }
                Spacer()
                HelpBadge(text: "Files set to an option are only used when that option is picked in Penumbra. Files set to Always belong to the mod itself. Two effects may share a game path when they sit in different options.")
            }
            if grouped {
                row("Group") { TextValueField(value: group.name) { group.name = $0 } }
                row("Type") {
                    SegmentButton(title: "Single", active: !group.multi) { group.multi = false }
                    SegmentButton(title: "Multi", active: group.multi) { group.multi = true }
                    Spacer()
                }
                ForEach(Array(group.options.enumerated()), id: \.offset) { index, option in
                    row(index == 0 ? "Default" : "Option \(index + 1)") {
                        TextValueField(value: option) { group.options[index] = $0.trimmingCharacters(in: .whitespaces) }
                        HeaderButton(symbol: "minus", help: "Remove this option") { removeOption(index) }
                    }
                }
                row("") {
                    SegmentButton(title: "Add Option", active: false) { group.options.append("Option \(group.options.count + 1)") }
                    Spacer()
                }
            }
        }
    }

    private func removeOption(_ index: Int) {
        guard group.options.count > 1 else { return }
        group.options.remove(at: index)
        func shift(_ value: Int) -> Int { value == index + 1 ? 0 : value > index + 1 ? value - 1 : value }
        group.effects = group.effects.mapValues(shift)
        group.textures = group.textures.mapValues(shift)
    }

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).frame(width: 110, alignment: .trailing)
            content()
        }
    }

    private var candidates: [EffectDocument] { app.openDocuments.filter { $0.format == .avfx } }

    private var slots: [String] {
        var seen: Set<String> = []
        return candidates.filter { effects.contains($0.id) }.flatMap { $0.textureSlots.map(\.path) }.filter { seen.insert($0).inserted }
    }

    private var problem: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "Give the mod a name" }
        if effects.isEmpty { return "Tick at least one effect" }
        for effect in candidates where effects.contains(effect.id) {
            if let issue = PenumbraExport.problem(in: paths[effect.id] ?? "") { return "\(effect.title): \(issue)" }
        }
        if usesGroup, let issue = group.problem { return issue }
        return nil
    }

    var body: some View {
        let textures = slots
        let issue = problem
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox").foregroundStyle(Theme.text)
                Text("Export Mod").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Theme.gray(0.157))
            ScrollView {
                VStack(spacing: 6) {
                    Panel(title: "Mod") {
                        row("Name") { TextValueField(value: name) { name = $0 } }
                        row("Author") { TextValueField(value: author) { author = $0 } }
                        row("Version") { TextValueField(value: version) { version = $0 } }
                        row("Description") { TextValueField(value: details) { details = $0 } }
                        row("Format") {
                            SegmentButton(title: "Penumbra .pmp", active: format == 0) { format = 0 }
                            SegmentButton(title: "TexTools .ttmp2", active: format == 1) { format = 1 }
                            Spacer()
                        }
                    }
                    if format == 0 { groupPanel }
                    Panel(title: "Effects", trailing: "\(effects.count) / \(candidates.count)") {
                        HStack {
                            Spacer()
                            HelpBadge(text: "Every ticked effect is written into the mod at its game path, in its current state. The path is remembered with the effect.")
                        }
                        ForEach(candidates) { effect in
                            HStack(spacing: 6) {
                                CheckBox(isOn: effects.contains(effect.id), label: effect.title) { on in
                                    if on {
                                        effects.insert(effect.id)
                                        included.formUnion(effect.textureSlots.map(\.path).filter { app.isCustomTexture($0) })
                                    } else {
                                        effects.remove(effect.id)
                                    }
                                }
                                .frame(width: 180)
                                TextValueField(value: paths[effect.id] ?? "") { paths[effect.id] = $0 }
                                if usesGroup {
                                    ChoiceField(choices: placements, value: group.effects[effect.id] ?? 0) { group.effects[effect.id] = $0 }.frame(width: 110)
                                }
                            }
                        }
                    }
                    Panel(title: "Textures", trailing: "\(included.intersection(textures).count) / \(textures.count)") {
                        HStack {
                            Spacer()
                            HelpBadge(text: "Tick the textures you changed. Unticked textures keep coming from the game.")
                        }
                        ForEach(textures, id: \.self) { path in
                            let found = app.textureURL(path) != nil
                            HStack(spacing: 6) {
                                CheckBox(isOn: included.contains(path), label: path) { on in
                                    if on, found { included.insert(path) } else { included.remove(path) }
                                }
                                if !found { HelpBadge(text: "This texture was not found in the open folder.", symbol: "exclamationmark.triangle", tint: .orange) }
                                if usesGroup, found {
                                    ChoiceField(choices: placements, value: group.textures[path] ?? 0) { group.textures[path] = $0 }.frame(width: 110)
                                }
                            }
                            .opacity(found ? 1 : 0.6)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(minHeight: 320, maxHeight: 560)
            HStack(spacing: 8) {
                if let issue { Text(issue).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1) }
                Spacer()
                SegmentButton(title: "Cancel", active: false) { app.modExport = false }
                SegmentButton(title: "Export…", active: issue == nil) {
                    guard issue == nil else { return }
                    let chosen = candidates.filter { effects.contains($0.id) }.map { (document: $0, path: paths[$0.id] ?? "") }
                    for effect in chosen { effect.document.gamePath = PenumbraExport.normalized(effect.path) }
                    let mod = ModDescription(name: name, author: author, version: version, description: details)
                    let picked = Array(included.intersection(textures))
                    app.modExport = false
                    app.exportMod(mod, effects: chosen, textures: picked, texTools: format == 1, group: usesGroup ? group : nil)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Theme.gray(0.157))
        }
        .frame(width: 620)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
        .onAppear {
            guard !prepared else { return }
            prepared = true
            if name.isEmpty {
                var base = document.url.deletingPathExtension().lastPathComponent
                if document.isEditedCopy, base.hasSuffix(EffectDocument.editSuffix) { base.removeLast(EffectDocument.editSuffix.count) }
                name = base
            }
            for effect in candidates { paths[effect.id] = effect.gamePath.isEmpty ? PenumbraExport.guessEffectPath(effect) : effect.gamePath }
            effects = [document.id]
            included = Set(document.textureSlots.map(\.path).filter { app.isCustomTexture($0) })
        }
    }
}
