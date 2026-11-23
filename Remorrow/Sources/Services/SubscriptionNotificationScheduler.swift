import Foundation
import UserNotifications

/// Privacy-preserving charge reminders. Only the first explicitly confirmed
/// date is verified; later reminders are visibly identified as projections.
/// A maximum of two are queued per subscription to limit iOS pending requests.
struct SubscriptionNotificationScheduler {
    static func identifier(_ id: UUID) -> String { "subscription-" + id.uuidString }

    private static func identifiers(_ id: UUID) -> [String] {
        [identifier(id), identifier(id) + "-projected"]
    }

    func schedule(_ item: SubscriptionItem) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let ids = Self.identifiers(item.id)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard item.isActive else { return false }

        let status = await center.notificationSettings()
        let allowed: Bool
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            allowed = true
        case .notDetermined:
            allowed = try await center.requestAuthorization(options: [.alert, .sound])
        default:
            allowed = false
        }
        guard allowed else { return false }

        let next = SubscriptionForecast.upcomingOccurrences(
            from: item.nextCharge, frequency: item.frequency,
            intervalCount: item.effectiveBillingInterval, count: 2)
        var scheduled = false
        for (index, occurrence) in next.enumerated() {
            guard let fire = SmartNotificationTiming.warningDate(
                dueAt: occurrence.date, title: item.name, kind: "subscription",
                frequency: item.frequency) else { continue }
            let payload = UNMutableNotificationContent()
            payload.title = occurrence.isProjected
                ? "A subscription renewal may be approaching"
                : "A subscription charge is coming up"
            payload.body = occurrence.isProjected
                ? "Open Remorrow to verify this projected renewal date."
                : "Open Remorrow to review the renewal details."
            payload.sound = .default
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fire)
            try await center.add(UNNotificationRequest(
                identifier: ids[index], content: payload,
                trigger: UNCalendarNotificationTrigger(dateMatching: components,
                                                       repeats: false)))
            scheduled = true
        }
        return scheduled
    }

    func cancel(_ id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: Self.identifiers(id))
    }
}
