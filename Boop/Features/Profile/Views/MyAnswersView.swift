import SwiftUI

struct MyAnswersView: View {
    @State private var viewModel = MyAnswersViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.error)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if viewModel.history.isEmpty {
                    emptyState
                } else {
                    summaryCard

                    ForEach(viewModel.groupedByDimension, id: \.key) { group in
                        dimensionSection(key: group.key, items: group.items)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("My Answers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private var summaryCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            HStack(spacing: BoopSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.history.count)")
                        .font(BoopTypography.title1)
                        .foregroundStyle(BoopColors.primary)
                    Text("questions answered")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.groupedByDimension.count)")
                        .font(BoopTypography.title1)
                        .foregroundStyle(BoopColors.secondary)
                    Text("dimensions explored")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }

    private func dimensionSection(key: String, items: [AnswerHistoryItem]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(spacing: BoopSpacing.xs) {
                Circle()
                    .fill(BoopColors.dimensionColor(for: key))
                    .frame(width: 10, height: 10)

                Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("\(items.count)")
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(BoopColors.dimensionColor(for: key))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(BoopColors.dimensionColor(for: key).opacity(0.12))
                    .clipShape(Capsule())
            }

            ForEach(items) { item in
                answerCard(item)
            }
        }
    }

    private func answerCard(_ item: AnswerHistoryItem) -> some View {
        BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                Text(item.questionText)
                    .font(BoopTypography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(BoopColors.textPrimary)

                answerContent(item)

                if let date = item.submittedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
        }
    }

    @ViewBuilder
    private func answerContent(_ item: AnswerHistoryItem) -> some View {
        if let text = item.textAnswer, !text.isEmpty {
            Text(text)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textSecondary)
                .italic()
        } else if let option = item.selectedOption {
            answerChip(option)
        } else if let options = item.selectedOptions, !options.isEmpty {
            FlowLayout(spacing: BoopSpacing.xs) {
                ForEach(options, id: \.self) { option in
                    answerChip(option)
                }
            }
        }
    }

    private func answerChip(_ text: String) -> some View {
        Text(text)
            .font(BoopTypography.footnote)
            .foregroundStyle(BoopColors.secondary)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, BoopSpacing.xxs)
            .background(BoopColors.secondary.opacity(0.1))
            .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: BoopSpacing.md) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 40))
                .foregroundStyle(BoopColors.textMuted)
            Text("No answers yet")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)
            Text("Answer questions to build your personality profile.")
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
