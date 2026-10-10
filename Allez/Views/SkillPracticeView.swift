import SwiftUI

/// A practice session started from a skill tab: a random handful of questions.
private struct PracticeSession: Identifiable {
    let id = UUID()
    let questions: [Question]
}

/// The Lecture and Grammaire tabs: quick practice sets plus full timed tests.
struct SkillPracticeView: View {
    let skill: Skill
    static let questionsPerPractice = 10

    @Environment(AppState.self) private var appState
    @State private var levelFilter: Level?
    @State private var practice: PracticeSession?
    @State private var activeTest: QuestionSet?

    private var pool: [Question] { appState.library.questions(for: skill, level: levelFilter) }
    private var availableLevels: [Level] {
        let levels = Set(appState.library.questions(for: skill).map(\.level))
        return Level.allCases.filter(levels.contains)
    }
    private var tests: [QuestionSet] { appState.library.tests(for: skill) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    practiceSection
                    testsSection
                }
                .padding()
            }
            .navigationTitle(skill.title)
            .fullScreenCover(item: $activeTest) { test in
                TestView(test: test)
            }
        }
        .fullScreenCover(item: $practice) { session in
            LessonView(questions: session.questions) {}
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Practice", subtitle: "\(Self.questionsPerPractice) random questions with instant feedback.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    LevelChip(label: "All", isSelected: levelFilter == nil) { levelFilter = nil }
                    ForEach(availableLevels) { level in
                        LevelChip(label: level.rawValue, isSelected: levelFilter == level) { levelFilter = level }
                    }
                }
                .padding(.vertical, 4)
            }

            Button("Start") {
                practice = PracticeSession(questions: Array(pool.shuffled().prefix(Self.questionsPerPractice)))
            }
            .buttonStyle(ChunkyButtonStyle())
            .disabled(pool.isEmpty)

            Text(pool.count == 1 ? "1 question available" : "\(pool.count) questions available")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Full tests", subtitle: "Like exam day: timed, results at the end.")

            if tests.isEmpty {
                Text("No tests yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(tests) { test in
                Button {
                    activeTest = test
                } label: {
                    TestRow(test: test)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.heavy))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LevelChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(Capsule().fill(isSelected ? Theme.accent : Theme.locked))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

private struct TestRow: View {
    let test: QuestionSet

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))

            VStack(alignment: .leading, spacing: 4) {
                Text(test.title)
                    .font(.headline)
                if let description = test.description {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 12) {
                    Label("\(test.questions.count) questions", systemImage: "list.number")
                    if let minutes = test.timeLimitMinutes {
                        Label("\(minutes) min", systemImage: "timer")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.cardBorder, lineWidth: 2))
        .contentShape(Rectangle())
    }
}

#Preview {
    SkillPracticeView(skill: .reading)
        .environment(AppState())
        .fontDesign(.rounded)
}
