import Foundation
import Observation

enum UnitStatus {
    case completed, available, locked
}

/// Holds the loaded content and everything personal: finished lessons, practice time,
/// test results and settings. All of it is saved on the phone.
@Observable
final class AppState {
    /// Practice needed in a day to keep the streak going.
    static let dailyGoalSeconds: TimeInterval = 10 * 60

    let library: ContentLibrary

    var completedUnitIDs: Set<String> {
        didSet { Self.save(completedUnitIDs, key: "completedUnitIDs") }
    }
    /// Seconds practised per day, keyed by "yyyy-MM-dd".
    var practiceSeconds: [String: TimeInterval] {
        didSet { Self.save(practiceSeconds, key: "practiceSeconds") }
    }
    var testResults: [TestResult] {
        didSet { Self.save(testResults, key: "testResults") }
    }
    var settings: UserSettings {
        didSet {
            Self.save(settings, key: "settings")
            Reminders.reschedule(for: self)
        }
    }
    /// Set when today's practice first reaches 10 minutes, to show the streak celebration.
    var showStreakCelebration = false

    init(library: ContentLibrary = .loadFromBundle()) {
        self.library = library
        // Earlier versions saved finished lessons as a plain list; keep reading that too.
        completedUnitIDs = Self.load(Set<String>.self, key: "completedUnitIDs")
            ?? Set(UserDefaults.standard.stringArray(forKey: "completedUnitIDs") ?? [])
        practiceSeconds = Self.load([String: TimeInterval].self, key: "practiceSeconds") ?? [:]
        testResults = Self.load([TestResult].self, key: "testResults") ?? []
        settings = Self.load(UserSettings.self, key: "settings") ?? UserSettings()
    }

    // MARK: Grammar path

    var units: [LessonUnit] { library.units }

    func units(in level: Level) -> [LessonUnit] {
        units.filter { $0.level == level }
    }

    func isCompleted(_ unit: LessonUnit) -> Bool {
        completedUnitIDs.contains(unit.id)
    }

    /// A lesson is open when it's finished, when the lesson before it is finished,
    /// or when it's the first lesson of its level (so you can jump ahead to any level).
    func status(of unit: LessonUnit) -> UnitStatus {
        if isCompleted(unit) { return .completed }
        guard let index = units.firstIndex(where: { $0.id == unit.id }) else { return .locked }
        if index == 0 || units[index - 1].level != unit.level || isCompleted(units[index - 1]) {
            return .available
        }
        return .locked
    }

    /// The lesson to suggest next: the first open lesson that isn't finished yet.
    var nextUnit: LessonUnit? {
        units.first { status(of: $0) == .available }
    }

    /// The lesson that has to be finished before this one opens.
    func previousUnit(of unit: LessonUnit) -> LessonUnit? {
        guard let index = units.firstIndex(where: { $0.id == unit.id }), index > 0 else { return nil }
        return units[index - 1]
    }

    func complete(_ unit: LessonUnit) {
        completedUnitIDs.insert(unit.id)
    }

    // MARK: Practice time & streak

    func addPractice(seconds: TimeInterval, on date: Date = .now) {
        guard seconds > 1 else { return }
        let key = Day.key(date)
        let before = practiceSeconds[key, default: 0]
        // Cap one stretch at 3 hours in case the app was left open on a lesson.
        practiceSeconds[key] = before + min(seconds, 3 * 3600)
        if before < Self.dailyGoalSeconds && practiceSeconds[key, default: 0] >= Self.dailyGoalSeconds {
            showStreakCelebration = true
        }
        Reminders.reschedule(for: self)
    }

    func secondsPracticed(on date: Date) -> TimeInterval {
        practiceSeconds[Day.key(date), default: 0]
    }

    func goalMet(on date: Date) -> Bool {
        secondsPracticed(on: date) >= Self.dailyGoalSeconds
    }

    var todaySeconds: TimeInterval { secondsPracticed(on: .now) }

    /// Counts the streak backwards from today. One missed day per week is covered by a streak freeze;
    /// two missed days in a row always end the streak. Today only counts once its 10 minutes are done.
    var streak: StreakSummary {
        let today = Day.calendar.startOfDay(for: .now)
        var count = goalMet(on: today) ? 1 : 0
        var frozen = Set<String>()
        var usedWeeks = Set<String>()
        var lastFrozen: String?
        let earliest = practiceSeconds.filter { $0.value >= Self.dailyGoalSeconds }.keys.min()
        var day = Day.adding(-1, to: today)
        while let earliest, Day.key(day) >= earliest {
            if goalMet(on: day) {
                count += 1
                lastFrozen = nil
            } else {
                let week = Day.weekKey(day)
                if lastFrozen != nil || usedWeeks.contains(week) {
                    if let lastFrozen { frozen.remove(lastFrozen) }
                    break
                }
                usedWeeks.insert(week)
                lastFrozen = Day.key(day)
                frozen.insert(Day.key(day))
            }
            day = Day.adding(-1, to: day)
        }
        let thisWeek = Set(Day.week(containing: today).map(Day.key))
        return StreakSummary(count: count, frozenDays: frozen, freezeUsedThisWeek: !frozen.isDisjoint(with: thisWeek))
    }

    func status(of date: Date, in summary: StreakSummary) -> DayStatus {
        let today = Day.calendar.startOfDay(for: .now)
        let day = Day.calendar.startOfDay(for: date)
        if day > today { return .future }
        if goalMet(on: day) { return .practiced }
        if summary.frozenDays.contains(Day.key(day)) { return .frozen }
        return day == today ? .pending : .missed
    }

    // MARK: Tests & goal

    func record(_ result: TestResult) {
        testResults.append(result)
    }

    /// The level from your most recent full test.
    var currentLevel: Level? { testResults.last?.level }

    func bestScore(for testID: String) -> TestResult? {
        testResults.filter { $0.testID == testID }.max { Double($0.correct) / Double($0.total) < Double($1.correct) / Double($1.total) }
    }

    /// Whole days until the exam, or nil when no date is set.
    var daysUntilExam: Int? {
        guard let exam = settings.examDate else { return nil }
        return Day.calendar.dateComponents([.day], from: Day.calendar.startOfDay(for: .now), to: Day.calendar.startOfDay(for: exam)).day
    }

    // MARK: Saving

    private static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
