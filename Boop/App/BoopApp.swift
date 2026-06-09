import SwiftUI

@main
struct BoopApp: App {
    @UIApplicationDelegateAdaptor(BoopAppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    init() {
        Analytics.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
        }
    }
}
