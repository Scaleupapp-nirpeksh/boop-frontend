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
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            header(data)
            questionsList(data)
        }
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

    // MARK: - Header

    private func header(_ data: AnswerSyncResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "\(data.totalCommon) questions you've both answered", color: BoopColors.accentColor)
            AccentRule()
            Text(data.verdict)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Where you click — and where you're a little different. Each question shows how in sync the two of you are.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Per-question cards (you vs them + gradient meter)

    private func questionsList(_ data: AnswerSyncResponse) -> some View {
        VStack(spacing: BoopSpacing.md) {
            ForEach(data.questions.sorted { syncPercent($0.syncLevel) > syncPercent($1.syncLevel) }) { q in
                questionCard(q)
            }
        }
    }

    private func questionCard(_ q: AnswerSyncQuestion) -> some View {
        let pct = syncPercent(q.syncLevel)
        return VStack(alignment: .leading, spacing: BoopSpacing.md) {
            Text(q.questionText)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                answerRow(label: "You", text: q.summaryYou, accent: BoopColors.accentColor)
                answerRow(label: partnerName, text: q.summaryThem, accent: Color(hex: "6E84E6"))
            }

            compatMeter(pct: pct, level: q.syncLevel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.lg, shadow: false)
    }

    private func answerRow(label: String, text: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(1.5)
                .foregroundStyle(accent)
                .frame(width: 72, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(text)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func compatMeter(pct: Int, level: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BoopColors.hairline)
                    Capsule()
                        .fill(LinearGradient(colors: meterColors(pct), startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(pct) / 100))
                }
            }
            .frame(height: 8)
            HStack {
                Text(syncLabel(level))
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
                Spacer()
                Text("\(pct)% in sync")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(meterColors(pct).last ?? BoopColors.accentColor)
            }
        }
        .padding(.top, BoopSpacing.xxs)
    }

    private func syncPercent(_ level: String) -> Int {
        switch level {
        case "highly_in_sync": return 95
        case "in_sync": return 78
        case "neutral_ground": return 55
        case "different_views": return 32
        case "poles_apart": return 12
        default: return 50
        }
    }

    private func syncLabel(_ level: String) -> String {
        switch level {
        case "highly_in_sync": return "Totally in sync"
        case "in_sync": return "In sync"
        case "neutral_ground": return "Some overlap"
        case "different_views": return "Different takes"
        case "poles_apart": return "Poles apart"
        default: return "In common"
        }
    }

    private func meterColors(_ pct: Int) -> [Color] {
        if pct >= 85 { return [Color(hex: "FFB07A"), BoopColors.accentColor] }
        if pct >= 65 { return [Color(hex: "FFC07A"), Color(hex: "FF8A6B")] }
        if pct >= 45 { return [Color(hex: "C9A7EA"), Color(hex: "9B7BC0")] }
        return [Color(hex: "9DB6FF"), Color(hex: "6E84E6")]
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
