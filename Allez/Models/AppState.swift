import Foundation
import Observation

enum UnitStatus {
    case completed, current, locked
}

/// Keeps track of which units are done. For now this is forgotten when the app closes;
/// saving progress comes in build step 4.
@Observable
final class AppState {
    let units: [LessonUnit] = SampleData.units
    var completedUnitIDs: Set<String> = []

    func status(of unit: LessonUnit) -> UnitStatus {
        if completedUnitIDs.contains(unit.id) { return .completed }
        let firstUnfinished = units.first { !completedUnitIDs.contains($0.id) }
        return firstUnfinished?.id == unit.id ? .current : .locked
    }

    func complete(_ unit: LessonUnit) {
        completedUnitIDs.insert(unit.id)
    }
}
