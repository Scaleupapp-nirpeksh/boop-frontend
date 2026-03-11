import SwiftUI

struct OnboardingIntroView: View {
    @Binding var isFinished: Bool
    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [IntroPage] = [
        IntroPage(
            icon: "waveform.circle.fill",
            iconColor: BoopColors.secondary,
            title: "Personality before pixels",
            subtitle: "On Boop, photos stay blurred until you both feel ready. Your voice, your words, and who you really are come first.",
            illustrationColors: (BoopColors.secondary, BoopColors.primary)
        ),
        IntroPage(
            icon: "heart.circle.fill",
            iconColor: BoopColors.primary,
            title: "Real connection, not a race",
            subtitle: "No swiping. Each day, we handpick a few people who truly match your personality. Play games, chat, and let chemistry build naturally.",
            illustrationColors: (BoopColors.primary, BoopColors.accent)
        ),
    ]

    var body: some View {
        ZStack {
            BoopColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isFinished = true }
                    } label: {
                        Text("Skip")
                            .font(BoopTypography.callout)
                            .foregroundStyle(BoopColors.textSecondary)
                            .padding(.horizontal, BoopSpacing.md)
                            .padding(.vertical, BoopSpacing.xs)
                    }
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.top, BoopSpacing.xs)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        introPageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Bottom section
                VStack(spacing: BoopSpacing.lg) {
                    // Page dots
                    HStack(spacing: BoopSpacing.xs) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? BoopColors.primary : BoopColors.border)
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            withAnimation { isFinished = true }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Let's go")
                            .font(BoopTypography.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .foregroundStyle(.white)
                            .background(BoopColors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                            .shadow(color: BoopColors.primary.opacity(0.24), radius: 14, x: 0, y: 8)
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                }
                .padding(.bottom, BoopSpacing.huge)
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    // MARK: - Page View

    @ViewBuilder
    private func introPageView(_ page: IntroPage) -> some View {
        VStack(spacing: BoopSpacing.xxl) {
            Spacer()

            // Illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(page.illustrationColors.0.opacity(0.08))
                    .frame(width: 260, height: 260)

                Circle()
                    .fill(page.illustrationColors.1.opacity(0.06))
                    .frame(width: 200, height: 200)
                    .offset(x: 30, y: -20)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.illustrationColors.0, page.illustrationColors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))

                // Decorative small circles
                Circle()
                    .fill(page.illustrationColors.0.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .offset(x: -100, y: -60)

                Circle()
                    .fill(page.illustrationColors.1.opacity(0.25))
                    .frame(width: 8, height: 8)
                    .offset(x: 110, y: 40)

                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 16, height: 16)
                    .offset(x: -70, y: 80)

                Circle()
                    .fill(BoopColors.accent.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .offset(x: 90, y: -80)
            }
            .frame(height: 280)

            // Text
            VStack(spacing: BoopSpacing.md) {
                Text(page.title)
                    .font(BoopTypography.title1)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, BoopSpacing.xxl)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Model

private struct IntroPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let illustrationColors: (Color, Color)
}

#Preview {
    OnboardingIntroView(isFinished: .constant(false))
}
