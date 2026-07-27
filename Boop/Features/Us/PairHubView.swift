import SwiftUI

/// "Your Us" — the pair hub for two people who already know each other.
/// No stages, no points, no fog: game chemistry (with day-0 states),
/// how you answer, chat & games, and a way to end the pair.
struct PairHubView: View {
    let matchId: String
    let partnerName: String

    @State private var chemistry: GameChemistryResponse?
    @State private var answerSync: AnswerSyncResponse?
    @State private var isLoading = true
    @State private var showEndConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.lg) {
                howYouPlayCard
                togetherCard

                Button {
                    showEndConfirm = true
                } label: {
                    Text("End this pair")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.error)
                }
                .padding(.top, BoopSpacing.sm)

                Text("No stages. No points. No fog. Just you two.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Your Us")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("End this pair?", isPresented: $showEndConfirm, titleVisibility: .visible) {
            Button("End it", role: .destructive) {
                Task {
                    try? await APIClient.shared.requestVoid(.archiveMatch(matchId: matchId, reason: "other"))
                    dismiss()
                }
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You can always pair again later with a fresh code.")
        }
        .task {
            chemistry = try? await APIClient.shared.request(.getGameChemistry(matchId: matchId))
            answerSync = try? await APIClient.shared.request(.getAnswerSync(matchId: matchId))
            isLoading = false
        }
        .refreshable {
            chemistry = try? await APIClient.shared.request(.getGameChemistry(matchId: matchId))
            answerSync = try? await APIClient.shared.request(.getAnswerSync(matchId: matchId))
        }
    }

    // MARK: - How you play (day-0 aware)

    @ViewBuilder
    private var howYouPlayCard: some View {
        if isLoading {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "You two")
                AccentRule()
                ProgressView().tint(BoopColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BoopSpacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        } else if let chem = chemistry, chem.roundsCompared > 0 {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "You two")
                AccentRule()

                Text(verdict(chem))
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("From the games you've played together.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)

                if !chem.inSync.isEmpty {
                    sectionLabel("You both picked")
                    ForEach(chem.inSync.prefix(3)) { item in
                        row("♥", BoopColors.accentColor, sameText(item))
                    }
                }
                if !chem.differentTakes.isEmpty {
                    sectionLabel("Different takes")
                    ForEach(chem.differentTakes.prefix(2)) { item in
                        row("⇄", Color(hex: "6E84E6"), differentText(item))
                    }
                }
                if !chem.tryTogether.isEmpty {
                    sectionLabel("Firsts to share")
                    ForEach(chem.tryTogether.prefix(2)) { item in
                        row("✧", Color(hex: "C9A7EA"), "\(stripNHIE(item.prompt)) — neither of you has. Yet.")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        } else {
            // Day one — never an empty dashboard. One clear first step.
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "You two")
                AccentRule()
                Text("Your story starts here")
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)

                if let sync = answerSync, sync.totalCommon > 0 {
                    Text("From the questions you've both answered: \(sync.verdict.lowercased()). A game will spark even more.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Nothing to compare yet — and that's the fun part. A quick game sparks your first chemistry.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                NavigationLink {
                    MatchGamesView(matchId: matchId)
                } label: {
                    Text("▶  Play your first game")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BoopSpacing.md)
                        .background(Capsule().fill(BoopColors.accentColor))
                }

                Text("As you both answer daily questions, we'll compare minds too.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
    }

    // MARK: - Together

    private var togetherCard: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Together")
            AccentRule()

            NavigationLink {
                MatchConversationLoaderView(matchId: matchId)
            } label: {
                HairlineRow("Chat", showChevron: true)
            }

            NavigationLink {
                MatchGamesView(matchId: matchId)
            } label: {
                HairlineRow("Play Games", showChevron: true)
            }

            NavigationLink {
                AnswerSyncView(matchId: matchId, partnerName: partnerName)
            } label: {
                HairlineRow("How you two answer", showChevron: true)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    // MARK: - Helpers (same warm language as You Two)

    private func verdict(_ chem: GameChemistryResponse) -> String {
        let ratio = Double(chem.sameCount) / Double(max(1, chem.roundsCompared))
        if ratio >= 0.75 { return "Same wavelength" }
        if ratio >= 0.5 { return "More alike than different" }
        if ratio >= 0.3 { return "Opposites attracting" }
        return "Beautifully different"
    }

    private func sameText(_ item: GameChemistrySame) -> String {
        if item.gameType == "never_have_i_ever" { return "\(stripNHIE(item.prompt)) — you both have 😏" }
        if item.gameType == "intimacy_spectrum" { return "\(item.prompt) — same place for both of you" }
        return item.answer
    }

    private func differentText(_ item: GameChemistryDifferent) -> String {
        if item.gameType == "never_have_i_ever" {
            let youHave = item.you.lowercased() == "i have"
            return "\(stripNHIE(item.prompt)) — \(youHave ? "you have, they haven't" : "they have, you haven't")"
        }
        if item.gameType == "intimacy_spectrum" {
            return "\(item.prompt) — you're \(item.you), they're \(item.them)"
        }
        return "You: \(item.you) · Them: \(item.them)"
    }

    private func stripNHIE(_ prompt: String) -> String {
        var text = prompt
        let prefix = "never have i ever "
        if text.lowercased().hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
        }
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(BoopTypography.cineLabel)
            .tracking(1.5)
            .foregroundStyle(BoopColors.textMuted)
            .padding(.top, BoopSpacing.xs)
    }

    private func row(_ symbol: String, _ color: Color, _ text: String) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Text(symbol)
                .font(.system(size: 15))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(text)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
