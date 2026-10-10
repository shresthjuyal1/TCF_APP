import Foundation

/// One content file: a group of questions, either for practice or as a full timed test.
struct QuestionSet: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case practice, test
    }

    let id: String
    let title: String
    var description: String?
    let kind: Kind
    var timeLimitMinutes: Int?
    var questions: [Question]

    /// The skill most questions in this set belong to.
    var mainSkill: Skill? {
        let counts = Dictionary(grouping: questions, by: \.skill).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }
}

/// The layout of the home path, read from `parcours.json`.
private struct PathFile: Codable {
    struct Unit: Codable {
        let id: String
        let title: String
        let level: Level
        let icon: String
        let questionIds: [String]
    }

    let units: [Unit]
}

/// Everything the app can teach, loaded from the JSON files bundled in the app.
struct ContentLibrary {
    var sets: [QuestionSet] = []
    var units: [LessonUnit] = []
    /// Plain-English descriptions of files that couldn't be read, shown in the app so mistakes are easy to spot.
    var problems: [String] = []

    var allQuestions: [Question] { sets.flatMap(\.questions) }

    func questions(for skill: Skill, level: Level? = nil) -> [Question] {
        allQuestions.filter { $0.skill == skill && (level == nil || $0.level == level) }
    }

    func tests(for skill: Skill) -> [QuestionSet] {
        sets.filter { $0.kind == .test && $0.mainSkill == skill }
    }

    static func loadFromBundle(_ bundle: Bundle = .main) -> ContentLibrary {
        var library = ContentLibrary()
        var pathFile: PathFile?
        let decoder = JSONDecoder()
        let urls = (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for url in urls {
            let fileName = url.lastPathComponent
            do {
                let data = try Data(contentsOf: url)
                if fileName == "parcours.json" {
                    pathFile = try decoder.decode(PathFile.self, from: data)
                    continue
                }
                var set = try decoder.decode(QuestionSet.self, from: data)
                set.questions = set.questions.filter { question in
                    guard question.options.indices.contains(question.correctIndex) else {
                        library.problems.append("\(fileName): question \"\(question.id)\" has a correctIndex that doesn't match any option (remember the first option is 0). It was skipped.")
                        return false
                    }
                    return true
                }
                library.sets.append(set)
            } catch {
                library.problems.append("\(fileName): \(describe(error))")
            }
        }

        var questionsByID: [String: Question] = [:]
        for question in library.allQuestions {
            if questionsByID[question.id] != nil {
                library.problems.append("Two questions share the id \"\(question.id)\". Every id must be unique.")
            } else {
                questionsByID[question.id] = question
            }
        }

        guard let pathFile else {
            library.problems.append("parcours.json is missing or unreadable, so the path is empty.")
            return library
        }
        library.units = pathFile.units.map { unit in
            let questions = unit.questionIds.compactMap { id in
                if let question = questionsByID[id] { return question }
                library.problems.append("parcours.json: unit \"\(unit.title)\" uses question \"\(id)\", which doesn't exist.")
                return nil
            }
            return LessonUnit(id: unit.id, title: unit.title, level: unit.level, icon: unit.icon, questions: questions)
        }
        return library
    }

    /// Turns Swift's JSON errors into something readable.
    private static func describe(_ error: Error) -> String {
        guard let error = error as? DecodingError else { return error.localizedDescription }
        func location(_ context: DecodingError.Context) -> String {
            let path = context.codingPath
                .map { $0.intValue.map { "item \($0 + 1)" } ?? $0.stringValue }
                .joined(separator: " → ")
            return path.isEmpty ? "" : " (at \(path))"
        }
        switch error {
        case .keyNotFound(let key, let context):
            return "missing field \"\(key.stringValue)\"\(location(context))"
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            return "\(context.debugDescription)\(location(context))"
        @unknown default:
            return error.localizedDescription
        }
    }
}

extension ContentLibrary {
    /// A rough CEFR estimate from a percentage of correct answers. Not an official TCF score.
    static func estimatedLevel(forScore fraction: Double) -> Level {
        switch fraction {
        case ..<0.2: .a1
        case ..<0.4: .a2
        case ..<0.6: .b1
        case ..<0.75: .b2
        case ..<0.9: .c1
        default: .c2
        }
    }
}
