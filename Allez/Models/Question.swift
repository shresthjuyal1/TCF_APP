import Foundation

/// The five TCF sections, plus vocabulary practice.
enum Skill: String, Codable, CaseIterable, Identifiable {
    case reading, listening, grammar, writing, speaking, vocabulary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "Reading"
        case .listening: "Listening"
        case .grammar: "Grammar"
        case .writing: "Writing"
        case .speaking: "Speaking"
        case .vocabulary: "Vocabulary"
        }
    }

    var icon: String {
        switch self {
        case .reading: "book.fill"
        case .listening: "headphones"
        case .grammar: "textformat.abc"
        case .writing: "pencil"
        case .speaking: "mic.fill"
        case .vocabulary: "character.book.closed.fill"
        }
    }
}

/// CEFR levels. The TCF tests every level from A1 to C2.
enum Level: String, Codable, CaseIterable, Identifiable, Comparable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"

    var id: String { rawValue }

    /// Common English names of the CEFR levels.
    var name: String {
        switch self {
        case .a1: "Beginner"
        case .a2: "Elementary"
        case .b1: "Intermediate"
        case .b2: "Upper intermediate"
        case .c1: "Advanced"
        case .c2: "Proficient"
        }
    }

    static func < (lhs: Level, rhs: Level) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

/// A word or phrase worth learning from a question.
struct VocabItem: Codable, Hashable {
    let french: String
    let english: String
}

/// One multiple-choice question. Fields marked optional (`?`) can be left out of the JSON.
/// In a fill-in-the-blank question, write `___` where the answer goes.
struct Question: Identifiable, Codable, Hashable {
    let id: String
    let skill: Skill
    let level: Level
    var passage: String?
    var passageTranslation: String?
    var audioFile: String?
    let question: String
    var questionTranslation: String?
    let options: [String]
    /// English for each option, in the same order as `options`.
    var optionTranslations: [String]?
    let correctIndex: Int
    var explanation: String?
    var vocabulary: [VocabItem]?
    /// True when the source marked the official answer as disputed by other learners.
    var answerDisputed: Bool?

    var correctAnswer: String { options[correctIndex] }

    var correctAnswerTranslation: String? { translation(ofOption: correctIndex) }

    func translation(ofOption index: Int) -> String? {
        guard let optionTranslations, optionTranslations.indices.contains(index) else { return nil }
        return optionTranslations[index]
    }

    var hasTranslation: Bool {
        passageTranslation != nil || questionTranslation != nil || optionTranslations != nil
    }

    /// Identifies the same question appearing in several tests, ignoring spacing and punctuation.
    var contentKey: String {
        ((passage ?? "") + question).lowercased().filter { $0.isLetter || $0.isNumber }
    }
}

/// The rule card shown before a grammar lesson.
struct Guide: Codable, Hashable {
    struct Example: Codable, Hashable {
        let french: String
        let english: String
    }

    let summary: String
    let examples: [Example]
}

/// One circle on the grammar path.
struct LessonUnit: Identifiable, Hashable {
    let id: String
    let title: String
    let level: Level
    let icon: String
    var guide: Guide?
    let questions: [Question]
}

/// A word in the Vocab tab. `french` includes the article (and gender for l'), e.g. "l'emploi (m.)".
struct VocabWord: Codable, Identifiable, Hashable {
    let french: String
    let english: String
    let level: Level
    var example: String?
    var exampleTranslation: String?

    var id: String { french }

    /// The separate English meanings, e.g. "yet, however" → ["yet", "however"].
    var meanings: Set<String> {
        Set(english.lowercased().split(whereSeparator: { ",;".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) })
    }

    /// What the French voice should read: no "(m.)" notes, and "le/la collègue" becomes "collègue".
    var spokenText: String {
        french
            .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "le/la ", with: "")
    }
}

/// A group of words on one topic, e.g. Work & careers.
struct VocabTheme: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let words: [VocabWord]
}
