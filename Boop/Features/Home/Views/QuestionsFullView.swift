import SwiftUI

/// Standalone questions view used from the home page sheet.
/// Unlike onboarding QuestionsView, this doesn't limit to 6 and doesn't
/// trigger profile stage completion — it's for ongoing daily questions.
struct QuestionsFullView: View {
    @State private var viewModel = QuestionsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Background upload indicator
            if viewModel.pendingVoiceUploads > 0 {
                HStack(spacing: BoopSpacing.sm) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(BoopColors.accentColor)
                    Text("UPLOADING \(viewModel.pendingVoiceUploads) VOICE ANSWER\(viewModel.pendingVoiceUploads > 1 ? "S" : "")")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                    Spacer()
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.sm)
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(BoopColors.accentColor)
                Spacer()
            } else if let question = viewModel.currentQuestion {
                questionContent(question)
            } else {
                allDoneView
            }
        }
        .boopBackground()
        .task {
            viewModel.isDeepenMode = true
            await viewModel.fetchAllQuestions()
        }
    }

    private func questionContent(_ question: Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                questionHeader
                questionPrompt(question)

                // Answer mode toggle for text questions
                if question.questionType == .text {
                    answerModeToggle
                }

                // Answer area
                if viewModel.isVoiceMode && question.questionType == .text {
                    voiceAnswerArea
                } else {
                    answerArea(for: question)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
                }

                BoopButton(
                    title: viewModel.isVoiceMode ? "Submit Voice Answer" : "Continue",
                    isLoading: viewModel.isSubmitting,
                    isDisabled: !viewModel.canSubmitAnswer
                ) {
                    Task { await viewModel.submitAnswer() }
                }
                .padding(.top, BoopSpacing.xs)
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .onTapGesture { hideKeyboard() }
    }

    // MARK: - Header (eyebrow + progress counter + hairline progress)

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Question \(String(format: "%02d", viewModel.currentIndex + 1))",
                             color: BoopColors.accentColor)
                Spacer()
                Text("\(String(format: "%02d", viewModel.currentIndex + 1)) / \(String(format: "%02d", max(viewModel.questions.count, 1)))")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
            }

            HairlineProgress(progress: Double(viewModel.currentIndex + 1) / Double(max(viewModel.questions.count, 1)))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
        }
    }

    // MARK: - Prompt (rule + dimension + cinematic question)

    private func questionPrompt(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            AccentRule()
            EyebrowLabel(text: question.dimensionDisplayName, color: BoopColors.textMuted)
            Text(question.questionText)
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Answer Mode Toggle (voice option as a tracked text line)

    private var answerModeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleVoiceMode()
            }
        } label: {
            HStack(spacing: BoopSpacing.sm) {
                Text(viewModel.isVoiceMode ? "— OR ANSWER BY TYPING" : "— OR ANSWER BY VOICE")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.accentColor)
                Spacer()
                Image(systemName: viewModel.isVoiceMode ? "keyboard" : "mic")
                    .font(.system(size: 13, weight: .thin))
                    .foregroundStyle(BoopColors.accentColor)
            }
        }
        .buttonStyle(.plain)
    }

    private var voiceAnswerArea: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            BoopVoiceRecorder(state: viewModel.voiceRecorder)

            Text("Record your answer — transcription happens automatically")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func answerArea(for question: Question) -> some View {
        switch question.questionType {
        case .text:
            BoopTextField(
                label: "Your answer",
                text: $viewModel.textAnswer,
                placeholder: "Share your thoughts...",
                isMultiline: true,
                maxLength: question.characterLimit ?? 500
            )

        case .singleChoice:
            if let options = question.options, !options.isEmpty {
                VStack(spacing: 0) {
                    ForEach(options, id: \.self) { option in
                        optionRow(option,
                                  isSelected: viewModel.selectedChoices.contains(option),
                                  isMulti: false) {
                            viewModel.toggleChoice(option, multiSelect: false)
                        }
                    }
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                }
            }

        case .multipleChoice:
            if let options = question.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "Select all that apply", color: BoopColors.textMuted)
                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            optionRow(option,
                                      isSelected: viewModel.selectedChoices.contains(option),
                                      isMulti: true) {
                                viewModel.toggleChoice(option, multiSelect: true)
                            }
                        }
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                    }
                }
            }
        }
    }

    /// Hairline option row with a coral radio (single) or coral check (multi).
    private func optionRow(_ text: String, isSelected: Bool, isMulti: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
                HStack(spacing: BoopSpacing.md) {
                    OptionIndicator(isSelected: isSelected, isMulti: isMulti)
                    Text(text)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(isSelected ? BoopColors.textPrimary : BoopColors.textSecondary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: BoopSpacing.sm)
                }
                .padding(.vertical, BoopSpacing.md)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var allDoneView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "All Caught Up", color: BoopColors.accentColor)
                AccentRule()
                Text("All caught up.")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                Text("No new questions right now. Check back tomorrow.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }
}
