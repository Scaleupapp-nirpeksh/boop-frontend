import Foundation

struct User: Codable, Identifiable {
    let id: String
    let phone: String
    let phoneVerified: Bool
    var firstName: String?
    var dateOfBirth: Date?
    var gender: Gender?
    var interestedIn: InterestedIn?
    var username: String?
    var location: UserLocation?
    var bio: UserBio?
    var voiceIntro: VoiceIntro?
    var photos: UserPhotos?
    var questionsAnswered: Int
    var profileStage: ProfileStage
    var isPremium: Bool?
    var isOnline: Bool?
    var lastSeen: Date?
    var fcmToken: String?
    var notificationPreferences: UserNotificationPreferences?
    var createdAt: Date?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case phone, phoneVerified, firstName, dateOfBirth, gender
        case interestedIn, username, location, bio, voiceIntro, photos
        case questionsAnswered, profileStage, isPremium, isOnline
        case lastSeen, fcmToken, notificationPreferences, createdAt, updatedAt
    }
}

enum Gender: String, Codable, CaseIterable {
    case male, female
    case nonBinary = "non-binary"
    case other

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .nonBinary: return "Non-binary"
        case .other: return "Other"
        }
    }
}

enum InterestedIn: String, Codable, CaseIterable {
    case men, women, everyone

    var displayName: String {
        switch self {
        case .men: return "Men"
        case .women: return "Women"
        case .everyone: return "Everyone"
        }
    }
}

enum ProfileStage: String, Codable {
    case incomplete
    case voicePending = "voice_pending"
    case questionsPending = "questions_pending"
    case ready
}

struct UserLocation: Codable {
    var city: String?
    var coordinates: [Double]?
}

struct UserBio: Codable {
    var text: String?
    var audioUrl: String?
    var audioDuration: Double?
    var transcription: String?
}

struct VoiceIntro: Codable {
    var audioUrl: String?
    var s3Key: String?
    var duration: Double?
    var transcription: String?
    var createdAt: Date?
}

struct UserPhotos: Codable {
    var items: [PhotoItem]
    var profilePhoto: ProfilePhoto?
    var totalPhotos: Int

    struct PhotoItem: Codable, Identifiable {
        var id: String { s3Key ?? url }
        let url: String
        var s3Key: String?
        var order: Int
        var uploadedAt: Date?
    }

    struct ProfilePhoto: Codable {
        var url: String?
        var s3Key: String?
        var blurredUrl: String?
        var silhouetteUrl: String?
    }
}

struct UserNotificationPreferences: Codable {
    var allMuted: Bool
    var quietHoursStart: String?
    var quietHoursEnd: String?
    var timezone: String
}
