import SwiftUI

/// The single most charged item on Home: the connection closest to reveal,
/// rendered as a near-clear portrait fading into the ground with a headline.
struct MomentHeroCard: View {
    let match: MatchInfo

    private var comfort: Int { match.comfortScore ?? 0 }
    private var pointsToReveal: Int { max(0, 70 - comfort) }

    private var headline: String {
        if match.stage == "revealed" || match.stage == "dating" {
            return "You've revealed — keep it going"
        }
        if pointsToReveal == 0 { return "You're ready to reveal" }
        return "\(pointsToReveal) points from seeing each other"
    }

    var body: some View {
        CinematicHeader(
            urlString: match.heroPhotoURL,
            blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
            height: 220
        ) {
            EyebrowLabel(text: headline, color: BoopColors.textSecondary)
            AccentRule()
            Text(match.displayName)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            HStack(spacing: BoopSpacing.sm) {
                if let streak = match.streak?.current, streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame")
                            .font(.system(size: 12, weight: .thin))
                        Text("\(streak)")
                            .font(BoopTypography.cineCaption)
                            .tracking(1)
                    }
                    .foregroundStyle(BoopColors.textSecondary)
                }
                if match.otherUser.isOnline == true {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6, weight: .thin))
                        Text("ONLINE")
                            .font(BoopTypography.cineCaption)
                            .tracking(1.5)
                    }
                    .foregroundStyle(BoopColors.success)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
    }
}
