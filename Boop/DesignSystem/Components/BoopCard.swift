import SwiftUI

struct BoopCard<Content: View>: View {
    var padding: CGFloat = BoopSpacing.md
    var radius: CGFloat = BoopRadius.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(BoopColors.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
            }
    }
}

struct BoopSectionIntro: View {
    let title: String
    var subtitle: String? = nil
    var eyebrow: String? = nil
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: BoopSpacing.xs) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .kerning(1.1)
                    .foregroundStyle(BoopColors.textMuted)
            }

            Text(title)
                .font(BoopTypography.title1)
                .foregroundStyle(BoopColors.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private var frameAlignment: Alignment {
        alignment == .center ? .center : .leading
    }
}

struct BoopStatPill: View {
    let icon: String
    let value: String
    let label: String
    var tint: Color = BoopColors.primary

    var body: some View {
        HStack(spacing: BoopSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(BoopColors.textPrimary)

                Text(label)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
        .padding(.horizontal, BoopSpacing.sm)
        .padding(.vertical, BoopSpacing.xs)
        .background(BoopColors.surfaceElevated)
        .overlay(
            Capsule()
                .stroke(BoopColors.border.opacity(0.6), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct BoopCalloutCard: View {
    let icon: String
    let title: String
    let message: String
    var tint: Color = BoopColors.secondary

    var body: some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(BoopColors.textPrimary)

                Text(message)
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(BoopSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                .fill(tint.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                .stroke(tint.opacity(0.12), lineWidth: 1)
        )
    }
}
