import Foundation

struct ReportLine: Identifiable {
    enum Level { case ok, info, warning, problem }

    let id = UUID()
    var level: Level
    var text: String
    var detail = ""
    var target: String?
}

struct ReportSection: Identifiable {
    let id = UUID()
    var title: String
    var lines: [ReportLine]
}

extension EffectDocument {
    private static var reportCache: [ObjectIdentifier: (revision: Int, token: Int, sections: [ReportSection])] = [:]

    func report(textureURL: (String) -> URL?, soundURL: (String) -> URL?) -> [ReportSection] {
        let key = ObjectIdentifier(self)
        if let cached = EffectDocument.reportCache[key], cached.revision == revision, cached.token == PreviewRules.token { return cached.sections }
        let sections = avfxRoot.map { buildReport($0, textureURL: textureURL, soundURL: soundURL) } ?? jsonReport()
        EffectDocument.reportCache[key] = (revision, PreviewRules.token, sections)
        return sections
    }

    private func jsonReport() -> [ReportSection] {
        guard let root = jsonRoot else { return [] }
        return [ReportSection(title: "Summary", lines: [
            ReportLine(level: .info, text: "Timelines \(root["timelines"]?.elements?.count ?? 0) · Emitters \(root["emitters"]?.elements?.count ?? 0) · Particles \(root["particles"]?.elements?.count ?? 0)"),
            ReportLine(level: .info, text: "Textures \(textureSlots.count) · Models \(modelNames.count)"),
        ])]
    }

    private func buildReport(_ root: AvfxBlock, textureURL: (String) -> URL?, soundURL: (String) -> URL?) -> [ReportSection] {
        let schema = AvfxSchemaReader.read(root)
        let particles = root.childrenNamed("Ptcl"), emitters = root.childrenNamed("Emit"), timelines = root.childrenNamed("TmLn")
        let textures = root.childrenNamed("Tex"), models = root.childrenNamed("Modl"), effectors = root.childrenNamed("Efct"), binders = root.childrenNamed("Bind")
        func name(_ enumName: String, _ value: Int) -> String { catalog.enumCaseName(enumName, value) ?? "\(value)" }
        var problems: [ReportLine] = []

        let version = root.int("Ver")
        var types: [String: Int] = [:]
        for particle in particles {
            var title = name("ParticleType", particle.int("PrVT"))
            if particle.int("bSCt") != 0 { title += " + Simple Animation" }
            types[title, default: 0] += 1
        }
        let summary = ReportSection(title: "Summary", lines: [
            ReportLine(level: .info, text: "Version \((version >> 24) & 0xff).\((version >> 16) & 0xff).\((version >> 8) & 0xff).\(version & 0xff)"),
            ReportLine(level: .info, text: "Timelines \(timelines.count) · Emitters \(emitters.count) · Particles \(particles.count)"),
            ReportLine(level: .info, text: "Effectors \(effectors.count) · Binders \(binders.count) · Textures \(textures.count) · Models \(models.count)"),
        ] + types.sorted { $0.key < $1.key }.map { ReportLine(level: .info, text: "\($0.key) × \($0.value)") })

        var users: [Int: [String]] = [:]
        for (i, particle) in particles.enumerated() {
            for layer in ["TC1", "TC2", "TC3", "TC4", "TN", "TR", "TD", "TP"] {
                guard let block = particle.child(layer), block.children != nil, block.int("bEna") != 0 else { continue }
                var indices: [Int] = []
                if let number = block.child("TxNo") { indices.append(number.intValue) }
                if let list = block.child("TLst") { indices.append(contentsOf: list.data.compactMap { $0 == 255 ? nil : Int($0) }) }
                for index in indices where index >= 0 {
                    if index < textures.count { users[index, default: []].append("P\(i) \(layer)") } else {
                        problems.append(ReportLine(level: .problem, text: "Particle \(i) \(layer) uses texture \(index)", detail: "the effect has \(textures.count)",
                                                   target: "avfx/Ptcl/\(i)"))
                    }
                }
            }
        }
        var textureLines: [ReportLine] = []
        for (i, block) in textures.enumerated() {
            let path = block.stringValue
            let used = users[i] ?? []
            let uses = used.isEmpty ? "unused" : used.prefix(6).joined(separator: ", ") + (used.count > 6 ? " +\(used.count - 6)" : "")
            guard let url = textureURL(path) else {
                textureLines.append(ReportLine(level: .problem, text: "\(i) · \(path)", detail: "missing · \(uses)", target: "avfx/Tex/\(i)"))
                problems.append(ReportLine(level: .problem, text: "Texture \(i) is missing", detail: path, target: "avfx/Tex/\(i)"))
                continue
            }
            var facts = url.pathExtension.uppercased()
            if let handle = try? FileHandle(forReadingFrom: url), let head = try? handle.read(upToCount: 16), head.count >= 16 {
                let bytes = [UInt8](head)
                let attributes = bytes.u32(0), format = TexFormat(rawValue: bytes.u32(4))?.name ?? String(format: "0x%X", bytes.u32(4))
                let width = Int(bytes[8]) | Int(bytes[9]) << 8, height = Int(bytes[10]) | Int(bytes[11]) << 8
                facts = "\(format) \(width)×\(height) · \(max(1, Int(bytes[14] & 0x7f))) mips" + (attributes & 0x2000000 != 0 ? " · cube" : "")
                try? handle.close()
            }
            textureLines.append(ReportLine(level: used.isEmpty ? .warning : .ok, text: "\(i) · \((path as NSString).lastPathComponent)",
                                           detail: "\(facts) · \(uses)", target: "avfx/Tex/\(i)"))
        }

        var modelUsers: [Int: [String]] = [:]
        for (i, particle) in schema.particles.enumerated() {
            for index in Set(particle.modelIndices + [particle.modelIndex]) where index >= 0 {
                if index < models.count { modelUsers[index, default: []].append("P\(i)") } else if [5, 13].contains(particle.type) {
                    problems.append(ReportLine(level: .problem, text: "Particle \(i) uses model \(index)", detail: "the effect has \(models.count)", target: "avfx/Ptcl/\(i)"))
                }
            }
        }
        for (i, emitter) in schema.emitters.enumerated() where emitter.type == 5 {
            if emitter.modelIndex >= 0, emitter.modelIndex < models.count { modelUsers[emitter.modelIndex, default: []].append("E\(i)") }
            else if emitter.modelIndex >= models.count {
                problems.append(ReportLine(level: .problem, text: "Emitter \(i) uses model \(emitter.modelIndex)", detail: "the effect has \(models.count)", target: "avfx/Emit/\(i)"))
            }
        }
        let modelLines = models.enumerated().map { i, model -> ReportLine in
            let vertices = (model.child("VDrw")?.data.count ?? 0) / 36, triangles = (model.child("VIdx")?.data.count ?? 0) / 6
            let points = (model.child("VEmt")?.data.count ?? 0) / 28
            let used = modelUsers[i] ?? []
            return ReportLine(level: used.isEmpty ? .warning : .ok, text: "Model \(i)",
                              detail: "\(vertices) vertices · \(triangles) triangles" + (points > 0 ? " · \(points) emit points" : "") + " · " + (used.isEmpty ? "unused" : used.joined(separator: ", ")),
                              target: "avfx/Modl/\(i)")
        }

        var soundLines: [ReportLine] = []
        for (i, emitter) in schema.emitters.enumerated() where !emitter.sound.isEmpty {
            let found = soundURL(emitter.sound) != nil
            soundLines.append(ReportLine(level: found ? .ok : .warning, text: "E\(i) · \((emitter.sound as NSString).lastPathComponent)",
                                         detail: (found ? "found" : "not in the open folder") + " · track \(emitter.soundIndex)", target: "avfx/Emit/\(i)"))
        }

        var binderLines: [ReportLine] = []
        for (i, binder) in schema.binders.enumerated() {
            let holder = binder.bindPoint == 1 ? "Target" : "Caster"
            let point = binder.bindTargetPoint == 3 ? "point \(binder.bindPointId)" : name("BindTargetPoint", binder.bindTargetPoint)
            binderLines.append(ReportLine(level: .info, text: "Binder \(i) · \(name("BinderType", binder.type))", detail: "\(holder) · \(point)", target: "avfx/Bind/\(i)"))
        }

        for (i, emitter) in emitters.enumerated() {
            let effector = emitter.int("EfNo", -1)
            if effector >= effectors.count {
                problems.append(ReportLine(level: .problem, text: "Emitter \(i) uses effector \(effector)", detail: "the effect has \(effectors.count)", target: "avfx/Emit/\(i)"))
            }
        }
        for (t, timeline) in timelines.enumerated() {
            let items = timeline.ownRecords("Item")
            if items.count > 32 {
                problems.append(ReportLine(level: .warning, text: "Timeline \(t) has \(items.count) items", detail: "the game runs only the first 32", target: "avfx/TmLn/\(t)"))
            }
            for (k, record) in items.enumerated() {
                func value(_ tag: String) -> Int { record.first { $0.tag == tag }?.intValue ?? -1 }
                let emitter = value("EmNo"), clip = value("ClNo"), binder = value("BdNo")
                if emitter >= emitters.count {
                    problems.append(ReportLine(level: .problem, text: "Timeline \(t) item \(k) starts emitter \(emitter)", detail: "the effect has \(emitters.count)", target: "avfx/TmLn/\(t)"))
                }
                if binder >= binders.count {
                    problems.append(ReportLine(level: .problem, text: "Timeline \(t) item \(k) uses binder \(binder)", detail: "the effect has \(binders.count)", target: "avfx/TmLn/\(t)"))
                }
                if emitter < 0 && clip < 0 {
                    problems.append(ReportLine(level: .warning, text: "Timeline \(t) item \(k) starts nothing", detail: "no emitter and no clip", target: "avfx/TmLn/\(t)"))
                }
            }
        }

        var coverage: [ReportLine] = []
        for (i, particle) in particles.enumerated() {
            let type = particle.int("PrVT")
            let target = "avfx/Ptcl/\(i)"
            switch type {
            case 0: coverage.append(ReportLine(level: .info, text: "Particle \(i) · Parameter", detail: "has no geometry, nothing to draw (as in the game)", target: target))
            case 3 where particle.int("bSCt") == 0:
                coverage.append(ReportLine(level: .info, text: "Particle \(i) · Line", detail: "without Simple Animation it is a helper and is not drawn (as in the game)", target: target))
            case 14: coverage.append(ReportLine(level: .info, text: "Particle \(i) · Model Skin", detail: "drawn over the loaded model (File → Game → Load Model)", target: target))
            case 15: coverage.append(ReportLine(level: .info, text: "Particle \(i) · Dissolve", detail: "dissolves the loaded model (File → Game → Load Model)", target: target))
            case 10, 11: coverage.append(ReportLine(level: .info, text: "Particle \(i) · \(name("ParticleType", type))", detail: "projects onto the floor and the loaded model; walls of the game's scene are not there", target: target))
            default: break
            }
        }
        for (i, effector) in effectors.enumerated() {
            let kind = effector.int("EfVT")
            let target = "avfx/Efct/\(i)"
            switch kind {
            case 2, 8: coverage.append(ReportLine(level: .warning, text: "Effector \(i) · \(name("EffectorType", kind))", detail: "not previewed", target: target))
            case 0 where effector.child("Data")?.int("bSdw") != 0:
                coverage.append(ReportLine(level: .info, text: "Effector \(i) · Point Light with shadow", detail: "only the loaded model casts it", target: target))
            default: break
            }
        }
        if !schema.emitters.filter({ !$0.sound.isEmpty }).isEmpty, soundLines.contains(where: { $0.level != .ok }) {
            coverage.append(ReportLine(level: .warning, text: "Emitter sounds", detail: "some .scd files are not in the open folder, they stay silent"))
        }
        var unused: [String: [String]] = [:]
        func visit(_ node: OutlineNode) {
            for section in sections(for: node) {
                for field in section.fields where field.unseen && field.read().number != 0 {
                    unused[field.label + " (\(field.tag))", default: []].append(node.title)
                }
            }
            node.children.forEach(visit)
        }
        outline.forEach(visit)
        let unusedLines = unused.sorted { $0.key < $1.key }.map { key, holders in
            ReportLine(level: .info, text: key, detail: holders.prefix(4).joined(separator: ", ") + (holders.count > 4 ? " +\(holders.count - 4)" : ""))
        }

        var out = [summary]
        out.append(ReportSection(title: "Problems", lines: problems.isEmpty ? [ReportLine(level: .ok, text: "No broken references or missing files")] : problems))
        if !textureLines.isEmpty { out.append(ReportSection(title: "Textures", lines: textureLines)) }
        if !modelLines.isEmpty { out.append(ReportSection(title: "Models", lines: modelLines)) }
        if !soundLines.isEmpty { out.append(ReportSection(title: "Sounds", lines: soundLines)) }
        if !binderLines.isEmpty { out.append(ReportSection(title: "Binders", lines: binderLines)) }
        out.append(ReportSection(title: "Preview Coverage", lines: coverage.isEmpty ? [ReportLine(level: .ok, text: "Everything in this effect is drawn by the preview")] : coverage))
        if !unusedLines.isEmpty { out.append(ReportSection(title: "Set but Not Previewed", lines: unusedLines)) }
        return out
    }
}
