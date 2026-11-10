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

    func testSevenPMWithoutDatePreservesClockTimeButNoInventedDay() async throws {
        let input = ExtractionInput(text: "Dinner with ruby at 7pm",
                                    capturedAt: .now,
                                    localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let result = try await LocalRulesEngine().extract(from: input)
        let suggestion = try XCTUnwrap(result.first)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(suggestion.kind, .calendarEvent)
        XCTAssertEqual(suggestion.suggestedHour, 19)
        XCTAssertEqual(suggestion.suggestedMinute, 0)
        XCTAssertNil(suggestion.proposedDate)
        XCTAssertTrue(suggestion.uncertaintyFlags.contains("missingDate"))
        XCTAssertFalse(suggestion.uncertaintyFlags.contains("timeNotSpecified"))
    }

    func testStandaloneTimeWithoutAt() async throws {
        let input = ExtractionInput(text: "Dinner with ruby 7 PM",
                                    capturedAt: .now,
                                    localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let result = try await LocalRulesEngine().extract(from: input)
        XCTAssertEqual(result.first?.suggestedHour, 19)
        XCTAssertNil(result.first?.proposedDate)
    }

    func testOCRLineWrappedTimeIsNotLost() async throws {
        let input = ExtractionInput(text: "Dinner with Ruby\nat 7 PM",
                                    capturedAt: .now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let result = try await LocalRulesEngine().extract(from: input)
        XCTAssertEqual(result.first?.suggestedHour, 19)
        XCTAssertNil(result.first?.proposedDate)
    }

    func testTomorrowSevenPMKeepsCorrectDayAndTime() async throws {
        let now = Date(timeIntervalSince1970: 1794200000)
        let input = ExtractionInput(text: "Dinner with Ruby tomorrow 7pm",
                                    capturedAt: now, localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let result = try await LocalRulesEngine().extract(from: input)
        let proposed = try XCTUnwrap(result.first?.proposedDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        XCTAssertEqual(calendar.component(.hour, from: proposed), 19)
        XCTAssertEqual(calendar.component(.minute, from: proposed), 0)
    }

    func testTimeOnlyTextDoesNotTreatBareHourAsVerified() async throws {
        let input = ExtractionInput(text: "Dinner with Ruby at 7",
                                    capturedAt: .now,
                                    localeIdentifier: "en_US",
                                    timeZoneIdentifier: "America/New_York")
        let result = try await LocalRulesEngine().extract(from: input)
        XCTAssertTrue(result.isEmpty)
    }
}
