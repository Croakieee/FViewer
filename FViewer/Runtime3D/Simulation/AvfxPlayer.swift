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
    private var appliedEvents = -1
    private var statusTick = 0
    private var workTime: Double = 0
    private var frameRate: Double = 0
    private let stepFrames: Float = 0.5
    private var builtRoot: AvfxBlock?

    init(document: EffectDocument) {
        self.document = document
    }

    var schemaChanged: Bool { loadedRevision != document.previewRevision || loadedOriginal != document.showOriginal || loadedRules != PreviewRules.token }

    private func rebuild() {
        let sameSource = loadedOriginal == document.showOriginal && loadedRules == PreviewRules.token
        loadedRevision = document.previewRevision
        duration = document.duration
        loadedOriginal = document.showOriginal
        loadedRules = PreviewRules.token
        guard let root = (document.showOriginal ? document.original?.avfxRoot : nil) ?? document.avfxRoot else {
            simulation = nil
            builtRoot = nil
            return
        }
        if sameSource, simulation != nil, let builtRoot, builtRoot.sameContent(as: root) {
            Log.simulation.debug("Revision \(loadedRevision) leaves the effect unchanged, simulation kept")
            return
        }
        let started = CFAbsoluteTimeGetCurrent()
        builtRoot = root.deepCopy()
        let schema = AvfxSchemaReader.read(root)
        simulation = AvfxSimulation(schema: schema)
        rewindSimulation()
        Log.simulation.debug("Rebuilt for revision \(loadedRevision): \(schema.emitters.count) emitters, \(schema.particles.count) particles, \(Log.milliseconds(since: started))")
    }

    private func rewindSimulation() {
        simulation?.events = document.clock.playedEvents
        appliedEvents = document.clock.eventsRevision
        simulation?.restart()
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
        if appliedEvents != clock.eventsRevision { rewindSimulation() }
        clock.advance(elapsed, duration: max(duration, clock.lastEventFrame + 1), finished: simulation.finished, held: simulation.held)
        let target = (Float(clock.time) / stepFrames + 0.001).rounded(.down) * stepFrames
        if target < simulation.time - 0.01 { rewindSimulation() }
        var guardCount = 0
        while simulation.time < target - 0.001 && guardCount < 6000 {
            guardCount += 1
            let step = stepFrames
            if simulation.time + stepFrames > target + 0.001 { break }
            simulation.advance(step)
        }
        if !clock.playing { simulation.applyEvents() }
        let draws = simulation.render(camera: camera, filter: filter)
        statusTick += 1
        workTime = workTime * 0.9 + (CACurrentMediaTime() - began) * 100
        if elapsed > 1e-4 { frameRate = frameRate == 0 ? 1 / elapsed : frameRate * 0.9 + 0.1 / elapsed }
        if statusTick % 12 == 0 {
            let shown = (workTime * 10).rounded() / 10
            if clock.frameMilliseconds != shown { DispatchQueue.main.async { clock.frameMilliseconds = shown } }
            let rate = (frameRate).rounded()
            if clock.framesPerSecond != rate { DispatchQueue.main.async { clock.framesPerSecond = rate } }
        }
        if simulation.clipLog.count != loggedClips {
            loggedClips = simulation.clipLog.count
            let names = ["KILL": "Kill", "REST": "Reset", "END ": "End", "FADI": "Fade In", "ULLP": "Unlock Loop Point", "TRG ": "Trigger", "RTRG": "Random Trigger"]
            let lines = simulation.clipLog.map { "Frame \(Int(safe: $0.time.rounded())): \(names[$0.type] ?? $0.type.trimmingCharacters(in: .whitespaces))" }
            DispatchQueue.main.async { if clock.clipLog != lines { clock.clipLog = lines } }
        }
        if statusTick % 12 == 0 {
            let status = "\(simulation.particles.count) particles · \(simulation.emitters.count) emitters" + (simulation.held ? " · held" : "")
            if clock.status != status { clock.status = status }
            let states = simulation.timelineStates()
            if clock.timelineStates != states { DispatchQueue.main.async { if clock.timelineStates != states { clock.timelineStates = states } } }
        }
        return draws
    }
}
