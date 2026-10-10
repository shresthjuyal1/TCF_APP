import Foundation
import Observation

enum UnitStatus {
    case completed, available, locked
}

/// Holds the loaded content and which grammar lessons are finished. Finished lessons are
/// saved on the phone, so they stay gold after the app is closed.
@Observable
final class AppState {
    private static let completedKey = "completedUnitIDs"

    let library: ContentLibrary
    var completedUnitIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(completedUnitIDs), forKey: Self.completedKey) }
    }

    init(library: ContentLibrary = .loadFromBundle()) {
        self.library = library
        completedUnitIDs = Set(UserDefaults.standard.stringArray(forKey: Self.completedKey) ?? [])
    }

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
}
