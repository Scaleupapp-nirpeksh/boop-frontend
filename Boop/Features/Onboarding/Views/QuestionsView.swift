import SwiftUI

struct QuestionsView: View {
    @Bindable var onboardingVM: OnboardingViewModel
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
            } else if viewModel.isComplete {
                completionView
            } else if let question = viewModel.currentQuestion {
                questionContent(question)
            } else {
                emptyView
            }
        }
        .task {
            await viewModel.fetchQuestions()
        }
    }

    // MARK: - Question Content

    private func questionContent(_ question: Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                // Progress
                Text(viewModel.progressText)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textMuted)

                // Dimension badge
                Text(question.dimensionDisplayName)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.secondary)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, BoopSpacing.xxxs)
                    .background(BoopColors.secondary.opacity(0.1))
                    .clipShape(Capsule())

                // Question text
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

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                // Submit
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

    // MARK: - Answer Mode Toggle

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

    // MARK: - Voice Answer Area

    private var voiceAnswerArea: some View {
        VStack(spacing: BoopSpacing.md) {
            BoopVoiceRecorder(state: viewModel.voiceRecorder)

            Text("Record your answer — it'll be transcribed automatically while you continue with other questions")
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

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: BoopSpacing.xxl) {
            Spacer()

            VStack(spacing: BoopSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(BoopColors.accent)

                Text("You're all set!")
                    .font(BoopTypography.title1)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Your profile is ready.\nTime to find your connections!")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            BoopButton(title: "Start Discovering") {
                onboardingVM.markComplete()
            }
        }
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.lg)
    }

    private var emptyView: some View {
        VStack(spacing: BoopSpacing.md) {
            Spacer()
            Text("No questions available right now")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textSecondary)
            Text("Check back tomorrow for more!")
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textMuted)
            Spacer()
        }
    }
}
