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
            .sorted {
                // Seasonal (legacy "unknown") is the catch-all for retired
                // questions — always list it after the real dimensions.
                let lhsCatchAll = Self.isCatchAllDimension($0.key)
                let rhsCatchAll = Self.isCatchAllDimension($1.key)
                if lhsCatchAll != rhsCatchAll { return rhsCatchAll }
                return $0.items.count > $1.items.count
            }
    }

    private static func isCatchAllDimension(_ key: String) -> Bool {
        key == "seasonal" || key == "unknown"
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
