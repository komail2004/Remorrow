import SwiftUI

enum RemorrowStyle {
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.15)
    static let muted = Color(red: 0.45, green: 0.48, blue: 0.53)
    static let violet = Color(red: 0.01, green: 0.38, blue: 0.65)
    static let lilac = Color(red: 0.52, green: 0.75, blue: 0.93)
    static let mint = Color(red: 0.84, green: 0.92, blue: 0.98)
    static let deepBlue = Color(red: 0.0, green: 0.16, blue: 0.37)
    static let blueTint = Color(red: 0.89, green: 0.94, blue: 0.99)
    static let canvas = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1)
            : UIColor(red: 0.974, green: 0.980, blue: 0.990, alpha: 1)
    })
    static let surface = Color(uiColor: .systemBackground)
    static let primaryAction = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
}

struct RemorrowCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(RemorrowStyle.primaryText.opacity(0.035), lineWidth: 1)
            }
            .shadow(color: RemorrowStyle.ink.opacity(0.065), radius: 17, x: 0, y: 7)
    }
}

struct SectionEyebrow: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .default))
            .tracking(1.25)
            .foregroundStyle(RemorrowStyle.secondaryText)
    }
}

struct RemorrowPrimaryButton: View {
    let title: String
    let systemImage: String
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Spacer()
                if isBusy {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Spacer()
            }
            .foregroundStyle(.white)
            .frame(minHeight: 54)
            .background(RemorrowStyle.primaryAction, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}
