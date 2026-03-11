import SwiftUI

struct BasicInfoView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "About you",
                    eyebrow: "About You"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopTextField(
                            label: "First Name",
                            text: $viewModel.firstName,
                            placeholder: "What should we call you?",
                            textContentType: .givenName
                        )

                        BoopDatePicker(
                            label: "Date of Birth",
                            date: $viewModel.dateOfBirth
                        )

                        BoopSegmentedPicker(
                            label: "I identify as",
                            options: Gender.allCases.map { ($0, $0.displayName) },
                            selected: $viewModel.gender
                        )

                        BoopSegmentedPicker(
                            label: "I'm interested in",
                            options: InterestedIn.allCases.map { ($0, $0.displayName) },
                            selected: $viewModel.interestedIn
                        )

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.error)
                        }

                        BoopButton(
                            title: "Continue",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.canProceedBasicInfo
                        ) {
                            Task { await viewModel.submitBasicInfo() }
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
