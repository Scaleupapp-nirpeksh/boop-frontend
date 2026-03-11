import SwiftUI

struct BoopProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        VStack(spacing: BoopSpacing.xs) {
            // Step dots
            HStack(spacing: BoopSpacing.xs) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? BoopColors.primary : BoopColors.border)
                        .frame(width: 8, height: 8)
                        .scaleEffect(step == currentStep ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(BoopColors.border.opacity(0.5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(BoopColors.primaryGradient)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}
