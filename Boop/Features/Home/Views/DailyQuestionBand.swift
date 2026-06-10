import SwiftUI

/// The daily ritual entry — taps into the existing Questions flow.
struct DailyQuestionBand: View {
    let newCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.light(); onTap() }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S QUESTIONS")
                    .font(.nunito(.bold, size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                Text(newCount > 0
                     ? "\(newCount) new unlocked — answer to grow your profile"
                     : "Answer today's questions to deepen your matches")
                    .font(.nunito(.bold, size: 16))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text("Open").font(.nunito(.semiBold, size: 12))
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .background(BoopColors.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
            .shadow(color: BoopColors.brand.opacity(0.3), radius: 14, y: 8)
        }
        .padding(.horizontal, BoopSpacing.xl)
    }
}
