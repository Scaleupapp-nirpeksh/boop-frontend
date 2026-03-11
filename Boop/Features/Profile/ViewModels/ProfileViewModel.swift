import Foundation
import UIKit

@Observable
final class ProfileViewModel {
    var user: User?
    var isLoading = false
    var isSaving = false
    var isUploadingPhotos = false
    var isReorderingPhotos = false
    var deletingPhotoIndex: Int?
    var errorMessage: String?
    var successMessage: String?

    var firstName = ""
    var dateOfBirth = Calendar.current.date(byAdding: .year, value: -24, to: Date()) ?? Date()
    var gender: Gender?
    var interestedIn: InterestedIn?
    var city = ""
    var bio = ""
    var isRecordingVoice = false
    var isUploadingVoice = false

    var isProfileComplete: Bool {
        user?.profileStage == .ready || user?.profileStage == .questionsPending || user?.profileStage == .voicePending
    }

    init() {
        if let currentUser = AuthManager.shared.currentUser {
            user = currentUser
            firstName = currentUser.firstName ?? ""
            dateOfBirth = currentUser.dateOfBirth ?? dateOfBirth
            gender = currentUser.gender
            interestedIn = currentUser.interestedIn
            city = currentUser.location?.city ?? ""
            bio = currentUser.bio?.text ?? ""
        }
    }

    @MainActor
    func loadProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let wrapper: ProfileWrapper = try await APIClient.shared.request(.getProfile)
            apply(user: wrapper.user)
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load your profile."
        }
    }

    @MainActor
    func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var request = UpdateBasicInfoRequest(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            dateOfBirth: formatter.string(from: dateOfBirth),
            gender: gender?.rawValue,
            interestedIn: interestedIn?.rawValue,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            request.location = .init(city: city.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.updateBasicInfo(request))
            apply(user: wrapper.user)
            errorMessage = nil
            successMessage = "Profile updated"
        } catch let error as APIError {
            errorMessage = error.errorDescription
            successMessage = nil
        } catch {
            errorMessage = "Could not save your changes."
            successMessage = nil
        }
    }

    @MainActor
    func deletePhoto(at index: Int) async {
        deletingPhotoIndex = index
        defer { deletingPhotoIndex = nil }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(.deletePhoto(index: index))
            apply(user: wrapper.user)
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not delete this photo."
        }
    }

    @MainActor
    func uploadPhotos(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }

        isUploadingPhotos = true
        defer { isUploadingPhotos = false }

        let photoData = images.compactMap { image in
            image.jpegData(compressionQuality: 0.82)
        }

        do {
            let updatedUser = try await APIClient.shared.uploadPhotos(images: photoData)
            apply(user: updatedUser)
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not upload photos."
        }
    }

    @MainActor
    func movePhoto(from index: Int, by delta: Int) async {
        guard var items = user?.photos?.items else { return }
        let targetIndex = index + delta
        guard items.indices.contains(index), items.indices.contains(targetIndex) else { return }

        items.swapAt(index, targetIndex)
        for itemIndex in items.indices {
            items[itemIndex].order = itemIndex
        }
        await persistPhotoOrder(items, mainPhotoId: nil)
    }

    @MainActor
    func setMainPhoto(photoId: String) async {
        guard var items = user?.photos?.items else { return }
        guard let selectedIndex = items.firstIndex(where: { $0.id == photoId }) else { return }

        let selected = items.remove(at: selectedIndex)
        items.insert(selected, at: 0)
        for itemIndex in items.indices {
            items[itemIndex].order = itemIndex
        }
        await persistPhotoOrder(items, mainPhotoId: photoId)
    }

    @MainActor
    func reorderPhotos(ids: [String], mainPhotoId: String? = nil) async {
        guard var items = user?.photos?.items else { return }
        guard ids.count == items.count else { return }

        let map = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        items = ids.enumerated().compactMap { index, id in
            guard var item = map[id] else { return nil }
            item.order = index
            return item
        }

        guard items.count == ids.count else { return }
        await persistPhotoOrder(items, mainPhotoId: mainPhotoId)
    }

    @MainActor
    private func persistPhotoOrder(_ items: [UserPhotos.PhotoItem], mainPhotoId: String?) async {
        isReorderingPhotos = true
        defer { isReorderingPhotos = false }

        do {
            let wrapper: UserWrapper = try await APIClient.shared.request(
                .reorderPhotos(
                    ReorderPhotosRequest(
                        orderedPhotoIds: items.map(\.id),
                        mainPhotoId: mainPhotoId
                    )
                )
            )
            apply(user: wrapper.user)
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not update photo order."
        }
    }

    @MainActor
    func uploadVoiceIntro(data: Data, duration: Int) async {
        isUploadingVoice = true
        defer { isUploadingVoice = false }

        do {
            let updatedUser = try await APIClient.shared.uploadVoiceIntro(data: data, duration: duration)
            apply(user: updatedUser)
            errorMessage = nil
            successMessage = "Voice intro updated"
        } catch let error as APIError {
            errorMessage = error.errorDescription
            successMessage = nil
        } catch {
            errorMessage = "Could not upload voice intro."
            successMessage = nil
        }
    }

    @MainActor
    private func apply(user: User) {
        self.user = user
        firstName = user.firstName ?? ""
        dateOfBirth = user.dateOfBirth ?? dateOfBirth
        gender = user.gender
        interestedIn = user.interestedIn
        city = user.location?.city ?? ""
        bio = user.bio?.text ?? ""
        AuthManager.shared.updateUser(user)
    }
}
