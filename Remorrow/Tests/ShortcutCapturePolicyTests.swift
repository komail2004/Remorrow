import XCTest
@testable import Remorrow

final class ShortcutCapturePolicyTests: XCTestCase {
    func testEmptyTextIsRejected() {
        XCTAssertFalse(ShortcutCapturePolicy.isValid("  \n  "))
    }
    func testNormalTextIsAccepted() {
        XCTAssertTrue(ShortcutCapturePolicy.isValid("Dinner Friday at 7 PM"))
    }
    func testHugeTextIsRejected() {
        XCTAssertFalse(ShortcutCapturePolicy.isValid(String(repeating: "A", count: 20_001)))
    }
}
