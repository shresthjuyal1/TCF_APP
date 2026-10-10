import SwiftUI

/// The celebration screen shown after the last question.
struct LessonCompleteView: View {
    let correct: Int
    let total: Int
    let onContinue: () -> Void

    @State private var appeared = false

    private var accuracy: Int {
        total == 0 ? 0 : Int((Double(correct) / Double(total) * 100).rounded())
    }

    private var message: String {
        switch accuracy {
        case 90...: "Impressive!"
        case 70..<90: "Very good!"
        default: "Keep it up!"
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "trophy.fill")
                .font(.system(size: 96))
                .foregroundStyle(Theme.gold)
                .scaleEffect(appeared ? 1 : 0.3)
                .rotationEffect(.degrees(appeared ? 0 : -20))
                .symbolEffect(.bounce, value: appeared)

            VStack(spacing: 8) {
                Text("Lesson complete!")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.accent)
                Text(message)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .opacity(appeared ? 1 : 0)

            HStack(spacing: 16) {
                StatCard(title: "Correct", value: "\(correct)/\(total)", icon: "checkmark.circle.fill", color: Theme.correct)
                StatCard(title: "Accuracy", value: "\(accuracy)%", icon: "target", color: Theme.accent)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            Button("Continue", action: onContinue)
                .buttonStyle(ChunkyButtonStyle())
        }
        .padding()
        .background(Theme.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) {
                appeared = true
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(value)
            }
            .font(.title2.weight(.heavy))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16).strokeBorder(color, lineWidth: 2))
    }
}

#Preview {
    LessonCompleteView(correct: 8, total: 10) {}
        .fontDesign(.rounded)
}
