import SwiftUI

/// Design tokens for Tack. Inspired by PitWall's `PW` family — `TK` here.
///
/// Two appearances: dark (default) and light. Tokens are semantic, not literal.
/// Use these everywhere instead of hardcoded colors/spacing/font sizes.
public enum TK {
    public enum Radius {
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 10
        public static let md: CGFloat = 14
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 28
        public static let pill: CGFloat = 999
    }

    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    public enum Palette {
        // Surfaces (dark mode primary)
        public static let bgDeep = Color(red: 0.043, green: 0.055, blue: 0.071)        // #0B0E12
        public static let surface = Color(red: 0.078, green: 0.094, blue: 0.122)       // #14181F
        public static let surfaceHigh = Color(red: 0.110, green: 0.133, blue: 0.188)  // #1C2230
        public static let surfaceElevated = Color(red: 0.149, green: 0.180, blue: 0.255) // #262E41

        // Surfaces (light mode)
        public static let bgDeepLight = Color(red: 0.973, green: 0.973, blue: 0.980)  // #F8F8FA
        public static let surfaceLight = Color(red: 1.0, green: 1.0, blue: 1.0)       // #FFFFFF
        public static let surfaceHighLight = Color(red: 0.953, green: 0.957, blue: 0.969) // #F3F4F7

        // Text
        public static let textStrong = Color.primary
        public static let textMuted = Color.secondary
        public static let textTertiary = Color(white: 0.55)

        // Borders
        public static let border = Color.white.opacity(0.06)
        public static let borderStrong = Color.white.opacity(0.12)
        public static let borderLight = Color.black.opacity(0.06)
        public static let borderLightStrong = Color.black.opacity(0.12)

        // Brand
        public static let accent = Color(red: 0.357, green: 0.561, blue: 0.976)       // #5B8FF9
        public static let accentMuted = Color(red: 0.357, green: 0.561, blue: 0.976).opacity(0.18)
        public static let accentGlow = Color(red: 0.357, green: 0.561, blue: 0.976).opacity(0.45)

        // Semantic
        public static let success = Color(red: 0.290, green: 0.870, blue: 0.500)      // #4ADE80
        public static let warning = Color(red: 0.984, green: 0.749, blue: 0.141)      // #FBBF24
        public static let danger = Color(red: 0.973, green: 0.443, blue: 0.443)       // #F87171
        public static let info = Color(red: 0.357, green: 0.561, blue: 0.976)

        // Status (per task state)
        public static let statusOpen = accent
        public static let statusInProgress = warning
        public static let statusDone = success
        public static let statusCancelled = textTertiary
    }

    public enum Spring {
        // Animated.spring presets keyed to design feel.
        public static let snappy: Animation = .spring(response: 0.28, dampingFraction: 0.78)
        public static let gentle: Animation = .spring(response: 0.42, dampingFraction: 0.85)
        public static let bouncy: Animation = .spring(response: 0.45, dampingFraction: 0.62)
        public static let stiff: Animation = .spring(response: 0.22, dampingFraction: 0.88)
    }

    public enum Gradient {
        public static let hero = LinearGradient(
            colors: [Palette.accent.opacity(0.35), Palette.accent.opacity(0.0)],
            startPoint: .top, endPoint: .bottom
        )
        public static let sunburst = RadialGradient(
            colors: [Palette.accent.opacity(0.30), Palette.accent.opacity(0.0)],
            center: .topLeading, startRadius: 4, endRadius: 360
        )
    }
}

// MARK: - View modifiers

struct TKCardStyle: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: TK.Radius.md, style: .continuous)
                    .fill(elevated ? TK.Palette.surfaceElevated : TK.Palette.surfaceHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: TK.Radius.md, style: .continuous)
                            .stroke(TK.Palette.border, lineWidth: 0.5)
                    )
            }
    }
}

extension View {
    func tkCard(elevated: Bool = false) -> some View {
        modifier(TKCardStyle(elevated: elevated))
    }

    /// Soft entrance animation for list rows. Pair with `.tkAppear(index: 0)` etc.
    func tkAppear(index: Int, total: Int = 12) -> some View {
        let clamped = max(0, min(index, total - 1))
        let delay = Double(clamped) * 0.025
        return self
            .opacity(0)
            .offset(y: 8)
            .animation(TK.Spring.gentle.delay(delay), value: index)
            .onAppear {
                withAnimation(TK.Spring.gentle.delay(delay)) {
                    // Trigger redraw with full opacity
                }
            }
    }

    func tkHoverable() -> some View {
        #if os(macOS)
        return self.onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
        #else
        return self
        #endif
    }
}

#if os(macOS)
import AppKit
#endif
