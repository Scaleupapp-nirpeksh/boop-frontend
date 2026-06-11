import SwiftUI

struct VoiceIntroView: View {
    @Bindable var onboardingVM: OnboardingViewModel
    @State private var viewModel = VoiceIntroViewModel()
    @State private var permissionDenied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    AccentRule()
                    EyebrowLabel(text: "Voice", color: BoopColors.textMuted)
                    Text("Let them hear your voice.")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if permissionDenied {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        EyebrowLabel(text: "Microphone Off", color: BoopColors.accentColor)
                        Text("Microphone access is required.")
                            .font(BoopTypography.cineHeadline)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text("Please enable it in Settings to record your voice intro.")
                            .font(BoopTypography.cineBodyLight)
                            .foregroundStyle(BoopColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, BoopSpacing.lg)
                } else {
                    BoopVoiceRecorder(state: viewModel.recorderState)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
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
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .task {
            let granted = await viewModel.requestMicPermission()
            if !granted { permissionDenied = true }
        }
    }
}
