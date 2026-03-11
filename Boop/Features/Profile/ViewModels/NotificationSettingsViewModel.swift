import Foundation

@MainActor
@Observable
final class NotificationSettingsViewModel {
    var allMuted = false
    var quietHoursEnabled = false
    var quietHoursStart = "22:00"
    var quietHoursEnd = "07:00"
    var timezone = TimeZone.current.identifier
    var isSaving = false
    var errorMessage: String?
    var successMessage: String?

    func loadFromCurrentUser() {
        let preferences = AuthManager.shared.currentUser?.notificationPreferences
        allMuted = preferences?.allMuted ?? false
        quietHoursStart = preferences?.quietHoursStart ?? "22:00"
        quietHoursEnd = preferences?.quietHoursEnd ?? "07:00"
        timezone = preferences?.timezone ?? TimeZone.current.identifier
        quietHoursEnabled = preferences?.quietHoursStart != nil && preferences?.quietHoursEnd != nil
    }

    func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(
                .updateNotificationPreferences(
                    UpdateNotificationPreferencesRequest(
                        allMuted: allMuted,
                        quietHoursStart: quietHoursEnabled ? quietHoursStart : nil,
                        quietHoursEnd: quietHoursEnabled ? quietHoursEnd : nil,
                        timezone: timezone
                    )
                )
            )
            AuthManager.shared.updateUser(wrapper.user)
            errorMessage = nil
            successMessage = "Notification preferences updated."
        } catch let error as APIError {
            errorMessage = error.errorDescription
            successMessage = nil
        } catch {
            errorMessage = "Could not update notification preferences."
            successMessage = nil
        }
    }
}
