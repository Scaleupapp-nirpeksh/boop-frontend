import SwiftUI

/// "Come into focus" — the Me-tab home for answering questions.
/// Two soft orbs (the merge mark) start blurred and sharpen as the user answers
/// more questions: the app is literally seeing them more clearly. No numbers,
/// no percentages — just warmth. Tapping opens the questions sheet.
struct KnowYouCard: View {
    let answered: Int
    let freshToday: Int?
    let onTap: () -> Void

    private static let fullPicture = 60.0

    private var progress: Double {
        min(1.0, Double(answered) / Self.fullPicture)
    }

    /// The clarity of the artwork tracks how well we know them.
    private var orbBlur: CGFloat {
        CGFloat((1.0 - progress) * 9.0)
    }

    private var stageText: String {
        switch progress {
        case ..<0.25: return "Just getting to know you"
        case ..<0.5: return "Coming into focus"
        case ..<0.75: return "Seeing you more clearly"
        case ..<1.0: return "Almost crystal clear"
        default: return "Crystal clear"
        }
    }

    private var ctaText: String {
        if let freshToday, freshToday > 0 {
            return freshToday == 1 ? "1 fresh question today" : "\(freshToday) fresh questions today"
        }
        if progress >= 1.0 {
            return "We see you beautifully"
        }
        return "Answer a few more"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: BoopSpacing.md) {
                focusOrbs

                VStack(alignment: .leading, spacing: 3) {
                    EyebrowLabel(text: stageText)

                    Text("Help us see the real you")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: BoopSpacing.xs) {
                        Text(ctaText)
                            .font(BoopTypography.cineLabel)
                            .tracking(1.5)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .thin))
                    }
                    .foregroundStyle(BoopColors.accentColor)
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(BoopSpacing.md)
            .boopCard(radius: BoopRadius.xl, shadow: false)
        }
        .buttonStyle(.plain)
    }

    /// The merge orbs, sharpening with every answer.
    private var focusOrbs: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "FFB07A"), Color(hex: "FF5C72"), Color(hex: "D7335F")],
                        center: UnitPoint(x: 0.42, y: 0.38),
                        startRadius: 1,
                        endRadius: 18
                    )
                )
                .frame(width: 30, height: 30)
                .offset(x: -8)
                .opacity(0.95)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "9DB6FF"), Color(hex: "6E84E6"), Color(hex: "4E5FC9")],
                        center: UnitPoint(x: 0.58, y: 0.38),
                        startRadius: 1,
                        endRadius: 18
                    )
                )
                .frame(width: 30, height: 30)
                .offset(x: 8)
                .opacity(0.95)

            Circle()
                .fill(Color(hex: "F0D2F2"))
                .frame(width: 13, height: 13)
                .opacity(0.55)
                .blur(radius: 3)
        }
        .frame(width: 50, height: 38)
        .blur(radius: orbBlur * 0.7)
        .animation(.easeInOut(duration: 0.6), value: orbBlur)
    }
}

/// Design-review harness: the card at three stages of "focus".
struct KnowYouGalleryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            EyebrowLabel(text: "Me tab · Come into focus")
            KnowYouCard(answered: 6, freshToday: 3) {}
            KnowYouCard(answered: 28, freshToday: 1) {}
            KnowYouCard(answered: 60, freshToday: 0) {}
        }
        .padding(BoopSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .boopBackground()
    }
}

#Preview("Early") {
    VStack(spacing: 16) {
        KnowYouCard(answered: 6, freshToday: 3) {}
        KnowYouCard(answered: 28, freshToday: 1) {}
        KnowYouCard(answered: 60, freshToday: 0) {}
    }
    .padding()
    .boopBackground()
}
