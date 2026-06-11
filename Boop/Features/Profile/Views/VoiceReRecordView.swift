import SwiftUI

struct VoiceReRecordView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var recorder = VoiceRecorderState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                header

                BoopVoiceRecorder(state: recorder)

                if let error = recorder.error {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
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

                BoopButton(
                    title: "Save voice intro",
                    isLoading: viewModel.isUploadingVoice,
                    isDisabled: !recorder.hasRecording || !recorder.minDurationMet || recorder.isRecording
                ) {
                    guard let data = recorder.getRecordingData() else { return }
                    Task {
                        await viewModel.uploadVoiceIntro(data: data, duration: Int(recorder.duration))
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Record Voice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Voice intro", color: BoopColors.accentColor)
            AccentRule()
            Text("Record the real you")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text("A short intro so people can hear the real you.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            VoiceLine(duration: recorder.formattedDuration)
                .padding(.top, BoopSpacing.xs)
        }
    }
}
