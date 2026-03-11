import SwiftUI

struct BioView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "Short bio",
                    eyebrow: "Optional"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopTextField(
                            label: "Bio",
                            text: $viewModel.bioText,
                            placeholder: "Coffee lover, book worm, and occasional dancer...",
                            isMultiline: true,
                            maxLength: 500
                        )

                        VStack(spacing: BoopSpacing.sm) {
                            BoopButton(
                                title: "Continue",
                                isLoading: viewModel.isLoading
                            ) {
                                Task { await viewModel.submitLocationAndBio() }
                            }

                            BoopButton(
                                title: "Skip for now",
                                variant: .ghost
                            ) {
                                Task { await viewModel.submitLocationAndBio() }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .onTapGesture { hideKeyboard() }
    }
}
