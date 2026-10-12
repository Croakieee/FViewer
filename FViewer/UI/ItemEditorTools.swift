import Combine
import SwiftUI
import simd

struct ItemTools: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let node: OutlineNode

    var body: some View {
        if case .avfx(let block, _, let record) = node.payload, record == nil {
            switch block.tag {
            case "Ptcl":
                LifeGradientPanel(document: document, particle: block)
                ShapeDiagramPanel(document: document, clock: document.clock, particle: block)
                LayerStackPanel(document: document, particleNode: node)
            case "Smpl":
                SimpleGridPanel(document: document, node: node, simple: block)
            case "Emit":
                CreationRibbonPanel(document: document, emitter: block)
            default:
                EmptyView()
            }
        }
    }
}

private func layerTexturePath(_ fields: [PropField], _ document: EffectDocument) -> String? {
    let slots = document.textureSlots
    for field in fields where field.tag == "TxNo" || field.tag.hasPrefix("TLst") || field.label.hasPrefix("Mask Texture") {
        if case .int(let index) = field.read(), index >= 0, index < slots.count { return slots[index].path }
    }
    return nil
}

struct LifeGradientPanel: View {
    @ObservedObject var document: EffectDocument
    let particle: AvfxBlock

    private var samples: [SIMD4<Float>] {
        guard particle.child("Col") != nil else { return [] }
        let color = AvfxSchemaReader.color(particle.child("Col"))
        var life = particle.child("Life")?.float("Val", 30) ?? 30
        if life <= 0 { life = 60 }
        var random = SeededRandom(seed: 1)
        let seed = RandomSeed(&random, count: 26)
        return (0..<96).map { Eval.color(color, CurveTime(life * Float($0) / 95), seed) }
    }

    var body: some View {
        let list = samples
        if !list.isEmpty {
            Panel(title: "Colour over Life") {
                ZStack {
                    CheckerBackground()
                    Canvas { context, size in
                        let step = size.width / CGFloat(list.count)
                        for (index, c) in list.enumerated() {
                            let peak = max(c.x, c.y, c.z, 1)
                            let color = Color(red: Double(c.x / peak), green: Double(c.y / peak), blue: Double(c.z / peak)).opacity(Double(min(max(c.w, 0), 1)))
                            context.fill(Path(CGRect(x: CGFloat(index) * step, y: 0, width: step + 0.5, height: size.height)), with: .color(color))
                        }
                    }
                }
                .frame(height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                HStack {
                    Text("birth").font(Theme.small).foregroundStyle(Theme.dim)
                    Spacer()
                    HelpBadge(text: "The particle colour from birth to death, as the Color curve gives it. Values above 1 are shown at full brightness.")
                    Text("death").font(Theme.small).foregroundStyle(Theme.dim)
                }
            }
        }
    }
}

struct ShapeDiagramPanel: View {
    @ObservedObject var document: EffectDocument
    @ObservedObject var clock: PlaybackClock
    let particle: AvfxBlock

    private func value(_ data: AvfxBlock?, _ tag: String, _ fallback: Float, _ time: CurveTime) -> Float {
        guard let block = data?.child(tag) else { return fallback }
        return Eval.curve(AvfxSchemaReader.curve(block), time, fallback)
    }

    var body: some View {
        let type = particle.int("PrVT")
        if type == 2 {
            Panel(title: "Windmill Shape") {
                Canvas { context, size in
                    let centre = CGPoint(x: size.width / 2, y: size.height / 2), reach = min(size.width, size.height) / 2 - 8
                    for blade in 0..<4 {
                        let angle = CGFloat(blade) * .pi / 4
                        var path = Path()
                        path.move(to: CGPoint(x: centre.x - cos(angle) * reach, y: centre.y - sin(angle) * reach))
                        path.addLine(to: CGPoint(x: centre.x + cos(angle) * reach, y: centre.y + sin(angle) * reach))
                        context.stroke(path, with: .color(NodeTint.particle.color.opacity(0.8)), lineWidth: 3)
                    }
                    context.fill(Path(ellipseIn: CGRect(x: centre.x - 2, y: centre.y - 2, width: 4, height: 4)), with: .color(.white))
                    let mirrored = (particle.child("Data")?.int("WUvT") ?? 0) == 1
                    context.draw(Text(mirrored ? "mirrored UV" : "plain UV").font(.system(size: 9)).foregroundStyle(.white), at: CGPoint(x: size.width / 2, y: 9))
                }
                .frame(height: 110)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.14)))
                HStack {
                    Spacer()
                    HelpBadge(text: "Seen from above: four upright quads crossing at the particle origin, each one unit of scale wide.")
                }
            }
        }
        if type == 4 || type == 6 {
            let data = particle.child("Data")
            let time = CurveTime(Float(clock.time))
            Panel(title: type == 4 ? "Laser Shape" : "Trail Profile") {
                Canvas { context, size in
                    let mid = size.height / 2
                    if type == 4 {
                        let length = CGFloat(max(0.01, value(data, "Len", 1, time))), width = CGFloat(max(0.001, value(data, "Wdt", 1, time)))
                        let scale = min((size.width - 24) / length, (size.height - 16) / width)
                        let rect = CGRect(x: 12, y: mid - width * scale / 2, width: length * scale, height: width * scale)
                        context.fill(Path(rect), with: .color(NodeTint.particle.color.opacity(0.55)))
                        context.fill(Path(ellipseIn: CGRect(x: 10, y: mid - 2, width: 4, height: 4)), with: .color(.white))
                        context.draw(Text(String(format: "%.2f × %.2f m", Double(length), Double(width))).font(.system(size: 9)).foregroundStyle(.white),
                                     at: CGPoint(x: size.width / 2, y: 9))
                    } else {
                        let base = CGFloat(value(data, "Wd", 1, time))
                        let widths = [CGFloat(value(data, "WdB", 1, time)), CGFloat(value(data, "WdC", 1, time)), CGFloat(value(data, "WdE", 1, time))].map { $0 * base }
                        let points = max(2, data?.int("PnC", 2) ?? 2)
                        let centre = min(1, max(0, CGFloat(data?.int("PnCC") ?? 0) / CGFloat(points - 1)))
                        let peak = max(widths.max() ?? 1, 0.001)
                        let scale = (size.height / 2 - 6) / peak
                        let xs: [CGFloat] = [10, 10 + (size.width - 20) * centre, size.width - 10]
                        var path = Path()
                        path.move(to: CGPoint(x: xs[0], y: mid - widths[0] * scale))
                        path.addLine(to: CGPoint(x: xs[1], y: mid - widths[1] * scale))
                        path.addLine(to: CGPoint(x: xs[2], y: mid - widths[2] * scale))
                        path.addLine(to: CGPoint(x: xs[2], y: mid + widths[2] * scale))
                        path.addLine(to: CGPoint(x: xs[1], y: mid + widths[1] * scale))
                        path.addLine(to: CGPoint(x: xs[0], y: mid + widths[0] * scale))
                        path.closeSubpath()
                        context.fill(path, with: .color(NodeTint.particle.color.opacity(0.55)))
                        for i in 0..<points {
                            let x = 10 + (size.width - 20) * CGFloat(i) / CGFloat(points - 1)
                            context.fill(Path(CGRect(x: x - 0.5, y: mid - 2, width: 1, height: 4)), with: .color(Color.white.opacity(0.6)))
                        }
                        context.fill(Path(ellipseIn: CGRect(x: 8, y: mid - 2, width: 4, height: 4)), with: .color(.white))
                    }
                }
                .frame(height: 90)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.14)))
                HStack {
                    Spacer()
                    HelpBadge(text: type == 4 ? "The beam at the playhead: length along the beam, width across it. The dot is the particle origin."
                        : "Half width of the trail from its head (left, at the particle) through the centre point to its tail, at the playhead. Ticks are the trail points.")
                }
            }
        }
        if type == 12 || type == 11 {
            let data = particle.child("Data")
            let time = CurveTime(Float(clock.time))
            Panel(title: type == 12 ? "Disc Shape" : "Ring Shape") {
                Canvas { context, size in
                    let centre = CGPoint(x: size.width / 2, y: size.height / 2)
                    var bands: [(inner: CGFloat, outer: CGFloat, from: CGFloat, to: CGFloat)] = []
                    var extent: CGFloat = 1
                    if type == 12 {
                        let angle = CGFloat(value(data, "Ang", .pi * 2, time))
                        let steps = 48
                        for i in 0..<steps {
                            let f0 = CGFloat(i) / CGFloat(steps), f1 = CGFloat(i + 1) / CGFloat(steps)
                            let r = CGFloat(value(data, "RB", 1, time)) + CGFloat(value(data, "RE", 1, time) - value(data, "RB", 1, time)) * f0
                            let w = CGFloat(value(data, "WB", 0.2, time)) + CGFloat(value(data, "WE", 0.2, time) - value(data, "WB", 0.2, time)) * f0
                            bands.append((r - w, r + w, f0 * angle, f1 * angle))
                            extent = max(extent, abs(r) + abs(w))
                        }
                    } else {
                        let width = CGFloat(value(data, "WID", 0.1, time))
                        let fan = CGFloat(data?.float("RF", 1) ?? 1)
                        let arc = 2 * acos(min(max(1 - 2 * fan, -1), 1))
                        bands.append((0.5 - width, 0.5 + width, .pi / 2 - arc / 2, .pi / 2 + arc / 2))
                        extent = max(0.6, 0.5 + abs(width))
                    }
                    let scale = (min(size.width, size.height) / 2 - 6) / max(extent, 0.01)
                    context.stroke(Path(ellipseIn: CGRect(x: centre.x - scale * extent, y: centre.y - scale * extent, width: scale * extent * 2, height: scale * extent * 2)),
                                   with: .color(Color.white.opacity(0.12)), lineWidth: 1)
                    for band in bands {
                        var path = Path()
                        let parts = max(2, Int(abs(band.to - band.from) / 0.06))
                        for k in 0...parts {
                            let a = band.from + (band.to - band.from) * CGFloat(k) / CGFloat(parts)
                            let p = CGPoint(x: centre.x + cos(a) * band.outer * scale, y: centre.y - sin(a) * band.outer * scale)
                            if k == 0 { path.move(to: p) } else { path.addLine(to: p) }
                        }
                        for k in (0...parts).reversed() {
                            let a = band.from + (band.to - band.from) * CGFloat(k) / CGFloat(parts)
                            path.addLine(to: CGPoint(x: centre.x + cos(a) * band.inner * scale, y: centre.y - sin(a) * band.inner * scale))
                        }
                        path.closeSubpath()
                        context.fill(path, with: .color(NodeTint.particle.color.opacity(0.55)))
                    }
                    context.fill(Path(ellipseIn: CGRect(x: centre.x - 2, y: centre.y - 2, width: 4, height: 4)), with: .color(.white))
                }
                .frame(height: 150)
                .background(RoundedRectangle(cornerRadius: 4).fill(Theme.gray(0.14)))
                HStack {
                    Spacer()
                    HelpBadge(text: "Top view of the shape at the playhead, built from the radius, width and angle values of the Data block. The dot is the particle origin.")
                }
            }
        }
    }
}

struct LayerStackPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let particleNode: OutlineNode
    @State private var target: String?

    static let order = ["TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP"]

    private var layers: [(node: OutlineNode, tag: String, fields: [PropField])] {
        var result: [(OutlineNode, String, [PropField])] = []
        for tag in LayerStackPanel.order {
            for child in particleNode.children {
                if case .avfx(let block, _, let record) = child.payload, record == nil, block.tag == tag {
                    result.append((child, tag, document.sections(for: child).flatMap(\.fields)))
                }
            }
        }
        return result
    }

    private func field(_ fields: [PropField], _ tag: String) -> PropField? {
        if tag == "TxNo" { return fields.first { $0.tag == "TxNo" } ?? fields.first { $0.label.hasPrefix("Mask Texture") || $0.tag.hasPrefix("TLst") } }
        return fields.first { $0.tag == tag }
    }

    private func composite(_ list: [(node: OutlineNode, tag: String, fields: [PropField])]) -> CGImage? {
        let size = 96
        var out = [Float](repeating: 1, count: size * size * 4)
        var any = false
        for layer in list where ["TC1", "TC2", "TC3", "TC4"].contains(layer.tag) {
            guard field(layer.fields, "bEna")?.read() == .bool(true), let path = layerTexturePath(layer.fields, document),
                  let texture = app.decodedTexture(for: path), texture.width > 0, texture.height > 0 else { continue }
            let colorMode = Int(field(layer.fields, "TCCT")?.read().number ?? 0), alphaMode = Int(field(layer.fields, "TCAT")?.read().number ?? 0)
            let toAlpha = field(layer.fields, "bC2A")?.read() == .bool(true)
            for y in 0..<size {
                for x in 0..<size {
                    let sx = x * texture.width / size, sy = y * texture.height / size
                    let o = (sy * texture.width + sx) * 4
                    var t = SIMD4<Float>(Float(texture.rgba[o]), Float(texture.rgba[o + 1]), Float(texture.rgba[o + 2]), Float(texture.rgba[o + 3])) / 255
                    if toAlpha { t = SIMD4(1, 1, 1, t.x * 0.299 + t.y * 0.587 + t.z * 0.114) }
                    let at = (y * size + x) * 4
                    if !any {
                        out[at] = t.x; out[at + 1] = t.y; out[at + 2] = t.z; out[at + 3] = t.w
                        continue
                    }
                    for c in 0..<3 {
                        let base = out[at + c], top = t[c]
                        switch colorMode {
                        case 1: out[at + c] = base + top
                        case 2: out[at + c] = base - top
                        case 3: out[at + c] = max(base, top)
                        case 4: out[at + c] = min(base, top)
                        default: out[at + c] = base * top
                        }
                    }
                    switch alphaMode {
                    case 1: out[at + 3] = max(out[at + 3], t.w)
                    case 2: out[at + 3] = min(out[at + 3], t.w)
                    case 3: break
                    default: out[at + 3] *= t.w
                    }
                }
            }
            any = true
        }
        guard any else { return nil }
        let bytes = out.map { UInt8(min(max($0, 0), 1) * 255) }
        return DecodedTexture(width: size, height: size, formatName: "", mipLevels: 1, alphaOnly: false, rgba: bytes).makeImage()
    }

    private func dropImage(_ urls: [URL], on layer: (node: OutlineNode, tag: String, fields: [PropField])) -> Bool {
        guard let url = urls.first(where: { AppModel.imageSourceTypes.contains($0.pathExtension.lowercased()) }), let root = document.avfxRoot,
              let index = field(layer.fields, "TxNo") else { return false }
        document.undoManager.beginUndoGrouping()
        defer { document.undoManager.endUndoGrouping() }
        let selection = document.selectionID
        document.addTexture(path: app.customPrefix + url.deletingPathExtension().lastPathComponent.lowercased() + ".atex")
        let textures = root.childrenNamed("Tex")
        guard let block = textures.last else { return false }
        do {
            _ = try app.installTexture(from: url, for: block, in: document)
        } catch {
            app.errorMessage = "\(url.lastPathComponent): \(error.localizedDescription)"
            return false
        }
        document.commit(index, from: index.read(), to: .int(textures.count - 1))
        if let enabled = field(layer.fields, "bEna"), enabled.read() != .bool(true) { document.commit(enabled, from: enabled.read(), to: .bool(true)) }
        document.selectionID = selection
        app.notice = "\(url.lastPathComponent) added as Texture \(textures.count - 1) on \(layer.node.title)"
        return true
    }

    private func thumbnail(_ path: String?) -> some View {
        ZStack {
            CheckerBackground()
            if let path, let image = app.image(for: path) {
                Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo").font(.system(size: 12)).foregroundStyle(Theme.dim)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func row(_ layer: (node: OutlineNode, tag: String, fields: [PropField])) -> some View {
        let enabled = field(layer.fields, "bEna")
        let on = enabled?.read() == .bool(true)
        return HStack(spacing: 6) {
            thumbnail(layerTexturePath(layer.fields, document))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if let enabled { FieldControl(document: document, field: enabled, label: "").frame(width: 22) }
                    Text(layer.node.title.replacingOccurrences(of: "Texture ", with: "")).font(Theme.font).foregroundStyle(on ? Theme.text : Theme.dim).lineLimit(1)
                    if document.changes.contains(layer.node.id) { ChangeDot() }
                    Spacer(minLength: 2)
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).foregroundStyle(Theme.dim)
                        .frame(width: 16, height: 18).contentShape(Rectangle())
                        .onTapGesture { document.selectionID = layer.node.id }
                        .help("Open every parameter of this layer")
                }
                HStack(spacing: 4) {
                    if let texture = field(layer.fields, "TxNo") { FieldControl(document: document, field: texture).frame(minWidth: 90) }
                    if let uv = field(layer.fields, "UvSN") { FieldControl(document: document, field: uv).frame(width: 84) }
                    if let color = field(layer.fields, "TCCT") { FieldControl(document: document, field: color).frame(width: 84).help("Calculate Color") }
                    if let alpha = field(layer.fields, "TCAT") { FieldControl(document: document, field: alpha).frame(width: 76).help("Calculate Alpha") }
                }
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 4).fill(target == layer.node.id ? Theme.selection.opacity(0.6) : Theme.field.opacity(on ? 0.4 : 0.18)))
        .dropDestination(for: URL.self) { urls, _ in dropImage(urls, on: layer) } isTargeted: { inside in
            if inside { target = layer.node.id } else if target == layer.node.id { target = nil }
        }
    }

    var body: some View {
        let list = layers
        if !list.isEmpty {
            Panel(title: "Texture Layers", trailing: "\(list.filter { field($0.fields, "bEna")?.read() == .bool(true) }.count) on") {
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: 3) { ForEach(list, id: \.node.id) { layer in row(layer) } }
                    VStack(spacing: 4) {
                        ZStack {
                            CheckerBackground()
                            if let image = composite(list) {
                                Image(decorative: image, scale: 1).resizable().interpolation(.medium).aspectRatio(contentMode: .fit)
                            }
                        }
                        .frame(width: 110, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        HelpBadge(text: "Colour layers 1 to 4 combined with their Calculate Color and Calculate Alpha modes, without UV motion. Drop an image file on a layer to give it a new texture.")
                    }
                }
            }
        }
    }
}

struct SimpleGridPanel: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var document: EffectDocument
    let node: OutlineNode
    let simple: AvfxBlock

    private var texturePath: String? {
        let parts = node.id.split(separator: "/").prefix(3).joined(separator: "/")
        guard let particle = document.node(parts) else { return nil }
        for child in particle.children {
            if case .avfx(let block, _, let record) = child.payload, record == nil, block.tag == "TC1" {
                return layerTexturePath(document.sections(for: child).flatMap(\.fields), document)
            }
        }
        return nil
    }

    private var stops: [(color: Color, frame: Int)] {
        let colors = simple.child("Cols")?.data ?? [], frames = simple.child("Frms")?.data ?? []
        var result: [(Color, Int)] = []
        for i in 0..<4 where i * 4 + 3 < colors.count {
            let o = i * 4
            let color = Color(red: Double(colors[o]) / 255, green: Double(colors[o + 1]) / 255, blue: Double(colors[o + 2]) / 255).opacity(Double(colors[o + 3]) / 255)
            result.append((color, i * 2 + 1 < frames.count ? Int(Int16(bitPattern: frames.u16(i * 2))) : 0))
        }
        return result
    }

    var body: some View {
        let u = max(1, simple.int("UvCU", 1)), v = max(1, simple.int("UvCV", 1))
        let list = stops
        Panel(title: "Sprite Sheet", trailing: "\(u) × \(v)") {
            ZStack {
                CheckerBackground()
                if let path = texturePath, let image = app.image(for: path) {
                    Image(decorative: image, scale: 1).resizable().interpolation(.medium)
                }
                Canvas { context, size in
                    var grid = Path()
                    for i in 1..<max(u, 1) where u > 1 {
                        let x = size.width * CGFloat(i) / CGFloat(u)
                        grid.move(to: CGPoint(x: x, y: 0))
                        grid.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for j in 1..<max(v, 1) where v > 1 {
                        let y = size.height * CGFloat(j) / CGFloat(v)
                        grid.move(to: CGPoint(x: 0, y: y))
                        grid.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(grid, with: .color(Theme.changed.opacity(0.9)), lineWidth: 1)
                    if u * v <= 64 {
                        for cell in 0..<(u * v) {
                            let at = CGPoint(x: size.width * (CGFloat(cell % u) + 0.08) / CGFloat(u) + 6, y: size.height * (CGFloat(cell / u) + 0.08) / CGFloat(v) + 6)
                            context.draw(Text("\(cell)").font(.system(size: 9, weight: .semibold)).foregroundStyle(.white), at: at)
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: 220)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            if !list.isEmpty {
                HStack(spacing: 2) {
                    ForEach(Array(list.enumerated()), id: \.offset) { _, stop in
                        VStack(spacing: 1) {
                            ZStack {
                                CheckerBackground()
                                stop.color
                            }
                            .frame(height: 14)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            Text("\(stop.frame)").font(Theme.small).foregroundStyle(Theme.dim)
                        }
                    }
                }
            }
            HStack {
                Spacer()
                HelpBadge(text: "The first colour texture cut into UV Cell U × UV Cell V cells, numbered in the order sprites take them. Below: the four sprite colours and the frame each one is reached at.")
            }
        }
    }
}

struct CreationRibbonPanel: View {
    @ObservedObject var document: EffectDocument
    let emitter: AvfxBlock

    private struct Row {
        let title: String
        let enabled: Bool
        let ticks: [(time: Float, count: Int)]
        let tint: Color
    }

    private func build() -> (rows: [Row], life: Float) {
        guard let root = document.avfxRoot, let index = root.childrenNamed("Emit").firstIndex(where: { $0 === emitter }) else { return ([], 1) }
        let schema = AvfxSchemaReader.read(root)
        guard index < schema.emitters.count else { return ([], 1) }
        let e = schema.emitters[index]
        var life = e.life.value
        if life <= 0 || !life.isFinite { life = 60 }
        func ticks(_ item: REmitterItem) -> [(Float, Int)] {
            var result: [(Float, Int)] = []
            var t = Float(max(0, item.generateDelay))
            var guardCount = 0
            while t <= life, guardCount < 400 {
                guardCount += 1
                let at = CurveTime(t)
                let perItem = item.createTime == 1 ? max(0, item.createCount) : 1
                let count = Int(Eval.curve(e.createCount, at, 1).rounded()) * perItem
                if count > 0 { result.append((t, count)) }
                let interval = Eval.curve(e.createInterval, at, 0)
                if interval > 0, item.createTime == 0 { t += interval } else { break }
            }
            return result
        }
        var rows: [Row] = []
        for item in e.particleItems {
            rows.append(Row(title: "Particle \(item.target)", enabled: item.enabled, ticks: ticks(item), tint: NodeTint.particle.color))
        }
        for item in e.emitterItems {
            rows.append(Row(title: "Emitter \(item.target)", enabled: item.enabled, ticks: ticks(item), tint: NodeTint.emitter.color))
        }
        return (rows, life)
    }

    var body: some View {
        let data = build()
        if !data.rows.isEmpty {
            Panel(title: "Creation over Life", trailing: "\(Int(data.life)) frames") {
                ForEach(Array(data.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 6) {
                        Text(row.title).font(Theme.font).foregroundStyle(row.enabled ? Theme.text : Theme.dim).lineLimit(1).frame(width: 84, alignment: .leading)
                        Canvas { context, size in
                            context.fill(Path(CGRect(x: 0, y: size.height - 1, width: size.width, height: 1)), with: .color(Color.white.opacity(0.15)))
                            let peak = max(1, row.ticks.map(\.count).max() ?? 1)
                            for tick in row.ticks {
                                let x = CGFloat(tick.time / max(data.life, 1)) * (size.width - 2)
                                let h = max(3, (size.height - 2) * CGFloat(tick.count) / CGFloat(peak))
                                context.fill(Path(CGRect(x: x, y: size.height - h, width: 2, height: h)), with: .color(row.tint.opacity(row.enabled ? 1 : 0.35)))
                            }
                        }
                        .frame(height: 18)
                        Text("\(row.ticks.reduce(0) { $0 + $1.count })").font(Theme.small).foregroundStyle(Theme.dim).frame(width: 34, alignment: .trailing)
                    }
                }
                HStack {
                    Spacer()
                    HelpBadge(text: "When this emitter creates each of its particles and child emitters during one life, from Create Count and Create Interval without their random parts. Bar height is the count; the number on the right is the total.")
                }
            }
        }
    }
}
