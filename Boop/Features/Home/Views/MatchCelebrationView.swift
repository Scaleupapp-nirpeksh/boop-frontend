import SwiftUI

struct MatchCelebrationView: View {
    let name: String
    let matchTier: String
    let score: Int
    let onStartTalking: () -> Void
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showHearts = false

    var body: some View {
        ZStack {
            // Near-ground backdrop
            BoopColors.ground.opacity(0.94)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Floating hearts
            if showHearts {
                FloatingHeartsView()
            }

            VStack(spacing: BoopSpacing.xxl) {
                Spacer()

                // Two circles connecting (the brand motif)
                ZStack {
                    Circle()
                        .stroke(BoopColors.accentColor, lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                        .offset(x: showContent ? -20 : -60)

                    Circle()
                        .stroke(BoopColors.textPrimary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                        .offset(x: showContent ? 20 : 60)

                    if showContent {
                        Image(systemName: "heart")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundStyle(BoopColors.accentColor)
                            .scaleEffect(showContent ? 1.0 : 0.0)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)

                VStack(spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "It's a Connection", color: BoopColors.accentColor)

                    Text(name)
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)
                        .multilineTextAlignment(.center)

                    AccentRule()
                        .padding(.vertical, BoopSpacing.xs)

                    Text("You and \(name) both want to connect")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .multilineTextAlignment(.center)

                    EyebrowLabel(text: tierLabel)
                        .padding(.top, BoopSpacing.xs)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                VStack(spacing: BoopSpacing.sm) {
                    BoopButton(title: "Start Talking", variant: .primary) {
                        onStartTalking()
                    }

                    Button("Keep Discovering") {
                        onDismiss()
                    }
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
                }
                .opacity(showContent ? 1 : 0)
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.bottom, BoopSpacing.xxl)
            }
        }
        .onAppear {
            Haptics.celebration()
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
                showHearts = true
            }
        }
    }

    private var tierLabel: String {
        switch matchTier {
        case "platinum": return "Platinum Match"
        case "gold": return "Gold Match"
        case "silver": return "Silver Match"
        default: return "A New Connection"
        }
    }
}

// MARK: - Floating Hearts Animation

struct FloatingHeartsView: View {
    @State private var hearts: [FloatingHeart] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(hearts) { heart in
                    Image(systemName: "heart")
                        .font(.system(size: heart.size, weight: .thin))
                        .foregroundStyle(heart.color)
                        .position(x: heart.x, y: heart.y)
                        .opacity(heart.opacity)
                }
            }
            .onAppear {
                generateHearts(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func generateHearts(in size: CGSize) {
        for i in 0..<12 {
            let delay = Double(i) * 0.15
            let heart = FloatingHeart(
                x: CGFloat.random(in: 40...(size.width - 40)),
                y: size.height + 20,
                size: CGFloat.random(in: 12...24),
                color: BoopColors.accentColor.opacity(Double.random(in: 0.4...0.9)),
                opacity: 1.0
            )
            hearts.append(heart)

            let index = hearts.count - 1
            withAnimation(.easeOut(duration: 2.0).delay(delay)) {
                hearts[index].y = CGFloat.random(in: 50...(size.height * 0.4))
                hearts[index].opacity = 0
            }
        }
    }
}

struct FloatingHeart: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}
