import Foundation
import UserNotifications

/// A generic notification body avoids exposing receipt/item details on the lock screen.
struct ReturnNotificationScheduler {
    static func identifier(_ id: UUID) -> String { "return-" + id.uuidString }

    func schedule(_ item: ReturnItem) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(item.id)])
        guard !item.isReturned else { return false }

        let status = await center.notificationSettings()
        let allowed: Bool
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            allowed = true
        case .notDetermined:
            allowed = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        default:
            allowed = false
        }
        guard allowed else { return false }

        let now = Date()
        guard item.deadline > now else { return false }
        let twoDaysBefore = item.deadline.addingTimeInterval(-2 * 24 * 60 * 60)
        let alertDate = twoDaysBefore > now ? twoDaysBefore : item.deadline.addingTimeInterval(-60 * 60)
        guard alertDate > now else { return false }

        let content = UNMutableNotificationContent()
        content.title = "A return deadline is coming up"
        content.body = "Open Remorrow to check the details."
        content.sound = .default
        let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        try await center.add(UNNotificationRequest(identifier: Self.identifier(item.id), content: content, trigger: trigger))
        return true
    }

    func cancel(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.identifier(id)])
    }
}
