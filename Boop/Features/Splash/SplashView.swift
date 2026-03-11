import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    // Animation states
    @State private var leftCircle = false
    @State private var rightCircle = false
    @State private var heartScale = false
    @State private var heartBeat = false
    @State private var logoText = false
    @State private var tagline = false
    @State private var particlesVisible = false
    @State private var backgroundGlow = false
    @State private var fadeOut = false

    private let circleSize: CGFloat = 110
    private let overlap: CGFloat = 30

    var body: some View {
        ZStack {
            // Animated background
            backgroundLayer

            // Floating particles
            if particlesVisible {
                FloatingParticlesView()
                    .transition(.opacity)
            }

            // Main content
            VStack(spacing: 20) {
                Spacer()

                // Logo animation
                ZStack {
                    // Glow behind logo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [BoopColors.primary.opacity(0.2), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(backgroundGlow ? 1.2 : 0.8)
                        .opacity(backgroundGlow ? 1 : 0)

                    // Left circle
                    Circle()
                        .fill(BoopColors.primary)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: -(circleSize / 2 - overlap))
                        .scaleEffect(leftCircle ? 1 : 0)
                        .opacity(leftCircle ? 1 : 0)

                    // Right circle
                    Circle()
                        .fill(BoopColors.secondary)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: circleSize / 2 - overlap)
                        .scaleEffect(rightCircle ? 1 : 0)
                        .opacity(rightCircle ? 1 : 0)

                    // Blend overlay
                    Circle()
                        .fill(BoopColors.primary)
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: -(circleSize / 2 - overlap))
                        .blendMode(.multiply)
                        .opacity(leftCircle && rightCircle ? 1 : 0)

                    // Heart
                    HeartShape()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .scaleEffect(heartScale ? (heartBeat ? 1.15 : 1.0) : 0)
                        .opacity(heartScale ? 1 : 0)
                }
                .frame(width: 200, height: circleSize)

                // "boop" text
                Text("boop")
                    .font(.nunito(.extraBold, size: 48))
                    .foregroundStyle(BoopColors.primary)
                    .opacity(logoText ? 1 : 0)
                    .offset(y: logoText ? 0 : 15)

                // Tagline
                Text("personality before pixels")
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textSecondary)
                    .opacity(tagline ? 1 : 0)
                    .offset(y: tagline ? 0 : 10)

                Spacer()
                Spacer()
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .ignoresSafeArea()
        .onAppear { runAnimation() }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            BoopColors.background.ignoresSafeArea()

            // Soft gradient orbs
            Circle()
                .fill(BoopColors.primary.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -80, y: -200)
                .scaleEffect(backgroundGlow ? 1.1 : 0.9)

            Circle()
                .fill(BoopColors.secondary.opacity(0.06))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 100, y: 200)
                .scaleEffect(backgroundGlow ? 1.15 : 0.85)

            Circle()
                .fill(BoopColors.accent.opacity(0.05))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 80, y: -100)
                .scaleEffect(backgroundGlow ? 1.05 : 0.95)
        }
    }

    // MARK: - Animation sequence

    private func runAnimation() {
        // Background glow starts
        withAnimation(.easeInOut(duration: 2.0)) {
            backgroundGlow = true
        }

        // Left circle bounces in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
            leftCircle = true
        }

        // Right circle bounces in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
            rightCircle = true
        }

        // Heart pops in
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.9)) {
            heartScale = true
        }

        // Heart beat pulse
        withAnimation(.easeInOut(duration: 0.4).delay(1.3).repeatCount(2, autoreverses: true)) {
            heartBeat = true
        }

        // Logo text slides up
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
            logoText = true
        }

        // Tagline fades in
        withAnimation(.easeOut(duration: 0.6).delay(1.6)) {
            tagline = true
        }

        // Particles appear
        withAnimation(.easeIn(duration: 0.5).delay(1.4)) {
            particlesVisible = true
        }

        // Fade out and finish
        withAnimation(.easeInOut(duration: 0.5).delay(2.8)) {
            fadeOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            isFinished = true
        }
    }
}

// MARK: - Floating Particles

private struct FloatingParticlesView: View {
    @State private var animate = false

    private let particles: [(x: CGFloat, y: CGFloat, size: CGFloat, color: Color, delay: Double)] = [
        (-120, -250, 8, BoopColors.primary.opacity(0.3), 0),
        (140, -180, 6, BoopColors.secondary.opacity(0.3), 0.2),
        (-80, 220, 10, BoopColors.accent.opacity(0.4), 0.1),
        (100, 280, 7, BoopColors.primary.opacity(0.25), 0.3),
        (-150, 100, 5, BoopColors.secondary.opacity(0.35), 0.15),
        (160, -50, 9, BoopColors.accent.opacity(0.3), 0.25),
        (-30, 320, 6, BoopColors.primary.opacity(0.2), 0.35),
        (50, -300, 8, BoopColors.secondary.opacity(0.25), 0.05),
    ]

    var body: some View {
        ZStack {
            ForEach(0..<particles.count, id: \.self) { i in
                let p = particles[i]
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .offset(
                        x: p.x + (animate ? CGFloat.random(in: -15...15) : 0),
                        y: p.y + (animate ? -30 : 0)
                    )
                    .opacity(animate ? 0.8 : 0)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                        .delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
