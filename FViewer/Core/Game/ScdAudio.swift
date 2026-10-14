import AVFoundation
import Foundation

enum MsAdpcm {
    static let coefficients: [(Int, Int)] = [(256, 0), (512, -256), (0, 0), (192, 64), (240, 0), (460, -208), (392, -232)]
    static let adaptation = [230, 230, 230, 230, 307, 409, 512, 614, 768, 614, 512, 409, 307, 230, 230, 230]
    static let samplesPerBlock = 128

    static func header(channels: Int, rate: Int) -> [UInt8] {
        let align = blockAlign(channels)
        var out: [UInt8] = []
        out.appendU16(2)
        out.appendU16(UInt16(channels))
        out.appendU32(UInt32(rate))
        out.appendU32(UInt32(rate * align / samplesPerBlock))
        out.appendU16(UInt16(align))
        out.appendU16(4)
        out.appendU16(32)
        out.appendU16(UInt16(samplesPerBlock))
        out.appendU16(UInt16(coefficients.count))
        for pair in coefficients {
            out.appendU16(UInt16(bitPattern: Int16(pair.0)))
            out.appendU16(UInt16(bitPattern: Int16(pair.1)))
        }
        return out
    }

    static func blockAlign(_ channels: Int) -> Int { (7 + (samplesPerBlock - 2) / 2) * channels }

    private static func clamp16(_ value: Int) -> Int { min(32767, max(-32768, value)) }

    private static func encodeChannel(_ s: [Int], predictor: Int, delta start: Int) -> (nibbles: [UInt8], error: Int) {
        let c = coefficients[predictor]
        var s1 = s[1], s2 = s[0], delta = start, error = 0
        var nibbles: [UInt8] = []
        nibbles.reserveCapacity(s.count - 2)
        for index in 2..<s.count {
            let predicted = (s1 * c.0 + s2 * c.1) >> 8
            let difference = s[index] - predicted
            let step = Int(safe: (Double(difference) / Double(delta)).rounded())
            let nibble = min(7, max(-8, step))
            let made = clamp16(predicted + nibble * delta)
            error += (s[index] - made) * (s[index] - made)
            s2 = s1
            s1 = made
            delta = max(16, (adaptation[nibble & 0xF] * delta) >> 8)
            nibbles.append(UInt8(nibble & 0xF))
        }
        return (nibbles, error)
    }

    static func encode(_ samples: [Int16], channels: Int) -> [UInt8] {
        let frames = samples.count / max(1, channels)
        let blocks = (frames + samplesPerBlock - 1) / samplesPerBlock
        var out: [UInt8] = []
        out.reserveCapacity(blocks * blockAlign(channels))
        for block in 0..<blocks {
            var chosen: [(predictor: Int, delta: Int, nibbles: [UInt8], samples: [Int])] = []
            for channel in 0..<channels {
                var s = [Int](repeating: 0, count: samplesPerBlock)
                for index in 0..<samplesPerBlock {
                    let frame = block * samplesPerBlock + index
                    if frame < frames { s[index] = Int(samples[frame * channels + channel]) }
                }
                var best: (predictor: Int, delta: Int, nibbles: [UInt8], error: Int)?
                for predictor in coefficients.indices {
                    let c = coefficients[predictor]
                    var total = 0
                    for index in 2..<samplesPerBlock { total += abs(s[index] - ((s[index - 1] * c.0 + s[index - 2] * c.1) >> 8)) }
                    let mean = total / (samplesPerBlock - 2)
                    for delta in [max(16, mean / 4), max(16, mean / 2), max(16, mean)].map({ min($0, 32767) }) {
                        let result = encodeChannel(s, predictor: predictor, delta: delta)
                        if best == nil || result.error < best!.error { best = (predictor, delta, result.nibbles, result.error) }
                    }
                }
                chosen.append((best?.predictor ?? 0, best?.delta ?? 16, best?.nibbles ?? [], s))
            }
            for item in chosen { out.append(UInt8(item.predictor)) }
            for item in chosen { out.appendU16(UInt16(bitPattern: Int16(clamp16(item.delta)))) }
            for item in chosen { out.appendU16(UInt16(bitPattern: Int16(item.samples[1]))) }
            for item in chosen { out.appendU16(UInt16(bitPattern: Int16(item.samples[0]))) }
            var pending: UInt8?
            for index in 0..<(samplesPerBlock - 2) {
                for item in chosen {
                    if let high = pending {
                        out.append(high << 4 | item.nibbles[index])
                        pending = nil
                    } else {
                        pending = item.nibbles[index]
                    }
                }
            }
            if let high = pending { out.append(high << 4) }
        }
        return out
    }

    static func decode(_ data: [UInt8], channels: Int, blockAlign: Int) -> [Int16] {
        guard channels > 0, blockAlign >= 7 * channels else { return [] }
        var out: [Int16] = []
        var at = 0
        while at + blockAlign <= data.count {
            var predictor = [Int](repeating: 0, count: channels), delta = predictor, s1 = predictor, s2 = predictor
            for channel in 0..<channels { predictor[channel] = min(Int(data[at + channel]), coefficients.count - 1) }
            for channel in 0..<channels { delta[channel] = GameFiles.i16(data, at + channels + channel * 2) }
            for channel in 0..<channels { s1[channel] = GameFiles.i16(data, at + channels * 3 + channel * 2) }
            for channel in 0..<channels { s2[channel] = GameFiles.i16(data, at + channels * 5 + channel * 2) }
            for channel in 0..<channels { out.append(Int16(s2[channel])) }
            for channel in 0..<channels { out.append(Int16(s1[channel])) }
            var channel = 0
            for index in (at + 7 * channels)..<(at + blockAlign) {
                for raw in [Int(data[index] >> 4), Int(data[index] & 0xF)] {
                    let nibble = raw >= 8 ? raw - 16 : raw
                    let c = coefficients[predictor[channel]]
                    let made = clamp16(((s1[channel] * c.0 + s2[channel] * c.1) >> 8) + nibble * delta[channel])
                    s2[channel] = s1[channel]
                    s1[channel] = made
                    delta[channel] = min(max(16, (adaptation[raw] * delta[channel]) >> 8), 1 << 24)
                    out.append(Int16(made))
                    channel = (channel + 1) % channels
                }
            }
            at += blockAlign
        }
        return out
    }
}

extension GameFiles {
    static func scdAux(_ b: [UInt8], _ audio: ScdAudio) -> Int {
        guard i32(b, audio.offset + 28) & 1 != 0 else { return 0 }
        let size = i32(b, audio.offset + 0x20 + 4)
        return size > 0 && size <= audio.headerSize ? size : 0
    }

    static func scdOgg(_ b: [UInt8], _ audio: ScdAudio) -> [UInt8]? {
        guard audio.format == 0x06 else { return nil }
        let at = audio.offset + 0x20 + scdAux(b, audio)
        guard at >= 0, at + 24 <= b.count else { return nil }
        let mode = Int(b.u16(at)), key = b[at + 2]
        let tableSize = i32(b, at + 16), headerSize = i32(b, at + 20)
        let start = at + 0x20 + tableSize
        guard tableSize >= 0, headerSize >= 0, audio.dataLength >= 0, start + headerSize + audio.dataLength <= b.count, mode != 0x2003 else { return nil }
        var header = Array(b[start..<start + headerSize])
        if mode == 0x2002, key != 0 { for index in header.indices { header[index] ^= key } }
        return header + Array(b[(start + headerSize)..<(start + headerSize + audio.dataLength)])
    }

    static func scdSamples(_ b: [UInt8], _ audio: ScdAudio) -> [Int16] {
        let data = scdStream(b, audio)
        switch audio.format {
        case 0x0C:
            let at = audio.offset + 0x20 + scdAux(b, audio)
            return MsAdpcm.decode(data, channels: audio.channels, blockAlign: Int(b.u16(at + 12)))
        case 0x01:
            return stride(from: 0, to: data.count - 1, by: 2).map { Int16(bitPattern: UInt16(data[$0]) | UInt16(data[$0 + 1]) << 8) }
        default:
            return []
        }
    }

    static func scdEntry(samples: [Int16], channels: Int, rate: Int, flags: UInt32, aux: [UInt8]) -> [UInt8] {
        let format = MsAdpcm.header(channels: channels, rate: rate)
        let data = MsAdpcm.encode(samples, channels: channels)
        var out: [UInt8] = []
        out.appendU32(UInt32(data.count))
        out.appendU32(UInt32(channels))
        out.appendU32(UInt32(rate))
        out.appendU32(0x0C)
        out.appendU32(0)
        out.appendU32(0)
        out.appendU32(UInt32(aux.count + format.count))
        out.appendU32(flags)
        out.append(contentsOf: aux)
        out.append(contentsOf: format)
        out.append(contentsOf: data)
        return out
    }

    private static func scdTable(_ b: [UInt8]) -> (at: Int, count: Int)? {
        guard b.count >= 0x50, string(b, 0, max: 8) == "SEDBSSCF" else { return nil }
        let header = i16(b, 0x0E)
        guard header > 0, header + 0x20 <= b.count else { return nil }
        let sounds = i16(b, header), tracks = i16(b, header + 2), count = i16(b, header + 4)
        func padded(_ count: Int) -> Int { (count * 4 + 15) / 16 * 16 }
        return (header + 0x20 + padded(sounds) + padded(tracks), count)
    }

    static func scdReplacing(_ b: [UInt8], index: Int, entry: [UInt8]) -> [UInt8]? {
        let list = scdAudio(b)
        guard let table = scdTable(b), let target = list.first(where: { $0.id == index }) else { return nil }
        let ordered = list.sorted { $0.offset < $1.offset }
        guard let place = ordered.firstIndex(where: { $0.id == index }) else { return nil }
        let end = place + 1 < ordered.count ? ordered[place + 1].offset : b.count
        let header = i16(b, 0x0E)
        for slot in [8, 16, 24] where i32(b, header + slot) > target.offset { return nil }
        var fresh = entry
        while fresh.count % 16 != 0 { fresh.append(0) }
        let delta = fresh.count - (end - target.offset)
        var out = Array(b[0..<target.offset]) + fresh + Array(b[end...])
        for slot in 0..<table.count {
            let value = i32(out, table.at + slot * 4)
            if value > target.offset { put32(&out, table.at + slot * 4, UInt32(max(0, value + delta))) }
        }
        var padding = 0
        for audio in scdAudio(out) where audio.dataLength > 0 {
            let used = 0x20 + audio.headerSize + audio.dataLength
            padding += (16 - used % 16) % 16
        }
        put32(&out, 0x10, UInt32(max(0, out.count - (padding - padding % 16))))
        return out
    }

    static func pcm(from url: URL) throws -> (samples: [Int16], channels: Int, rate: Int) {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        guard file.length > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw NSError(domain: "FViewer", code: 1, userInfo: [NSLocalizedDescriptionKey: "The sound file is empty"])
        }
        try file.read(into: buffer)
        guard let channelData = buffer.floatChannelData else {
            throw NSError(domain: "FViewer", code: 1, userInfo: [NSLocalizedDescriptionKey: "The sound format is not supported"])
        }
        let channels = min(2, Int(format.channelCount)), frames = Int(buffer.frameLength)
        var samples = [Int16](repeating: 0, count: frames * channels)
        for channel in 0..<channels {
            let source = channelData[channel]
            for frame in 0..<frames { samples[frame * channels + channel] = Int16(max(-32768, min(32767, (source[frame] * 32767).rounded()))) }
        }
        return (samples, channels, Int(format.sampleRate))
    }

    static func wave(samples: [Int16], channels: Int, rate: Int) -> [UInt8] {
        var out = Array("RIFF".utf8)
        out.appendU32(UInt32(36 + samples.count * 2))
        out.append(contentsOf: Array("WAVEfmt ".utf8))
        out.appendU32(16)
        out.appendU16(1)
        out.appendU16(UInt16(channels))
        out.appendU32(UInt32(rate))
        out.appendU32(UInt32(rate * channels * 2))
        out.appendU16(UInt16(channels * 2))
        out.appendU16(16)
        out.append(contentsOf: Array("data".utf8))
        out.appendU32(UInt32(samples.count * 2))
        for sample in samples { out.appendU16(UInt16(bitPattern: sample)) }
        return out
    }
}
