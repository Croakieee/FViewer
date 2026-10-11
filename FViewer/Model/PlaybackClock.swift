import Combine
import Foundation

final class PlaybackClock: ObservableObject {
    @Published var time: Double = 0
    @Published var playing = true
    @Published var loop = true
    @Published var status = ""
    var releaseTime: Double?
    var triggers: [(time: Double, index: Int)] = []
    var restartToken = 0

    func rewind() {
        time = 0
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
        let next = time + min(seconds, 0.1) * 30
        let ended = finished && next > 2
        let overrun = !held && next > duration + 150
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
