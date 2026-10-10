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

/// CEFR levels covered by the app.
enum Level: String, Codable, CaseIterable, Identifiable, Comparable {
    case a2 = "A2", b1 = "B1", b2 = "B2"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .a2: "Élémentaire"
        case .b1: "Intermédiaire"
        case .b2: "Avancé"
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
    let options: [String]
    let correctIndex: Int
    var explanation: String?
    var vocabulary: [VocabItem]?

    var correctAnswer: String { options[correctIndex] }
}

/// One circle on the home path.
struct LessonUnit: Identifiable, Hashable {
    let id: String
    let title: String
    let level: Level
    let icon: String
    let questions: [Question]
}
