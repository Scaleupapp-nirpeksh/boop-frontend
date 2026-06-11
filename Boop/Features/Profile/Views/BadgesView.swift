import SwiftUI

struct BadgesView: View {
    @State private var viewModel = BadgesViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                if !viewModel.badges.isEmpty {
                    summary
                }

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
                    ForEach(viewModel.categories, id: \.self) { category in
                        categorySection(category)
                    }
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

    // MARK: - Summary (earned / total + hairline progress)

    private var summary: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Earned", color: BoopColors.accentColor)
                Spacer()
                Text("\(viewModel.earnedBadges.count) / \(viewModel.badges.count)")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
            }

            AccentRule()

            Text("\(viewModel.earnedBadges.count) earned")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)

            HairlineProgress(
                progress: viewModel.badges.isEmpty
                    ? 0
                    : Double(viewModel.earnedBadges.count) / Double(viewModel.badges.count)
            )
            .padding(.top, BoopSpacing.xxs)
        }
    }

    // MARK: - Category section (eyebrow + hairline badge rows)

    private func categorySection(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: categoryDisplayName(category))

            VStack(spacing: 0) {
                ForEach(viewModel.badgesForCategory(category)) { badge in
                    badgeRow(badge)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func badgeRow(_ badge: BadgeCatalogItem) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(alignment: .top, spacing: BoopSpacing.md) {
                // Earned mark — thin coral circle; locked — hollow muted ring. No emoji.
                Image(systemName: badge.earned ? "circle.fill" : "circle")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundStyle(badge.earned ? BoopColors.accentColor : BoopColors.textMuted)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                    Text(badge.title)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(badge.earned ? BoopColors.textPrimary : BoopColors.textMuted)

                    Text(badge.description)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(badge.earned ? BoopColors.textSecondary : BoopColors.textMuted)
                }

                Spacer(minLength: BoopSpacing.sm)

                if badge.earned, let earnedAt = badge.earnedAt {
                    Text(earnedAt.formatted(.dateTime.month(.abbreviated).day()).uppercased())
                        .font(BoopTypography.cineCaption)
                        .tracking(1)
                        .foregroundStyle(BoopColors.accentColor)
                        .padding(.top, 2)
                } else {
                    Text("LOCKED")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, BoopSpacing.md)
            .opacity(badge.earned ? 1 : 0.7)
        }
    }

    private func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "profile": return "Profile"
        case "questions": return "Questions"
        case "engagement": return "Engagement"
        case "games": return "Games"
        case "connections": return "Connections"
        case "special": return "Special"
        default: return category.capitalized
        }
    }
}
