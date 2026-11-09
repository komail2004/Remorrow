import XCTest
@testable import Remorrow

final class WarrantyIntelligenceTests: XCTestCase {
    func testNoInferredWarrantyFromPurchaseDate() {
        let ocr = "Portland Electronics\nOrder # 45A77H\nPurchase date: November 9, 2026\n1 year limited warranty"
        let result = FinancialDocumentParser.interpret(ocr, kind: .receipt)
        XCTAssertNil(result.warrantyExpiry)
        XCTAssertEqual(result.receiptNumber, "45A77H")
        XCTAssertNotNil(result.purchaseDate)
    }

    func testExplicitWarrantyAndReturnDatesStaySeparate() {
        let ocr = "Gadget Shop\nReturn by: December 1, 2026\nWarranty expires: November 9, 2028\nTotal $65.99"
        let result = FinancialDocumentParser.interpret(ocr, kind: .receipt)
        XCTAssertNotNil(result.date)
        XCTAssertNotNil(result.warrantyExpiry)
        XCTAssertNotEqual(result.date, result.warrantyExpiry)
    }

    func testSubscriptionIsNeverAssignedReceiptWarranty() {
        let result = FinancialDocumentParser.interpret(
           "Video Stream\nNext billing: December 1, 2026\nWarranty expires: December 1, 2030",
           kind: .subscription
        )
        XCTAssertNil(result.warrantyExpiry)
    }
}
