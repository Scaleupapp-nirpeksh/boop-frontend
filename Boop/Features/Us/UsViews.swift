import SwiftUI

// MARK: - "Us" tab: people you know

/// The Us tab: your own space for people you already know — separate from
/// dating. Pairs live here, invites start here, codes are redeemed here.
struct UsTabView: View {
    @State private var viewModel = UsViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Us", color: BoopColors.accentColor)
                    AccentRule()
                    Text("People you know")
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("Someone from your world — see how you two actually match. No stages, no fog. Just you two.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, BoopSpacing.xl)

                VStack(spacing: BoopSpacing.md) {
                    if viewModel.pairs.isEmpty && !viewModel.isLoadingPairs {
                        emptyState
                    } else {
                        ForEach(viewModel.pairs) { pair in
                            NavigationLink {
                                PartnerProfileView(matchId: pair.matchId, firstName: pair.otherUser.firstName)
                            } label: {
                                pairRow(pair)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    NavigationLink {
                        UsInviteView()
                    } label: {
                        inviteCard
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        UsRedeemView()
                    } label: {
                        HStack(spacing: BoopSpacing.xs) {
                            Text("Have a code?")
                                .font(BoopTypography.cineLabel)
                                .tracking(1.5)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .thin))
                        }
                        .foregroundStyle(BoopColors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, BoopSpacing.xl)
            }
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationBarHidden(true)
        .task { await viewModel.loadPairs() }
        .refreshable { await viewModel.loadPairs() }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Nobody here yet ✧")
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)
            Text("A crush, a maybe, or the one you're already with — invite them and find out what you two are made of.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.xl)
        .boopCard(radius: BoopRadius.xxl, shadow: false)
    }

    private func pairRow(_ pair: MatchInfo) -> some View {
        HStack(spacing: BoopSpacing.md) {
            AsyncImage(url: URL(string: pair.heroPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(BoopColors.surfaceSecondary)
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(pair.otherUser.firstName)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Text(pairLine(pair))
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.accentColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .thin))
                .foregroundStyle(BoopColors.textMuted)
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.lg, shadow: false)
    }

    private func pairLine(_ pair: MatchInfo) -> String {
        if pair.usLinked == true { return "Found each other twice ✨" }
        return "Exploring together"
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("+ Invite someone you know")
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.accentColor)
            Text("They get a code. You two get chemistry.")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                .stroke(BoopColors.accentColor.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [7, 7]))
        )
    }
}

// MARK: - Invite: create + share a pair code

struct UsInviteView: View {
    @State private var viewModel = UsViewModel()

    private var shareMessage: String {
        let code = viewModel.currentCode?.code ?? ""
        return "I want to see how we actually match 👀 My UnMutee code: \(code) — get the app: https://apps.apple.com/in/app/id6760401571"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Us", color: BoopColors.accentColor)
                    AccentRule()
                    Text("Invite someone you know")
                        .font(BoopTypography.cineDisplay)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Share a code with one person — a crush, a maybe, your favourite human. The moment they join, you two are paired: games, questions and chemistry, just for you.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let invite = viewModel.currentCode {
                    VStack(alignment: .leading, spacing: BoopSpacing.md) {
                        HStack(spacing: BoopSpacing.sm) {
                            ForEach(Array(invite.code.enumerated()), id: \.offset) { _, ch in
                                Text(String(ch))
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundStyle(BoopColors.textPrimary)
                                    .frame(width: 46, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                                            .fill(BoopColors.surface)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                                            .stroke(BoopColors.hairline, lineWidth: 1)
                                    )
                            }
                        }
                        Text("EXPIRES IN 7 DAYS · ONE PERSON ONLY")
                            .font(BoopTypography.cineCaption)
                            .tracking(1)
                            .foregroundStyle(BoopColors.textMuted)

                        ShareLink(item: shareMessage) {
                            Text("Share the code")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BoopSpacing.md)
                                .background(Capsule().fill(BoopColors.accentColor))
                        }
                    }
                } else {
                    BoopButton(title: "Create a code", isLoading: viewModel.isWorking) {
                        Task { await viewModel.createInvite() }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
                }

                if !viewModel.activeInvites.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        EyebrowLabel(text: "Your active codes")
                        VStack(spacing: 0) {
                            ForEach(viewModel.activeInvites) { invite in
                                VStack(spacing: 0) {
                                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                                    HStack {
                                        Text(invite.code)
                                            .font(.system(size: 19, weight: .medium))
                                            .tracking(3)
                                            .foregroundStyle(BoopColors.textPrimary)
                                        Spacer()
                                        Text("waiting")
                                            .font(BoopTypography.cineCaption)
                                            .foregroundStyle(BoopColors.textMuted)
                                        Button("Revoke") {
                                            Task { await viewModel.revoke(invite.code) }
                                        }
                                        .font(BoopTypography.cineCaption)
                                        .foregroundStyle(BoopColors.accentColor)
                                    }
                                    .padding(.vertical, BoopSpacing.md)
                                }
                            }
                            Rectangle().fill(BoopColors.hairline).frame(height: 1)
                        }
                        Text("Up to 5 active codes · each pairs you with one person")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Invite")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadInvites() }
    }
}

// MARK: - Redeem: enter a code, get paired

struct UsRedeemView: View {
    @State private var viewModel = UsViewModel()
    @State private var code = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                if let result = viewModel.redeemResult {
                    successView(result)
                } else {
                    entryView
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Pair up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var entryView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            EyebrowLabel(text: "Have a pair code?", color: BoopColors.accentColor)
            AccentRule()
            Text("Enter your code")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text("The six characters someone you know shared with you.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)

            TextField("ROSE42", text: $code)
                .font(.system(size: 34, weight: .semibold))
                .tracking(10)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .padding(.vertical, BoopSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                        .fill(BoopColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                        .stroke(code.count == 6 ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1.5)
                )
                .onChange(of: code) { _, newValue in
                    code = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(6))
                }

            BoopButton(title: "Pair up", isLoading: viewModel.isWorking, isDisabled: code.count != 6) {
                Task { await viewModel.redeem(code) }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }

    private func successView(_ result: PairRedeemResponse) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            EyebrowLabel(text: outcomeEyebrow(result.outcome), color: BoopColors.accentColor)
            AccentRule()

            Text(outcomeTitle(result))
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(outcomeLine(result.outcome))
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                PartnerProfileView(matchId: result.matchId, firstName: result.partner.firstName)
            } label: {
                Text("Say hi")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BoopSpacing.md)
                    .background(Capsule().fill(BoopColors.accentColor))
            }
        }
    }

    private func outcomeEyebrow(_ outcome: String) -> String {
        switch outcome {
        case "merged": return "You found each other twice"
        case "already_connected": return "Already connected"
        case "reactivated": return "A fresh start"
        default: return "Paired"
        }
    }

    private func outcomeTitle(_ result: PairRedeemResponse) -> String {
        let name = result.partner.firstName ?? "them"
        switch result.outcome {
        case "merged": return "It was \(name) all along ✨"
        case "already_connected": return "You and \(name) are already here"
        case "reactivated": return "Back with \(name)"
        default: return "You're paired with \(name)"
        }
    }

    private func outcomeLine(_ outcome: String) -> String {
        switch outcome {
        case "merged":
            return "You two were already matched here — photos are now unlocked and your whole history comes along."
        case "already_connected":
            return "Your existing connection now has the Us view too."
        case "reactivated":
            return "Your pair is back, fresh start. Be kind to each other."
        default:
            return "Games, questions and chemistry — just you two."
        }
    }
}
