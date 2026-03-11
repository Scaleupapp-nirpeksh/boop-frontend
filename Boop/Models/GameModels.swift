import Foundation

struct MatchGamesResponse: Decodable {
    let games: [GameSummary]
}

struct GameSummary: Decodable, Identifiable {
    let gameId: String
    let gameType: String
    let status: String
    let totalRounds: Int
    let currentRound: Int
    let createdBy: GameUserRef?
    let completedAt: Date?
    let createdAt: Date?
    let sessionPhase: String?
    let sync: GameSyncState?

    var id: String { gameId }
}

struct GameSession: Decodable, Identifiable {
    let gameId: String
    let gameType: String
    let status: String
    let totalRounds: Int
    let currentRound: Int
    let rounds: [GameRound]
    let participants: [GameUserRef]?
    let createdBy: GameUserRef?
    let completedAt: Date?
    let createdAt: Date?
    let sessionPhase: String?
    let sync: GameSyncState?

    var id: String { gameId }
}

struct GameRound: Decodable, Identifiable {
    let roundNumber: Int
    let prompt: GamePrompt
    let responses: [GameResponse]?
    let isComplete: Bool
    let myResponse: GameResponse?
    let otherPlayerAnswered: Bool?
    let waitingForOther: Bool?

    var id: Int { roundNumber }
}

struct GameSyncState: Decodable {
    let serverNow: Date?
    let countdownSeconds: Int?
    let roundDurationSeconds: Int?
    let countdownStartedAt: Date?
    let countdownEndsAt: Date?
    let roundStartedAt: Date?
    let roundEndsAt: Date?
    let replayAvailableAt: Date?
    let readyPlayers: [GameReadyPlayer]
    let myReady: Bool?
    let allReady: Bool?
    let waitingForUserNames: [String]?
}

struct GameReadyPlayer: Decodable, Identifiable {
    let userId: String
    let firstName: String
    let isReady: Bool
    let readyAt: Date?

    var id: String { userId }
}

struct GamePrompt: Decodable {
    let text: String
    let optionA: String?
    let optionB: String?
    let category: String?
    let scale: GameScale?
    let context: String?
    let revealPrompt: String?
}

struct GameScale: Decodable {
    let min: Int?
    let max: Int?
}

struct GameResponse: Decodable, Identifiable {
    let userId: GameUserRef?
    let answer: String
    let answeredAt: Date?

    var id: String { (userId?.id ?? "user") + answer }
}

struct GameUserRef: Decodable, Identifiable, Hashable {
    let id: String
    let firstName: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let stringValue = try? container.decode(String.self) {
            id = stringValue
            firstName = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
    }
}

struct GameActionResponse: Decodable {
    let gameId: String
    let gameType: String
    let status: String
    let totalRounds: Int?
    let currentRound: Int?
    let rounds: [GameRound]?
    let participants: [GameUserRef]?
    let createdBy: GameUserRef?
    let createdAt: Date?
    let sessionPhase: String?
    let sync: GameSyncState?
}

struct SubmitGameRoundResponse: Decodable {
    let gameId: String
    let gameType: String
    let status: String
    let currentRound: Int
    let totalRounds: Int
    let roundComplete: Bool
    let gameComplete: Bool
    let round: GameRoundResult
    let completedAt: Date?
    let sessionPhase: String?
    let sync: GameSyncState?
}

struct GameRoundResult: Decodable {
    let roundNumber: Int
    let prompt: GamePrompt
    let responses: [GameResponse]?
    let isComplete: Bool
}

struct MessageReadEvent: Decodable {
    let conversationId: String
    let readBy: String
    let readAt: Date?
    let messagesRead: Int?
}

struct MessageReactionEvent: Decodable {
    let messageId: String
    let reactions: [ChatReaction]
    let addedBy: String?
    let removedBy: String?
    let emoji: String?
}

struct TypingEvent: Decodable {
    let conversationId: String
    let userId: String
}

struct MatchSocketEvent: Decodable {
    let matchId: String
    let compatibilityScore: Int?
    let matchTier: String?
}

struct MatchStageSocketEvent: Decodable {
    let matchId: String
    let stage: String
}

struct MatchRevealSocketEvent: Decodable {
    let matchId: String
    let requestedBy: String?
    let requestedByName: String?
}

struct GameInviteSocketEvent: Decodable {
    let gameId: String
    let gameType: String
    let invitedBy: String?
    let invitedByName: String?
    let matchId: String?
}

struct GameResponseSocketEvent: Decodable {
    let gameId: String
    let roundNumber: Int
    let respondedBy: String?
    let roundComplete: Bool
    let gameComplete: Bool
}

struct GameCancelledSocketEvent: Decodable {
    let gameId: String
    let cancelledBy: String?
}

struct GameStateChangedEvent: Decodable {
    let gameId: String
    let status: String?
    let currentRound: Int?
    let totalRounds: Int?
    let sessionPhase: String?
    let sync: GameSyncState?
}
