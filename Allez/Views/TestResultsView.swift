import SwiftUI

/// Score, rough level estimate, results per level, and a review of every answer.
struct TestResultsView: View {
    let test: QuestionSet
    let answers: [Int?]
    let ranOutOfTime: Bool
    let onDone: () -> Void

    @State private var appeared = false

    private var questions: [Question] { test.questions }
    private var correctCount: Int {
        questions.indices.filter { answers[$0] == questions[$0].correctIndex }.count
    }
    private var fraction: Double {
        questions.isEmpty ? 0 : Double(correctCount) / Double(questions.count)
    }
    private var levelsInTest: [Level] {
        Level.allCases.filter { level in questions.contains { $0.level == level } }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    summary
                    levelBreakdown
                    review
                }
                .padding()
            }
            Button("Terminer", action: onDone)
                .buttonStyle(ChunkyButtonStyle())
                .padding()
        }
        .onAppear { appeared = true }
        .sensoryFeedback(.success, trigger: appeared)
    }

    private var summary: some View {
        VStack(spacing: 12) {
            Image(systemName: ranOutOfTime ? "timer" : "flag.checkered")
                .font(.system(size: 56))
                .foregroundStyle(Theme.gold)
            Text(ranOutOfTime ? "Temps écoulé !" : "Test terminé !")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(Theme.accent)
            Text("\(correctCount) / \(questions.count) bonnes réponses · \(Int((fraction * 100).rounded())) %")
                .font(.headline)

            VStack(spacing: 4) {
                Text("Niveau estimé")
                    .font(.caption.weight(.heavy))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                let level = ContentLibrary.estimatedLevel(forScore: fraction)
                Text(level.rawValue)
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(Theme.accent)
                Text(level.name)
                    .font(.subheadline.weight(.semibold))
                Text("Estimation approximative, pas un score officiel du TCF.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.accentBackground))
        }
        .padding(.top, 12)
    }

    private var levelBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Par niveau")
                .font(.title3.weight(.heavy))
            ForEach(levelsInTest) { level in
                let indices = questions.indices.filter { questions[$0].level == level }
                let correct = indices.filter { answers[$0] == questions[$0].correctIndex }.count
                HStack {
                    Text(level.rawValue)
                        .font(.headline)
                        .frame(width: 36, alignment: .leading)
                    ProgressView(value: Double(correct), total: Double(indices.count))
                        .tint(Theme.correct)
                    Text("\(correct)/\(indices.count)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Revoir les réponses")
                .font(.title3.weight(.heavy))
            ForEach(questions.indices, id: \.self) { index in
                AnswerReviewRow(number: index + 1, question: questions[index], answer: answers[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnswerReviewRow: View {
    let number: Int
    let question: Question
    let answer: Int?

    @State private var isExpanded = false

    private var isCorrect: Bool { answer == question.correctIndex }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? Theme.correct : Theme.wrong)
                    Text("Question \(number)")
                        .font(.headline)
                    Text(question.level.rawValue)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if let passage = question.passage {
                    Text(passage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Text(question.question)
                    .font(.subheadline.weight(.bold))
                if let answer {
                    Text("Ta réponse : \(question.options[answer])")
                        .foregroundStyle(isCorrect ? Theme.correct : Theme.wrong)
                } else {
                    Text("Pas de réponse")
                        .foregroundStyle(Theme.wrong)
                }
                if !isCorrect {
                    Text("Bonne réponse : \(question.correctAnswer)")
                        .foregroundStyle(Theme.correct)
                }
                if let explanation = question.explanation {
                    Text(explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let translation = question.passageTranslation {
                    Text(translation)
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
        }
        .font(.subheadline)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))
    }
}
