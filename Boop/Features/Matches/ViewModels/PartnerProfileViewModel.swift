import Foundation

@Observable
final class PartnerProfileViewModel {
    var partner: PartnerProfile?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func load(matchId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: PartnerProfileResponse = try await APIClient.shared.request(.getMatchPartner(matchId: matchId))
            partner = response.partner
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load their profile."
        }
    }
}
