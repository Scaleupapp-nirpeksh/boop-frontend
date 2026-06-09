import Foundation
import PostHog

/// Thin wrapper around PostHog for product-funnel analytics.
///
/// The API key below is PostHog's *write-only* project token — safe to ship in
/// a public app (it can only ingest events, not read data). Region: US Cloud.
enum Analytics {
    private static let projectToken = "phc_zPxQMBcMqnwFzsqapdvMHbi3gfMeteB5uTNcXxAcEYxb"
    private static let host = "https://us.i.posthog.com"

    /// Call once at app launch.
    static func bootstrap() {
        let config = PostHogConfig(apiKey: projectToken, host: host)
        config.captureApplicationLifecycleEvents = true   // app opened / backgrounded
        config.captureScreenViews = false                 // we track funnel events explicitly
        PostHogSDK.shared.setup(config)
    }

    /// Tie subsequent events to a known user (call after login / on bootstrap).
    static func identify(_ userId: String, _ properties: [String: Any] = [:]) {
        guard !userId.isEmpty else { return }
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }

    /// Capture a funnel/product event.
    static func capture(_ event: String, _ properties: [String: Any] = [:]) {
        PostHogSDK.shared.capture(event, properties: properties)
    }

    /// Clear identity on logout.
    static func reset() {
        PostHogSDK.shared.reset()
    }
}
