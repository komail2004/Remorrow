import SwiftUI

enum RemorrowStyle {
    static let ink = Color(red: 0.13, green: 0.14, blue: 0.21)
    static let muted = Color(red: 0.43, green: 0.44, blue: 0.51)
    static let violet = Color(red: 0.39, green: 0.31, blue: 0.89)
    static let lilac = Color(red: 0.74, green: 0.66, blue: 0.99)
    static let mint = Color(red: 0.74, green: 0.91, blue: 0.83)
    static let canvas = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.08, blue: 0.13, alpha: 1)
            : UIColor(red: 0.97, green: 0.965, blue: 0.985, alpha: 1)
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
            .background(RemorrowStyle.surface, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .strokeBorder(RemorrowStyle.primaryText.opacity(0.045), lineWidth: 1)
            }
    }
}

struct SectionEyebrow: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(2.0)
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
