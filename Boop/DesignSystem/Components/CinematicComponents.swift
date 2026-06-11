import SwiftUI

/// Uppercase, letter-spaced low-opacity label — the editorial signature.
struct EyebrowLabel: View {
    let text: String
    var color: Color = BoopColors.textMuted
    var body: some View {
        Text(text.uppercased())
            .font(BoopTypography.cineLabel)
            .tracking(2)
            .foregroundStyle(color)
    }
}

/// The 24×2 coral rule used as a section marker.
struct AccentRule: View {
    var width: CGFloat = 24
    var body: some View {
        Rectangle().fill(BoopColors.accentColor).frame(width: width, height: 2)
    }
}

/// A hairline-topped list row: leading title, optional trailing value, optional chevron.
struct HairlineRow<Trailing: View>: View {
    let title: String
    var titleColor: Color = BoopColors.textPrimary
    var showChevron: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, titleColor: Color = BoopColors.textPrimary, showChevron: Bool = false,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title; self.titleColor = titleColor; self.showChevron = showChevron; self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                Text(title).font(BoopTypography.cineBody).foregroundStyle(titleColor)
                Spacer()
                trailing()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}

/// A 1px progress track with a coral filled portion (0...1).
struct HairlineProgress: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(BoopColors.hairline)
                Rectangle().fill(BoopColors.accentColor)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 1)
    }
}

/// Formats a playback duration in seconds to "m:ss".
func formatPlaybackTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let s = Int(seconds.rounded())
    return String(format: "%d:%02d", s / 60, s % 60)
}

/// Refined voice control: a thin-stroked play circle + a 1px line + duration.
struct VoiceLine: View {
    var duration: String
    var isPlaying: Bool = false
    var progress: Double = 0
    var elapsedText: String? = nil
    var onTap: () -> Void = {}
    var body: some View {
        HStack(spacing: BoopSpacing.sm) {
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(BoopColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(BoopColors.textPrimary.opacity(0.5), lineWidth: 1))
            }
            HairlineProgress(progress: progress).frame(maxWidth: .infinity)
            Text(elapsedText ?? duration).font(BoopTypography.cineCaption).foregroundStyle(BoopColors.textMuted)
        }
    }
}

/// Full-bleed blurred portrait fading into the ground, with an overlaid bottom-left content block.
struct CinematicHeader<Overlay: View>: View {
    let urlString: String?
    var blurRadius: CGFloat = 0
    var height: CGFloat = 280
    @ViewBuilder var overlay: () -> Overlay

    init(urlString: String?, blurRadius: CGFloat = 0, height: CGFloat = 280,
         @ViewBuilder overlay: @escaping () -> Overlay) {
        self.urlString = urlString; self.blurRadius = blurRadius; self.height = height; self.overlay = overlay
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BlurredPortrait(urlString: urlString, blurRadius: blurRadius, shape: .roundedRect(0), scrim: false)
                .frame(height: height)
                .clipped()
            LinearGradient(colors: [.clear, BoopColors.ground.opacity(0.6), BoopColors.ground],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: height)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) { overlay() }
                .padding(BoopSpacing.lg)
        }
        .frame(height: height)
    }
}
