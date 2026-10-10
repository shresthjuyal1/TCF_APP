import SwiftUI

/// A full timed test, like exam day: no feedback until the end.
struct TestView: View {
    let test: QuestionSet

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var answers: [Int?]
    @State private var secondsLeft: Int
    @State private var isFinished = false
    @State private var ranOutOfTime = false
    @State private var showQuitAlert = false

    init(test: QuestionSet) {
        self.test = test
        _answers = State(initialValue: Array(repeating: nil, count: test.questions.count))
        _secondsLeft = State(initialValue: (test.timeLimitMinutes ?? 60) * 60)
    }

    private var isLastQuestion: Bool { index == test.questions.count - 1 }

    var body: some View {
        if isFinished {
            TestResultsView(test: test, answers: answers, ranOutOfTime: ranOutOfTime) {
                dismiss()
            }
        } else {
            VStack(spacing: 0) {
                header
                ScrollView {
                    QuestionView(
                        question: test.questions[index],
                        selectedIndex: Binding(get: { answers[index] }, set: { answers[index] = $0 }),
                        isChecked: false,
                        showsTranslation: false
                    )
                    .padding()
                    .padding(.bottom, 24)
                }
                .id(index)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))

                Button(isLastQuestion ? "Terminer" : (answers[index] == nil ? "Passer" : "Suivant"), action: next)
                    .buttonStyle(ChunkyButtonStyle())
                    .padding()
            }
            .task(runTimer)
            .alert("Quitter le test ?", isPresented: $showQuitAlert) {
                Button("Continuer le test", role: .cancel) {}
                Button("Quitter", role: .destructive) { dismiss() }
            } message: {
                Text("Tes réponses ne seront pas enregistrées.")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    showQuitAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Quitter")

                Text("Question \(index + 1) / \(test.questions.count)")
                    .font(.headline)
                Spacer()
                TimerPill(secondsLeft: secondsLeft)
            }
            LessonProgressBar(progress: Double(index) / Double(test.questions.count))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private func next() {
        if isLastQuestion {
            withAnimation { isFinished = true }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { index += 1 }
        }
    }

    @Sendable private func runTimer() async {
        while secondsLeft > 0 {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return }
            secondsLeft -= 1
        }
        ranOutOfTime = true
        withAnimation { isFinished = true }
    }
}

private struct TimerPill: View {
    let secondsLeft: Int

    private var isRunningOut: Bool { secondsLeft < 5 * 60 }

    var body: some View {
        Label(String(format: "%d:%02d", secondsLeft / 60, secondsLeft % 60), systemImage: "timer")
            .font(.subheadline.weight(.bold).monospacedDigit())
            .foregroundStyle(isRunningOut ? Theme.wrong : Theme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(isRunningOut ? Theme.wrongBackground : Theme.accentBackground))
    }
}
