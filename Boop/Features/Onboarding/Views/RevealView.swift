import SwiftUI

/// The reward-first dopamine moment shown after the 8 onboarding questions.
///
/// A full-screen, "The Clearing"-style reverent reveal of the user's fixed
/// personality archetype ("Coded & Rare" treatment). The personality analysis
/// is generated asynchronously on the backend (queued at milestone 8), so this
/// screen loads `.getPersonalityAnalysis`, polls a few times while it's still
/// `nil`, and falls back to a graceful "being prepared" state that still lets
/// the user step into the app.
struct RevealView: View {
    @Bindable var onboardingVM: OnboardingViewModel
    /// Refreshes the user → `preview` and returns to RootView routing.
    let goToHomepage: () async -> Void

    @State private var phase: RevealPhase = .reading
    @State private var analysis: PersonalityAnalysis?
    @State private var nearbyCount: Int?
    @State private var showContent = false
    @State private var isEntering = false

    /// How many times we re-fetch the (async) analysis before giving up.
    private let maxPollAttempts = 3
    private let pollDelay: Duration = .seconds(1.5)

    private enum RevealPhase {
        case reading       // analysis not ready yet — cinematic loading
        case revealed      // analysis loaded — show the archetype
        case preparing     // gave up polling — graceful "being prepared" fallback
    }

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            switch phase {
            case .reading:
                readingState
            case .revealed:
                revealedState
            case .preparing:
                preparingState
            }
        }
        .task { await loadAnalysis() }
    }

    // MARK: - Reading (async analysis pending)

    private var readingState: some View {
        VStack(spacing: BoopSpacing.lg) {
            Spacer()
            EyebrowLabel(text: "Your type", color: BoopColors.accentColor)
            AccentRule(width: 40)
            Text("Reading your answers…")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .multilineTextAlignment(.center)
            ProgressView()
                .tint(BoopColors.accentColor)
                .padding(.top, BoopSpacing.xs)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, BoopSpacing.xl)
        .transition(.opacity)
    }

    // MARK: - Revealed (the archetype)

    private var revealedState: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: BoopSpacing.huge)

            if showContent {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Your type", color: BoopColors.accentColor)

                    // Coded & Rare top row: TYPE 0N (left) · N% RARE (right).
                    codedRareRow

                    // The archetype name — the hero line.
                    Text(displayName)
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    AccentRule()

                    // Essence line.
                    if let essence = essenceLine {
                        Text(essence)
                            .font(BoopTypography.cineBodyLight)
                            .foregroundStyle(BoopColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Signature traits — top facets by score, as tracked lines.
                    if !signatureTraits.isEmpty {
                        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                            ForEach(signatureTraits, id: \.self) { trait in
                                EyebrowLabel(text: trait, color: BoopColors.textMuted)
                            }
                        }
                        .padding(.top, BoopSpacing.sm)
                    }
                }
                .transition(.opacity)
            }

            Spacer(minLength: BoopSpacing.huge)

            BoopButton(title: pullTitle, isLoading: isEntering) {
                enterApp()
            }
            .opacity(showContent ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

    @ViewBuilder
    private var codedRareRow: some View {
        if typeLabel != nil || rarityLabel != nil {
            HStack {
                if let typeLabel {
                    Text(typeLabel)
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                if let rarityLabel {
                    Text(rarityLabel)
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
            }
        }
    }

    // MARK: - Preparing (graceful fallback after polling)

    private var preparingState: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "Your type", color: BoopColors.accentColor)
                AccentRule()
                Text("Your reading is being prepared")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("It takes a moment to read all eight answers. Explore while it finishes — your type will be waiting in your profile.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            BoopButton(title: pullTitle, isLoading: isEntering) {
                enterApp()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
        .transition(.opacity)
    }

    // MARK: - Derived display values

    /// Prefer the catalog archetype name; fall back to personalityType.
    private var displayName: String {
        if let name = analysis?.archetypeName, !name.isEmpty { return name }
        if let type = analysis?.personalityType, !type.isEmpty { return type }
        return "Your type"
    }

    /// "TYPE 0N" when we have a number; otherwise nil (row renders gracefully).
    private var typeLabel: String? {
        guard let number = analysis?.archetypeNumber else { return nil }
        return "TYPE \(String(format: "%02d", number))"
    }

    /// "N% RARE" when rarity is available and meaningful.
    private var rarityLabel: String? {
        guard let rarity = analysis?.rarityPercent, rarity > 0 else { return nil }
        return "\(rarity)% RARE"
    }

    private var essenceLine: String? {
        guard let essence = analysis?.essence, !essence.isEmpty else { return nil }
        return essence
    }

    /// The 3 highest-scoring facet titles as uppercase signature lines.
    private var signatureTraits: [String] {
        guard let facets = analysis?.facets else { return [] }
        return facets
            .sorted { $0.score > $1.score }
            .prefix(3)
            .map { $0.title }
    }

    /// The coral pull. Appends "· N nearby" when a candidate count is known.
    private var pullTitle: String {
        if let count = nearbyCount, count > 0 {
            return "See who fits you · \(count) nearby"
        }
        return "See who fits you"
    }

    // MARK: - Load (async analysis + poll + fallback)

    @MainActor
    private func loadAnalysis() async {
        // Fetch the nearby/compatible count in parallel — best-effort, optional.
        async let stats: DiscoverStats? = try? APIClient.shared.request(.getDiscoverStats)

        // The analysis is queued at milestone 8 and may not exist yet. Poll a
        // few times while `analysis` is nil before falling back gracefully.
        for attempt in 0..<maxPollAttempts {
            if let response: PersonalityAnalysisResponse = try? await APIClient.shared.request(.getPersonalityAnalysis),
               let ready = response.analysis {
                analysis = ready
                nearbyCount = (await stats)?.totalCandidates
                reveal()
                return
            }
            // Don't sleep after the final attempt.
            if attempt < maxPollAttempts - 1 {
                try? await Task.sleep(for: pollDelay)
            }
        }

        // Still nothing — let the user proceed; the reading finishes in the app.
        nearbyCount = (await stats)?.totalCandidates
        withAnimation(.easeInOut(duration: 0.4)) { phase = .preparing }
    }

    @MainActor
    private func reveal() {
        Haptics.celebration()
        withAnimation(.easeInOut(duration: 0.4)) { phase = .revealed }
        withAnimation(.easeIn(duration: 0.6).delay(0.3)) { showContent = true }
    }

    // MARK: - Enter the app

    private func enterApp() {
        isEntering = true
        Analytics.capture("reveal_enter_app", [
            "archetype": analysis?.archetypeCode ?? "pending",
            "had_analysis": analysis != nil
        ])
        Task {
            await goToHomepage()
            await MainActor.run { onboardingVM.markComplete() }
        }
    }
}
