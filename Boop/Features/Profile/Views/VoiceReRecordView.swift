import SwiftUI

struct VoiceReRecordView: View {
    @Bindable var viewModel: ProfileViewModel
    @State private var recorder = VoiceRecorderState()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.xl) {
                BoopSectionIntro(
                    title: "Voice intro",
                    subtitle: "Record a short intro so people can hear the real you.",
                    eyebrow: "Profile"
                )

                BoopCard(padding: BoopSpacing.xl, radius: BoopRadius.xxl) {
                    BoopVoiceRecorder(state: recorder)
                }

                if let error = recorder.error {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                if let success = viewModel.successMessage {
                    Text(success)
                        .font(BoopTypography.footnote)
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
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Record Voice")
        .navigationBarTitleDisplayMode(.inline)
    }
}
