import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    // Animation states (timing/navigation preserved)
    @State private var wordmark = false
    @State private var ruleReveal = false
    @State private var tagline = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            // Near-ground cinematic backdrop
            BoopColors.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Light-weight tracked wordmark
                Text("UnMutee")
                    .font(BoopTypography.cineDisplayXL)
                    .tracking(6)
                    .foregroundStyle(BoopColors.textPrimary)
                    .opacity(wordmark ? 1 : 0)
                    .offset(y: wordmark ? 0 : 10)

                // Quiet coral rule reveal
                AccentRule(width: ruleReveal ? 56 : 0)
                    .opacity(ruleReveal ? 1 : 0)
                    .padding(.top, BoopSpacing.lg)

                // Tagline
                Text("personality before pixels")
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

    // MARK: - Animation sequence (timings preserved)

    private func runAnimation() {
        // Wordmark settles in
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            wordmark = true
        }

        // Coral rule draws out
        withAnimation(.easeInOut(duration: 0.7).delay(0.9)) {
            ruleReveal = true
        }

        // Tagline fades in
        withAnimation(.easeOut(duration: 0.6).delay(1.6)) {
            tagline = true
        }

        // Fade out and finish (preserved timing)
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
