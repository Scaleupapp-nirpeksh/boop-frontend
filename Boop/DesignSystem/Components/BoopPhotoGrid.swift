import SwiftUI
import PhotosUI

struct PhotoSlot: Identifiable {
    let id = UUID()
    var image: UIImage?
    var isUploading: Bool = false
    var isUploaded: Bool = false
    var remoteURL: String?
}

struct BoopPhotoGrid: View {
    @Binding var slots: [PhotoSlot]
    let maxPhotos: Int = 6
    let minPhotos: Int = 3
    var onAddPhoto: ((UIImage) -> Void)?
    var onDeletePhoto: ((Int) -> Void)?

    @State private var selectedItems: [PhotosPickerItem] = []

    private let columns = [
        GridItem(.flexible(), spacing: BoopSpacing.sm),
        GridItem(.flexible(), spacing: BoopSpacing.sm),
        GridItem(.flexible(), spacing: BoopSpacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("\(slots.filter { $0.image != nil }.count)/\(maxPhotos) photos (min \(minPhotos))")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)

            LazyVGrid(columns: columns, spacing: BoopSpacing.sm) {
                ForEach(0..<maxPhotos, id: \.self) { index in
                    if index < slots.count, slots[index].image != nil {
                        filledSlot(at: index)
                    } else if slots.filter({ $0.image != nil }).count < maxPhotos {
                        emptySlot(at: index)
                    }
                }
            }
        }
    }

    private func filledSlot(at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: slots[index].image!)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))

            if slots[index].isUploading {
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .fill(Color.black.opacity(0.4))
                ProgressView()
                    .tint(.white)
            }

            // Delete button
            Button {
                onDeletePhoto?(index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }
            .padding(BoopSpacing.xxs)

            // "Main" badge on first photo
            if index == 0 {
                VStack {
                    Spacer()
                    Text("Main")
                        .font(BoopTypography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, BoopSpacing.xxxs)
                        .background(BoopColors.primary.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(BoopSpacing.xxs)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(height: 140)
    }

    private func emptySlot(at index: Int) -> some View {
        PhotosPicker(
            selection: Binding(
                get: { selectedItems },
                set: { newItems in
                    selectedItems = newItems
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                onAddPhoto?(image)
                            }
                        }
                        selectedItems = []
                    }
                }
            ),
            maxSelectionCount: maxPhotos - slots.filter({ $0.image != nil }).count,
            matching: .images
        ) {
            RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                .strokeBorder(BoopColors.border, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .frame(height: 140)
                .overlay(
                    VStack(spacing: BoopSpacing.xxs) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(BoopColors.textMuted)
                        Text("Add")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                )
        }
    }
}
