import SwiftUI

/// Runs one lesson: shows each question, checks the answer, and shows feedback.
struct LessonView: View {
    let unit: LessonUnit
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var isChecked = false
    @State private var correctCount = 0
    @State private var isFinished = false
    @State private var showQuitAlert = false

    private var question: Question { unit.questions[currentIndex] }
    private var isCorrect: Bool { selectedIndex == question.correctIndex }
    private var progress: Double {
        Double(currentIndex + (isChecked ? 1 : 0)) / Double(unit.questions.count)
    }

    var body: some View {
        if isFinished {
            LessonCompleteView(correct: correctCount, total: unit.questions.count) {
                onComplete()
                dismiss()
            }
        } else {
            VStack(spacing: 0) {
                header
                ScrollView {
                    QuestionView(question: question, selectedIndex: $selectedIndex, isChecked: isChecked)
                        .padding()
                        .padding(.bottom, 24)
                }
                .id(currentIndex)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
                bottomBar
            }
            .sensoryFeedback(trigger: isChecked) { _, checked in
                checked ? (isCorrect ? .success : .error) : nil
            }
            .alert("Quitter la leçon ?", isPresented: $showQuitAlert) {
                Button("Continuer la leçon", role: .cancel) {}
                Button("Quitter", role: .destructive) { dismiss() }
            } message: {
                Text("Ta progression dans cette leçon sera perdue.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                showQuitAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quitter")
            LessonProgressBar(progress: progress)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if isChecked {
            FeedbackBar(question: question, isCorrect: isCorrect, praise: praise, onContinue: next)
                .transition(.move(edge: .bottom))
        } else {
            Button("Vérifier", action: check)
                .buttonStyle(ChunkyButtonStyle())
                .disabled(selectedIndex == nil)
                .padding()
        }
    }

    private var praise: String {
        let words = ["Bravo !", "Excellent !", "Parfait !", "Super !", "Génial !"]
        return words[currentIndex % words.count]
    }

    private func check() {
        guard selectedIndex != nil else { return }
        if isCorrect { correctCount += 1 }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isChecked = true
        }
    }

    private func next() {
        if currentIndex + 1 < unit.questions.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
                selectedIndex = nil
                isChecked = false
            }
        } else {
            withAnimation { isFinished = true }
        }
    }
}

private struct LessonProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.locked)
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: max(geo.size.width * progress, progress > 0 ? 18 : 0))
                    .overlay(alignment: .top) {
                        // Small shine on top of the bar.
                        Capsule()
                            .fill(.white.opacity(0.3))
                            .frame(height: 4)
                            .padding(.horizontal, 8)
                            .padding(.top, 3)
                    }
            }
        }
        .frame(height: 16)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
    }
}

/// The colored bar that slides up from the bottom after "Vérifier".
private struct FeedbackBar: View {
    let question: Question
    let isCorrect: Bool
    let praise: String
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                Text(isCorrect ? praise : "Pas tout à fait…")
                    .font(.title2.weight(.heavy))
            }
            .foregroundStyle(color)

            if !isCorrect {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bonne réponse :")
                        .font(.subheadline.weight(.bold))
                    Text(question.correctAnswer)
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(color)
            }

            if let explanation = question.explanation {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Continuer", action: onContinue)
                .buttonStyle(ChunkyButtonStyle(
                    face: color,
                    shadow: isCorrect ? Theme.correctShadow : Theme.wrongShadow
                ))
                .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (isCorrect ? Theme.correctBackground : Theme.wrongBackground)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var color: Color { isCorrect ? Theme.correct : Theme.wrong }
}

#Preview {
    LessonView(unit: SampleData.units[0]) {}
        .fontDesign(.rounded)
}
