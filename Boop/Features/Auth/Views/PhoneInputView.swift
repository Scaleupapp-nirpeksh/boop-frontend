import SwiftUI

struct PhoneInputView: View {
    @State private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                    BoopSectionIntro(
                        title: "Your number",
                        subtitle: "We’ll send a 6-digit code.",
                        eyebrow: "Sign In"
                    )

                    BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                            BoopPhoneInput(
                                phoneNumber: $viewModel.phoneNumber,
                                errorMessage: viewModel.errorMessage
                            )

                            Text("India numbers only in this build.")
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.textSecondary)

                            BoopButton(
                                title: "Continue",
                                isLoading: viewModel.isLoading,
                                isDisabled: !viewModel.isPhoneValid
                            ) {
                                Task { await viewModel.sendOTP() }
                            }
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
                BoopLogo(size: 32, showText: false)
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
