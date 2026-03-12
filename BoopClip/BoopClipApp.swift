import SwiftUI

@main
struct BoopClipApp: App {
    var body: some Scene {
        WindowGroup {
            ProfilePreviewView()
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    ProfilePreviewView.extractUserId(from: url)
                }
        }
    }
}
