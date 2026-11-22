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
        XCTAssertEqual(proposal.name, "Music Service")
    }

    func testEmptyInputDoesNotGuessDateOrAmount() {
        let result = FinancialDocumentParser.interpret("", kind: .receipt)
        XCTAssertNil(result.date)
        XCTAssertNil(result.amount)
    }

    func testReceiptHeaderIsNotTreatedAsProductName() {
        let receipt = """
        RECEIPT
        Bluebird Store
        Transaction 892100
        Wireless headphones 49.99
        Subtotal $49.99
        Tax $3.50
        Grand Total $53.49
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertEqual(proposal.merchant, "Bluebird Store")
        XCTAssertEqual(proposal.name, "Wireless headphones")
        XCTAssertEqual(proposal.amount, 53.49)
    }

    func testExplicitItemNameWinsOverGenericHeader() {
        let receipt = """
        Purchase confirmation
        Merchant: Example Electronics
        Product: Noise Cancelling Headphones
        Amount paid: $79.90
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertEqual(proposal.merchant, "Example Electronics")
        XCTAssertEqual(proposal.name, "Noise Cancelling Headphones")
        XCTAssertEqual(proposal.amount, 79.90)
    }

    func testSubscriptionPlanNameIsPreferredOverGenericMerchant() {
        let notice = """
        Merchant: Apple
        Plan: iCloud+ 200GB
        Next renewal: December 20, 2026
        Total paid: $2.99
        """
        let proposal = FinancialDocumentParser.interpret(notice, kind: .subscription)
        XCTAssertEqual(proposal.merchant, "Apple")
        XCTAssertEqual(proposal.name, "iCloud+ 200GB")
        XCTAssertEqual(proposal.amount, 2.99)
    }

    func testUnclearReceiptDoesNotInventProductName() {
        let receipt = """
        RECEIPT
        Bluebird Store
        Order number: A83728
        Grand Total: $14.99
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertEqual(proposal.name, "Purchase")
        XCTAssertEqual(proposal.amount, 14.99)
    }

    func testDetectedNameCandidatesCanBeSelectedByUser() {
        let receipt = """
        Bluebird Store
        USB-C Charger
        USB-C Cable
        Total $29.99
        """
        let proposal = FinancialDocumentParser.interpret(receipt, kind: .receipt)
        XCTAssertEqual(proposal.name, "USB-C Charger")
        XCTAssertTrue(proposal.nameCandidates.contains("USB-C Cable"))
    }
}
