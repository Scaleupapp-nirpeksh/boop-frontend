import SwiftUI

struct ConnectionCard: View {
    let match: MatchInfo

    var body: some View {
        HStack(spacing: BoopSpacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: stageGradientColors.map { $0.opacity(0.18) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(match.otherUser.firstName.prefix(1)))
                            .font(.nunito(.bold, size: 22))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: stageGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: stageGradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                if match.otherUser.isOnline == true {
                    Circle()
                        .fill(BoopColors.success)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(BoopColors.surface, lineWidth: 2.5))
                        .offset(x: 2, y: 2)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(displayName)
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    // Stage badge
                    Text(match.stageLabel)
                        .font(BoopTypography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(stageGradientColors.first ?? BoopColors.secondary)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, 3)
                        .background(
                            (stageGradientColors.first ?? BoopColors.secondary).opacity(0.1)
                        )
                        .clipShape(Capsule())
                }

                if let city = match.otherUser.city {
                    Text(city)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                HStack(spacing: BoopSpacing.md) {
                    // Compatibility
                    if let score = match.compatibilityScore {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("\(score)%")
                                .font(BoopTypography.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(BoopColors.primary)
                    }

                    // Comfort bar
                    if let comfort = match.comfortScore {
                        HStack(spacing: 6) {
                            comfortBar(value: comfort)
                            Text("\(comfort)/100")
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }

                    Spacer()

                    // Day count
                    Text("Day \(match.daysSinceMatch)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BoopColors.textMuted)
        }
        .padding(BoopSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .fill(BoopColors.surface)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .stroke(stageGradientColors.first?.opacity(0.1) ?? .clear, lineWidth: 1)
        )
    }

    private func comfortBar(value: Int) -> some View {
        GeometryReader { _ in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(BoopColors.border.opacity(0.4))
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: comfortGradient(for: value),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, CGFloat(value) / 100.0 * 60))
            }
        }
        .frame(width: 60, height: 6)
    }

    private func comfortGradient(for value: Int) -> [Color] {
        if value >= 70 { return [BoopColors.success, BoopColors.secondary] }
        if value >= 40 { return [BoopColors.secondary, BoopColors.accent] }
        return [BoopColors.accent, BoopColors.primary]
    }

    private var displayName: String {
        if let age = match.otherUser.age {
            return "\(match.otherUser.firstName), \(age)"
        }
        return match.otherUser.firstName
    }

    private var stageGradientColors: [Color] {
        switch match.stage {
        case "revealed", "dating": return [BoopColors.success, BoopColors.secondary]
        case "reveal_ready": return [BoopColors.accent, BoopColors.primary]
        default: return [BoopColors.primary, BoopColors.secondary]
        }
    }
}
