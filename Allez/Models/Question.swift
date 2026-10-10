import Foundation

/// The five TCF sections.
enum Skill: String, Codable, CaseIterable, Identifiable {
    case reading, listening, grammar, writing, speaking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reading: "Compréhension écrite"
        case .listening: "Compréhension orale"
        case .grammar: "Structures de la langue"
        case .writing: "Expression écrite"
        case .speaking: "Expression orale"
        }
    }

    var icon: String {
        switch self {
        case .reading: "book.fill"
        case .listening: "headphones"
        case .grammar: "textformat.abc"
        case .writing: "pencil"
        case .speaking: "mic.fill"
        }
    }
}

/// CEFR levels. The TCF tests every level from A1 to C2.
enum Level: String, Codable, CaseIterable, Identifiable, Comparable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"

    var id: String { rawValue }

    /// Official French names of the CEFR levels.
    var name: String {
        switch self {
        case .a1: "Découverte"
        case .a2: "Survie"
        case .b1: "Seuil"
        case .b2: "Avancé"
        case .c1: "Autonome"
        case .c2: "Maîtrise"
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

/// One circle on the home path.
struct LessonUnit: Identifiable, Hashable {
    let id: String
    let title: String
    let level: Level
    let icon: String
    let questions: [Question]
}
