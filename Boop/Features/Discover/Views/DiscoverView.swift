import SwiftUI

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    header

                    if AuthManager.shared.currentUser?.profileStage == .preview {
                        setupBanner
                    }

                    Group {
                        if viewModel.isLoading {
                            SkeletonCandidateCard()
                                .boopCard(radius: BoopRadius.xxl)
                        } else if let error = viewModel.errorMessage {
                            errorView(error)
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
                    }

                    if viewModel.candidates.count > 1 && viewModel.currentCandidateIndex < viewModel.candidates.count {
                        queueProgress
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
                    onStartTalking: {
                        let matchId = viewModel.celebrationMatch?.matchId
                        viewModel.dismissCelebration()
                        if let matchId { NotificationRouter.shared.openChat(matchId: matchId) }
                    },
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
        .sheet(isPresented: $viewModel.showConnectSetup) {
            ConnectSetupView {
                Task { await viewModel.completeSetupAndRetry() }
            }
        }
    }

    // MARK: - Setup banner (preview users — hairline prompt to unlock connecting)

    private var setupBanner: some View {
        Button {
            Haptics.light()
            viewModel.openConnectSetup()
        } label: {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
                HStack(spacing: BoopSpacing.sm) {
                    Text("Add your voice + photos to start connecting")
                        .font(BoopTypography.cineCaption)
                        .tracking(0.5)
                        .foregroundStyle(BoopColors.textSecondary)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(BoopColors.accentColor)
                }
                .padding(.vertical, BoopSpacing.sm)
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header (eyebrow + daily count)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                EyebrowLabel(text: "Discover", color: BoopColors.textMuted)
                AccentRule()
            }

            Spacer()

            if viewModel.candidatesRemaining > 0 {
                Text("\(viewModel.candidatesRemaining) TODAY")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }

    // MARK: - Queue progress (hairline ticks)

    private var queueProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(viewModel.candidates.count, 10), id: \.self) { i in
                Rectangle()
                    .fill(i == viewModel.currentCandidateIndex ? BoopColors.accentColor : BoopColors.hairline)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error

    private func errorView(_ error: String) -> some View {
        VStack(spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Connection lost", color: BoopColors.textMuted)
            Text(error)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
            BoopButton(title: "Try Again", variant: .secondary, fullWidth: false) {
                Task { await viewModel.loadCandidates() }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BoopSpacing.huge)
        .padding(.horizontal, BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xxl)
    }

    // MARK: - Empty

    private var allCaughtUpView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "All caught up", color: BoopColors.textMuted)
            AccentRule()
            Text("You've seen today's queue")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
            Text("New people align with you each day. Check back tomorrow.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.xl)
        .boopCard(radius: BoopRadius.xxl)
    }
}
