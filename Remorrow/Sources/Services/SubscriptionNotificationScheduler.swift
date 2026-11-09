import Foundation
import UserNotifications

/// Generic notifications protect subscription names and amounts on lock screen.
struct SubscriptionNotificationScheduler {
    static func identifier(_ id: UUID) -> String { "subscription-" + id.uuidString }

    func schedule(_ item: SubscriptionItem) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(item.id)])
        guard item.isActive && item.nextCharge > Date() else { return false }
        let status = await center.notificationSettings()
        let allowed: Bool
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral: allowed = true
        case .notDetermined:
            allowed = try await center.requestAuthorization(options: [.alert, .sound])
        default: allowed = false
        }
        guard allowed else { return false }
        guard let fire = SmartNotificationTiming.warningDate(
            dueAt: item.nextCharge, title: item.name, kind: "subscription", frequency: item.frequency) else {
            return false
        }
        let payload = UNMutableNotificationContent()
        payload.title = "A subscription charge is coming up"
        payload.body = "Open Remorrow to review the renewal details."
        payload.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        try await center.add(UNNotificationRequest(
            identifier: Self.identifier(item.id), content: payload,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        ))
        return true
    }

    func cancel(_ id: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.identifier(id)])
    }
}
