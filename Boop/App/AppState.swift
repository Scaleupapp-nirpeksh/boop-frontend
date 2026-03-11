import SwiftUI

@Observable
class AppState {
    var authManager = AuthManager.shared

    enum Route {
        case loading
        case auth
        case onboarding
        case main
    }

    var currentRoute: Route {
        if authManager.isLoading {
            return .loading
        }
        if !authManager.isAuthenticated {
            return .auth
        }
        if let user = authManager.currentUser, user.profileStage == .ready {
            return .main
        }
        return .onboarding
    }

    func bootstrap() async {
        await authManager.bootstrap()
    }
}
