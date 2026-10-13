import Foundation
import VfxCore

private final class SilentView: ParticleView {
    func setPlacement(_ m: Affine3, perspective: Double) {}
    func setColor(_ color: Rgb, brightness: Double, alpha: Double) {}
    func setUv(_ slot: UvSlot, scaleX: Double, scaleY: Double, scrollX: Double, scrollY: Double, rotation: Double) {}
    func setNineSlice(borderX: Double, borderY: Double, stretchX: Double, stretchY: Double) {}
    func setDistortPower(_ power: Double) {}
    func geometryChanged() {}
    func destroy() {}
}

private final class SilentFactory: ViewFactory {
    func hasTexture(_ name: String) -> Bool { true }
    func textureSize(_ name: String) -> (width: Double, height: Double) { (64, 64) }
    func createParticleView(_ spec: ParticleViewSpec) -> ParticleView { SilentView() }
}

final class DensityJob {
    private let frames: Int
    private var frame = 0
    private var simulation: AvfxSimulation?
    private var core: EffectCore?
    private let factory = SilentFactory()
    private(set) var values: [String: [Float]] = [:]
    var cancelled = false

    init?(document: EffectDocument, frames: Int) {
        self.frames = frames
        if let root = document.avfxRoot {
            simulation = AvfxSimulation(schema: AvfxSchemaReader.read(root))
        } else if document.jsonRoot != nil {
            let data = document.pixiData(filter: VisibilityFilter())
            guard let created = try? EffectCore(json: data, options: EffectCoreOptions(views: factory, models: [:], seed: UInt32(max(1, document.clock.seed)))) else { return nil }
            created.play()
            core = created
        } else {
            return nil
        }
    }

    private func record(_ counts: [String: Int]) {
        var total = 0
        for (key, count) in counts {
            total += count
            values[key, default: [Float](repeating: 0, count: frames)][frame] = Float(count)
        }
        values["*", default: [Float](repeating: 0, count: frames)][frame] = Float(total)
    }

    func step(_ budget: Int) -> Bool {
        var done = 0
        while frame < frames, done < budget {
            if let simulation {
                simulation.advance(1)
                var counts: [String: Int] = [:]
                for particle in simulation.particles { counts["e\(particle.emitter.schema.index)", default: 0] += 1 }
                record(counts)
            } else if let core {
                core.update(1.0 / core.fps)
                record(core.particleCounts())
            }
            frame += 1
            done += 1
        }
        return frame >= frames
    }
}

extension EffectDocument {
    func scheduleDensity() {
        densityJob?.cancelled = true
        densityJob = nil
        let wanted = previewRevision
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.previewRevision == wanted, self.densityRevision != wanted else { return }
            let span = max(self.sequencerRows.map(\.end).max() ?? 60, self.clock.endFrame ?? 0)
            guard let job = DensityJob(document: self, frames: min(max(Int(safe: span.rounded(.up)) + 1, 30), 900)) else { return }
            self.densityJob = job
            self.runDensity(job, revision: wanted)
        }
    }

    private func runDensity(_ job: DensityJob, revision wanted: Int) {
        guard !job.cancelled, revision == wanted else { return }
        if job.step(24) {
            density = job.values
            densityRevision = wanted
            densityJob = nil
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.012) { [weak self] in self?.runDensity(job, revision: wanted) }
        }
    }
}
