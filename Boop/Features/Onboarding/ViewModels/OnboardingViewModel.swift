import SwiftUI

/// Reward-first onboarding: basic info, then the 8 onboarding questions.
/// Voice + photos + extended bio/location are deferred to a later
/// "connect-setup" / profile-editing flow (their views remain in the project).
enum OnboardingStep: Int, CaseIterable {
    case basicInfo = 0
    case questions

    var title: String {
        switch self {
        case .basicInfo: return "About You"
        case .questions: return "Questions"
        }
    }

    var isSkippable: Bool {
        false
    }
}

@Observable
class OnboardingViewModel {
    var currentStep: OnboardingStep = .basicInfo
    var isLoading = false
    var errorMessage: String?
    var isComplete = false

    // "Us" invited-user fork: set after basic info when a pending pair code
    // redeems successfully — asks whether they also want the dating side.
    var showPairFork = false
    var pairPartnerName: String?

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

        // Determine starting step. Basic info is collected first; once the
        // backend has it the user moves on to the 8 onboarding questions.
        // Voice is deferred, so a `voicePending` user resumes at questions.
        switch user.profileStage {
        case .incomplete:
            currentStep = .basicInfo
        case .voicePending, .questionsPending:
            currentStep = .questions
        case .preview, .ready, .pairOnly:
            isComplete = true
        }
    }

    // MARK: - "Us" pair fork (invited users)

    @MainActor
    private func redeemPendingPairCodeIfAny() async {
        guard let code = UserDefaults.standard.string(forKey: "pendingPairCode"),
              !code.isEmpty else { return }
        UserDefaults.standard.removeObject(forKey: "pendingPairCode")
        do {
            let result: PairRedeemResponse = try await APIClient.shared.request(
                .redeemPairCode(code: code)
            )
            pairPartnerName = result.partner.firstName
            showPairFork = true
        } catch {
            // Invalid/expired code — continue onboarding normally.
        }
    }

    /// Fork: "Yes, show me around" — they want dating too.
    @MainActor
    func choosePairAndDating() async {
        _ = try? await APIClient.shared.requestVoid(.setDatingMode(enabled: true))
        await AuthManager.shared.fetchCurrentUser()
        showPairFork = false
    }

    /// Fork: "Not now — just Us" — pair-only account, straight to the app.
    @MainActor
    func choosePairOnly() async {
        await AuthManager.shared.fetchCurrentUser()
        showPairFork = false
        isComplete = true
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
            await redeemPendingPairCodeIfAny()
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
            await redeemPendingPairCodeIfAny()
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
