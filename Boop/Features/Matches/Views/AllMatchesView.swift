import SwiftUI

/// A simple list of all the user's matches, newest/closest first.
struct AllMatchesView: View {
    @State private var matches: [MatchInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            if isLoading && matches.isEmpty {
                ProgressView()
                    .tint(BoopColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
            } else if matches.isEmpty {
                emptyView
            } else {
                LazyVStack(spacing: BoopSpacing.md) {
                    ForEach(matches) { match in
                        NavigationLink {
                            PartnerProfileView(matchId: match.matchId, firstName: match.otherUser.firstName)
                        } label: {
                            row(match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.vertical, BoopSpacing.lg)
            }
        }
        .boopBackground()
        .navigationTitle("Your Matches")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    private func row(_ match: MatchInfo) -> some View {
        HStack(spacing: BoopSpacing.md) {
            AsyncImage(url: URL(string: match.heroPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                    .fill(BoopColors.surfaceSecondary)
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(match.displayName)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(match.stageLabel)
                    .font(BoopTypography.cineCaption)
                    .tracking(0.5)
                    .foregroundStyle(BoopColors.textMuted)
            }

            Spacer()

            if let comfort = match.comfortScore {
                let pts = max(0, 70 - comfort)
                Text(pts > 0 ? "\(pts) to reveal" : "Reveal ready")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(pts > 0 ? BoopColors.textMuted : BoopColors.accentColor)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .thin))
                .foregroundStyle(BoopColors.textMuted)
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.lg, shadow: false)
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "No matches yet")
            AccentRule()
            Text("Head to Discover to start connecting.")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: MatchesResponse = try await APIClient.shared.request(.getMatches())
            matches = response.matches
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load your matches."
        }
    }
}
