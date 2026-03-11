import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState
    private let authManager = AuthManager.shared
    @State private var didBootstrap = false
    @State private var splashFinished = false
    @State private var introFinished = false

    @AppStorage("hasSeenIntro") private var hasSeenIntro = false

    var body: some View {
        Group {
            if !splashFinished {
                SplashView(isFinished: $splashFinished)
            } else if !hasSeenIntro && !introFinished {
                OnboardingIntroView(isFinished: $introFinished)
                    .transition(.opacity)
                    .onChange(of: introFinished) { _, done in
                        if done { hasSeenIntro = true }
                    }
            } else {
                mainContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: splashFinished)
        .animation(.easeInOut(duration: 0.4), value: introFinished)
        .task {
            guard !didBootstrap else { return }
            didBootstrap = true
            await appState.bootstrap()
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        Group {
            switch currentRoute {
            case .loading:
                loadingView
            case .auth:
                NavigationStack {
                    WelcomeView()
                }
            case .onboarding:
                NavigationStack {
                    OnboardingContainerView()
                }
            case .main:
                MainTabView()
            }
        }
        .task(id: currentRoute) {
            if currentRoute == .main {
                RealtimeService.shared.connect(token: authManager.accessToken)
                await PushNotificationService.shared.refreshStatus()
                await PushNotificationService.shared.syncTokenToBackendIfPossible()
            } else {
                RealtimeService.shared.disconnect()
            }
        }
    }

    private var currentRoute: AppState.Route {
        if authManager.isLoading {
            return .loading
        }
        if !authManager.isAuthenticated {
            return .auth
        }
        if let user = authManager.currentUser,
           user.profileStage == .ready ||
           (user.profileStage == .questionsPending && (user.questionsAnswered ?? 0) >= 6) {
            return .main
        }
        return .onboarding
    }

    private var loadingView: some View {
        ZStack {
            BoopColors.background.ignoresSafeArea()
            VStack(spacing: BoopSpacing.lg) {
                BoopLogo(size: 120, animated: true)
                ProgressView()
                    .tint(BoopColors.primary)
            }
        }
    }
}
