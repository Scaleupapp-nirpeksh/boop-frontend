import SwiftUI

struct BasicInfoView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    AccentRule()
                    EyebrowLabel(text: "About You", color: BoopColors.textMuted)
                    Text("Tell us who you are.")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: BoopSpacing.xl) {
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

                    BoopTextField(
                        label: "City (optional)",
                        text: $viewModel.city,
                        placeholder: "Where are you based?",
                        textContentType: .addressCity
                    )
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
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
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .onTapGesture { hideKeyboard() }
    }
}
