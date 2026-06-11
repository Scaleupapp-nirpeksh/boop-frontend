import SwiftUI

/// The daily ritual entry — taps into the existing Questions flow.
struct DailyQuestionBand: View {
    let newCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.light(); onTap() }) {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                EyebrowLabel(text: "Sharpen your matches")
                Text(newCount > 0
                     ? "\(newCount) new question\(newCount == 1 ? "" : "s") to sharpen your matches"
                     : "A new question to sharpen your matches")
                    .font(BoopTypography.cineHeadline)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                AccentRule()
                HStack(spacing: 6) {
                    Text("OPEN")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .thin))
                }
                .foregroundStyle(BoopColors.accentColor)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .boopCard(radius: BoopRadius.xxl)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, BoopSpacing.xl)
    }
}
