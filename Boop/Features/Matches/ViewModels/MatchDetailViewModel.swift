import Foundation

struct MatchInsight: Identifiable {
    let title: String
    let detail: String
    let tintHex: String

    var id: String { title + detail }
}

struct MatchStageStep: Identifiable {
    let rawValue: String
    let title: String
    let subtitle: String

    var id: String { rawValue }
}

@Observable
final class MatchDetailViewModel {
    let matchId: String

    var detail: MatchDetail?
    var comfort: ComfortScoreResponse?
    var readiness: DateReadinessResponse?
    var scoreHistory: ScoreHistoryResponse?
    var insights: RelationshipInsightsResponse?
    var isLoading = false
    var isWorking = false
    var isLoadingInsights = false
    var errorMessage: String?

    init(matchId: String) {
        self.matchId = matchId
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let detailTask: MatchDetail = APIClient.shared.request(.getMatchById(matchId: matchId))
            async let comfortTask: ComfortScoreResponse = APIClient.shared.request(.getComfortScore(matchId: matchId))
            async let readinessTask: DateReadinessResponse = APIClient.shared.request(.getDateReadiness(matchId: matchId))
            async let historyTask: ScoreHistoryResponse = APIClient.shared.request(.getScoreHistory(matchId: matchId))

            detail = try await detailTask
            comfort = try? await comfortTask
            readiness = try? await readinessTask
            scoreHistory = try? await historyTask
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load this match."
        }
    }

    @MainActor
    func loadInsights() async {
        guard insights == nil else { return }
        isLoadingInsights = true
        defer { isLoadingInsights = false }

        insights = try? await APIClient.shared.request(.getRelationshipInsights(matchId: matchId))
    }

    @MainActor
    func requestReveal() async {
        await performAction { [self] in
            let _: RevealRequestResponse = try await APIClient.shared.request(.requestReveal(matchId: self.matchId))
            await self.load()
        }
    }

    @MainActor
    func advanceStage() async {
        await performAction { [self] in
            let _: MatchStageActionResponse = try await APIClient.shared.request(.advanceMatchStage(matchId: self.matchId))
            await self.load()
        }
    }

    @MainActor
    func archive() async {
        await performAction { [self] in
            let _: ArchiveMatchResponse = try await APIClient.shared.request(.archiveMatch(matchId: self.matchId, reason: "other"))
            await self.load()
        }
    }

    private func performAction(_ action: @escaping @Sendable () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }

        do {
            try await action()
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Action failed."
        }
    }

    var stageTitle: String {
        let raw = detail?.stage ?? "mutual"
        return raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var stageSteps: [MatchStageStep] {
        [
            .init(rawValue: "mutual", title: "Mutual", subtitle: "You matched"),
            .init(rawValue: "connecting", title: "Connecting", subtitle: "Talk and listen"),
            .init(rawValue: "reveal_ready", title: "Reveal Ready", subtitle: "Strong signal"),
            .init(rawValue: "revealed", title: "Revealed", subtitle: "Photos unlocked"),
            .init(rawValue: "dating", title: "Dating", subtitle: "Meet offline"),
        ]
    }

    var currentStageIndex: Int {
        stageSteps.firstIndex(where: { $0.rawValue == detail?.stage }) ?? 0
    }

    var nextStage: MatchStageStep? {
        let nextIndex = currentStageIndex + 1
        guard stageSteps.indices.contains(nextIndex) else { return nil }
        return stageSteps[nextIndex]
    }

    var stageSummary: String {
        switch detail?.stage {
        case "mutual":
            return "Start light. Exchange a few thoughtful messages and get comfortable with each other's voice."
        case "connecting":
            return "This is the chemistry-building stage. Games, voice notes, and consistency matter more than speed."
        case "reveal_ready":
            return "You have enough momentum to decide whether you both want to reveal photos."
        case "revealed":
            return "Photos are unlocked. Now check if the energy still holds and plan something real."
        case "dating":
            return "You’ve moved beyond the app stage. Keep the momentum and make the next step concrete."
        case "archived":
            return "This connection is archived."
        default:
            return "Build comfort first, then move forward with intention."
        }
    }

    var nextActionSummary: String {
        if isAwaitingOtherReveal {
            return "Your reveal request is in. The next step depends on the other person."
        }
        if let nextStage {
            return "Next: \(nextStage.title). \(nextStage.subtitle)"
        }
        return "You’re at the latest stage available in the app."
    }

    var revealProgressText: String? {
        guard let revealStatus = detail?.revealStatus else { return nil }
        let requests = [revealStatus.user1?.requested, revealStatus.user2?.requested]
            .compactMap { $0 }
            .filter { $0 }
            .count
        guard requests > 0 || detail?.stage == "reveal_ready" || detail?.stage == "revealed" else { return nil }
        return "\(requests) of 2 reveal requests sent"
    }

    var revealButtonTitle: String {
        isAwaitingOtherReveal ? "Waiting for them" : "Request Reveal"
    }

    var hasCurrentUserRequestedReveal: Bool {
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return false }
        if detail?.revealStatus?.user1?.userId == currentUserId {
            return detail?.revealStatus?.user1?.requested == true
        }
        if detail?.revealStatus?.user2?.userId == currentUserId {
            return detail?.revealStatus?.user2?.requested == true
        }
        return false
    }

    var isAwaitingOtherReveal: Bool {
        hasCurrentUserRequestedReveal && detail?.stage != "revealed"
    }

    var canRequestReveal: Bool {
        guard let stage = detail?.stage else { return false }
        return (stage == "connecting" || stage == "reveal_ready") && !hasCurrentUserRequestedReveal
    }

    var canAdvanceStage: Bool {
        guard let stage = detail?.stage else { return false }
        return stage != "dating" && stage != "archived"
    }

    var topInsights: [MatchInsight] {
        guard let scores = detail?.dimensionScores, !scores.isEmpty else { return [] }

        return scores
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { key, value in
                MatchInsight(
                    title: dimensionTitle(for: key),
                    detail: dimensionPositiveCopy(for: key, score: value),
                    tintHex: dimensionTint(for: key)
                )
            }
    }

    var growthInsight: MatchInsight? {
        guard let scores = detail?.dimensionScores, let lowest = scores.min(by: { $0.value < $1.value }) else {
            return nil
        }

        return MatchInsight(
            title: "Move gently with \(dimensionTitle(for: lowest.key))",
            detail: dimensionGrowthCopy(for: lowest.key, score: lowest.value),
            tintHex: "C17A16"
        )
    }

    private func dimensionTitle(for key: String) -> String {
        switch key {
        case "emotional_vulnerability": return "Emotional honesty"
        case "attachment_patterns": return "Attachment rhythm"
        case "life_vision": return "Future direction"
        case "conflict_resolution": return "Repair style"
        case "love_expression": return "Love expression"
        case "intimacy_comfort": return "Closeness comfort"
        case "lifestyle_rhythm": return "Daily rhythm"
        case "growth_mindset": return "Growth mindset"
        default:
            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func dimensionPositiveCopy(for key: String, score: Double) -> String {
        let percent = Int((score * 100).rounded())
        switch key {
        case "emotional_vulnerability":
            return "You both open up in a similar way. \(percent)% alignment."
        case "attachment_patterns":
            return "Your pacing around connection looks naturally compatible."
        case "life_vision":
            return "The kind of future you imagine has real overlap."
        case "conflict_resolution":
            return "You tend to repair tension in ways that can actually meet."
        case "love_expression":
            return "The way you show care lands in a familiar register."
        case "intimacy_comfort":
            return "Your comfort with closeness feels unusually well matched."
        case "lifestyle_rhythm":
            return "Your day-to-day tempo looks easy to share."
        case "growth_mindset":
            return "You both lean toward growth instead of staying stuck."
        default:
            return "\(percent)% alignment in this part of the relationship."
        }
    }

    private func dimensionGrowthCopy(for key: String, score: Double) -> String {
        let percent = Int((score * 100).rounded())
        switch key {
        case "conflict_resolution":
            return "This is where patience will matter most. \(percent)% alignment here."
        case "attachment_patterns":
            return "You may want different speeds of reassurance and closeness."
        case "intimacy_comfort":
            return "Let this part grow through trust, not pressure."
        case "life_vision":
            return "Keep talking about long-term expectations early."
        default:
            return "This is the area to stay curious about while the connection grows."
        }
    }

    private func dimensionTint(for key: String) -> String {
        switch key {
        case "emotional_vulnerability": return "FF6B6B"
        case "attachment_patterns": return "E056A0"
        case "life_vision": return "4ECDC4"
        case "conflict_resolution": return "FF8C42"
        case "love_expression": return "F56FAD"
        case "intimacy_comfort": return "9B5DE5"
        case "lifestyle_rhythm": return "00BBF9"
        case "growth_mindset": return "2ECC71"
        default: return "4ECDC4"
        }
    }
}
