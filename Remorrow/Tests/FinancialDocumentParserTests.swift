import XCTest
@testable import Remorrow

final class FinancialDocumentParserTests: XCTestCase {
    func testPurchaseDateDoesNotBecomeReturnDeadline() {
        let receipt = """
        Bluebird Store
        Wireless headphones
        Purchased: November 2, 2026
        Total $49.99
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertNil(proposal.date)
        XCTAssertNil(proposal.dateEvidence)
        XCTAssertEqual(proposal.amount, 49.99)
        XCTAssertEqual(proposal.merchant, "Bluebird Store")
    }

    func testExplicitReturnDeadlineMayBeSuggested() {
        let receipt = """
        Bluebird Store
        Wireless headphones
        TOTAL $49.99
        Return by December 31, 2026
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertNotNil(proposal.date)
        XCTAssertTrue(proposal.dateEvidence?.localizedCaseInsensitiveContains("return by") == true)
        XCTAssertEqual(proposal.amount, 49.99)
    }

    func testSubscriptionPurchaseDateAloneIsNotRenewal() {
        let document = """
        Stream Service
        Purchase: November 7, 2026
        Amount due $12.99
        """
        let proposal = FinancialDocumentParser.interpret(document, kind: .subscription)
        XCTAssertNil(proposal.date)
        XCTAssertEqual(proposal.amount, 12.99)
    }

    func testExplicitNextBillingDateIsRecognized() {
        let document = """
        Music Service
        Next billing: December 15, 2026
        Total: $9.99
        """
        let proposal = FinancialDocumentParser.interpret(document, kind: .subscription)
        XCTAssertNotNil(proposal.date)
        XCTAssertEqual(proposal.amount, 9.99)
        XCTAssertTrue(proposal.name.contains("subscription"))
    }

    func testEmptyInputDoesNotGuessDateOrAmount() {
        let result = FinancialDocumentParser.interpret("", kind: .receipt)
        XCTAssertNil(result.date)
        XCTAssertNil(result.amount)
    }
}
