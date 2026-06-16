import SwiftUI

/// "Growth & Insights" — the detail page that holds everything technical about a
/// connection, framed gently. Reached from the Growth teaser on the slimmed
/// match detail page.
///
/// Hosts (moved out of MatchDetailView): the comfort score + breakdown, date
/// readiness, the comfort-over-time chart, and the AI relationship-insights
/// block. It owns its own MatchDetailViewModel and runs the same loads the main
/// page used for these sections.
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                introCard

                if let breakdown = viewModel.comfort?.breakdown {
                    comfortCard(breakdown: breakdown)
                }

                if let readiness = viewModel.readiness {
                    readinessCard(readiness)

                    // Date planning CTA when readiness is high enough.
                    if readiness.score >= 70 {
                        datePlanCTA
                    }
                }

                // Comfort-over-time chart.
                if let history = viewModel.scoreHistory {
                    ScoreProgressView(
                        snapshots: history.snapshots,
                        currentComfort: viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0,
                        currentCompatibility: viewModel.detail?.compatibilityScore
                    )
                }

                // AI relationship insights.
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
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Growth & Insights")
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

    // MARK: - Intro

    private var introCard: some View {
        let comfort = viewModel.comfort?.score ?? viewModel.detail?.comfortScore ?? 0
        let compatibility = viewModel.detail?.compatibilityScore
        let readiness = viewModel.readiness?.score

        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "The Full Picture")
            AccentRule()
            Text("What this connection is made of, and where it can grow.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 0) {
                statBlock(title: "Comfort", value: "\(clampPercent(comfort))")
                if let compatibility {
                    statDivider
                    statBlock(title: "Match", value: "\(clampPercent(compatibility))%")
                }
                if let readiness {
                    statDivider
                    statBlock(title: "Readiness", value: "\(clampPercent(readiness))")
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.sm)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(BoopColors.hairline)
            .frame(width: 1, height: 40)
    }

    // MARK: - Comfort

    private func comfortCard(breakdown: [String: ComfortBreakdownItem]) -> some View {
        let comfortScore = clampPercent(viewModel.comfort?.score ?? 0)
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

            HairlineProgress(progress: Double(comfortScore) / 100.0)

            Text("Reveal unlocks at \(threshold). You're at \(comfortScore).")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: BoopSpacing.md) {
                ForEach(breakdown.keys.sorted(), id: \.self) { key in
                    if let item = breakdown[key] {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(Self.humanize(key))
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(clampPercent(item.value))")
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textMuted)
                            }

                            HairlineProgress(progress: Double(clampPercent(item.value)) / 100.0)

                            Text(item.detail)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.top, BoopSpacing.xs)

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

    // MARK: - Readiness

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

            HairlineProgress(progress: Double(clampPercent(readiness.score)) / 100.0)

            Text("Overall readiness: \(clampPercent(readiness.score))/100")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)

            VStack(spacing: BoopSpacing.md) {
                ForEach(readiness.breakdown.keys.sorted(), id: \.self) { key in
                    if let item = readiness.breakdown[key] {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(Self.humanize(key))
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Spacer()
                                Text("\(clampPercent(item.value))")
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textMuted)
                            }

                            HairlineProgress(progress: Double(clampPercent(item.value)) / 100.0)
                        }
                    }
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var datePlanCTA: some View {
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

    // MARK: - Insights

    private var insightsPromptCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Relationship Insights")
            AccentRule()
            Text("AI analysis of your connection, strengths, and growth areas.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            BoopButton(title: "Analyze Connection", variant: .secondary, isLoading: false, fullWidth: true) {
                Task { await viewModel.loadInsights() }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    // MARK: - Helpers

    /// Clamp + round any score/percentage to a 0...100 integer so we never
    /// render nonsense like "10000%".
    private func clampPercent(_ value: Int) -> Int {
        min(100, max(0, value))
    }

    /// Turn a dimension / comfort-factor key into a human label.
    ///
    /// Handles both `snake_case` (from the API in places) and the `camelCase`
    /// the breakdown dictionaries actually arrive in, e.g.
    /// `active_days` / `activeDays` → "Active days",
    /// `voiceEngagement` → "Voice engagement",
    /// `vulnerabilitySignals` → "Vulnerability signals".
    /// Result is sentence-case (first word capitalised, rest lower).
    static func humanize(_ key: String) -> String {
        // 1. Underscores → spaces.
        var spaced = key.replacingOccurrences(of: "_", with: " ")

        // 2. Insert a space at lower→upper / letter→digit boundaries (camelCase).
        var result = ""
        var previous: Character?
        for char in spaced {
            if let prev = previous {
                let boundary =
                    (prev.isLowercase && char.isUppercase) ||
                    (prev.isLetter && char.isNumber) ||
                    (prev.isNumber && char.isLetter)
                if boundary {
                    result.append(" ")
                }
            }
            result.append(char)
            previous = char
        }
        spaced = result

        // 3. Collapse runs of whitespace, trim, lowercase everything.
        let words = spaced
            .split(whereSeparator: { $0 == " " })
            .map { $0.lowercased() }

        guard !words.isEmpty else { return key }

        // 4. Sentence case: capitalise only the first word.
        let first = words[0]
        let capitalisedFirst = first.prefix(1).uppercased() + first.dropFirst()
        return ([capitalisedFirst] + words.dropFirst()).joined(separator: " ")
    }
}
