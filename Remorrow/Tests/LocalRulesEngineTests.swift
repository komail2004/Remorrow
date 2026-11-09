import XCTest
@testable import Remorrow

final class LocalRulesEngineTests: XCTestCase {
    func testEmptyInputHasNoProposals() async throws {
        let result = try await LocalRulesEngine().extract(
            from: ExtractionInput(text: "  ", capturedAt: .now, localeIdentifier: "en_US", timeZoneIdentifier: "America/New_York")
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testTextWithNoDateHasNoProposals() async throws {
        let result = try await LocalRulesEngine().extract(
            from: ExtractionInput(text: "Buy a notebook", capturedAt: .now, localeIdentifier: "en_US", timeZoneIdentifier: "America/New_York")
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testDateCandidateNeverWritesSystemActions() async throws {
        let result = try await LocalRulesEngine().extract(
            from: ExtractionInput(text: "Meeting on December 12, 2026 at 3 PM", capturedAt: .now, localeIdentifier: "en_US", timeZoneIdentifier: "America/New_York")
        )
        XCTAssertFalse(result.isEmpty)
        XCTAssertEqual(result.first?.origin, .localRules)
        XCTAssertTrue(result.allSatisfy { !$0.uncertaintyFlags.isEmpty })
    }

    func testMeetingSuggestsCalendarEventWithoutSaving() async throws {
        let input = ExtractionInput(text: "Dinner with Alex on December 12, 2026 at 7 PM",
                                    capturedAt: .now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let proposals = try await LocalRulesEngine().extract(from: input)
        XCTAssertEqual(proposals.first?.kind, .calendarEvent)
        XCTAssertTrue(proposals.allSatisfy { !$0.uncertaintyFlags.isEmpty })
    }

    func testAssignmentSuggestsReminder() async throws {
        let input = ExtractionInput(text: "Submit biology assignment on December 12, 2026",
                                    capturedAt: .now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let proposals = try await LocalRulesEngine().extract(from: input)
        XCTAssertEqual(proposals.first?.kind, .reminder)
    }

    func testExplicitEightPMWinsOverDefaultAbsoluteDateTime() async throws {
        let input = ExtractionInput(text: "Dinner with Rubi on November 20, 2026 at 8 PM",
                                    capturedAt: .now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let proposals = try await LocalRulesEngine().extract(from: input)
        let detected = try XCTUnwrap(proposals.first?.proposedDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        XCTAssertEqual(calendar.component(.hour, from: detected), 20)
        XCTAssertEqual(calendar.component(.day, from: detected), 20)
    }

    func testMissingTimeRemainsUncertain() async throws {
        let input = ExtractionInput(text: "Dinner with Rubi on November 20, 2026",
                                    capturedAt: .now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let proposals = try await LocalRulesEngine().extract(from: input)
        XCTAssertTrue(proposals.first?.uncertaintyFlags.contains("confirmTime") == true)
    }
}
