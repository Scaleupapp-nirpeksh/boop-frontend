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

    // Connect-setup gate (preview users must add voice + photos before connecting)
    var showConnectSetup = false
    private var pendingConnectCandidate: Candidate?
    private var pendingNote: LikeNote?

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

        let note: LikeNote? = withNote && !noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? LikeNote(content: noteDraft.trimmingCharacters(in: .whitespacesAndNewlines))
            : nil

        await performConnect(candidate: candidate, note: note)
    }

    /// Sends the like and handles the result. If the backend reports the requester must
    /// finish setup (voice + photos), stashes the candidate/note and opens the setup gate
    /// instead of surfacing a generic error.
    @MainActor
    private func performConnect(candidate: Candidate, note: LikeNote?) async {
        isSendingLike = true
        defer { isSendingLike = false }

        do {
            let response: LikeResponse = try await APIClient.shared.request(
                .likeUser(LikeRequest(targetUserId: candidate.userId, note: note))
            )

            showConnectSheet = false
            Analytics.capture("connect_sent", ["with_note": note != nil])

            if response.isMutual, let match = response.match {
                celebrationMatch = match
                celebrationName = candidate.firstName
                showMatchCelebration = true
                Analytics.capture("match_created", ["tier": match.matchTier, "compatibility": match.compatibilityScore])
            }

            advanceToNextCandidate()
        } catch let error as APIError where error.requiresSetup {
            // Preview user — stash and open the connect-setup gate.
            pendingConnectCandidate = candidate
            pendingNote = note
            showConnectSheet = false
            showConnectSetup = true
            Analytics.capture("connect_setup_prompted")
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong"
        }
    }

    /// Opens the connect-setup gate proactively (preview banner) with no pending like.
    @MainActor
    func openConnectSetup() {
        pendingConnectCandidate = nil
        pendingNote = nil
        showConnectSetup = true
        Analytics.capture("connect_setup_prompted", ["source": "banner"])
    }

    /// Called once ConnectSetupView reports the user is `ready`. Re-sends the stashed like
    /// (if any) so the original Connect action completes transparently.
    @MainActor
    func completeSetupAndRetry() async {
        Analytics.capture("connect_setup_completed")
        guard let candidate = pendingConnectCandidate else { return }
        let note = pendingNote
        pendingConnectCandidate = nil
        pendingNote = nil
        await performConnect(candidate: candidate, note: note)
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
