import XCTest
@testable import Remorrow

final class SmartNotificationTimingTests: XCTestCase {
    func testPresentationGetsMorePreparationTime() {
        XCTAssertEqual(SmartNotificationTiming.leadSeconds(title: "Prepare the presentation",
                          kind: "reminder"), 86400)
        XCTAssertEqual(SmartNotificationTiming.leadSeconds(title: "Dinner with Alex",
                          kind: "calendarEvent"), 1800)
    }
    func testAnnualRenewalGetsLongerNotice() {
        XCTAssertEqual(SmartNotificationTiming.leadSeconds(
            title: "Subscription", kind: "subscription", frequency: "Yearly"), 7*86400)
    }
    func testPastDateNeverSchedulesAnything() {
        XCTAssertNil(SmartNotificationTiming.warningDate(dueAt: .distantPast,
                        title: "Expired", kind: "return", now: .now))
    }
}
