import Foundation
import UserNotifications

struct DailyBriefingScheduler {
    static let identifier = "remorrow-daily-briefing"

    func configure(enabled: Bool, hour: Int) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        guard enabled else { return true }
        let settings = await center.notificationSettings()
        let permission: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: permission = true
        case .notDetermined:
            permission = try await center.requestAuthorization(options: [.alert, .sound])
        default: permission = false
        }
        guard permission else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Your Remorrow daily briefing is ready"
        content.body = "See what needs attention today. No personal details are shown here."
        content.sound = .default
        let components = DateComponents(hour: min(23, max(0, hour)), minute: 0)
        try await center.add(UNNotificationRequest(
            identifier: Self.identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        ))
        return true
    }
}
