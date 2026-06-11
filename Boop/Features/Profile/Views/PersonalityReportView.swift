import SwiftUI

struct PersonalityReportView: View {
    @State private var viewModel = PersonalityReportViewModel()
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let analysis = viewModel.analysis {
                    reportContent(analysis)
                } else {
                    noAnalysisView
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Personality Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .sheet(item: $shareImage) { image in
            ShareSheet(items: [image])
        }
    }

    // MARK: - Share

    private func shareCard(_ analysis: PersonalityAnalysis) {
        shareImage = PersonalityShareCardRenderer.render(analysis)
    }

    // MARK: - Report Content

    @ViewBuilder
    private func reportContent(_ analysis: PersonalityAnalysis) -> some View {
        heroSection(analysis)

        if viewModel.isPreliminary {
            preliminaryNote
        }

        shareButton(analysis)

        if !analysis.facets.isEmpty {
            radarSection(analysis.facets)
        }

        if !analysis.facets.isEmpty {
            facetBreakdownSection(analysis.facets)
        }

        summarySection(analysis.summary)

        if let numerology = analysis.numerology {
            numerologySection(numerology)
        }

        milestoneFooter
    }

    // MARK: - Share button

    private func shareButton(_ analysis: PersonalityAnalysis) -> some View {
        BoopButton(title: "Share card", variant: .outline) {
            shareCard(analysis)
        }
    }

    // MARK: - Hero ("Coded & Rare" — type code, archetype name, essence)

    private func heroSection(_ analysis: PersonalityAnalysis) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            // TYPE 0N (left) · N% RARE (right) — omit either side gracefully when nil.
            HStack(alignment: .firstTextBaseline) {
                if let number = analysis.archetypeNumber {
                    Text(String(format: "TYPE %02d", number))
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                if let rarity = analysis.rarityPercent {
                    Text("\(rarity)% RARE")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
            }

            Text(analysis.archetypeName ?? analysis.personalityType)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let rarity = analysis.rarityPercent {
                Text("Only \(rarity)% of members share this type")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AccentRule()

            if let essence = analysis.essence, !essence.isEmpty {
                Text(essence)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Based on \(analysis.questionsAnalyzed) answers")
                .font(BoopTypography.cineCaption)
                .tracking(1.5)
                .foregroundStyle(BoopColors.textMuted)
        }
    }

    // MARK: - Preliminary note

    private var preliminaryNote: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Preliminary — answer more to sharpen your type")

            Text("Your type recalibrates at \(viewModel.nextMilestone) answers — answer \(viewModel.questionsUntilNext) more.")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textMuted)

            HairlineProgress(
                progress: 1.0 - (Double(viewModel.questionsUntilNext) / Double(max(viewModel.nextMilestone, 1)))
            )
        }
    }

    // MARK: - Radar

    private func radarSection(_ facets: [PersonalityFacet]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            EyebrowLabel(text: "Your profile shape")

            PersonalityRadarChartView(facets: facets, size: 270)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Summary

    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "About you")
            AccentRule()
            Text(summary)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Facet breakdown (hairline rows + thin bars)

    private func facetBreakdownSection(_ facets: [PersonalityFacet]) -> some View {
        let sortedFacets = facets.sorted { $0.score > $1.score }

        return VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Trait breakdown")

            VStack(spacing: 0) {
                ForEach(sortedFacets) { facet in
                    facetRow(facet)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func facetRow(_ facet: PersonalityFacet) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(facet.title)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(facet.score)")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(BoopColors.textPrimary)
                }

                HairlineProgress(progress: Double(facet.score) / 100.0)

                Text(facet.description)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    // MARK: - Numerology (hairline rows)

    private func numerologySection(_ numerology: NumerologyData) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Numerology")

            VStack(spacing: 0) {
                numerologyRow(label: "Life path", value: "\(numerology.lifePathNumber)")

                if let expr = numerology.expressionNumber {
                    numerologyRow(label: "Expression", value: "\(expr)")
                }

                if [11, 22, 33].contains(numerology.lifePathNumber) {
                    numerologyRow(label: "Master number", value: "Yes", accent: true)
                }

                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }

            if !numerology.description.isEmpty {
                Text(numerology.description)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, BoopSpacing.xs)
            }

            if !numerology.traits.isEmpty {
                Text(numerology.traits.joined(separator: "   ·   ").uppercased())
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, BoopSpacing.xxs)
            }
        }
    }

    private func numerologyRow(label: String, value: String, accent: Bool = false) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack {
                Text(label)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(accent ? BoopColors.accentColor : BoopColors.textPrimary)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    // MARK: - No analysis

    private var noAnalysisView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "In progress", color: BoopColors.accentColor)
            AccentRule()
            Text("Your personality profile is being crafted")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Answer \(viewModel.questionsUntilNext) more questions to unlock your unique personality insights.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
    }

    // MARK: - Milestone footer

    @ViewBuilder
    private var milestoneFooter: some View {
        if viewModel.questionsUntilNext > 0 {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
                HStack {
                    Text("Next update at \(viewModel.nextMilestone) answers")
                        .font(BoopTypography.cineCaption)
                        .tracking(1)
                        .foregroundStyle(BoopColors.textSecondary)
                    Spacer()
                    Text("\(viewModel.questionsUntilNext) TO GO")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
                .padding(.vertical, BoopSpacing.md)
            }
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Couldn't load", color: BoopColors.error)
            AccentRule()
            Text(message)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
    }
}
