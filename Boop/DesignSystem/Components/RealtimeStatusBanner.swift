import SwiftUI

struct RealtimeStatusBanner: View {
    @State private var realtime = RealtimeService.shared

    var body: some View {
        if realtime.shouldShowBanner {
            HStack(alignment: .top, spacing: BoopSpacing.sm) {
                Circle()
                    .fill(Color(hex: realtime.statusAccentHex))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(realtime.statusTitle)
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textPrimary)

                    Text(realtime.statusMessage)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                Spacer()

                Button("Retry") {
                    Task { await realtime.reconnectIfPossible() }
                }
                .font(BoopTypography.caption)
                .foregroundStyle(Color(hex: realtime.statusAccentHex))
            }
            .padding(BoopSpacing.md)
            .background(Color(hex: realtime.statusColorHex))
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
        }
    }
}
