import Foundation

@MainActor
@Observable
final class NotificationRouter {
    static let shared = NotificationRouter()

    enum Destination: Equatable {
        case chat(matchId: String)
        case match(matchId: String)
        case game(gameId: String)
        case home
    }

    var pendingDestination: Destination?
    var selectedTab: Int = 0

    private init() {}

    func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "new_message", "message":
            if let matchId = userInfo["matchId"] as? String {
                pendingDestination = .chat(matchId: matchId)
                selectedTab = 2
            }
        case "new_match", "match":
            if let matchId = userInfo["matchId"] as? String {
                pendingDestination = .match(matchId: matchId)
                selectedTab = 0
            }
        case "game_invite", "game_response", "game_state_changed":
            if let gameId = userInfo["gameId"] as? String {
                pendingDestination = .game(gameId: gameId)
                selectedTab = 0
            }
        case "reveal_request", "reveal_complete":
            if let matchId = userInfo["matchId"] as? String {
                pendingDestination = .match(matchId: matchId)
                selectedTab = 0
            }
        default:
            pendingDestination = .home
            selectedTab = 0
        }
    }

    func consumeDestination() -> Destination? {
        let dest = pendingDestination
        pendingDestination = nil
        return dest
    }
}
