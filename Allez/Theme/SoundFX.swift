import AVFoundation

/// Cheerful sound effects, generated in code when the app starts (no sound files).
/// They follow the phone's silent switch and can be turned off in Settings.
final class SoundFX {
    enum Effect: CaseIterable {
        case pop, correct, wrong, fanfare, streak, sparkle, magic
    }

    static let shared = SoundFX()
    /// Set from Settings.
    static var isMuted = false

    private static let sampleRate = 44_100.0
    private let engine = AVAudioEngine()
    private let players = (0..<6).map { _ in AVAudioPlayerNode() }
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundFX.sampleRate, channels: 1)!
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    /// "Boing" sounds for the easter eggs, each one a little higher than the last.
    private var boings: [AVAudioPCMBuffer] = []
    private var nextPlayer = 0

    private init() {
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.8
        for effect in Effect.allCases {
            buffers[effect] = makeBuffer(Self.samples(for: effect))
        }
        boings = (0..<10).map { makeBuffer(Self.boing(step: $0)) }
    }

    func play(_ effect: Effect) {
        guard let buffer = buffers[effect] else { return }
        schedule(buffer)
    }

    /// A springy "boing"; `step` 0…9 makes it higher with each tap.
    func playBoing(step: Int) {
        schedule(boings[min(max(step, 0), boings.count - 1)])
    }

    private func schedule(_ buffer: AVAudioPCMBuffer) {
        guard !Self.isMuted else { return }
        if !Speaker.shared.isSpeaking {
            Self.useAmbientSession()
        }
        if !engine.isRunning {
            try? engine.start()
        }
        guard engine.isRunning else { return }
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }

    /// "Ambient" audio is silenced by the silent switch and mixes with music from other apps.
    static func useAmbientSession() {
        let session = AVAudioSession.sharedInstance()
        if session.category != .ambient {
            try? session.setCategory(.ambient, options: .mixWithOthers)
        }
        try? session.setActive(true)
    }

    private func makeBuffer(_ samples: [Float]) -> AVAudioPCMBuffer {
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            buffer.floatChannelData![0].update(from: source.baseAddress!, count: samples.count)
        }
        return buffer
    }

    // MARK: Sound design

    private struct Note {
        var frequency: Double
        var start: Double
        var duration: Double
        var volume: Double = 0.3
        /// Multiplies the frequency over the note, e.g. 1.6 slides up, 0.75 slides down.
        var glide: Double = 1
        var soft = false
    }

    /// Mixes notes with a quick attack and a smooth fade, plus a touch of overtone for brightness.
    private static func render(_ notes: [Note], noise: [(start: Double, duration: Double, volume: Double)] = []) -> [Float] {
        let length = (notes.map { $0.start + $0.duration } + noise.map { $0.start + $0.duration }).max() ?? 0.1
        var out = [Float](repeating: 0, count: Int((length + 0.02) * sampleRate))
        for note in notes {
            let first = Int(note.start * sampleRate)
            let count = Int(note.duration * sampleRate)
            var phase = 0.0
            for i in 0..<count where first + i < out.count {
                let t = Double(i) / sampleRate
                let progress = t / note.duration
                let frequency = note.frequency * pow(note.glide, progress)
                phase += 2 * .pi * frequency / sampleRate
                let attack = min(t / 0.006, 1)
                let release = pow(1 - progress, note.soft ? 1.2 : 2.2)
                let wave = note.soft
                    ? (2 / .pi) * asin(sin(phase))               // triangle: rounder, for the "bonk"
                    : sin(phase) + 0.25 * sin(2 * phase) + 0.08 * sin(3 * phase)
                out[first + i] += Float(wave * note.volume * attack * release)
            }
        }
        var seed: UInt64 = 42
        for burst in noise {
            let first = Int(burst.start * sampleRate)
            let count = Int(burst.duration * sampleRate)
            var smoothed = 0.0
            for i in 0..<count where first + i < out.count {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let white = Double(seed >> 33) / Double(1 << 31) - 1
                let progress = Double(i) / Double(count)
                let cutoff = 0.05 + 0.5 * progress          // the hiss opens up: a "whoosh"
                smoothed += cutoff * (white - smoothed)
                out[first + i] += Float(smoothed * burst.volume * sin(.pi * progress))
            }
        }
        return out.map { max(-0.95, min(0.95, $0)) }
    }

    private static func samples(for effect: Effect) -> [Float] {
        switch effect {
        case .pop:
            return render([Note(frequency: 520, start: 0, duration: 0.07, volume: 0.28, glide: 1.8)])
        case .correct:
            return render([
                Note(frequency: 880, start: 0, duration: 0.14),
                Note(frequency: 1318.5, start: 0.09, duration: 0.38),
            ])
        case .wrong:
            return render([
                Note(frequency: 220, start: 0, duration: 0.16, volume: 0.32, glide: 0.9, soft: true),
                Note(frequency: 164.8, start: 0.13, duration: 0.32, volume: 0.32, glide: 0.85, soft: true),
            ])
        case .fanfare:
            let arpeggio = [523.25, 659.25, 783.99].enumerated().map { index, frequency in
                Note(frequency: frequency, start: Double(index) * 0.11, duration: 0.16, volume: 0.25)
            }
            let chord = [523.25, 659.25, 783.99, 1046.5].map {
                Note(frequency: $0, start: 0.34, duration: 0.75, volume: 0.17)
            }
            return render(arpeggio + chord)
        case .streak:
            return render([
                Note(frequency: 1046.5, start: 0.28, duration: 0.3, volume: 0.22),
                Note(frequency: 1568, start: 0.38, duration: 0.5, volume: 0.2),
            ], noise: [(0, 0.4, 0.5)])
        case .sparkle:
            return render([1318.5, 1568, 1975.5, 2637].enumerated().map { index, frequency in
                Note(frequency: frequency, start: Double(index) * 0.06, duration: 0.3, volume: 0.15)
            })
        case .magic:
            let shimmer = [1568, 1975.5, 2349.3, 3136, 2637].enumerated().map { index, frequency in
                Note(frequency: frequency, start: 0.25 + Double(index) * 0.07, duration: 0.35, volume: 0.12)
            }
            return render([Note(frequency: 400, start: 0, duration: 0.45, volume: 0.2, glide: 5)] + shimmer,
                          noise: [(0, 0.12, 0.6)])
        }
    }

    private static func boing(step: Int) -> [Float] {
        let base = 260 * pow(2, Double(step) / 6)
        let duration = 0.3
        var out = [Float](repeating: 0, count: Int(duration * sampleRate))
        var phase = 0.0
        for i in 0..<out.count {
            let t = Double(i) / sampleRate
            // The pitch wobbles like a spring and settles down.
            let frequency = base * (1 + 0.5 * sin(2 * .pi * 7 * t) * exp(-7 * t))
            phase += 2 * .pi * frequency / sampleRate
            let envelope = min(t / 0.005, 1) * pow(1 - t / duration, 2)
            out[i] = Float(sin(phase) * 0.3 * envelope)
        }
        return out
    }
}
