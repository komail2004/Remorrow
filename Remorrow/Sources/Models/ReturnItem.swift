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
    var sourceText: String? = nil
    var attachmentName: String? = nil

    init(itemName: String, merchant: String, deadline: Date, isReturned: Bool = false) {
        id = UUID()
        self.itemName = itemName
        self.merchant = merchant
        self.deadline = deadline
        createdAt = .now
        self.isReturned = isReturned
    }
}
