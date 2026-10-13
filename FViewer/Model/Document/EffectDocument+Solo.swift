import Foundation

extension EffectDocument {
    func topLevelID(_ id: String?) -> String? {
        guard let id else { return nil }
        let parts = id.split(separator: "/").map(String.init)
        guard parts.count >= 3 else { return nil }
        return parts.prefix(3).joined(separator: "/")
    }

    func soloRange(for selection: String?) -> (start: Double, end: Double)? {
        guard let top = topLevelID(selection) else { return nil }
        var parents: [String: [String]] = [:]
        for edge in graph.edges { parents[edge.to, default: []].append(edge.from) }
        var related: Set<String> = [top]
        var queue = [top]
        while let current = queue.popLast() {
            for parent in parents[current] ?? [] where related.insert(parent).inserted { queue.append(parent) }
        }
        var start = Double.infinity, end = -Double.infinity
        for row in sequencerRows {
            guard let rowID = row.nodeID else { continue }
            var target: String?
            if let node = node(rowID) {
                switch node.payload {
                case .avfx(_, _, let record?):
                    if let emitter = record.first(where: { $0.tag == "EmNo" })?.intValue, emitter >= 0 { target = "avfx/Emit/\(emitter)" }
                case .json(let item):
                    if let name = item["emitter"]?.string,
                       let index = (jsonRoot?["emitters"]?.elements ?? []).firstIndex(where: { $0["id"]?.string == name }) {
                        target = "json/emitters/\(index)"
                    }
                default: break
                }
            }
            let owner = topLevelID(rowID)
            guard (target.map { related.contains($0) } ?? false) || owner == top else { continue }
            start = min(start, row.start)
            end = max(end, row.end)
        }
        guard start.isFinite, end.isFinite else { return nil }
        var tail = 0.0
        if case .avfx(let block, _, _)? = node(top)?.payload, block.tag == "Ptcl", let life = block.child("Life")?.child("Val") {
            tail = max(0, Double(life.floatValue))
        } else if case .json(let json)? = node(top)?.payload, let life = json["life"]?.number, top.contains("/particles/") {
            tail = max(0, life)
        }
        return (max(0, start), max(end + min(tail, 600), start + 10))
    }

    func applySolo() {
        guard soloPreview else { return }
        if let range = soloRange(for: selectionID) {
            clock.startFrame = range.start.rounded(.down)
            clock.endFrame = range.end.rounded(.up)
        } else {
            clock.startFrame = 0
            clock.endFrame = savedEnd
        }
        isolateSelection = true
        if clock.time < clock.startFrame || clock.time > (clock.endFrame ?? .infinity) { clock.rewind() }
    }

    func setSolo(_ on: Bool) {
        guard on != soloPreview else { return }
        if on {
            savedEnd = clock.endFrame
            savedIsolate = isolateSelection
            soloPreview = true
            clock.loop = true
            applySolo()
            clock.rewind()
            clock.playing = true
        } else {
            soloPreview = false
            clock.startFrame = 0
            clock.endFrame = savedEnd
            isolateSelection = savedIsolate
        }
    }
}
