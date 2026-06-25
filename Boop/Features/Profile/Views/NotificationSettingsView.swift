import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var viewModel = NotificationSettingsViewModel()
    @State private var pushService = PushNotificationService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                statusSection
                preferencesSection
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadFromCurrentUser()
            await pushService.refreshStatus()
            await pushService.syncTokenToBackendIfPossible()
        }
    }

    // MARK: - Device status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                Circle()
                    .fill(statusTint)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                    Text(simpleStatusTitle)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text(simpleStatusMessage)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if pushService.authorizationStatus == .notDetermined {
                BoopButton(title: "Turn on notifications", variant: .primary, fullWidth: true) {
                    Task { await pushService.requestAuthorization() }
                }
            } else if pushService.authorizationStatus == .denied {
                BoopButton(title: "Open Settings", variant: .outline, fullWidth: true) {
                    pushService.openSystemSettings()
                }
            }
        }
    }

    private var simpleStatusTitle: String {
        switch pushService.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Notifications are on"
        case .denied: return "Notifications are off"
        default: return "Stay in the loop"
        }
    }

    private var simpleStatusMessage: String {
        switch pushService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "We'll let you know about new matches, messages and reveals."
        case .denied:
            return "Turn them on in Settings to hear about new matches, messages and reveals."
        default:
            return "Get notified about new matches, messages and reveals."
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Preferences")

            VStack(spacing: 0) {
                toggleRow("Mute all notifications", isOn: $viewModel.allMuted)
                toggleRow("Use quiet hours", isOn: $viewModel.quietHoursEnabled)
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }

            if viewModel.quietHoursEnabled {
                VStack(spacing: 0) {
                    quietHoursField(title: "Starts", text: $viewModel.quietHoursStart)
                    quietHoursField(title: "Ends", text: $viewModel.quietHoursEnd)
                    quietHoursField(title: "Timezone", text: $viewModel.timezone)
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }

            if let success = viewModel.successMessage {
                Text(success)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.success)
            }

            BoopButton(title: "Save Preferences", isLoading: viewModel.isSaving) {
                Task { await viewModel.save() }
            }
            .padding(.top, BoopSpacing.xs)
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            Toggle(isOn: isOn) {
                Text(title)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
            }
            .tint(BoopColors.accentColor)
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private func quietHoursField(title: String, text: Binding<String>) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.md) {
                EyebrowLabel(text: title)
                Spacer()
                TextField(title, text: text)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private var statusTint: Color {
        switch pushService.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return BoopColors.success
        case .denied:
            return BoopColors.error
        default:
            return BoopColors.textMuted
        }
    }
}
