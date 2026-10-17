import AVFoundation
import Foundation
import QuartzCore

final class EmitterSounds {
    static let shared = EmitterSounds()
    static var locate: ((String) -> URL?)?

    private struct Clip {
        let buffer: AVAudioPCMBuffer
        let loop: (start: AVAudioFramePosition, end: AVAudioFramePosition)?
        var duration: Double { Double(buffer.frameLength) / buffer.format.sampleRate }
    }

    private final class Voice {
        let owner: ObjectIdentifier
        let emitter: ObjectIdentifier
        let node: AVAudioPlayerNode
        let endsAt: Double?

        init(owner: ObjectIdentifier, emitter: ObjectIdentifier, node: AVAudioPlayerNode, endsAt: Double?) {
            self.owner = owner
            self.emitter = emitter
            self.node = node
            self.endsAt = endsAt
        }
    }

    private let engine = AVAudioEngine()
    private var clips: [String: Clip?] = [:]
    private var voices: [Voice] = []
    private(set) var missing: Set<String> = []
    var playingCount: Int { voices.count }
    private var leaders: [ObjectIdentifier: (player: ObjectIdentifier, seen: Double)] = [:]

    func lead(document: ObjectIdentifier, player: ObjectIdentifier) -> Bool {
        let now = CACurrentMediaTime()
        if let leader = leaders[document], leader.player != player, now - leader.seen < 0.5 { return false }
        leaders[document] = (player, now)
        return true
    }

    func play(path: String, index: Int, owner: ObjectIdentifier, emitter: ObjectIdentifier) {
        guard voices.count < 32, let clip = clip(path: path, index: index) else { return }
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: clip.buffer.format)
        if !engine.isRunning, (try? engine.start()) == nil {
            engine.detach(node)
            return
        }
        if let loop = clip.loop, let intro = slice(clip.buffer, 0, loop.end), let body = slice(clip.buffer, loop.start, loop.end) {
            node.scheduleBuffer(intro, at: nil)
            node.scheduleBuffer(body, at: nil, options: .loops)
            voices.append(Voice(owner: owner, emitter: emitter, node: node, endsAt: nil))
        } else {
            node.scheduleBuffer(clip.buffer, at: nil)
            voices.append(Voice(owner: owner, emitter: emitter, node: node, endsAt: CACurrentMediaTime() + clip.duration + 0.1))
        }
        node.play()
    }

    func loops(path: String, index: Int) -> Bool { clip(path: path, index: index)?.loop != nil }

    func update(owner: ObjectIdentifier, alive: Set<ObjectIdentifier>) {
        let now = CACurrentMediaTime()
        remove { $0.owner == owner && ($0.endsAt.map { now > $0 } ?? !alive.contains($0.emitter)) }
    }

    func stop(owner: ObjectIdentifier) { remove { $0.owner == owner } }

    func resign(_ player: ObjectIdentifier) {
        stop(owner: player)
        leaders = leaders.filter { $0.value.player != player }
    }

    private func remove(_ condition: (Voice) -> Bool) {
        for voice in voices where condition(voice) {
            voice.node.stop()
            engine.detach(voice.node)
        }
        voices.removeAll(where: condition)
        if voices.isEmpty, engine.isRunning { engine.pause() }
    }

    private func clip(path: String, index: Int) -> Clip? {
        let key = path.lowercased() + "#\(index)"
        if let known = clips[key] { return known }
        let made = load(path: path, index: index)
        clips[key] = .some(made)
        if made == nil { missing.insert(path) }
        return made
    }

    private func load(path: String, index: Int) -> Clip? {
        guard let url = EmitterSounds.locate?(path), let data = try? Data(contentsOf: url) else { return nil }
        let bytes = [UInt8](data)
        let entries = GameFiles.scdAudio(bytes).filter { $0.format != -1 && $0.dataLength > 0 }
        guard !entries.isEmpty else { return nil }
        let audio = entries.first { $0.id == index } ?? entries[min(max(index, 0), entries.count - 1)]
        let file: [UInt8]
        let suffix: String
        if audio.format == 0x06, let ogg = GameFiles.scdOgg(bytes, audio) {
            file = ogg
            suffix = "ogg"
        } else if let wave = GameFiles.scdWave(bytes, audio) {
            file = wave
            suffix = "wav"
        } else {
            return nil
        }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("fviewer-sound-\(UUID().uuidString).\(suffix)")
        defer { try? FileManager.default.removeItem(at: temp) }
        guard (try? Data(file).write(to: temp)) != nil, let reader = try? AVAudioFile(forReading: temp),
              let buffer = AVAudioPCMBuffer(pcmFormat: reader.processingFormat, frameCapacity: AVAudioFrameCount(max(1, reader.length))),
              (try? reader.read(into: buffer)) != nil, buffer.frameLength > 0 else { return nil }
        return Clip(buffer: buffer, loop: loop(bytes, audio, ogg: suffix == "ogg" ? file : nil, frames: AVAudioFramePosition(buffer.frameLength)))
    }

    private func loop(_ b: [UInt8], _ audio: ScdAudio, ogg: [UInt8]?, frames: AVAudioFramePosition) -> (start: AVAudioFramePosition, end: AVAudioFramePosition)? {
        var start: AVAudioFramePosition = -1, end: AVAudioFramePosition = -1
        if let ogg {
            start = comment("LoopStart=", ogg) ?? -1
            end = comment("LoopEnd=", ogg) ?? (start >= 0 ? frames : -1)
        } else if audio.loopEnd > 0 {
            let channels = max(1, audio.channels)
            if audio.format == 0x01 {
                start = AVAudioFramePosition(audio.loopStart / (2 * channels))
                end = AVAudioFramePosition(audio.loopEnd / (2 * channels))
            } else if audio.format == 0x0C {
                let at = audio.offset + 0x20 + GameFiles.scdAux(b, audio) + 12
                let block = at + 2 <= b.count ? Int(b[at]) | Int(b[at + 1]) << 8 : 0
                guard block > 7 * channels else { return nil }
                let perBlock = (block / channels - 7) * 2 + 2
                func samples(_ bytes: Int) -> AVAudioFramePosition { AVAudioFramePosition(bytes / block * perBlock) }
                start = samples(audio.loopStart)
                end = samples(audio.loopEnd)
            }
        }
        end = min(end, frames)
        guard start >= 0, end > start + 16 else { return nil }
        return (start, end)
    }

    private func comment(_ name: String, _ ogg: [UInt8]) -> AVAudioFramePosition? {
        let key = Array(name.lowercased().utf8)
        let limit = min(ogg.count, 16384) - key.count
        guard limit > 0 else { return nil }
        for at in 0..<limit {
            var matched = true
            for k in 0..<key.count where (ogg[at + k] | (ogg[at + k] >= 65 && ogg[at + k] <= 90 ? 32 : 0)) != key[k] {
                matched = false
                break
            }
            guard matched else { continue }
            var value: AVAudioFramePosition = 0, digits = 0, p = at + key.count
            while p < ogg.count, ogg[p] >= 48, ogg[p] <= 57, digits < 12 {
                value = value * 10 + AVAudioFramePosition(ogg[p] - 48)
                p += 1
                digits += 1
            }
            return digits > 0 ? value : nil
        }
        return nil
    }

    private func slice(_ buffer: AVAudioPCMBuffer, _ from: AVAudioFramePosition, _ to: AVAudioFramePosition) -> AVAudioPCMBuffer? {
        let count = AVAudioFrameCount(max(0, min(to, AVAudioFramePosition(buffer.frameLength)) - from))
        guard count > 0, let out = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: count), let source = buffer.floatChannelData,
              let target = out.floatChannelData else { return nil }
        for channel in 0..<Int(buffer.format.channelCount) {
            (target[channel]).update(from: source[channel].advanced(by: Int(from)), count: Int(count))
        }
        out.frameLength = count
        return out
    }
}
