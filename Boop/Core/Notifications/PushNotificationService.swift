import FirebaseCore
import FirebaseMessaging
import SwiftUI
import UIKit
import UserNotifications

@MainActor
@Observable
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    enum RegistrationState: Equatable {
        case unavailable
        case idle
        case requestingPermission
        case registering
        case ready
        case failed
    }

    private(set) var registrationState: RegistrationState = .idle
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var fcmToken: String?
    private(set) var backendTokenSynced = false
    private(set) var lastErrorMessage: String?
    private(set) var isFirebaseConfigured = false

    private override init() {
        super.init()
    }

    func configureIfPossible() {
        guard !isFirebaseConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            registrationState = .unavailable
            lastErrorMessage = "Add GoogleService-Info.plist to enable push delivery."
            return
        }

        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        isFirebaseConfigured = true
        registrationState = .idle
        lastErrorMessage = nil
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus

        if !isFirebaseConfigured {
            registrationState = .unavailable
        } else if authorizationStatus == .authorized || authorizationStatus == .provisional {
            UIApplication.shared.registerForRemoteNotifications()
            registrationState = backendTokenSynced ? .ready : .idle
        } else {
            registrationState = .idle
        }
    }

    func requestAuthorization() async {
        if !isFirebaseConfigured {
            registrationState = .unavailable
            return
        }

        registrationState = .requestingPermission
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
            guard granted else { return }
            UIApplication.shared.registerForRemoteNotifications()
            registrationState = .registering
        } catch {
            registrationState = .failed
            lastErrorMessage = "Notification permission request failed."
        }
    }

    func handleAPNSToken(_ deviceToken: Data) {
        guard isFirebaseConfigured else { return }
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { [weak self] token, error in
            Task { @MainActor in
                if let error {
                    self?.registrationState = .failed
                    self?.lastErrorMessage = error.localizedDescription
                    return
                }
                self?.consumeFCMToken(token)
            }
        }
    }

    func consumeFCMToken(_ token: String?) {
        guard let token, !token.isEmpty else { return }
        fcmToken = token
        registrationState = .registering
        Task {
            await syncTokenToBackendIfPossible()
        }
    }

    func handleRegistrationError(_ error: Error) {
        registrationState = .failed
        lastErrorMessage = error.localizedDescription
    }

    func syncTokenToBackendIfPossible() async {
        guard let token = fcmToken,
              AuthManager.shared.isAuthenticated else { return }

        do {
            try await APIClient.shared.requestVoid(.updateFCMToken(token: token))
            backendTokenSynced = true
            registrationState = .ready
            lastErrorMessage = nil
        } catch let error as APIError {
            backendTokenSynced = false
            registrationState = .failed
            lastErrorMessage = error.errorDescription
        } catch {
            backendTokenSynced = false
            registrationState = .failed
            lastErrorMessage = "Could not register this device for push notifications."
        }
    }

    // MARK: - Badge Management

    func updateBadgeFromServer() async {
        do {
            let response: UnreadCountResponse = try await APIClient.shared.request(.getUnreadNotificationCount)
            try await UNUserNotificationCenter.current().setBadgeCount(response.unreadCount)
        } catch {
            // Non-critical
        }
    }

    func clearBadge() {
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    var statusTitle: String {
        if !isFirebaseConfigured {
            return "Push setup missing"
        }

        switch authorizationStatus {
        case .authorized, .provisional:
            return backendTokenSynced ? "Push is ready" : "Finishing setup"
        case .denied:
            return "Notifications blocked"
        case .notDetermined:
            return "Notifications off"
        case .ephemeral:
            return "Temporary permission"
        @unknown default:
            return "Notification status unknown"
        }
    }

    var statusMessage: String {
        if !isFirebaseConfigured {
            return "The app is missing GoogleService-Info.plist, so FCM cannot issue a token yet."
        }
        if authorizationStatus == .denied {
            return "Enable notifications in iOS Settings to receive matches and messages."
        }
        if fcmToken == nil {
            #if targetEnvironment(simulator)
            return "Permission can be tested in Simulator, but a real iPhone is needed for push token delivery."
            #else
            return "Grant permission and the app will register this device."
            #endif
        }
        if !backendTokenSynced {
            return "The device token exists, but it has not been synced to the backend yet."
        }
        return "New matches, messages, reveals, and games can notify this device."
    }
}

extension PushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            PushNotificationService.shared.consumeFCMToken(fcmToken)
        }
    }
}

final class BoopAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationService.shared.configureIfPossible()
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
        Task { @MainActor in
            await PushNotificationService.shared.refreshStatus()
        }
        return true
    }

    // MARK: - Notification Categories & Actions

    private func registerNotificationCategories() {
        // New message — quick reply action
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type a reply..."
        )
        let viewChatAction = UNNotificationAction(
            identifier: "VIEW_CHAT_ACTION",
            title: "View Chat",
            options: [.foreground]
        )
        let messageCategory = UNNotificationCategory(
            identifier: "new_message",
            actions: [replyAction, viewChatAction],
            intentIdentifiers: [],
            options: []
        )

        // New match
        let viewMatchAction = UNNotificationAction(
            identifier: "VIEW_MATCH_ACTION",
            title: "View Match",
            options: [.foreground]
        )
        let matchCategory = UNNotificationCategory(
            identifier: "new_match",
            actions: [viewMatchAction],
            intentIdentifiers: [],
            options: []
        )

        // Like received
        let viewProfileAction = UNNotificationAction(
            identifier: "VIEW_PROFILE_ACTION",
            title: "View Profile",
            options: [.foreground]
        )
        let likeCategory = UNNotificationCategory(
            identifier: "like_received",
            actions: [viewProfileAction],
            intentIdentifiers: [],
            options: []
        )

        // Game invite
        let playAction = UNNotificationAction(
            identifier: "PLAY_GAME_ACTION",
            title: "Play",
            options: [.foreground]
        )
        let gameCategory = UNNotificationCategory(
            identifier: "game_invite",
            actions: [playAction],
            intentIdentifiers: [],
            options: []
        )

        // Reveal request
        let viewRevealAction = UNNotificationAction(
            identifier: "VIEW_REVEAL_ACTION",
            title: "View",
            options: [.foreground]
        )
        let revealCategory = UNNotificationCategory(
            identifier: "reveal_request",
            actions: [viewRevealAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            messageCategory, matchCategory, likeCategory, gameCategory, revealCategory
        ])
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationService.shared.handleAPNSToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            PushNotificationService.shared.handleRegistrationError(error)
        }
    }

    // Show banner when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }

    // Handle notification tap and actions — deep link routing
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionId = response.actionIdentifier

        Task { @MainActor in
            // Handle quick reply action
            if actionId == "REPLY_ACTION",
               let textResponse = response as? UNTextInputNotificationResponse,
               let conversationId = userInfo["conversationId"] as? String {
                do {
                    try await APIClient.shared.requestVoid(
                        .sendMessage(conversationId: conversationId, request: SendMessageRequest(
                            text: textResponse.userText
                        ))
                    )
                } catch {
                    // Fall through to open chat
                }
            }

            // Route to appropriate screen
            NotificationRouter.shared.handleNotificationPayload(userInfo)

            // Update badge
            await PushNotificationService.shared.updateBadgeFromServer()
        }
        completionHandler()
    }
}
