import XCTest
@testable import RoutineTracker

final class RoutineTrackerTests: XCTestCase {
    func testTotalTargetTimeSumsTaskDurations() {
        let routine = Routine(
            name: "Morning",
            tasks: [
                TaskItem(name: "Stretch", targetTime: 120),
                TaskItem(name: "Read", targetTime: 300)
            ]
        )

        XCTAssertEqual(routine.totalTargetTime, 420)
    }

    func testTargetSummaryUsesClockFormatForNonScheduledRoutine() {
        let routine = Routine(
            name: "Focus",
            tasks: [
                TaskItem(name: "Plan", targetTime: 90),
                TaskItem(name: "Execute", targetTime: 150)
            ]
        )

        XCTAssertEqual(routine.targetSummary, "04:00")
    }

    func testTargetSummaryForScheduledRoutineWithoutTime() {
        let routine = Routine(
            name: "Evening",
            tasks: [TaskItem(name: "Walk", targetTime: 600)],
            isScheduled: true,
            scheduledTime: nil
        )

        XCTAssertEqual(routine.targetSummary, "Scheduled")
    }

    func testTargetSummaryForScheduledRoutineIncludesFormattedTime() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 25
        components.hour = 9
        components.minute = 5
        let date = Calendar(identifier: .gregorian).date(from: components)!

        let routine = Routine(
            name: "Workout",
            tasks: [TaskItem(name: "Warmup", targetTime: 300)],
            isScheduled: true,
            scheduledTime: date
        )

        XCTAssertEqual(routine.targetSummary, "Scheduled 09:05")
    }

    func testLegacyTealThemeResolvesToSpaceGrey() {
        let palette = ThemeColors.palette(for: "teal")
        XCTAssertEqual(palette.id, "spaceGrey")
    }
}
