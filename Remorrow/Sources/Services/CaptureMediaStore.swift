import Foundation
import UIKit

/// Stores only images deliberately captured/selected by the user.
enum CaptureMediaStore {
    static func save(_ data: Data) throws -> String {
        let folder = try directory()
        let name = UUID().uuidString + ".jpg"
        guard let original = UIImage(data: data),
              let imageData = original.jpegData(compressionQuality: 0.78) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try imageData.write(to: folder.appendingPathComponent(name), options: .atomic)
        return name
    }

    static func image(named name: String?) -> UIImage? {
        guard let name, name == URL(fileURLWithPath: name).lastPathComponent,
              let folder = try? directory() else { return nil }
        return UIImage(contentsOfFile: folder.appendingPathComponent(name).path)
    }

    static func remove(named name: String?) {
        guard let name, name == URL(fileURLWithPath: name).lastPathComponent,
              let folder = try? directory() else { return }
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }

    private static func directory() throws -> URL {
        let library = try FileManager.default.url(for: .applicationSupportDirectory,
                                                  in: .userDomainMask, appropriateFor: nil, create: true)
        let folder = library.appendingPathComponent("CapturedImages", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
