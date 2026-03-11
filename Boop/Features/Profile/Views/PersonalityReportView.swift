import SwiftUI

struct PersonalityReportView: View {
    @State private var viewModel = PersonalityReportViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let analysis = viewModel.analysis {
                    reportContent(analysis)
                } else {
                    noAnalysisView
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Personality Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Report Content

    @ViewBuilder
    private func reportContent(_ analysis: PersonalityAnalysis) -> some View {
        // Preliminary banner
        if viewModel.isPreliminary {
            preliminaryBanner
        }

        // Hero: personality type
        heroCard(analysis)

        // Radar chart
        if !analysis.facets.isEmpty {
            radarSection(analysis.facets)
        }

        // Summary
        summaryCard(analysis.summary)

        // Facet cards
        ForEach(analysis.facets) { facet in
            facetCard(facet)
        }

        // Numerology section
        if let numerology = analysis.numerology {
            numerologyCard(numerology)
        }

        // Next milestone footer
        milestoneFooter
    }

    // MARK: - Hero Card

    private func heroCard(_ analysis: PersonalityAnalysis) -> some View {
        BoopCard(padding: BoopSpacing.xl, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                Text(analysis.personalityType)
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BoopColors.primary, BoopColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                if viewModel.isPreliminary {
                    Text("Preliminary Profile")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.accent)
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, BoopSpacing.xxxs)
                        .background(BoopColors.accent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("Based on \(analysis.questionsAnalyzed) answers")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Radar Section

    private func radarSection(_ facets: [PersonalityFacet]) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(spacing: BoopSpacing.md) {
                Text("Your Profile Shape")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                PersonalityRadarChartView(facets: facets, size: 240)
                    .frame(maxWidth: .infinity)

                // Legend
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: BoopSpacing.xs)], spacing: BoopSpacing.xs) {
                    ForEach(facets) { facet in
                        HStack(spacing: 4) {
                            Text(facet.emoji)
                                .font(.system(size: 12))
                            Text(facet.title)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: String) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 14))
                        .foregroundStyle(BoopColors.primary.opacity(0.5))
                    Text("About You")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                }

                Text(summary)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(4)
            }
        }
    }

    // MARK: - Facet Card

    private func facetCard(_ facet: PersonalityFacet) -> some View {
        BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack {
                    Text(facet.emoji)
                        .font(.system(size: 20))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(facet.title)
                            .font(BoopTypography.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(BoopColors.textPrimary)

                        Text("\(facet.score)/100")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }

                    Spacer()
                }

                // Score bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(BoopColors.surfaceSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [BoopColors.primary, BoopColors.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(facet.score) / 100.0, height: 8)
                    }
                }
                .frame(height: 8)

                Text(facet.description)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Numerology Card

    private func numerologyCard(_ numerology: NumerologyData) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(spacing: BoopSpacing.sm) {
                    Text("Numerology")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()
                }

                HStack(spacing: BoopSpacing.lg) {
                    numberCircle(value: numerology.lifePathNumber, label: "Life Path")

                    if let expr = numerology.expressionNumber {
                        numberCircle(value: expr, label: "Expression")
                    }
                }
                .frame(maxWidth: .infinity)

                if !numerology.description.isEmpty {
                    Text(numerology.description)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(3)
                }

                // Traits as chips
                if !numerology.traits.isEmpty {
                    FlowLayoutNumerology(spacing: BoopSpacing.xs) {
                        ForEach(numerology.traits, id: \.self) { trait in
                            Text(trait)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.accent)
                                .padding(.horizontal, BoopSpacing.sm)
                                .padding(.vertical, BoopSpacing.xxs)
                                .background(BoopColors.accent.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func numberCircle(value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BoopColors.accent.opacity(0.2), BoopColors.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(BoopColors.accent.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 56, height: 56)

                Text("\(value)")
                    .font(.nunito(.extraBold, size: 22))
                    .foregroundStyle(BoopColors.accent)
            }

            Text(label)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
        }
    }

    // MARK: - Preliminary Banner

    private var preliminaryBanner: some View {
        HStack(spacing: BoopSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(BoopColors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Preliminary Analysis")
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Answer \(viewModel.questionsUntilNext) more questions for deeper insights and better matches.")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .stroke(BoopColors.accent.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - No Analysis View

    private var noAnalysisView: some View {
        VStack(spacing: BoopSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(BoopColors.primary.opacity(0.08))
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(BoopColors.primary.opacity(0.5))
            }

            VStack(spacing: BoopSpacing.sm) {
                Text("Personality insights coming soon")
                    .font(BoopTypography.title3)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Answer \(viewModel.questionsUntilNext) more questions to unlock your personality profile.")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }

    // MARK: - Milestone Footer

    private var milestoneFooter: some View {
        Group {
            if viewModel.questionsUntilNext > 0 {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(BoopColors.textMuted)
                    Text("Next update at \(viewModel.nextMilestone) answers (\(viewModel.questionsUntilNext) to go)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.sm)
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: BoopSpacing.md) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(BoopColors.error)
            Text(message)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.error)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// Simple flow layout for numerology traits
private struct FlowLayoutNumerology: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
