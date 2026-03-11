import SwiftUI

struct OTPVerificationView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var shakeError = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                BoopSectionIntro(
                    title: "Enter code",
                    subtitle: viewModel.formattedPhone,
                    eyebrow: "Verify"
                )

                HStack {
                    BoopStatPill(
                        icon: "message.badge.fill",
                        value: "6 digits",
                        label: "SMS verification",
                        tint: BoopColors.primary
                    )

                    Spacer()

                    Button("Change number") {
                        viewModel.reset()
                    }
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.primary)
                }

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopOTPField(code: $viewModel.otpCode) { _ in
                            Task { await viewModel.verifyOTP() }
                        }
                        .shakeEffect(trigger: shakeError)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .onAppear {
                                    shakeError.toggle()
                                }
                        }

                        HStack {
                            if viewModel.resendCountdown > 0 {
                                Text("Resend code in \(viewModel.resendCountdown)s")
                                    .font(BoopTypography.callout)
                                    .foregroundStyle(BoopColors.textMuted)
                                    .monospacedDigit()
                            } else {
                                Button {
                                    Task { await viewModel.resendOTP() }
                                } label: {
                                    Text("Resend code")
                                        .font(BoopTypography.callout)
                                        .foregroundStyle(BoopColors.primary)
                                }
                            }

                            Spacer()

                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(BoopColors.primary)
                            }
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
