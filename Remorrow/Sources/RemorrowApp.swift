import SwiftUI
import SwiftData

@main
struct RemorrowApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SavedAction.self, ReturnItem.self])
    }
}
