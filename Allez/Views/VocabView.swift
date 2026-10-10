import SwiftUI

/// A vocabulary quiz started from the Vocab tab.
private struct VocabSession: Identifiable {
    let id = UUID()
    let questions: [Question]
}

/// The Vocab tab: a quiz with a French ↔ English switch, plus every word grouped by theme.
struct VocabView: View {
    static let questionsPerQuiz = 10

    @Environment(AppState.self) private var appState
    @AppStorage("vocabDirection") private var direction = VocabDirection.frenchToEnglish
    @State private var quizThemeID: String?
    @State private var session: VocabSession?
    @State private var searchText = ""

    private var themes: [VocabTheme] { appState.library.vocabThemes }

    private var searchResults: [VocabWord] {
        appState.library.allVocab.filter {
            $0.french.localizedStandardContains(searchText) || $0.english.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    Section {
                        practiceCard
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    Section("Themes") {
                        ForEach(themes) { theme in
                            NavigationLink(value: theme) {
                                ThemeRow(theme: theme)
                            }
                        }
                    }
                } else {
                    Section("\(searchResults.count) words") {
                        ForEach(searchResults) { word in
                            NavigationLink(value: word) {
                                WordRow(word: word)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vocabulary")
            .searchable(text: $searchText, prompt: "Search in French or English")
            .navigationDestination(for: VocabTheme.self) { theme in
                ThemeDetailView(theme: theme)
            }
            .navigationDestination(for: VocabWord.self) { word in
                WordDetailView(word: word)
            }
        }
        .fullScreenCover(item: $session) { session in
            LessonView(questions: session.questions) {}
        }
    }

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Practice")
                .font(.title2.weight(.heavy))
            Text("\(Self.questionsPerQuiz) words, pick the right meaning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Direction", selection: $direction) {
                ForEach(VocabDirection.allCases) { direction in
                    Text(direction.label).tag(direction)
                }
            }
            .pickerStyle(.segmented)

            Picker("Theme", selection: $quizThemeID) {
                Text("All themes").tag(String?.none)
                ForEach(themes) { theme in
                    Label(theme.title, systemImage: theme.icon).tag(Optional(theme.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)

            Button("Start") {
                session = VocabSession(questions: appState.library.vocabQuestions(
                    themeID: quizThemeID, direction: direction, count: Self.questionsPerQuiz
                ))
            }
            .buttonStyle(ChunkyButtonStyle())
            .disabled(themes.isEmpty)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Theme.cardBorder, lineWidth: 2))
        .padding(.vertical, 4)
    }
}

private struct ThemeRow: View {
    let theme: VocabTheme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: theme.icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accent))
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.title)
                    .font(.headline)
                Text("\(theme.words.count) words")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// All the words in one theme, easiest levels first.
private struct ThemeDetailView: View {
    let theme: VocabTheme

    var body: some View {
        List {
            ForEach(Level.allCases) { level in
                let words = theme.words.filter { $0.level == level }
                if !words.isEmpty {
                    Section("\(level.rawValue) · \(level.name)") {
                        ForEach(words) { word in
                            NavigationLink(value: word) {
                                WordRow(word: word)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(theme.title)
    }
}

private struct WordRow: View {
    let word: VocabWord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.french)
                    .font(.body.weight(.semibold))
                Text(word.english)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            LevelBadge(level: word.level)
        }
    }
}

private struct LevelBadge: View {
    let level: Level

    var body: some View {
        Text(level.rawValue)
            .font(.caption.weight(.heavy))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Theme.accentBackground))
    }
}

/// One word: pronunciation, meaning, and a real example from the reading tests.
private struct WordDetailView: View {
    let word: VocabWord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.french)
                            .font(.largeTitle.weight(.heavy))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(word.english)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    SpeakButton(text: word.spokenText)
                        .scaleEffect(1.3)
                }

                LevelBadge(level: word.level)

                if let example = word.example {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Example from your reading tests")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            SpeakButton(text: example)
                        }
                        Text(example)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        if let translation = word.exampleTranslation {
                            TranslationText(text: translation)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemBackground)))
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Speaker.shared.speak(word.spokenText) }
    }
}

#Preview {
    VocabView()
        .environment(AppState())
        .fontDesign(.rounded)
}
