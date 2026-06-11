import SwiftUI

/// The reveal payoff: the fog dissolves and the other person's portrait
/// resolves to full clarity, with a recap of the journey that earned it.
struct TheClearingView: View {
    let name: String
    let photoURL: String?
    let days: Int
    let games: Int
    let voiceNotes: Int
    let onDone: () -> Void

    @State private var blur: CGFloat = 28
    @State private var showText = false

    var body: some View {
        ZStack {
            BoopColors.ground.ignoresSafeArea()

            BoopRemoteImage(urlString: photoURL) {
                BoopColors.accentColor.opacity(0.35)
            }
            .blur(radius: blur, opaque: true)
            .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, BoopColors.ground.opacity(0.6), BoopColors.ground],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                Spacer()
                if showText {
                    EyebrowLabel(text: "The Fog Has Lifted", color: BoopColors.accentColor)
                        .transition(.opacity)
                    AccentRule()
                        .transition(.opacity)
                    Text(name)
                        .font(BoopTypography.cineDisplayXL)
                        .foregroundStyle(BoopColors.textPrimary)
                        .transition(.opacity)
                    EyebrowLabel(text: recapLine)
                        .transition(.opacity)
                    BoopButton(title: "Say something") { onDone() }
                        .padding(.top, BoopSpacing.md)
                        .transition(.opacity)
                }
                Spacer().frame(height: BoopSpacing.xl)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.bottom, BoopSpacing.xl)
        }
        .onAppear {
            Haptics.celebration()
            withAnimation(.easeInOut(duration: 1.4)) { blur = 0 }
            withAnimation(.easeIn(duration: 0.6).delay(1.0)) { showText = true }
        }
    }

    private var recapLine: String {
        var parts: [String] = []
        if days > 0 { parts.append("\(days) Days") }
        if games > 0 { parts.append("\(games) Games") }
        if voiceNotes > 0 { parts.append("\(voiceNotes) Voice") }
        guard !parts.isEmpty else { return "A connection earned" }
        return parts.joined(separator: "  ·  ")
    }
}
