import SwiftUI

/// Reusable empty / placeholder view. Used in Today, Inbox, Search, etc.
struct EmptyStateView: View {
    let system: String
    let title: String
    let subtitle: String
    var action: (label: String, perform: () -> Void)? = nil

    init(system: String, title: String, subtitle: String) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
    }

    init(system: String, title: String, subtitle: String, actionLabel: String, perform: @escaping () -> Void) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.action = (actionLabel, perform)
    }

    var body: some View {
        VStack(spacing: TK.Spacing.md) {
            ZStack {
                Circle()
                    .fill(TK.Palette.accentMuted)
                    .frame(width: 88, height: 88)
                Image(systemName: system)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(TK.Palette.accent)
            }
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(TK.Palette.textStrong)
            Text(subtitle)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .frame(maxWidth: 320)
                .padding(.horizontal, TK.Spacing.lg)
            if let action {
                Button(action: { action.perform() }) {
                    Text(action.label)
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, TK.Spacing.lg)
                        .padding(.vertical, TK.Spacing.sm)
                        .background(
                            Capsule().fill(TK.Palette.accent)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.tkPress)
                .padding(.top, TK.Spacing.xs)
            }
        }
        .padding(.vertical, TK.Spacing.xxl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        system: "checkmark.seal.fill",
        title: "Inbox is empty",
        subtitle: "Captures appear here as soon as you add them."
    )
    .background(TK.Palette.bgDeep)
    .preferredColorScheme(.dark)
}
