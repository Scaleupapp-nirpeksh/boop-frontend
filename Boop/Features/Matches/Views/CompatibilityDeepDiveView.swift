import SwiftUI

struct CompatibilityDeepDiveView: View {
    let matchId: String

    @State private var viewModel: CompatibilityDeepDiveViewModel

    init(matchId: String) {
        self.matchId = matchId
        _viewModel = State(initialValue: CompatibilityDeepDiveViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading && viewModel.data == nil {
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .fill(BoopColors.surfaceSecondary)
                            .frame(height: 1)
                            .padding(.vertical, BoopSpacing.xl)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.xl)
            } else if let data = viewModel.data {
                VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                    overallSection(data: data)

                    if let strongest = viewModel.strongestDimension {
                        calloutSection(title: "Strongest bond", dimension: strongest, accent: BoopColors.success)
                    }

                    if let growth = viewModel.growthDimension {
                        calloutSection(title: "Growth opportunity", dimension: growth, accent: BoopColors.accentColor)
                    }

                    dimensionBreakdownSection(viewModel.sortedDimensions)
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.xl)
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .boopBackground()
        .navigationTitle("Compatibility")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - Overall (editorial hero + radar bars)

    private func overallSection(data: CompatibilityDeepDiveResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    EyebrowLabel(text: "Compatibility", color: BoopColors.accentColor)
                    Spacer()
                    if let tier = data.matchTier {
                        Text((tier + " match").uppercased())
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }

                AccentRule()

                HStack(alignment: .firstTextBaseline, spacing: BoopSpacing.sm) {
                    Text("\(data.compatibilityScore ?? 0)")
                        .font(BoopTypography.cineDisplayXL)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("%")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textSecondary)
                    Spacer()
                }

                Text("\(data.user1Name ?? "You")  &  \(data.user2Name ?? "Match")")
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textSecondary)

                if let narrative = data.overallNarrative {
                    Text(narrative)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, BoopSpacing.xs)
                }
            }

            // Mini radar-style bars (typeset % + thin coral bars)
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                EyebrowLabel(text: "At a glance")

                VStack(spacing: BoopSpacing.sm) {
                    ForEach(data.dimensions) { dim in
                        HStack(spacing: BoopSpacing.sm) {
                            Text(dim.label)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .frame(width: 120, alignment: .leading)

                            HairlineProgress(progress: Double(dim.score ?? 0) / 100.0)

                            Text("\(dim.score ?? 0)")
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(BoopColors.textPrimary)
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Callout (strongest / growth)

    private func calloutSection(title: String, dimension: CompatibilityDimension, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: title, color: accent)
            AccentRule()

            HStack(alignment: .firstTextBaseline) {
                Text(dimension.label)
                    .font(BoopTypography.cineHeadline)
                    .foregroundStyle(BoopColors.textPrimary)
                Spacer()
                Text("\(dimension.score ?? 0)%")
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(accent)
            }

            if let narrative = dimension.narrative {
                Text(narrative)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Dimension Breakdown (hairline rows)

    private func dimensionBreakdownSection(_ dimensions: [CompatibilityDimension]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Dimension breakdown")

            VStack(spacing: 0) {
                ForEach(dimensions) { dimension in
                    dimensionRow(dimension)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func dimensionRow(_ dimension: CompatibilityDimension) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(dimension.label)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(dimension.score ?? 0)")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(BoopColors.textPrimary)
                }

                HairlineProgress(progress: Double(dimension.score ?? 0) / 100.0)

                if let narrative = dimension.narrative {
                    Text(narrative)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, BoopSpacing.md)
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
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }
}
