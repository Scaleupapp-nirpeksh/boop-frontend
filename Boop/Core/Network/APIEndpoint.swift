import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

enum APIEndpoint {
    // Auth
    case sendOTP(SendOTPRequest)
    case verifyOTP(VerifyOTPRequest)
    case refreshToken(RefreshTokenRequest)
    case logout
    case me

    // Profile
    case getProfile
    case updateBasicInfo(UpdateBasicInfoRequest)
    case uploadVoiceIntro
    case uploadPhotos
    case reorderPhotos(ReorderPhotosRequest)
    case deletePhoto(index: Int)
    case updateFCMToken(token: String)
    case updateNotificationPreferences(UpdateNotificationPreferencesRequest)

    // Questions
    case getQuestions
    case getQuestionsProgress
    case answerQuestion(SubmitAnswerRequest)
    case submitVoiceAnswer

    // Discover
    case getCandidates(limit: Int = 10)
    case getDiscoverStats
    case getPendingLikes
    case likeUser(LikeRequest)
    case passUser(PassRequest)
    case suggestNote(targetUserId: String)

    // Matches
    case getMatches(stage: String? = nil, page: Int = 1)
    case getMatchById(matchId: String)
    case advanceMatchStage(matchId: String)
    case archiveMatch(matchId: String, reason: String)
    case requestReveal(matchId: String)
    case getComfortScore(matchId: String)
    case getDateReadiness(matchId: String)

    // Games
    case createGame(CreateGameRequest)
    case getGame(gameId: String)
    case setGameReady(gameId: String, ready: Bool)
    case submitGameResponse(gameId: String, answer: String)
    case cancelGame(gameId: String)
    case getGamesForMatch(matchId: String)

    // Score History & Insights
    case getScoreHistory(matchId: String, limit: Int = 50)
    case getRelationshipInsights(matchId: String)
    case getConversationStarters(matchId: String)

    // Notifications
    case getNotifications(page: Int = 1)
    case getUnreadNotificationCount
    case markNotificationRead(notificationId: String)
    case markAllNotificationsRead
    case deleteNotification(notificationId: String)

    // Messages
    case getConversations(page: Int = 1)
    case getMessages(conversationId: String, before: String? = nil)
    case uploadConversationMedia(conversationId: String)
    case sendMessage(conversationId: String, request: SendMessageRequest)
    case markConversationRead(conversationId: String)
    case addReaction(messageId: String, emoji: String)
    case removeReaction(messageId: String)

    var path: String {
        switch self {
        case .sendOTP: return "/auth/send-otp"
        case .verifyOTP: return "/auth/verify-otp"
        case .refreshToken: return "/auth/refresh-token"
        case .logout: return "/auth/logout"
        case .me: return "/auth/me"
        case .getProfile: return "/profile"
        case .updateBasicInfo: return "/profile/basic-info"
        case .uploadVoiceIntro: return "/profile/voice-intro"
        case .uploadPhotos: return "/profile/photos"
        case .reorderPhotos: return "/profile/photos/reorder"
        case .deletePhoto(let index): return "/profile/photos/\(index)"
        case .updateFCMToken: return "/profile/fcm-token"
        case .updateNotificationPreferences: return "/profile/notification-preferences"
        case .getQuestions: return "/questions"
        case .getQuestionsProgress: return "/questions/progress"
        case .answerQuestion: return "/questions/answer"
        case .submitVoiceAnswer: return "/questions/voice-answer"
        case .getCandidates(let limit): return "/discover?limit=\(limit)"
        case .getDiscoverStats: return "/discover/stats"
        case .getPendingLikes: return "/discover/pending"
        case .likeUser: return "/discover/like"
        case .passUser: return "/discover/pass"
        case .suggestNote(let targetUserId): return "/discover/suggest-note/\(targetUserId)"
        case .getMatches(let stage, let page):
            var path = "/matches?page=\(page)"
            if let stage { path += "&stage=\(stage)" }
            return path
        case .getMatchById(let matchId): return "/matches/\(matchId)"
        case .advanceMatchStage(let matchId): return "/matches/\(matchId)/advance"
        case .archiveMatch(let matchId, _): return "/matches/\(matchId)/archive"
        case .requestReveal(let matchId): return "/matches/\(matchId)/reveal"
        case .getComfortScore(let matchId): return "/matches/\(matchId)/comfort"
        case .getDateReadiness(let matchId): return "/matches/\(matchId)/date-readiness"
        case .createGame: return "/games"
        case .getGame(let gameId): return "/games/\(gameId)"
        case .setGameReady(let gameId, _): return "/games/\(gameId)/ready"
        case .submitGameResponse(let gameId, _): return "/games/\(gameId)/respond"
        case .cancelGame(let gameId): return "/games/\(gameId)/cancel"
        case .getGamesForMatch(let matchId): return "/games/match/\(matchId)"
        case .getScoreHistory(let matchId, let limit): return "/matches/\(matchId)/score-history?limit=\(limit)"
        case .getRelationshipInsights(let matchId): return "/matches/\(matchId)/insights"
        case .getConversationStarters(let matchId): return "/matches/\(matchId)/conversation-starters"
        case .getNotifications(let page): return "/notifications?page=\(page)"
        case .getUnreadNotificationCount: return "/notifications/unread-count"
        case .markNotificationRead(let id): return "/notifications/\(id)/read"
        case .markAllNotificationsRead: return "/notifications/mark-all-read"
        case .deleteNotification(let id): return "/notifications/\(id)"
        case .getConversations(let page): return "/messages/conversations?page=\(page)"
        case .getMessages(let conversationId, let before):
            if let before {
                return "/messages/conversations/\(conversationId)/messages?before=\(before)"
            }
            return "/messages/conversations/\(conversationId)/messages"
        case .uploadConversationMedia(let conversationId): return "/messages/conversations/\(conversationId)/media"
        case .sendMessage(let conversationId, _): return "/messages/conversations/\(conversationId)/messages"
        case .markConversationRead(let conversationId): return "/messages/conversations/\(conversationId)/read"
        case .addReaction(let messageId, _): return "/messages/\(messageId)/reactions"
        case .removeReaction(let messageId): return "/messages/\(messageId)/reactions"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .sendOTP, .verifyOTP, .refreshToken, .logout,
             .uploadVoiceIntro, .uploadPhotos, .answerQuestion, .submitVoiceAnswer,
             .likeUser, .passUser, .requestReveal, .createGame, .submitGameResponse,
             .setGameReady,
             .uploadConversationMedia,
             .sendMessage, .addReaction:
            return .POST
        case .me, .getProfile, .getQuestions, .getQuestionsProgress,
             .getCandidates, .getDiscoverStats, .getPendingLikes, .suggestNote, .getMatches, .getMatchById,
             .getComfortScore, .getDateReadiness, .getGame, .getGamesForMatch,
             .getScoreHistory, .getRelationshipInsights, .getConversationStarters,
             .getNotifications, .getUnreadNotificationCount,
             .getConversations, .getMessages:
            return .GET
        case .updateBasicInfo, .reorderPhotos, .updateFCMToken, .updateNotificationPreferences:
            return .PUT
        case .advanceMatchStage, .archiveMatch, .cancelGame, .markConversationRead,
             .markNotificationRead, .markAllNotificationsRead:
            return .PATCH
        case .deletePhoto, .removeReaction, .deleteNotification:
            return .DELETE
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .sendOTP, .verifyOTP, .refreshToken:
            return false
        default:
            return true
        }
    }

    var body: Encodable? {
        switch self {
        case .sendOTP(let req): return req
        case .verifyOTP(let req): return req
        case .refreshToken(let req): return req
        case .updateBasicInfo(let req): return req
        case .reorderPhotos(let req): return req
        case .updateNotificationPreferences(let req): return req
        case .answerQuestion(let req): return req
        case .likeUser(let req): return req
        case .passUser(let req): return req
        case .createGame(let req): return req
        case .setGameReady(_, let ready): return ReadyGameRequest(ready: ready)
        case .submitGameResponse(_, let answer): return SubmitGameResponseRequest(answer: answer)
        case .archiveMatch(_, let reason): return ["reason": reason]
        case .updateFCMToken(let token):
            return ["fcmToken": token]
        case .sendMessage(_, let request): return request
        case .addReaction(_, let emoji): return MessageReactionRequest(emoji: emoji)
        default: return nil
        }
    }
}
