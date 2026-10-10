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
                Text("Bientôt disponible")
                    .font(.title.weight(.heavy))
                Text("Ici, tu pourras t'enregistrer, te réécouter et comparer avec une réponse modèle.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .navigationTitle(Skill.speaking.title)
        }
    }
}

#Preview {
    SpeakingView()
        .fontDesign(.rounded)
}
