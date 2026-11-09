import Foundation
import WidgetKit

/// Writes only aggregate counts to the Home Screen by default.
/// The name of the next item is shared only after a separate opt-in.
@MainActor
enum WidgetSnapshotWriter {
    private struct Digest: Codable {
        var overdue: Int
        var today: Int
        var soon: Int
        var nextTitle: String?
        var nextDueAt: Date?
        var updatedAt: Date
    }

    static func publish(briefing: DailyBriefing, allowDetails: Bool) {
        guard let defaults = UserDefaults(suiteName: "group.com.komail.Remorrow") else { return }
        let upcoming = (briefing.today + briefing.soon).sorted { $0.dueAt < $1.dueAt }
        let first = upcoming.first
        let digest = Digest(overdue: briefing.overdue.count,
                            today: briefing.today.count, soon: briefing.soon.count,
                            nextTitle: allowDetails ? first?.title : nil,
                            nextDueAt: allowDetails ? first?.dueAt : nil,
                            updatedAt: .now)
        guard let encoded = try? JSONEncoder().encode(digest) else { return }
        defaults.set(encoded, forKey: "widgetDigestV1")
        WidgetCenter.shared.reloadTimelines(ofKind: "com.komail.Remorrow.today")
    }
}
