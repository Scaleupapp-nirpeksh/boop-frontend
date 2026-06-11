import SwiftUI

// MARK: - Shareable archetype card

/// A compact, self-contained Cinematic Dark card rendered to an image for sharing.
/// Fixed 320×480 so the `ImageRenderer` output is deterministic across devices.
/// No emoji — typeset + the tonal coral radar only.
struct ShareCardView: View {
    let analysis: PersonalityAnalysis

    static let cardSize = CGSize(width: 320, height: 480)

    private var typeLabel: String? {
        guard let n = analysis.archetypeNumber else { return nil }
        return String(format: "TYPE %02d", n)
    }

    private var rarityLabel: String? {
        guard let r = analysis.rarityPercent else { return nil }
        return "\(r)% RARE"
    }

    private var archetypeName: String {
        analysis.archetypeName ?? analysis.personalityType
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            // Type / rarity row
            HStack(alignment: .firstTextBaseline) {
                if let typeLabel {
                    Text(typeLabel)
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.textMuted)
                }
                Spacer()
                if let rarityLabel {
                    Text(rarityLabel)
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
            }

            // Archetype name
            Text(archetypeName)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            AccentRule()

            // Essence
            if let essence = analysis.essence, !essence.isEmpty {
                Text(essence)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            // Small radar (no animation so the render captures the final shape)
            if !analysis.facets.isEmpty {
                PersonalityRadarChartView(facets: analysis.facets, size: 200, animated: false)
                    .frame(maxWidth: .infinity)
            }

            Spacer(minLength: 0)

            // Wordmark footer
            HStack {
                Text("UNMUTEE")
                    .font(BoopTypography.cineLabel)
                    .tracking(3)
                    .foregroundStyle(BoopColors.textMuted)
                Spacer()
            }
        }
        .padding(BoopSpacing.xl)
        .frame(width: Self.cardSize.width, height: Self.cardSize.height, alignment: .topLeading)
        .background(BoopColors.ground)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Render + share

enum PersonalityShareCardRenderer {
    /// Renders `ShareCardView` to a `UIImage` at native screen scale.
    @MainActor
    static func render(_ analysis: PersonalityAnalysis) -> UIImage? {
        let renderer = ImageRenderer(content: ShareCardView(analysis: analysis))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// Lets a rendered card image drive a `.sheet(item:)` presentation.
extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}

#Preview {
    let facets = [
        PersonalityFacet(key: "warmth", title: "Warmth", score: 82, description: "", emoji: ""),
        PersonalityFacet(key: "depth", title: "Depth", score: 74, description: "", emoji: ""),
        PersonalityFacet(key: "play", title: "Play", score: 61, description: "", emoji: ""),
        PersonalityFacet(key: "drive", title: "Drive", score: 69, description: "", emoji: ""),
        PersonalityFacet(key: "calm", title: "Calm", score: 55, description: "", emoji: "")
    ]
    let analysis = PersonalityAnalysis(
        id: "1",
        personalityType: "The Quiet Flame",
        summary: "",
        facets: facets,
        numerology: nil,
        questionsAnalyzed: 18,
        isPreliminary: false,
        createdAt: nil,
        archetypeCode: "QF",
        archetypeNumber: 7,
        archetypeName: "The Quiet Flame",
        essence: "Steady warmth that draws people in without ever raising its voice.",
        rarityPercent: 4
    )
    return ShareCardView(analysis: analysis)
        .padding()
        .boopBackground()
}
