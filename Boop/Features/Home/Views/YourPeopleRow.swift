import SwiftUI

/// Horizontal row of active connections as portraits that sharpen by comfort.
struct YourPeopleRow: View {
    let matches: [MatchInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("YOUR PEOPLE")
                .font(.nunito(.bold, size: 12))
                .foregroundStyle(BoopColors.textSecondary)
                .padding(.horizontal, BoopSpacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BoopSpacing.sm) {
                    ForEach(matches) { match in
                        NavigationLink {
                            MatchDetailView(matchId: match.matchId)
                        } label: {
                            personCell(match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
            }
        }
    }

    private func personCell(_ match: MatchInfo) -> some View {
        VStack(spacing: 6) {
            BlurredPortrait(
                urlString: match.heroPhotoURL,
                blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
                shape: .roundedRect(BoopRadius.lg),
                scrim: false
            ) {
                if match.otherUser.isOnline == true {
                    VStack {
                        HStack {
                            Spacer()
                            Circle().fill(BoopColors.success)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 84, height: 84)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                    .stroke((match.comfortScore ?? 0) >= 70 ? BoopColors.brand : Color.clear, lineWidth: 2)
            )

            Text(match.otherUser.firstName)
                .font(.nunito(.semiBold, size: 12))
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
            Text("\(match.comfortScore ?? 0)/70")
                .font(.nunito(.medium, size: 10))
                .foregroundStyle(BoopColors.textMuted)
        }
        .frame(width: 84)
    }
}
