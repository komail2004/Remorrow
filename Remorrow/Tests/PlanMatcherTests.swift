import XCTest
@testable import Remorrow

final class PlanMatcherTests: XCTestCase {
    func testRescheduleCanSuggestUpdate() {
        XCTAssertTrue(PlanMatcher.looksLikeChange("The biology presentation moved to Monday"))
        XCTAssertTrue(PlanMatcher.similar("Biology presentation moved to Monday", "Biology presentation"))
    }
    func testGenericWordsDoNotMergeUnrelatedAppointments() {
        XCTAssertFalse(PlanMatcher.similar("Doctor appointment", "Dentist appointment"))
    }
    func testNoAutomaticUpdateOnOrdinaryMessage() {
        XCTAssertFalse(PlanMatcher.looksLikeChange("Meeting Friday at 7 PM"))
    }
    func testNegatedChangeWordsNotAcceptedAsSameSubject() {
        XCTAssertFalse(PlanMatcher.similar("Physics exam", "Biology exam"))
    }
}
