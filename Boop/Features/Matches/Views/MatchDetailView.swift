import SwiftUI

struct MatchDetailView: View {
    let matchId: String

    @State private var viewModel: MatchDetailViewModel
    @State private var audioPlayer = RemoteAudioPlayer()

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: MatchDetailViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                heroCard
                RealtimeStatusBanner()
                boopAndStreakRow
                scoreRow
                if !viewModel.topInsights.isEmpty || viewModel.growthInsight != nil {
                    chemistryCard
                }
                stageCard
                if let breakdown = viewModel.comfort?.breakdown {
                    comfortCard(breakdown: breakdown)
                }
                if let readiness = viewModel.readiness {
                    readinessCard(readiness)

                    // Date planning CTA when readiness >= 70
                    if readiness.score >= 70 {
                        NavigationLink {
                            DatePlanView(matchId: matchId)
                        } label: {
                            BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                                HStack(spacing: BoopSpacing.sm) {
                                    Circle()
                                        .fill(BoopColors.primary.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "calendar.badge.plus")
                                                .font(.system(size: 18))
                                                .foregroundStyle(BoopColors.primary)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Plan a Date")
                                            .font(BoopTypography.callout)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(BoopColors.textPrimary)
                                        Text("You're both ready! Suggest a time and place.")
                                            .font(BoopTypography.caption)
                                            .foregroundStyle(BoopColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(BoopColors.textMuted)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                                    .stroke(BoopColors.primary.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                }

                // Score progress chart
                if let history = viewModel.scoreHistory {
                    ScoreProgressView(
                        snapshots: history.snapshots,
                        currentComfort: viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0,
                        currentCompatibility: viewModel.detail?.compatibilityScore
                    )
                }

                // AI Relationship insights
                if viewModel.isLoadingInsights {
                    RelationshipInsightsLoadingCard()
                } else if let insightsResponse = viewModel.insights {
                    RelationshipInsightsCard(
                        insights: insightsResponse.insights,
                        scores: insightsResponse.scores
                    )
                } else {
                    insightsPromptCard
                }

                actionsCard
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .refreshable {
            await viewModel.load()
        }
        .navigationTitle(viewModel.detail?.otherUser?.firstName ?? "Match")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchStageChanged)) { notification in
            guard let payload = notification.userInfo?["payload"] as? MatchStageSocketEvent,
                  payload.matchId == matchId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchRevealRequest)) { notification in
            guard let payload = notification.userInfo?["payload"] as? MatchRevealSocketEvent,
                  payload.matchId == matchId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchRevealed)) { notification in
            guard let payload = notification.userInfo?["payload"] as? MatchRevealSocketEvent,
                  payload.matchId == matchId else { return }
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchBoop)) { notification in
            guard let payload = notification.userInfo?["payload"] as? BoopSocketEvent,
                  payload.matchId == matchId else { return }
            Task { await viewModel.load() }
        }
    }

    private var heroCard: some View {
        BoopCard(padding: 0, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [BoopColors.cardDarkAccent, BoopColors.cardDarkSlate, BoopColors.secondary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 210)

                    if let photo = displayPhotoURL {
                        BoopRemoteImage(urlString: photo) {
                            Rectangle().fill(Color.white.opacity(0.08))
                        }
                        .frame(height: 210)
                        .clipped()
                        .blur(radius: CGFloat(viewModel.detail?.otherUser?.blurLevel ?? 0))
                        .opacity(0.42)
                    }

                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        Text(viewModel.stageTitle.uppercased())
                            .font(BoopTypography.caption)
                            .fontWeight(.bold)
                            .kerning(1)
                            .foregroundStyle(Color.white.opacity(0.72))

                        Text(heroTitle)
                            .font(BoopTypography.title1)
                            .foregroundStyle(.white)

                        Text(heroSubtitle)
                            .font(BoopTypography.callout)
                            .foregroundStyle(Color.white.opacity(0.82))

                        if viewModel.detail?.otherUser?.voiceIntro?.audioUrl != nil {
                            Button {
                                audioPlayer.togglePlayback(urlString: viewModel.detail?.otherUser?.voiceIntro?.audioUrl)
                            } label: {
                                HStack(spacing: BoopSpacing.xs) {
                                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                    Text("Play voice intro")
                                }
                                .font(BoopTypography.footnote)
                                .foregroundStyle(.white)
                                .padding(.horizontal, BoopSpacing.sm)
                                .padding(.vertical, BoopSpacing.xs)
                                .background(Color.white.opacity(0.16))
                                .clipShape(Capsule())
                            }
                            .padding(.top, BoopSpacing.xs)
                        }
                    }
                    .padding(BoopSpacing.lg)
                }

                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    Text(viewModel.detail?.otherUser?.bio ?? "Keep building the connection. This page brings together comfort, reveal readiness, and the next action.")
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .padding(BoopSpacing.lg)
            }
        }
    }

    private var boopAndStreakRow: some View {
        HStack(spacing: BoopSpacing.sm) {
            // Boop button
            Button {
                Task { await viewModel.sendBoop() }
            } label: {
                HStack(spacing: BoopSpacing.xs) {
                    if viewModel.boopSuccess {
                        Image(systemName: "heart.fill")
                            .symbolEffect(.bounce, value: viewModel.boopSuccess)
                    } else {
                        Image(systemName: "heart.circle.fill")
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.boopSuccess ? "Booped!" : "Boop")
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                        if let count = viewModel.detail?.boopCount, count > 0 {
                            Text("\(count) total")
                                .font(BoopTypography.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .background(
                    viewModel.boopSuccess
                        ? BoopColors.success
                        : viewModel.canBoop ? BoopColors.primary : BoopColors.textMuted
                )
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
            }
            .disabled(!viewModel.canBoop || viewModel.isBoopping)
            .sensoryFeedback(.success, trigger: viewModel.boopSuccess)

            // Streak display
            VStack(spacing: 4) {
                let streakCurrent = viewModel.detail?.streak?.current ?? 0
                let streakLongest = viewModel.detail?.streak?.longest ?? 0

                HStack(spacing: 4) {
                    Text(streakCurrent > 0 ? "🔥" : "💤")
                    Text("\(streakCurrent)")
                        .font(BoopTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(streakCurrent > 0 ? BoopColors.primary : BoopColors.textMuted)
                }

                Text(streakCurrent > 0 ? "day streak" : "no streak")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)

                if streakLongest > streakCurrent {
                    Text("Best: \(streakLongest)")
                        .font(.system(size: 10))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BoopSpacing.md)
            .background(Color.white.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
        }
    }

    private var scoreRow: some View {
        HStack(spacing: BoopSpacing.sm) {
            statBlock(title: "Match", value: "\(viewModel.detail?.compatibilityScore ?? 0)%", tint: BoopColors.primary)
            statBlock(title: "Comfort", value: "\(viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0)", tint: BoopColors.secondary)
            statBlock(title: "Date", value: "\(viewModel.readiness?.score ?? 0)", tint: BoopColors.accent)
        }
    }

    private var stageCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .top, spacing: BoopSpacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection stage")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text(viewModel.stageSummary)
                            .font(BoopTypography.body)
                            .foregroundStyle(BoopColors.textSecondary)
                    }

                    Spacer()

                    Text(viewModel.stageTitle)
                        .font(BoopTypography.caption)
                        .foregroundStyle(stageColor(for: viewModel.detail?.stage ?? "mutual"))
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, 6)
                        .background(stageColor(for: viewModel.detail?.stage ?? "mutual").opacity(0.12))
                        .clipShape(Capsule())
                }

                VStack(spacing: BoopSpacing.sm) {
                    ForEach(Array(viewModel.stageSteps.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: BoopSpacing.sm) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(index <= viewModel.currentStageIndex ? stageColor(for: step.rawValue) : BoopColors.border)
                                    .frame(width: 12, height: 12)

                                if index < viewModel.stageSteps.count - 1 {
                                    Rectangle()
                                        .fill(index < viewModel.currentStageIndex ? stageColor(for: step.rawValue) : BoopColors.border)
                                        .frame(width: 2, height: 24)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Text(step.subtitle)
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }

                            Spacer()
                        }
                    }
                }

                if let revealProgressText = viewModel.revealProgressText {
                    HStack(spacing: BoopSpacing.xs) {
                        Image(systemName: "eye.fill")
                        Text(revealProgressText)
                    }
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.secondary)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, BoopSpacing.xs)
                    .background(BoopColors.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended next move")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                    Text(viewModel.nextActionSummary)
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textPrimary)
                }
                .padding(BoopSpacing.md)
                .background(BoopColors.chatBackground)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                HStack(spacing: BoopSpacing.sm) {
                    if viewModel.canRequestReveal {
                        BoopButton(title: viewModel.revealButtonTitle, variant: .secondary, isLoading: viewModel.isWorking, fullWidth: false) {
                            Task { await viewModel.requestReveal() }
                        }
                    } else if viewModel.isAwaitingOtherReveal {
                        Text("Reveal request sent")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.secondary)
                            .padding(.horizontal, BoopSpacing.sm)
                            .padding(.vertical, BoopSpacing.xs)
                            .background(BoopColors.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if viewModel.canAdvanceStage {
                        BoopButton(title: "Advance", variant: .primary, isLoading: viewModel.isWorking, fullWidth: false) {
                            Task { await viewModel.advanceStage() }
                        }
                    }
                }
            }
        }
    }

    private var chemistryCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Why this could work")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Your strongest overlap shows up here first.")
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)

                ForEach(viewModel.topInsights) { insight in
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        Circle()
                            .fill(Color(hex: insight.tintHex))
                            .frame(width: 10, height: 10)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(insight.title)
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.textPrimary)
                            Text(insight.detail)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }
                }

                if let growthInsight = viewModel.growthInsight {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(growthInsight.title)
                            .font(BoopTypography.callout)
                            .foregroundStyle(Color(hex: growthInsight.tintHex))
                        Text(growthInsight.detail)
                            .font(BoopTypography.footnote)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    .padding(BoopSpacing.md)
                    .background(BoopColors.surfaceGoldenLight)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }

                NavigationLink {
                    CompatibilityDeepDiveView(matchId: matchId)
                } label: {
                    HStack {
                        Text("View Full Breakdown")
                            .font(BoopTypography.callout)
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(BoopColors.secondary)
                    .padding(BoopSpacing.md)
                    .background(BoopColors.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                }
            }
        }
    }

    private func comfortCard(breakdown: [String: ComfortBreakdownItem]) -> some View {
        let comfortScore = viewModel.comfort?.score ?? 0
        let threshold = 70

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("How the connection is growing")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(comfortScore)/100")
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(BoopColors.secondary)
                }

                // Overall progress bar
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(BoopColors.surfaceSecondary)
                        Capsule()
                            .fill(BoopColors.secondaryGradient)
                            .frame(width: proxy.size.width * CGFloat(min(comfortScore, 100)) / 100.0)

                        // Threshold marker
                        Rectangle()
                            .fill(BoopColors.textMuted)
                            .frame(width: 2, height: 16)
                            .offset(x: proxy.size.width * CGFloat(threshold) / 100.0 - 1)
                    }
                }
                .frame(height: 10)

                Text("Reveal unlocks at \(threshold). You're at \(comfortScore).")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)

                ForEach(breakdown.keys.sorted(), id: \.self) { key in
                    if let item = breakdown[key] {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(item.value)")
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.secondary)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(BoopColors.surfaceSecondary)
                                    Capsule()
                                        .fill(BoopColors.secondary.opacity(0.6))
                                        .frame(width: proxy.size.width * CGFloat(min(item.value, 100)) / 100.0)
                                }
                            }
                            .frame(height: 6)

                            Text(item.detail)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }
                }

                // Comfort tips
                if comfortScore < threshold {
                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        Text("Tips to grow comfort")
                            .font(BoopTypography.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(BoopColors.textPrimary)

                        comfortTip(icon: "bubble.left.fill", text: "Send more messages to build conversation depth")
                        comfortTip(icon: "gamecontroller.fill", text: "Play games together to unlock shared experiences")
                        comfortTip(icon: "waveform", text: "Send a voice note to add warmth")
                        comfortTip(icon: "clock.fill", text: "Consistent daily interaction boosts your score")
                    }
                    .padding(BoopSpacing.md)
                    .background(BoopColors.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }
            }
        }
    }

    private func comfortTip(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(BoopColors.secondary)
                .frame(width: 18)
            Text(text)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    private func readinessCard(_ readiness: DateReadinessResponse) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Momentum to reveal or meet")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text(readiness.isReady ? "Ready" : "Not yet")
                        .font(BoopTypography.caption)
                        .foregroundStyle(readiness.isReady ? BoopColors.success : BoopColors.warning)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, 3)
                        .background((readiness.isReady ? BoopColors.success : BoopColors.warning).opacity(0.12))
                        .clipShape(Capsule())
                }

                // Overall score bar
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(BoopColors.surfaceSecondary)
                        Capsule()
                            .fill(BoopColors.warmGradient)
                            .frame(width: proxy.size.width * CGFloat(min(readiness.score, 100)) / 100.0)
                    }
                }
                .frame(height: 10)

                Text("Overall readiness: \(readiness.score)/100")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)

                ForEach(readiness.breakdown.keys.sorted(), id: \.self) { key in
                    if let item = readiness.breakdown[key] {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(item.value)")
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.accent)
                            }

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(BoopColors.surfaceSecondary)
                                    Capsule()
                                        .fill(BoopColors.accent.opacity(0.6))
                                        .frame(width: proxy.size.width * CGFloat(min(item.value, 100)) / 100.0)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
        }
    }

    private var insightsPromptCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(BoopColors.primary.opacity(0.6))

                VStack(spacing: 4) {
                    Text("Get relationship insights")
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("AI-powered analysis of your connection, strengths, and growth areas")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                BoopButton(title: "Analyze Connection", variant: .secondary, isLoading: false, fullWidth: true) {
                    Task { await viewModel.loadInsights() }
                }
            }
        }
    }

    private var actionsCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Next actions")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                NavigationLink {
                    MatchConversationLoaderView(matchId: matchId)
                } label: {
                    HStack {
                        Text("Open Chat")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textPrimary)
                    .padding(BoopSpacing.md)
                    .background(BoopColors.surfaceWarm)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                }

                NavigationLink {
                    MatchGamesView(matchId: matchId)
                } label: {
                    HStack {
                        Text("Play Games")
                        Spacer()
                        Image(systemName: "gamecontroller.fill")
                    }
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textPrimary)
                    .padding(BoopSpacing.md)
                    .background(BoopColors.surfaceMintLight)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                }

                Button {
                    Task { await viewModel.archive() }
                } label: {
                    Text("Archive Match")
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.error)
                }
            }
        }
    }

    private func statBlock(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
            Text(value)
                .font(BoopTypography.title3)
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.md)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
    }

    private var displayPhotoURL: String? {
        if let photo = viewModel.detail?.otherUser?.photos?.profilePhotoUrl {
            return photo
        }
        return viewModel.detail?.otherUser?.photos?.blurredUrl ?? viewModel.detail?.otherUser?.photos?.silhouetteUrl
    }

    private var heroTitle: String {
        let name = viewModel.detail?.otherUser?.firstName ?? "Someone"
        if let age = viewModel.detail?.otherUser?.age {
            return "\(name), \(age)"
        }
        return name
    }

    private var heroSubtitle: String {
        viewModel.detail?.otherUser?.city ?? "Building your connection"
    }

    private func stageIndex(_ stage: String) -> Int {
        switch stage {
        case "mutual": return 0
        case "connecting": return 1
        case "reveal_ready": return 2
        case "revealed": return 3
        case "dating": return 4
        default: return 0
        }
    }

    private func stageColor(for stage: String) -> Color {
        switch stage {
        case "revealed", "dating": return BoopColors.success
        case "reveal_ready": return BoopColors.accent
        default: return BoopColors.primary
        }
    }
}
