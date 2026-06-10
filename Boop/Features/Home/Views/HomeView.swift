import SwiftUI

struct NotificationRoute: Hashable {}

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var notificationVM = NotificationInboxViewModel()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: BoopSpacing.xl) {
                    greetingHeader

                    if let hero = heroMatch {
                        NavigationLink {
                            MatchDetailView(matchId: hero.matchId)
                        } label: {
                            MomentHeroCard(match: hero)
                                .padding(.horizontal, BoopSpacing.xl)
                        }
                        .buttonStyle(.plain)
                    }

                    if !viewModel.activeMatches.isEmpty {
                        YourPeopleRow(matches: viewModel.activeMatches)
                    }

                    DailyQuestionBand(newCount: viewModel.newQuestionsCount) {
                        viewModel.showQuestionsSheet = true
                    }

                    if !viewModel.incomingPendingLikes.isEmpty || !viewModel.outgoingPendingLikes.isEmpty {
                        activitySection
                    } else if viewModel.activeMatches.isEmpty {
                        emptyDiscoverPrompt
                    }
                }
                .padding(.vertical, BoopSpacing.lg)
            }
            .refreshable { await viewModel.refresh() }

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
            await viewModel.loadHome()
            await notificationVM.refreshUnreadCount()
        }
        .boopBackground()
        .sheet(isPresented: $viewModel.showQuestionsSheet) {
            NavigationStack {
                QuestionsFullView()
                    .navigationTitle("Today's Questions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.showQuestionsSheet = false }
                        }
                    }
            }
            .onDisappear {
                Task { await viewModel.refresh() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchNew)) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchStageChanged)) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchRevealed)) { _ in
            Task { await viewModel.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("boop.blockedUser"))) { _ in
            Task { await viewModel.refresh() }
        }
    }

    // MARK: - Greeting Header

    /// The connection closest to the reveal — the hero of the feed.
    private var heroMatch: MatchInfo? {
        viewModel.activeMatches.max(by: { ($0.comfortScore ?? 0) < ($1.comfortScore ?? 0) })
    }

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("good evening")
                    .font(.nunito(.medium, size: 13))
                    .foregroundStyle(BoopColors.textSecondary)
                Text(AuthManager.shared.currentUser?.firstName ?? "you")
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(BoopColors.textPrimary)
            }
            Spacer()
            if let streak = topStreak, streak > 0 {
                Text("🔥 \(streak)")
                    .font(.nunito(.bold, size: 13))
                    .foregroundStyle(BoopColors.brand)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, 6)
                    .background(BoopColors.backgroundBlush)
                    .clipShape(Capsule())
            }
            NavigationLink(value: NotificationRoute()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(BoopColors.surface)
                        .clipShape(Circle())
                    if notificationVM.unreadCount > 0 {
                        Text(notificationVM.unreadCount > 99 ? "99+" : "\(notificationVM.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(BoopColors.brand)
                            .clipShape(Capsule())
                            .offset(x: 4, y: -2)
                    }
                }
            }
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, BoopSpacing.xl)
    }

    private var topStreak: Int? {
        viewModel.activeMatches.compactMap { $0.streak?.current }.max()
    }

    private var emptyDiscoverPrompt: some View {
        VStack(spacing: BoopSpacing.sm) {
            Text("✨").font(.system(size: 36))
            Text("Find your first connection")
                .font(.nunito(.bold, size: 16))
                .foregroundStyle(BoopColors.textPrimary)
            Text("Head to Discover to meet someone whose answers match yours.")
                .font(.nunito(.regular, size: 13))
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BoopSpacing.xl)
        .boopCard(radius: BoopRadius.xxl)
        .padding(.horizontal, BoopSpacing.xl)
    }

    // MARK: - Activity (incoming + outgoing pending likes, compact)

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Activity")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)
                .padding(.horizontal, BoopSpacing.xl)

            if !viewModel.incomingPendingLikes.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(BoopColors.primary)
                            .frame(width: 8, height: 8)
                        Text("Liked You")
                            .font(BoopTypography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text("\(viewModel.incomingPendingLikes.count)")
                            .font(BoopTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(BoopColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BoopColors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, BoopSpacing.xl)

                    VStack(spacing: 1) {
                        ForEach(viewModel.incomingPendingLikes) { profile in
                            PendingRow(
                                profile: profile,
                                mode: .incoming,
                                onLike: { Task { await viewModel.likeIncomingPending(profile) } },
                                onPass: { Task { await viewModel.passIncomingPending(profile) } }
                            )
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }
            }

            if !viewModel.outgoingPendingLikes.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(BoopColors.accent)
                            .frame(width: 8, height: 8)
                        Text("Waiting On Them")
                            .font(BoopTypography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text("\(viewModel.outgoingPendingLikes.count)")
                            .font(BoopTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(BoopColors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BoopColors.accent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, BoopSpacing.xl)

                    VStack(spacing: 1) {
                        ForEach(viewModel.outgoingPendingLikes) { profile in
                            PendingRow(
                                profile: profile,
                                mode: .outgoing,
                                onLike: nil,
                                onPass: nil
                            )
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }
            }
        }
    }

    // MARK: - Seasonal Banner

    private func seasonalBanner(_ season: ActiveSeason) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            HStack(spacing: BoopSpacing.sm) {
                Text(season.emoji)
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 4) {
                    Text(season.title)
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(BoopColors.textPrimary)

                    Text(season.subtitle)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                Spacer()

                Text("Live")
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, BoopSpacing.xs)
                    .padding(.vertical, 4)
                    .background(season.tint)
                    .clipShape(Capsule())
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .stroke(season.tint.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, BoopSpacing.xl)
    }

}

// MARK: - Pending Row (compact inline item with note support)

private struct PendingRow: View {
    let profile: PendingLikeProfile
    let mode: PendingMode
    let onLike: (() -> Void)?
    let onPass: (() -> Void)?

    @State private var showNote = false

    enum PendingMode {
        case incoming
        case outgoing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: BoopSpacing.sm) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BoopColors.primary.opacity(0.15), BoopColors.secondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(profile.firstName.prefix(1)))
                            .font(.nunito(.semiBold, size: 17))
                            .foregroundStyle(BoopColors.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: BoopSpacing.xs) {
                        Text(displayName)
                            .font(BoopTypography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(BoopColors.textPrimary)
                            .lineLimit(1)

                        // Note indicator
                        if mode == .incoming, profile.note != nil {
                            Image(systemName: profile.note?.type == "voice" ? "mic.fill" : "envelope.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(BoopColors.secondary)
                        }
                    }

                    HStack(spacing: BoopSpacing.xs) {
                        if let city = profile.city {
                            Text(city)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .lineLimit(1)
                        }
                        if let score = profile.compatibilityScore {
                            HStack(spacing: 2) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 9))
                                Text("\(score)%")
                                    .font(BoopTypography.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(BoopColors.primary)
                        }
                    }
                }

                Spacer()

                if mode == .incoming {
                    HStack(spacing: BoopSpacing.xs) {
                        if profile.note != nil {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) { showNote.toggle() }
                            } label: {
                                Image(systemName: "text.bubble")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BoopColors.secondary)
                                    .frame(width: 34, height: 34)
                                    .background(BoopColors.secondary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        Button(action: { Haptics.light(); onPass?() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(BoopColors.textMuted)
                                .frame(width: 34, height: 34)
                                .background(BoopColors.surfaceSecondary)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Pass")

                        Button(action: { Haptics.medium(); onLike?() }) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(BoopColors.primaryGradient)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Like")
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(BoopColors.accent)
                            .frame(width: 6, height: 6)
                        Text("Pending")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.accent)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.sm)

            // Expandable note preview
            if showNote, let note = profile.note {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: note.type == "voice" ? "waveform" : "quote.opening")
                            .font(.system(size: 10))
                            .foregroundStyle(BoopColors.secondary)
                        Text(note.type == "voice" ? "Voice note (\(Int(note.duration ?? 0))s)" : "Their note")
                            .font(BoopTypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(BoopColors.secondary)
                    }

                    if note.type == "text" {
                        Text(note.content)
                            .font(BoopTypography.footnote)
                            .foregroundStyle(BoopColors.textPrimary)
                            .italic()
                    }
                }
                .padding(.horizontal, BoopSpacing.lg)
                .padding(.bottom, BoopSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(BoopColors.surface)
    }

    private var displayName: String {
        if let age = profile.age {
            return "\(profile.firstName), \(age)"
        }
        return profile.firstName
    }
}
