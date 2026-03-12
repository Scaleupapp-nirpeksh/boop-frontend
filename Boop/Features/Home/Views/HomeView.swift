import SwiftUI

struct NotificationRoute: Hashable {}

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var notificationVM = NotificationInboxViewModel()

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: BoopSpacing.xl) {
                    header

                    if let season = ActiveSeason.current {
                        seasonalBanner(season)
                    }

                    if viewModel.newQuestionsCount > 0 {
                        newQuestionsBanner
                    }

                    connectionsSection

                    if !viewModel.incomingPendingLikes.isEmpty || !viewModel.outgoingPendingLikes.isEmpty {
                        activitySection
                    }
                }
                .padding(.vertical, BoopSpacing.lg)
            }
            .refreshable {
                await viewModel.refresh()
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
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BoopColors.cardDark, BoopColors.cardDarkMidBlue, BoopColors.cardDarkOcean],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 22, y: 14)

            Circle()
                .fill(BoopColors.secondary.opacity(0.18))
                .frame(width: 160, height: 160)
                .blur(radius: 10)
                .offset(x: 30, y: -24)

            Circle()
                .fill(BoopColors.primary.opacity(0.2))
                .frame(width: 140, height: 140)
                .blur(radius: 12)
                .offset(x: -170, y: -40)

            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("boop")
                            .font(.nunito(.extraBold, size: 28))
                            .foregroundStyle(Color.white.opacity(0.92))

                        Text("Welcome back, \(AuthManager.shared.currentUser?.firstName ?? "you")")
                            .font(BoopTypography.title3)
                            .foregroundStyle(.white)

                        Text(dailySummary)
                            .font(BoopTypography.body)
                            .foregroundStyle(Color.white.opacity(0.72))
                    }

                    Spacer()

                    NavigationLink(value: NotificationRoute()) {
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white)
                                )

                            if notificationVM.unreadCount > 0 {
                                Text(notificationVM.unreadCount > 99 ? "99+" : "\(notificationVM.unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(BoopColors.primary)
                                    .clipShape(Capsule())
                                    .offset(x: 4, y: -2)
                            }
                        }
                    }
                    .accessibilityLabel("Notifications\(notificationVM.unreadCount > 0 ? ", \(notificationVM.unreadCount) unread" : "")")
                }

                HStack(spacing: BoopSpacing.sm) {
                    statCard(value: "\(viewModel.activeMatches.count)", label: "Connections", tint: BoopColors.secondary)
                    statCard(value: "\(viewModel.incomingPendingLikes.count)", label: "Liked you", tint: BoopColors.primary)
                    statCard(value: "\(viewModel.newQuestionsCount)", label: "New prompts", tint: BoopColors.accent)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(BoopSpacing.lg)
        }
        .padding(.horizontal, BoopSpacing.xl)
    }

    // MARK: - Questions Banner

    private var newQuestionsBanner: some View {
        Button {
            viewModel.showQuestionsSheet = true
        } label: {
            BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                HStack(alignment: .top, spacing: BoopSpacing.sm) {
                    Circle()
                        .fill(BoopColors.goldenAccent.opacity(0.18))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(BoopColors.goldenAccent)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.newQuestionsCount) new question\(viewModel.newQuestionsCount == 1 ? "" : "s") unlocked")
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(BoopColors.textPrimary)

                        Text("Answer them to improve your profile.")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textPrimary.opacity(0.68))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                    .fill(BoopColors.surfaceGoldenBanner)
            )
        }
        .padding(.horizontal, BoopSpacing.xl)
    }

    // MARK: - Connections (full-width cards, vertical)

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Connections")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("People you've matched with")
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                Spacer()
                if !viewModel.activeMatches.isEmpty {
                    Text("\(viewModel.activeMatches.count)")
                        .font(BoopTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(BoopColors.secondary)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, 3)
                        .background(BoopColors.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, BoopSpacing.xl)

            if viewModel.activeMatches.isEmpty {
                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(spacing: BoopSpacing.sm) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 36))
                            .foregroundStyle(BoopColors.secondary.opacity(0.5))

                        Text("No connections yet")
                            .font(BoopTypography.callout)
                            .foregroundStyle(BoopColors.textPrimary)

                        Text("Head to Discover to find your first connection.")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, BoopSpacing.xl)
            } else {
                VStack(spacing: BoopSpacing.xs) {
                    ForEach(viewModel.activeMatches) { match in
                        NavigationLink {
                            MatchDetailView(matchId: match.matchId)
                        } label: {
                            ConnectionCard(match: match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
            }
        }
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

    // MARK: - Helpers

    private var dailySummary: String {
        if !viewModel.incomingPendingLikes.isEmpty {
            return "\(viewModel.incomingPendingLikes.count) people liked you."
        }
        if viewModel.newQuestionsCount > 0 {
            return "You have fresh prompts waiting."
        }
        if !viewModel.activeMatches.isEmpty {
            return "\(viewModel.activeMatches.count) active connections."
        }
        return "Head to Discover to find your next match."
    }

    private func statCard(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(BoopTypography.title3)
                .foregroundStyle(tint)

            Text(label)
                .font(BoopTypography.caption)
                .foregroundStyle(Color.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.md)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
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
