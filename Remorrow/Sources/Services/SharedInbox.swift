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
        var queue: [(url: URL, payload: Payload)] = []
        for folder in folders where manager.fileExists(atPath: folder.path) {
            let entries = try manager.contentsOfDirectory(
                at: folder, includingPropertiesForKeys: nil
            )
            for file in entries where file.pathExtension == "json" {
                // Manifests contain the author's timestamp. Reading that is
                // more reliable than filesystem creation dates (and avoids
                // platform file-timestamp metadata permissions).
                // Shared content originates in other apps. Bound manifest size
                // before decoding to prevent unbounded JSON allocations.
                guard let handle = try? FileHandle(forReadingFrom: file) else { continue }
                let data = try? handle.read(upToCount: 256 * 1024 + 1)
                try? handle.close()
                guard let data, data.count <= 256 * 1024,
                      let payload = try? JSONDecoder().decode(Payload.self, from: data)
                else { continue }
                queue.append((url: file, payload: payload))
            }
        }
        queue.sort {
            if $0.payload.createdAt != $1.payload.createdAt {
                return $0.payload.createdAt < $1.payload.createdAt
            }
            return $0.url.lastPathComponent < $1.url.lastPathComponent
        }
        guard let next = queue.first else { return nil }
        let manifest = next.url
        let payload = next.payload
        let folder = manifest.deletingLastPathComponent()
        // Validate image names independently of the source of the manifest.
        let imageURL: URL?
        if let name = payload.imageFile,
           name == URL(fileURLWithPath: name).lastPathComponent,
           name != "." && name != ".." {
            imageURL = folder.appendingPathComponent(name)
        } else {
            imageURL = nil
        }
        // Prevent accidentally decoding an enormous shared file into memory.
        // The original stays queued if it exceeds this cap; the app reports
        // the import failure without committing any external action.
        let imageData: Data?
        if let imageURL {
            // Read at most the allowed payload plus one byte; this avoids
            // file-timestamp metadata APIs and prevents a giant shared image
            // from allocating unbounded memory before validation.
            let handle = try FileHandle(forReadingFrom: imageURL)
            defer { try? handle.close() }
            let limit = 30 * 1024 * 1024
            var bytes = Data()
            while bytes.count <= limit {
                let request = min(1024 * 1024, limit + 1 - bytes.count)
                guard let chunk = try handle.read(upToCount: request),
                      !chunk.isEmpty else { break }
                bytes.append(chunk)
            }
            guard bytes.count <= limit else {
                throw SharedInboxError.invalidPayload
            }
            imageData = bytes
        } else {
            imageData = nil
        }
        return Pending(payload: payload, manifestURL: manifest,
                       imageURL: imageURL, imageData: imageData)
    }

    static func remove(_ item: Pending) throws {
        try FileManager.default.removeItem(at: item.manifestURL)
        if let url = item.imageURL { try? FileManager.default.removeItem(at: url) }
    }
}
