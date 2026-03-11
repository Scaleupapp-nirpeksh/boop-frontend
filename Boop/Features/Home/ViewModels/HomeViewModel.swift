import SwiftUI

@Observable
class HomeViewModel {
    // Section data
    var newQuestionsCount = 0
    var stats = DiscoverStats(newMatches: 0, activeConnections: 0, totalCandidates: 0)
    var activeMatches: [MatchInfo] = []
    var incomingPendingLikes: [PendingLikeProfile] = []
    var outgoingPendingLikes: [PendingLikeProfile] = []

    // State
    var isLoading = false
    var errorMessage: String?

    // Match celebration
    var showMatchCelebration = false
    var celebrationMatch: LikeResponse.MutualMatchInfo?
    var celebrationName: String?

    // Navigation
    var showQuestionsSheet = false

    // MARK: - Load All Data

    @MainActor
    func loadHome() async {
        isLoading = true
        errorMessage = nil

        async let statsTask: () = loadStats()
        async let matchesTask: () = loadMatches()
        async let pendingTask: () = loadPendingLikes()
        async let questionsTask: () = loadNewQuestionsCount()

        _ = await (statsTask, matchesTask, pendingTask, questionsTask)
        isLoading = false
    }

    @MainActor
    func refresh() async {
        await loadHome()
    }

    // MARK: - Stats

    @MainActor
    private func loadStats() async {
        do {
            stats = try await APIClient.shared.request(.getDiscoverStats)
        } catch {
            // Non-critical
        }
    }

    // MARK: - Matches

    @MainActor
    private func loadMatches() async {
        do {
            let response: MatchesResponse = try await APIClient.shared.request(.getMatches())
            activeMatches = response.matches
        } catch {
            // Non-critical
        }
    }

    @MainActor
    private func loadPendingLikes() async {
        do {
            let response: PendingLikesResponse = try await APIClient.shared.request(.getPendingLikes)
            incomingPendingLikes = response.incoming
            outgoingPendingLikes = response.outgoing
        } catch {
            incomingPendingLikes = []
            outgoingPendingLikes = []
        }
    }

    // MARK: - New Questions Count

    @MainActor
    private func loadNewQuestionsCount() async {
        do {
            let response: AvailableQuestionsResponse = try await APIClient.shared.request(.getQuestions)
            newQuestionsCount = response.meta.totalRemaining
        } catch {
            // Non-critical
        }
    }

    // MARK: - Like / Pass (for incoming pending likes)

    @MainActor
    func likeIncomingPending(_ profile: PendingLikeProfile) async {
        do {
            let response: LikeResponse = try await APIClient.shared.request(
                .likeUser(LikeRequest(targetUserId: profile.userId))
            )

            if response.isMutual, let match = response.match {
                celebrationMatch = match
                celebrationName = profile.firstName
                showMatchCelebration = true
            }

            incomingPendingLikes.removeAll { $0.userId == profile.userId }
            outgoingPendingLikes.removeAll { $0.userId == profile.userId }
            Task { await loadMatches() }
            Task { await loadPendingLikes() }
            Task { await loadStats() }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong"
        }
    }

    @MainActor
    func passIncomingPending(_ profile: PendingLikeProfile) async {
        do {
            try await APIClient.shared.requestVoid(
                .passUser(PassRequest(targetUserId: profile.userId))
            )
            incomingPendingLikes.removeAll { $0.userId == profile.userId }
            Task { await loadPendingLikes() }
            Task { await loadStats() }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not pass this profile."
        }
    }

    @MainActor
    func dismissCelebration() {
        showMatchCelebration = false
        celebrationMatch = nil
        celebrationName = nil
    }
}
