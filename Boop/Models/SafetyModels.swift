import Foundation

struct ReportUserRequest: Encodable {
    let userId: String
    let reason: String
    let details: String?
    let contentType: String
}

enum ReportReason: String, CaseIterable, Identifiable {
    case harassment
    case inappropriateMessages = "inappropriate_messages"
    case inappropriatePhotos = "inappropriate_photos"
    case fakeProfile = "fake_profile"
    case underage
    case spam
    case safetyConcern = "safety_concern"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .harassment: return "Harassment or bullying"
        case .inappropriateMessages: return "Inappropriate messages"
        case .inappropriatePhotos: return "Inappropriate photos"
        case .fakeProfile: return "Fake profile / catfishing"
        case .underage: return "Appears to be under 18"
        case .spam: return "Spam or scam"
        case .safetyConcern: return "I'm concerned about my safety"
        case .other: return "Something else"
        }
    }
}
