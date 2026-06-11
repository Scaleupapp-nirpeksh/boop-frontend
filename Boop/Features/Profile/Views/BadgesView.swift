import SwiftUI

struct BadgesView: View {
    @State private var viewModel = BadgesViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: BoopSpacing.md),
        GridItem(.flexible(), spacing: BoopSpacing.md),
        GridItem(.flexible(), spacing: BoopSpacing.md)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                // Header
                header

                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    trophyShelf
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Achievements")

            AccentRule()

            HStack(alignment: .lastTextBaseline, spacing: BoopSpacing.xs) {
                Text("\(viewModel.earnedBadges.count)")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("of \(viewModel.badges.count) earned")
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textMuted)
            }

            HairlineProgress(
                progress: viewModel.badges.isEmpty
                    ? 0
                    : Double(viewModel.earnedBadges.count) / Double(viewModel.badges.count)
            )
            .padding(.top, BoopSpacing.xxs)
        }
    }

    // MARK: - Trophy shelf (per-category sub-grids)

    private var trophyShelf: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
            ForEach(viewModel.categories, id: \.self) { category in
                categoryGrid(category)
            }
        }
    }

    private func categoryGrid(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: categoryDisplayName(category))

            LazyVGrid(columns: columns, spacing: BoopSpacing.lg) {
                ForEach(viewModel.badgesForCategory(category)) { badge in
                    BadgeMedallion(badge: badge)
                }
            }
        }
    }

    private func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "profile":     return "Profile"
        case "questions":   return "Questions"
        case "engagement":  return "Engagement"
        case "games":       return "Games"
        case "connections": return "Connections"
        case "special":     return "Special"
        default:            return category.capitalized
        }
    }
}

// MARK: - Badge Medallion

private struct BadgeMedallion: View {
    let badge: BadgeCatalogItem

    private let ringSize: CGFloat = 62
    private let ringLineWidth: CGFloat = 1.5

    var body: some View {
        VStack(spacing: BoopSpacing.xs) {
            ZStack {
                // Track ring (always present)
                Circle()
                    .stroke(BoopColors.hairline, lineWidth: ringLineWidth)
                    .frame(width: ringSize, height: ringSize)

                // Earned ring: full coral; locked: remains track only (dimmed via opacity)
                if badge.earned {
                    Circle()
                        .stroke(BoopColors.accentColor, lineWidth: ringLineWidth)
                        .frame(width: ringSize, height: ringSize)
                }

                // SF Symbol glyph
                Image(systemName: symbolName(for: badge))
                    .font(.system(size: 22, weight: .thin))
                    .foregroundStyle(badge.earned ? BoopColors.accentColor : BoopColors.textMuted)
            }
            .opacity(badge.earned ? 1 : 0.45)

            Text(badge.title)
                .font(BoopTypography.cineCaption)
                .tracking(0.3)
                .foregroundStyle(badge.earned ? BoopColors.textPrimary : BoopColors.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func symbolName(for badge: BadgeCatalogItem) -> String {
        // Key-first specifics
        switch badge.key {
        case _ where badge.key.contains("voice"):      return "waveform"
        case _ where badge.key.contains("streak"):     return "flame"
        case _ where badge.key.contains("photo"):      return "person.crop.square"
        case _ where badge.key.contains("selfie"):     return "person.crop.square"
        case _ where badge.key.contains("heart"):      return "heart"
        case _ where badge.key.contains("match"):      return "heart"
        case _ where badge.key.contains("game"):       return "gamecontroller"
        case _ where badge.key.contains("connect"):    return "heart.circle"
        case _ where badge.key.contains("question"):   return "text.alignleft"
        case _ where badge.key.contains("answer"):     return "text.alignleft"
        case _ where badge.key.contains("profile"):    return "person.crop.square"
        default: break
        }
        // Category fallback
        switch badge.category {
        case "voice":        return "waveform"
        case "questions":    return "text.alignleft"
        case "engagement":   return "waveform"
        case "games":        return "gamecontroller"
        case "profile":      return "person.crop.square"
        case "connections":  return "heart"
        case "special":      return "sparkle"
        default:             return "star"
        }
    }
}
