import Foundation

// MARK: - Match Detail

struct MatchDetail: Codable, Identifiable {
    let matchId: String
    let stage: String
    let compatibilityScore: Int?
    let matchTier: String?
    let dimensionScores: [String: Double]?
    let comfortScore: Int?
    let matchedAt: Date?
    let revealStatus: MatchRevealStatus?
    let lastBoop: BoopData?
    let boopCount: Int?
    let streak: StreakData?
    let otherUser: MatchDetailUser?

    var id: String { matchId }
}

struct MatchRevealStatus: Codable {
    let user1: RevealUserStatus?
    let user2: RevealUserStatus?
    let revealedAt: Date?
}

struct RevealUserStatus: Codable {
    let userId: String?
    let requested: Bool?
}

struct MatchDetailUser: Codable {
    let userId: String
    let firstName: String?
    let age: Int?
    let city: String?
    let isOnline: Bool?
    let lastSeen: Date?
    let blurLevel: Int?
    let voiceIntro: MatchOtherUser.MatchVoiceIntro?
    let photos: MatchOtherUser.MatchPhotos?
    let gender: String?
    let bio: String?
}

struct MatchStageActionResponse: Codable {
    let matchId: String
    let stage: String
    let previousStage: String?
}

struct ArchiveMatchResponse: Codable {
    let matchId: String
    let stage: String
    let archiveReason: String?
}

struct RevealRequestResponse: Codable {
    let matchId: String
    let stage: String
    let revealStatus: MatchRevealStatus?
    let bothRevealed: Bool
    let otherUserId: String?
}

struct ComfortScoreResponse: Codable {
    let score: Int
    let breakdown: [String: ComfortBreakdownItem]
    let matchId: String
    let updatedAt: Date?
}

struct ComfortBreakdownItem: Codable, Identifiable {
    let value: Int
    let weight: Double
    let detail: String

    var id: String { detail + String(value) }
}

struct DateReadinessResponse: Codable {
    let matchId: String
    let score: Int
    let isReady: Bool
    let breakdown: [String: DateReadinessBreakdown]
}

struct DateReadinessBreakdown: Codable, Identifiable {
    let value: Int
    let weight: Double

    var id: String { String(value) + String(weight) }
}

// MARK: - Score History

struct ScoreHistoryResponse: Codable {
    let matchId: String
    let snapshots: [ScoreSnapshot]
    let currentScores: CurrentScores

    struct CurrentScores: Codable {
        let comfort: Int?
        let compatibility: Int?
        let matchTier: String?
    }
}

struct ScoreSnapshot: Codable, Identifiable {
    let id: String
    let matchId: String
    let comfortScore: Int
    let dateReadinessScore: Int?
    let compatibilityScore: Int?
    let trigger: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case matchId, comfortScore, dateReadinessScore, compatibilityScore, trigger, createdAt
    }
}

// MARK: - AI Relationship Insights

struct RelationshipInsightsResponse: Codable {
    let matchId: String
    let insights: RelationshipInsights
    let scores: InsightScores
    let generatedAt: Date?
}

struct RelationshipInsights: Codable {
    let overallSummary: String?
    let strengths: [InsightItem]?
    let growthAreas: [InsightItem]?
    let gameInsights: String?
    let communicationStyle: String?
    let nextSteps: [String]?
    let source: String?
}

struct InsightItem: Codable, Identifiable {
    let title: String
    let detail: String

    var id: String { title }
}

struct InsightScores: Codable {
    let compatibility: Int?
    let comfort: Int?
    let matchTier: String?
}

// MARK: - Chat

struct ConversationsResponse: Codable {
    let conversations: [ConversationInfo]
    let total: Int
    let page: Int
    let totalPages: Int
}

struct ConversationInfo: Codable, Identifiable {
    let conversationId: String
    let matchId: String?
    let matchStage: String?
    let compatibilityScore: Int?
    let matchTier: String?
    let lastMessage: ConversationLastMessage?
    let unreadCount: Int
    let messageCount: Int
    let otherUser: ConversationOtherUser
    let updatedAt: Date?

    var id: String { conversationId }
}

struct ConversationLastMessage: Codable {
    let text: String?
    let senderId: String?
    let sentAt: Date?
    let type: String?
}

struct ConversationOtherUser: Codable {
    let userId: String
    let firstName: String?
    let isOnline: Bool?
    let lastSeen: Date?
    let photo: String?
}

struct ConversationMessagesResponse: Codable {
    let messages: [ChatMessage]
    let hasMore: Bool
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let conversationId: String
    let senderId: ChatSender
    let type: String
    let content: ChatMessageContent
    let reactions: [ChatReaction]
    let replyTo: ChatReplyMessage?
    let readAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversationId, senderId, type, content, reactions, replyTo, readAt, createdAt
    }
}

struct ChatSender: Codable {
    let id: String
    let firstName: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
    }
}

struct ChatMessageContent: Codable {
    let text: String?
    let mediaUrl: String?
    let mediaDuration: Double?
    let gameType: String?
    let gameSessionId: String?
}

struct ChatReaction: Codable, Identifiable {
    let id: String
    let userId: String
    let emoji: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId, emoji, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawUserId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        userId = rawUserId
        emoji = try container.decode(String.self, forKey: .emoji)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        id = rawUserId + emoji
    }
}

struct ChatReplyMessage: Codable {
    let id: String?
    let content: ChatMessageContent?
    let senderId: ChatSender?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case content, senderId, type
    }
}

struct SendMessageRequest: Encodable {
    let type: String
    let text: String?
    let mediaUrl: String?
    let mediaDuration: Double?
    let replyTo: String?

    init(
        type: String = "text",
        text: String? = nil,
        mediaUrl: String? = nil,
        mediaDuration: Double? = nil,
        replyTo: String? = nil
    ) {
        self.type = type
        self.text = text
        self.mediaUrl = mediaUrl
        self.mediaDuration = mediaDuration
        self.replyTo = replyTo
    }
}

struct MarkReadResponse: Codable {
    let conversationId: String
    let messagesRead: Int
    let readAt: Date?
}

struct MessageReactionRequest: Encodable {
    let emoji: String
}

struct MessageReactionResponse: Codable {
    let messageId: String
    let conversationId: String
    let reactions: [ChatReaction]
}

// MARK: - Chat Media Gallery

struct ConversationMediaResponse: Codable {
    let media: [ChatMessage]
    let total: Int
    let page: Int
    let totalPages: Int
}

// MARK: - Compatibility Deep-Dive

struct CompatibilityDeepDiveResponse: Codable {
    let matchId: String
    let compatibilityScore: Int?
    let matchTier: String?
    let user1Name: String?
    let user2Name: String?
    let dimensions: [CompatibilityDimension]
    let overallNarrative: String?
    let strongestBond: String?
    let growthOpportunity: String?
}

struct CompatibilityDimension: Codable, Identifiable {
    let key: String
    let label: String
    let icon: String
    let color: String
    let score: Int?
    let narrative: String?

    var id: String { key }
}

// MARK: - Date Plans

struct DatePlansResponse: Codable {
    let plans: [DatePlanItem]
}

struct DatePlanItem: Codable, Identifiable {
    let _id: String
    let matchId: String
    let proposedBy: String
    let status: String
    let venue: DatePlanVenue
    let proposedDate: Date
    let proposedTime: String?
    let notes: String?
    let acceptedAt: Date?
    let declinedAt: Date?
    let declineReason: String?
    let completedAt: Date?
    let safetyContact: SafetyContact?
    let locationSharing: LocationSharing?
    let checkIns: [DateCheckIn]?
    let createdAt: Date?

    var id: String { _id }

    var statusLabel: String {
        switch status {
        case "proposed": return "Pending"
        case "accepted": return "Confirmed"
        case "declined": return "Declined"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return status.capitalized
        }
    }

    var statusColor: String {
        switch status {
        case "proposed": return "accent"
        case "accepted": return "success"
        case "declined": return "error"
        case "completed": return "secondary"
        case "cancelled": return "textMuted"
        default: return "textSecondary"
        }
    }
}

struct DatePlanVenue: Codable {
    let name: String
    let type: String?
    let address: String?
}

struct SafetyContact: Codable {
    let name: String?
    let phone: String?
}

struct LocationSharing: Codable {
    let enabled: Bool?
    let startedAt: Date?
    let expiresAt: Date?
}

struct DateCheckIn: Codable, Identifiable {
    let userId: String?
    let status: String
    let timestamp: Date?

    var id: String { "\(userId ?? "")_\(timestamp?.timeIntervalSince1970 ?? 0)" }
}

struct VenueSuggestionsResponse: Codable {
    let suggestions: [VenueSuggestion]
}

struct VenueSuggestion: Codable, Identifiable {
    let name: String
    let type: String
    let reason: String

    var id: String { name }
}

struct ProposeDatePlanRequest: Encodable {
    let venueName: String
    let venueType: String
    let address: String?
    let proposedDate: String
    let proposedTime: String?
    let notes: String?
}

struct DatePlanResponseRequest: Encodable {
    let accept: Bool
    let declineReason: String?
}

struct SafetyContactRequest: Encodable {
    let name: String
    let phone: String
}

struct DatePlanResponse: Codable {
    let plan: DatePlanItem
}
