import Foundation
import UIKit

@Observable
final class ChatMediaGalleryViewModel {
    let conversationId: String

    var photos: [ChatMessage] = []
    var voiceNotes: [ChatMessage] = []
    var isLoading = false
    var errorMessage: String?
    var photosPage = 1
    var voicePage = 1
    var hasMorePhotos = true
    var hasMoreVoice = true

    init(conversationId: String) {
        self.conversationId = conversationId
    }

    @MainActor
    func loadPhotos() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ConversationMediaResponse = try await APIClient.shared.request(
                .getConversationMedia(conversationId: conversationId, type: "image", page: 1)
            )
            photos = response.media
            hasMorePhotos = response.page < response.totalPages
            photosPage = 1
            errorMessage = nil
        } catch {
            errorMessage = "Could not load photos."
        }
    }

    @MainActor
    func loadVoiceNotes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ConversationMediaResponse = try await APIClient.shared.request(
                .getConversationMedia(conversationId: conversationId, type: "voice", page: 1)
            )
            voiceNotes = response.media
            hasMoreVoice = response.page < response.totalPages
            voicePage = 1
            errorMessage = nil
        } catch {
            errorMessage = "Could not load voice notes."
        }
    }

    @MainActor
    func loadMorePhotos() async {
        guard hasMorePhotos else { return }
        let nextPage = photosPage + 1

        do {
            let response: ConversationMediaResponse = try await APIClient.shared.request(
                .getConversationMedia(conversationId: conversationId, type: "image", page: nextPage)
            )
            photos.append(contentsOf: response.media)
            photosPage = nextPage
            hasMorePhotos = response.page < response.totalPages
        } catch {
            // Silent pagination failure
        }
    }

    @MainActor
    func loadMoreVoice() async {
        guard hasMoreVoice else { return }
        let nextPage = voicePage + 1

        do {
            let response: ConversationMediaResponse = try await APIClient.shared.request(
                .getConversationMedia(conversationId: conversationId, type: "voice", page: nextPage)
            )
            voiceNotes.append(contentsOf: response.media)
            voicePage = nextPage
            hasMoreVoice = response.page < response.totalPages
        } catch {
            // Silent pagination failure
        }
    }

    // MARK: - Sending from Shared Media

    @MainActor
    func sendImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let upload = try await APIClient.shared.uploadConversationMedia(
                data: data, conversationId: conversationId, mediaType: "image",
                fileName: "chat_image.jpg", mimeType: "image/jpeg"
            )
            let _: ChatMessage = try await APIClient.shared.request(
                .sendMessage(conversationId: conversationId,
                             request: SendMessageRequest(type: "image", mediaUrl: upload.mediaUrl))
            )
            await loadPhotos()
            Analytics.capture("message_sent", ["type": "image", "source": "shared_media"])
        } catch {
            errorMessage = "Could not send photo."
        }
    }

    @MainActor
    func sendVoice(data: Data, duration: Double) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let upload = try await APIClient.shared.uploadConversationMedia(
                data: data, conversationId: conversationId, mediaType: "voice",
                fileName: "voice_note.m4a", mimeType: "audio/mp4", duration: duration
            )
            let _: ChatMessage = try await APIClient.shared.request(
                .sendMessage(conversationId: conversationId,
                             request: SendMessageRequest(type: "voice", mediaUrl: upload.mediaUrl, mediaDuration: upload.mediaDuration))
            )
            await loadVoiceNotes()
            Analytics.capture("message_sent", ["type": "voice", "source": "shared_media"])
        } catch {
            errorMessage = "Could not send voice note."
        }
    }
}
