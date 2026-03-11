import SwiftUI

struct WelcomeView: View {
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: BoopSpacing.xxl) {
                Spacer(minLength: 40)

                VStack(spacing: BoopSpacing.lg) {
                    BoopLogo(size: 140, animated: true)

                    BoopSectionIntro(
                        title: "Connection before appearance",
                        subtitle: "Voice and chemistry first.",
                        eyebrow: "Welcome",
                        alignment: .center
                    )
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                VStack(spacing: BoopSpacing.sm) {
                    HStack(spacing: BoopSpacing.sm) {
                        BoopStatPill(
                            icon: "waveform",
                            value: "Voice-first",
                            label: "Real intros",
                            tint: BoopColors.secondary
                        )

                        BoopStatPill(
                            icon: "sparkles",
                            value: "Thoughtful",
                            label: "Guided prompts",
                            tint: BoopColors.accent
                        )
                    }

                    BoopStatPill(
                        icon: "eye.slash",
                        value: "Private",
                        label: "Blurred by default",
                        tint: BoopColors.primary
                    )
                }
                .padding(.horizontal, BoopSpacing.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.md) {
                        Text("Start simple")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)

                        Text("Number, profile, voice, photos.")
                            .font(BoopTypography.body)
                            .foregroundStyle(BoopColors.textSecondary)

                        NavigationLink {
                            PhoneInputView()
                        } label: {
                            Text("Get Started")
                                .font(BoopTypography.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .foregroundStyle(.white)
                                .background(BoopColors.primaryGradient)
                                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                                .shadow(color: BoopColors.primary.opacity(0.24), radius: 14, x: 0, y: 8)
                        }

                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Spacer(minLength: BoopSpacing.xxl)
            }
        }
        .boopBackground()
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                appeared = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
