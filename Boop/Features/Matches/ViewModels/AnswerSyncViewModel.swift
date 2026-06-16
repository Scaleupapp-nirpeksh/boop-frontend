import Foundation

@Observable
final class AnswerSyncViewModel {
    let matchId: String
    var data: AnswerSyncResponse?
    var isLoading = false
    var errorMessage: String?
    var selectedBucket: String?

    init(matchId: String) {
        self.matchId = matchId
    }

    /// Convenience initializer for previews / debug harnesses: inject preloaded data,
    /// optionally pre-selecting a bucket so an expanded state is visible immediately.
    init(matchId: String, preloaded: AnswerSyncResponse, selectedBucket: String? = nil) {
        self.matchId = matchId
        self.data = preloaded
        self.selectedBucket = selectedBucket
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            data = try await APIClient.shared.request(.getAnswerSync(matchId: matchId))
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load."
        }
    }

    func questions(in bucket: String) -> [AnswerSyncQuestion] {
        (data?.questions ?? []).filter { $0.syncLevel == bucket }
    }
}
