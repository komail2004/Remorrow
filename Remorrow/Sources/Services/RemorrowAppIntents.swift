import AppIntents
import Foundation

/// An explicit, private Siri/Shortcuts entry point for text that the user
/// deliberately supplies. No automated Messages access or network requests.
struct RememberWithRemorrowIntent: AppIntent {
    static var title: LocalizedStringResource = "Remember with Remorrow"
    static var description = IntentDescription("Send chosen text to your private Remorrow review inbox.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Text to remember")
    var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let selected = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ShortcutCapturePolicy.isValid(selected) else {
            return .result(dialog: "Provide some text, up to 20,000 characters.")
        }
        // App Intent runs in Remorrow's app context. The app-private inbox
        // works without App Group provisioning and remains fully on-device.
        try SharedInbox.stageShortcutText(selected)
        return .result(dialog: "Saved privately. Open Remorrow to review the reminder.")
    }
}

struct RemorrowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: RememberWithRemorrowIntent(),
                    phrases: [
                        "Remember with \(.applicationName)",
                        "Save something with \(.applicationName)"
                    ],
                    shortTitle: "Remember",
                    systemImageName: "bookmark")
    }
}

enum ShortcutCapturePolicy {
    static func isValid(_ text: String) -> Bool {
        let count = text.trimmingCharacters(in: .whitespacesAndNewlines).count
        return count > 0 && count <= 20_000
    }
}
