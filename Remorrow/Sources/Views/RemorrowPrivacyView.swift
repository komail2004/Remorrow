import SwiftUI

/// A readable on-device explanation; the separate public policy URL must be
/// supplied and verified before the App Store submission.
struct RemorrowPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 19) {
                VStack(alignment: .leading, spacing: 9) {
                    Label("PRIVATE BY DESIGN", systemImage: "lock.shield")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(RemorrowStyle.violet)
                    Text("Your moments stay yours.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Remorrow works locally, and you decide what gets saved.")
                        .font(.subheadline)
                        .foregroundStyle(RemorrowStyle.secondaryText)
                }

                section("What Remorrow can see",
                        icon: "hand.tap",
                        body: "Only text you enter, paste or explicitly share, and photos you select or take. Remorrow does not scan your Messages, emails, contacts or photo library in the background.")

                section("On-device understanding",
                        icon: "sparkles",
                        body: "OCR uses Apple's Vision framework on your device. When available, Apple's on-device intelligence may interpret text; an offline rules engine is the fallback. Remorrow has no app-owned cloud analysis service.")

                section("Calendar, Reminders and notifications",
                        icon: "calendar",
                        body: "Remorrow requests iOS permission when needed. It reads calendars you authorize to check possible conflicts and available slots. Adding or changing events needs your approval. Apple Calendar and Reminders can sync through accounts configured in iOS; Remorrow does not control those services.")

                section("Where your information is kept",
                        icon: "iphone",
                        body: "Saved plans, receipt details, original selected images and extracted text are kept in the app's local storage. Shared-content extensions use a limited App Group inbox. iOS device backups may include app data depending on your backup settings.")

                section("What appears on your lock screen",
                        icon: "bell",
                        body: "Return and subscription alerts use generic text. Home Screen widgets show counts by default; showing the next plan title is optional in Settings.")

                section("Your control",
                        icon: "trash",
                        body: "You can delete saved plans, receipts and subscriptions in Remorrow. For plans linked to Calendar or Reminders, Remorrow also attempts to remove the corresponding Apple item. Review any errors in the Apple app.")

                Text("This is an in-app privacy explanation for the current build. An externally accessible privacy policy and App Store privacy disclosures must be finalized before release.")
                    .font(.caption)
                    .foregroundStyle(RemorrowStyle.secondaryText)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .background(RemorrowStyle.canvas.ignoresSafeArea())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, icon: String, body: String) -> some View {
        RemorrowCard {
            VStack(alignment: .leading, spacing: 9) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(RemorrowStyle.violet)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(RemorrowStyle.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
