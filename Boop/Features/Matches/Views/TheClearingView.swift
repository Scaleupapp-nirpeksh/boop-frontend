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
            Color.black.ignoresSafeArea()

            BoopRemoteImage(urlString: photoURL) {
                BoopColors.brandGradient
            }
            .blur(radius: blur, opaque: true)
            .ignoresSafeArea()

            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: BoopSpacing.md) {
                Spacer()
                if showText {
                    Text("THE FOG HAS LIFTED")
                        .font(.nunito(.bold, size: 12))
                        .foregroundStyle(Color(hex: "FFD6DD"))
                        .transition(.opacity)
                    Text(name)
                        .font(.nunito(.extraBold, size: 34))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                    HStack(spacing: BoopSpacing.xs) {
                        recapChip("🔥 \(days) days")
                        recapChip("🎮 \(games) games")
                        recapChip("🎙 \(voiceNotes) voice")
                    }
                    .transition(.opacity)
                    BoopButton(title: "Say something 💕") { onDone() }
                        .padding(.horizontal, BoopSpacing.xl)
                        .padding(.top, BoopSpacing.sm)
                        .transition(.opacity)
                }
                Spacer().frame(height: BoopSpacing.xl)
            }
            .padding(.bottom, BoopSpacing.xl)
        }
        .onAppear {
            Haptics.celebration()
            withAnimation(.easeInOut(duration: 1.4)) { blur = 0 }
            withAnimation(.easeIn(duration: 0.6).delay(1.0)) { showText = true }
        }
    }

    private func recapChip(_ text: String) -> some View {
        Text(text)
            .font(.nunito(.bold, size: 11))
            .foregroundStyle(.white)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
    }
}
