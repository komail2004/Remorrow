import Foundation
import SwiftData

@Model
final class SavedAction {
    @Attribute(.unique) var id: UUID
    var title: String
    var dueAt: Date
    var kind: String
    var externalID: String
    var createdAt: Date

    init(title: String, dueAt: Date, kind: String, externalID: String) {
        self.id = UUID()
        self.title = title
        self.dueAt = dueAt
        self.kind = kind
        self.externalID = externalID
        self.createdAt = .now
    }
}
