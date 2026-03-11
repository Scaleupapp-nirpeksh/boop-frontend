import SwiftUI

struct BoopRemoteImage<Placeholder: View>: View {
    let urlString: String?
    let contentMode: ContentMode
    let placeholder: Placeholder

    init(
        urlString: String?,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        AsyncImage(url: normalizedURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(BoopColors.textMuted)
                    }
            case .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
    }

    private var normalizedURL: URL? {
        guard let raw = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        if let url = URL(string: raw) {
            return url
        }
        if let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encoded)
        }
        return nil
    }
}
