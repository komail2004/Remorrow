import SwiftUI

enum RemorrowStyle {
    static let ink = Color(red: 0.16, green: 0.21, blue: 0.21)
    static let muted = Color(red: 0.43, green: 0.46, blue: 0.45)
    static let violet = Color(red: 0.20, green: 0.35, blue: 0.33)
    static let lilac = Color(red: 0.87, green: 0.75, blue: 0.65)
    static let mint = Color(red: 0.75, green: 0.85, blue: 0.78)
    static let canvas = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.11, blue: 0.11, alpha: 1)
            : UIColor(red: 0.974, green: 0.97, blue: 0.956, alpha: 1)
    })
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let primaryText = Color(uiColor: .label)
    static let secondaryText = Color(uiColor: .secondaryLabel)
}

struct RemorrowCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(RemorrowStyle.primaryText.opacity(0.045), lineWidth: 1)
            }
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
            .background(RemorrowStyle.violet, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}
