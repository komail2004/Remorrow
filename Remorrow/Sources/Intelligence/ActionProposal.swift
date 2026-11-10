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
    /// Explicit clock time can be known even when the day is unknown.
    var suggestedHour: Int?
    var suggestedMinute: Int?
    var uncertaintyFlags: [String]
    var origin: ProposalOrigin

    init(
        id: UUID = UUID(),
        kind: ProposedActionKind,
        title: String,
        sourceEvidence: String,
        proposedDate: Date? = nil,
        suggestedHour: Int? = nil,
        suggestedMinute: Int? = nil,
        uncertaintyFlags: [String] = [],
        origin: ProposalOrigin
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.sourceEvidence = sourceEvidence
        self.proposedDate = proposedDate
        self.suggestedHour = suggestedHour
        self.suggestedMinute = suggestedMinute
        self.uncertaintyFlags = uncertaintyFlags
        self.origin = origin
    }
}
