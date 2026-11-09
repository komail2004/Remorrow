import Foundation

enum SharedInboxError: Error {
    case invalidPayload
    case unavailable
}

/// The extension writes atomically. The main app consumes on launch or foreground.
enum SharedInbox {
    static let groupID = "group.com.komail.Remorrow"

    struct Payload: Codable {
        let id: String
        let type: String
        let text: String?
        let imageFile: String?
        let createdAt: Date
    }

    struct Pending {
        let payload: Payload
        let manifestURL: URL
        let imageURL: URL?
        let imageData: Data?
    }

    /// App Intents are implemented in the containing app. They can use its
    /// private sandbox without requesting an App Group entitlement. This avoids
    /// Shortcuts failing with "client is not entitled" on unprovisioned builds.
    /// The Share and Action extensions still use the App Group separately.
    static func shortcutInboxDirectory() throws -> URL {
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else {
            throw SharedInboxError.unavailable
        }
        return support
            .appendingPathComponent("Remorrow", isDirectory: true)
            .appendingPathComponent("ShortcutInbox", isDirectory: true)
    }

    @discardableResult
    static func stageShortcutText(_ text: String) throws -> URL {
        let selected = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selected.isEmpty && selected.count <= 20_000 else {
            throw SharedInboxError.invalidPayload
        }
        let folder = try shortcutInboxDirectory()
        try FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: true
        )
        let id = UUID().uuidString
        let payload = Payload(
            id: id, type: "text", text: selected,
            imageFile: nil, createdAt: .now
        )
        let url = folder.appendingPathComponent(id + ".json")
        try JSONEncoder().encode(payload).write(to: url, options: .atomic)
        return url
    }

    /// The main app reads both sources. Shortcuts writes to the app sandbox;
    /// extension-generated items arrive through the App Group, if provisioned.
    static func loadOldest() throws -> Pending? {
        var folders = [try shortcutInboxDirectory()]
        if let base = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: groupID
        ) {
            folders.append(base.appendingPathComponent("Inbox", isDirectory: true))
        }
        return try loadOldest(in: folders)
    }

    /// Folder override is also used by tests; no App Group is required.
    static func loadOldest(in folders: [URL]) throws -> Pending? {
        let manager = FileManager.default
        var files: [URL] = []
        for folder in folders where manager.fileExists(atPath: folder.path) {
            let entries = try manager.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: [.creationDateKey]
            )
            files.append(contentsOf: entries.filter { $0.pathExtension == "json" })
        }
        files.sort {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate)
                ?? .distantFuture
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate)
                ?? .distantFuture
            return lhs == rhs ? $0.lastPathComponent < $1.lastPathComponent : lhs < rhs
        }
        guard let manifest = files.first else { return nil }
        let folder = manifest.deletingLastPathComponent()
        let payload = try JSONDecoder().decode(
            Payload.self, from: Data(contentsOf: manifest)
        )
        // Validate image names independently of the source of the manifest.
        let imageURL: URL?
        if let name = payload.imageFile,
           name == URL(fileURLWithPath: name).lastPathComponent,
           name != "." && name != ".." {
            imageURL = folder.appendingPathComponent(name)
        } else {
            imageURL = nil
        }
        let imageData = try imageURL.map { try Data(contentsOf: $0) }
        return Pending(payload: payload, manifestURL: manifest,
                       imageURL: imageURL, imageData: imageData)
    }

    static func remove(_ item: Pending) throws {
        try FileManager.default.removeItem(at: item.manifestURL)
        if let url = item.imageURL { try? FileManager.default.removeItem(at: url) }
    }
}
