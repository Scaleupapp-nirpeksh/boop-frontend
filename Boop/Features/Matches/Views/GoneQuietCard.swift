import SwiftUI

/// Surfaced when a connection has gone quiet: revive with a Boop, or let it go.
struct GoneQuietCard: View {
    let name: String
    let onBoop: () -> Void
    let onLetGo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Gone Quiet")
            AccentRule()
            Text("This one's drifted")
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)
            Text("\(name) hasn't been around lately. Send a Boop to revive it, or gracefully let it go and make room for someone new.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
            HStack(spacing: BoopSpacing.sm) {
                BoopButton(title: "Boop", variant: .outline, fullWidth: true) { onBoop() }
                BoopButton(title: "Let it go", variant: .ghost, fullWidth: true) { onLetGo() }
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }
}
