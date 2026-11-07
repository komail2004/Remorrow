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
}
