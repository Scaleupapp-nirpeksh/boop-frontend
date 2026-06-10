import SwiftUI

/// Horizontal row of active connections as portraits that sharpen by comfort.
struct YourPeopleRow: View {
    let matches: [MatchInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Your people")
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
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(BoopColors.ground, lineWidth: 1.5))
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 84, height: 84)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                    .stroke((match.comfortScore ?? 0) >= 70 ? BoopColors.accentColor : Color.clear, lineWidth: 1)
            )

            Text(match.otherUser.firstName)
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
            Text("\(match.comfortScore ?? 0)/70")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textMuted)
        }
        .frame(width: 84)
    }
}
