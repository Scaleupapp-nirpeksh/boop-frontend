import SwiftUI

/// Surfaced when a connection has gone quiet: revive with a Boop, or let it go.
struct GoneQuietCard: View {
    let name: String
    let onBoop: () -> Void
    let onLetGo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("This one's gone quiet")
                .font(.nunito(.bold, size: 16))
                .foregroundStyle(BoopColors.textPrimary)
            Text("\(name) hasn't been around lately. Send a Boop to revive it, or gracefully let it go and make room for someone new.")
                .font(.nunito(.regular, size: 13))
                .foregroundStyle(BoopColors.textSecondary)
            HStack(spacing: BoopSpacing.sm) {
                BoopButton(title: "👋 Boop", variant: .outline, fullWidth: true) { onBoop() }
                BoopButton(title: "Let it go", variant: .ghost, fullWidth: true) { onLetGo() }
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xxl)
    }
}
