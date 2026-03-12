import Foundation

@Observable
final class CompatibilityDeepDiveViewModel {
    let matchId: String

    var data: CompatibilityDeepDiveResponse?
    var isLoading = false
    var errorMessage: String?

    init(matchId: String) {
        self.matchId = matchId
    }

    @MainActor
    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            data = try await APIClient.shared.request(.getCompatibilityDeepDive(matchId: matchId))
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load compatibility data."
        }
    }

    var sortedDimensions: [CompatibilityDimension] {
        data?.dimensions ?? []
    }

    var strongestDimension: CompatibilityDimension? {
        guard let key = data?.strongestBond else { return nil }
        return sortedDimensions.first(where: { $0.key == key })
    }

    var growthDimension: CompatibilityDimension? {
        guard let key = data?.growthOpportunity else { return nil }
        return sortedDimensions.first(where: { $0.key == key })
    }
}
