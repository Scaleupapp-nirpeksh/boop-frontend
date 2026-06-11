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
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            Text("\(slots.filter { $0.image != nil }.count) / \(maxPhotos) PHOTOS · MIN \(minPhotos)")
                .font(BoopTypography.cineLabel)
                .tracking(2)
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
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous))

            if slots[index].isUploading {
                RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                    .fill(BoopColors.ground.opacity(0.55))
                ProgressView()
                    .tint(BoopColors.accentColor)
            }

            // 1px hairline frame
            RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)

            // Delete button
            Button {
                onDeletePhoto?(index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(BoopColors.ground.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.chip, style: .continuous))
            }
            .padding(BoopSpacing.xs)

            // "Main" marker on first photo
            if index == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Text("MAIN")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, BoopSpacing.xs)
                            .padding(.vertical, BoopSpacing.xxs)
                            .background(BoopColors.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
                        Spacer()
                    }
                    .padding(BoopSpacing.xs)
                }
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
            RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                .stroke(BoopColors.hairline, lineWidth: 1)
                .frame(height: 140)
                .overlay(
                    VStack(spacing: BoopSpacing.xs) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .thin))
                            .foregroundStyle(BoopColors.textMuted)
                        Text("ADD")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                )
        }
    }
}
