import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var viewModel = NotificationSettingsViewModel()
    @State private var pushService = PushNotificationService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                statusCard
                preferencesCard
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
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

    private var statusCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Device status")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                HStack(alignment: .top, spacing: BoopSpacing.sm) {
                    Circle()
                        .fill(statusTint)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pushService.statusTitle)
                            .font(BoopTypography.callout)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text(pushService.statusMessage)
                            .font(BoopTypography.body)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                }

                if let token = pushService.fcmToken {
                    Text("FCM token: \(token.prefix(16))...")
                        .font(BoopTypography.caption)
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

                if let error = pushService.lastErrorMessage {
                    Text(error)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.error)
                }
            }
        }
    }

    private var preferencesCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Preferences")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Toggle("Mute all notifications", isOn: $viewModel.allMuted)
                    .tint(BoopColors.primary)

                Toggle("Use quiet hours", isOn: $viewModel.quietHoursEnabled)
                    .tint(BoopColors.primary)

                if viewModel.quietHoursEnabled {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        quietHoursField(title: "Starts", text: $viewModel.quietHoursStart)
                        quietHoursField(title: "Ends", text: $viewModel.quietHoursEnd)
                        quietHoursField(title: "Timezone", text: $viewModel.timezone)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.error)
                }

                if let success = viewModel.successMessage {
                    Text(success)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.success)
                }

                BoopButton(title: "Save Preferences", isLoading: viewModel.isSaving) {
                    Task { await viewModel.save() }
                }
            }
        }
    }

    private func quietHoursField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
            TextField(title, text: text)
                .font(BoopTypography.body)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.sm)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
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
            return BoopColors.secondary
        @unknown default:
            return BoopColors.textMuted
        }
    }
}
