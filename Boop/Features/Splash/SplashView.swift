import SwiftUI

/// "The Merge" — two outlined circles (two people, two colours) slide together;
/// where they meet, a new soothing colour is born through shades. Then the wordmark.
/// Mirrors the app icon, adapts to light/dark via tokens.
struct SplashView: View {
    @Binding var isFinished: Bool
    @Environment(\.colorScheme) private var colorScheme

    // Merge choreography
    @State private var merged = false        // circles slide together
    @State private var strokesDim = false    // outlines soften at full merge
    @State private var bloomStage = 0        // 0 none, 1 warm shade, 2 mauve, 3 lavender gradient
    // Wordmark
    @State private var wordmark = false
    @State private var ruleReveal = false
    @State private var tagline = false
    @State private var fadeOut = false

    // Palette (deeper in light mode, luminous in dark — matches the icon variants)
    private var leftStroke: Color {
        colorScheme == .dark ? Color(red: 1.0, green: 0.30, blue: 0.43) : Color(red: 0.88, green: 0.23, blue: 0.35)
    }
    private var rightStroke: Color {
        colorScheme == .dark ? Color(red: 0.50, green: 0.66, blue: 0.94) : Color(red: 0.36, green: 0.51, blue: 0.84)
    }
    private var shadeWarm: Color {
        colorScheme == .dark ? Color(red: 0.94, green: 0.66, blue: 0.71) : Color(red: 0.91, green: 0.56, blue: 0.62)
    }
    private var shadeMauve: Color {
        colorScheme == .dark ? Color(red: 0.85, green: 0.68, blue: 0.90) : Color(red: 0.78, green: 0.60, blue: 0.85)
    }
    private var lavender: Color {
        colorScheme == .dark ? Color(red: 0.79, green: 0.72, blue: 0.94) : Color(red: 0.73, green: 0.65, blue: 0.91)
    }
    private var lavenderCool: Color {
        colorScheme == .dark ? Color(red: 0.66, green: 0.74, blue: 0.94) : Color(red: 0.56, green: 0.65, blue: 0.88)
    }

    private let circleSize: CGFloat = 120
    private let apart: CGFloat = 42   // half-distance between centers in the Venn state

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // The merge
                ZStack {
                    // The new colour, born through shades at full merge
                    Circle()
                        .fill(bloomFill)
                        .frame(width: circleSize, height: circleSize)
                        .scaleEffect(bloomStage > 0 ? 1 : 0.72)
                        .opacity(bloomStage > 0 ? 1 : 0)

                    // Lens: the new colour already showing where the circles overlap
                    Circle()
                        .fill(LinearGradient(colors: [shadeWarm, lavender, lavenderCool],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: merged ? 0 : apart)
                        .mask(
                            Circle()
                                .frame(width: circleSize, height: circleSize)
                                .offset(x: merged ? 0 : -apart)
                        )
                        .opacity(bloomStage > 0 ? 0 : 1)

                    // Two people, two colours — visible outlines
                    Circle()
                        .stroke(leftStroke, lineWidth: 2.5)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: merged ? 0 : -apart)
                        .opacity(strokesDim ? 0.18 : 1)
                    Circle()
                        .stroke(rightStroke, lineWidth: 2.5)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: merged ? 0 : apart)
                        .opacity(strokesDim ? 0.18 : 1)
                }
                .frame(height: 140)

                // Wordmark in the app's own type
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

    /// The bloom passes through shades — warm, then mauve, then settles
    /// into the lavender gradient (the new colour, gradiently taking shades).
    private var bloomFill: AnyShapeStyle {
        switch bloomStage {
        case 1: return AnyShapeStyle(shadeWarm)
        case 2: return AnyShapeStyle(shadeMauve)
        default:
            return AnyShapeStyle(LinearGradient(colors: [shadeWarm, lavender, lavenderCool],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    // MARK: - Choreography (overall fade/finish timings preserved: 2.8s fade, 3.3s finish)

    private func runAnimation() {
        // 1. Hold the Venn a beat, then the circles slide into each other
        withAnimation(.easeInOut(duration: 0.7).delay(0.45)) {
            merged = true
        }
        // 2. At full merge the outlines soften and the new colour blooms…
        withAnimation(.easeInOut(duration: 0.35).delay(1.05)) {
            strokesDim = true
            bloomStage = 1
        }
        // …gradiently taking shades: warm → mauve → lavender gradient
        withAnimation(.easeInOut(duration: 0.3).delay(1.35)) { bloomStage = 2 }
        withAnimation(.easeInOut(duration: 0.45).delay(1.6)) { bloomStage = 3 }

        // 3. Wordmark settles in, rule draws, tagline fades
        withAnimation(.easeOut(duration: 0.7).delay(1.3)) {
            wordmark = true
        }
        withAnimation(.easeInOut(duration: 0.6).delay(1.8)) {
            ruleReveal = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(2.2)) {
            tagline = true
        }

        // 4. Fade out and finish (preserved timing)
        withAnimation(.easeInOut(duration: 0.5).delay(2.8)) {
            fadeOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            isFinished = true
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
