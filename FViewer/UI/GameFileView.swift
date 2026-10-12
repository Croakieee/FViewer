import AVFoundation
import Combine
import SwiftUI

final class GameFileDocument: ObservableObject {
    let url: URL
    let kind: GameFileKind
    let original: [UInt8]
    @Published var bytes: [UInt8]
    @Published var selection = 0
    @Published var block = 0
    @Published var note: String?
    private var player: AVAudioPlayer?

    init(url: URL) throws {
        self.url = url
        let data = [UInt8](try Data(contentsOf: url))
        original = data
        bytes = data
        kind = GameFiles.kind(of: url, bytes: data)
    }

    init(url: URL, bytes: [UInt8], kind: GameFileKind) {
        self.url = url
        self.kind = kind
        original = bytes
        self.bytes = bytes
    }

    var dirty: Bool { bytes != original }
    var tmbBlocks: [TmbBlock] { GameFiles.tmbBlocks(bytes) }

    func setInt(_ at: Int, _ value: Int) { GameFiles.put32(&bytes, at, UInt32(bitPattern: Int32(truncatingIfNeeded: value))) }
    func setShort(_ at: Int, _ value: Int) { GameFiles.put16(&bytes, at, value) }

    func setPath(item: TmbItem, field: Int, to text: String) {
        guard let current = GameFiles.offsetString(bytes, item: item, field: field) else { return }
        if GameFiles.setString(&bytes, at: current.at, old: current.text, new: text) {
            note = nil
        } else if !text.isEmpty, let owner = tmbBlocks.first(where: { item.offset >= $0.offset && item.offset < $0.offset + $0.size }),
                  let index = owner.items.firstIndex(where: { $0.offset == item.offset }),
                  let next = TmbCatalog.setString(bytes, block: owner, index: index, field: field, text: text) {
            bytes = next
            note = "The longer path was added at the end of the timeline"
        } else {
            note = "The path can be at most \(current.text.utf8.count) characters here"
        }
    }

    func setPoints(_ points: [EidPoint], new: Bool) { bytes = GameFiles.eidBytes(points, new: new, header: original) }

    func revert() {
        bytes = original
        note = nil
    }

    func play(_ audio: ScdAudio) {
        guard let wave = GameFiles.scdWave(bytes, audio) else {
            note = "\(audio.formatName) cannot be played here; export the stream instead"
            return
        }
        do {
            player = try AVAudioPlayer(data: Data(wave))
            player?.play()
            note = nil
        } catch {
            note = error.localizedDescription
        }
    }

    func stop() { player?.stop() }

    private var peakCache: [String: [Float]] = [:]

    func peaks(_ audio: ScdAudio, buckets: Int = 240) -> [Float] {
        let key = "\(audio.id).\(audio.offset).\(audio.dataLength).\(bytes.count)"
        if let cached = peakCache[key] { return cached }
        let samples = GameFiles.scdSamples(bytes, audio)
        var result = [Float](repeating: 0, count: samples.isEmpty ? 0 : buckets)
        if !samples.isEmpty {
            let step = max(1, samples.count / buckets)
            for bucket in 0..<buckets {
                var top: Int16 = 0
                var index = bucket * step
                let end = min(samples.count, index + step)
                while index < end {
                    let value = samples[index] == Int16.min ? Int16.max : abs(samples[index])
                    if value > top { top = value }
                    index += max(1, step / 64)
                }
                result[bucket] = Float(top) / 32767
            }
        }
        peakCache[key] = result
        return result
    }

    func replaceAudio(_ audio: ScdAudio, from source: URL) {
        do {
            let sound = try GameFiles.pcm(from: source)
            let aux = GameFiles.scdAux(bytes, audio)
            let auxBytes = aux > 0 ? Array(bytes[(audio.offset + 0x20)..<(audio.offset + 0x20 + aux)]) : []
            let entry = GameFiles.scdEntry(samples: sound.samples, channels: sound.channels, rate: sound.rate, flags: bytes.u32(audio.offset + 28), aux: auxBytes)
            guard let next = GameFiles.scdReplacing(bytes, index: audio.id, entry: entry) else {
                note = "This file keeps its sounds in an order this app cannot rebuild"
                return
            }
            bytes = next
            note = nil
        } catch {
            note = error.localizedDescription
        }
    }
}

struct GameFileView: View {
    @EnvironmentObject var app: AppModel

    var body: some View {
        Group {
            if let file = app.gameFile {
                GameFileContent(file: file)
            } else {
                HelpBadge(text: "Open a .tmb, .pap, .eid, .scd, .atch, .mtrl or any other game file with File → Game → Inspect Game File…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 820, minHeight: 480)
        .background(Theme.panel)
        .preferredColorScheme(Theme.scheme)
    }
}

private struct GameFileContent: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var file: GameFileDocument

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass").foregroundStyle(Theme.text)
                Text(file.url.lastPathComponent).font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1).truncationMode(.middle)
                Text("\(file.kind.rawValue.uppercased()) · \(file.bytes.count) bytes").font(Theme.small).foregroundStyle(Theme.dim)
                if file.dirty { ChangeDot() }
                Spacer(minLength: 8)
                if let note = file.note { Text(note).font(Theme.small).foregroundStyle(Color.orange).lineLimit(1) }
                if file.dirty {
                    SegmentButton(title: "Revert", active: false) { file.revert() }
                    SegmentButton(title: "Save Copy", active: true) { app.saveGameFile(file) }
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(Theme.gray(0.157))
            switch file.kind {
            case .tmb: TmbView(file: file, blocks: file.tmbBlocks, animations: [])
            case .pap: TmbView(file: file, blocks: file.tmbBlocks, animations: GameFiles.papAnimations(file.bytes))
            case .eid: EidView(file: file)
            case .scd: ScdView(file: file)
            case .atch: AtchView(file: file)
            case .other: RawFileView(file: file)
            }
        }
    }
}

private struct TmbView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var file: GameFileDocument
    let blocks: [TmbBlock]
    let animations: [PapAnimation]

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 150, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }

    var body: some View {
        let current = blocks.first { $0.id == file.block } ?? blocks.first
        let items = current?.items ?? []
        let item = items.first { $0.id == file.selection } ?? items.first
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if blocks.count > 1 || !animations.isEmpty {
                        ForEach(blocks, id: \.offset) { block in
                            let name = block.id < animations.count ? animations[block.id].name : "Timeline \(block.id)"
                            HStack(spacing: 5) {
                                Image(systemName: "film").font(.system(size: 9)).foregroundStyle(NodeTint.timeline.color).frame(width: 14)
                                Text(name).font(Theme.font).foregroundStyle(block.id == current?.id ? .white : Theme.text).lineLimit(1)
                                Spacer(minLength: 0)
                                Text("\(block.items.count)").font(Theme.small).foregroundStyle(Theme.dim)
                            }
                            .padding(.horizontal, 6)
                            .frame(height: 20)
                            .background(block.id == current?.id ? Theme.selection.opacity(0.6) : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                file.block = block.id
                                file.selection = 0
                            }
                        }
                        Rectangle().fill(Color.black.opacity(0.4)).frame(height: 1).padding(.vertical, 3)
                    }
                    ForEach(items, id: \.offset) { entry in
                        HStack(spacing: 5) {
                            Text(entry.magic).font(.system(size: 10, design: .monospaced)).foregroundStyle(entry.magic == "C012" || entry.magic == "C173" ? Theme.changed : Theme.dim)
                                .frame(width: 38, alignment: .leading)
                            Text(TmbCatalog.name(entry.magic)).font(Theme.font).foregroundStyle(entry.id == item?.id ? .white : Theme.text).lineLimit(1)
                            Spacer(minLength: 0)
                            Text(entry.itemID < 0 ? "" : "#\(entry.itemID) · \(entry.time)").font(Theme.small).foregroundStyle(Theme.dim)
                        }
                        .padding(.horizontal, 6)
                        .frame(height: 20)
                        .background(entry.id == item?.id ? Theme.selection : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { file.selection = entry.id }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(width: 270)
            .background(Theme.gray(0.157))
            ScrollView {
                VStack(spacing: 6) {
                    if !animations.isEmpty, let current, current.id < animations.count {
                        let animation = animations[current.id]
                        Panel(title: "Animation") {
                            row("Name") { Text(animation.name).font(Theme.font).foregroundStyle(Theme.text).textSelection(.enabled) }
                            row("Type") { Text("\(animation.type)").font(Theme.font).foregroundStyle(Theme.text) }
                            row("Havok Index") { Text("\(animation.havokIndex)").font(Theme.font).foregroundStyle(Theme.text) }
                            row("Face Animation") { Text(animation.face ? "Yes" : "No").font(Theme.font).foregroundStyle(Theme.text) }
                        }
                    }
                    if let item { detail(item) }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private func number(_ label: String, _ value: Double, integer: Bool, _ commit: @escaping (Double) -> Void) -> some View {
        row(label) {
            NumberField(label: nil, value: value, isInteger: integer, step: integer ? 1 : 0.01, onLive: { _ in }, onCommit: { _, v in commit(v) }).frame(width: 130)
        }
    }

    private func read(_ b: [UInt8], _ at: Int, _ size: Int) -> Int {
        switch size {
        case 1: return at < b.count ? Int(Int8(bitPattern: b[at])) : 0
        case 2: return GameFiles.i16(b, at)
        default: return GameFiles.i32(b, at)
        }
    }

    private func write(_ at: Int, _ size: Int, _ value: Int) {
        switch size {
        case 1: if at < file.bytes.count { file.bytes[at] = UInt8(bitPattern: Int8(truncatingIfNeeded: value)) }
        case 2: file.setShort(at, value)
        default: file.setInt(at, value)
        }
    }

    @ViewBuilder private func fieldRow(_ field: TmbFieldDef, _ item: TmbItem) -> some View {
        let b = file.bytes
        let at = item.offset + field.at
        switch field.type {
        case "Float":
            number(field.name, Double(GameFiles.f32(b, at)), integer: false) { GameFiles.put32(&file.bytes, at, Float($0).bitPattern) }
        case "Bool":
            row(field.name) { CheckBox(isOn: read(b, at, field.size) != 0, label: "") { write(at, field.size, $0 ? 1 : 0) }.frame(width: 40) }
        case "Enum" where !field.choices.isEmpty:
            row(field.name) { ChoiceField(choices: field.choices, value: read(b, at, field.size)) { write(at, field.size, $0) }.frame(width: 210) }
        case "OffsetString":
            if let path = GameFiles.offsetString(b, item: item, field: field.at) {
                row(field.name) {
                    TextValueField(value: path.text) { file.setPath(item: item, field: field.at, to: $0) }
                    if path.text.hasSuffix(".avfx") { SegmentButton(title: "Open", active: true) { app.openEffect(gamePath: path.text) } }
                }
            } else {
                row(field.name) { Text("not set").font(Theme.font).foregroundStyle(Theme.dim) }
            }
        case "OffsetFloat3", "OffsetAngle3", "OffsetFloat4":
            let offset = GameFiles.i32(b, at), count = min(max(GameFiles.i32(b, at + 4), 0), 4)
            let target = item.offset + 8 + offset
            if offset > 0, target + count * 4 <= b.count {
                let scale: Float = field.type == "OffsetAngle3" ? 180 / .pi : 1
                row(field.name) {
                    ForEach(0..<count, id: \.self) { index in
                        NumberField(label: nil, value: Double(GameFiles.f32(b, target + index * 4) * scale), suffix: scale == 1 ? "" : "°", step: 0.01,
                                    onLive: { _ in }, onCommit: { _, v in GameFiles.put32(&file.bytes, target + index * 4, (Float(v) / scale).bitPattern) })
                            .frame(width: 84)
                    }
                }
            } else {
                row(field.name) { Text("not set").font(Theme.font).foregroundStyle(Theme.dim) }
            }
        case "OffsetTimeline":
            row(field.name) {
                Text(TmbCatalog.idList(b, item: item, field: field.at).ids.map { "#\($0)" }.joined(separator: "  ")).font(Theme.font).foregroundStyle(Theme.text)
                    .lineLimit(2)
            }
        case "OffsetExtra":
            row(field.name) { Text(GameFiles.i32(b, at) == 0 ? "not set" : "present").font(Theme.font).foregroundStyle(Theme.dim) }
        default:
            number(field.name, Double(read(b, at, field.size)), integer: true) { write(at, field.size, Int($0)) }
        }
    }

    @ViewBuilder private func detail(_ item: TmbItem) -> some View {
        let b = file.bytes
        let type = TmbCatalog.types[item.magic].flatMap { $0.size == item.size ? $0 : nil }
        let block = blocks.first { $0.id == file.block } ?? blocks.first
        Panel(title: (TmbCatalog.name(item.magic).isEmpty ? item.magic : TmbCatalog.name(item.magic)) + "  ·  " + item.magic, trailing: "\(item.size) bytes") {
            if item.magic.hasPrefix("C"), let block {
                HStack(spacing: 6) {
                    SegmentButton(title: "Duplicate Entry", active: false) {
                        if let problem = TmbCatalog.canRestructure(b, block) {
                            file.note = problem
                        } else if let next = TmbCatalog.duplicate(b, block: block, index: item.id) {
                            file.bytes = next
                            file.selection = item.id + 1
                            file.note = nil
                        }
                    }
                    SegmentButton(title: "Delete Entry", active: false) {
                        if let problem = TmbCatalog.canRestructure(b, block) {
                            file.note = problem
                        } else if let next = TmbCatalog.remove(b, block: block, index: item.id) {
                            file.bytes = next
                            file.selection = max(0, item.id - 1)
                            file.note = nil
                        }
                    }
                    Spacer()
                    HelpBadge(text: "A duplicate gets a new id and goes into the same track right after this entry. To add an entry of another kind, select a track and use Add Entry.")
                }
            }
            if item.magic == "TMTR", let block {
                HStack(spacing: 6) {
                    Menu {
                        ForEach(TmbCatalog.entryTypes, id: \.magic) { entry in
                            Button("\(entry.magic)  \(entry.name)") {
                                if let problem = TmbCatalog.canRestructure(b, block) {
                                    file.note = problem
                                } else if let next = TmbCatalog.create(b, block: block, magic: entry.magic, track: item.id) {
                                    file.bytes = next
                                    file.selection = block.items.count
                                    file.note = nil
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus").font(.system(size: 9, weight: .bold))
                            Text("Add Entry").font(Theme.font)
                        }
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field.opacity(0.6)))
                    }
                    .menuStyle(.button)
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    Spacer()
                    HelpBadge(text: "A new entry of the chosen kind is added to the end of this track with the values the plugin gives a fresh entry.")
                }
            }
            if let block, let kind = TmbCatalog.childKind(item.magic) {
                HStack(spacing: 6) {
                    SegmentButton(title: kind == "TMAC" ? "Add Actor" : "Add Track", active: false) {
                        if let problem = TmbCatalog.canRestructure(b, block) {
                            file.note = problem
                        } else if let next = TmbCatalog.createContainer(b, block: block, parent: item.id) {
                            file.bytes = next
                            file.note = nil
                        }
                    }
                    Spacer()
                    HelpBadge(text: kind == "TMAC" ? "A new empty actor is added to this list. Give it tracks with Add Track." : "A new empty track is added to this actor. Give it entries with Add Entry.")
                }
            }
            if let block, TmbCatalog.isEmptyContainer(b, item) {
                HStack(spacing: 6) {
                    SegmentButton(title: item.magic == "TMAC" ? "Delete Actor" : "Delete Track", active: false) {
                        if let problem = TmbCatalog.canRestructure(b, block) {
                            file.note = problem
                        } else if let next = TmbCatalog.remove(b, block: block, index: item.id) {
                            file.bytes = next
                            file.selection = max(0, item.id - 1)
                            file.note = nil
                        }
                    }
                    Spacer()
                }
            }
            if item.magic != "TMAL", item.magic != "TMPP" {
                row("Id") { Text("\(item.itemID)").font(Theme.font).foregroundStyle(Theme.dim) }
            }
            if item.magic.hasPrefix("C") || item.magic == "TMAC" || item.magic == "TMTR" || item.magic == "TMFC" {
                number("Time", Double(item.time), integer: true) { file.setShort(item.offset + 10, Int($0)) }
            }
            if let type {
                ForEach(Array(type.fields.enumerated()), id: \.offset) { _, field in fieldRow(field, item) }
            }
        }
        Panel(title: "Raw Values", trailing: "\((item.size - 8) / 4)") {
            ForEach(Array(stride(from: 8, to: item.size - 3, by: 4)), id: \.self) { at in
                let raw = GameFiles.i32(b, item.offset + at)
                let float = GameFiles.f32(b, item.offset + at)
                HStack(spacing: 8) {
                    Text(String(format: "+%02X", at)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim).frame(width: 34, alignment: .leading)
                    NumberField(label: nil, value: Double(raw), isInteger: true, onLive: { _ in }, onCommit: { _, v in file.setInt(item.offset + at, Int(v)) })
                        .frame(width: 130)
                    Text(abs(float) > 1e-4 && abs(float) < 1e7 ? String(format: "%.4g", float) : "").font(Theme.small).foregroundStyle(Theme.dim)
                        .frame(width: 80, alignment: .leading)
                    Text(String(format: "%08X", UInt32(bitPattern: Int32(truncatingIfNeeded: raw)))).font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Theme.dim)
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct EidView: View {
    @ObservedObject var file: GameFileDocument

    var body: some View {
        if let parsed = GameFiles.eidPoints(file.bytes) {
            let points = parsed.points
            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Id").frame(width: 60, alignment: .leading)
                        Text("Bone").frame(width: 150, alignment: .leading)
                        Text("Position X / Y / Z").frame(width: 266, alignment: .leading)
                        Text("Rotation X / Y / Z").frame(width: 266, alignment: .leading)
                    }
                    .font(Theme.small)
                    .foregroundStyle(Theme.dim)
                    ForEach(points) { point in
                        HStack(spacing: 4) {
                            NumberField(label: nil, value: Double(point.pointID), isInteger: true, onLive: { _ in }, onCommit: { _, v in
                                var list = points
                                list[point.id].pointID = Int(v)
                                file.setPoints(list, new: parsed.new)
                            }).frame(width: 60)
                            TextValueField(value: point.bone) { text in
                                var list = points
                                list[point.id].bone = text
                                file.setPoints(list, new: parsed.new)
                            }.frame(width: 150)
                            ForEach(0..<3, id: \.self) { axis in
                                NumberField(label: nil, value: Double(point.position[axis]), step: 0.01, onLive: { _ in }, onCommit: { _, v in
                                    var list = points
                                    list[point.id].position[axis] = Float(v)
                                    file.setPoints(list, new: parsed.new)
                                }).frame(width: 86)
                            }
                            ForEach(0..<3, id: \.self) { axis in
                                NumberField(label: nil, value: Double(point.rotation[axis]), suffix: "°", step: 0.5, onLive: { _ in }, onCommit: { _, v in
                                    var list = points
                                    list[point.id].rotation[axis] = Float(v)
                                    file.setPoints(list, new: parsed.new)
                                }).frame(width: 86)
                            }
                            HeaderButton(symbol: "trash", help: "Delete this bind point") {
                                var list = points
                                list.remove(at: point.id)
                                file.setPoints(list.enumerated().map { index, item in
                                    EidPoint(id: index < point.id ? index : -1 - index, bone: item.bone, pointID: item.pointID, position: item.position, rotation: item.rotation)
                                }, new: parsed.new)
                            }
                        }
                    }
                    SegmentButton(title: "Add Bind Point", active: false) {
                        var list = points
                        list.append(EidPoint(id: list.count, bone: "n_root", pointID: (list.map(\.pointID).max() ?? 0) + 1, position: .zero, rotation: .zero))
                        file.setPoints(list, new: parsed.new)
                    }
                    .padding(.top, 6)
                }
                .padding(10)
            }
        } else {
            Text("Not a bind point file").font(Theme.font).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ScdView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var file: GameFileDocument

    var body: some View {
        let list = GameFiles.scdAudio(file.bytes)
        ScrollView {
            VStack(spacing: 6) {
                Panel(title: "Audio", trailing: "\(list.count)") {
                    ForEach(list) { audio in
                        HStack(spacing: 8) {
                            Text("\(audio.id)").font(Theme.font).foregroundStyle(Theme.text).frame(width: 26, alignment: .leading)
                            Text(audio.formatName).font(Theme.font).foregroundStyle(Theme.text).frame(width: 80, alignment: .leading)
                            Text("\(audio.channels) ch · \(audio.sampleRate) Hz · \(audio.dataLength) bytes").font(Theme.small).foregroundStyle(Theme.dim).lineLimit(1)
                            if audio.loopEnd > 0 { Text("loop \(audio.loopStart)–\(audio.loopEnd)").font(Theme.small).foregroundStyle(Theme.dim) }
                            Spacer(minLength: 4)
                            HeaderButton(symbol: "play.fill", help: "Play") { file.play(audio) }
                            HeaderButton(symbol: "stop.fill", help: "Stop") { file.stop() }
                            HeaderButton(symbol: "square.and.arrow.up", help: "Export the sound") { app.exportScdStream(file, audio) }
                            HeaderButton(symbol: "square.and.arrow.down", help: "Replace with a sound file") { app.replaceScdSound(file, audio) }
                        }
                        WaveStrip(peaks: file.peaks(audio))
                    }
                    HStack {
                        Spacer()
                        HelpBadge(text: "Replace takes a .wav, .aiff, .m4a or .mp3 file and stores it as MS ADPCM with the same channel count and sample rate as the source. Vorbis sounds can be exported as .ogg but are not played here.")
                    }
                    if list.isEmpty { Text("No audio entries").font(Theme.font).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, alignment: .leading) }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

private struct AtchView: View {
    @ObservedObject var file: GameFileDocument

    private func change(_ table: AtchTable, _ mutate: (inout AtchTable) -> Void) {
        var next = table
        mutate(&next)
        file.bytes = next.serialized()
    }

    private func row<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.text).lineLimit(1).frame(width: 110, alignment: .trailing)
            content()
            Spacer(minLength: 0)
        }
    }

    var body: some View {
        if let table = AtchTable.parse(file.bytes) {
            let index = min(max(file.selection, 0), table.entries.count - 1)
            let entry = table.entries[index]
            HStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(table.entries) { item in
                            HStack(spacing: 6) {
                                Text(item.name).font(.system(size: 10, design: .monospaced)).foregroundStyle(item.accessory ? Theme.changed : Theme.dim).frame(width: 30, alignment: .leading)
                                Text(AtchTable.weaponNames[item.name] ?? "").font(Theme.font).foregroundStyle(item.id == index ? .white : Theme.text).lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 6)
                            .frame(height: 20)
                            .background(item.id == index ? Theme.selection : Color.clear)
                            .contentShape(Rectangle())
                            .onTapGesture { file.selection = item.id }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(width: 270)
                .background(Theme.gray(0.157))
                ScrollView {
                    VStack(spacing: 6) {
                        Panel(title: entry.name + (AtchTable.weaponNames[entry.name].map { "  ·  " + $0 } ?? "")) {
                            row("Accessory") { CheckBox(isOn: entry.accessory, label: "") { on in change(table) { $0.entries[index].accessory = on } }.frame(width: 40) }
                        }
                        ForEach(Array(entry.states.enumerated()), id: \.offset) { slot, state in
                            Panel(title: "State \(slot)") {
                                row("Bone") { TextValueField(value: state.bone) { text in change(table) { $0.entries[index].states[slot].bone = text } }.frame(width: 220) }
                                row("Scale") {
                                    NumberField(label: nil, value: Double(state.scale), step: 0.01, onLive: { _ in },
                                                onCommit: { _, v in change(table) { $0.entries[index].states[slot].scale = Float(v) } }).frame(width: 90)
                                }
                                row("Offset") {
                                    ForEach(0..<3, id: \.self) { axis in
                                        NumberField(label: nil, value: Double(state.offset[axis]), step: 0.01, onLive: { _ in },
                                                    onCommit: { _, v in change(table) { $0.entries[index].states[slot].offset[axis] = Float(v) } }).frame(width: 90)
                                    }
                                }
                                row("Rotation") {
                                    ForEach(0..<3, id: \.self) { axis in
                                        NumberField(label: nil, value: Double(state.rotation[axis] * 180 / .pi), suffix: "°", step: 0.5, onLive: { _ in },
                                                    onCommit: { _, v in change(table) { $0.entries[index].states[slot].rotation[axis] = Float(v) * .pi / 180 } }).frame(width: 90)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        } else {
            Text("Not an attach table").font(Theme.font).foregroundStyle(Theme.dim).frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct MtrlPanels: View {
    @ObservedObject var file: GameFileDocument
    let layout: MtrlLayout

    private func hex(_ at: Int) -> String { String(format: "%08X", file.bytes.u32(at)) }

    private func integer(_ at: Int, width: CGFloat = 120) -> some View {
        NumberField(label: nil, value: Double(file.bytes.u32(at)), isInteger: true, onLive: { _ in },
                    onCommit: { _, v in GameFiles.put32(&file.bytes, at, UInt32(max(0, min(v, 4_294_967_295)))) }).frame(width: width)
    }

    private func label(_ text: String, _ width: CGFloat) -> some View {
        Text(text).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim).frame(width: width, alignment: .leading)
    }

    private func color(_ row: Int, _ first: Int) -> some View {
        let at = layout.tableAt + (row * layout.rowWidth + first) * 2
        let value = SIMD4<Double>(Double(GameFiles.half(file.bytes.u16(at))), Double(GameFiles.half(file.bytes.u16(at + 2))), Double(GameFiles.half(file.bytes.u16(at + 4))), 1)
        return ColorField(color: value, alpha: false, onLive: { _ in }, onCommit: { _, next in
            for axis in 0..<3 {
                let bits = GameFiles.halfBits(Float(next[axis]))
                file.bytes[at + axis * 2] = UInt8(bits & 0xFF)
                file.bytes[at + axis * 2 + 1] = UInt8(bits >> 8)
            }
        })
        .frame(width: 150)
    }

    var body: some View {
        Panel(title: "Shader Values") {
            HStack(spacing: 8) {
                label("Flags", 110)
                integer(layout.shaderFlagsAt)
                label(hex(layout.shaderFlagsAt), 80)
                if let flagsAt = layout.flagsAt {
                    CheckBox(isOn: file.bytes[flagsAt] & 0x4 != 0, label: "Colour table") { on in file.bytes[flagsAt] = on ? file.bytes[flagsAt] | 0x4 : file.bytes[flagsAt] & ~0x4 }
                    CheckBox(isOn: file.bytes[flagsAt] & 0x8 != 0, label: "Dyeable") { on in file.bytes[flagsAt] = on ? file.bytes[flagsAt] | 0x8 : file.bytes[flagsAt] & ~0x8 }
                }
                Spacer(minLength: 0)
            }
        }
        if !layout.keys.isEmpty {
            Panel(title: "Shader Keys", trailing: "\(layout.keys.count)") {
                ForEach(layout.keys, id: \.self) { at in
                    HStack(spacing: 8) {
                        label(hex(at), 110)
                        integer(at + 4)
                        label(hex(at + 4), 80)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        if !layout.constants.isEmpty {
            Panel(title: "Constants", trailing: "\(layout.constants.count)") {
                ForEach(layout.constants, id: \.at) { constant in
                    HStack(spacing: 6) {
                        label(hex(constant.at), 110)
                        ForEach(0..<min(constant.count, 4), id: \.self) { slot in
                            let at = constant.valuesAt + slot * 4
                            NumberField(label: nil, value: Double(GameFiles.f32(file.bytes, at)), step: 0.01, onLive: { _ in },
                                        onCommit: { _, v in GameFiles.put32(&file.bytes, at, Float(v).bitPattern) }).frame(width: 90)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        if !layout.samplers.isEmpty {
            Panel(title: "Samplers", trailing: "\(layout.samplers.count)") {
                ForEach(layout.samplers, id: \.self) { at in
                    HStack(spacing: 8) {
                        label(hex(at), 110)
                        integer(at + 4)
                        label(hex(at + 4), 80)
                        Text("Texture").font(Theme.font).foregroundStyle(Theme.dim)
                        NumberField(label: nil, value: Double(file.bytes[at + 8]), isInteger: true, onLive: { _ in },
                                    onCommit: { _, v in file.bytes[at + 8] = UInt8(max(0, min(v, 255))) }).frame(width: 60)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        if layout.rows > 0 {
            Panel(title: "Colour Table", trailing: "\(layout.rows) rows") {
                HStack(spacing: 8) {
                    label("Row", 34)
                    Text("Diffuse").frame(width: 150, alignment: .leading)
                    Text("Specular").frame(width: 150, alignment: .leading)
                    Text("Emissive").frame(width: 150, alignment: .leading)
                    Spacer(minLength: 0)
                    HelpBadge(text: "Each row of the colour table holds a diffuse, a specular and an emissive colour as half floats; values above 1 are kept as they are until the colour is edited.")
                }
                .font(Theme.small)
                .foregroundStyle(Theme.dim)
                ForEach(0..<layout.rows, id: \.self) { row in
                    HStack(spacing: 8) {
                        label("\(row)", 34)
                        color(row, 0)
                        color(row, 4)
                        color(row, 8)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}

private struct WaveStrip: View {
    let peaks: [Float]

    var body: some View {
        Canvas { context, size in
            guard !peaks.isEmpty else { return }
            let width = size.width / CGFloat(peaks.count)
            var path = Path()
            for (index, peak) in peaks.enumerated() {
                let height = max(1, CGFloat(peak) * size.height)
                path.addRect(CGRect(x: CGFloat(index) * width, y: (size.height - height) / 2, width: max(1, width - 0.5), height: height))
            }
            context.fill(path, with: .color(Theme.selection))
        }
        .frame(height: peaks.isEmpty ? 0 : 26)
        .background(peaks.isEmpty ? Color.clear : Theme.field.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

private struct RawFileView: View {
    @ObservedObject var file: GameFileDocument

    private func edit(_ label: String, _ value: String, slot: Int) -> some View {
        HStack(spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.dim).frame(width: 130, alignment: .trailing)
            TextValueField(value: value) { text in
                guard let at = GameFiles.mtrlStringOffset(file.bytes, slot: slot) else { return }
                if GameFiles.setString(&file.bytes, at: at, old: value, new: text) {
                    file.note = nil
                } else {
                    file.note = "The text can be at most \(value.utf8.count) characters here"
                }
            }
        }
    }

    private func line(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label).font(Theme.font).foregroundStyle(Theme.dim).frame(width: 130, alignment: .trailing)
            Text(value).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.text).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    var body: some View {
        let strings = GameFiles.strings(file.bytes)
        let ext = file.url.pathExtension.lowercased()
        ScrollView {
            VStack(spacing: 6) {
                if ext == "mtrl", let summary = GameFiles.mtrlSummary(file.bytes) {
                    Panel(title: "Material") {
                        edit("Shader", summary.shader, slot: -1)
                        ForEach(Array(summary.textures.enumerated()), id: \.offset) { index, path in edit("Texture \(index)", path, slot: index) }
                        HStack {
                            Spacer()
                            HelpBadge(text: "The shader and texture paths can be replaced by text of the same length or shorter; the file layout stays as it is.")
                        }
                        ForEach(Array(summary.uvSets.enumerated()), id: \.offset) { index, name in line("UV Set \(index)", name) }
                        ForEach(Array(summary.colorSets.enumerated()), id: \.offset) { index, name in line("Colour Set \(index)", name) }
                    }
                }
                if ext == "mtrl", let layout = MtrlLayout.parse(file.bytes) { MtrlPanels(file: file, layout: layout) }
                if ext == "sklb", let skeleton = GameSkeleton.parse(file.bytes) {
                    Panel(title: "Bones", trailing: "\(skeleton.names.count)") {
                        ForEach(Array(skeleton.names.enumerated()), id: \.offset) { index, name in
                            let parent = index < skeleton.parents.count ? skeleton.parents[index] : -1
                            let p = skeleton.position(index)
                            HStack(spacing: 8) {
                                Text("\(index)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim).frame(width: 34, alignment: .leading)
                                Text(name).font(Theme.font).foregroundStyle(Theme.text).frame(width: 190, alignment: .leading).lineLimit(1).textSelection(.enabled)
                                Text(parent >= 0 && parent < skeleton.names.count ? skeleton.names[parent] : "—").font(Theme.font).foregroundStyle(Theme.dim)
                                    .frame(width: 190, alignment: .leading).lineLimit(1)
                                Text(String(format: "%.3f  %.3f  %.3f", p.x, p.y, p.z)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }
                if ext == "mdl", let summary = GameFiles.mdlSummary(file.bytes) {
                    Panel(title: "Model") {
                        ForEach(Array(summary.enumerated()), id: \.offset) { _, entry in line(entry.label, entry.value) }
                    }
                }
                Panel(title: "Strings", trailing: "\(strings.count)") {
                    ForEach(Array(strings.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 8) {
                            Text(String(format: "%06X", entry.offset)).font(.system(size: 10, design: .monospaced)).foregroundStyle(Theme.dim).frame(width: 52, alignment: .leading)
                            Text(entry.text).font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.text).lineLimit(1).textSelection(.enabled)
                            Spacer(minLength: 0)
                        }
                    }
                }
                Panel(title: "Start of File", trailing: "\(min(file.bytes.count, 512)) bytes") {
                    ForEach(Array(stride(from: 0, to: min(file.bytes.count, 512), by: 16)), id: \.self) { at in
                        let slice = file.bytes[at..<min(at + 16, file.bytes.count)]
                        HStack(spacing: 10) {
                            Text(String(format: "%04X", at)).foregroundStyle(Theme.dim).frame(width: 40, alignment: .leading)
                            Text(slice.map { String(format: "%02X", $0) }.joined(separator: " ")).foregroundStyle(Theme.text).frame(width: 340, alignment: .leading)
                            Text(String(slice.map { $0 >= 0x20 && $0 < 0x7F ? Character(UnicodeScalar($0)) : "." })).foregroundStyle(Theme.dim)
                            Spacer(minLength: 0)
                        }
                        .font(.system(size: 10, design: .monospaced))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
