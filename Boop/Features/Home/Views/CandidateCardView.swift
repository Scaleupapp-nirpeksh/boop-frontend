import SwiftUI

struct CandidateCardView: View {
    let candidate: Candidate
    let onConnect: () -> Void
    let onSkip: () -> Void

    @State private var isExpanded = false
    @State private var audioPlayer = RemoteAudioPlayer()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBanner

            identityRow
                .padding(.horizontal, BoopSpacing.lg)
                .padding(.top, BoopSpacing.lg)

            if candidate.voiceIntro.audioUrl != nil {
                voiceIntroRow
                    .padding(.horizontal, BoopSpacing.lg)
                    .padding(.vertical, BoopSpacing.sm)
            }

            showcaseSection
                .padding(BoopSpacing.lg)

            compatibilitySection
                .padding(.horizontal, BoopSpacing.lg)

            actionButtons
                .padding(BoopSpacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .fill(BoopColors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: BoopColors.primary.opacity(0.1), radius: 20, y: 12)
        )
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private var topBanner: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BoopColors.cardDarkAlt, BoopColors.cardDarkDeepBlue, Color(hex: "3A5668")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay {
                    if let visualURL = candidate.photos.blurredUrl ?? candidate.photos.silhouetteUrl {
                        BoopRemoteImage(urlString: visualURL) {
                            Rectangle().fill(Color.clear)
                        }
                        .opacity(0.3)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(BoopColors.secondary.opacity(0.18))
                        .frame(width: 96, height: 96)
                        .blur(radius: 6)
                        .offset(x: 24, y: -12)
                }
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(BoopColors.primary.opacity(0.16))
                        .frame(width: 108, height: 108)
                        .blur(radius: 4)
                        .offset(x: -18, y: -24)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text("Match signal")
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .kerning(1.0)
                    .foregroundStyle(Color.white.opacity(0.68))

                Text("\(candidate.compatibility.score)% aligned")
                    .font(BoopTypography.title2)
                    .foregroundStyle(.white)
            }
            .padding(BoopSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
    }

    private var identityRow: some View {
        HStack(alignment: .top, spacing: BoopSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [BoopColors.primary.opacity(0.15), BoopColors.secondary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [BoopColors.primary.opacity(0.4), BoopColors.secondary.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )

                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(BoopColors.primary.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: BoopSpacing.xxs) {
                    Text(candidate.firstName)
                        .font(BoopTypography.title3)
                        .foregroundStyle(BoopColors.textPrimary)

                    if let age = candidate.age {
                        Text(", \(age)")
                            .font(BoopTypography.title3)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                }

                if let city = candidate.city {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                        Text(city)
                            .font(BoopTypography.footnote)
                    }
                    .foregroundStyle(BoopColors.textMuted)
                }

                Text("Answers first.")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)
                    .padding(.top, 2)
            }

            Spacer()

            compatibilityBadge
        }
    }

    private var voiceIntroRow: some View {
        HStack(spacing: BoopSpacing.sm) {
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index.isMultiple(of: 3) ? BoopColors.secondary : BoopColors.secondary.opacity(0.4))
                        .frame(width: 4, height: CGFloat(12 + (index % 4) * 5))
                }
            }
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, BoopSpacing.xs)
            .background(BoopColors.secondary.opacity(0.1))
            .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text("Voice intro available")
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.secondary)

                if let duration = candidate.voiceIntro.duration {
                    Text("\(Int(duration)) second intro")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            Spacer()

            Button {
                audioPlayer.togglePlayback(urlString: candidate.voiceIntro.audioUrl)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: audioPlayer.currentURL == candidate.voiceIntro.audioUrl && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    Text(audioPlayer.currentURL == candidate.voiceIntro.audioUrl && audioPlayer.isPlaying ? "Pause" : "Play")
                }
                .font(BoopTypography.footnote)
                .foregroundStyle(BoopColors.textPrimary)
                .padding(.horizontal, BoopSpacing.sm)
                .padding(.vertical, BoopSpacing.xs)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
    }

    private var showcaseSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                Text("Answers")
                    .font(BoopTypography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(BoopColors.textPrimary)

            if let firstAnswer = candidate.showcaseAnswers.first {
                dimensionTag(for: firstAnswer)

                Text("\"\(firstAnswer.answer)\"")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
                    .italic()
                    .lineLimit(isExpanded ? nil : 4)
                    .onTapGesture { withAnimation { isExpanded.toggle() } }

                if isExpanded && candidate.showcaseAnswers.count > 1 {
                    ForEach(candidate.showcaseAnswers.dropFirst()) { answer in
                        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                            dimensionTag(for: answer)

                            Text("\"\(answer.answer)\"")
                                .font(BoopTypography.body)
                                .foregroundStyle(BoopColors.textPrimary)
                                .italic()
                        }
                        .padding(.top, BoopSpacing.xs)
                    }
                }

                if !isExpanded && candidate.showcaseAnswers.count > 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { isExpanded = true }
                    } label: {
                        HStack(spacing: 4) {
                            Text("+ \(candidate.showcaseAnswers.count - 1) more answer\(candidate.showcaseAnswers.count > 2 ? "s" : "") to discover")
                                .font(BoopTypography.footnote)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(BoopColors.primary)
                    }
                    .padding(.top, BoopSpacing.xxs)
                }
            } else {
                Text("This person hasn't shared answers yet")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textMuted)
                    .italic()
            }
        }
    }

    private func dimensionTag(for answer: ShowcaseAnswer) -> some View {
        let color = BoopColors.dimensionColor(for: answer.dimension)
        return Text(answer.dimensionDisplayName)
            .font(BoopTypography.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, BoopSpacing.xs)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var compatibilityBadge: some View {
        HStack(spacing: BoopSpacing.xs) {
            Text(candidate.compatibility.tierEmoji)
                .font(.system(size: 16))
            Text(candidate.compatibility.tierDisplayName)
                .font(BoopTypography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(tierColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, BoopSpacing.sm)
        .padding(.vertical, BoopSpacing.xxs)
        .background(tierColor.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(tierColor.opacity(0.2), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var compatibilitySection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Why it fits")
                .font(BoopTypography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(BoopColors.textPrimary)

            Text(compatibilitySummary)
                .font(BoopTypography.footnote)
                .foregroundStyle(BoopColors.textSecondary)

            if !topDimensionInsights.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    ForEach(topDimensionInsights, id: \.title) { item in
                        HStack(alignment: .top, spacing: BoopSpacing.xs) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.title)
                                        .font(BoopTypography.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(BoopColors.textPrimary)
                                    Text("\(item.score)%")
                                        .font(BoopTypography.caption)
                                        .foregroundStyle(item.color)
                                }

                                Text(item.copy)
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.surfaceBlushLight)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
    }

    private var tierColor: Color {
        switch candidate.compatibility.tier {
        case "platinum": return BoopColors.secondary
        case "gold": return BoopColors.accent
        case "silver": return BoopColors.textSecondary
        default: return BoopColors.primary
        }
    }

    private var compatibilitySummary: String {
        switch candidate.compatibility.tier {
        case "platinum":
            return "\(candidate.compatibility.score)% aligned. Rare level chemistry across your strongest traits."
        case "gold":
            return "\(candidate.compatibility.score)% aligned. Strong overlap in the places that usually matter early."
        case "silver":
            return "\(candidate.compatibility.score)% aligned. There is enough shared ground here to explore properly."
        default:
            return "\(candidate.compatibility.score)% aligned. Early signs are promising, but this one needs discovery."
        }
    }

    private var topDimensionInsights: [(title: String, score: Int, copy: String, color: Color)] {
        guard let dimensions = candidate.compatibility.dimensions else { return [] }

        return dimensions
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { key, rawScore in
                let score = Int(rawScore.rounded())
                return (
                    title: friendlyDimensionTitle(for: key),
                    score: score,
                    copy: dimensionCopy(for: key),
                    color: BoopColors.dimensionColor(for: key)
                )
            }
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

    private func dimensionCopy(for key: String) -> String {
        switch key {
        case "emotional_vulnerability": return "You may open up at a similar emotional depth."
        case "attachment_patterns": return "Your way of seeking closeness looks naturally compatible."
        case "life_vision": return "The kind of future you want has overlap."
        case "conflict_resolution": return "You may recover from tension in similar ways."
        case "love_expression": return "The way you show care could land well on each other."
        case "intimacy_comfort": return "Your pace around closeness may feel easier to share."
        case "lifestyle_rhythm": return "Your everyday energy could fit well together."
        case "growth_mindset": return "Both of you seem open to learning and evolving."
        default: return "One of the stronger areas in this match."
        }
    }

    private var actionButtons: some View {
        HStack(spacing: BoopSpacing.md) {
            Button(action: onSkip) {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Skip")
                        .font(BoopTypography.callout)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .foregroundStyle(BoopColors.textSecondary)
                .background(BoopColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
            }

            Button(action: onConnect) {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                    Text("Connect")
                        .font(BoopTypography.callout)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .foregroundStyle(.white)
                .background(BoopColors.primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
            }
        }
    }
}
