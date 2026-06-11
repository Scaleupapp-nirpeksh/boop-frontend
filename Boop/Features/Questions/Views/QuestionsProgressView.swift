import SwiftUI

struct QuestionsProgressView: View {
    @State private var viewModel = QuestionsProgressViewModel()
    @State private var showAnswerSheet = false
    /// Drives the ring trim animation on appear.
    @State private var ringFraction: Double = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                if let progress = viewModel.progress {
                    header
                    confidenceRing(progress)
                    coverage(progress)
                    BoopButton(title: "Answer more") {
                        showAnswerSheet = true
                    }
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
            .padding(.top, BoopSpacing.xl)
            // Clear the floating tab bar so the last coverage row stays visible.
            .padding(.bottom, 100)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .navigationTitle("Deepen your profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            animateRing()
        }
        .sheet(isPresented: $showAnswerSheet) {
            NavigationStack {
                QuestionsFullView()
                    .navigationTitle("Deepen your profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showAnswerSheet = false }
                        }
                    }
            }
            .onDisappear {
                Task {
                    await viewModel.load()
                    animateRing()
                }
            }
        }
    }

    private func animateRing() {
        guard let progress = viewModel.progress else { return }
        let target = viewModel.confidenceFraction(progress)
        ringFraction = 0
        withAnimation(.easeOut(duration: 0.9)) {
            ringFraction = target
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Your profile", color: BoopColors.accentColor)
            Text("Deepen to match better")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Match-confidence ring (centerpiece)

    private func confidenceRing(_ progress: QuestionsProgressResponse) -> some View {
        let percent = viewModel.confidencePercent(progress)
        return VStack(spacing: BoopSpacing.lg) {
            // Only the number lives inside the ring — the tracked eyebrow is
            // wider than the ring's interior, so it sits below instead.
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: ringFraction)
                    .stroke(BoopColors.accentColor,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(percent)%")
                    .font(BoopTypography.cineDisplayXL)
                    .foregroundStyle(BoopColors.textPrimary)
            }
            .frame(width: 150, height: 150)

            VStack(spacing: BoopSpacing.xs) {
                EyebrowLabel(text: "Match confidence", color: BoopColors.textMuted)
                Text(viewModel.nudgeText(progress))
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Coverage by dimension (least-covered first)

    private func coverage(_ progress: QuestionsProgressResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Coverage by dimension", color: BoopColors.textMuted)

            VStack(spacing: 0) {
                ForEach(viewModel.sortedDimensions(progress), id: \.key) { entry in
                    dimensionRow(key: entry.key, dimension: entry.value)
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
                    Text(Self.dimensionDisplayName(key))
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(dimension.answered) / \(dimension.unlocked)")
                        .font(BoopTypography.cineCaption)
                        .tracking(1)
                        .foregroundStyle(BoopColors.textMuted)
                }

                HairlineProgress(progress: Double(dimension.answered) / Double(max(dimension.unlocked, 1)))
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    /// Canonical dimension display names (mirrors `Question.dimensionDisplayName`).
    static func dimensionDisplayName(_ key: String) -> String {
        switch key {
        case "emotional_vulnerability": return "Emotional Vulnerability"
        case "attachment_patterns": return "Attachment Patterns"
        case "life_vision": return "Life Vision"
        case "conflict_resolution": return "Conflict Resolution"
        case "love_expression": return "Love Expression"
        case "intimacy_comfort": return "Intimacy Comfort"
        case "lifestyle_rhythm": return "Lifestyle Rhythm"
        case "growth_mindset": return "Growth Mindset"
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}
