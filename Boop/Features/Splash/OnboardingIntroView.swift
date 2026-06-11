import SwiftUI

struct OnboardingIntroView: View {
    @Binding var isFinished: Bool
    @State private var currentPage = 0
    @State private var appeared = false

    private let pages: [IntroPage] = [
        IntroPage(
            eyebrow: "How it works",
            symbol: "waveform",
            title: "Personality before pixels",
            subtitle: "On UnMutee, photos stay blurred until you both feel ready. Your voice, your words, and who you really are come first."
        ),
        IntroPage(
            eyebrow: "No swiping",
            symbol: "circle.grid.cross",
            title: "Real connection, not a race",
            subtitle: "No swiping. Each day, we handpick a few people who truly match your personality. Play games, chat, and let chemistry build naturally."
        ),
    ]

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button {
                        withAnimation { isFinished = true }
                    } label: {
                        Text("SKIP")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textMuted)
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
                VStack(spacing: BoopSpacing.xl) {
                    // Hairline tick indicator — thin coral mark for current page
                    HStack(spacing: BoopSpacing.xs) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Rectangle()
                                .fill(index == currentPage ? BoopColors.accentColor : BoopColors.hairline)
                                .frame(width: index == currentPage ? 28 : 14, height: 2)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    BoopButton(
                        title: currentPage < pages.count - 1 ? "Continue" : "Let's go"
                    ) {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            withAnimation { isFinished = true }
                        }
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
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            // Quiet thin-stroke mark
            Image(systemName: page.symbol)
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(BoopColors.accentColor)

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: page.eyebrow)

                Text(page.title)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                AccentRule()

                Text(page.subtitle)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xxl)
    }
}

// MARK: - Model

private struct IntroPage {
    let eyebrow: String
    let symbol: String
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingIntroView(isFinished: .constant(false))
}
