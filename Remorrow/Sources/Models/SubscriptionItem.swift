import Foundation
import SwiftData

/// Explicitly confirmed subscription charge date. No bank or email access.
@Model
final class SubscriptionItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var merchant: String
    var nextCharge: Date
    var amount: Double?
    var frequency: String
    // Optional for safe migration of subscriptions created by previous versions.
    var billingInterval: Int?
    var currencyCode: String?
    var isActive: Bool
    var createdAt: Date
    var sourceText: String?
    var attachmentName: String?

    init(name: String, merchant: String, nextCharge: Date,
         amount: Double? = nil, frequency: String = "Monthly",
         billingInterval: Int = 1, currencyCode: String = "USD",
         sourceText: String? = nil, attachmentName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.merchant = merchant
        self.nextCharge = nextCharge
        self.amount = amount
        self.frequency = frequency
        self.billingInterval = max(1, min(365, billingInterval))
        self.currencyCode = currencyCode.uppercased()
        self.isActive = true
        self.createdAt = .now
        self.sourceText = sourceText
        self.attachmentName = attachmentName
    }

    var effectiveBillingInterval: Int { max(1, min(365, billingInterval ?? 1)) }
    var effectiveCurrencyCode: String {
        guard let code = currencyCode?.uppercased(), code.count == 3 else { return "USD" }
        return code
    }
}
