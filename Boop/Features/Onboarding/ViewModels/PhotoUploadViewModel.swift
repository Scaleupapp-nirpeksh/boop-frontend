import SwiftUI
import UIKit

@Observable
class PhotoUploadViewModel {
    var slots: [PhotoSlot] = []
    var isUploading = false
    var errorMessage: String?

    var uploadedCount: Int {
        slots.filter { $0.image != nil }.count
    }

    var canSubmit: Bool {
        uploadedCount >= 3 && !isUploading
    }

    func addPhoto(_ image: UIImage) {
        guard uploadedCount < 6 else { return }
        let compressed = compressImage(image)
        var slot = PhotoSlot()
        slot.image = compressed
        slots.append(slot)
    }

    func removePhoto(at index: Int) {
        guard index < slots.count else { return }
        slots.remove(at: index)
    }

    @MainActor
    func uploadAllPhotos() async -> User? {
        let images = slots.compactMap { slot -> Data? in
            guard let image = slot.image else { return nil }
            return image.jpegData(compressionQuality: 0.8)
        }

        guard images.count >= 3 else {
            errorMessage = "Please add at least 3 photos"
            return nil
        }

        isUploading = true
        errorMessage = nil

        do {
            let user = try await APIClient.shared.uploadPhotos(images: images)
            isUploading = false
            return user
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Upload failed. Please try again."
        }

        isUploading = false
        return nil
    }

    private func compressImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
