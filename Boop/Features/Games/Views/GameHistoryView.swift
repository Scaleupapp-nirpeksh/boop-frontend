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

    private var stats: GameStats {
        let total = games.count
        let typeBreakdown = Dictionary(grouping: games, by: \.gameType).mapValues(\.count)
        return GameStats(totalGames: total, typeBreakdown: typeBreakdown)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                statsCard
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

    private var statsCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Game stats")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(stats.totalGames) played")
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: BoopSpacing.sm) {
                    ForEach(stats.typeBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                        let option = GameTypeOption(rawValue: type)
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(BoopTypography.title3)
                                .foregroundStyle(option?.tint ?? BoopColors.primary)
                            Text(option?.label ?? type)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BoopSpacing.sm)
                        .background((option?.tint ?? BoopColors.primary).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                    }
                }
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BoopSpacing.xs) {
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
            Text(label)
                .font(BoopTypography.caption)
                .foregroundStyle(isSelected ? .white : BoopColors.textPrimary)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.xs)
                .background(isSelected ? BoopColors.primary : BoopColors.surfaceSecondary)
                .clipShape(Capsule())
        }
    }

    private var gamesList: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            if filteredGames.isEmpty {
                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    Text("No games of this type yet")
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            } else {
                ForEach(filteredGames) { game in
                    Button {
                        selectedGameId = game.gameId
                    } label: {
                        gameHistoryCard(game)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func gameHistoryCard(_ game: GameSummary) -> some View {
        let option = GameTypeOption(rawValue: game.gameType)

        return BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: BoopSpacing.xs) {
                            Circle()
                                .fill(option?.tint ?? BoopColors.primary)
                                .frame(width: 8, height: 8)
                            Text(option?.label ?? game.gameType)
                                .font(BoopTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)
                        }

                        if let completedAt = game.completedAt {
                            Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("\(game.totalRounds) rounds")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.success)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            }
        }
    }
}

private struct GameStats {
    let totalGames: Int
    let typeBreakdown: [String: Int]
}
