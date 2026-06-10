import SwiftUI

/// The single most charged item on Home: the connection closest to reveal,
/// rendered as a near-clear portrait with a headline and one tap target.
struct MomentHeroCard: View {
    let match: MatchInfo

    private var comfort: Int { match.comfortScore ?? 0 }
    private var pointsToReveal: Int { max(0, 70 - comfort) }

    private var headline: String {
        if match.stage == "revealed" || match.stage == "dating" {
            return "You've revealed — keep it going"
        }
        if pointsToReveal == 0 { return "You're ready to reveal 👀" }
        return "\(pointsToReveal) points from seeing each other"
    }

    var body: some View {
        BlurredPortrait(
            urlString: match.heroPhotoURL,
            blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
            shape: .roundedRect(BoopRadius.xxl)
        ) {
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Spacer()
                Text(headline.uppercased())
                    .font(.nunito(.bold, size: 11))
                    .foregroundStyle(Color(hex: "FFD6DD"))
                Text(match.displayName)
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(.white)
                HStack(spacing: BoopSpacing.xs) {
                    if let streak = match.streak?.current, streak > 0 {
                        Text("🔥 \(streak)")
                            .font(.nunito(.bold, size: 12))
                            .foregroundStyle(.white)
                    }
                    if match.otherUser.isOnline == true {
                        Text("● online")
                            .font(.nunito(.semiBold, size: 11))
                            .foregroundStyle(BoopColors.success)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
        }
        .frame(height: 200)
        .shadow(color: BoopColors.brand.opacity(0.25), radius: 18, y: 10)
    }
}
