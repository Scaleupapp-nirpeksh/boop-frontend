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
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("Could not load image")
                                .font(BoopTypography.body)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
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
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding()

                    Spacer()

                    HStack(spacing: BoopSpacing.xl) {
                        if loadedImage != nil {
                            Button {
                                saveToPhotos()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: showSaveSuccess ? "checkmark.circle.fill" : "square.and.arrow.down")
                                        .font(.system(size: 22))
                                    Text(showSaveSuccess ? "Saved" : "Save")
                                        .font(BoopTypography.caption)
                                }
                                .foregroundStyle(.white)
                            }

                            Button {
                                showShareSheet = true
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 22))
                                    Text("Share")
                                        .font(BoopTypography.caption)
                                }
                                .foregroundStyle(.white)
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
