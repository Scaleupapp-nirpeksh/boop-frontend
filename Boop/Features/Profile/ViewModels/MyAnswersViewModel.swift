import SwiftUI

@Observable
class MyAnswersViewModel {
    var history: [AnswerHistoryItem] = []
    var isLoading = false
    var errorMessage: String?

    var groupedByDimension: [(key: String, items: [AnswerHistoryItem])] {
        let grouped = Dictionary(grouping: history, by: { $0.dimension })
        return grouped
            .map { (key: $0.key, items: $0.value) }
            .sorted { $0.items.count > $1.items.count }
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: AnswerHistoryResponse = try await APIClient.shared.request(.getQuestionHistory)
            history = response.history
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load answer history"
        }

        isLoading = false
    }
}
