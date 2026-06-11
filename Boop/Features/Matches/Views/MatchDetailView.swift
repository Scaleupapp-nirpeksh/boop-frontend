import SwiftUI

struct MatchDetailView: View {
    let matchId: String

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MatchDetailViewModel
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var showBlockError = false
    @State private var showClearing = false
    @State private var showLetGoConfirm = false

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: MatchDetailViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                heroCard
                RealtimeStatusBanner()
                goneQuietSection
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
                            HStack(spacing: BoopSpacing.md) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .thin))
                                    .foregroundStyle(BoopColors.accentColor)
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(BoopColors.accentColor.opacity(0.5), lineWidth: 1))

                                VStack(alignment: .leading, spacing: 4) {
                                    EyebrowLabel(text: "Plan A Date", color: BoopColors.accentColor)
                                    Text("You're both ready. Suggest a time and place.")
                                        .font(BoopTypography.cineCaption)
                                        .foregroundStyle(BoopColors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .thin))
                                    .foregroundStyle(BoopColors.textMuted)
                            }
                            .padding(BoopSpacing.lg)
                            .boopCard(radius: BoopRadius.xl, shadow: false)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("Block", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .thin))
                        .foregroundStyle(BoopColors.textPrimary)
                }
                .accessibilityLabel("Match options")
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportUserSheet(
                userId: viewModel.detail?.otherUser?.userId ?? "",
                userName: viewModel.detail?.otherUser?.firstName ?? "this user",
                contentType: "profile"
            )
        }
        .confirmationDialog(
            "Block \(viewModel.detail?.otherUser?.firstName ?? "this user")?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                Task { await blockOtherUser() }
            }
        } message: {
            Text("They won't be able to message you, this match will be removed, and they won't appear in Discover. They won't be notified.")
        }
        .alert("Couldn't block this user", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your connection and try again.")
        }
        .confirmationDialog("Let this connection go?", isPresented: $showLetGoConfirm, titleVisibility: .visible) {
            Button("Let it go", role: .destructive) {
                Task {
                    await viewModel.archive()
                    NotificationCenter.default.post(name: .init("boop.blockedUser"), object: nil)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This archives the conversation and frees a spot in Discover for someone new.")
        }
        .fullScreenCover(isPresented: $showClearing) {
            TheClearingView(
                name: viewModel.detail?.otherUser?.firstName ?? "Your match",
                photoURL: viewModel.detail?.otherUser?.photos?.profilePhotoUrl,
                days: viewModel.detail?.streak?.longest ?? viewModel.detail?.streak?.current ?? 0,
                games: gamesCountForRecap,
                voiceNotes: voiceCountForRecap,
                onDone: {
                    showClearing = false
                    if let matchId = viewModel.detail?.matchId {
                        NotificationRouter.shared.openChat(matchId: matchId)
                    }
                }
            )
        }
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

    private var isStalled: Bool {
        guard let d = viewModel.detail else { return false }
        let active = d.stage != "revealed" && d.stage != "dating" && d.stage != "archived"
        let coldStreak = (d.streak?.current ?? 0) == 0
        let lowComfort = (d.comfortScore ?? 0) < 70
        return active && coldStreak && lowComfort
    }

    @ViewBuilder
    private var goneQuietSection: some View {
        if isStalled {
            GoneQuietCard(
                name: viewModel.detail?.otherUser?.firstName ?? "This match",
                onBoop: { Task { await viewModel.sendBoop() } },
                onLetGo: { showLetGoConfirm = true }
            )
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            CinematicHeader(
                urlString: displayPhotoURL,
                blurRadius: FogBlur.radius(forComfort: viewModel.detail?.comfortScore, stage: viewModel.detail?.stage),
                height: 300
            ) {
                EyebrowLabel(text: viewModel.stageTitle, color: BoopColors.accentColor)
                AccentRule()
                Text(heroTitle)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(heroSubtitle)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textSecondary)

                if viewModel.detail?.otherUser?.voiceIntro?.audioUrl != nil {
                    Button {
                        audioPlayer.togglePlayback(urlString: viewModel.detail?.otherUser?.voiceIntro?.audioUrl)
                    } label: {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 11, weight: .regular))
                            Text("Voice intro")
                                .font(BoopTypography.cineCaption)
                                .tracking(0.5)
                        }
                        .foregroundStyle(BoopColors.textPrimary)
                        .padding(.vertical, BoopSpacing.xs)
                        .padding(.horizontal, BoopSpacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: BoopRadius.chip, style: .continuous)
                                .stroke(BoopColors.hairline, lineWidth: 1)
                        )
                    }
                    .padding(.top, BoopSpacing.xs)
                }

                NavigationLink {
                    PartnerProfileView(matchId: matchId, firstName: viewModel.detail?.otherUser?.firstName)
                } label: {
                    HStack(spacing: BoopSpacing.xs) {
                        Text("VIEW PROFILE")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .regular))
                    }
                    .foregroundStyle(BoopColors.accentColor)
                }
                .padding(.top, BoopSpacing.xs)
            }
            .padding(.horizontal, -BoopSpacing.xl)

            Text(viewModel.detail?.otherUser?.bio ?? "Keep building the connection. This page brings together comfort, reveal readiness, and the next action.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    private var boopAndStreakRow: some View {
        HStack(alignment: .center, spacing: BoopSpacing.lg) {
            // Boop button
            Button {
                Task { await viewModel.sendBoop() }
            } label: {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: viewModel.boopSuccess ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .regular))
                        .symbolEffect(.bounce, value: viewModel.boopSuccess)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(viewModel.boopSuccess ? "Booped" : "Boop")
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(0.5)
                        if let count = viewModel.detail?.boopCount, count > 0 {
                            Text("\(count) total")
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }
                }
                .foregroundStyle(viewModel.boopSuccess ? BoopColors.accentColor : BoopColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                        .stroke(viewModel.canBoop ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
                )
            }
            .disabled(!viewModel.canBoop || viewModel.isBoopping)
            .sensoryFeedback(.success, trigger: viewModel.boopSuccess)

            // Streak display
            VStack(alignment: .leading, spacing: 4) {
                let streakCurrent = viewModel.detail?.streak?.current ?? 0
                let streakLongest = viewModel.detail?.streak?.longest ?? 0

                EyebrowLabel(text: streakCurrent > 0 ? "Day Streak" : "No Streak")

                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "flame")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(streakCurrent > 0 ? BoopColors.accentColor : BoopColors.textMuted)
                    Text("\(streakCurrent)")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(streakCurrent > 0 ? BoopColors.textPrimary : BoopColors.textMuted)
                    if streakLongest > streakCurrent {
                        Text("Best \(streakLongest)")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scoreRow: some View {
        let comfort = viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0
        let readiness = viewModel.readiness?.score ?? 0
        return HStack(alignment: .top, spacing: 0) {
            statBlock(title: "Match", value: "\(viewModel.detail?.compatibilityScore ?? 0)%", progress: nil)
            scoreDivider
            statBlock(title: "Comfort", value: "\(comfort)", progress: Double(comfort) / 100.0)
            scoreDivider
            statBlock(title: "Readiness", value: "\(readiness)", progress: Double(readiness) / 100.0)
        }
    }

    private var scoreDivider: some View {
        Rectangle()
            .fill(BoopColors.hairline)
            .frame(width: 1, height: 48)
    }

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .top) {
                EyebrowLabel(text: "Connection Stage")
                Spacer()
                EyebrowLabel(text: viewModel.stageTitle, color: BoopColors.accentColor)
            }
            AccentRule()

            Text(viewModel.stageSummary)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.stageSteps.enumerated()), id: \.element.id) { index, step in
                    let reached = index <= viewModel.currentStageIndex
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(reached ? BoopColors.accentColor : BoopColors.hairline)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)

                            if index < viewModel.stageSteps.count - 1 {
                                Rectangle()
                                    .fill(index < viewModel.currentStageIndex ? BoopColors.accentColor : BoopColors.hairline)
                                    .frame(width: 1, height: 28)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(BoopTypography.cineBody)
                                .foregroundStyle(reached ? BoopColors.textPrimary : BoopColors.textMuted)
                            Text(step.subtitle)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                        .padding(.bottom, index < viewModel.stageSteps.count - 1 ? BoopSpacing.sm : 0)

                        Spacer()
                    }
                }
            }

            if let revealProgressText = viewModel.revealProgressText {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "eye")
                        .font(.system(size: 11, weight: .thin))
                    Text(revealProgressText)
                        .font(BoopTypography.cineCaption)
                        .tracking(0.5)
                }
                .foregroundStyle(BoopColors.accentColor)
            }

            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                EyebrowLabel(text: "Recommended Next Move")
                Text(viewModel.nextActionSummary)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
            }
            .padding(.top, BoopSpacing.xs)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }

            HStack(spacing: BoopSpacing.sm) {
                if viewModel.canRequestReveal {
                    BoopButton(title: viewModel.revealButtonTitle, variant: .secondary, isLoading: viewModel.isWorking, fullWidth: false) {
                        Task {
                            await viewModel.requestReveal()
                            if viewModel.detail?.stage == "revealed" {
                                showClearing = true
                            }
                        }
                    }
                } else if viewModel.isAwaitingOtherReveal {
                    EyebrowLabel(text: "Reveal Request Sent", color: BoopColors.accentColor)
                }

                if viewModel.canAdvanceStage {
                    BoopButton(title: "Advance", variant: .primary, isLoading: viewModel.isWorking, fullWidth: false) {
                        Task { await viewModel.advanceStage() }
                    }
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var chemistryCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Why This Could Work")
            AccentRule()

            Text("Your strongest overlap shows up here first.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(viewModel.topInsights) { insight in
                    VStack(alignment: .leading, spacing: 3) {
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                        Text(insight.title)
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)
                            .padding(.top, BoopSpacing.md)
                        Text(insight.detail)
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .padding(.bottom, BoopSpacing.md)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let growthInsight = viewModel.growthInsight {
                VStack(alignment: .leading, spacing: 4) {
                    EyebrowLabel(text: growthInsight.title, color: BoopColors.accentColor)
                    Text(growthInsight.detail)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .padding(.top, BoopSpacing.xs)
            }

            NavigationLink {
                CompatibilityDeepDiveView(matchId: matchId)
            } label: {
                HStack {
                    Text("View Full Breakdown")
                        .font(BoopTypography.cineBody)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .thin))
                }
                .foregroundStyle(BoopColors.accentColor)
                .padding(.top, BoopSpacing.xs)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private func comfortCard(breakdown: [String: ComfortBreakdownItem]) -> some View {
        let comfortScore = viewModel.comfort?.score ?? 0
        let threshold = 70

        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "How The Connection Is Growing")
                Spacer()
                Text("\(comfortScore)/100")
                    .font(BoopTypography.cineHeadline)
                    .foregroundStyle(BoopColors.textPrimary)
            }
            AccentRule()

            HairlineProgress(progress: Double(min(comfortScore, 100)) / 100.0)

            Text("Reveal unlocks at \(threshold). You're at \(comfortScore).")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: BoopSpacing.md) {
                ForEach(breakdown.keys.sorted(), id: \.self) { key in
                    if let item = breakdown[key] {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(item.value)")
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textMuted)
                            }

                            HairlineProgress(progress: Double(min(item.value, 100)) / 100.0)

                            Text(item.detail)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.top, BoopSpacing.xs)

            // Comfort tips
            if comfortScore < threshold {
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "Tips To Grow Comfort")

                    comfortTip(icon: "bubble.left", text: "Send more messages to build conversation depth")
                    comfortTip(icon: "gamecontroller", text: "Play games together to unlock shared experiences")
                    comfortTip(icon: "waveform", text: "Send a voice note to add warmth")
                    comfortTip(icon: "clock", text: "Consistent daily interaction boosts your score")
                }
                .padding(.top, BoopSpacing.sm)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private func comfortTip(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .thin))
                .foregroundStyle(BoopColors.accentColor)
                .frame(width: 18)
            Text(text)
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    private func readinessCard(_ readiness: DateReadinessResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Momentum To Reveal Or Meet")
                Spacer()
                EyebrowLabel(
                    text: readiness.isReady ? "Ready" : "Not Yet",
                    color: readiness.isReady ? BoopColors.accentColor : BoopColors.textMuted
                )
            }
            AccentRule()

            HairlineProgress(progress: Double(min(readiness.score, 100)) / 100.0)

            Text("Overall readiness: \(readiness.score)/100")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: BoopSpacing.md) {
                ForEach(readiness.breakdown.keys.sorted(), id: \.self) { key in
                    if let item = readiness.breakdown[key] {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(item.value)")
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textMuted)
                            }

                            HairlineProgress(progress: Double(min(item.value, 100)) / 100.0)
                        }
                    }
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var insightsPromptCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Relationship Insights")
            AccentRule()
            Text("AI analysis of your connection, strengths, and growth areas.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            BoopButton(title: "Analyze Connection", variant: .secondary, isLoading: false, fullWidth: true) {
                Task { await viewModel.loadInsights() }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Next Actions")
            AccentRule()

            NavigationLink {
                PartnerProfileView(matchId: matchId, firstName: viewModel.detail?.otherUser?.firstName)
            } label: {
                HairlineRow("About \(viewModel.detail?.otherUser?.firstName ?? "them")", showChevron: true)
            }

            NavigationLink {
                MatchConversationLoaderView(matchId: matchId)
            } label: {
                HairlineRow("Open Chat", showChevron: true)
            }

            NavigationLink {
                MatchGamesView(matchId: matchId)
            } label: {
                HairlineRow("Play Games", showChevron: true)
            }

            Button {
                Task { await viewModel.archive() }
            } label: {
                HairlineRow("Archive Match", titleColor: BoopColors.error)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private func statBlock(title: String, value: String, progress: Double?) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: title)
            Text(value)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            if let progress {
                HairlineProgress(progress: progress)
                    .frame(width: 56)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.md)
    }

    private var gamesCountForRecap: Int {
        let detail = viewModel.comfort?.breakdown["gamesCompleted"]?.detail ?? ""
        return Int(detail.prefix(while: \.isNumber)) ?? 0
    }

    private var voiceCountForRecap: Int {
        let detail = viewModel.comfort?.breakdown["voiceEngagement"]?.detail ?? ""
        return Int(detail.prefix(while: \.isNumber)) ?? 0
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

    private func blockOtherUser() async {
        guard let userId = viewModel.detail?.otherUser?.userId else { return }
        do {
            try await APIClient.shared.requestVoid(.blockUser(userId: userId))
            Haptics.success()
            NotificationCenter.default.post(name: .init("boop.blockedUser"), object: nil)
            dismiss()
        } catch {
            showBlockError = true
        }
    }
}
