import Foundation

/// An untrusted suggestion for a future user-approved action.
/// Deliberately contains no EventKit, UserNotifications, or persistence side effects.
enum ProposedActionKind: String, Codable, Sendable {
    case calendarEvent
    case reminder
    case shoppingReturn
}

enum ProposalOrigin: String, Codable, Sendable {
    case localRules
    case appleFoundationModels
    case cloudOptIn
}

struct ActionProposal: Identifiable, Codable, Sendable {
    var id: UUID
    var kind: ProposedActionKind
    var title: String
    var sourceEvidence: String
    /// Optional, because a missing/ambiguous date MUST NOT be invented.
    var proposedDate: Date?
    var uncertaintyFlags: [String]
    var origin: ProposalOrigin

    init(
        id: UUID = UUID(),
        kind: ProposedActionKind,
        title: String,
        sourceEvidence: String,
        proposedDate: Date? = nil,
        uncertaintyFlags: [String] = [],
        origin: ProposalOrigin
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.sourceEvidence = sourceEvidence
        self.proposedDate = proposedDate
        self.uncertaintyFlags = uncertaintyFlags
        self.origin = origin
    }
}
