import SwiftUI
import WidgetKit

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
        updateWidgetData()
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

    // MARK: - Widget Data

    private func updateWidgetData() {
        guard let defaults = UserDefaults(suiteName: "group.com.influhitch.boop") else { return }
        defaults.set(activeMatches.count, forKey: "widget_connections")
        defaults.set(0, forKey: "widget_unread") // Updated from chat if available
        defaults.set(AuthManager.shared.currentUser?.questionsAnswered ?? 0, forKey: "widget_questions")

        // Find best streak from active matches
        var bestStreak = 0
        var bestStreakName: String?
        for match in activeMatches {
            if let streak = match.streak?.current, streak > bestStreak {
                bestStreak = streak
                bestStreakName = match.otherUser?.firstName
            }
        }
        defaults.set(bestStreak, forKey: "widget_streak")
        defaults.set(bestStreakName, forKey: "widget_streak_name")

        // Trigger widget reload
        if #available(iOS 14.0, *) {
            WidgetKit.WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
