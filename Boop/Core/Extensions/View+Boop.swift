import SwiftUI

extension View {
    func boopCard(radius: CGFloat = BoopRadius.lg, shadow: Bool = true) -> some View {
        self.background {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(BoopColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(BoopColors.hairline, lineWidth: 1)
                )
                .shadow(
                    color: shadow ? Color.black.opacity(0.2) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
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
        ZStack(alignment: .topTrailing) {
            BoopColors.ground.ignoresSafeArea()

            Circle()
                .fill(BoopColors.accentColor.opacity(0.05))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 80, y: -120)
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
