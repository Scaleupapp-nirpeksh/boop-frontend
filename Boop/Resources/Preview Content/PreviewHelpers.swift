import Foundation

enum PreviewData {
    static let sampleUser = User(
        id: "preview_user_1",
        phone: "+919876543210",
        phoneVerified: true,
        firstName: "Priya",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()),
        gender: .female,
        interestedIn: .men,
        location: UserLocation(city: "Mumbai", coordinates: [72.8777, 19.0760]),
        bio: UserBio(text: "Coffee lover, book worm, and occasional dancer"),
        voiceIntro: nil,
        photos: UserPhotos(items: [], profilePhoto: nil, totalPhotos: 0),
        questionsAnswered: 0,
        profileStage: .incomplete,
        isOnline: true,
        lastSeen: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )

    static let sampleQuestion = Question(
        id: "q1",
        questionNumber: 1,
        questionText: "What does a perfect Sunday morning look like for you?",
        dimension: "lifestyle_rhythm",
        questionType: .text,
        dayAvailable: 1,
        order: 1,
        options: nil,
        characterLimit: 300
    )
}
