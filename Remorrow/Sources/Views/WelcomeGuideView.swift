import SwiftUI

struct WelcomeGuideView: View {
    let onFinish: () -> Void
    @State private var page = 0
    private var isBlueCover: Bool { page == 0 }
    private let headings = [
        "Make room for what matters.",
        "A screenshot is enough.",
        "Nothing is saved by surprise."
    ]
    private let descriptions = [
        "Keep the moments worth remembering. Remorrow helps turn the details you choose into a plan.",
        "Select a photo, take a picture, paste a message or share selected text. Your content stays on your iPhone.",
        "Check each suggested date and title. Only you can approve saving to Calendar or Reminders."
    ]
    private let symbols = ["bubble.left.and.text.bubble.right", "text.viewfinder", "calendar.badge.checkmark"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("remorrow", systemImage: "hourglass")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(isBlueCover ? .white : RemorrowStyle.primaryText)
                Spacer()
                Button("Skip") { onFinish() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isBlueCover ? .white.opacity(0.85) : RemorrowStyle.secondaryText)
                    .accessibilityIdentifier("welcomeSkip")
            }
            .padding(.top, 16)

            Spacer(minLength: 0)
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(isBlueCover ? Color.white.opacity(0.08) : RemorrowStyle.violet.opacity(0.09))
                    .frame(height: 240)
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isBlueCover ? Color.white.opacity(0.35) : RemorrowStyle.violet.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-9))
                Image(systemName: symbols[page])
                    .font(.system(size: 78, weight: .ultraLight))
                    .foregroundStyle(isBlueCover ? .white : RemorrowStyle.violet)
                    .contentTransition(.symbolEffect(.replace))
            }
            .accessibilityHidden(true)
            Text("0" + String(page + 1) + " / 03")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(isBlueCover ? .white.opacity(0.8) : RemorrowStyle.violet)
            Text(headings[page])
                .font(.system(size: 36, weight: .semibold, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(isBlueCover ? .white : RemorrowStyle.primaryText)
            Text(descriptions[page])
                .font(.body)
                .foregroundStyle(isBlueCover ? .white.opacity(0.8) : RemorrowStyle.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? (isBlueCover ? Color.white : RemorrowStyle.violet) : (isBlueCover ? Color.white.opacity(0.24) : RemorrowStyle.violet.opacity(0.18)))
                        .frame(width: i == page ? 26 : 8, height: 7)
                }
            }
            .accessibilityLabel("Step " + String(page + 1) + " of 3")
            Button {
                if page == 2 {
                    onFinish()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) { page += 1 }
                }
            } label: {
                HStack {
                    Spacer()
                    Text(page == 2 ? "Start remembering" : "Continue")
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .foregroundStyle(.white)
                .font(.subheadline.weight(.semibold))
                .frame(height: 54)
                .background(isBlueCover ? RemorrowStyle.primaryAction : RemorrowStyle.violet, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("welcomeContinue")
            .padding(.bottom, 20)
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity)
        .background {
            if isBlueCover {
                LinearGradient(colors: [RemorrowStyle.violet, RemorrowStyle.deepBlue],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            } else {
                RemorrowStyle.canvas.ignoresSafeArea()
            }
        }
    }
}

#Preview {
    WelcomeGuideView(onFinish: {})
}
