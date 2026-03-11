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
}
