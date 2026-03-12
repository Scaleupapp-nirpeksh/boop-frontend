import Foundation

@Observable
final class BadgesViewModel {
    var badges: [BadgeCatalogItem] = []
    var isLoading = false
    var errorMessage: String?

    var earnedBadges: [BadgeCatalogItem] {
        badges.filter(\.earned)
    }

    var unearnedBadges: [BadgeCatalogItem] {
        badges.filter { !$0.earned }
    }

    var categories: [String] {
        let cats = Set(badges.map(\.category))
        let order = ["profile", "questions", "engagement", "games", "connections", "special"]
        return order.filter { cats.contains($0) }
    }

    func badgesForCategory(_ category: String) -> [BadgeCatalogItem] {
        badges.filter { $0.category == category }
    }

    @MainActor
    func load() async {
        guard badges.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let response: BadgeCatalogResponse = try await APIClient.shared.request(.getBadges)
            badges = response.badges
            errorMessage = nil
        } catch {
            errorMessage = "Could not load badges."
        }
    }
}
