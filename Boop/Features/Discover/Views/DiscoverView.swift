import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: BoopSpacing.lg) {
                    BoopSectionIntro(
                        title: "Discover",
                        subtitle: "Chemistry first. See who aligns with you today.",
                        eyebrow: "Daily connections"
                    )

                    if viewModel.candidatesRemaining > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(BoopColors.secondary)
                                .frame(width: 6, height: 6)
                            Text("\(viewModel.candidatesRemaining) left today")
                                .font(BoopTypography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(BoopColors.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [BoopColors.cardDark, BoopColors.cardDarkDiscover],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )

                        VStack(spacing: BoopSpacing.md) {
                            if viewModel.isLoading {
                                SkeletonCandidateCard()
                            } else if let error = viewModel.errorMessage {
                                VStack(spacing: BoopSpacing.md) {
                                    Image(systemName: "wifi.exclamationmark")
                                        .font(.system(size: 36))
                                        .foregroundStyle(BoopColors.error.opacity(0.6))
                                    Text(error)
                                        .font(BoopTypography.body)
                                        .foregroundStyle(BoopColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    BoopButton(title: "Try Again", variant: .secondary, fullWidth: false) {
                                        Task { await viewModel.loadCandidates() }
                                    }
                                }
                                .padding(.vertical, BoopSpacing.xl)
                            } else if let candidate = viewModel.currentCandidate {
                                CandidateCardView(
                                    candidate: candidate,
                                    onConnect: { Haptics.medium(); viewModel.openConnectSheet(for: candidate) },
                                    onSkip: { Haptics.light(); Task { await viewModel.passCurrentCandidate() } }
                                )
                                .id(candidate.userId)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            } else {
                                allCaughtUpView
                            }

                            if viewModel.candidates.count > 1 && viewModel.currentCandidateIndex < viewModel.candidates.count {
                                HStack(spacing: 6) {
                                    ForEach(0..<min(viewModel.candidates.count, 10), id: \.self) { i in
                                        Circle()
                                            .fill(i == viewModel.currentCandidateIndex ? BoopColors.primary : Color.white.opacity(0.18))
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                        }
                        .padding(BoopSpacing.md)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.lg)
            }
            .boopBackground()
            .refreshable {
                await viewModel.loadCandidates()
            }

            if viewModel.showMatchCelebration {
                MatchCelebrationView(
                    name: viewModel.celebrationName ?? "Someone",
                    matchTier: viewModel.celebrationMatch?.matchTier ?? "gold",
                    score: viewModel.celebrationMatch?.compatibilityScore ?? 0,
                    onDismiss: { viewModel.dismissCelebration() }
                )
                .transition(.opacity.combined(with: .scale))
            }
        }
        .task {
            await viewModel.loadCandidates()
        }
        .sheet(isPresented: $viewModel.showConnectSheet) {
            ConnectNoteSheet(viewModel: viewModel)
        }
    }

    private var allCaughtUpView: some View {
        BoopCard(padding: BoopSpacing.xl, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(BoopColors.primary.opacity(0.5))
                    .symbolEffect(.pulse, options: .repeating)

                Text("All caught up for now")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("You've seen today's queue. Check back tomorrow!")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BoopSpacing.xl)
    }
}
