import SwiftUI

/// A practice session started from a skill tab: a random handful of questions.
private struct PracticeSession: Identifiable {
    let id = UUID()
    let questions: [Question]
}

/// The Reading tab: quick practice sets plus full timed tests.
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
            .background(Theme.background)
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
            SectionTitle(title: "Practice", subtitle: "\(Self.questionsPerPractice) random questions with instant feedback.",
                         icon: "bolt.fill", color: Theme.pink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    LevelChip(label: "All", color: Theme.accent, isSelected: levelFilter == nil) { levelFilter = nil }
                    ForEach(availableLevels) { level in
                        LevelChip(label: level.rawValue, color: Theme.levelColor(level).face, isSelected: levelFilter == level) { levelFilter = level }
                    }
                }
                .padding(.vertical, 4)
            }

            Button {
                practice = PracticeSession(questions: Array(pool.shuffled().prefix(Self.questionsPerPractice)))
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(ChunkyButtonStyle(face: Theme.pink, shadow: Theme.pinkShadow))
            .disabled(pool.isEmpty)

            Text(pool.count == 1 ? "1 question available" : "\(pool.count) questions available")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .card()
    }

    private var testsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Full tests", subtitle: "Like exam day: timed, results at the end.",
                         icon: "stopwatch.fill", color: Theme.purple)

            if tests.isEmpty {
                Text("No tests yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(tests.enumerated()), id: \.element.id) { index, test in
                Button {
                    activeTest = test
                } label: {
                    TestRow(test: test, color: Theme.paletteColor(index).face, best: appState.bestScore(for: test.id))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SectionTitle: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, color: color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title2.weight(.heavy))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct LevelChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : color)
                .background(Capsule().fill(isSelected ? color : color.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

private struct TestRow: View {
    let test: QuestionSet
    let color: Color
    let best: TestResult?

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemName: best == nil ? "doc.text.fill" : "checkmark.seal.fill", color: best == nil ? color : Theme.gold, size: 52)

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
                .foregroundStyle(color)
            }
            Spacer(minLength: 0)
            if let best {
                VStack(spacing: 2) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(Theme.gold)
                    Text("\(Int((Double(best.correct) / Double(best.total) * 100).rounded()))%")
                        .font(.caption.weight(.heavy))
                    Text(best.level.rawValue)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Theme.levelColor(best.level).face)
                }
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .card()
        .contentShape(Rectangle())
    }
}

#Preview {
    SkillPracticeView(skill: .reading)
        .environment(AppState())
        .fontDesign(.rounded)
}
