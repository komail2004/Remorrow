import Foundation
import XCTest
@testable import Remorrow

private struct FailingEngine: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] {
        throw ExtractionEngineError.unavailable
    }
}

private struct EmptyEngine: ExtractionEngine {
    func extract(from input: ExtractionInput) async throws -> [ActionProposal] { [] }
}

final class ExtractionRouterTests: XCTestCase {
    func testFallsBackWhenPreferredFails() async throws {
        let router = ExtractionRouter(preferred: FailingEngine(), fallback: EmptyEngine())
        let items = try await router.extract(
            from: ExtractionInput(text: "Test", capturedAt: .now, localeIdentifier: "en_US", timeZoneIdentifier: "UTC")
        )
        XCTAssertTrue(items.isEmpty)
    }
}
