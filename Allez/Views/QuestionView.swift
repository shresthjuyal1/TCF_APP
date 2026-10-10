import SwiftUI

/// Shows one multiple-choice question: skill tag, optional passage, the question and the answer cards.
struct QuestionView: View {
    let question: Question
    @Binding var selectedIndex: Int?
    let isChecked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SkillTag(skill: question.skill, level: question.level)

            if let passage = question.passage {
                PassageCard(passage: passage, translation: question.passageTranslation)
            }

            questionText
                .font(.title3.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                ForEach(question.options.indices, id: \.self) { index in
                    Button {
                        selectedIndex = index
                    } label: {
                        OptionLabel(letter: letter(for: index), text: question.options[index], state: state(for: index))
                    }
                    .buttonStyle(OptionButtonStyle(state: state(for: index)))
                    .allowsHitTesting(!isChecked)
                }
            }
            .sensoryFeedback(.selection, trigger: selectedIndex)
        }
    }

    /// For fill-in-the-blank questions, puts the chosen answer into the "___" gap.
    private var questionText: Text {
        let parts = question.question.components(separatedBy: "___")
        guard parts.count == 2 else { return Text(question.question) }
        let fill = selectedIndex.map { question.options[$0] } ?? "_____"
        return Text(parts[0])
            + Text(fill).foregroundStyle(Theme.accent).underline()
            + Text(parts[1])
    }

    private func letter(for index: Int) -> String {
        String(UnicodeScalar(UInt8(65 + index)))
    }

    private func state(for index: Int) -> OptionState {
        if isChecked {
            if index == question.correctIndex { return .correct }
            if index == selectedIndex { return .wrong }
            return .faded
        }
        return index == selectedIndex ? .selected : .normal
    }
}

enum OptionState {
    case normal, selected, correct, wrong, faded
}

private struct SkillTag: View {
    let skill: Skill
    let level: Level

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: skill.icon)
            Text(skill.title)
            Text("·")
            Text(level.rawValue)
        }
        .font(.footnote.weight(.bold))
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.accentBackground))
    }
}

private struct PassageCard: View {
    let passage: String
    let translation: String?
    @State private var showTranslation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(passage)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if let translation {
                Button(showTranslation ? "Masquer la traduction" : "Voir la traduction") {
                    withAnimation { showTranslation.toggle() }
                }
                .font(.footnote.weight(.bold))

                if showTranslation {
                    Text(translation)
                        .font(.callout)
                        .italic()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))
    }
}

private struct OptionLabel: View {
    let letter: String
    let text: String
    let state: OptionState

    var body: some View {
        HStack(spacing: 12) {
            Text(letter)
                .font(.subheadline.weight(.heavy))
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(lineWidth: 2).opacity(0.4))
            Text(text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if state == .correct {
                Image(systemName: "checkmark.circle.fill")
            } else if state == .wrong {
                Image(systemName: "xmark.circle.fill")
            }
        }
    }
}

/// An answer card that sinks when pressed and changes color for selected / correct / wrong.
private struct OptionButtonStyle: ButtonStyle {
    let state: OptionState

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(border, lineWidth: 2))
            .background(RoundedRectangle(cornerRadius: 16).fill(border).offset(y: pressed ? 0 : 4))
            .offset(y: pressed ? 4 : 0)
            .opacity(state == .faded ? 0.5 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
            .animation(.easeOut(duration: 0.15), value: state)
    }

    private var fill: Color {
        switch state {
        case .normal, .faded: Theme.card
        case .selected: Theme.accentBackground
        case .correct: Theme.correctBackground
        case .wrong: Theme.wrongBackground
        }
    }

    private var border: Color {
        switch state {
        case .normal, .faded: Theme.cardBorder
        case .selected: Theme.accent
        case .correct: Theme.correct
        case .wrong: Theme.wrong
        }
    }

    private var textColor: Color {
        switch state {
        case .normal, .faded: .primary
        case .selected: Theme.accent
        case .correct: Theme.correct
        case .wrong: Theme.wrong
        }
    }
}
