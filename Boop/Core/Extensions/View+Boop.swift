import SwiftUI

extension View {
    func boopCard(radius: CGFloat = BoopRadius.lg, shadow: Bool = true) -> some View {
        self.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(BoopColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(BoopColors.border, lineWidth: 1)
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
            BoopColors.background.ignoresSafeArea()

            Circle()
                .fill(BoopColors.brand.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -120, y: -260)

            Circle()
                .fill(BoopColors.brandViolet.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 36)
                .offset(x: 140, y: -160)

            Circle()
                .fill(BoopColors.accent.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 38)
                .offset(x: 110, y: 320)
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
