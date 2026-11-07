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
}
