import SwiftUI

// MARK: - Shared game result reveal
//
// One celebratory "what came of it" moment that EVERY game plugs into — not just
// Would You Rather. It normalises each game's result shape into a sync summary
// and renders a dopamine-hit reveal: a rolling number, a filling ring, a coral
// bloom pulse, and celebration haptics. The per-round breakdown still renders
// below it in `GameSessionView`.

/// How a game's "togetherness" is measured.
enum GameSyncKind {
    case picks   // Would You Rather, Never Have I Ever — same pick = in sync
    case scale   // Intimacy Spectrum — close numbers = aligned
    case text    // open-ended games — no objective match; celebrate showing up
}

/// Normalised, game-agnostic result used to drive the reveal.
struct GameSyncSummary {
    let kind: GameSyncKind
    let totalRounds: Int
    let comparableRounds: Int   // rounds where both players answered
    let inSyncRounds: Int       // matched picks / aligned scales
    let answeredByMe: Int
    let isFull: Bool
    let partnerName: String
    /// How much this game lifted the connection's comfort (drives the fog/blur).
    let comfortDelta: Int?
    let comfortAfter: Int?

    var didLiftComfort: Bool { (comfortDelta ?? 0) > 0 }

    /// 0–100 overlap for picks/scale games; for text games this is full once both showed up.
    var syncPercent: Int {
        switch kind {
        case .text:
            return comparableRounds > 0 ? 100 : 0
        case .picks, .scale:
            guard comparableRounds > 0 else { return 0 }
            return Int((Double(inSyncRounds) / Double(comparableRounds) * 100).rounded())
        }
    }

    var ringFraction: Double { Double(syncPercent) / 100.0 }

    /// Big headline number shown inside the ring.
    var heroValue: Int {
        switch kind {
        case .text: return comparableRounds
        case .picks, .scale: return inSyncRounds
        }
    }

    var heroUnit: String {
        switch kind {
        case .text: return comparableRounds == 1 ? "moment shared" : "moments shared"
        case .picks, .scale: return "of \(comparableRounds) in sync"
        }
    }

    var headline: String {
        switch kind {
        case .text:
            return "You both showed up"
        case .picks, .scale:
            switch syncPercent {
            case 80...:  return "You're remarkably in sync"
            case 50..<80: return "You've got real overlap"
            case 1..<50:  return "Opposites attract"
            default:      return "Two different worlds"
            }
        }
    }

    var subline: String {
        switch kind {
        case .text:
            return "\(comparableRounds) honest \(comparableRounds == 1 ? "answer" : "answers") between you and \(partnerName)."
        case .picks, .scale:
            return "You and \(partnerName) lined up on \(inSyncRounds) of \(comparableRounds)."
        }
    }

    /// Whether to fire the louder, hearts-and-bloom celebration.
    var isCelebratory: Bool {
        switch kind {
        case .text: return comparableRounds > 0
        case .picks, .scale: return syncPercent >= 50
        }
    }

    // MARK: Build from a live session

    static func make(from game: GameSession, currentUserId: String?) -> GameSyncSummary {
        let kind: GameSyncKind
        switch game.gameType {
        case "would_you_rather", "never_have_i_ever": kind = .picks
        case "intimacy_spectrum":                     kind = .scale
        default:                                       kind = .text
        }

        let completed = game.rounds.filter(\.isComplete)
        var comparable = 0
        var inSync = 0
        var partnerName = "your partner"

        for round in completed {
            let responses = round.responses ?? []
            guard responses.count == 2 else { continue }
            comparable += 1

            switch kind {
            case .picks:
                if responses[0].answer.lowercased() == responses[1].answer.lowercased() { inSync += 1 }
            case .scale:
                let a = Int(responses[0].answer) ?? 0
                let b = Int(responses[1].answer) ?? 0
                if abs(a - b) <= 2 { inSync += 1 }
            case .text:
                break
            }

            if let name = responses.first(where: { $0.userId?.id != currentUserId })?.userId?.firstName,
               !name.isEmpty {
                partnerName = name
            }
        }

        let answeredByMe = game.rounds.filter { round in
            round.responses?.contains(where: { $0.userId?.id == currentUserId }) == true
        }.count

        return GameSyncSummary(
            kind: kind,
            totalRounds: game.totalRounds,
            comparableRounds: comparable,
            inSyncRounds: inSync,
            answeredByMe: answeredByMe,
            isFull: completed.count == game.totalRounds,
            partnerName: partnerName,
            comfortDelta: game.comfort?.delta,
            comfortAfter: game.comfort?.after
        )
    }
}

// MARK: - Reveal view

struct GameResultRevealView: View {
    let summary: GameSyncSummary

    @State private var appeared = false
    @State private var shownValue = 0
    @State private var bloom = false

    private let ringSize: CGFloat = 168

    var body: some View {
        VStack(spacing: BoopSpacing.lg) {
            EyebrowLabel(text: "Finished together", color: BoopColors.accentColor)

            ZStack {
                // Coral bloom pulse behind the ring — the dopamine flare.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BoopColors.accentColor.opacity(0.55), .clear],
                            center: .center, startRadius: 1, endRadius: ringSize * 0.7
                        )
                    )
                    .frame(width: ringSize, height: ringSize)
                    .scaleEffect(bloom ? 1.15 : 0.6)
                    .opacity(bloom ? (summary.isCelebratory ? 0.9 : 0.5) : 0)
                    .blur(radius: 8)

                // Track + progress ring
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: appeared ? summary.ringFraction : 0)
                    .stroke(BoopColors.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(shownValue)")
                        .font(BoopTypography.cineDisplayXL)
                        .foregroundStyle(BoopColors.textPrimary)
                        .contentTransition(.numericText(value: Double(shownValue)))
                        .monospacedDigit()
                    Text(summary.heroUnit.uppercased())
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, BoopSpacing.sm)

                // A few rising sparks on a strong result — restrained, on-brand.
                if summary.isCelebratory {
                    CelebrationSparks(active: appeared)
                        .frame(width: ringSize * 1.6, height: ringSize * 1.6)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: ringSize, height: ringSize)

            VStack(spacing: BoopSpacing.xs) {
                Text(summary.headline)
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.subline)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Comfort lift — ties the game to the connection growing (and the
            // photo fog lifting). Only shown when this game actually moved it.
            if summary.didLiftComfort, let delta = summary.comfortDelta {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                    Text("Comfort +\(delta) · the fog lifted a little")
                        .font(BoopTypography.cineLabel)
                        .tracking(1)
                }
                .foregroundStyle(BoopColors.accentColor)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.xs)
                .overlay(
                    Capsule().stroke(BoopColors.accentColor.opacity(0.4), lineWidth: 1)
                )
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
            }

            // Compact stat strip — keeps the at-a-glance numbers.
            HStack(spacing: BoopSpacing.lg) {
                stat("\(summary.comparableRounds)/\(summary.totalRounds)", "Rounds")
                stat("\(summary.answeredByMe)", "You answered")
                stat(summary.isFull ? "Full" : "Partial", "Completion")
            }
            .padding(.top, BoopSpacing.xs)
        }
        .padding(BoopSpacing.lg)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
        )
        .onAppear(perform: runReveal)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private func runReveal() {
        guard !appeared else { return }
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appeared = true }
        withAnimation(.easeOut(duration: 0.9)) { shownValue = summary.heroValue }
        withAnimation(.easeOut(duration: 0.8).delay(0.15)) { bloom = true }

        if summary.isCelebratory {
            Haptics.celebration()
        } else {
            Haptics.success()
        }
    }
}

// MARK: - Restrained celebration sparks

/// A small set of coral hearts that rise and fade once — tasteful, not confetti.
private struct CelebrationSparks: View {
    let active: Bool
    private let count = 7

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let frac = CGFloat(i) / CGFloat(max(count - 1, 1))
                    let x = geo.size.width * (0.18 + 0.64 * frac)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9 + CGFloat(i % 3) * 3))
                        .foregroundStyle(BoopColors.accentColor.opacity(0.85))
                        .position(x: x, y: geo.size.height * 0.62)
                        .offset(y: active ? -geo.size.height * (0.34 + 0.10 * frac) : 0)
                        .opacity(active ? 0 : 0.9)
                        .animation(
                            .easeOut(duration: 1.5).delay(0.1 + Double(i) * 0.08),
                            value: active
                        )
                }
            }
        }
    }
}
