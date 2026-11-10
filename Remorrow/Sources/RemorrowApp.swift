import SwiftUI
import SwiftData

@main
struct RemorrowApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--remorrow-ui-resolve") {
                ResolveConflictView(
                    proposedTitle: "Research presentation",
                    proposedStart: Date().addingTimeInterval(48 * 3600),
                    proposedSavedPlan: nil,
                    conflictingPlan: SavedPlanRecord(
                        id: UUID(), title: "Dinner with friends",
                        dueAt: Date().addingTimeInterval(48 * 3600),
                        kind: "calendarEvent"
                    ),
                    onChooseProposedTime: { _ in },
                    onMoveSavedEvent: { _, _ in }
                )
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
        .modelContainer(for: [SavedAction.self, ReturnItem.self, SubscriptionItem.self])
    }
}
