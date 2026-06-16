import SwiftUI

struct AnswerSyncView: View {
    let matchId: String
    let partnerName: String

    @State private var viewModel: AnswerSyncViewModel

    init(matchId: String, partnerName: String) {
        self.matchId = matchId
        self.partnerName = partnerName
        _viewModel = State(initialValue: AnswerSyncViewModel(matchId: matchId))
    }

    /// Used by debug harnesses / previews to inject a preloaded view model.
    init(matchId: String, partnerName: String, viewModel: AnswerSyncViewModel) {
        self.matchId = matchId
        self.partnerName = partnerName
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
        }
        .boopBackground()
        .navigationTitle("How you answer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.data == nil {
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.data == nil {
            loadingView
        } else if let data = viewModel.data {
            if data.totalCommon == 0 {
                emptyView
            } else {
                loadedView(data)
            }
        } else if let error = viewModel.errorMessage {
            errorView(error)
        } else {
            emptyView
        }
    }

    // MARK: - Loaded

    private func loadedView(_ data: AnswerSyncResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
            header(data)
            bucketList(data)

            if let selected = viewModel.selectedBucket {
                expandedBucket(selected, data: data)
            }
        }
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedBucket)
    }

    // MARK: - Header (eyebrow + verdict + subtitle + spectrum)

    private func header(_ data: AnswerSyncResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "\(data.totalCommon) questions, both answered", color: BoopColors.accentColor)

            AccentRule()

            Text(data.verdict)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("How your answers line up across the questions you've both shared.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            spectrumBar(data)
                .padding(.top, BoopSpacing.xs)
        }
    }

    /// A horizontal spectrum: one rectangle per non-zero bucket, width proportional to count.
    private func spectrumBar(_ data: AnswerSyncResponse) -> some View {
        let segments = data.buckets.filter { $0.count > 0 }
        let total = max(1, segments.reduce(0) { $0 + $1.count })
        return GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(segments) { bucket in
                    Rectangle()
                        .fill(syncColor(bucket.key))
                        .frame(width: max(3, (CGFloat(bucket.count) / CGFloat(total)) * (geo.size.width - CGFloat(max(0, segments.count - 1)) * 2)))
                }
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    // MARK: - Bucket list (5 tappable rows)

    private func bucketList(_ data: AnswerSyncResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Where you land")

            VStack(spacing: 0) {
                ForEach(data.buckets) { bucket in
                    bucketRow(bucket)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func bucketRow(_ bucket: AnswerSyncBucket) -> some View {
        let isEmpty = bucket.count == 0
        let isSelected = viewModel.selectedBucket == bucket.key
        return Button {
            guard !isEmpty else { return }
            viewModel.selectedBucket = isSelected ? nil : bucket.key
        } label: {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
                HStack(spacing: BoopSpacing.sm) {
                    Circle()
                        .fill(syncColor(bucket.key))
                        .frame(width: 10, height: 10)

                    Text(bucket.label)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    Text("\(bucket.count)")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(BoopColors.textPrimary)

                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                        .opacity(isEmpty ? 0 : 1)
                }
                .padding(.vertical, BoopSpacing.md)
            }
            .opacity(isEmpty ? 0.4 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isEmpty)
    }

    // MARK: - Expanded bucket (question cards)

    @ViewBuilder
    private func expandedBucket(_ key: String, data: AnswerSyncResponse) -> some View {
        let bucket = data.buckets.first(where: { $0.key == key })
        let questions = viewModel.questions(in: key)
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: bucket?.label ?? humanize(key), color: syncColor(key))

            if questions.isEmpty {
                Text("No detail to show for these yet.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BoopSpacing.lg)
                    .boopCard(radius: BoopRadius.lg, shadow: false)
            } else {
                ForEach(questions) { question in
                    questionCard(question, bucketLabel: bucket?.label ?? humanize(key))
                }
            }
        }
    }

    private func questionCard(_ question: AnswerSyncQuestion, bucketLabel: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            Text("\(bucketLabel) · \(humanize(question.category))")
                .font(BoopTypography.cineCaption)
                .tracking(1)
                .foregroundStyle(BoopColors.textMuted)

            Text(question.questionText)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                summaryRow(label: "You", text: question.summaryYou, accent: BoopColors.accentColor)
                summaryRow(label: partnerName.uppercased(), text: question.summaryThem, accent: BoopColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.lg, shadow: false)
    }

    private func summaryRow(label: String, text: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Text(label)
                .font(BoopTypography.cineLabel)
                .tracking(1.5)
                .foregroundStyle(accent)
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(text)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - States

    private var loadingView: some View {
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
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Not enough yet")
            AccentRule()
            Text("Answer a few more shared questions")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Once you've both answered the same questions, we'll show how your views line up here.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

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

    // MARK: - Helpers

    private func humanize(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Coral → muted colour ramp keyed by sync level.
    private func syncColor(_ key: String) -> Color {
        switch key {
        case "highly_in_sync": return BoopColors.accentColor
        case "in_sync": return Color(hex: "FF8A6B")
        case "neutral_ground": return Color(hex: "8A7F9E")
        case "different_views": return Color(hex: "5B6B8D")
        case "poles_apart": return Color(hex: "3A3550")
        default: return BoopColors.textMuted
        }
    }
}
