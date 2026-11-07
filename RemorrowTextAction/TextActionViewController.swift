import UIKit
import UniformTypeIdentifiers

/// Appears as "Remember with Remorrow" for text shared by compatible host apps.
/// The extension cannot read unselected messages or other apps' private content.
final class TextActionViewController: UIViewController {
    private let preview = UITextView()
    private let statusLabel = UILabel()
    private let saveButton = UIButton(type: .system)
    private var selectedText: String?
    private var isSaving = false
    private let groupID = "group.com.komail.Remorrow"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildInterface()
        loadExplicitlySelectedText()
    }

    private func buildInterface() {
        let titleLabel = UILabel()
        titleLabel.text = "Remember with Remorrow"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0

        let explanation = UILabel()
        explanation.text = "Save this selection to Remorrow. You will review dates and actions before anything is added to Calendar or Reminders."
        explanation.font = .preferredFont(forTextStyle: .subheadline)
        explanation.textColor = .secondaryLabel
        explanation.numberOfLines = 0

        preview.backgroundColor = .secondarySystemGroupedBackground
        preview.layer.cornerRadius = 14
        preview.font = .preferredFont(forTextStyle: .body)
        preview.isEditable = true
        preview.accessibilityLabel = "Selected text for Remorrow"
        preview.heightAnchor.constraint(greaterThanOrEqualToConstant: 140).isActive = true

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = "Reading selected text…"

        saveButton.setTitle("Save for review", for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(saveSelectedText), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttons.axis = .horizontal
        buttons.distribution = .equalSpacing
        buttons.alignment = .center
        buttons.spacing = 16

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, explanation, preview, statusLabel, buttons
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func loadExplicitlySelectedText() {
        let inputItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        let providers = inputItems.flatMap { $0.attachments ?? [] }

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] value, error in
                    guard let self else { return }
                    let string = (value as? String)
                        ?? (value as? NSAttributedString)?.string
                        ?? (value as? NSString).map { String($0) }
                    self.finishLoading(error == nil ? string : nil)
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, error in
                    guard let self else { return }
                    self.finishLoading(error == nil ? (value as? URL)?.absoluteString : nil)
                }
                return
            }
        }
        finishLoading(nil)
    }

    private func finishLoading(_ text: String?) {
        DispatchQueue.main.async {
            let cleaned = text?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.selectedText = cleaned
            self.preview.text = cleaned ?? ""
            self.saveButton.isEnabled = !(cleaned ?? "").isEmpty
            self.statusLabel.text = self.saveButton.isEnabled
                ? "Only this selected text will be stored on your iPhone."
                : "This app did not provide shareable text. Copy it and use Paste in Remorrow instead."
        }
    }

    @objc private func saveSelectedText() {
        guard !isSaving else { return }
        let text = preview.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            statusLabel.text = "Choose some text before saving."
            return
        }
        isSaving = true
        saveButton.isEnabled = false
        do {
            guard let container = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: groupID
            ) else {
                throw CocoaError(.fileNoSuchFile)
            }
            let folder = container.appendingPathComponent("Inbox", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let id = UUID().uuidString
            let payload = InboxPayload(
                id: id, type: "text", text: text, imageFile: nil, createdAt: Date()
            )
            let data = try JSONEncoder().encode(payload)
            // Same contract as the existing Share Extension and SharedInbox reader.
            try data.write(to: folder.appendingPathComponent(id + ".json"), options: .atomic)
            statusLabel.text = "Saved. Open Remorrow to review and confirm."
            saveButton.setTitle("Saved", for: .normal)
            saveButton.isEnabled = false
        } catch {
            isSaving = false
            saveButton.isEnabled = true
            statusLabel.text = "Could not save locally. Check App Group signing for both targets."
        }
    }

    @objc private func cancel() {
        extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
    }

    private struct InboxPayload: Codable {
        let id: String
        let type: String
        let text: String?
        let imageFile: String?
        let createdAt: Date
    }
}
