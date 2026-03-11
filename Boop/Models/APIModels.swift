import Foundation

// MARK: - Auth

struct SendOTPRequest: Encodable {
    let phone: String
}

struct SendOTPResponse: Decodable {
    let phone: String
    let expiresIn: Int
}

struct VerifyOTPRequest: Encodable {
    let phone: String
    let otp: String
}

struct VerifyOTPResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let user: User?
}

// MARK: - Wrapper for endpoints that return { user: ... }

struct UserWrapper: Decodable {
    let user: User
}

struct ProfileWrapper: Decodable {
    let user: User
}

// MARK: - Profile

struct UpdateBasicInfoRequest: Encodable {
    var firstName: String?
    var dateOfBirth: String?
    var gender: String?
    var interestedIn: String?
    var bio: String?
    var location: LocationUpdate?

    struct LocationUpdate: Encodable {
        let city: String
        var coordinates: [Double]?
    }
}

struct ReorderPhotosRequest: Encodable {
    let orderedPhotoIds: [String]
    let mainPhotoId: String?
}

struct UpdateNotificationPreferencesRequest: Encodable {
    let allMuted: Bool
    let quietHoursStart: String?
    let quietHoursEnd: String?
    let timezone: String
}

// MARK: - Questions

struct SubmitAnswerRequest: Encodable {
    let questionNumber: Int
    var textAnswer: String?
    var selectedOption: String?
    var selectedOptions: [String]?
    var followUpAnswer: String?
    var timeSpent: Int?
}

struct SubmitAnswerResponse: Decodable {
    let answer: AnswerRecord
    let questionsAnswered: Int
    let profileStage: String

    struct AnswerRecord: Decodable {
        let id: String?

        enum CodingKeys: String, CodingKey {
            case id = "_id"
        }
    }
}

// MARK: - Discover

struct LikeRequest: Encodable {
    let targetUserId: String
    let note: LikeNote?

    init(targetUserId: String, note: LikeNote? = nil) {
        self.targetUserId = targetUserId
        self.note = note
    }
}

struct LikeNote: Codable {
    let type: String
    let content: String
    let duration: Double?

    init(type: String = "text", content: String, duration: Double? = nil) {
        self.type = type
        self.content = content
        self.duration = duration
    }
}

struct PassRequest: Encodable {
    let targetUserId: String
}

// MARK: - Available Questions Response

struct AvailableQuestionsResponse: Decodable {
    let questions: [Question]
    let meta: QuestionsMeta

    struct QuestionsMeta: Decodable {
        let daysSinceRegistration: Int
        let totalUnlocked: Int
        let totalAnswered: Int
        let totalRemaining: Int
    }
}

struct QuestionsProgressResponse: Decodable {
    let totalAnswered: Int
    let totalUnlocked: Int
    let totalQuestions: Int
    let daysSinceRegistration: Int
    let profileStage: String
    let readyThreshold: Int
    let isReady: Bool
    let dimensions: [String: QuestionDimensionProgress]
}

struct QuestionDimensionProgress: Decodable, Identifiable {
    let answered: Int
    let unlocked: Int
    let total: Int

    var id: String { "\(answered)-\(unlocked)-\(total)" }
}

// MARK: - Answer History

struct AnswerHistoryResponse: Decodable {
    let history: [AnswerHistoryItem]
    let groupedByDimension: [String: [AnswerHistoryItem]]?
}

struct AnswerHistoryItem: Decodable, Identifiable {
    let id: String
    let questionNumber: Int
    let questionText: String
    let dimension: String
    let questionType: String
    let textAnswer: String?
    let selectedOption: String?
    let selectedOptions: [String]?
    let followUpAnswer: String?
    let submittedAt: Date?
}

// MARK: - Personality Analysis

struct PersonalityAnalysisResponse: Decodable {
    let analysis: PersonalityAnalysis?
    let nextMilestone: Int
    let questionsUntilNext: Int
    let isPreliminary: Bool
}

struct PersonalityAnalysis: Decodable, Identifiable {
    let id: String
    let personalityType: String
    let summary: String
    let facets: [PersonalityFacet]
    let numerology: NumerologyData?
    let questionsAnalyzed: Int
    let isPreliminary: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case personalityType, summary, facets, numerology
        case questionsAnalyzed, isPreliminary, createdAt
    }
}

struct PersonalityFacet: Decodable, Identifiable {
    let key: String
    let title: String
    let score: Int
    let description: String
    let emoji: String

    var id: String { key }
}

struct NumerologyData: Decodable {
    let lifePathNumber: Int
    let expressionNumber: Int?
    let traits: [String]
    let description: String
}

// MARK: - Games

struct CreateGameRequest: Encodable {
    let matchId: String
    let gameType: String
}

struct SubmitGameResponseRequest: Encodable {
    let answer: String
}

struct ReadyGameRequest: Encodable {
    let ready: Bool
}

struct UploadedConversationMediaResponse: Decodable {
    let mediaUrl: String
    let mediaType: String
    let mediaDuration: Double?
}
