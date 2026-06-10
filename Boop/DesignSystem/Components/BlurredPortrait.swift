import SwiftUI

enum PortraitShape {
    case circle
    case roundedRect(CGFloat)
}

/// The app's shared human-first visual: a remote portrait blurred to a given
/// radius (animated, so faces sharpen over time), with an optional dark scrim
/// and overlay content (name, presence, streak). Built on BoopRemoteImage.
struct BlurredPortrait<Overlay: View>: View {
    let urlString: String?
    var blurRadius: CGFloat = 0
    var shape: PortraitShape = .roundedRect(BoopRadius.lg)
    var scrim: Bool = true
    @ViewBuilder var overlay: () -> Overlay

    init(
        urlString: String?,
        blurRadius: CGFloat = 0,
        shape: PortraitShape = .roundedRect(BoopRadius.lg),
        scrim: Bool = true,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }
    ) {
        self.urlString = urlString
        self.blurRadius = blurRadius
        self.shape = shape
        self.scrim = scrim
        self.overlay = overlay
    }

    var body: some View {
        ZStack {
            BoopRemoteImage(urlString: urlString) {
                BoopColors.brandGradient.opacity(0.35)
            }
            .blur(radius: blurRadius)
            .animation(.easeInOut(duration: 0.6), value: blurRadius)

            if scrim {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            overlay()
        }
        .clipShape(clipShape)
        .contentShape(clipShape)
    }

    private var clipShape: AnyShape {
        switch shape {
        case .circle: return AnyShape(Circle())
        case .roundedRect(let r): return AnyShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }
}
