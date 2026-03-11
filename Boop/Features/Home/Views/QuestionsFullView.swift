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
                HStack(spacing: BoopSpacing.xs) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(BoopColors.secondary)
                    Text("Uploading \(viewModel.pendingVoiceUploads) voice answer\(viewModel.pendingVoiceUploads > 1 ? "s" : "")...")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.secondary)
                }
                .padding(.vertical, BoopSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(BoopColors.secondary.opacity(0.08))
            }

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(BoopColors.primary)
                Spacer()
            } else if let question = viewModel.currentQuestion {
                questionContent(question)
            } else {
                allDoneView
            }
        }
        .boopBackground()
        .task {
            await viewModel.fetchAllQuestions()
        }
    }

    private func questionContent(_ question: Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                Text(viewModel.progressText)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textMuted)

                Text(question.dimensionDisplayName)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.secondary)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, BoopSpacing.xxxs)
                    .background(BoopColors.secondary.opacity(0.1))
                    .clipShape(Capsule())

                Text(question.questionText)
                    .font(BoopTypography.title3)
                    .foregroundStyle(BoopColors.textPrimary)

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
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                BoopButton(
                    title: viewModel.isVoiceMode ? "Submit Voice Answer" : "Next",
                    isLoading: viewModel.isSubmitting,
                    isDisabled: !viewModel.canSubmitAnswer
                ) {
                    Task { await viewModel.submitAnswer() }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .onTapGesture { hideKeyboard() }
    }

    private var answerModeToggle: some View {
        HStack(spacing: BoopSpacing.xs) {
            modeButton(title: "Type", icon: "keyboard", isActive: !viewModel.isVoiceMode)
            modeButton(title: "Voice", icon: "mic.fill", isActive: viewModel.isVoiceMode)
        }
    }

    private func modeButton(title: String, icon: String, isActive: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.toggleVoiceMode()
            }
        } label: {
            HStack(spacing: BoopSpacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(title)
                    .font(BoopTypography.footnote)
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.xs)
            .foregroundStyle(isActive ? .white : BoopColors.textSecondary)
            .background(isActive ? BoopColors.primary : BoopColors.surfaceSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.clear : BoopColors.border, lineWidth: 1)
            )
        }
    }

    private var voiceAnswerArea: some View {
        VStack(spacing: BoopSpacing.md) {
            BoopVoiceRecorder(state: viewModel.voiceRecorder)

            Text("Record your answer — transcription happens automatically")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, BoopSpacing.md)
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
                VStack(spacing: BoopSpacing.xs) {
                    ForEach(options, id: \.self) { option in
                        choiceButton(option, isSelected: viewModel.selectedChoices.contains(option)) {
                            viewModel.toggleChoice(option, multiSelect: false)
                        }
                    }
                }
            }

        case .multipleChoice:
            if let options = question.options, !options.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                    Text("Select all that apply")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                    VStack(spacing: BoopSpacing.xs) {
                        ForEach(options, id: \.self) { option in
                            choiceButton(option, isSelected: viewModel.selectedChoices.contains(option)) {
                                viewModel.toggleChoice(option, multiSelect: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func choiceButton(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(BoopTypography.callout)
                    .foregroundStyle(isSelected ? .white : BoopColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.sm)
            .background(isSelected ? BoopColors.primary : BoopColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .stroke(isSelected ? Color.clear : BoopColors.border, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var allDoneView: some View {
        VStack(spacing: BoopSpacing.md) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(BoopColors.success)
            Text("All caught up!")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)
            Text("No new questions right now.\nCheck back tomorrow!")
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
