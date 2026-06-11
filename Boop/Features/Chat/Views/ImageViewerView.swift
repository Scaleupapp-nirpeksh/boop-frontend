import SwiftUI

struct ImageViewerView: View {
    let imageURL: String

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showControls = true
    @State private var loadedImage: UIImage?
    @State private var showShareSheet = false
    @State private var showSaveSuccess = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(magnificationGesture)
                            .gesture(dragGesture)
                            .gesture(doubleTapGesture)
                            .gesture(dismissGesture)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showControls.toggle()
                                }
                            }
                            .onAppear {
                                // Extract UIImage for save/share
                                Task {
                                    if let data = try? Data(contentsOf: url) {
                                        loadedImage = UIImage(data: data)
                                    }
                                }
                            }
                    case .failure:
                        VStack(spacing: BoopSpacing.md) {
                            Image(systemName: "photo.trianglebadge.exclamationmark")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Could not load image")
                                .font(BoopTypography.cineBody)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.7))
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Controls overlay
            if showControls {
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .thin))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding()

                    Spacer()

                    HStack(spacing: BoopSpacing.xxl) {
                        if loadedImage != nil {
                            Button {
                                saveToPhotos()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: showSaveSuccess ? "checkmark" : "square.and.arrow.down")
                                        .font(.system(size: 18, weight: .thin))
                                    Text(showSaveSuccess ? "SAVED" : "SAVE")
                                        .font(BoopTypography.cineLabel)
                                        .tracking(1.5)
                                }
                                .foregroundStyle(.white.opacity(0.85))
                            }

                            Button {
                                showShareSheet = true
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 18, weight: .thin))
                                    Text("SHARE")
                                        .font(BoopTypography.cineLabel)
                                        .tracking(1.5)
                                }
                                .foregroundStyle(.white.opacity(0.85))
                            }
                        }
                    }
                    .padding(.bottom, BoopSpacing.xl)
                }
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = loadedImage {
                ShareSheet(items: [image])
            }
        }
        .statusBarHidden(true)
    }

    // MARK: - Gestures

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = max(1.0, min(newScale, 5.0))
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1.0 {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                    lastScale = 1.0
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1.0 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation(.spring(response: 0.3)) {
                    if scale > 1.0 {
                        scale = 1.0
                        offset = .zero
                        lastOffset = .zero
                        lastScale = 1.0
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 60)
            .onEnded { value in
                if scale <= 1.0 && abs(value.translation.height) > 100 {
                    dismiss()
                }
            }
    }

    // MARK: - Actions

    private func saveToPhotos() {
        guard let image = loadedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation {
            showSaveSuccess = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showSaveSuccess = false
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
