import XCTest
@testable import Remorrow

final class SmartTitleGeneratorTests: XCTestCase {
    func testRemovesConversationAndDateEvidence() {
        XCTAssertEqual(
            SmartTitleGenerator.title(from: "Hey! Remind me to submit the biology assignment on December 12 at 5 PM",
                                      dateEvidence: "December 12 at 5 PM"),
            "Submit the biology assignment"
        )
    }

    func testShortSimpleTextIsReadable() {
        XCTAssertEqual(SmartTitleGenerator.title(from: "call the dentist tomorrow"),
                       "Call the dentist")
    }

    func testWhitespaceDoesNotProduceEmptyTitle() {
        XCTAssertEqual(SmartTitleGenerator.title(from: "  "), "Review this reminder")
    }

    func testThirdPersonDinnerIsAConciseEventTitle() {
        XCTAssertEqual(
            SmartTitleGenerator.title(from: "Rubi will have dinner with me"),
            "Dinner with Rubi"
        )
    }

    func testGreetingDoesNotBecomeActionTitle() {
        let result = SmartTitleGenerator.title(from:
            "Hi, how are you. Let's dine at 10am on Saturday")
        XCTAssertEqual(result, "Have dinner")
    }

    func testDifferentGuestRemainsDifferent() {
        XCTAssertEqual(SmartTitleGenerator.title(from: "Alex will have dinner with me"),
                       "Dinner with Alex")
    }
}
