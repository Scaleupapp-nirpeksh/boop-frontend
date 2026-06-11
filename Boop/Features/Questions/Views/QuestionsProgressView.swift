import SwiftUI

struct QuestionsProgressView: View {
    @State private var viewModel = QuestionsProgressViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                if let progress = viewModel.progress {
                    summary(progress)
                    dimensionList(progress)
                } else if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.error)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .navigationTitle("Question Progress")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Summary (eyebrow + headline count + hairline progress to ready)

    private func summary(_ progress: QuestionsProgressResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Answered", color: BoopColors.accentColor)
                Spacer()
                Text("\(progress.totalAnswered) / \(progress.readyThreshold)")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
            }

            AccentRule()

            Text("\(progress.totalAnswered) answered")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)

            Text(progress.isReady
                 ? "Profile threshold reached."
                 : "\(max(progress.readyThreshold - progress.totalAnswered, 0)) more to reach ready.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            HairlineProgress(progress: Double(progress.totalAnswered) / Double(max(progress.readyThreshold, 1)))
                .padding(.top, BoopSpacing.xxs)
        }
    }

    // MARK: - Per-dimension breakdown (hairline rows)

    private func dimensionList(_ progress: QuestionsProgressResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "By dimension", color: BoopColors.textMuted)

            VStack(spacing: 0) {
                ForEach(progress.dimensions.keys.sorted(), id: \.self) { key in
                    if let dimension = progress.dimensions[key] {
                        dimensionRow(key: key, dimension: dimension)
                    }
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func dimensionRow(key: String, dimension: QuestionDimensionProgress) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                HStack {
                    Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(dimension.answered) / \(dimension.unlocked)")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                }

                HairlineProgress(progress: Double(dimension.answered) / Double(max(dimension.unlocked, 1)))
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}
