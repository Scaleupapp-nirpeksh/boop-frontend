import SwiftUI

/// Cinematic Dark candidate card: a full-bleed, heavily blurred portrait (discovery
/// is pre-match, so faces stay fogged) fading into the ground, with the compatibility
/// eyebrow, name, subtitle, voice intro, "why you fit" hairline chips, and the
/// Pass / Connect actions overlaid. Photography-led, quiet, no emoji or candy.
struct CandidateCardView: View {
    let candidate: Candidate
    let onConnect: () -> Void
    let onSkip: () -> Void

    @State private var isExpanded = false
    @State private var audioPlayer = RemoteAudioPlayer()

    /// Discovery is pre-match — the face must stay heavily fogged. Use the
    /// candidate's blurred/silhouette image and a fixed heavy blur on top.
    private var portraitURL: String? {
        candidate.photos.blurredUrl ?? candidate.photos.silhouetteUrl
    }
    private let portraitBlur: CGFloat = 26
    private let cardHeight: CGFloat = 540

    var body: some View {
        // Read the available viewport width and pin every layer to it. A square
        // blurred portrait under aspectRatio(.fill) with a fixed height reports an
        // intrinsic width equal to that height (~540), and `.frame(maxWidth: .infinity)`
        // only caps growth — it can't shrink that intrinsic width below the proposal
        // inside a vertical ScrollView. Binding to an explicit width stops any
        // descendant (portrait, gradient, content, buttons) from widening the card.
        GeometryReader { proxy in
            cardStack(width: proxy.size.width)
        }
        .frame(height: cardHeight)
    }

    private func cardStack(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            BlurredPortrait(
                urlString: portraitURL,
                blurRadius: portraitBlur,
                shape: .roundedRect(0),
                scrim: false
            )
            .frame(width: width, height: cardHeight)
            .clipped()

            // Fade the portrait into the ground so the type sits on darkness.
            LinearGradient(
                colors: [.clear, BoopColors.ground.opacity(0.55), BoopColors.ground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: width, height: cardHeight)

            content
                .padding(BoopSpacing.lg)
                .frame(width: width, height: cardHeight, alignment: .bottomLeading)
        }
        .frame(width: width, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
        .onDisappear {
            audioPlayer.stop()
        }
    }

    // MARK: - Content stack

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            Spacer(minLength: 0)

            compatibilityHeader

            identityBlock

            if candidate.voiceIntro.audioUrl != nil {
                voiceIntroRow
            }

            whyYouFit

            actionButtons
                .padding(.top, BoopSpacing.xs)
        }
    }

    // MARK: - Compatibility eyebrow

    @ViewBuilder
    private var compatibilityHeader: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: "\(candidate.compatibility.score) COMPATIBLE", color: BoopColors.accentColor)
            AccentRule()
        }
    }

    // MARK: - Name + subtitle

    @ViewBuilder
    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
            Text(candidate.firstName)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(subtitle)
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textSecondary)
                .lineLimit(2)
        }
    }

    /// "27 · Bengaluru · aligned on …" — built from whatever fields exist.
    private var subtitle: String {
        var parts: [String] = []
        if let age = candidate.age { parts.append("\(age)") }
        if let city = candidate.city { parts.append(city) }
        if let lead = candidate.showcaseAnswers.first {
            parts.append("aligned on \(lead.dimensionDisplayName.lowercased())")
        } else {
            parts.append(candidate.compatibility.tierDisplayName.lowercased())
        }
        return parts.joined(separator: "  ·  ")
    }

    // MARK: - Voice intro

    @ViewBuilder
    private var voiceIntroRow: some View {
        let isActive = audioPlayer.currentURL == candidate.voiceIntro.audioUrl && audioPlayer.isPlaying
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: "Voice intro", color: BoopColors.textMuted)
            VoiceLine(
                duration: voiceDurationLabel,
                isPlaying: isActive,
                progress: audioPlayer.currentURL == candidate.voiceIntro.audioUrl ? audioPlayer.progress : 0,
                elapsedText: isActive ? "\(formatPlaybackTime(audioPlayer.elapsed)) / \(formatPlaybackTime(audioPlayer.duration))" : nil,
                onTap: {
                    Haptics.light()
                    audioPlayer.togglePlayback(urlString: candidate.voiceIntro.audioUrl)
                }
            )
        }
    }

    private var voiceDurationLabel: String {
        if let duration = candidate.voiceIntro.duration {
            return "\(Int(duration))s"
        }
        return "Listen"
    }

    // MARK: - Why you fit (hairline chips)

    @ViewBuilder
    private var whyYouFit: some View {
        if !fitChips.isEmpty {
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                EyebrowLabel(text: "Why you fit", color: BoopColors.textMuted)
                FlowChips(items: fitChips)

                if let answer = leadAnswer {
                    Text("\u{201C}\(answer.answer)\u{201D}")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .italic()
                        .lineLimit(isExpanded ? nil : 3)
                        .onTapGesture { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }
                }
            }
        }
    }

    private var leadAnswer: ShowcaseAnswer? {
        candidate.showcaseAnswers.first
    }

    /// Hairline text chips drawn from the strongest compatibility dimensions,
    /// falling back to the showcase-answer dimensions. Thin, sharp, no emoji.
    private var fitChips: [String] {
        if let dimensions = candidate.compatibility.dimensions, !dimensions.isEmpty {
            return dimensions
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { friendlyDimensionTitle(for: $0.key) }
        }
        // Fallback: dedupe showcase-answer dimensions.
        var seen = Set<String>()
        var titles: [String] = []
        for answer in candidate.showcaseAnswers {
            let title = answer.dimensionDisplayName
            if seen.insert(title).inserted { titles.append(title) }
            if titles.count == 3 { break }
        }
        return titles
    }

    private func friendlyDimensionTitle(for key: String) -> String {
        switch key {
        case "emotional_vulnerability": return "Emotional honesty"
        case "attachment_patterns": return "Attachment rhythm"
        case "life_vision": return "Life direction"
        case "conflict_resolution": return "Repair style"
        case "love_expression": return "Love language"
        case "intimacy_comfort": return "Closeness comfort"
        case "lifestyle_rhythm": return "Daily rhythm"
        case "growth_mindset": return "Growth mindset"
        default:
            return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: BoopSpacing.sm) {
            // Pass — hairline-outlined, softly rounded
            Button(action: onSkip) {
                Text("Pass")
                    .font(.system(size: 15, weight: .regular))
                    .tracking(0.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(BoopColors.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                            .stroke(BoopColors.hairline, lineWidth: 1)
                    )
            }

            // Connect — flat coral bar, softly rounded
            Button(action: onConnect) {
                Text("Connect")
                    .font(.system(size: 15, weight: .semibold))
                    .tracking(0.5)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(BoopColors.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous))
            }
        }
    }
}

// MARK: - Flowing hairline chips

/// Wrapping row of thin, hairline-outlined, softly rounded text chips. No emoji, no candy.
private struct FlowChips: View {
    let items: [String]

    var body: some View {
        FlowLayout(spacing: BoopSpacing.xs) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(BoopTypography.cineCaption)
                    .tracking(0.5)
                    .foregroundStyle(BoopColors.textSecondary)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, BoopSpacing.xs)
                    .overlay(
                        RoundedRectangle(cornerRadius: BoopRadius.chip, style: .continuous)
                            .stroke(BoopColors.hairline, lineWidth: 1)
                    )
            }
        }
    }
}
