import SwiftUI

struct PhoneInputView: View {
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.md) {
                        EyebrowLabel(text: "Sign In")

                        Text("Your number")
                            .font(BoopTypography.cineDisplay)
                            .foregroundStyle(BoopColors.textPrimary)

                        AccentRule()

                        Text("We'll send a 6-digit code.")
                            .font(BoopTypography.cineBodyLight)
                            .foregroundStyle(BoopColors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopPhoneInput(
                            phoneNumber: $viewModel.phoneNumber,
                            errorMessage: viewModel.errorMessage
                        )

                        Text("India numbers only in this build.")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)

                        BoopButton(
                            title: "Continue",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isPhoneValid
                        ) {
                            Task { await viewModel.sendOTP() }
                        }
                    }

                    Spacer(minLength: BoopSpacing.xxl)
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.top, BoopSpacing.lg)
                .padding(.bottom, BoopSpacing.xxl)
            }
            .boopBackground()

            // Navigation to OTP
            NavigationLink(
                destination: OTPVerificationView(viewModel: viewModel),
                isActive: $viewModel.showOTP
            ) { EmptyView() }
                .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("UnMutee")
                    .font(BoopTypography.cineCaption)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        }
        .boopBackground()
        .onTapGesture { hideKeyboard() }
    }
}

#Preview {
    NavigationStack {
        PhoneInputView()
    }
}
