import SwiftUI

/// Read-only depth view of a matched partner: who they are, how they sound,
/// and their personality type and shape. Deliberately never shows the partner's
/// verbatim written answers (privacy). Presented from MatchDetailView.
struct PartnerProfileView: View {
    let matchId: String
    var firstName: String? = nil

    @State private var viewModel = PartnerProfileViewModel()
    @State private var audioPlayer = RemoteAudioPlayer()

    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.isLoading && viewModel.partner == nil {
                loadingView
            } else if let partner = viewModel.partner {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection(partner)

                    VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                        if partner.voiceIntro?.audioUrl != nil {
                            voiceSection(partner)
                        }

                        typeSection(partner)

                        connectionCard

                        compareSection(partner)
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.top, BoopSpacing.lg)
                    .padding(.bottom, BoopSpacing.xxl)
                }
            } else if let error = viewModel.errorMessage {
                errorView(error)
            }
        }
        .boopBackground()
        .navigationTitle(viewModel.partner?.firstName ?? firstName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(matchId: matchId)
        }
        .refreshable {
            await viewModel.load(matchId: matchId)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    // MARK: - Hero (full-bleed portrait, honors photo reveal state)

    private func heroSection(_ partner: PartnerProfile) -> some View {
        CinematicHeader(
            urlString: heroPhotoURL(partner),
            blurRadius: partner.photos?.clearUrl != nil ? 0 : 18,
            height: 320
        ) {
            EyebrowLabel(text: "Their Profile", color: BoopColors.accentColor)
            AccentRule()
            Text(heroTitle(partner))
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            if let city = partner.city, !city.isEmpty {
                Text(city.uppercased())
                    .font(BoopTypography.cineCaption)
                    .tracking(1.5)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }

    /// Clear photo only once the match's reveal has happened; otherwise the
    /// blurred portrait stays fogged (silhouette as last resort).
    private func heroPhotoURL(_ partner: PartnerProfile) -> String? {
        partner.photos?.clearUrl ?? partner.photos?.blurredUrl ?? partner.photos?.silhouetteUrl
    }

    private func heroTitle(_ partner: PartnerProfile) -> String {
        let name = partner.firstName ?? "Someone"
        if let age = partner.age {
            return "\(name), \(age)"
        }
        return name
    }

    // MARK: - Voice

    private func voiceSection(_ partner: PartnerProfile) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Voice Intro")

            if let audioURL = partner.voiceIntro?.audioUrl {
                let isActive = audioPlayer.currentURL == audioURL && audioPlayer.isPlaying
                VoiceLine(
                    duration: voiceDurationText(partner),
                    isPlaying: isActive,
                    progress: audioPlayer.currentURL == audioURL ? audioPlayer.progress : 0,
                    elapsedText: isActive ? "\(formatPlaybackTime(audioPlayer.elapsed)) / \(formatPlaybackTime(audioPlayer.duration))" : nil
                ) {
                    audioPlayer.togglePlayback(urlString: audioURL)
                }
            }
        }
    }

    private func voiceDurationText(_ partner: PartnerProfile) -> String {
        if let duration = partner.voiceIntro?.duration {
            return "\(Int(duration))s"
        }
        return ""
    }

    // MARK: - Their type ("Coded & Rare" block, mirrors PersonalityReportView's hero)

    @ViewBuilder
    private func typeSection(_ partner: PartnerProfile) -> some View {
        if let archetype = partner.archetype, let name = archetype.name {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    if let number = archetype.number {
                        Text(String(format: "TYPE %02d", number))
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                    Spacer()
                    if let rarity = archetype.rarityPercent {
                        Text("\(rarity)% RARE")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.accentColor)
                    }
                }

                Text(name)
                    .font(BoopTypography.cineDisplay)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let rarity = archetype.rarityPercent {
                    Text("Only \(rarity)% share \(name)")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AccentRule()

                if let essence = archetype.essence, !essence.isEmpty {
                    Text(essence)
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let answered = partner.questionsAnswered, answered > 0 {
                    Text("Based on \(answered) answers")
                        .font(BoopTypography.cineCaption)
                        .tracking(1.5)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                EyebrowLabel(text: "Their Type")
                AccentRule()
                Text("Their type reveals as you talk.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
            }
        }
    }

    // MARK: - Your connection (opens the connection page)

    @ViewBuilder
    private var connectionCard: some View {
        if let detail = viewModel.matchDetail, detail.origin == "pair" || detail.usLinked == true {
            NavigationLink {
                PairHubView(matchId: matchId, partnerName: viewModel.partner?.firstName ?? firstName ?? "them")
            } label: {
                HStack(spacing: BoopSpacing.md) {
                    Text("✧")
                        .font(.system(size: 24))
                        .foregroundStyle(BoopColors.accentColor)

                    VStack(alignment: .leading, spacing: 3) {
                        EyebrowLabel(text: "Your Us", color: BoopColors.accentColor)
                        Text("Games, questions and chemistry — just you two")
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                .padding(BoopSpacing.lg)
                .boopCard(radius: BoopRadius.xl, shadow: false)
            }
            .buttonStyle(.plain)
        } else if let detail = viewModel.matchDetail {
            let comfort = min(100, max(0, detail.comfortScore ?? 0))
            let revealed = detail.stage == "revealed" || detail.stage == "dating"
            let pts = max(0, 70 - comfort)
            let phrase: String = {
                if revealed { return "In full colour" }
                if comfort >= 70 { return "Ready for the reveal" }
                if comfort >= 45 { return "The fog is lifting" }
                if comfort >= 25 { return "Warming up" }
                return "Just beginning"
            }()

            NavigationLink {
                MatchDetailView(matchId: matchId)
            } label: {
                HStack(spacing: BoopSpacing.md) {
                    Text("🫧")
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 3) {
                        EyebrowLabel(text: "Your Connection", color: BoopColors.accentColor)
                        Text(phrase)
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)
                        if !revealed && pts > 0 {
                            Text("\(pts) points to the reveal")
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                .padding(BoopSpacing.lg)
                .boopCard(radius: BoopRadius.xl, shadow: false)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - How you two compare (you vs her + overall connection)

    @ViewBuilder
    private func compareSection(_ partner: PartnerProfile) -> some View {
        let partnerFacets = partner.facets ?? []
        let herName = partner.firstName ?? firstName ?? "Them"
        if !partnerFacets.isEmpty || viewModel.compatibilityScore != nil {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                EyebrowLabel(text: "How you two compare")

                if let compat = viewModel.compatibilityScore {
                    compatHero(compat)
                }

                VStack(spacing: BoopSpacing.lg) {
                    ForEach(partnerFacets) { facet in
                        compareRow(facet: facet, herName: herName)
                    }
                }
            }
        }
    }

    private func compatHero(_ compat: Int) -> some View {
        HStack(alignment: .center, spacing: BoopSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(compatLabel(compat))
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)
                Text("how connected you two are")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }
            Spacer()
            Text("\(compat)%")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(BoopColors.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.lg, shadow: false)
    }

    private func compatLabel(_ c: Int) -> String {
        if c >= 85 { return "Rare chemistry" }
        if c >= 70 { return "Strong connection" }
        if c >= 55 { return "Real potential" }
        return "Worth exploring"
    }

    private func compareRow(facet: PartnerFacet, herName: String) -> some View {
        let title = facet.title ?? facet.key.replacingOccurrences(of: "_", with: " ").capitalized
        let herScore = facet.score ?? 0
        let myScore = viewModel.myFacets.first(where: { $0.key == facet.key })?.score
        return VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text(title)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
            if let myScore {
                barLine(label: "You", score: myScore, color: BoopColors.accentColor)
            }
            barLine(label: herName, score: herScore, color: Color(hex: "6E84E6"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func barLine(label: String, score: Int, color: Color) -> some View {
        HStack(spacing: BoopSpacing.sm) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(1)
                .foregroundStyle(color)
                .frame(width: 64, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(BoopColors.hairline)
                    Capsule().fill(color).frame(width: max(6, geo.size.width * CGFloat(score) / 100))
                }
            }
            .frame(height: 7)
            Text("\(score)")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(BoopColors.textSecondary)
                .frame(width: 28, alignment: .trailing)
        }
    }

    // PRIVACY: the partner's verbatim written answers (their "showcase answers"
    // / raw question responses) and free-text bio are intentionally NOT rendered
    // here. The "About [person]" page may only surface derived signals — voice
    // intro, personality type (archetype), and the facet shape. Verbatim
    // responses surface elsewhere as synthesized summaries (answer-sync), never
    // as the other person's exact words on this page.

    // MARK: - Loading

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            Rectangle()
                .fill(BoopColors.surfaceSecondary)
                .frame(height: 320)

            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(BoopColors.surfaceSecondary)
                        .frame(height: 1)
                        .padding(.vertical, BoopSpacing.xl)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Couldn't load", color: BoopColors.error)
            AccentRule()
            Text(message)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.error)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.vertical, BoopSpacing.xl)
    }
}
