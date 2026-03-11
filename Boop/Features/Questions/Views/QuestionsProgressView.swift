import SwiftUI

struct QuestionsProgressView: View {
    @State private var viewModel = QuestionsProgressViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                if let progress = viewModel.progress {
                    summaryCard(progress)

                    ForEach(progress.dimensions.keys.sorted(), id: \.self) { key in
                        if let dimension = progress.dimensions[key] {
                            BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
                                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                                    HStack {
                                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(BoopTypography.callout)
                                            .foregroundStyle(BoopColors.textPrimary)
                                        Spacer()
                                        Text("\(dimension.answered)/\(dimension.unlocked)")
                                            .font(BoopTypography.caption)
                                            .foregroundStyle(BoopColors.textSecondary)
                                    }

                                    ProgressView(value: Double(dimension.answered), total: Double(max(dimension.unlocked, 1)))
                                        .tint(BoopColors.dimensionColor(for: key))
                                }
                            }
                        }
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.error)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Question Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func summaryCard(_ progress: QuestionsProgressResponse) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("\(progress.totalAnswered) answered")
                    .font(BoopTypography.title1)
                    .foregroundStyle(BoopColors.textPrimary)

                Text(progress.isReady ? "Profile threshold reached." : "\(max(progress.readyThreshold - progress.totalAnswered, 0)) more to reach ready.")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)

                ProgressView(value: Double(progress.totalAnswered), total: Double(progress.readyThreshold))
                    .tint(progress.isReady ? BoopColors.success : BoopColors.primary)
            }
        }
    }
}
