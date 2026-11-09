import Foundation

/// Privacy-respecting suggestions. Never schedule an alert without a user's
/// existing approval/notification permissions. All dates can be changed.
enum SmartNotificationTiming {
    static func leadSeconds(title: String, kind: String, frequency: String? = nil) -> TimeInterval {
        let value = title.lowercased()
        if kind == "warranty" { return 14 * 86400 }
        if kind == "return" { return 2 * 86400 }
        if kind == "subscription" {
            return frequency?.lowercased() == "yearly" ? 7 * 86400 : 2 * 86400
        }
        if ["flight", "airport", "trip"].contains(where: { value.contains($0) }) { return 24 * 3600 }
        if ["exam", "presentation", "interview", "submit", "assignment", "deadline", "due"].contains(where: { value.contains($0) }) {
            return 24 * 3600
        }
        if ["meeting", "appointment", "dinner", "lunch"].contains(where: { value.contains($0) }) { return 30 * 60 }
        return 60 * 60
    }

    static func warningDate(dueAt: Date, title: String, kind: String,
                            frequency: String? = nil, now: Date = .now) -> Date? {
        guard dueAt > now else { return nil }
        let lead = leadSeconds(title: title, kind: kind, frequency: frequency)
        let desired = dueAt.addingTimeInterval(-lead)
        if desired > now { return desired }
        // If the ideal time already passed, offer a nearer warning only when
        // there is time for the user to act; never schedule an alert in the past.
        let soon = now.addingTimeInterval(60)
        return soon < dueAt ? soon : nil
    }
}
