import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let questionNumber: Int
    let questionText: String
    let dimension: String
    let questionType: QuestionType
    let dayAvailable: Int
    let order: Int
    var options: [String]?
    var characterLimit: Int?
    var depthLevel: String?
    /// True for the small set of questions shown during reward-first onboarding.
    /// Optional/default-safe: treat nil as false.
    var isOnboarding: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case questionNumber, questionText, dimension, questionType
        case dayAvailable, order, options, characterLimit, depthLevel
        case isOnboarding
    }

    var dimensionDisplayName: String {
        switch dimension {
        case "emotional_vulnerability": return "Emotional Vulnerability"
        case "attachment_patterns": return "Attachment Patterns"
        case "life_vision": return "Life Vision"
        case "conflict_resolution": return "Conflict Resolution"
        case "love_expression": return "Love Expression"
        case "intimacy_comfort": return "Intimacy Comfort"
        case "lifestyle_rhythm": return "Lifestyle Rhythm"
        case "growth_mindset": return "Growth Mindset"
        default: return dimension.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

enum QuestionType: String, Codable {
    case text
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
}
