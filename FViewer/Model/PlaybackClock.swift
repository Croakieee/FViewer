import Combine
import Foundation

final class PlaybackClock: ObservableObject {
    @Published var time: Double = 0
    @Published var playing = true
    @Published var loop = true
    @Published var status = ""
    @Published var endFrame: Double?
    @Published var startFrame: Double = 0
    @Published var speed: Double = 1
    @Published var seed = 1
    @Published var clipLog: [String] = []
    var releaseTime: Double?
    var triggers: [(time: Double, index: Int)] = []
    var restartToken = 0

    func rewind() {
        time = startFrame
        releaseTime = nil
        triggers = []
        restartToken += 1
    }

    func release() {
        if releaseTime == nil { releaseTime = time }
    }

    func trigger(_ index: Int) {
        triggers.append((time, index))
    }

    func advance(_ seconds: Double, duration: Double, finished: Bool, held: Bool) {
        guard playing else { return }
        let next = time + min(seconds, 0.1) * 30 * speed
        let ended = endFrame == nil && finished && next > 2 && !held
        let overrun = next >= (endFrame ?? max(duration, 1))
        if ended || overrun {
            if loop {
                rewind()
            } else {
                playing = false
            }
            return
        }
        time = next
    }
}
