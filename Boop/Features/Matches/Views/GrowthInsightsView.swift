import SwiftUI

/// "You Two" — how the connection is going, told warmly and without a single
/// visible number (points-to-reveal is the one deliberate exception: it's the
/// currency users asked for). The backend's comfort breakdown still powers
/// everything — it silently decides WHICH celebrations and suggestions appear.
struct GrowthInsightsView: View {
    let matchId: String

    @State private var viewModel: MatchDetailViewModel

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: MatchDetailViewModel(matchId: matchId))
    }

    /// Used by debug harnesses / previews to inject a preloaded view model.
    init(matchId: String, viewModel: MatchDetailViewModel) {
        self.matchId = matchId
        _viewModel = State(initialValue: viewModel)
    }

    private var comfort: Int {
        min(100, max(0, viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0))
    }

    private var pointsToReveal: Int { max(0, 70 - comfort) }

    private var isRevealed: Bool {
        let stage = viewModel.detail?.stage ?? ""
        return stage == "revealed" || stage == "dating"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                fogHero

                if !celebrations.isEmpty {
                    bloomingCard
                }

                if !suggestions.isEmpty {
                    closerCard
                }

                if (viewModel.readiness?.isReady ?? false) || comfort >= 70 {
                    datePlanCTA
                }

                noteSection
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("You Two")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load()
        }
        .task {
            if viewModel.detail == nil {
                await viewModel.load()
            }
        }
    }

    // MARK: - Fog hero: their photo, clearing as you grow closer

    private var heroPhotoURL: String? {
        let photos = viewModel.detail?.otherUser?.photos
        return photos?.profilePhotoUrl ?? photos?.blurredUrl ?? photos?.silhouetteUrl
    }

    /// How thick the fog sits over the photo (0 = clear).
    private var fogAmount: Double {
        if isRevealed { return 0 }
        return Double(pointsToReveal) / 70.0
    }

    private var stagePhrase: String {
        if isRevealed { return "In full colour" }
        if comfort >= 70 { return "Ready for the reveal" }
        if comfort >= 45 { return "The fog is lifting" }
        if comfort >= 25 { return "Warming up" }
        return "Just beginning"
    }

    private var pointsLine: String {
        if isRevealed { return "You've seen each other — keep going" }
        if pointsToReveal == 0 { return "You've earned the reveal ✨" }
        return "\(pointsToReveal) points to the reveal"
    }

    /// A whisper about direction, from the score history — no chart, no numbers.
    private var trendWhisper: String? {
        guard let snapshots = viewModel.scoreHistory?.snapshots, snapshots.count >= 2,
              let first = snapshots.first?.comfortScore, let last = snapshots.last?.comfortScore else {
            return nil
        }
        if last > first { return "You're closer than when you started" }
        if last < first { return "It's been quiet — a little hello goes a long way" }
        return nil
    }

    private var fogHero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let url = heroPhotoURL.flatMap(URL.init(string:)) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(BoopColors.surfaceSecondary)
                    }
                } else {
                    // No photo yet — the brand orbs behind the fog.
                    ZStack {
                        Rectangle().fill(BoopColors.surfaceSecondary)
                        HStack(spacing: -14) {
                            Circle().fill(Color(hex: "FF5C72")).frame(width: 74, height: 74)
                            Circle().fill(Color(hex: "6E84E6")).frame(width: 74, height: 74)
                        }
                        .blur(radius: 18)
                        .opacity(0.8)
                    }
                }
            }
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .clipped()
            .blur(radius: fogAmount * 10)
            .overlay(BoopColors.ground.opacity(fogAmount * 0.45))
            .overlay(
                LinearGradient(
                    colors: [.clear, BoopColors.ground.opacity(0.9)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Text(stagePhrase)
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)

                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: isRevealed ? "eye" : "eye.slash")
                        .font(.system(size: 11, weight: .thin))
                    Text(pointsLine)
                        .font(BoopTypography.cineLabel)
                        .tracking(1.5)
                }
                .foregroundStyle(BoopColors.accentColor)

                if let whisper = trendWhisper {
                    Text(whisper)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(BoopSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
        .animation(.easeInOut(duration: 0.6), value: fogAmount)
    }

    // MARK: - What's blooming (celebrations — the strong drivers, worded warmly)

    private struct Celebration: Identifiable {
        let emoji: String
        let line: String
        var id: String { line }
    }

    private var celebrations: [Celebration] {
        guard let breakdown = viewModel.comfort?.breakdown else { return [] }
        return breakdown
            .filter { $0.value.value >= 60 }
            .sorted { $0.value.value > $1.value.value }
            .prefix(2)
            .compactMap { key, _ in Self.celebrationCopy[normalize(key)] }
    }

    private static let celebrationCopy: [String: Celebration] = [
        "activedays": Celebration(emoji: "💛", line: "You keep showing up for each other"),
        "gamescompleted": Celebration(emoji: "🎮", line: "Your game nights are a vibe"),
        "messagedepth": Celebration(emoji: "💬", line: "Your conversations go deep"),
        "messagevolume": Celebration(emoji: "✨", line: "The chat never sleeps"),
        "responseconsistency": Celebration(emoji: "⚡️", line: "You match each other's energy"),
        "vulnerabilitysignals": Celebration(emoji: "💭", line: "You're letting each other in"),
        "voiceengagement": Celebration(emoji: "🎙️", line: "Your voices do the talking"),
    ]

    private var bloomingCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "What's blooming")
            AccentRule()
            ForEach(celebrations) { c in
                HStack(spacing: BoopSpacing.sm) {
                    Text(c.emoji)
                    Text(c.line)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    // MARK: - What brings you closer (the weak drivers → things to do)

    private enum SuggestionLink { case chat, games }

    private struct Suggestion: Identifiable {
        let emoji: String
        let title: String
        let line: String
        let link: SuggestionLink?
        var id: String { title }
    }

    private var suggestions: [Suggestion] {
        guard let breakdown = viewModel.comfort?.breakdown else { return [] }
        let celebrated = Set(
            breakdown.filter { $0.value.value >= 60 }
                .sorted { $0.value.value > $1.value.value }
                .prefix(2)
                .map { normalize($0.key) }
        )
        return breakdown
            .sorted { $0.value.value < $1.value.value }
            .compactMap { key, _ -> Suggestion? in
                let k = normalize(key)
                guard !celebrated.contains(k) else { return nil }
                return Self.suggestionCopy[k]
            }
            .prefix(3)
            .map { $0 }
    }

    private static let suggestionCopy: [String: Suggestion] = [
        "activedays": Suggestion(emoji: "☀️", title: "Drop by tomorrow too", line: "Little visits add up", link: .chat),
        "gamescompleted": Suggestion(emoji: "🎮", title: "Play a game together", line: "Shared laughs build trust", link: .games),
        "messagedepth": Suggestion(emoji: "💬", title: "Ask something real", line: "Go deeper than 'hey'", link: .chat),
        "messagevolume": Suggestion(emoji: "💌", title: "Keep the conversation flowing", line: "A message a day melts the fog", link: .chat),
        "responseconsistency": Suggestion(emoji: "⚡️", title: "Match their rhythm", line: "Replying back keeps the spark", link: .chat),
        "vulnerabilitysignals": Suggestion(emoji: "💭", title: "Share something real", line: "Something you don't usually tell people", link: .chat),
        "voiceengagement": Suggestion(emoji: "🎙️", title: "Send a voice note", line: "Let them hear you", link: .chat),
    ]

    private var closerCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "What brings you closer")
            AccentRule()
            ForEach(suggestions) { s in
                suggestionRow(s)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    @ViewBuilder
    private func suggestionRow(_ s: Suggestion) -> some View {
        switch s.link {
        case .games:
            NavigationLink { MatchGamesView(matchId: matchId) } label: { suggestionLabel(s) }
                .buttonStyle(.plain)
        case .chat:
            NavigationLink { MatchConversationLoaderView(matchId: matchId) } label: { suggestionLabel(s) }
                .buttonStyle(.plain)
        case nil:
            suggestionLabel(s)
        }
    }

    private func suggestionLabel(_ s: Suggestion) -> some View {
        HStack(alignment: .center, spacing: BoopSpacing.sm) {
            Text(s.emoji)
                .font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(s.title)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(s.line)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textSecondary)
            }
            Spacer()
            if s.link != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .thin))
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
        .padding(.vertical, BoopSpacing.xs)
        .contentShape(Rectangle())
    }

    // MARK: - Date CTA

    private var datePlanCTA: some View {
        NavigationLink {
            DatePlanView(matchId: matchId)
        } label: {
            HStack(spacing: BoopSpacing.md) {
                Text("🌆")
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    EyebrowLabel(text: "Ready for the real world", color: BoopColors.accentColor)
                    Text("You two seem ready. Plan the first date.")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
        .buttonStyle(.plain)
    }

    // MARK: - A note about you two (AI insight, words only — never scores)

    @ViewBuilder
    private var noteSection: some View {
        if viewModel.isLoadingInsights {
            RelationshipInsightsLoadingCard()
        } else if let insights = viewModel.insights?.insights {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "A note about you two")
                AccentRule()

                if let summary = insights.overallSummary {
                    Text(summary)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textPrimary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let steps = insights.nextSteps, !steps.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        ForEach(steps.prefix(2), id: \.self) { step in
                            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                                Text("♡")
                                    .foregroundStyle(BoopColors.accentColor)
                                Text(step)
                                    .font(BoopTypography.cineCaption)
                                    .foregroundStyle(BoopColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.top, BoopSpacing.xxs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        } else {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "A note about you two")
                AccentRule()
                Text("A little letter about how you two fit — written just for you.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                BoopButton(title: "Write our note", variant: .secondary, isLoading: false, fullWidth: true) {
                    Task { await viewModel.loadInsights() }
                }
                .padding(.top, BoopSpacing.xs)
            }
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
    }

    // MARK: - Helpers

    /// Breakdown keys arrive as camelCase or snake_case — normalise to compare.
    private func normalize(_ key: String) -> String {
        key.replacingOccurrences(of: "_", with: "").lowercased()
    }
}

/// Design-review harness: the You Two page with representative data.
struct YouTwoGalleryView: View {
    var body: some View {
        NavigationStack {
            GrowthInsightsView(matchId: "demo", viewModel: Self.mockVM())
        }
    }

    private static func mockVM() -> MatchDetailViewModel {
        let vm = MatchDetailViewModel(matchId: "demo")
        vm.detail = MatchDetail(
            matchId: "demo",
            stage: "connecting",
            compatibilityScore: 92,
            matchTier: "platinum",
            dimensionScores: nil,
            comfortScore: 42,
            matchedAt: nil,
            revealStatus: nil,
            lastBoop: nil,
            boopCount: nil,
            streak: nil,
            otherUser: nil
        )
        vm.comfort = ComfortScoreResponse(
            score: 42,
            breakdown: [
                "activeDays": ComfortBreakdownItem(value: 29, weight: 0.2, detail: ""),
                "gamesCompleted": ComfortBreakdownItem(value: 67, weight: 0.15, detail: ""),
                "messageDepth": ComfortBreakdownItem(value: 53, weight: 0.2, detail: ""),
                "messageVolume": ComfortBreakdownItem(value: 10, weight: 0.15, detail: ""),
                "responseConsistency": ComfortBreakdownItem(value: 67, weight: 0.15, detail: ""),
                "vulnerabilitySignals": ComfortBreakdownItem(value: 38, weight: 0.15, detail: ""),
            ],
            matchId: "demo",
            updatedAt: nil
        )
        return vm
    }
}
