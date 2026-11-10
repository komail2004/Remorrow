import XCTest
@testable import Remorrow

final class SavedScheduleClashDetectorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1794400000)

    private func event(_ name: String, after minutes: Int,
                       kind: String = "calendarEvent") -> SavedPlanRecord {
        SavedPlanRecord(id: UUID(), title: name,
                        dueAt: now.addingTimeInterval(Double(minutes)*60),
                        kind: kind, externalID: "fixture")
    }
    func testSavedEventsAtSameTimeAreDetected() {
        let result = SavedScheduleClashDetector.find([
            event("Presentation", after: 60),
            event("Dinner", after: 60)
        ], now: now)
        XCTAssertEqual(result.count, 1)
    }
    func testTwoDifferentRemindersDoNotBecomeConflicts() {
        XCTAssertTrue(SavedScheduleClashDetector.find([
            event("Send slides", after: 60, kind: "reminder"),
            event("Bring adapter", after: 60, kind: "reminder")
        ], now: now).isEmpty)
    }
    func testNonoverlapAndOldDatesAreIgnored() {
        XCTAssertTrue(SavedScheduleClashDetector.find([
            event("Presentation", after: 60),
            event("Dinner", after: 120),
            event("Old meeting", after: -10*24*60)
        ], now: now).isEmpty)
    }
    func testPairIDIsStableIndependentOfOrder() {
        let first = event("Presentation", after: 60)
        let second = event("Dinner", after: 60)
        let a = SavedScheduleClash(first: first, second: second)
        let b = SavedScheduleClash(first: second, second: first)
        XCTAssertEqual(a.id, b.id)
    }
}
