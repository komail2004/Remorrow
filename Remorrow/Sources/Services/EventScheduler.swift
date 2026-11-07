import Foundation
import EventKit

enum ScheduleFailure: LocalizedError {
    case accessDenied
    case noCalendar
    case invalidKind

    var errorDescription: String? {
        switch self {
        case .accessDenied: "Calendar or Reminders access is disabled. You can allow it in Settings."
        case .noCalendar: "No writable calendar or reminders list was found."
        case .invalidKind: "This type can't be saved yet."
        }
    }
}

/// All system changes happen only following explicit review and confirmation.
@MainActor
final class EventScheduler {
    private let store = EKEventStore()

    func save(title: String, date: Date, kind: ProposedActionKind) async throws -> String {
        switch kind {
        case .calendarEvent:
            guard try await store.requestFullAccessToEvents() else { throw ScheduleFailure.accessDenied }
            let event = EKEvent(eventStore: store)
            event.title = title
            event.startDate = date
            event.endDate = date.addingTimeInterval(3600)
            guard let calendar = store.defaultCalendarForNewEvents else { throw ScheduleFailure.noCalendar }
            event.calendar = calendar
            try store.save(event, span: .thisEvent)
            return event.eventIdentifier ?? UUID().uuidString
        case .reminder:
            guard try await store.requestFullAccessToReminders() else { throw ScheduleFailure.accessDenied }
            let reminder = EKReminder(eventStore: store)
            reminder.title = title
            guard let calendar = store.defaultCalendarForNewReminders() else { throw ScheduleFailure.noCalendar }
            reminder.calendar = calendar
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            reminder.dueDateComponents = components
            reminder.addAlarm(EKAlarm(absoluteDate: date))
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        case .shoppingReturn:
            throw ScheduleFailure.invalidKind
        }
    }

    func delete(kind: String, externalID: String) async throws {
        if kind == ProposedActionKind.calendarEvent.rawValue {
            guard try await store.requestFullAccessToEvents() else { throw ScheduleFailure.accessDenied }
            guard let event = store.event(withIdentifier: externalID) else { return }
            try store.remove(event, span: .thisEvent, commit: true)
        } else if kind == ProposedActionKind.reminder.rawValue {
            guard try await store.requestFullAccessToReminders() else { throw ScheduleFailure.accessDenied }
            guard let reminder = store.calendarItem(withIdentifier: externalID) as? EKReminder else { return }
            try store.remove(reminder, commit: true)
        } else {
            throw ScheduleFailure.invalidKind
        }
    }
}
