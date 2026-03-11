import SwiftUI

extension View {
    func boopCard(radius: CGFloat = BoopRadius.lg, shadow: Bool = true) -> some View {
        self.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(BoopColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(
                    color: shadow ? Color.black.opacity(0.08) : .clear,
                    radius: 18,
                    x: 0,
                    y: 10
                )
        }
    }

    func boopBackground() -> some View {
        self.background(BoopAmbientBackground())
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func shakeEffect(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(animating: trigger))
    }
}

struct BoopAmbientBackground: View {
    var body: some View {
        ZStack {
            BoopColors.sunriseGradient.ignoresSafeArea()

            Circle()
                .fill(BoopColors.primary.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: -120, y: -260)

            Circle()
                .fill(BoopColors.secondary.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 26)
                .offset(x: 140, y: -160)

            Circle()
                .fill(BoopColors.accent.opacity(0.08))
                .frame(width: 220, height: 220)
                .blur(radius: 28)
                .offset(x: 110, y: 320)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(18))
                .blur(radius: 2)
                .offset(x: -150, y: 240)
        }
    }
}

struct ShakeModifier: ViewModifier {
    var animating: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: animating) { _, newValue in
                guard newValue else { return }
                withAnimation(.default.repeatCount(4, autoreverses: true).speed(6)) {
                    offset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    offset = 0
                }
            }
    }
}
