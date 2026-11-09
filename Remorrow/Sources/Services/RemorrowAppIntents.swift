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
        guard let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: SharedInbox.groupID) else {
            throw SharedInboxError.unavailable
        }
        let folder = base.appendingPathComponent("Inbox", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let id = UUID().uuidString
        let payload = SharedInbox.Payload(
            id: id, type: "text", text: selected, imageFile: nil, createdAt: .now
        )
        try JSONEncoder().encode(payload)
            .write(to: folder.appendingPathComponent(id + ".json"), options: .atomic)
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
