import SwiftUI

struct MatchDetailView: View {
    let matchId: String
    /// When presented modally (full-screen cover), show a Close button. When
    /// pushed in a navigation stack the system back button handles dismissal.
    let isModal: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: MatchDetailViewModel
    @State private var answerSyncViewModel: AnswerSyncViewModel
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var showBlockError = false
    @State private var showClearing = false
    @State private var showLetGoConfirm = false

    init(matchId: String, isModal: Bool = false) {
        self.matchId = matchId
        self.isModal = isModal
        _viewModel = State(initialValue: MatchDetailViewModel(matchId: matchId))
        _answerSyncViewModel = State(initialValue: AnswerSyncViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                // 1. Hero (unchanged)
                heroCard
                RealtimeStatusBanner()
                goneQuietSection
                lastInteractedRow

                // 2. Connection stage — horizontal stepper
                connectionStageStrip

                // 3. "Growth & insights" teaser
                growthInsightsTeaser

                // 4. Next actions
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
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(BoopColors.accentColor)
                }
            }
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
        .task {
            if answerSyncViewModel.data == nil {
                await answerSyncViewModel.load()
            }
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

    private var lastInteractedRow: some View {
        HStack(alignment: .center, spacing: BoopSpacing.lg) {
            // Last interaction
            VStack(alignment: .leading, spacing: 4) {
                EyebrowLabel(text: "Last Chatted")
                Text(lastInteractedText)
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Points to reveal
            VStack(alignment: .leading, spacing: 4) {
                let pts = pointsToReveal
                EyebrowLabel(text: pts > 0 ? "To Reveal" : "Reveal Ready")
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: pts > 0 ? "eye.slash" : "eye")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(pts > 0 ? BoopColors.textMuted : BoopColors.accentColor)
                    Text(pts > 0 ? "\(pts) points" : "Ready")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(pts > 0 ? BoopColors.textPrimary : BoopColors.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var pointsToReveal: Int {
        let comfort = min(100, max(0, viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0))
        return max(0, 70 - comfort)
    }

    private var lastInteractedText: String {
        if let d = viewModel.detail?.streak?.lastActiveDate {
            return d.formatted(.relative(presentation: .named)).capitalized
        }
        if let m = viewModel.detail?.matchedAt {
            return "Matched \(m.formatted(.relative(presentation: .named)))"
        }
        return "Not yet"
    }

    // MARK: - Section 2 · Connection stage (horizontal)

    private var connectionStageStrip: some View {
        ConnectionStageStrip(
            steps: viewModel.stageSteps,
            currentIndex: viewModel.currentStageIndex,
            stageTitle: viewModel.stageTitle,
            summary: viewModel.stageSummary,
            revealProgressText: viewModel.revealProgressText,
            canRequestReveal: viewModel.canRequestReveal,
            isAwaitingOtherReveal: viewModel.isAwaitingOtherReveal,
            revealButtonTitle: viewModel.revealButtonTitle,
            canAdvanceStage: viewModel.canAdvanceStage,
            isWorking: viewModel.isWorking,
            errorMessage: viewModel.errorMessage,
            onRequestReveal: {
                Task {
                    await viewModel.requestReveal()
                    if viewModel.detail?.stage == "revealed" {
                        showClearing = true
                    }
                }
            },
            onAdvance: {
                Task { await viewModel.advanceStage() }
            }
        )
    }

    // MARK: - Section 3 · "How you answer together" teaser

    private var answerSyncTeaser: some View {
        NavigationLink {
            AnswerSyncView(matchId: matchId, partnerName: viewModel.detail?.otherUser?.firstName ?? "them")
        } label: {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .top) {
                    EyebrowLabel(text: "How You Answer Together")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                AccentRule()

                if let data = answerSyncViewModel.data, data.totalCommon > 0 {
                    Text(data.verdict)
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    answerSyncSpectrum(data)
                        .padding(.top, BoopSpacing.xxs)

                    Text("\(data.totalCommon) questions you've both answered")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                } else {
                    Text("See where you click")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("Answer the same questions and we'll show how your views line up.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
        .buttonStyle(.plain)
    }

    /// Mini sync spectrum: one segment per non-empty bucket, width ∝ count.
    private func answerSyncSpectrum(_ data: AnswerSyncResponse) -> some View {
        let segments = data.buckets.filter { $0.count > 0 }
        let total = max(1, segments.reduce(0) { $0 + $1.count })
        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments) { bucket in
                    Rectangle()
                        .fill(answerSyncColor(bucket.key))
                        .frame(width: max(3, (CGFloat(bucket.count) / CGFloat(total)) * (geo.size.width - CGFloat(max(0, segments.count - 1)) * 2)))
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    /// Coral → muted colour ramp keyed by sync level (matches AnswerSyncView).
    private func answerSyncColor(_ key: String) -> Color {
        switch key {
        case "highly_in_sync": return BoopColors.accentColor
        case "in_sync": return Color(hex: "FF8A6B")
        case "neutral_ground": return Color(hex: "8A7F9E")
        case "different_views": return Color(hex: "5B6B8D")
        case "poles_apart": return Color(hex: "3A3550")
        default: return BoopColors.textMuted
        }
    }

    // MARK: - Section 4 · "Growth & insights" teaser

    private var growthInsightsTeaser: some View {
        let comfort = min(100, max(0, viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0))
        let trend = comfortTrend

        return NavigationLink {
            GrowthInsightsView(matchId: matchId)
        } label: {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .top) {
                    EyebrowLabel(text: "Growth & Insights")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                AccentRule()

                HStack(alignment: .firstTextBaseline, spacing: BoopSpacing.sm) {
                    Text("Comfort \(comfort)/100")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                    if let trend {
                        HStack(spacing: 3) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .light))
                            Text(trend >= 0 ? "+\(trend)" : "\(trend)")
                                .font(.system(size: 13, weight: .light))
                        }
                        .foregroundStyle(trend >= 0 ? BoopColors.success : BoopColors.error)
                    }
                }

                Text("Tap to see what grows it + your insights.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
        .buttonStyle(.plain)
    }

    /// Net comfort change across the score history, if there's enough history.
    private var comfortTrend: Int? {
        guard let snapshots = viewModel.scoreHistory?.snapshots, snapshots.count >= 2,
              let first = snapshots.first?.comfortScore, let last = snapshots.last?.comfortScore else {
            return nil
        }
        return last - first
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Next Actions")
            AccentRule()

            NavigationLink {
                AnswerSyncView(matchId: matchId, partnerName: viewModel.detail?.otherUser?.firstName ?? "them")
            } label: {
                HairlineRow("How you two answer", showChevron: true)
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
                showLetGoConfirm = true
            } label: {
                HairlineRow("Archive Match", titleColor: BoopColors.error)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
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
