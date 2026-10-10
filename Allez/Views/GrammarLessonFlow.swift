import SwiftUI

/// A grammar lesson: the rule card first, then the questions.
struct GrammarLessonFlow: View {
    let unit: LessonUnit
    let onComplete: () -> Void

    @State private var hasStarted = false

    var body: some View {
        if hasStarted {
            LessonView(questions: unit.questions.shuffled(), onComplete: onComplete)
        } else {
            RuleCardView(unit: unit) {
                withAnimation { hasStarted = true }
            }
        }
    }
}

/// Explains the grammar rule with examples. Shown before every lesson, so it can be reread anytime.
struct RuleCardView: View {
    let unit: LessonUnit
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close")
                Spacer()
            }
            .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: unit.icon)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level \(unit.level.rawValue) · Grammar")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Theme.accent)
                            Text(unit.title)
                                .font(.title2.weight(.heavy))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let guide = unit.guide {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("The rule", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(Theme.gold)
                            Text(guide.summary)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Examples")
                                .font(.headline)
                            ForEach(guide.examples, id: \.self) { example in
                                HStack(alignment: .top, spacing: 12) {
                                    SpeakButton(text: example.french)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(example.french)
                                            .font(.body.weight(.semibold))
                                        Text(example.english)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                    .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            Button("Start lesson", action: onStart)
                .buttonStyle(ChunkyButtonStyle())
                .padding()
        }
    }
}

#Preview {
    RuleCardView(unit: ContentLibrary.loadFromBundle().units[0]) {}
        .fontDesign(.rounded)
}
