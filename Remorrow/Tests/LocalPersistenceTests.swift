import XCTest
import SwiftData
@testable import Remorrow

@MainActor
final class LocalPersistenceTests: XCTestCase {
    func testReceiptsAndWarrantiesPersistLocally() throws {
        let schema = Schema([SavedAction.self, ReturnItem.self, SubscriptionItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let item = ReturnItem(itemName: "Headphones", merchant: "Audio Store",
                              deadline: Date().addingTimeInterval(10 * 86400))
        item.hasConfirmedReturnDeadline = false
        item.receiptNumber = "ORD-2026-02"
        item.purchaseAmount = 59.99
        item.purchaseDate = Date().addingTimeInterval(-3 * 86400)
        item.warrantyExpiresAt = Date().addingTimeInterval(365 * 86400)
        context.insert(item)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<ReturnItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.receiptNumber, "ORD-2026-02")
        XCTAssertEqual(fetched.first?.purchaseAmount, 59.99)
        XCTAssertFalse(fetched.first?.hasConfirmedReturnDeadline ?? true)
        XCTAssertNotNil(fetched.first?.warrantyExpiresAt)
    }

    func testSavedPlanAndRenewalCanCoexistInOneContainer() throws {
        let schema = Schema([SavedAction.self, ReturnItem.self, SubscriptionItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let plan = SavedAction(title: "Prepare slides", dueAt: .now,
                               kind: "reminder", externalID: "testing-only")
        plan.sourceText = "Prepare slides before Friday."
        context.insert(plan)
        context.insert(SubscriptionItem(name: "Music", merchant: "Music service",
                                         nextCharge: .now, amount: 8.99,
                                         frequency: "Monthly"))
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<SavedAction>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SubscriptionItem>()).count, 1)
    }

    func testSubscriptionBillingEditsPersistLocally() throws {
        let schema = Schema([SavedAction.self, ReturnItem.self, SubscriptionItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let item = SubscriptionItem(name: "Music", merchant: "Service",
                                    nextCharge: .now, amount: 7.99,
                                    frequency: "Monthly", billingInterval: 1,
                                    currencyCode: "USD")
        context.insert(item)
        try context.save()
        item.name = "Family Music"
        item.amount = 24.95
        item.frequency = "Monthly"
        item.billingInterval = 3
        item.currencyCode = "EUR"
        try context.save()
        let retrieved = try XCTUnwrap(context.fetch(FetchDescriptor<SubscriptionItem>()).first)
        XCTAssertEqual(retrieved.name, "Family Music")
        XCTAssertEqual(retrieved.amount, 24.95)
        XCTAssertEqual(retrieved.effectiveBillingInterval, 3)
        XCTAssertEqual(retrieved.effectiveCurrencyCode, "EUR")
    }

    func testLegacySubscriptionFieldsHaveSafeDefaultValues() {
        let item = SubscriptionItem(name: "Existing", merchant: "",
                                    nextCharge: .now, amount: 5, frequency: "Monthly")
        item.billingInterval = nil
        item.currencyCode = nil
        XCTAssertEqual(item.effectiveBillingInterval, 1)
        XCTAssertEqual(item.effectiveCurrencyCode, "USD")
    }
}
