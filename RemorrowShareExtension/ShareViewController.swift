import UIKit
import UniformTypeIdentifiers

/// The user deliberately shares content. The extension does NOT read other apps in the background.
final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let doneButton = UIButton(type: .system)
    private var isFinished = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureInterface()
        importProvidedItems()
    }

    private func configureInterface() {
        let icon = UIImageView(image: UIImage(systemName: "bookmark.fill"))
        icon.tintColor = UIColor(red: 0.39, green: 0.31, blue: 0.89, alpha: 1)
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let heading = UILabel()
        heading.text = "Save to Remorrow"
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.textAlignment = .center

        statusLabel.text = "Preparing your shared content..."
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel

        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.isEnabled = false
        doneButton.addTarget(self, action: #selector(finish), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, heading, statusLabel, doneButton])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 26),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -26)
        ])
    }

    private func importProvidedItems() {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        guard !providers.isEmpty else {
            show("No compatible item was shared.", success: false)
            return
        }

        // Prefer text and URLs; fall back to screenshot/image data.
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] value, error in
                    guard let self else { return }
                    guard error == nil else { self.show("Couldn't read the shared text.", success: false); return }
                    let text = (value as? String) ?? (value as? NSString).map { String($0) }
                    guard let text, !text.isEmpty else { self.show("Shared text was empty.", success: false); return }
                    self.store(type: "text", text: text, image: nil)
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, error in
                    guard let self else { return }
                    guard error == nil, let url = value as? URL else {
                        self.show("Couldn't read the shared link.", success: false); return
                    }
                    // A shared URL is not the website body. No network fetch is implied.
                    self.store(type: "text", text: url.absoluteString, image: nil)
                }
                return
            }
            if let imageType = provider.registeredTypeIdentifiers.first(where: {
                UTType($0)?.conforms(to: .image) == true
            }) {
                provider.loadDataRepresentation(forTypeIdentifier: imageType) { [weak self] data, error in
                    guard let self else { return }
                    guard error == nil, let data else {
                        self.show("Couldn't read the shared image.", success: false); return
                    }
                    self.store(type: "image", text: nil, image: data)
                }
                return
            }
        }
        show("Share text, a web link, or one image.", success: false)
    }

    private func store(type: String, text: String?, image: Data?) {
        do {
            guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.komail.Remorrow") else {
                throw NSError(domain: "RemorrowShare", code: 1)
            }
            let folder = container.appendingPathComponent("Inbox", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let id = UUID().uuidString
            let imageFile = image == nil ? nil : id + ".image"
            if let image, let imageFile {
                try image.write(to: folder.appendingPathComponent(imageFile), options: .atomic)
            }
            let payload = SharePayload(id: id, type: type, text: text, imageFile: imageFile, createdAt: Date())
            let data = try JSONEncoder().encode(payload)
            try data.write(to: folder.appendingPathComponent(id + ".json"), options: .atomic)
            show("Saved for review. Open Remorrow to make your reminder.", success: true)
        } catch {
            show("Couldn't save the share. Check Remorrow's App Group capability.", success: false)
        }
    }

    private func show(_ message: String, success: Bool) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.doneButton.isEnabled = true
        }
    }

    @objc private func finish() {
        guard !isFinished else { return }
        isFinished = true
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

private struct SharePayload: Codable {
    let id: String
    let type: String
    let text: String?
    let imageFile: String?
    let createdAt: Date
}
