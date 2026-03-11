import SwiftUI

struct RelationshipInsightsCard: View {
    let insights: RelationshipInsights
    let scores: InsightScores?

    var body: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Relationship insights")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        HStack(spacing: 4) {
                            Image(systemName: insights.source == "ai" ? "sparkles" : "brain")
                                .font(.system(size: 10))
                            Text(insights.source == "ai" ? "AI-powered analysis" : "Pattern-based analysis")
                        }
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.secondary)
                    }
                    Spacer()
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BoopColors.primary.opacity(0.6))
                }

                // Overall summary
                if let summary = insights.overallSummary, !summary.isEmpty {
                    Text(summary)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textPrimary)
                        .padding(BoopSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(BoopColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }

                // Strengths
                if let strengths = insights.strengths, !strengths.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(BoopColors.accent)
                            Text("Your strengths")
                                .font(BoopTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)
                        }

                        ForEach(strengths) { item in
                            insightRow(item, tint: BoopColors.success)
                        }
                    }
                }

                // Growth areas
                if let growthAreas = insights.growthAreas, !growthAreas.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "leaf.fill")
                                .foregroundStyle(BoopColors.secondary)
                            Text("Areas to grow")
                                .font(BoopTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)
                        }

                        ForEach(growthAreas) { item in
                            insightRow(item, tint: BoopColors.warning)
                        }
                    }
                }

                // Game insights
                if let gameInsights = insights.gameInsights, !gameInsights.isEmpty {
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(BoopColors.primary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Game chemistry")
                                .font(BoopTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)
                            Text(gameInsights)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }
                    .padding(BoopSpacing.md)
                    .background(BoopColors.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }

                // Communication style
                if let commStyle = insights.communicationStyle, !commStyle.isEmpty {
                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(BoopColors.secondary)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Communication")
                                .font(BoopTypography.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(BoopColors.textPrimary)
                            Text(commStyle)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }
                    .padding(BoopSpacing.md)
                    .background(BoopColors.secondary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }

                // Next steps
                if let nextSteps = insights.nextSteps, !nextSteps.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        Text("Suggested next steps")
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(BoopColors.textPrimary)

                        ForEach(Array(nextSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: BoopSpacing.xs) {
                                Text("\(index + 1)")
                                    .font(BoopTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 20, height: 20)
                                    .background(BoopColors.primary)
                                    .clipShape(Circle())

                                Text(step)
                                    .font(BoopTypography.footnote)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                        }
                    }
                    .padding(BoopSpacing.md)
                    .background(BoopColors.surfaceWarm)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                }
            }
        }
    }

    private func insightRow(_ item: InsightItem, tint: Color) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Circle()
                .fill(tint)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(item.detail)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }
}

struct RelationshipInsightsLoadingCard: View {
    var body: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                ProgressView()
                    .tint(BoopColors.secondary)
                Text("Analyzing your connection...")
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, BoopSpacing.lg)
        }
    }
}
