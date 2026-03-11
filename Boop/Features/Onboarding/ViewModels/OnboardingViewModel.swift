import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case basicInfo = 0
    case location
    case bio
    case voiceIntro
    case photos
    case questions

    var title: String {
        switch self {
        case .basicInfo: return "About You"
        case .location: return "Your Location"
        case .bio: return "Your Bio"
        case .voiceIntro: return "Voice Intro"
        case .photos: return "Your Photos"
        case .questions: return "Questions"
        }
    }

    var isSkippable: Bool {
        self == .bio
    }
}

@Observable
class OnboardingViewModel {
    var currentStep: OnboardingStep = .basicInfo
    var isLoading = false
    var errorMessage: String?
    var isComplete = false

    // Basic Info
    var firstName = ""
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -22, to: Date()) ?? Date()
    var gender: Gender?
    var interestedIn: InterestedIn?

    // Location
    var city = ""
    var coordinates: [Double]?

    // Bio
    var bioText = ""

    var totalSteps: Int { OnboardingStep.allCases.count }
    var currentStepNumber: Int { currentStep.rawValue + 1 }

    var canProceedBasicInfo: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && gender != nil
            && interestedIn != nil
    }

    var canProceedLocation: Bool {
        !city.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init() {
        // Resume from correct step based on profile stage
        if let user = AuthManager.shared.currentUser {
            populateFromUser(user)
        }
    }

    private func populateFromUser(_ user: User) {
        firstName = user.firstName ?? ""
        if let dob = user.dateOfBirth { dateOfBirth = dob }
        gender = user.gender
        interestedIn = user.interestedIn
        city = user.location?.city ?? ""
        coordinates = user.location?.coordinates
        bioText = user.bio?.text ?? ""

        // Determine starting step
        switch user.profileStage {
        case .incomplete:
            currentStep = .basicInfo
        case .voicePending:
            currentStep = .voiceIntro
        case .questionsPending:
            // If user already answered 6+ questions, skip onboarding (go to main)
            if (user.questionsAnswered ?? 0) >= 6 {
                isComplete = true
            } else {
                currentStep = .questions
            }
        case .ready:
            isComplete = true
        }
    }

    // MARK: - Submit Basic Info + Location + Bio

    @MainActor
    func submitBasicInfo() async {
        isLoading = true
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var request = UpdateBasicInfoRequest(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            dateOfBirth: formatter.string(from: dateOfBirth),
            gender: gender?.rawValue,
            interestedIn: interestedIn?.rawValue
        )

        if !city.isEmpty {
            request.location = .init(city: city, coordinates: coordinates)
        }

        if !bioText.isEmpty {
            request.bio = bioText
        }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.updateBasicInfo(request))
            AuthManager.shared.updateUser(wrapper.user)
            advanceStep()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to save. Please try again."
        }

        isLoading = false
    }

    @MainActor
    func submitLocationAndBio() async {
        isLoading = true
        errorMessage = nil

        var request = UpdateBasicInfoRequest()
        request.location = .init(city: city, coordinates: coordinates)
        if !bioText.isEmpty {
            request.bio = bioText
        }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.updateBasicInfo(request))
            AuthManager.shared.updateUser(wrapper.user)
            advanceStep()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to save. Please try again."
        }

        isLoading = false
    }

    // MARK: - Navigation

    func advanceStep() {
        if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
        }
    }

    func skipStep() {
        advanceStep()
    }

    @MainActor
    func markComplete() {
        // Refresh user data so RootView re-evaluates routing
        Task {
            if let wrapper: UserWrapper = try? await APIClient.shared.request(.me) {
                AuthManager.shared.updateUser(wrapper.user)
            }
        }
        isComplete = true
    }
}
