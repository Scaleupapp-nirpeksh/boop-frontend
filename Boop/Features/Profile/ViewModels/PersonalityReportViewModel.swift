import SwiftUI

@Observable
class PersonalityReportViewModel {
    var response: PersonalityAnalysisResponse?
    var isLoading = false
    var errorMessage: String?

    var analysis: PersonalityAnalysis? { response?.analysis }
    var hasAnalysis: Bool { analysis != nil }
    var isPreliminary: Bool { response?.isPreliminary ?? true }
    var nextMilestone: Int { response?.nextMilestone ?? 15 }
    var questionsUntilNext: Int { response?.questionsUntilNext ?? 15 }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            response = try await APIClient.shared.request(.getPersonalityAnalysis)
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to load personality analysis"
        }

        isLoading = false
    }
}
