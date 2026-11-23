import Foundation
import SwiftData

/// User-confirmed merchant deadline. Does not infer retailer policies.
@Model
final class ReturnItem {
    @Attribute(.unique) var id: UUID
    var itemName: String
    var merchant: String
    var deadline: Date
    var createdAt: Date
    var isReturned: Bool
    var purchaseAmount: Double? = nil
    // Optional: existing receipts remain readable without a schema reset.
    var purchaseCurrencyCode: String? = nil
    var purchaseDate: Date? = nil
    var warrantyExpiresAt: Date? = nil
    var hasConfirmedReturnDeadline: Bool = true
    var receiptNumber: String? = nil
    var sourceText: String? = nil
    var attachmentName: String? = nil

    var effectiveCurrencyCode: String {
        guard let code = purchaseCurrencyCode?.uppercased(), code.count == 3 else { return "USD" }
        return code
    }

    init(itemName: String, merchant: String, deadline: Date, isReturned: Bool = false) {
        id = UUID()
        self.itemName = itemName
        self.merchant = merchant
        self.deadline = deadline
        createdAt = .now
        self.isReturned = isReturned
    }
}
