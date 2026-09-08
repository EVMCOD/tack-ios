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
        public static let xxl: CGFloat = 36
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
        public static let surfaceLiquid = Color(red: 0.067, green: 0.082, blue: 0.114)

        // Surfaces (light mode)
        public static let bgDeepLight = Color(red: 0.973, green: 0.973, blue: 0.980)
        public static let surfaceLight = Color(red: 1.0, green: 1.0, blue: 1.0)
        public static let surfaceHighLight = Color(red: 0.953, green: 0.957, blue: 0.969)

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
        public static let accentDeep = Color(red: 0.255, green: 0.412, blue: 0.835)    // #4169D5
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

        // Streak / gamification
        public static let streak = Color(red: 0.984, green: 0.412, blue: 0.310)       // #FB6950
        public static let streakMuted = Color(red: 0.984, green: 0.412, blue: 0.310).opacity(0.18)
        public static let gold = Color(red: 0.961, green: 0.745, blue: 0.255)         // #F5BE41

        // Integrations
        public static let notion = Color(red: 0.45, green: 0.45, blue: 0.50)
        public static let obsidian = Color(red: 0.42, green: 0.31, blue: 0.71)
    }

    public enum Spring {
        public static let snappy: Animation = .spring(response: 0.28, dampingFraction: 0.78)
        public static let gentle: Animation = .spring(response: 0.42, dampingFraction: 0.85)
        public static let bouncy: Animation = .spring(response: 0.45, dampingFraction: 0.62)
        public static let stiff: Animation = .spring(response: 0.22, dampingFraction: 0.88)
        public static let hero: Animation = .spring(response: 0.6, dampingFraction: 0.7)
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
        public static let streak = LinearGradient(
            colors: [Palette.streak, Palette.warning],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        public static let success = LinearGradient(
            colors: [Palette.success, Palette.success.opacity(0.6)],
            startPoint: .top, endPoint: .bottom
        )
        public static let mesh = AngularGradient(
            colors: [Palette.accent, Palette.streak, Palette.gold, Palette.accent],
            center: .center
        )
    }

    public enum Icon {
        public static let inbox      = "tray.fill"
        public static let today      = "sun.max.fill"
        public static let done       = "checkmark.seal.fill"
        public static let add        = "plus.circle.fill"
        public static let addBold    = "plus"
        public static let search     = "magnifyingglass"
        public static let tag        = "tag.fill"
        public static let date       = "calendar"
        public static let notion     = "doc.text.fill"
        public static let obsidian   = "diamond.fill"
        public static let streak     = "flame.fill"
        public static let stats      = "chart.bar.fill"
        public static let lists      = "list.bullet.rectangle"
        public static let settings   = "gearshape.fill"
        public static let grid       = "square.grid.2x2"
        public static let back       = "chevron.left"
        public static let filter     = "line.3.horizontal.decrease.circle"
        public static let sort       = "arrow.up.arrow.down"
    }

    public enum Typography {
        public static let heroTitle:    Font = .system(size: 34, weight: .bold, design: .rounded)
        public static let heroSubtitle: Font = .system(size: 17, weight: .regular)
        public static let cardTitle:    Font = .system(size: 17, weight: .semibold)
        public static let cardBody:     Font = .system(size: 15)
        public static let sectionHead:  Font = .system(size: 13, weight: .semibold)
        public static let caption:      Font = .system(size: 13)
        public static let micro:        Font = .system(size: 11)
        public static let metric:       Font = .system(size: 36, weight: .bold, design: .rounded)
        public static let metricLg:     Font = .system(size: 48, weight: .bold, design: .rounded)
        public static let mono:         Font = .system(size: 13, weight: .medium, design: .monospaced)
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

struct TKGlassStyle: ViewModifier {
    var tint: Color = TK.Palette.accent
    var radius: CGFloat = TK.Radius.lg
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(tint.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(tint.opacity(0.30), lineWidth: 0.5)
                    )
            }
    }
}

struct TKHeroStyle: ViewModifier {
    var accent: Color = TK.Palette.accent
    func body(content: Content) -> some View {
        content
            .background {
                LinearGradient(
                    colors: [accent.opacity(0.30), accent.opacity(0.10), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .overlay(
                    RadialGradient(
                        colors: [accent.opacity(0.4), .clear],
                        center: .topTrailing, startRadius: 4, endRadius: 320
                    )
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: TK.Radius.xl, style: .continuous)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
            )
    }
}

struct TKAppearStyle: ViewModifier {
    @State private var appeared: Bool = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .onAppear {
                withAnimation(TK.Spring.gentle.delay(delay)) {
                    appeared = true
                }
            }
    }
}

extension View {
    func tkCard(elevated: Bool = false) -> some View {
        modifier(TKCardStyle(elevated: elevated))
    }

    func tkGlass(tint: Color = TK.Palette.accent, radius: CGFloat = TK.Radius.lg) -> some View {
        modifier(TKGlassStyle(tint: tint, radius: radius))
    }

    func tkHero(accent: Color = TK.Palette.accent) -> some View {
        modifier(TKHeroStyle(accent: accent))
    }

    /// Soft entrance animation for list rows. Pair with `.tkAppear(index: 0)` etc.
    func tkAppear(index: Int, total: Int = 12) -> some View {
        let clamped = max(0, min(index, total - 1))
        let delay = Double(clamped) * 0.040
        return modifier(TKAppearStyle(delay: delay))
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

// MARK: - Press button style (lifts + glow on press)

struct TKPressStyle: ButtonStyle {
    var tint: Color = TK.Palette.accent
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: tint.opacity(configuration.isPressed ? 0.3 : 0.15),
                    radius: configuration.isPressed ? 8 : 14, x: 0, y: configuration.isPressed ? 4 : 8)
            .animation(TK.Spring.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TKPressStyle {
    static var tkPress: TKPressStyle { TKPressStyle() }
    static func tkPress(tint: Color) -> TKPressStyle { TKPressStyle(tint: tint) }
}

#if os(macOS)
import AppKit
#endif
