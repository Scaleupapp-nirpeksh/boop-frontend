import SwiftUI

struct PhotoUploadView: View {
    @Bindable var onboardingVM: OnboardingViewModel
    @State private var viewModel = PhotoUploadViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    AccentRule()
                    EyebrowLabel(text: "Photos", color: BoopColors.textMuted)
                    Text("Show your best self.")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

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
                        .font(BoopTypography.cineCaption)
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
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
    }
}
