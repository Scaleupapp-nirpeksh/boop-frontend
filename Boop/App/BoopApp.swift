import SwiftUI

@main
struct BoopApp: App {
    @UIApplicationDelegateAdaptor(BoopAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @AppStorage("appTheme") private var appTheme = AppTheme.dark.rawValue

    init() {
        Analytics.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)
        }
    }
}
