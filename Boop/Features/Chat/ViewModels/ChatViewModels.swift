import Foundation
import UIKit

enum ChatMessageDeliveryState {
    case sending
    case sent
    case seen
    case failed
}

@Observable
final class ChatInboxViewModel {
    var conversations: [ConversationInfo] = []
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadInbox() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ConversationsResponse = try await APIClient.shared.request(.getConversations())
            conversations = response.conversations
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load conversations."
        }
    }

    func conversation(for matchId: String) -> ConversationInfo? {
        conversations.first(where: { $0.matchId == matchId })
    }
}

@Observable
final class ChatConversationViewModel {
    let conversation: ConversationInfo

    var messages: [ChatMessage] = []
    var draft = ""
    var isLoading = false
    var isSending = false
    var errorMessage: String?
    var replyingTo: ChatMessage?
    var hasMoreMessages = true
    var isLoadingMore = false
    private(set) var pendingMessageIDs: Set<String> = []
    private(set) var failedMessageIDs: Set<String> = []

    // Conversation starters
    var starters: [ConversationStarter] = []
    var isLoadingStarters = false
    var hasLoadedStarters = false

    init(conversation: ConversationInfo) {
        self.conversation = conversation
    }

    @MainActor
    func loadConversationStarters() async {
        guard !hasLoadedStarters, let matchId = conversation.matchId else { return }
        hasLoadedStarters = true
        isLoadingStarters = true
        do {
            let response: ConversationStartersResponse = try await APIClient.shared.request(
                .getConversationStarters(matchId: matchId)
            )
            starters = response.starters
        } catch {
            // Non-critical
        }
        isLoadingStarters = false
    }

    @MainActor
    func loadMessages() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ConversationMessagesResponse = try await APIClient.shared.request(
                .getMessages(conversationId: conversation.conversationId)
            )
            messages = response.messages.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            hasMoreMessages = response.hasMore
            errorMessage = nil
            try? await APIClient.shared.requestVoid(.markConversationRead(conversationId: conversation.conversationId))

            // Load starters if few messages
            if messages.count <= 3 {
                Task { await loadConversationStarters() }
            }
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load messages."
        }
    }

    @MainActor
    func loadOlderMessages() async {
        guard !isLoadingMore, hasMoreMessages else { return }
        guard let oldest = messages.first, let createdAt = oldest.createdAt else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let beforeString = formatter.string(from: createdAt)

        do {
            let response: ConversationMessagesResponse = try await APIClient.shared.request(
                .getMessages(conversationId: conversation.conversationId, before: beforeString)
            )
            let older = response.messages.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            messages.insert(contentsOf: older, at: 0)
            hasMoreMessages = response.hasMore
        } catch {
            // Silently fail pagination — user can scroll again
        }
    }

    @MainActor
    func sendDraft() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        let tempMessage = makePendingMessage(
            type: "text",
            content: ChatMessageContent(text: trimmed, mediaUrl: nil, mediaDuration: nil, gameType: nil, gameSessionId: nil)
        )
        insertPendingMessage(tempMessage)

        let replyId = replyingTo?.id

        do {
            let message: ChatMessage = try await APIClient.shared.request(
                .sendMessage(
                    conversationId: conversation.conversationId,
                    request: SendMessageRequest(text: trimmed, replyTo: replyId)
                )
            )
            resolvePendingMessage(tempId: tempMessage.id, with: message)
            draft = ""
            replyingTo = nil
            errorMessage = nil
        } catch let error as APIError {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = error.errorDescription
        } catch {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = "Could not send message."
        }
    }

    @MainActor
    func sendImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return }

        isSending = true
        defer { isSending = false }

        let tempMessage = makePendingMessage(
            type: "image",
            content: ChatMessageContent(text: nil, mediaUrl: nil, mediaDuration: nil, gameType: nil, gameSessionId: nil)
        )
        insertPendingMessage(tempMessage)

        do {
            let upload = try await APIClient.shared.uploadConversationMedia(
                data: data,
                conversationId: conversation.conversationId,
                mediaType: "image",
                fileName: "chat_image.jpg",
                mimeType: "image/jpeg"
            )
            let message: ChatMessage = try await APIClient.shared.request(
                .sendMessage(
                    conversationId: conversation.conversationId,
                    request: SendMessageRequest(type: "image", mediaUrl: upload.mediaUrl)
                )
            )
            resolvePendingMessage(tempId: tempMessage.id, with: message)
            errorMessage = nil
        } catch let error as APIError {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = error.errorDescription
        } catch {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = "Could not send image."
        }
    }

    @MainActor
    func sendVoice(data: Data, duration: Double) async {
        isSending = true
        defer { isSending = false }

        let tempMessage = makePendingMessage(
            type: "voice",
            content: ChatMessageContent(text: nil, mediaUrl: nil, mediaDuration: duration, gameType: nil, gameSessionId: nil)
        )
        insertPendingMessage(tempMessage)

        do {
            let upload = try await APIClient.shared.uploadConversationMedia(
                data: data,
                conversationId: conversation.conversationId,
                mediaType: "voice",
                fileName: "voice_note.m4a",
                mimeType: "audio/mp4",
                duration: duration
            )
            let message: ChatMessage = try await APIClient.shared.request(
                .sendMessage(
                    conversationId: conversation.conversationId,
                    request: SendMessageRequest(type: "voice", mediaUrl: upload.mediaUrl, mediaDuration: upload.mediaDuration)
                )
            )
            resolvePendingMessage(tempId: tempMessage.id, with: message)
            errorMessage = nil
        } catch let error as APIError {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = error.errorDescription
        } catch {
            markPendingMessageFailed(tempId: tempMessage.id)
            errorMessage = "Could not send voice note."
        }
    }

    @MainActor
    func toggleReaction(for message: ChatMessage, emoji: String) async {
        let currentUserId = AuthManager.shared.currentUser?.id
        let existing = message.reactions.first(where: { $0.userId == currentUserId && $0.emoji == emoji })

        do {
            let response: MessageReactionResponse
            if existing != nil {
                response = try await APIClient.shared.request(.removeReaction(messageId: message.id))
            } else {
                response = try await APIClient.shared.request(.addReaction(messageId: message.id, emoji: emoji))
            }

            guard let index = messages.firstIndex(where: { $0.id == message.id }) else { return }
            let updated = ChatMessage(
                id: messages[index].id,
                conversationId: messages[index].conversationId,
                senderId: messages[index].senderId,
                type: messages[index].type,
                content: messages[index].content,
                reactions: response.reactions,
                replyTo: messages[index].replyTo,
                readAt: messages[index].readAt,
                createdAt: messages[index].createdAt
            )
            messages[index] = updated
        } catch {
            errorMessage = "Could not update reaction."
        }
    }

    @MainActor
    func upsertIncomingMessage(_ message: ChatMessage) {
        guard message.conversationId == conversation.conversationId else { return }
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        } else {
            messages.append(message)
            messages.sort { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
        }
    }

    @MainActor
    func applyReactionEvent(_ event: MessageReactionEvent) {
        guard let index = messages.firstIndex(where: { $0.id == event.messageId }) else { return }
        messages[index] = ChatMessage(
            id: messages[index].id,
            conversationId: messages[index].conversationId,
            senderId: messages[index].senderId,
            type: messages[index].type,
            content: messages[index].content,
            reactions: event.reactions,
            replyTo: messages[index].replyTo,
            readAt: messages[index].readAt,
            createdAt: messages[index].createdAt
        )
    }

    @MainActor
    func applyReadEvent(_ event: MessageReadEvent) {
        guard event.conversationId == conversation.conversationId else { return }
        let currentUserId = AuthManager.shared.currentUser?.id
        for index in messages.indices where messages[index].senderId.id == currentUserId {
            messages[index] = ChatMessage(
                id: messages[index].id,
                conversationId: messages[index].conversationId,
                senderId: messages[index].senderId,
                type: messages[index].type,
                content: messages[index].content,
                reactions: messages[index].reactions,
                replyTo: messages[index].replyTo,
                readAt: event.readAt ?? messages[index].readAt,
                createdAt: messages[index].createdAt
            )
        }
    }

    @MainActor
    func retryFailedMessage(_ message: ChatMessage) async {
        guard failedMessageIDs.contains(message.id), message.type == "text" else { return }

        failedMessageIDs.remove(message.id)
        pendingMessageIDs.insert(message.id)

        do {
            let sentMessage: ChatMessage = try await APIClient.shared.request(
                .sendMessage(
                    conversationId: conversation.conversationId,
                    request: SendMessageRequest(text: message.content.text ?? "")
                )
            )
            resolvePendingMessage(tempId: message.id, with: sentMessage)
            errorMessage = nil
        } catch let error as APIError {
            markPendingMessageFailed(tempId: message.id)
            errorMessage = error.errorDescription
        } catch {
            markPendingMessageFailed(tempId: message.id)
            errorMessage = "Could not resend this message."
        }
    }

    @MainActor
    func deliveryState(for message: ChatMessage) -> ChatMessageDeliveryState {
        if pendingMessageIDs.contains(message.id) {
            return .sending
        }
        if failedMessageIDs.contains(message.id) {
            return .failed
        }
        if message.readAt != nil {
            return .seen
        }
        return .sent
    }

    @MainActor
    private func makePendingMessage(type: String, content: ChatMessageContent) -> ChatMessage {
        let tempId = "temp-\(UUID().uuidString)"
        return ChatMessage(
            id: tempId,
            conversationId: conversation.conversationId,
            senderId: ChatSender(
                id: AuthManager.shared.currentUser?.id ?? "current-user",
                firstName: AuthManager.shared.currentUser?.firstName
            ),
            type: type,
            content: content,
            reactions: [],
            replyTo: nil,
            readAt: nil,
            createdAt: Date()
        )
    }

    @MainActor
    private func insertPendingMessage(_ message: ChatMessage) {
        pendingMessageIDs.insert(message.id)
        failedMessageIDs.remove(message.id)
        messages.append(message)
        messages.sort { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    @MainActor
    private func resolvePendingMessage(tempId: String, with message: ChatMessage) {
        pendingMessageIDs.remove(tempId)
        failedMessageIDs.remove(tempId)
        messages.removeAll(where: { $0.id == tempId })
        upsertIncomingMessage(message)
    }

    @MainActor
    private func markPendingMessageFailed(tempId: String) {
        pendingMessageIDs.remove(tempId)
        failedMessageIDs.insert(tempId)
    }
}
