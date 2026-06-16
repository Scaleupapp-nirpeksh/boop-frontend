import SwiftUI

/// Horizontal connection-stage stepper for the slimmed match detail page.
///
/// Replaces the old vertical timeline + separate "Recommended next move" block.
/// It renders the stage steps left-to-right, a one-line summary of where the
/// connection is, an optional reveal-progress line, and the existing primary
/// action(s) (Request Reveal / Advance / awaiting state).
///
/// All data and behaviour are injected via `init` so the strip stays decoupled
/// from the view model while reusing the same derived properties the old card
/// consumed.
struct ConnectionStageStrip: View {
    let steps: [MatchStageStep]
    let currentIndex: Int
    let stageTitle: String
    let summary: String

    // Reveal / advance state — mirrors MatchDetailViewModel.
    var revealProgressText: String?
    var canRequestReveal: Bool
    var isAwaitingOtherReveal: Bool
    var revealButtonTitle: String
    var canAdvanceStage: Bool
    var isWorking: Bool
    var errorMessage: String?

    var onRequestReveal: () -> Void = {}
    var onAdvance: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .top) {
                EyebrowLabel(text: "Connection Stage")
                Spacer()
                EyebrowLabel(text: stageTitle, color: BoopColors.accentColor)
            }
            AccentRule()

            stepper

            Text(summary)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let revealProgressText {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "eye")
                        .font(.system(size: 11, weight: .thin))
                    Text(revealProgressText)
                        .font(BoopTypography.cineCaption)
                        .tracking(0.5)
                }
                .foregroundStyle(BoopColors.accentColor)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }

            if hasActions {
                HStack(spacing: BoopSpacing.sm) {
                    if canRequestReveal {
                        BoopButton(title: revealButtonTitle, variant: .secondary, isLoading: isWorking, fullWidth: false) {
                            onRequestReveal()
                        }
                    } else if isAwaitingOtherReveal {
                        EyebrowLabel(text: "Reveal Request Sent", color: BoopColors.accentColor)
                    }

                    if canAdvanceStage {
                        BoopButton(title: "Advance", variant: .primary, isLoading: isWorking, fullWidth: false) {
                            onAdvance()
                        }
                    }
                }
                .padding(.top, BoopSpacing.xxs)
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var hasActions: Bool {
        canRequestReveal || isAwaitingOtherReveal || canAdvanceStage
    }

    // MARK: - Horizontal stepper

    private var stepper: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepColumn(index: index, step: step)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func stepColumn(index: Int, step: MatchStageStep) -> some View {
        let reached = index <= currentIndex
        let isCurrent = index == currentIndex
        let isLast = index == steps.count - 1

        return VStack(spacing: BoopSpacing.xs) {
            // Dot + connecting lines on a single row so dots align horizontally.
            HStack(spacing: 0) {
                // Left connector (filled if the previous step is reached).
                Rectangle()
                    .fill(index <= currentIndex && index > 0 ? BoopColors.accentColor : BoopColors.hairline)
                    .frame(height: 1)
                    .opacity(index == 0 ? 0 : 1)

                ZStack {
                    if isCurrent {
                        Circle()
                            .stroke(BoopColors.accentColor, lineWidth: 1)
                            .frame(width: 16, height: 16)
                    }
                    Circle()
                        .fill(reached ? BoopColors.accentColor : BoopColors.hairline)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 16, height: 16)

                // Right connector (filled if the next step is reached).
                Rectangle()
                    .fill(index < currentIndex ? BoopColors.accentColor : BoopColors.hairline)
                    .frame(height: 1)
                    .opacity(isLast ? 0 : 1)
            }

            Text(step.title)
                .font(.system(size: 11, weight: isCurrent ? .semibold : .regular))
                .foregroundStyle(reached ? BoopColors.textPrimary : BoopColors.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
