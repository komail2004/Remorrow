import Foundation
import EventKit

struct ResolveEventDetails {
    let duration: TimeInterval
    let canMoveDirectly: Bool
    let hasAttendees: Bool
}

enum ResolveCalendarError: LocalizedError {
    case accessDenied
    case missingEvent
    case readOnlyOrShared
    case timeNoLongerFree
    case noCalendars

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access isn't enabled. You can allow it in iPhone Settings. No times have been guessed."
        case .missingEvent:
            return "The saved event could not be found in Calendar. Check the event before trying again."
        case .readOnlyOrShared:
            return "This event involves other people or isn't editable here. Propose a time instead."
        case .timeNoLongerFree:
            return "That time is no longer free in your calendars. Check again for alternatives."
        case .noCalendars:
            return "There are no accessible calendars to verify. Add or enable a calendar before checking free times."
        }
    }
}

/// Only invoked after the user chooses to check availability.
/// Does not read Messages, invitees' calendars, or server data.
@MainActor
final class ResolveCalendarService {
    private let store = EKEventStore()

    private func authorize() async throws {
        guard try await store.requestFullAccessToEvents() else {
            throw ResolveCalendarError.accessDenied
        }
        guard !store.calendars(for: .event).isEmpty else {
            throw ResolveCalendarError.noCalendars
        }
    }

    func details(externalID: String) async throws -> ResolveEventDetails {
        try await authorize()
        guard let event = store.event(withIdentifier: externalID) else {
            throw ResolveCalendarError.missingEvent
        }
        return ResolveEventDetails(
            duration: max(15*60, event.endDate.timeIntervalSince(event.startDate)),
            canMoveDirectly: event.calendar.allowsContentModifications &&
                !event.hasAttendees && !event.isAllDay,
            hasAttendees: event.hasAttendees
        )
    }

    func suggestions(
        around preferred: Date,
        duration: TimeInterval,
        excluding eventID: String? = nil,
        alsoBlocking tentative: [ResolveBusyInterval] = []
    ) async throws -> [ResolveSuggestion] {
        try await authorize()
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: max(preferred, Date()))
        guard let horizon = calendar.date(byAdding: .day, value: 9, to: start) else {
            return []
        }
        let predicate = store.predicateForEvents(withStart: start, end: horizon, calendars: nil)
        let events = store.events(matching: predicate)
        let busy: [ResolveBusyInterval] = events.compactMap {
            guard $0.availability != .free,
                  $0.eventIdentifier != eventID else { return nil }
            return ResolveBusyInterval(start: $0.startDate, end: $0.endDate)
        }
        return ResolveSlotPlanner.suggestions(
            around: preferred, duration: duration, busy: busy + tentative,
            calendar: calendar
        )
    }

    /// Repeat a fresh EventKit query at the moment of confirmation, rather
    /// than trusting availability that might have become stale in the sheet.
    func validate(
        date: Date,
        duration: TimeInterval,
        excluding eventID: String? = nil,
        alsoBlocking tentative: [ResolveBusyInterval] = []
    ) async throws {
        try await authorize()
        let start = date.addingTimeInterval(-15*60)
        let end = date.addingTimeInterval(duration + 15*60)
        let events = store.events(matching:
            store.predicateForEvents(withStart: start, end: end, calendars: nil)
        )
        let busy = events.compactMap { event -> ResolveBusyInterval? in
            guard event.availability != .free,
                  event.eventIdentifier != eventID else { return nil }
            return ResolveBusyInterval(start: event.startDate, end: event.endDate)
        }
        guard ResolveSlotPlanner.isFree(start: date, duration: duration,
                                        busy: busy + tentative) else {
            throw ResolveCalendarError.timeNoLongerFree
        }
    }
}
