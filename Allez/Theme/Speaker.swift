import AVFoundation
import SwiftUI

/// Reads French text aloud with the iPhone's built-in French voice.
/// Only used from the main thread, so it's safe to share.
final class Speaker: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    var isSpeaking: Bool { synthesizer.isSpeaking }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        // The voice plays even with the silent switch on, like other language apps.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }

    /// Afterwards, go back to normal so sound effects respect the silent switch again.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        SoundFX.useAmbientSession()
    }
}

/// A small speaker button that reads the given French text aloud.
struct SpeakButton: View {
    let text: String

    var body: some View {
        Button {
            Speaker.shared.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Theme.accentBackground))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Listen")
    }
}
