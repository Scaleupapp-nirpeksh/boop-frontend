import SwiftUI

struct GameHistoryView: View {
    let matchId: String
    let games: [GameSummary]

    @State private var selectedType: String? = nil
    @State private var selectedGameId: String? = nil

    private var filteredGames: [GameSummary] {
        guard let type = selectedType else { return games }
        return games.filter { $0.gameType == type }
    }

    private var gameTypes: [String] {
        Array(Set(games.map(\.gameType))).sorted()
    }

    private var typeBreakdown: [(key: String, value: Int)] {
        Dictionary(grouping: games, by: \.gameType)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                masthead
                breakdownSection
                filterChips
                gamesList
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Game History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { selectedGameId != nil },
            set: { if !$0 { selectedGameId = nil } }
        )) {
            if let gameId = selectedGameId {
                GameSessionView(gameId: gameId)
            }
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "History")
            Text("\(games.count) played")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Breakdown (hairline rows)

    @ViewBuilder
    private var breakdownSection: some View {
        if !typeBreakdown.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                EyebrowLabel(text: "By Game")
                    .padding(.bottom, BoopSpacing.sm)

                ForEach(typeBreakdown, id: \.key) { type, count in
                    let option = GameTypeOption(rawValue: type)
                    HairlineRow(option?.label ?? type) {
                        Text("\(count)")
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    // MARK: - Filter chips (hairline)

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BoopSpacing.sm) {
                filterChip("All", isSelected: selectedType == nil) {
                    selectedType = nil
                }

                ForEach(gameTypes, id: \.self) { type in
                    let option = GameTypeOption(rawValue: type)
                    filterChip(option?.label ?? type, isSelected: selectedType == type) {
                        selectedType = type
                    }
                }
            }
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textMuted)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .stroke(isSelected ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Games list (hairline)

    private var gamesList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if filteredGames.isEmpty {
                Text("No games of this type yet")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .padding(.vertical, BoopSpacing.md)
            } else {
                ForEach(filteredGames) { game in
                    Button {
                        selectedGameId = game.gameId
                    } label: {
                        gameHistoryRow(game)
                    }
                    .buttonStyle(.plain)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func gameHistoryRow(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)
        let title = option?.label ?? game.gameType.replacingOccurrences(of: "_", with: " ").capitalized

        return VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    HStack(spacing: 6) {
                        Text("\(game.totalRounds) rounds".uppercased())
                        if let completedAt = game.completedAt {
                            Text("·")
                            Text(completedAt.formatted(date: .abbreviated, time: .shortened).uppercased())
                        }
                    }
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}
