import SwiftUI

/// First-launch flow. Three slides: capture / organize / sync. Skipped after a
/// single tap-through or via a "Get started" CTA on slide 3.
struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var page = 0

    private let slides: [Slide] = [
        .init(
            system: "plus.circle.fill",
            tint: .blue,
            title: "Capture fast",
            subtitle: "Quick Add is one tap away. Type it now, sort it later.",
            cta: "Continue"
        ),
        .init(
            system: "square.grid.2x2.fill",
            tint: .orange,
            title: "Today. Inbox. Lists.",
            subtitle: "Three views, zero friction. Tasks naturally find their home.",
            cta: "Continue"
        ),
        .init(
            system: "arrow.triangle.2.circlepath",
            tint: .indigo,
            title: "Sync with Obsidian",
            subtitle: "Pick your Obsidian vault. Tack keeps each task as a clean markdown file with YAML frontmatter, so other tools can read them too.",
            cta: "Get started"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            TabView(selection: $page) {
                ForEach(0..<slides.count, id: \.self) { idx in
                    slideView(slides[idx])
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            // macOS: stacked carousel — prev / current / next with paging buttons.
            HStack(spacing: TK.Spacing.lg) {
                Button {
                    withAnimation(TK.Spring.snappy) { page = max(0, page - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(TK.Palette.surfaceHigh))
                        .foregroundStyle(TK.Palette.textStrong)
                }
                .buttonStyle(.plain)
                .disabled(page == 0)
                .opacity(page == 0 ? 0.3 : 1)

                slideView(slides[page])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button {
                    withAnimation(TK.Spring.snappy) { page = min(slides.count - 1, page + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(slides[page].tint))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(page == slides.count - 1)
            }
            .padding(.horizontal, TK.Spacing.xl)
            #endif

            pageDots
                .padding(.vertical, TK.Spacing.md)

            Button(action: advance) {
                Text(slides[page].cta)
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, TK.Spacing.sm + 2)
                    .background(
                        Capsule().fill(slides[page].tint)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.tkPress(tint: slides[page].tint))
            .padding(.horizontal, TK.Spacing.xl)
            .padding(.bottom, TK.Spacing.xl)
        }
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }

    private func slideView(_ s: Slide) -> some View {
        VStack(spacing: TK.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(s.tint.opacity(0.18))
                    .frame(width: 140, height: 140)
                Image(systemName: s.system)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(s.tint)
            }
            Text(s.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
                .multilineTextAlignment(.center)
            Text(s.subtitle)
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            Spacer()
        }
        .padding(.horizontal, TK.Spacing.lg)
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<slides.count, id: \.self) { idx in
                Circle()
                    .fill(idx == page ? slides[page].tint : TK.Palette.border)
                    .frame(width: 6, height: 6)
            }
        }
    }

    private func advance() {
        if page < slides.count - 1 {
            withAnimation(TK.Spring.snappy) { page += 1 }
        } else {
            onComplete()
        }
    }

    private struct Slide {
        let system: String
        let tint: Color
        let title: String
        let subtitle: String
        let cta: String
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
