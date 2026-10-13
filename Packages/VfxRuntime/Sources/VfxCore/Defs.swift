import Foundation

public enum DefinitionError: Error, CustomStringConvertible {
    case invalid(String)
    public var description: String {
        switch self {
        case .invalid(let s): return s
        }
    }
}

final class EffectDefs {
    let def: EffectDef
    let table: ParamTable
    private var emitters: [String: EmitterDef] = [:]
    private var particles: [String: ParticleDef] = [:]
    private var models: [String: ModelData] = [:]

    init(_ def: EffectDef, table: ParamTable, hasTexture: (String) -> Bool, models allModels: [String: ModelData], params: [String: Double]) throws {
        self.def = def
        self.table = table
        let declared = def.params ?? [:]
        for name in table.cells.keys where declared[name] == nil {
            throw DefinitionError.invalid("unknown param \"\(name)\" (declare it in \"params\")")
        }
        for (name, value) in declared { table.cell(name).value = value }
        for (name, value) in params {
            guard declared[name] != nil else { throw DefinitionError.invalid("unknown param \"\(name)\"") }
            table.cell(name).value = value
        }
        for e in def.emitters { emitters[e.id] = e }
        for p in def.particles {
            let layers = p.layers ?? []
            if layers.count > maxLayers { throw DefinitionError.invalid("particle \"\(p.id)\": at most \(maxLayers) layers") }
            for name in [p.texture] + layers.map(\.texture) + [p.distortion?.texture] {
                if let name, !hasTexture(name) { throw DefinitionError.invalid("particle \"\(p.id)\": unknown texture \"\(name)\"") }
            }
            if case .mesh(let model) = p.shape {
                guard let m = allModels[model] else { throw DefinitionError.invalid("particle \"\(p.id)\": unknown model \"\(model)\"") }
                models[model] = m
            }
            if !p.forever && !(p.life.minValue > 0) { throw DefinitionError.invalid("particle \"\(p.id)\": life must be > 0 or -1") }
            var resolved = p
            if let material = p.material { resolved.material = material.resolved(shared: def.materials ?? [:]) }
            particles[p.id] = resolved
        }
        for e in def.emitters {
            for it in e.items {
                switch it.target {
                case .particle(let id): if particles[id] == nil { throw DefinitionError.invalid("emitter \"\(e.id)\": unknown particle \"\(id)\"") }
                case .emitter(let id): if emitters[id] == nil { throw DefinitionError.invalid("emitter \"\(e.id)\": unknown emitter \"\(id)\"") }
                }
                if it.repeat == true && !((it.interval ?? 0) > 0) { throw DefinitionError.invalid("emitter \"\(e.id)\": \"repeat\" needs \"interval\" > 0") }
            }
        }
        for tl in def.timelines {
            for it in tl.items {
                if case .emitter(let id, _, _) = it, emitters[id] == nil { throw DefinitionError.invalid("timeline: unknown emitter \"\(id)\"") }
            }
        }
    }

    func emitter(_ id: String) -> EmitterDef { emitters[id]! }
    func particle(_ id: String) -> ParticleDef { particles[id]! }
    func model(_ name: String) -> ModelData { models[name]! }

    func particleTextures(_ p: ParticleDef) -> ParticleTextures {
        let targets = p.distortion?.targets
        let distorts = { (t: Distortion.Target) in p.distortion != nil && (targets == nil || targets!.contains(t)) }
        return ParticleTextures(
            base: p.texture,
            baseColorToAlpha: p.colorToAlpha ?? false,
            baseLuminance: p.luminance ?? false,
            baseChannel: p.uv?.channel ?? 1,
            layers: (p.layers ?? []).enumerated().map { i, l in
                ParticleLayer(
                    texture: l.texture, combine: l.combine ?? .multiply, alpha: l.alpha ?? .multiply,
                    colorToAlpha: l.colorToAlpha ?? false, distorted: distorts(.layer(i)), channel: l.uv?.channel ?? 1)
            },
            distortion: p.distortion.map { ($0.texture, distorts(.texture), $0.uv?.channel ?? 1) })
    }
}
