import SwiftUI

/// A single connection rendered as a cinematic hairline row: a fogged portrait,
/// the name, stage as an eyebrow, and thin-symbol metadata.
struct ConnectionCard: View {
    let match: MatchInfo

    var body: some View {
        HStack(spacing: BoopSpacing.md) {
            // Fogged portrait avatar (sharpens by comfort, like the rest of Home)
            ZStack(alignment: .bottomTrailing) {
                BlurredPortrait(
                    urlString: match.heroPhotoURL,
                    blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
                    shape: .circle,
                    scrim: false
                )
                .frame(width: 56, height: 56)
                .overlay(Circle().stroke(BoopColors.hairline, lineWidth: 1))

                if match.otherUser.isOnline == true {
                    Circle()
                        .fill(BoopColors.success)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(BoopColors.ground, lineWidth: 1.5))
                        .offset(x: 1, y: 1)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(displayName)
                        .font(BoopTypography.cineHeadline)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    EyebrowLabel(text: match.stageLabel, color: BoopColors.accentColor)
                }

                if let city = match.otherUser.city {
                    Text(city)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                HStack(spacing: BoopSpacing.md) {
                    // Compatibility
                    if let score = match.compatibilityScore {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkle")
                                .font(.system(size: 10, weight: .thin))
                            Text("\(score)%")
                                .font(BoopTypography.cineCaption)
                                .tracking(0.5)
                        }
                        .foregroundStyle(BoopColors.accentColor)
                    }

                    // Comfort bar
                    if let comfort = match.comfortScore {
                        HStack(spacing: 6) {
                            HairlineProgress(progress: Double(comfort) / 100.0)
                                .frame(width: 60)
                            Text("\(comfort)/100")
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }

                    // Streak flame
                    if let streak = match.streak?.current, streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame")
                                .font(.system(size: 10, weight: .thin))
                            Text("\(streak)")
                                .font(BoopTypography.cineCaption)
                                .tracking(0.5)
                        }
                        .foregroundStyle(BoopColors.accentColor)
                    }

                    Spacer()

                    // Day count
                    Text("Day \(match.daysSinceMatch)")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .thin))
                .foregroundStyle(BoopColors.textMuted)
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var displayName: String {
        if let age = match.otherUser.age {
            return "\(match.otherUser.firstName), \(age)"
        }
        return match.otherUser.firstName
    }
}
