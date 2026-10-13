import Foundation
import QuartzCore
import simd

final class AvfxPlayer {
    let document: EffectDocument
    private(set) var simulation: AvfxSimulation?
    private var loadedRevision = -1
    private var loadedOriginal = false
    private var loadedRules = -1
    private var loggedClips = -1
    private var duration: Double = 30
    private var appliedRelease = false
    private var appliedTriggers = 0
    private var statusTick = 0
    private var workTime: Double = 0
    private let stepFrames: Float = 0.5

    init(document: EffectDocument) {
        self.document = document
    }

    var schemaChanged: Bool { loadedRevision != document.previewRevision || loadedOriginal != document.showOriginal || loadedRules != PreviewRules.token }

    private func rebuild() {
        loadedRevision = document.previewRevision
        duration = document.duration
        loadedOriginal = document.showOriginal
        loadedRules = PreviewRules.token
        guard let root = (document.showOriginal ? document.original?.avfxRoot : nil) ?? document.avfxRoot else {
            simulation = nil
            return
        }
        simulation = AvfxSimulation(schema: AvfxSchemaReader.read(root))
        rewindSimulation()
    }

    private func rewindSimulation() {
        simulation?.restart()
        appliedRelease = false
        appliedTriggers = 0
    }

    func frame(elapsed: Double, camera: CameraState, filter: VisibilityFilter) -> [ParticleDraw] {
        if schemaChanged { rebuild() }
        guard let simulation else { return [] }
        let began = CACurrentMediaTime()
        let clock = document.clock
        let seed = UInt64(max(0, clock.seed))
        if simulation.seed != seed {
            simulation.seed = seed
            rewindSimulation()
        }
        clock.advance(elapsed, duration: duration, finished: simulation.finished, held: simulation.held)
        let target = Float(clock.time)
        if target < simulation.time - 0.01 || (!clock.playing && abs(simulation.time - target) > 0.001) { rewindSimulation() }
        var guardCount = 0
        while simulation.time < target - 0.001 && guardCount < 6000 {
            guardCount += 1
            let step = clock.playing ? stepFrames : min(stepFrames, target - simulation.time)
            if clock.playing && simulation.time + stepFrames > target + 0.001 { break }
            if let release = clock.releaseTime, !appliedRelease, Double(simulation.time) >= release {
                appliedRelease = true
                simulation.release()
            }
            while appliedTriggers < clock.triggers.count, Double(simulation.time) >= clock.triggers[appliedTriggers].time {
                simulation.trigger(clock.triggers[appliedTriggers].index)
                appliedTriggers += 1
            }
            simulation.advance(step)
        }
        let draws = simulation.render(camera: camera, filter: filter)
        statusTick += 1
        workTime = workTime * 0.9 + (CACurrentMediaTime() - began) * 100
        if statusTick % 12 == 0 {
            let shown = (workTime * 10).rounded() / 10
            if clock.frameMilliseconds != shown { DispatchQueue.main.async { clock.frameMilliseconds = shown } }
        }
        if simulation.clipLog.count != loggedClips {
            loggedClips = simulation.clipLog.count
            let names = ["KILL": "Kill", "REST": "Reset", "END ": "End", "FADI": "Fade In", "ULLP": "Unlock Loop Point", "TRG ": "Trigger", "RTRG": "Random Trigger"]
            let lines = simulation.clipLog.map { "Frame \(Int($0.time.rounded())): \(names[$0.type] ?? $0.type.trimmingCharacters(in: .whitespaces))" }
            DispatchQueue.main.async { if clock.clipLog != lines { clock.clipLog = lines } }
        }
        if statusTick % 12 == 0 {
            let status = "\(simulation.particles.count) particles · \(simulation.emitters.count) emitters" + (simulation.held ? " · held" : "")
            if clock.status != status { clock.status = status }
        }
        return draws
    }
}
