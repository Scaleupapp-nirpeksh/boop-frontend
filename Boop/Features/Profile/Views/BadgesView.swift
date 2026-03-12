import SwiftUI

struct BadgesView: View {
    @State private var viewModel = BadgesViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                // Summary header
                if !viewModel.badges.isEmpty {
                    summaryCard
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(viewModel.categories, id: \.self) { category in
                        categorySection(category)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private var summaryCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                HStack(spacing: BoopSpacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.earnedBadges.count)")
                            .font(BoopTypography.title1)
                            .foregroundStyle(BoopColors.primary)
                        Text("Earned")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.badges.count)")
                            .font(BoopTypography.title1)
                            .foregroundStyle(BoopColors.textMuted)
                        Text("Total")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(BoopColors.surfaceSecondary)
                            .frame(height: 8)

                        Capsule()
                            .fill(BoopColors.primaryGradient)
                            .frame(
                                width: viewModel.badges.isEmpty ? 0 : geo.size.width * CGFloat(viewModel.earnedBadges.count) / CGFloat(viewModel.badges.count),
                                height: 8
                            )
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private func categorySection(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text(categoryDisplayName(category))
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: BoopSpacing.sm),
                GridItem(.flexible(), spacing: BoopSpacing.sm),
            ], spacing: BoopSpacing.sm) {
                ForEach(viewModel.badgesForCategory(category)) { badge in
                    badgeCard(badge)
                }
            }
        }
    }

    private func badgeCard(_ badge: BadgeCatalogItem) -> some View {
        BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
            VStack(spacing: BoopSpacing.sm) {
                Text(badge.emoji)
                    .font(.system(size: 32))
                    .opacity(badge.earned ? 1 : 0.3)

                Text(badge.title)
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(badge.earned ? BoopColors.textPrimary : BoopColors.textMuted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(badge.description)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if badge.earned, let earnedAt = badge.earnedAt {
                    Text("Earned \(earnedAt.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.success)
                } else {
                    Text("Locked")
                        .font(BoopTypography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(BoopColors.textMuted)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, 2)
                        .background(BoopColors.surfaceSecondary)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
        }
        .opacity(badge.earned ? 1 : 0.65)
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
