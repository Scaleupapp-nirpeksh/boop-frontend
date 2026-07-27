import Foundation

// MARK: - "Us" pair models

struct PairInviteInfo: Decodable, Identifiable {
    let code: String
    let expiresAt: Date?
    let status: String
    let createdAt: Date?

    var id: String { code }
}

struct PairInvitesList: Decodable {
    let invites: [PairInviteInfo]
    let maxActive: Int
}

struct PairRedeemResponse: Decodable {
    let outcome: String   // paired | merged | already_connected | reactivated
    let matchId: String
    let partner: PairPartner
}

struct PairPartner: Decodable {
    let userId: String
    let firstName: String?
    let photoUrl: String?
}

// MARK: - View model

@Observable
final class UsViewModel {
    var currentCode: PairInviteInfo?
    var activeInvites: [PairInviteInfo] = []
    var pairs: [MatchInfo] = []
    var isLoadingPairs = false
    var isWorking = false
    var errorMessage: String?

    // Redeem state
    var redeemResult: PairRedeemResponse?

    @MainActor
    func loadPairs() async {
        isLoadingPairs = pairs.isEmpty
        defer { isLoadingPairs = false }
        do {
            let response: MatchesResponse = try await APIClient.shared.request(.getMatches(origin: "pair"))
            pairs = response.matches
        } catch {
            // Non-critical
        }
    }

    @MainActor
    func loadInvites() async {
        do {
            let list: PairInvitesList = try await APIClient.shared.request(.getPairInvites)
            activeInvites = list.invites
            errorMessage = nil
        } catch {
            // Non-critical
        }
    }

    @MainActor
    func createInvite() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let invite: PairInviteInfo = try await APIClient.shared.request(.createPairInvite)
            currentCode = invite
            await loadInvites()
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Couldn't create a code. Please try again."
        }
    }

    @MainActor
    func revoke(_ code: String) async {
        do {
            try await APIClient.shared.requestVoid(.revokePairInvite(code: code))
            if currentCode?.code == code { currentCode = nil }
            await loadInvites()
        } catch {
            errorMessage = "Couldn't revoke that code."
        }
    }

    @MainActor
    func redeem(_ code: String) async {
        isWorking = true
        defer { isWorking = false }
        do {
            let result: PairRedeemResponse = try await APIClient.shared.request(
                .redeemPairCode(code: code.uppercased().trimmingCharacters(in: .whitespaces))
            )
            redeemResult = result
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "This code isn't valid."
        }
    }
}
