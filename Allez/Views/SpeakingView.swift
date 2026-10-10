import SwiftUI

/// Placeholder for the speaking practice tab (build step 7).
struct SpeakingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 72))
                    .foregroundStyle(Theme.accent)
                    .symbolEffect(.pulse)
                Text("Coming soon")
                    .font(.title.weight(.heavy))
                Text("Here you'll be able to record yourself, listen back, and compare with a model answer.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .navigationTitle(Skill.speaking.title)
        }
    }
}

#Preview {
    SpeakingView()
        .fontDesign(.rounded)
}
