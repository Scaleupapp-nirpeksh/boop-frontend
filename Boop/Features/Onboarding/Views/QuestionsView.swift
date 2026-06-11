import SwiftUI

struct QuestionsView: View {
    @Bindable var onboardingVM: OnboardingViewModel
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
            } else if viewModel.isComplete {
                // Profile stage is ready (15+ answers)
                fullCompletionView
            } else if viewModel.allBatchDone {
                // All available questions answered but profile not yet ready
                batchCompletionView
            } else if let question = viewModel.currentQuestion {
                questionContent(question)
            } else {
                emptyView
            }
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .task {
            await viewModel.fetchQuestions()
        }
    }

    // MARK: - Question Content

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

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
                }

                VStack(spacing: BoopSpacing.md) {
                    // Submit
                    BoopButton(
                        title: viewModel.isVoiceMode ? "Submit Voice Answer" : "Continue",
                        isLoading: viewModel.isSubmitting,
                        isDisabled: !viewModel.canSubmitAnswer
                    ) {
                        Task { await viewModel.submitAnswer() }
                    }

                    // Skip to homepage button (visible after 6+ answers)
                    if viewModel.canSkipToHome {
                        Button {
                            Task {
                                await viewModel.goToHomepage()
                                onboardingVM.markComplete()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("SKIP TO HOMEPAGE")
                                    .font(BoopTypography.cineLabel)
                                    .tracking(2)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .thin))
                            }
                            .foregroundStyle(BoopColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BoopSpacing.xs)
                        }

                        Text("You can answer remaining questions from your profile anytime.")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, BoopSpacing.xs)
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .onTapGesture { hideKeyboard() }
    }

    // MARK: - Header (eyebrow + counter + hairline progress)

    private var questionHeader: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Question \(String(format: "%02d", viewModel.currentIndex + 1))",
                             color: BoopColors.accentColor)
                Spacer()
                Text("\(String(format: "%02d", min(viewModel.answeredCount, 15))) / 15")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
            }

            // Progress toward the 15 answers that unlock the full profile + best matches
            HairlineProgress(progress: Double(min(viewModel.answeredCount, 15)) / 15.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.answeredCount)

            if viewModel.answeredCount < 15 {
                Text("\(viewModel.answeredCount) of 15 to unlock your full profile & best matches")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            } else {
                Text(viewModel.progressText.uppercased())
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }
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

    // MARK: - Voice Answer Area

    private var voiceAnswerArea: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            BoopVoiceRecorder(state: viewModel.voiceRecorder)

            Text("Record your answer — it'll be transcribed automatically while you continue with other questions")
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

    // MARK: - Full Completion (profile ready, 15+ answers)

    private var fullCompletionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "Profile Complete", color: BoopColors.accentColor)
                AccentRule()
                Text("You're all set.")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                Text("Your personality profile is complete. Time to find your connections.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            BoopButton(title: "Start Discovering") {
                onboardingVM.markComplete()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

    // MARK: - Batch Completion (answered all available but < 15 total)

    private var batchCompletionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "Great Start", color: BoopColors.accentColor)
                AccentRule()
                Text("\(viewModel.answeredCount) answered")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)

                if viewModel.answeredCount < 15 {
                    Text("Answer \(15 - viewModel.answeredCount) more to unlock your full personality profile and get the best matches.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("New questions unlock every day at midnight.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }

            Spacer()

            VStack(spacing: BoopSpacing.md) {
                BoopButton(title: "Go to Homepage") {
                    Task {
                        await viewModel.goToHomepage()
                        onboardingVM.markComplete()
                    }
                }

                Text("You can continue answering from your profile anytime.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            if viewModel.answeredCount >= 6 {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "All Caught Up", color: BoopColors.accentColor)
                    AccentRule()
                    Text("All caught up for today.")
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("New questions unlock tomorrow at midnight.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                BoopButton(title: "Go to Homepage") {
                    Task {
                        await viewModel.goToHomepage()
                        onboardingVM.markComplete()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "No Questions", color: BoopColors.textMuted)
                    AccentRule()
                    Text("No questions available right now.")
                        .font(BoopTypography.cineHeadline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("Check back tomorrow for more.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textMuted)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }
}

// MARK: - Option indicator (coral radio / coral checkbox)

/// A thin-ring radio (single-choice) or square checkbox (multi-choice) that
/// fills with the coral accent when selected.
struct OptionIndicator: View {
    let isSelected: Bool
    let isMulti: Bool

    var body: some View {
        ZStack {
            if isMulti {
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(isSelected ? BoopColors.accentColor : BoopColors.textMuted, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .fill(isSelected ? BoopColors.accentColor : Color.clear)
                    )
                    .frame(width: 18, height: 18)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .stroke(isSelected ? BoopColors.accentColor : BoopColors.textMuted, lineWidth: 1)
                    .frame(width: 18, height: 18)
                if isSelected {
                    Circle()
                        .fill(BoopColors.accentColor)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .frame(width: 18, height: 18)
    }
}
