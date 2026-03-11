import SwiftUI

struct VoiceIntroView: View {
    @Bindable var onboardingVM: OnboardingViewModel
    @State private var viewModel = VoiceIntroViewModel()
    @State private var permissionDenied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "Voice intro",
                    eyebrow: "Voice"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(spacing: BoopSpacing.lg) {
                        if permissionDenied {
                            VStack(spacing: BoopSpacing.md) {
                                Image(systemName: "mic.slash")
                                    .font(.system(size: 48))
                                    .foregroundStyle(BoopColors.textMuted)
                                Text("Microphone access is required")
                                    .font(BoopTypography.headline)
                                Text("Please enable it in Settings")
                                    .font(BoopTypography.body)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BoopSpacing.xl)
                        } else {
                            BoopVoiceRecorder(state: viewModel.recorderState)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.error)
                        }

                        BoopButton(
                            title: "Use this recording",
                            isLoading: viewModel.isUploading,
                            isDisabled: !viewModel.canSubmit
                        ) {
                            Task {
                                if let user = await viewModel.uploadVoiceIntro() {
                                    await MainActor.run {
                                        AuthManager.shared.updateUser(user)
                                        onboardingVM.advanceStep()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .task {
            let granted = await viewModel.requestMicPermission()
            if !granted { permissionDenied = true }
        }
    }
}
