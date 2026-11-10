import XCTest
@testable import Remorrow

final class ConversationIntelligenceTests: XCTestCase {
    private func parse(_ text: String) async throws -> [ActionProposal] {
        try await ConversationContextEngine().extract(from: ExtractionInput(
            text: text, capturedAt: Date(timeIntervalSince1970: 1794200000),
            localeIdentifier: "en_US", timeZoneIdentifier: "America/New_York"
        ))
    }
    func testUndatedFirstPersonTaskRequiresDate() async throws {
        let result = try await parse("I'll bring the HDMI adapter")
        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result[0].proposedDate)
        XCTAssertTrue(result[0].uncertaintyFlags.contains("missingDate"))
    }
    func testOtherPersonsCommitmentIsNotAssignedToUser() async throws {
        let result = try await parse("You will bring the HDMI adapter")
        XCTAssertTrue(result.isEmpty)
    }
    func testRescheduleUsesNewRelativeDateNotOldDate() async throws {
        let result = try await parse("The biology presentation moved from Friday to Monday at 10 AM")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result[0].sourceEvidence.contains("Monday"))
        // An ambiguous next weekday must remain subject to manual confirmation.
        XCTAssertTrue(result[0].uncertaintyFlags.contains("confirmRelativeDate"))
    }
    func testAQuestionDoesNotBecomeYourTask() async throws {
        let result = try await parse("I'll maybe bring the project tomorrow?")
        XCTAssertTrue(result.allSatisfy { $0.proposedDate != nil || $0.uncertaintyFlags.contains("missingDate") })
    }

    func testSevenPMSurvivesFallbackConversationPipeline() async throws {
        let results = try await parse("Dinner with Ruby at 7pm")
        XCTAssertEqual(results.first?.suggestedHour, 19)
        XCTAssertEqual(results.first?.suggestedMinute, 0)
        XCTAssertNil(results.first?.proposedDate)
        XCTAssertTrue(results.first?.uncertaintyFlags.contains("missingDate") == true)
    }
}
