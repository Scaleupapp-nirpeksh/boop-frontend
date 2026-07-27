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
            // Design-review harness (simctl launch env only; unreachable on devices):
            // renders the Me-tab focus card at three stages without signing in.
            if ProcessInfo.processInfo.environment["BOOP_UI_GALLERY"] == "knowyou" {
                KnowYouGalleryView()
            } else if ProcessInfo.processInfo.environment["BOOP_UI_GALLERY"] == "youtwo" {
                YouTwoGalleryView()
            } else if !splashFinished {
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
                // Ask for notification permission once the user reaches the app.
                // Previously this was only ever requested from Profile → Notifications,
                // so most users never granted it → no FCM token → zero pushes.
                // requestAuthorization is idempotent: it prompts only when status is
                // notDetermined, and otherwise just re-registers for remote notifications.
                await PushNotificationService.shared.requestAuthorization()
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
           user.profileStage == .ready || user.profileStage == .preview || user.profileStage == .pairOnly {
            return .main
        }
        return .onboarding
    }

    private var loadingView: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()
            VStack(spacing: BoopSpacing.lg) {
                Text("UnMutee")
                    .font(BoopTypography.cineDisplay)
                    .tracking(6)
                    .foregroundStyle(BoopColors.textPrimary)
                Rectangle()
                    .fill(BoopColors.accentColor)
                    .frame(width: 40, height: 2)
                ProgressView()
                    .tint(BoopColors.textMuted)
            }
        }
    }
}
