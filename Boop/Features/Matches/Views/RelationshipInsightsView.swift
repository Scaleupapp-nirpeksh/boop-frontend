import SwiftUI

struct RelationshipInsightsCard: View {
    let insights: RelationshipInsights
    let scores: InsightScores?

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                EyebrowLabel(text: "Relationship insights", color: BoopColors.accentColor)
                Text(insights.source == "ai" ? "AI-powered analysis" : "Pattern-based analysis")
                    .font(BoopTypography.cineCaption)
                    .tracking(1)
                    .foregroundStyle(BoopColors.textSecondary)
            }

            AccentRule()

            // Overall summary
            if let summary = insights.overallSummary, !summary.isEmpty {
                Text(summary)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Strengths
            if let strengths = insights.strengths, !strengths.isEmpty {
                insightItemSection(title: "Your strengths", items: strengths)
            }

            // Growth areas
            if let growthAreas = insights.growthAreas, !growthAreas.isEmpty {
                insightItemSection(title: "Areas to grow", items: growthAreas)
            }

            // Game insights
            if let gameInsights = insights.gameInsights, !gameInsights.isEmpty {
                narrativeSection(title: "Game chemistry", body: gameInsights)
            }

            // Communication style
            if let commStyle = insights.communicationStyle, !commStyle.isEmpty {
                narrativeSection(title: "Communication", body: commStyle)
            }

            // Next steps
            if let nextSteps = insights.nextSteps, !nextSteps.isEmpty {
                nextStepsSection(nextSteps)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    // MARK: - Sections

    private func insightItemSection(title: String, items: [InsightItem]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: title)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    insightRow(item)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func insightRow(_ item: InsightItem) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                Text(item.title)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(item.detail)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private func narrativeSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: title)
            Text(body)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func nextStepsSection(_ steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Suggested next steps")

            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 0) {
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                        HStack(alignment: .firstTextBaseline, spacing: BoopSpacing.sm) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(BoopColors.accentColor)
                                .frame(width: 22, alignment: .leading)
                            Text(step)
                                .font(BoopTypography.cineBodyLight)
                                .foregroundStyle(BoopColors.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, BoopSpacing.md)
                    }
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }
}

struct RelationshipInsightsLoadingCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Relationship insights", color: BoopColors.accentColor)
            AccentRule()
            HStack(spacing: BoopSpacing.sm) {
                ProgressView()
                    .tint(BoopColors.accentColor)
                Text("Analyzing your connection")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }
}
