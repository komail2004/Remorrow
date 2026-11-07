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
    var isActive: Bool
    var createdAt: Date
    var sourceText: String?
    var attachmentName: String?

    init(name: String, merchant: String, nextCharge: Date,
         amount: Double? = nil, frequency: String = "Monthly",
         sourceText: String? = nil, attachmentName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.merchant = merchant
        self.nextCharge = nextCharge
        self.amount = amount
        self.frequency = frequency
        self.isActive = true
        self.createdAt = .now
        self.sourceText = sourceText
        self.attachmentName = attachmentName
    }
}
