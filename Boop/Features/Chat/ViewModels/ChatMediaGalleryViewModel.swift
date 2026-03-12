import Foundation

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
}
