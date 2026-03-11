import SwiftUI

struct BoopLoadingView: View {
    var message: String? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: BoopSpacing.md) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(BoopColors.primary)

                if let message {
                    Text(message)
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textPrimary)
                }
            }
            .padding(BoopSpacing.xxl)
            .boopCard()
        }
    }
}
