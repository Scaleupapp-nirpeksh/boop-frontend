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
    var isComplete = false
    var allBatchDone = false

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

    /// User can skip to homepage after answering 6+ questions
    var canSkipToHome: Bool {
        answeredCount >= 6
    }

    var progressText: String {
        "Question \(currentIndex + 1) of \(questions.count)"
    }

    // MARK: - Fetch Questions

    /// Fetch all available questions for onboarding (no limit)
    @MainActor
    func fetchQuestions() async {
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

            // Check if profile stage just changed to ready (onboarding completion)
            let wasAlreadyReady = AuthManager.shared.currentUser?.profileStage == .ready
            if response.profileStage == "ready" && !wasAlreadyReady {
                isComplete = true
                if let wrapper: UserWrapper = try? await APIClient.shared.request(.me) {
                    AuthManager.shared.updateUser(wrapper.user)
                }
                return
            }

            // Update user data in background (don't block)
            if response.profileStage == "ready" {
                Task {
                    if let wrapper: UserWrapper = try? await APIClient.shared.request(.me) {
                        AuthManager.shared.updateUser(wrapper.user)
                    }
                }
            }

            advanceToNext()
        } catch let error as APIError {
            errorMessage = error.errorDescription
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
                    // Check if backend says profile is ready
                    if response.profileStage == "ready" {
                        self?.isComplete = true
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
            // All available questions in this batch answered
            allBatchDone = true
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
