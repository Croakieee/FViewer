struct TimelineStart {
    enum What {
        case emitter(EmitterDef, end: Double, seed: UInt32)
        case clip(TimelineItem.Clip)
    }
    let time: Double
    let what: What
}

func timelineStarts(_ defs: EffectDefs, _ effectSeed: UInt32, trigger: Int? = nil, at: Double = 0, firing: Int = 0) -> [TimelineStart] {
    var out: [TimelineStart] = []
    for (ti, tl) in defs.def.timelines.enumerated() where tl.trigger == trigger {
        let tlStart = at + (tl.start ?? 0)
        for (ii, it) in tl.items.enumerated() {
            let time = tlStart + it.start
            switch it {
            case .clip(let c): out.append(TimelineStart(time: time, what: .clip(c)))
            case .emitter(let id, _, let end):
                let seed = firing != 0 ? hash(Int(effectSeed), ti, ii, firing) : hash(Int(effectSeed), ti, ii)
                out.append(TimelineStart(time: time, what: .emitter(defs.emitter(id), end: end.map { tlStart + $0 } ?? .infinity, seed: seed)))
            }
        }
    }
    return out.enumerated().sorted { $0.element.time != $1.element.time ? $0.element.time < $1.element.time : $0.offset < $1.offset }.map(\.element)
}
