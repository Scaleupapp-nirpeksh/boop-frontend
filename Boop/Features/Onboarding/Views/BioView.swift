import SwiftUI

struct BioView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    AccentRule()
                    EyebrowLabel(text: "Optional", color: BoopColors.textMuted)
                    Text("Say something about yourself.")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BoopTextField(
                    label: "Bio",
                    text: $viewModel.bioText,
                    placeholder: "Coffee lover, book worm, and occasional dancer...",
                    isMultiline: true,
                    maxLength: 500
                )

                VStack(spacing: BoopSpacing.md) {
                    BoopButton(
                        title: "Continue",
                        isLoading: viewModel.isLoading
                    ) {
                        Task { await viewModel.submitLocationAndBio() }
                    }

                    Button {
                        Task { await viewModel.submitLocationAndBio() }
                    } label: {
                        Text("Skip for now")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BoopSpacing.xs)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .onTapGesture { hideKeyboard() }
    }
}
