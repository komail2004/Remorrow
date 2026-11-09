import XCTest
@testable import Remorrow

final class ShortcutInboxTests: XCTestCase {
    func testStagesPrivateShortcutTextAndImportsWithoutAppGroup() throws {
        let original = "Dinner with Alex on Friday at 7 PM " + UUID().uuidString
        let manifest = try SharedInbox.stageShortcutText("  " + original + "  ")
        defer { try? FileManager.default.removeItem(at: manifest) }

        XCTAssertTrue(manifest.path.contains("ShortcutInbox"))
        let decoded = try JSONDecoder().decode(
            SharedInbox.Payload.self, from: Data(contentsOf: manifest)
        )
        XCTAssertEqual(decoded.type, "text")
        XCTAssertEqual(decoded.text, original)
        XCTAssertNil(decoded.imageFile)

        let staged = try SharedInbox.loadOldest(
            in: [manifest.deletingLastPathComponent()]
        )
        // Use a uniquely named test folder in the second test for deterministic
        // ordering; the important invariant here is that a valid local entry
        // is readable without an App Group container.
        XCTAssertNotNil(staged)
    }

    func testImporterReadsPrivateFolderWithNoGroup() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemorrowShortcutTest-" + UUID().uuidString,
                                    isDirectory: true)
        try FileManager.default.createDirectory(
            at: folder, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: folder) }
        let id = UUID().uuidString
        let payload = SharedInbox.Payload(
            id: id, type: "text", text: "Submit assignment Friday",
            imageFile: nil, createdAt: .now
        )
        let file = folder.appendingPathComponent(id + ".json")
        try JSONEncoder().encode(payload).write(to: file, options: .atomic)

        let imported = try XCTUnwrap(SharedInbox.loadOldest(in: [folder]))
        XCTAssertEqual(imported.payload.text, "Submit assignment Friday")
        XCTAssertEqual(imported.manifestURL, file)
        try SharedInbox.remove(imported)
        XCTAssertNil(try SharedInbox.loadOldest(in: [folder]))
    }

    func testRejectsBlankAndOversizedShortcutInputs() {
        XCTAssertThrowsError(try SharedInbox.stageShortcutText("  "))
        XCTAssertThrowsError(
            try SharedInbox.stageShortcutText(String(repeating: "A", count: 20_001))
        )
    }
}
