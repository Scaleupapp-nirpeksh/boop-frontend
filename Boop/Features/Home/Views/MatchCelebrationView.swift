import SwiftUI

struct MatchCelebrationView: View {
    let name: String
    let matchTier: String
    let score: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var showHearts = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Floating hearts
            if showHearts {
                FloatingHeartsView()
            }

            // Content
            VStack(spacing: BoopSpacing.xxl) {
                Spacer()

                // Two circles connecting (like logo)
                ZStack {
                    Circle()
                        .fill(BoopColors.primary.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .offset(x: showContent ? -20 : -60)

                    Circle()
                        .fill(BoopColors.secondary.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .offset(x: showContent ? 20 : 60)

                    // Heart at intersection
                    if showContent {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .scaleEffect(showContent ? 1.0 : 0.0)
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)

                VStack(spacing: BoopSpacing.sm) {
                    Text("It's a connection!")
                        .font(.nunito(.extraBold, size: 28))
                        .foregroundStyle(.white)

                    Text("You and \(name) both want to connect")
                        .font(BoopTypography.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    // Tier badge
                    HStack(spacing: BoopSpacing.xs) {
                        Text(tierEmoji)
                        Text(tierLabel)
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.xs)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .padding(.top, BoopSpacing.xs)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                VStack(spacing: BoopSpacing.sm) {
                    BoopButton(title: "Start Talking", variant: .primary) {
                        onDismiss()
                        // TODO: Navigate to chat
                    }

                    Button("Keep Discovering") {
                        onDismiss()
                    }
                    .font(BoopTypography.callout)
                    .foregroundStyle(.white.opacity(0.7))
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

    private var tierEmoji: String {
        switch matchTier {
        case "platinum": return "💎"
        case "gold": return "💛"
        case "silver": return "🤍"
        default: return "🧡"
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
                    Image(systemName: "heart.fill")
                        .font(.system(size: heart.size))
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
                color: [BoopColors.primary, BoopColors.secondary, BoopColors.accent].randomElement()!,
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
