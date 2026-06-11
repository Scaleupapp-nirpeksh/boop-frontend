import SwiftUI
import AVFoundation

@Observable
class QuestionsViewModel {
    var questions: [Question] = []
    var currentIndex = 0
    var isLoading = false
    var isSubmitting = false
    var errorMessage: String?
    var answeredCount = 0
    var allBatchDone = false

    /// Deepen/"answer more" context (QuestionsFullView) vs onboarding (QuestionsView).
    /// In Deepen, the user is already preview/ready, so we must NOT treat a
    /// preview/ready submit response as terminal — we just advance to the next
    /// unanswered question. Onboarding leaves this false to drive the Reveal.
    var isDeepenMode = false

    /// Onboarding is complete once the 8 onboarding questions are answered.
    /// This drives the terminal Reveal screen — it is derived from the answer
    /// count / batch state, NOT from a backend `profileStage` string, so the
    /// flow is robust even if the async `preview`/`ready` signal lags.
    var isOnboardingComplete: Bool {
        allBatchDone || answeredCount >= Self.onboardingTarget
    }

    // Current answer
    var textAnswer = ""
    var selectedChoices: [String] = []
    var followUpAnswer = ""
    var questionStartTime = Date()

    // Voice recording
    var isVoiceMode = false
    var voiceRecorder: VoiceRecorderState = {
        let state = VoiceRecorderState()
        state.minDuration = 3   // 3s min for answers (vs 10s for voice intro)
        state.maxDuration = 60
        return state
    }()
    var pendingVoiceUploads = 0  // Track background uploads

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var canSubmitAnswer: Bool {
        guard let question = currentQuestion else { return false }
        if isVoiceMode {
            return voiceRecorder.hasRecording && !voiceRecorder.isRecording
        }
        switch question.questionType {
        case .text:
            return !textAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        case .singleChoice:
            return !selectedChoices.isEmpty
        case .multipleChoice:
            return !selectedChoices.isEmpty
        }
    }

    /// Number of onboarding questions a user must answer to unlock the reveal
    /// and enter the app in `preview` mode.
    static let onboardingTarget = 8

    /// Reward-first onboarding requires all 8 questions; there is no skip-at-6.
    var canSkipToHome: Bool {
        false
    }

    var progressText: String {
        "Question \(currentIndex + 1) of \(questions.count)"
    }

    // MARK: - Fetch Questions

    /// Fetch the onboarding question set (the 8 questions flagged `isOnboarding`).
    /// The backend returns all unlocked day-1 questions; we filter to the
    /// onboarding-flagged ones. If none are flagged (e.g. the field isn't
    /// serialized), fall back to the first `onboardingTarget` by questionNumber
    /// so the user is never left with an empty flow.
    @MainActor
    func fetchQuestions() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AvailableQuestionsResponse = try await APIClient.shared.request(.getQuestions)

            let onboardingQuestions = response.questions
                .filter { $0.isOnboarding == true }
                .sorted { $0.questionNumber < $1.questionNumber }

            if onboardingQuestions.isEmpty {
                // Fallback: backend didn't flag any onboarding questions.
                questions = Array(
                    response.questions
                        .sorted { $0.questionNumber < $1.questionNumber }
                        .prefix(Self.onboardingTarget)
                )
                #if DEBUG
                print("[QuestionsViewModel] No isOnboarding-flagged questions returned; falling back to first \(Self.onboardingTarget) by questionNumber. Verify the backend serializes `isOnboarding`.")
                #endif
            } else {
                questions = onboardingQuestions
            }

            answeredCount = response.meta.totalAnswered
            questionStartTime = Date()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load questions"
        }

        isLoading = false
    }

    /// Fetch all available questions (no limit — for home page sheet)
    @MainActor
    func fetchAllQuestions() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AvailableQuestionsResponse = try await APIClient.shared.request(.getQuestions)
            questions = response.questions
            answeredCount = response.meta.totalAnswered
            questionStartTime = Date()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load questions"
        }

        isLoading = false
    }

    // MARK: - Submit Answer

    @MainActor
    func submitAnswer() async {
        guard let question = currentQuestion else { return }

        // Voice mode: upload async and advance immediately
        if isVoiceMode {
            await submitVoiceAnswer(for: question)
            return
        }

        isSubmitting = true
        errorMessage = nil

        let timeSpent = Int(Date().timeIntervalSince(questionStartTime))

        var request = SubmitAnswerRequest(questionNumber: question.questionNumber, timeSpent: timeSpent)

        switch question.questionType {
        case .text:
            request.textAnswer = textAnswer.trimmingCharacters(in: .whitespaces)
        case .singleChoice:
            request.selectedOption = selectedChoices.first
        case .multipleChoice:
            request.selectedOptions = selectedChoices
        }

        if !followUpAnswer.isEmpty {
            request.followUpAnswer = followUpAnswer
        }

        defer { isSubmitting = false }

        do {
            let response: SubmitAnswerResponse = try await APIClient.shared.request(.answerQuestion(request))
            answeredCount = response.questionsAnswered

            // The onboarding-complete signal: the backend reports `preview`
            // (8 answers) or `ready` (15+). Treat either as terminal so the
            // Reveal shows even if this fires before we run out of questions.
            let isOnboardingDoneStage = response.profileStage == "preview" || response.profileStage == "ready"
            if isOnboardingDoneStage && !isDeepenMode {
                allBatchDone = true
                Analytics.capture("onboarding_complete", [
                    "answers": answeredCount,
                    "stage": response.profileStage
                ])
                if let wrapper: UserWrapper = try? await APIClient.shared.request(.me) {
                    AuthManager.shared.updateUser(wrapper.user)
                }
                return
            }

            advanceToNext()
        } catch let error as APIError {
            // A stale available-questions cache can re-serve an answered question;
            // the backend rejects the duplicate. Don't strand the user — skip it.
            if (error.errorDescription ?? "").lowercased().contains("already answered") {
                advanceToNext()
            } else {
                errorMessage = error.errorDescription
            }
        } catch {
            errorMessage = "Failed to submit answer"
        }
    }

    // MARK: - Voice Answer (Async / Non-Blocking)

    @MainActor
    private func submitVoiceAnswer(for question: Question) async {
        guard let audioData = voiceRecorder.getRecordingData() else {
            errorMessage = "Failed to read recording"
            return
        }

        let questionNumber = question.questionNumber
        isSubmitting = true

        // Advance to next question immediately — upload happens in background
        pendingVoiceUploads += 1
        answeredCount += 1
        advanceToNext()
        isSubmitting = false

        // Fire-and-forget: upload in background
        Task.detached { [weak self] in
            do {
                let response = try await APIClient.shared.uploadVoiceAnswer(
                    audioData: audioData,
                    questionNumber: questionNumber
                )
                await MainActor.run {
                    self?.pendingVoiceUploads -= 1
                    // Onboarding-complete signal from the backend (preview at 8,
                    // ready at 15+). Either flips into the terminal Reveal.
                    if response.profileStage == "preview" || response.profileStage == "ready" {
                        self?.allBatchDone = true
                        Analytics.capture("onboarding_complete", ["stage": response.profileStage])
                        Task {
                            let wrapper: UserWrapper = try await APIClient.shared.request(.me)
                            AuthManager.shared.updateUser(wrapper.user)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self?.pendingVoiceUploads -= 1
                    // Show a non-blocking error — user already moved on
                    self?.errorMessage = "Voice upload failed for Q\(questionNumber). You can re-answer later."
                }
            }
        }
    }

    // MARK: - Navigation

    @MainActor
    private func advanceToNext() {
        resetAnswer()
        if currentIndex + 1 < questions.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
            questionStartTime = Date()
        } else {
            // All available questions in this batch answered. Advance the index
            // past the end so `currentQuestion` becomes nil → "All caught up"
            // (Deepen) / Reveal (onboarding, driven by isOnboardingComplete).
            allBatchDone = true
            currentIndex = questions.count
            Task {
                let wrapper: UserWrapper = try await APIClient.shared.request(.me)
                AuthManager.shared.updateUser(wrapper.user)
            }
        }
    }

    /// Refresh user data and mark onboarding questions as done
    @MainActor
    func goToHomepage() async {
        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.me)
            AuthManager.shared.updateUser(wrapper.user)
        } catch {
            // Still allow navigation even if refresh fails
        }
    }

    private func resetAnswer() {
        textAnswer = ""
        selectedChoices = []
        followUpAnswer = ""
        errorMessage = nil
        isVoiceMode = false
        voiceRecorder.deleteRecording()
    }

    func toggleChoice(_ choice: String, multiSelect: Bool) {
        if multiSelect {
            if selectedChoices.contains(choice) {
                selectedChoices.removeAll { $0 == choice }
            } else {
                selectedChoices.append(choice)
            }
        } else {
            selectedChoices = [choice]
        }
    }

    func toggleVoiceMode() {
        isVoiceMode.toggle()
        if !isVoiceMode {
            voiceRecorder.deleteRecording()
        }
    }
}
