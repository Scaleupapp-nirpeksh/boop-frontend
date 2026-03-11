import SwiftUI

struct PhotoUploadView: View {
    @Bindable var onboardingVM: OnboardingViewModel
    @State private var viewModel = PhotoUploadViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "Add photos",
                    eyebrow: "Photos"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopPhotoGrid(
                            slots: $viewModel.slots,
                            onAddPhoto: { image in
                                viewModel.addPhoto(image)
                            },
                            onDeletePhoto: { index in
                                viewModel.removePhoto(at: index)
                            }
                        )

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.error)
                        }

                        BoopButton(
                            title: "Upload & Continue",
                            isLoading: viewModel.isUploading,
                            isDisabled: !viewModel.canSubmit
                        ) {
                            Task {
                                if let user = await viewModel.uploadAllPhotos() {
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
    }
}
