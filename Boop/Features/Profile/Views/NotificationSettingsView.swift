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
            EyebrowLabel(text: "Device status")
            AccentRule()

            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                Circle()
                    .fill(statusTint)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                    Text(pushService.statusTitle)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text(pushService.statusMessage)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }

            if let token = pushService.fcmToken {
                Text("FCM TOKEN \(token.prefix(16))…")
                    .font(BoopTypography.cineCaption)
                    .tracking(1)
                    .foregroundStyle(BoopColors.textMuted)
            }

            HStack(spacing: BoopSpacing.sm) {
                if pushService.authorizationStatus == .notDetermined {
                    BoopButton(title: "Enable", variant: .primary, isLoading: pushService.registrationState == .requestingPermission, fullWidth: false) {
                        Task { await pushService.requestAuthorization() }
                    }
                }

                if pushService.authorizationStatus == .denied {
                    BoopButton(title: "Open Settings", variant: .outline, fullWidth: false) {
                        pushService.openSystemSettings()
                    }
                }

                if pushService.fcmToken != nil && !pushService.backendTokenSynced {
                    BoopButton(title: "Retry Sync", variant: .secondary, isLoading: pushService.registrationState == .registering, fullWidth: false) {
                        Task { await pushService.syncTokenToBackendIfPossible() }
                    }
                }
            }
            .padding(.top, BoopSpacing.xxs)

            if let error = pushService.lastErrorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
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
        if !pushService.isFirebaseConfigured {
            return BoopColors.warning
        }
        switch pushService.authorizationStatus {
        case .authorized, .provisional:
            return pushService.backendTokenSynced ? BoopColors.success : BoopColors.warning
        case .denied:
            return BoopColors.error
        case .notDetermined:
            return BoopColors.textMuted
        case .ephemeral:
            return BoopColors.accentColor
        @unknown default:
            return BoopColors.textMuted
        }
    }
}
