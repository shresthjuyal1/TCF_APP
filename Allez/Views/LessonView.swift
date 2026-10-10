import SwiftUI

/// Runs one lesson: shows each question, checks the answer, and shows feedback.
struct LessonView: View {
    let questions: [Question]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var selectedIndex: Int?
    @State private var isChecked = false
    @State private var correctCount = 0
    @State private var isFinished = false
    @State private var showQuitAlert = false

    private var question: Question { questions[currentIndex] }
    private var isCorrect: Bool { selectedIndex == question.correctIndex }
    private var progress: Double {
        Double(currentIndex + (isChecked ? 1 : 0)) / Double(questions.count)
    }

    var body: some View {
        Group {
            if isFinished {
                LessonCompleteView(correct: correctCount, total: questions.count) {
                    onComplete()
                    dismiss()
                }
            } else {
                lesson
            }
        }
        .background(Theme.background)
        .tracksPracticeTime()
    }

    private var lesson: some View {
        Group {
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
            .alert("Quit the lesson?", isPresented: $showQuitAlert) {
                Button("Keep going", role: .cancel) {}
                Button("Quit", role: .destructive) { dismiss() }
            } message: {
                Text("Your progress in this lesson will be lost.")
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
            .accessibilityLabel("Quit")
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
            Button("Check", action: check)
                .buttonStyle(ChunkyButtonStyle())
                .disabled(selectedIndex == nil)
                .padding()
        }
    }

    private var praise: String {
        let words = ["Nice!", "Excellent!", "Perfect!", "Great job!", "Awesome!"]
        return words[currentIndex % words.count]
    }

    private func check() {
        guard selectedIndex != nil else { return }
        if isCorrect { correctCount += 1 }
        SoundFX.shared.play(isCorrect ? .correct : .wrong)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isChecked = true
        }
    }

    private func next() {
        if currentIndex + 1 < questions.count {
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

struct LessonProgressBar: View {
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

/// The colored bar that slides up from the bottom after "Check".
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
                Text(isCorrect ? praise : "Not quite…")
                    .font(.title2.weight(.heavy))
            }
            .foregroundStyle(color)

            if !isCorrect {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Correct answer:")
                        .font(.subheadline.weight(.bold))
                    Text(question.correctAnswer)
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(color)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let explanation = question.explanation {
                        Text(explanation)
                    } else if let questionTranslation = question.questionTranslation {
                        // No explanation yet: show the question and answer in English instead.
                        Text(questionTranslation).bold()
                            + Text(question.correctAnswerTranslation.map { " → " + $0 } ?? "")
                    } else if let answer = question.correctAnswerTranslation {
                        Text(answer)
                    }
                    if question.answerDisputed == true {
                        Label("Other test-takers dispute this answer.", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 160)

            Button("Continue", action: onContinue)
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
    LessonView(questions: ContentLibrary.loadFromBundle().units[0].questions) {}
        .fontDesign(.rounded)
}
