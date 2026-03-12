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
                VStack(spacing: BoopSpacing.lg) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: BoopRadius.xl)
                            .fill(BoopColors.surfaceSecondary)
                            .frame(height: 120)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.lg)
            } else if let data = viewModel.data {
                VStack(spacing: BoopSpacing.lg) {
                    overallCard(data: data)

                    if let strongest = viewModel.strongestDimension {
                        calloutCard(
                            title: "Strongest bond",
                            dimension: strongest,
                            tintColor: BoopColors.success
                        )
                    }

                    if let growth = viewModel.growthDimension {
                        calloutCard(
                            title: "Growth opportunity",
                            dimension: growth,
                            tintColor: BoopColors.accent
                        )
                    }

                    ForEach(viewModel.sortedDimensions) { dimension in
                        dimensionCard(dimension: dimension)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.lg)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: BoopSpacing.md) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(BoopColors.error)
                    Text(error)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(BoopSpacing.xl)
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

    // MARK: - Overall Card

    private func overallCard(data: CompatibilityDeepDiveResponse) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(data.user1Name ?? "You") & \(data.user2Name ?? "Match")")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        if let tier = data.matchTier {
                            Text(tier.capitalized + " match")
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.secondary)
                        }
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("\(data.compatibilityScore ?? 0)%")
                            .font(BoopTypography.title1)
                            .foregroundStyle(BoopColors.primary)
                        Text("overall")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }

                if let narrative = data.overallNarrative {
                    Text(narrative)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                // Mini radar-style bars
                VStack(spacing: BoopSpacing.xs) {
                    ForEach(data.dimensions) { dim in
                        HStack(spacing: BoopSpacing.sm) {
                            Text(dim.label)
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .frame(width: 110, alignment: .leading)

                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(BoopColors.surfaceSecondary)
                                    Capsule()
                                        .fill(Color(hex: dim.color))
                                        .frame(width: proxy.size.width * CGFloat(dim.score ?? 0) / 100.0)
                                }
                            }
                            .frame(height: 6)

                            Text("\(dim.score ?? 0)%")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color(hex: dim.color))
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Callout Card

    private func calloutCard(title: String, dimension: CompatibilityDimension, tintColor: Color) -> some View {
        HStack(spacing: BoopSpacing.md) {
            Image(systemName: dimension.icon)
                .font(.system(size: 22))
                .foregroundStyle(tintColor)
                .frame(width: 44, height: 44)
                .background(tintColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BoopTypography.caption)
                    .foregroundStyle(tintColor)
                    .fontWeight(.semibold)
                Text(dimension.label)
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(BoopColors.textPrimary)
                if let narrative = dimension.narrative {
                    Text(narrative)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text("\(dimension.score ?? 0)%")
                .font(BoopTypography.title3)
                .foregroundStyle(tintColor)
        }
        .padding(BoopSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .fill(tintColor.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                        .stroke(tintColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Dimension Card

    private func dimensionCard(dimension: CompatibilityDimension) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(spacing: BoopSpacing.sm) {
                    Image(systemName: dimension.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: dimension.color))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: dimension.color).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text(dimension.label)
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    Text("\(dimension.score ?? 0)%")
                        .font(BoopTypography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: dimension.color))
                }

                // Score bar
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(BoopColors.surfaceSecondary)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: dimension.color).opacity(0.7), Color(hex: dimension.color)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * CGFloat(dimension.score ?? 0) / 100.0)
                    }
                }
                .frame(height: 8)

                if let narrative = dimension.narrative {
                    Text(narrative)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }
}
