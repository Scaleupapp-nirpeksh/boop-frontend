import SwiftUI

struct OTPVerificationView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var shakeError = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Verify")

                    Text("Enter code")
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)

                    AccentRule()

                    Text(viewModel.formattedPhone)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .monospacedDigit()
                }

                HStack {
                    EyebrowLabel(text: "6-digit SMS code")

                    Spacer()

                    Button("Change number") {
                        viewModel.reset()
                    }
                    .font(BoopTypography.cineCaption)
                    .tracking(1)
                    .foregroundStyle(BoopColors.accentColor)
                }

                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    BoopOTPField(code: $viewModel.otpCode) { _ in
                        Task { await viewModel.verifyOTP() }
                    }
                    .shakeEffect(trigger: shakeError)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.error)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                shakeError.toggle()
                            }
                    }

                    HStack {
                        if viewModel.resendCountdown > 0 {
                            Text("RESEND IN \(viewModel.resendCountdown)S")
                                .font(BoopTypography.cineCaption)
                                .tracking(1.5)
                                .foregroundStyle(BoopColors.textMuted)
                                .monospacedDigit()
                        } else {
                            Button {
                                Task { await viewModel.resendOTP() }
                            } label: {
                                Text("RESEND CODE")
                                    .font(BoopTypography.cineCaption)
                                    .tracking(1.5)
                                    .foregroundStyle(BoopColors.accentColor)
                            }
                        }

                        Spacer()

                        if viewModel.isLoading {
                            ProgressView()
                                .tint(BoopColors.accentColor)
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
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
    }
}
