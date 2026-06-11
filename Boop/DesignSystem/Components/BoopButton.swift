import SwiftUI

enum BoopButtonVariant {
    case primary, secondary, outline, ghost
}

struct BoopButton: View {
    let title: String
    var variant: BoopButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var fullWidth: Bool = true
    let action: () -> Void

    private var isEnabled: Bool { !isLoading && !isDisabled }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: BoopSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.9)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(0.5)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: 52)
            .padding(.horizontal, BoopSpacing.xl)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous))
            .overlay(overlayView)
            .shadow(
                color: variant == .primary ? BoopColors.accentColor.opacity(0.25) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            BoopColors.accentColor
        case .secondary, .outline, .ghost:
            Color.clear
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        case .outline:
            RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                .stroke(BoopColors.accentColor, lineWidth: 1)
        case .primary, .ghost:
            EmptyView()
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return BoopColors.textPrimary
        case .outline:
            return BoopColors.accentColor
        case .ghost:
            return BoopColors.textSecondary
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BoopButton(title: "Get Started", variant: .primary) {}
        BoopButton(title: "Continue", variant: .secondary) {}
        BoopButton(title: "Sign In", variant: .outline) {}
        BoopButton(title: "Skip", variant: .ghost) {}
        BoopButton(title: "Loading...", isLoading: true) {}
        BoopButton(title: "Disabled", isDisabled: true) {}
    }
    .padding()
    .boopBackground()
}
