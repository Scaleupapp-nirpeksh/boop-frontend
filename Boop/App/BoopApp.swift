import SwiftUI

@main
struct BoopApp: App {
    @UIApplicationDelegateAdaptor(BoopAppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
        }
    }
}
