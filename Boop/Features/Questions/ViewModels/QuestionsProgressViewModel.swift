import Foundation

@Observable
final class QuestionsProgressViewModel {
    var progress: QuestionsProgressResponse?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            progress = try await APIClient.shared.request(.getQuestionsProgress)
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load progress."
        }
    }

    // MARK: - Confidence engine derivations

    /// Match-confidence as a 0...100 integer. Falls back to answered/total share
    /// when the backend doesn't yet send `matchConfidence` (older servers).
    func confidencePercent(_ progress: QuestionsProgressResponse) -> Int {
        if let mc = progress.matchConfidence {
            return max(0, min(100, mc))
        }
        let denom = max(progress.totalQuestions, 1)
        return max(0, min(100, Int((Double(progress.totalAnswered) / Double(denom) * 100).rounded())))
    }

    /// Ring fill fraction (0...1) for the trim animation.
    func confidenceFraction(_ progress: QuestionsProgressResponse) -> Double {
        Double(confidencePercent(progress)) / 100.0
    }

    /// Next round-number target above the current confidence, or nil once dialed in.
    func nextTarget(_ progress: QuestionsProgressResponse) -> Int? {
        let c = confidencePercent(progress)
        switch c {
        case ..<50: return 50
        case ..<70: return 70
        case ..<90: return 90
        default: return nil
        }
    }

    /// Encouraging nudge under the ring:
    /// "N answered · answer M more to reach T%", or a dialed-in message at the top.
    func nudgeText(_ progress: QuestionsProgressResponse) -> String {
        let answered = progress.totalAnswered
        guard let target = nextTarget(progress) else {
            return "\(answered) answered · your matches are dialed in"
        }
        // Honest, simple heuristic: how many unlocked questions are still unanswered.
        // Frame as "answer M more" without over-promising precise % math.
        let remainingUnlocked = max(progress.totalUnlocked - answered, 0)
        let more = max(remainingUnlocked, 1)
        let noun = more == 1 ? "answer" : "answers"
        return "\(answered) answered · \(more) more \(noun) to reach \(target)%"
    }

    /// Dimensions sorted by coverage, least-covered first — nudges what to fill next.
    func sortedDimensions(_ progress: QuestionsProgressResponse) -> [(key: String, value: QuestionDimensionProgress)] {
        progress.dimensions
            .map { (key: $0.key, value: $0.value) }
            .sorted { lhs, rhs in
                let l = Double(lhs.value.answered) / Double(max(lhs.value.unlocked, 1))
                let r = Double(rhs.value.answered) / Double(max(rhs.value.unlocked, 1))
                if l == r { return lhs.key < rhs.key }   // stable tiebreak
                return l < r
            }
    }
}
