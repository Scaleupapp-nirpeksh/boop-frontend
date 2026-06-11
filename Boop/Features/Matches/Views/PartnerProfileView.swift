import SwiftUI

/// Read-only depth view of a matched partner: who they are, how they sound,
/// their personality type and shape, and a few of their answers in their own
/// words. Presented from MatchDetailView.
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

                        if let facets = partner.facets, !facets.isEmpty {
                            shapeSection(facets)
                        }

                        if hasWords(partner) {
                            wordsSection(partner)
                        }
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

    // MARK: - Their shape (facet bars)

    private func shapeSection(_ facets: [PartnerFacet]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Their Shape")

            VStack(spacing: 0) {
                ForEach(facets) { facet in
                    facetRow(facet)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func facetRow(_ facet: PartnerFacet) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(facet.title ?? facet.key.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text("\(facet.score ?? 0)")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(BoopColors.textPrimary)
                }

                HairlineProgress(progress: Double(facet.score ?? 0) / 100.0)
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    // MARK: - In their words (bio + showcase answers as quiet quote rows)

    private func hasWords(_ partner: PartnerProfile) -> Bool {
        if let bio = partner.bio, !bio.isEmpty { return true }
        return !(partner.showcaseAnswers ?? []).isEmpty
    }

    private func wordsSection(_ partner: PartnerProfile) -> some View {
        let answers = partner.showcaseAnswers ?? []

        return VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "In Their Words")

            VStack(spacing: 0) {
                if let bio = partner.bio, !bio.isEmpty {
                    wordRow(label: "About", text: bio)
                }

                ForEach(Array(answers.enumerated()), id: \.offset) { _, item in
                    if let answer = item.answer, !answer.isEmpty {
                        wordRow(label: item.questionText ?? "They shared", text: answer)
                    }
                }

                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func wordRow(label: String, text: String) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                EyebrowLabel(text: label)
                    .fixedSize(horizontal: false, vertical: true)
                Text(text)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, BoopSpacing.md)
        }
    }

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
