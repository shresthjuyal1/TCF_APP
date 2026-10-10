import Foundation
import Observation

enum UnitStatus {
    case completed, current, locked
}

/// Holds the loaded content and which units are done. Completed units are forgotten when
/// the app closes; saving progress comes in build step 4.
@Observable
final class AppState {
    let library: ContentLibrary
    var completedUnitIDs: Set<String> = []

    init(library: ContentLibrary = .loadFromBundle()) {
        self.library = library
    }

    var units: [LessonUnit] { library.units }

    func status(of unit: LessonUnit) -> UnitStatus {
        if completedUnitIDs.contains(unit.id) { return .completed }
        let firstUnfinished = units.first { !completedUnitIDs.contains($0.id) }
        return firstUnfinished?.id == unit.id ? .current : .locked
    }

    func complete(_ unit: LessonUnit) {
        completedUnitIDs.insert(unit.id)
    }
}
