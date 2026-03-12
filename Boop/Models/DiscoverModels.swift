import Foundation

// MARK: - Candidate (from GET /discover)

struct Candidate: Codable, Identifiable {
    let userId: String
    let firstName: String
    let age: Int?
    let city: String?
    let photos: CandidatePhotos
    let voiceIntro: CandidateVoiceIntro
    let compatibility: CandidateCompatibility
    let showcaseAnswers: [ShowcaseAnswer]

    var id: String { userId }

    struct CandidatePhotos: Codable {
        let silhouetteUrl: String?
        let blurredUrl: String?
    }

    struct CandidateVoiceIntro: Codable {
        let audioUrl: String?
        let duration: Double?
    }

    struct CandidateCompatibility: Codable {
        let score: Int
        let tier: String
        let tierLabel: String
        let dimensions: [String: Double]?

        var tierEmoji: String {
            switch tier {
            case "platinum": return "💎"
            case "gold": return "💛"
            case "silver": return "🤍"
            case "bronze": return "🧡"
            default: return "✨"
            }
        }

        var tierDisplayName: String {
            switch tier {
            case "platinum": return "Rare Match"
            case "gold": return "Strong Match"
            case "silver": return "Good Match"
            case "bronze": return "Early Spark"
            default: return tierLabel
            }
        }
    }
}

struct ShowcaseAnswer: Codable, Identifiable {
    let questionText: String
    let dimension: String
    let depthLevel: String?
    let answer: String
    let questionType: String

    var id: String { questionText + answer }

    var dimensionDisplayName: String {
        dimension
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - Discover Stats (from GET /discover/stats)

struct DiscoverStats: Codable {
    let newMatches: Int
    let activeConnections: Int
    let totalCandidates: Int
}

struct PendingLikesResponse: Codable {
    let incoming: [PendingLikeProfile]
    let outgoing: [PendingLikeProfile]
}

struct PendingLikeProfile: Codable, Identifiable {
    let userId: String
    let firstName: String
    let age: Int?
    let city: String?
    let photos: Candidate.CandidatePhotos
    let voiceIntro: Candidate.CandidateVoiceIntro
    let compatibilityScore: Int?
    let matchTier: String?
    let likedAt: Date?
    let note: LikeNote?

    var id: String { userId }
}

// MARK: - Note Suggestions (from GET /discover/suggest-note/:targetUserId)

struct NoteSuggestionsResponse: Codable {
    let suggestions: [NoteSuggestion]
}

struct NoteSuggestion: Codable, Identifiable {
    let text: String
    let reason: String

    var id: String { text }
}

// MARK: - Conversation Starters (from GET /matches/:matchId/conversation-starters)

struct ConversationStartersResponse: Codable {
    let starters: [ConversationStarter]
}

struct ConversationStarter: Codable, Identifiable {
    let text: String
    let category: String

    var id: String { text }

    var categoryIcon: String {
        switch category {
        case "shared_interest": return "star.fill"
        case "deeper_question": return "heart.text.square"
        case "fun_hypothetical": return "lightbulb.fill"
        case "about_their_answer": return "quote.bubble.fill"
        default: return "bubble.left.fill"
        }
    }
}

// MARK: - Like Response (from POST /discover/like)

struct LikeResponse: Codable {
    let isMutual: Bool
    let match: MutualMatchInfo?

    struct MutualMatchInfo: Codable {
        let matchId: String
        let compatibilityScore: Int
        let matchTier: String
    }
}

// MARK: - Match (from GET /matches)

struct BoopData: Codable {
    let senderId: String?
    let sentAt: Date?
}

struct StreakData: Codable {
    let current: Int?
    let longest: Int?
    let lastActiveDate: Date?
}

struct MatchInfo: Codable, Identifiable {
    let matchId: String
    let stage: String
    let compatibilityScore: Int?
    let matchTier: String?
    let comfortScore: Int?
    let matchedAt: Date?
    let lastBoop: BoopData?
    let boopCount: Int?
    let streak: StreakData?
    let otherUser: MatchOtherUser

    var id: String { matchId }

    var stageIndex: Int {
        switch stage {
        case "mutual": return 0
        case "connecting": return 1
        case "reveal_ready": return 2
        case "revealed": return 3
        case "dating": return 4
        default: return 0
        }
    }

    var stageEmoji: String {
        switch stage {
        case "mutual": return "✨"
        case "connecting": return "💬"
        case "reveal_ready": return "🔓"
        case "revealed": return "📸"
        case "dating": return "☕"
        default: return "✨"
        }
    }

    var stageLabel: String {
        switch stage {
        case "mutual": return "Just Matched"
        case "connecting": return "Getting to Know"
        case "reveal_ready": return "Ready to Reveal"
        case "revealed": return "Photos Revealed"
        case "dating": return "Date Ready"
        default: return "New"
        }
    }

    var daysSinceMatch: Int {
        guard let matchedAt else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: matchedAt, to: Date()).day ?? 1)
    }
}

struct MatchOtherUser: Codable {
    let userId: String
    let firstName: String
    let age: Int?
    let city: String?
    let isOnline: Bool?
    let lastSeen: Date?
    let blurLevel: Int?
    let voiceIntro: MatchVoiceIntro?
    let photos: MatchPhotos

    struct MatchVoiceIntro: Codable {
        let audioUrl: String?
        let duration: Double?
    }

    struct MatchPhotos: Codable {
        // Pre-reveal
        let silhouetteUrl: String?
        let blurredUrl: String?
        // Post-reveal
        let profilePhotoUrl: String?
        let items: [MatchPhotoItem]?

        struct MatchPhotoItem: Codable {
            let url: String
            let order: Int
        }
    }
}

struct MatchesResponse: Codable {
    let matches: [MatchInfo]
    let total: Int
    let page: Int
    let totalPages: Int
}

// MARK: - Wrapper for candidates response

struct CandidatesWrapper: Decodable {
    let candidates: [Candidate]
}
