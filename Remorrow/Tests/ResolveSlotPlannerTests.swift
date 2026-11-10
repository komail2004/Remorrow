import XCTest
@testable import Remorrow

final class ResolveSlotPlannerTests: XCTestCase {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private var proposed: Date {
        utc.date(from: DateComponents(year: 2026, month: 11, day: 20,
                                      hour: 18, minute: 0))!
    }
    func testBusyEventAndFifteenMinuteBufferAreExcluded() {
        let busy = [ResolveBusyInterval(start: proposed,
                                        end: proposed.addingTimeInterval(3600))]
        XCTAssertFalse(ResolveSlotPlanner.isFree(start: proposed, duration: 3600, busy: busy))
        XCTAssertFalse(ResolveSlotPlanner.isFree(start: proposed.addingTimeInterval(3600),
                                                  duration: 3600, busy: busy))
        XCTAssertTrue(ResolveSlotPlanner.isFree(start: proposed.addingTimeInterval(2*3600),
                                                 duration: 3600, busy: busy))
    }
    func testOnlyThreeRealNonOverlappingAlternatives() {
        let busy = [ResolveBusyInterval(start: proposed,
                                        end: proposed.addingTimeInterval(5400))]
        let slots = ResolveSlotPlanner.suggestions(around: proposed, duration: 3600,
                        busy: busy, now: proposed.addingTimeInterval(-3*86400),
                        calendar: utc)
        XCTAssertEqual(slots.count, 3)
        XCTAssertTrue(slots.allSatisfy {
            ResolveSlotPlanner.isFree(start: $0.start, duration: 3600, busy: busy)
        })
        for first in slots.indices {
            for second in slots.indices where second > first {
                XCTAssertGreaterThanOrEqual(
                    abs(slots[first].start.timeIntervalSince(slots[second].start)),
                    90 * 60
                )
            }
        }
    }
    func testTentativeNewPlanCanBlockExistingEventMove() {
        let tentative = [ResolveBusyInterval(start: proposed,
                                              end: proposed.addingTimeInterval(3600))]
        let slots = ResolveSlotPlanner.suggestions(around: proposed, duration: 5400,
                        busy: tentative, now: proposed.addingTimeInterval(-86400),
                        calendar: utc)
        XCTAssertFalse(slots.isEmpty)
        XCTAssertTrue(slots.allSatisfy {
            ResolveSlotPlanner.isFree(start: $0.start, duration: 5400,
                                      busy: tentative)
        })
    }
    func testNoAvailabilityDoesNotInventTimes() {
        let allDay = ResolveBusyInterval(start: proposed.addingTimeInterval(-5*86400),
                                          end: proposed.addingTimeInterval(15*86400))
        let slots = ResolveSlotPlanner.suggestions(around: proposed, duration: 3600,
                          busy: [allDay], now: proposed.addingTimeInterval(-86400),
                          calendar: utc)
        XCTAssertTrue(slots.isEmpty)
    }
    func testTooLongOrPastSlotsAreNotSuggested() {
        XCTAssertTrue(ResolveSlotPlanner.suggestions(
            around: proposed, duration: 24*3600, busy: [],
            now: proposed.addingTimeInterval(-86400), calendar: utc).isEmpty)
        let now = proposed.addingTimeInterval(30*86400)
        let slots = ResolveSlotPlanner.suggestions(
            around: proposed, duration: 3600, busy: [], now: now, calendar: utc)
        XCTAssertTrue(slots.allSatisfy { $0.start >= now.addingTimeInterval(30*60) })
    }
}
