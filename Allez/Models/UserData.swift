import Foundation

/// Personal settings, changed from the Settings screen.
struct UserSettings: Codable, Equatable {
    var name = "Shresth"
    var examDate: Date?
    var goalLevel: Level = .b2
    var remindersOn = true
    var reminderHour = 19
    var reminderMinute = 0
    var soundsOn = true

    init() {}

    /// Reads saved settings, using the default for anything added in a newer version of the app.
    init(from decoder: Decoder) throws {
        let saved = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = UserSettings()
        name = try saved.decodeIfPresent(String.self, forKey: .name) ?? defaults.name
        examDate = try saved.decodeIfPresent(Date.self, forKey: .examDate)
        goalLevel = try saved.decodeIfPresent(Level.self, forKey: .goalLevel) ?? defaults.goalLevel
        remindersOn = try saved.decodeIfPresent(Bool.self, forKey: .remindersOn) ?? defaults.remindersOn
        reminderHour = try saved.decodeIfPresent(Int.self, forKey: .reminderHour) ?? defaults.reminderHour
        reminderMinute = try saved.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? defaults.reminderMinute
        soundsOn = try saved.decodeIfPresent(Bool.self, forKey: .soundsOn) ?? defaults.soundsOn
    }
}

/// The result of one full timed test, used to show your current estimated level.
struct TestResult: Codable, Hashable {
    let testID: String
    let date: Date
    let correct: Int
    let total: Int
    let level: Level
}

/// How a day looks on the streak calendar.
enum DayStatus {
    case practiced, frozen, missed, pending, future
}

struct StreakSummary {
    /// Days in a row with 10+ minutes of practice. Frozen days keep the streak alive but don't add to it.
    let count: Int
    let frozenDays: Set<String>
    let freezeUsedThisWeek: Bool
}

/// Helpers for turning dates into the "2026-10-10" keys used to store practice time.
enum Day {
    static let calendar = Calendar(identifier: .iso8601)

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func key(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func weekKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(parts.yearForWeekOfYear ?? 0)-\(parts.weekOfYear ?? 0)"
    }

    static func adding(_ days: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    /// Monday to Sunday of the week containing `date`.
    static func week(containing date: Date) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        return (0..<7).map { adding($0, to: start) }
    }
}
