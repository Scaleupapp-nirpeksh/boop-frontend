import SwiftUI

/// "The Merge" — two luminous orbs (two people, two colours) drift together until
/// they overlap, and in the overlap a new colour blooms: something new, together.
/// Then the wordmark settles in. Mirrors the app icon; adapts light/dark via tokens
/// with deliberate contrast tuning (deep-plum ground + white bloom in dark; cream
/// ground + deepened orbs + lavender bloom + a seating halo in light).
struct SplashView: View {
    @Binding var isFinished: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Choreography
    @State private var merged = false      // orbs drift from apart -> resting overlap
    @State private var bloom = false       // the new colour blooms in the overlap
    @State private var wordmark = false
    @State private var ruleReveal = false
    @State private var tagline = false
    @State private var fadeOut = false

    // Geometry
    private let orb: CGFloat = 132
    private var radius: CGFloat { orb / 2 }
    private let restGap: CGFloat = 34      // half-distance at rest (partial overlap = the logo)
    private let startGap: CGFloat = 92     // half-distance apart at the start

    private var gap: CGFloat { merged ? restGap : startGap }

    // MARK: Palette (contrast-tuned per scheme — matches the icon variants)
    private var coral: [Color] {
        colorScheme == .dark
            ? [Color(hex: "FFB07A"), Color(hex: "FF5C72"), Color(hex: "D7335F")]
            : [Color(hex: "FF8A6B"), Color(hex: "EE3D62"), Color(hex: "C2185B")]
    }
    private var peri: [Color] {
        colorScheme == .dark
            ? [Color(hex: "9DB6FF"), Color(hex: "6E84E6"), Color(hex: "4E5FC9")]
            : [Color(hex: "7E96F0"), Color(hex: "4F63D2"), Color(hex: "33409E")]
    }
    private var lens: [Color] {
        colorScheme == .dark
            ? [Color.white, Color(hex: "F0D2F2"), Color(hex: "C9A7EA")]
            : [Color(hex: "F3E4FB"), Color(hex: "D9B8EE"), Color(hex: "B07FD8")]
    }
    private var bloomCore: Color {
        colorScheme == .dark ? .white : Color(hex: "C9A7EA")
    }
    private var orbOpacity: Double { colorScheme == .dark ? 0.92 : 0.97 }
    private var glowOpacity: Double { colorScheme == .dark ? 0.55 : 0.30 }

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Seating halo — gives the mark depth on the cream light ground
                    if colorScheme == .light {
                        Ellipse()
                            .fill(Color(hex: "C98E86"))
                            .frame(width: orb * 2.4, height: orb * 2.1)
                            .opacity(merged ? 0.16 : 0)
                            .blur(radius: 46)
                    }

                    // Soft glow behind each orb
                    orbCircle(coral).offset(x: -gap).blur(radius: 26).opacity(glowOpacity)
                    orbCircle(peri).offset(x: gap).blur(radius: 26).opacity(glowOpacity)

                    // The two people, two colours
                    orbCircle(coral).offset(x: -gap).opacity(orbOpacity)
                    orbCircle(peri).offset(x: gap).opacity(orbOpacity)

                    // The new colour, showing only where they overlap
                    orbCircle(lens)
                        .offset(x: gap)
                        .mask(Circle().frame(width: orb, height: orb).offset(x: -gap))
                        .opacity(merged ? 0.96 : 0)

                    // The bloom — the new colour born in the overlap
                    Circle()
                        .fill(bloomCore)
                        .frame(width: orb * 0.62, height: orb * 0.62)
                        .blur(radius: 26)
                        .scaleEffect(bloom ? 1 : 0.5)
                        .opacity(bloom ? (colorScheme == .dark ? 0.55 : 0.5) : 0)
                }
                .frame(height: orb * 1.6)

                Text("UnMutee")
                    .font(BoopTypography.cineDisplayXL)
                    .tracking(wordmark ? 6 : 12)
                    .foregroundStyle(BoopColors.textPrimary)
                    .opacity(wordmark ? 1 : 0)
                    .padding(.top, BoopSpacing.xl)

                AccentRule(width: ruleReveal ? 56 : 0)
                    .opacity(ruleReveal ? 1 : 0)
                    .padding(.top, BoopSpacing.lg)

                Text("something new, together")
                    .font(BoopTypography.cineCaption)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
                    .opacity(tagline ? 1 : 0)
                    .padding(.top, BoopSpacing.md)

                Spacer()
                Spacer()
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .ignoresSafeArea()
        .onAppear { runAnimation() }
    }

    private func orbCircle(_ colors: [Color]) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: colors,
                    center: UnitPoint(x: 0.42, y: 0.38),
                    startRadius: 2,
                    endRadius: radius
                )
            )
            .frame(width: orb, height: orb)
    }

    // MARK: - Choreography (overall ~3.8s, preserved)
    private func runAnimation() {
        // 1. Orbs drift together into the resting overlap (the logo lockup)
        withAnimation(.spring(response: 0.9, dampingFraction: 0.78).delay(0.4)) {
            merged = true
        }
        // 2. The new colour blooms in the overlap
        withAnimation(.easeInOut(duration: 0.7).delay(1.15)) {
            bloom = true
        }
        // 3. Wordmark settles, rule draws, tagline fades in
        withAnimation(.easeOut(duration: 0.7).delay(1.4)) { wordmark = true }
        withAnimation(.easeInOut(duration: 0.6).delay(1.95)) { ruleReveal = true }
        withAnimation(.easeOut(duration: 0.5).delay(2.35)) { tagline = true }
        // 4. Hold, then fade out and finish
        withAnimation(.easeInOut(duration: 0.5).delay(3.3)) { fadeOut = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) { isFinished = true }
    }
}

#Preview("Dark") {
    SplashView(isFinished: .constant(false))
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    SplashView(isFinished: .constant(false))
        .preferredColorScheme(.light)
}
