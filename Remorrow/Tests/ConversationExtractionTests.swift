import XCTest
@testable import Remorrow

final class ConversationExtractionTests: XCTestCase {
    private let engine = LocalRulesEngine()
    private let reference = Date(timeIntervalSince1970: 1794096000)

    private func parse(_ text: String) async throws -> [ActionProposal] {
        try await engine.extract(from: ExtractionInput(
            text: text,
            capturedAt: reference,
            localeIdentifier: "en_US",
            timeZoneIdentifier: "America/New_York"
        ))
    }

    func testTwoDifferentDatedMessagesProduceTwoCandidates() async throws {
        let input = "Dinner with Alex Thursday at 7 PM\nSubmit biology homework Friday by 5 PM"
        let proposals = try await parse(input)
        XCTAssertEqual(proposals.count, 2)
        XCTAssertEqual(proposals[0].kind, .calendarEvent)
        XCTAssertEqual(proposals[1].kind, .reminder)
        XCTAssertNotEqual(proposals[0].title, proposals[1].title)
        XCTAssertTrue(proposals.allSatisfy { !$0.uncertaintyFlags.isEmpty })
    }

    func testSingleSentenceWithTwoIndependentDates() async throws {
        let proposals = try await parse("Dinner Thursday at 7 PM and submit the essay Friday by 5 PM")
        XCTAssertEqual(proposals.count, 2)
        XCTAssertTrue(proposals[0].title.localizedCaseInsensitiveContains("Dinner"))
        XCTAssertTrue(proposals[1].title.localizedCaseInsensitiveContains("essay"))
    }

    func testWrappedMessageAndDateLineBecomeOneCandidate() async throws {
        let proposals = try await parse("Dinner with Alex\nThursday at 7 PM")
        XCTAssertEqual(proposals.count, 1)
        XCTAssertTrue(proposals[0].title.localizedCaseInsensitiveContains("Dinner"))
    }

    func testOCRChromeAndChatTimestampAreNotTasks() async throws {
        let input = "9:41\nMessages\nToday\nAlex\nDinner Thursday at 7 PM\nDelivered"
        let proposals = try await parse(input)
        XCTAssertEqual(proposals.count, 1)
        XCTAssertTrue(proposals.first?.sourceEvidence.contains("Dinner") == true)
    }

    func testTentativeLanguageNeverBecomesConfirmed() async throws {
        let proposals = try await parse("Maybe dinner with Alex Friday at 7 PM")
        XCTAssertEqual(proposals.count, 1)
        XCTAssertTrue(proposals[0].uncertaintyFlags.contains("confirmCommitment"))
    }

    func testMissingTimeRequiresConfirmation() async throws {
        let proposals = try await parse("Submit the essay tomorrow")
        XCTAssertEqual(proposals.count, 1)
        XCTAssertTrue(proposals[0].uncertaintyFlags.contains("timeNotSpecified"))
    }

    func testNoTaskInDateHeaderProducesNothing() async throws {
        let results = try await parse("November 15, 2026\n9:41\nYesterday\nRead")
        XCTAssertTrue(results.isEmpty)
    }

    func testSeparateBubblesDoNotInventOneCombinedTask() async throws {
        let proposals = try await parse("Submit the assignment\n\nFriday at 5 PM")
        XCTAssertTrue(proposals.isEmpty)
    }

    func testNoPlanWithoutDateIsNotAutomaticallyInvented() async throws {
        let results = try await parse("Can you pick up the package sometime?")
        XCTAssertTrue(results.isEmpty)
    }
}
