import SwiftUI

@Observable
class DiscoverViewModel {
    var candidates: [Candidate] = []
    var currentCandidateIndex = 0
    var isLoading = false
    var errorMessage: String?

    // Connect note sheet
    var showConnectSheet = false
    var connectCandidate: Candidate?
    var noteDraft = ""
    var noteSuggestions: [NoteSuggestion] = []
    var isLoadingSuggestions = false
    var isSendingLike = false

    // Match celebration
    var showMatchCelebration = false
    var celebrationMatch: LikeResponse.MutualMatchInfo?
    var celebrationName: String?

    var currentCandidate: Candidate? {
        guard currentCandidateIndex < candidates.count else { return nil }
        return candidates[currentCandidateIndex]
    }

    var candidatesRemaining: Int {
        max(0, candidates.count - currentCandidateIndex)
    }

    @MainActor
    func loadCandidates() async {
        isLoading = true
        errorMessage = nil
        do {
            let wrapper: CandidatesWrapper = try await APIClient.shared.request(.getCandidates())
            candidates = wrapper.candidates
            currentCandidateIndex = 0
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load profiles"
        }
        isLoading = false
    }

    @MainActor
    func openConnectSheet(for candidate: Candidate) {
        connectCandidate = candidate
        noteDraft = ""
        noteSuggestions = []
        showConnectSheet = true
        Task { await loadSuggestions(for: candidate.userId) }
    }

    @MainActor
    func loadSuggestions(for targetUserId: String) async {
        isLoadingSuggestions = true
        do {
            let response: NoteSuggestionsResponse = try await APIClient.shared.request(
                .suggestNote(targetUserId: targetUserId)
            )
            noteSuggestions = response.suggestions
        } catch {
            // Non-critical — user can still write their own note
        }
        isLoadingSuggestions = false
    }

    @MainActor
    func sendConnect(withNote: Bool) async {
        guard let candidate = connectCandidate else { return }
        isSendingLike = true

        let note: LikeNote? = withNote && !noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? LikeNote(content: noteDraft.trimmingCharacters(in: .whitespacesAndNewlines))
            : nil

        do {
            let response: LikeResponse = try await APIClient.shared.request(
                .likeUser(LikeRequest(targetUserId: candidate.userId, note: note))
            )

            showConnectSheet = false

            if response.isMutual, let match = response.match {
                celebrationMatch = match
                celebrationName = candidate.firstName
                showMatchCelebration = true
            }

            advanceToNextCandidate()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong"
        }

        isSendingLike = false
    }

    @MainActor
    func passCurrentCandidate() async {
        guard let candidate = currentCandidate else { return }

        do {
            try await APIClient.shared.requestVoid(
                .passUser(PassRequest(targetUserId: candidate.userId))
            )
        } catch {
            // Non-critical
        }

        advanceToNextCandidate()
    }

    @MainActor
    func dismissCelebration() {
        showMatchCelebration = false
        celebrationMatch = nil
        celebrationName = nil
    }

    @MainActor
    private func advanceToNextCandidate() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentCandidateIndex += 1
        }
    }
}
