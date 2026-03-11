import SwiftUI

struct MainTabView: View {
    @State private var viewModel = MainTabViewModel()
    @State private var homeNavigationPath = NavigationPath()
    @State private var chatNavigationPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase

    private var router: NotificationRouter { NotificationRouter.shared }

    var body: some View {
        TabView(selection: Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )) {
            NavigationStack(path: $homeNavigationPath) {
                HomeView()
                    .navigationDestination(for: MatchRoute.self) { route in
                        MatchDetailView(matchId: route.matchId)
                    }
                    .navigationDestination(for: GameRoute.self) { route in
                        GameSessionView(gameId: route.gameId)
                    }
                    .navigationDestination(for: NotificationRoute.self) { _ in
                        NotificationInboxView()
                    }
            }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            NavigationStack {
                DiscoverView()
            }
                .tabItem {
                    Image(systemName: "sparkle.magnifyingglass")
                    Text("Discover")
                }
                .tag(1)

            NavigationStack(path: $chatNavigationPath) {
                ChatInboxView()
                    .navigationDestination(for: ChatRoute.self) { route in
                        MatchConversationLoaderView(matchId: route.matchId)
                    }
            }
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat")
                }
                .badge(viewModel.unreadChatCount)
                .tag(2)

            NavigationStack {
                ProfileView()
            }
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Me")
                }
                .tag(3)
        }
        .tint(BoopColors.primary)
        .task {
            await viewModel.loadBadges()
        }
        .onChange(of: router.pendingDestination) { _, destination in
            guard let destination else { return }
            handleDeepLink(destination)
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageNew)) { _ in
            Task { await viewModel.loadBadges() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageRead)) { _ in
            Task { await viewModel.loadBadges() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeStatusChanged)) { _ in
            if RealtimeService.shared.connectionState == .connected {
                Task { await viewModel.loadBadges() }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                RealtimeService.shared.connect(token: AuthManager.shared.accessToken)
                Task {
                    await viewModel.loadBadges()
                    await PushNotificationService.shared.updateBadgeFromServer()
                }
            case .background:
                RealtimeService.shared.disconnect()
            default:
                break
            }
        }
    }

    private func handleDeepLink(_ destination: NotificationRouter.Destination) {
        _ = router.consumeDestination()

        switch destination {
        case .chat(let matchId):
            chatNavigationPath = NavigationPath()
            chatNavigationPath.append(ChatRoute(matchId: matchId))
        case .match(let matchId):
            homeNavigationPath = NavigationPath()
            homeNavigationPath.append(MatchRoute(matchId: matchId))
        case .game(let gameId):
            homeNavigationPath = NavigationPath()
            homeNavigationPath.append(GameRoute(gameId: gameId))
        case .home:
            homeNavigationPath = NavigationPath()
        }
    }
}

struct MatchRoute: Hashable {
    let matchId: String
}

struct ChatRoute: Hashable {
    let matchId: String
}

struct GameRoute: Hashable {
    let gameId: String
}

@Observable
final class MainTabViewModel {
    var unreadChatCount = 0

    @MainActor
    func loadBadges() async {
        do {
            let response: ConversationsResponse = try await APIClient.shared.request(.getConversations())
            unreadChatCount = response.conversations.reduce(0) { $0 + $1.unreadCount }
        } catch {
            unreadChatCount = 0
        }
    }
}

#Preview {
    MainTabView()
}
