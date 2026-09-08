import SwiftUI

/// Reusable empty / placeholder view. Premium treatment: radial-gradient glow
/// behind the icon, generous spacing, optional primary CTA.
struct EmptyStateView: View {
    let system: String
    let title: String
    let subtitle: String
    var tint: Color = TK.Palette.accent
    var action: (label: String, perform: () -> Void)? = nil

    init(system: String, title: String, subtitle: String) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
    }

    init(system: String, title: String, subtitle: String, tint: Color) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
    }

    init(system: String, title: String, subtitle: String, tint: Color = TK.Palette.accent, actionLabel: String, perform: @escaping () -> Void) {
        self.system = system
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.action = (actionLabel, perform)
    }

    var body: some View {
        VStack(spacing: TK.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.40), tint.opacity(0.0)],
                            center: .center, startRadius: 6, endRadius: 130
                        )
                    )
                    .frame(width: 220, height: 220)
                ZStack {
                    Circle()
                        .fill(TK.Palette.surfaceHigh)
                        .frame(width: 96, height: 96)
                    Image(systemName: system)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(tint)
                }
            }
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .frame(maxWidth: 340)
                .padding(.horizontal, TK.Spacing.lg)
            if let action {
                Button(action: { action.perform() }) {
                    Label(action.label, systemImage: "plus.circle.fill")
                        .font(.callout.weight(.semibold))
                        .padding(.horizontal, TK.Spacing.lg)
                        .padding(.vertical, TK.Spacing.sm + 2)
                        .background(Capsule().fill(tint))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.tkPress(tint: tint))
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
        subtitle: "Captures appear here as soon as you add them.",
        tint: TK.Palette.success,
        actionLabel: "Add a task"
    ) {}
    .background(TK.Palette.bgDeep)
    .preferredColorScheme(.dark)
}
