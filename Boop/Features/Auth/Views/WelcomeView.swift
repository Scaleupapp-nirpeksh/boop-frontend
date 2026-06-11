import SwiftUI

struct WelcomeView: View {
    @State private var appeared = false

    private let callouts: [(label: String, detail: String)] = [
        ("Voice-first", "Real intros, not selfies"),
        ("Thoughtful", "Guided prompts, slow burn"),
        ("Private", "Blurred until you're ready"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                Spacer(minLength: 40)

                // Wordmark + headline
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    Text("UnMutee")
                        .font(BoopTypography.cineTitle)
                        .tracking(4)
                        .foregroundStyle(BoopColors.textPrimary)

                    VStack(alignment: .leading, spacing: BoopSpacing.md) {
                        EyebrowLabel(text: "Welcome")

                        Text("Connection before appearance")
                            .font(BoopTypography.cineDisplay)
                            .foregroundStyle(BoopColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        AccentRule()

                        Text("Voice and chemistry first.")
                            .font(BoopTypography.cineBodyLight)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                // Feature callouts as tracked hairline rows
                VStack(spacing: 0) {
                    ForEach(callouts, id: \.label) { item in
                        HairlineRow(item.label) {
                            Text(item.detail.uppercased())
                                .font(BoopTypography.cineLabel)
                                .tracking(1.5)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)

                // Start block
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Start simple")

                    Text("Number, profile, voice, photos.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)

                    NavigationLink {
                        PhoneInputView()
                    } label: {
                        Text("GET STARTED")
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(0.5)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundStyle(.white)
                            .background(BoopColors.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
                            .shadow(color: BoopColors.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, BoopSpacing.xs)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)

                Spacer(minLength: BoopSpacing.xxl)
            }
            .padding(.horizontal, BoopSpacing.xl)
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
