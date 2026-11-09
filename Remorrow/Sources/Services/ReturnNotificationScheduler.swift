import Foundation
import UserNotifications

/// A generic notification body avoids exposing receipt/item details on the lock screen.
struct ReturnNotificationScheduler {
    static func identifier(_ id: UUID) -> String { "return-" + id.uuidString }

    func schedule(_ item: ReturnItem) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier(item.id)])
        guard !item.isReturned && item.hasConfirmedReturnDeadline else { return false }

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
        guard let alertDate = SmartNotificationTiming.warningDate(
            dueAt: item.deadline, title: item.itemName, kind: "return", now: now) else { return false }

        let content = UNMutableNotificationContent()
        content.title = "A return deadline is coming up"
        content.body = "Open Remorrow to check the details."
        content.sound = .default
        let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: false)
        try await center.add(UNNotificationRequest(identifier: Self.identifier(item.id), content: content, trigger: trigger))
        return true
    }

    func scheduleWarranty(_ item: ReturnItem) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let identifier = "warranty-" + item.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard let expires = item.warrantyExpiresAt, expires > Date() else { return false }
        let status = await center.notificationSettings()
        guard status.authorizationStatus == .authorized || status.authorizationStatus == .provisional else { return false }
        let prior = Calendar.current.date(byAdding: .day, value: -14, to: expires) ?? expires
        let fire = prior > Date() ? prior : expires.addingTimeInterval(-86400)
        guard fire > Date() else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Warranty coverage is approaching its end"
        content.body = "Open Remorrow to check your proof of purchase."
        content.sound = .default
        let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        try await center.add(UNNotificationRequest(
            identifier: identifier, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: false)))
        return true
    }

    func cancelWarranty(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["warranty-" + id.uuidString])
    }

    func cancel(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.identifier(id)])
    }
}
