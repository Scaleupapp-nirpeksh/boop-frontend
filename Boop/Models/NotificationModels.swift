import Foundation

// MARK: - Notification Item (from GET /notifications)

struct NotificationItem: Codable, Identifiable {
    let _id: String
    let type: String
    let title: String
    let body: String
    let data: NotificationData?
    let read: Bool
    let createdAt: Date

    var id: String { _id }

    struct NotificationData: Codable {
        let matchId: String?
        let conversationId: String?
        let gameId: String?
        let senderId: String?
        let senderName: String?
    }

    var typeIcon: String {
        switch type {
        case "new_match": return "heart.circle.fill"
        case "new_message": return "bubble.left.fill"
        case "game_invite": return "gamecontroller.fill"
        case "reveal_request": return "eye.fill"
        case "photos_revealed": return "photo.fill"
        case "stage_advanced": return "arrow.up.circle.fill"
        case "like_received": return "heart.fill"
        case "system": return "bell.fill"
        default: return "bell.fill"
        }
    }

    var typeColor: String {
        switch type {
        case "new_match": return "primary"
        case "new_message": return "secondary"
        case "game_invite": return "accent"
        case "reveal_request", "photos_revealed": return "secondary"
        case "stage_advanced": return "secondary"
        case "like_received": return "primary"
        default: return "textMuted"
        }
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        if days < 7 { return "\(days)d ago" }
        return "\(days / 7)w ago"
    }
}

// MARK: - Responses

struct NotificationsResponse: Codable {
    let notifications: [NotificationItem]
    let unreadCount: Int
    let total: Int
    let page: Int
    let totalPages: Int
}

struct UnreadCountResponse: Codable {
    let unreadCount: Int
}
