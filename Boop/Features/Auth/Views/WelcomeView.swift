import SwiftUI

struct WelcomeView: View {
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
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
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                // Hero — two voices weaving into a single bloom.
                // Carries the feeling the splash promised, without re-listing the pitch.
                VoiceWeaveHero()
                    .frame(maxWidth: .infinity)
                    .padding(.top, BoopSpacing.lg)

                Text("Two voices, one bloom.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(appeared ? 1 : 0)

                Spacer(minLength: BoopSpacing.lg)

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
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous))
                            .shadow(color: BoopColors.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, BoopSpacing.xs)

                    NavigationLink {
                        PairCodeGateView()
                    } label: {
                        Text("Have a code from someone? Start with Us")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, BoopSpacing.sm)
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
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                appeared = true
            }
        }
    }
}

// MARK: - Voice Weave Hero

/// Two voices — one coral, one periwinkle — weave through each other and bloom a
/// new colour where they cross. Mirrors the splash's "merge" idea in the app's
/// hairline language, and visualises "voice-first" (which nothing else in the
/// flow shows). Draws on appear, then the bloom settles in.
private struct VoiceWeaveHero: View {
    @State private var draw = false
    @State private var bloom = false

    private let coral = [Color(hex: "FFB07A"), Color(hex: "FF5C72"), Color(hex: "D7335F")]
    private let peri  = [Color(hex: "9DB6FF"), Color(hex: "6E84E6"), Color(hex: "4E5FC9")]

    var body: some View {
        ZStack {
            // The new colour, born where the two voices cross.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.90),
                            Color(hex: "E9C9F4").opacity(0.40),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 56
                    )
                )
                .frame(width: 112, height: 112)
                .blur(radius: 12)
                .scaleEffect(bloom ? 1 : 0.55)
                .opacity(bloom ? 1 : 0)

            VoiceWave(flipped: false)
                .trim(from: 0, to: draw ? 1 : 0)
                .stroke(
                    LinearGradient(colors: coral, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                )

            VoiceWave(flipped: true)
                .trim(from: 0, to: draw ? 1 : 0)
                .stroke(
                    LinearGradient(colors: peri, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                )
        }
        .frame(height: 156)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).delay(0.4)) { draw = true }
            withAnimation(.easeOut(duration: 0.7).delay(1.3)) { bloom = true }
        }
    }
}

/// A single voice: a soft wave that rises on the left lobe and falls on the right
/// (or the mirror, when `flipped`). Two of these cross at the centre and the ends.
private struct VoiceWave: Shape {
    var flipped: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let midY = h / 2
        let up: CGFloat = flipped ? 0.74 : 0.26
        let down: CGFloat = flipped ? 0.26 : 0.74

        var p = Path()
        p.move(to: CGPoint(x: 0.06 * w, y: midY))
        p.addCurve(
            to: CGPoint(x: 0.46 * w, y: midY),
            control1: CGPoint(x: 0.19 * w, y: up * h),
            control2: CGPoint(x: 0.32 * w, y: up * h)
        )
        p.addCurve(
            to: CGPoint(x: 0.94 * w, y: midY),
            control1: CGPoint(x: 0.60 * w, y: down * h),
            control2: CGPoint(x: 0.74 * w, y: down * h)
        )
        return p
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}


// MARK: - Pair code gate ("Us" invites)

/// Entry for people who arrived with a friend's pair code. There is no account
/// yet, so the code is kept locally and redeemed right after basic info.
private struct PairCodeGateView: View {
    @State private var code = ""
    @State private var proceed = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                Spacer(minLength: 40)

                EyebrowLabel(text: "Us", color: BoopColors.accentColor)
                AccentRule()

                Text("Someone saved you a spot")
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Enter the six characters they sent you. Once you're set up, you two are linked — no searching, no waiting.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("ROSE42", text: $code)
                    .font(.system(size: 34, weight: .semibold))
                    .tracking(10)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .padding(.vertical, BoopSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                            .fill(BoopColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                            .stroke(code.count == 6 ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1.5)
                    )
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                    }

                BoopButton(title: "Continue", isDisabled: code.count != 6) {
                    UserDefaults.standard.set(code, forKey: "pendingPairCode")
                    proceed = true
                }

                Button {
                    UserDefaults.standard.removeObject(forKey: "pendingPairCode")
                    proceed = true
                } label: {
                    Text("I'll enter it later")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, BoopSpacing.xs)

                Spacer(minLength: BoopSpacing.xxl)
            }
            .padding(.horizontal, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationDestination(isPresented: $proceed) {
            PhoneInputView()
        }
    }
}
