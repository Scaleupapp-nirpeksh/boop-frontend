import PhotosUI
import SwiftUI

struct ChatInboxView: View {
    @State private var viewModel = ChatInboxViewModel()
    @State private var searchText = ""
    @State private var filter = InboxFilter.all

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                ScrollView {
                    VStack(spacing: BoopSpacing.sm) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonInboxRow()
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.vertical, BoopSpacing.lg)
                }
                .boopBackground()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopSectionIntro(
                            title: "Inbox",
                            subtitle: "Your active conversations.",
                            eyebrow: "Chat"
                        )

                        RealtimeStatusBanner()

                        Picker("Inbox Filter", selection: $filter) {
                            ForEach(InboxFilter.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        if filteredConversations.isEmpty {
                            BoopCard(padding: BoopSpacing.xl, radius: BoopRadius.xxl) {
                                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                                    Text(searchText.isEmpty ? "No conversations yet" : "No results")
                                        .font(BoopTypography.headline)
                                        .foregroundStyle(BoopColors.textPrimary)
                                    Text(searchText.isEmpty ? "New chats will appear after mutual matches." : "Try a different name or filter.")
                                        .font(BoopTypography.body)
                                        .foregroundStyle(BoopColors.textSecondary)
                                }
                            }
                        } else {
                            LazyVStack(spacing: BoopSpacing.sm) {
                                ForEach(filteredConversations) { conversation in
                                    NavigationLink {
                                        ChatConversationView(conversation: conversation)
                                    } label: {
                                        ChatInboxRow(conversation: conversation)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.vertical, BoopSpacing.lg)
                }
                .boopBackground()
                .refreshable {
                    await viewModel.loadInbox()
                }
            }
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search conversations")
        .task {
            await viewModel.loadInbox()
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageNew)) { _ in
            Task { await viewModel.loadInbox() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeGameInvite)) { _ in
            Task { await viewModel.loadInbox() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMatchNew)) { _ in
            Task { await viewModel.loadInbox() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeStatusChanged)) { _ in
            if RealtimeService.shared.connectionState == .connected {
                Task { await viewModel.loadInbox() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("boop.blockedUser"))) { _ in
            Task { await viewModel.loadInbox() }
        }
    }

    private var filteredConversations: [ConversationInfo] {
        viewModel.conversations.filter { conversation in
            let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = trimmedSearch.isEmpty
                || (conversation.otherUser.firstName ?? "").localizedCaseInsensitiveContains(trimmedSearch)

            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .unread:
                matchesFilter = conversation.unreadCount > 0
            case .active:
                matchesFilter = (conversation.matchStage ?? "mutual") != "archived"
            }

            return matchesSearch && matchesFilter
        }
    }
}

private enum InboxFilter: CaseIterable {
    case all
    case unread
    case active

    var title: String {
        switch self {
        case .all: return "All"
        case .unread: return "Unread"
        case .active: return "Active"
        }
    }
}

private struct ChatInboxRow: View {
    let conversation: ConversationInfo

    var body: some View {
        HStack(spacing: BoopSpacing.md) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUser.firstName ?? "Conversation")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    if let sentAt = conversation.lastMessage?.sentAt {
                        Text(sentAt.chatTimestamp)
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }

                Text(conversation.lastMessage?.text ?? "Start the conversation")
                    .font(BoopTypography.callout)
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: BoopSpacing.xs) {
                    stageChip

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount) new")
                            .font(BoopTypography.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, BoopSpacing.xs)
                            .padding(.vertical, BoopSpacing.xxxs)
                            .background(BoopColors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.xl)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: conversation.otherUser.photo ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(BoopColors.secondary.opacity(0.12))
                    .overlay(
                        Text(String((conversation.otherUser.firstName ?? "?").prefix(1)))
                            .font(BoopTypography.title3)
                            .foregroundStyle(BoopColors.secondary)
                    )
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())

            if conversation.otherUser.isOnline == true {
                Circle()
                    .fill(BoopColors.success)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
        }
    }

    private var stageChip: some View {
        Text((conversation.matchStage ?? "mutual").replacingOccurrences(of: "_", with: " ").capitalized)
            .font(BoopTypography.caption)
            .foregroundStyle(BoopColors.secondary)
            .padding(.horizontal, BoopSpacing.xs)
            .padding(.vertical, BoopSpacing.xxxs)
            .background(BoopColors.secondary.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Chat Conversation View

struct ChatConversationView: View {
    let conversation: ConversationInfo

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel: ChatConversationViewModel
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var remoteTypingUserId: String?
    @State private var hasSentTyping = false
    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var isVoiceSheetPresented = false
    @State private var voiceRecorderState = VoiceRecorderState()
    @State private var searchText = ""
    @State private var expandedImageURL: String?
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
    @State private var showBlockError = false
    @State private var showComfortDetail = false
    @State private var showGames = false

    init(conversation: ConversationInfo) {
        self.conversation = conversation
        _viewModel = State(initialValue: ChatConversationViewModel(conversation: conversation))
    }

    private var fogBlurRadius: CGFloat? {
        let stage = conversation.matchStage
        if stage == "revealed" || stage == "dating" { return nil }
        return FogBlur.radius(forComfort: viewModel.comfortScore, stage: stage)
    }

    private var scrimOpacity: Double { colorScheme == .dark ? 0.82 : 0.90 }

    @ViewBuilder
    private var fogBackground: some View {
        if let photo = conversation.otherUser.photo, let radius = fogBlurRadius {
            BoopRemoteImage(urlString: photo) { Color.clear }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .blur(radius: radius, opaque: true)
                .animation(.easeInOut(duration: 0.6), value: radius)
                .overlay(BoopColors.chatBackground.opacity(scrimOpacity))
                .ignoresSafeArea()
        } else {
            BoopColors.chatBackground.ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var fogNudgeChips: some View {
        if let comfort = viewModel.comfortScore,
           comfort < 70,
           conversation.matchId != nil,
           conversation.matchStage != "revealed",
           conversation.matchStage != "dating" {
            HStack(spacing: BoopSpacing.xs) {
                nudgeChip(icon: "mic.fill", label: "Voice note") {
                    isVoiceSheetPresented = true
                }
                nudgeChip(icon: "gamecontroller.fill", label: "Play a game") {
                    showGames = true
                }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.top, BoopSpacing.xs)
        }
    }

    private func nudgeChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(label).font(.nunito(.bold, size: 11))
            }
            .foregroundStyle(BoopColors.brandViolet)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(BoopColors.backgroundMint)
            .clipShape(Capsule())
        }
    }

    var body: some View {
        ZStack {
            fogBackground

            conversationContent
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: BoopSpacing.sm) {
                    ZStack(alignment: .bottomTrailing) {
                        AsyncImage(url: URL(string: conversation.otherUser.photo ?? "")) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(BoopColors.secondary.opacity(0.12))
                                .overlay(
                                    Text(String((conversation.otherUser.firstName ?? "?").prefix(1)))
                                        .font(BoopTypography.caption)
                                        .foregroundStyle(BoopColors.secondary)
                                )
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())

                        if conversation.otherUser.isOnline == true {
                            Circle()
                                .fill(BoopColors.success)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(conversation.otherUser.firstName ?? "Chat")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text(conversation.otherUser.isOnline == true ? "Online" : "Offline")
                            .font(BoopTypography.caption)
                            .foregroundStyle(conversation.otherUser.isOnline == true ? BoopColors.success : BoopColors.textMuted)

                        if let comfort = viewModel.comfortScore,
                           conversation.matchId != nil,
                           conversation.matchStage != "revealed",
                           conversation.matchStage != "dating" {
                            Button { showComfortDetail = true } label: {
                                Text("the fog is lifting · \(comfort)/70")
                                    .font(.nunito(.semiBold, size: 11))
                                    .foregroundStyle(BoopColors.brand)
                            }
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ChatMediaGalleryView(
                        conversationId: conversation.conversationId,
                        otherUserName: conversation.otherUser.firstName ?? "Chat"
                    )
                } label: {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("Block", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Conversation options")
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportUserSheet(
                userId: conversation.otherUser.userId,
                userName: conversation.otherUser.firstName ?? "this user",
                contentType: "message"
            )
        }
        .sheet(isPresented: $showComfortDetail) {
            if let matchId = conversation.matchId {
                NavigationStack { MatchDetailView(matchId: matchId) }
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showGames) {
            if let matchId = conversation.matchId {
                NavigationStack { MatchGamesView(matchId: matchId) }
                    .presentationDragIndicator(.visible)
            }
        }
        .confirmationDialog(
            "Block \(conversation.otherUser.firstName ?? "this user")?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                Task { await blockOtherUser() }
            }
        } message: {
            Text("They won't be able to message you, this match will be removed, and they won't appear in Discover. They won't be notified.")
        }
        .alert("Couldn't block this user", isPresented: $showBlockError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please check your connection and try again.")
        }
        .searchable(text: $searchText, prompt: "Search messages")
        .task {
            voiceRecorderState.minDuration = 1
            voiceRecorderState.maxDuration = 120
            Task { await viewModel.loadComfort() }
            await viewModel.loadMessages()
        }
        .onDisappear {
            RealtimeService.shared.emitTypingStop(conversationId: conversation.conversationId)
        }
        .onChange(of: selectedMediaItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.sendImage(image)
                }
                selectedMediaItem = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageNew)) { notification in
            guard let payload = notification.userInfo?["payload"] as? ChatMessage else { return }
            viewModel.upsertIncomingMessage(payload)
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageReaction)) { notification in
            guard let payload = notification.userInfo?["payload"] as? MessageReactionEvent else { return }
            viewModel.applyReactionEvent(payload)
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeMessageRead)) { notification in
            guard let payload = notification.userInfo?["payload"] as? MessageReadEvent else { return }
            viewModel.applyReadEvent(payload)
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeTypingStart)) { notification in
            guard let payload = notification.userInfo?["payload"] as? TypingEvent,
                  payload.conversationId == conversation.conversationId else { return }
            remoteTypingUserId = payload.userId
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeTypingStop)) { notification in
            guard let payload = notification.userInfo?["payload"] as? TypingEvent,
                  payload.conversationId == conversation.conversationId else { return }
            if remoteTypingUserId == payload.userId {
                remoteTypingUserId = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .realtimeStatusChanged)) { _ in
            if RealtimeService.shared.connectionState == .connected {
                Task { await viewModel.loadMessages() }
            }
        }
        .sheet(isPresented: $isVoiceSheetPresented) {
            NavigationStack {
                VStack(spacing: BoopSpacing.lg) {
                    BoopVoiceRecorder(state: voiceRecorderState)

                    if let data = voiceRecorderState.getRecordingData() {
                        BoopButton(
                            title: "Send voice note",
                            isLoading: viewModel.isSending,
                            isDisabled: !voiceRecorderState.hasRecording
                        ) {
                            Task {
                                await viewModel.sendVoice(data: data, duration: voiceRecorderState.duration)
                                voiceRecorderState.deleteRecording()
                                isVoiceSheetPresented = false
                            }
                        }
                    }
                }
                .padding(BoopSpacing.xl)
                .boopBackground()
                .navigationTitle("Voice Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            voiceRecorderState.deleteRecording()
                            isVoiceSheetPresented = false
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { expandedImageURL != nil },
            set: { if !$0 { expandedImageURL = nil } }
        )) {
            if let urlString = expandedImageURL {
                ImageViewerView(imageURL: urlString)
            }
        }
    }

    @ViewBuilder
    private var conversationContent: some View {
        VStack(spacing: 0) {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Text("\(filteredMessages.count) result\(filteredMessages.count == 1 ? "" : "s")")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.top, BoopSpacing.sm)
            }

            RealtimeStatusBanner()
                .padding(.horizontal, BoopSpacing.md)
                .padding(.bottom, BoopSpacing.sm)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: BoopSpacing.sm) {
                        // Conversation starters
                        if !viewModel.starters.isEmpty && viewModel.messages.count <= 3 {
                            ConversationStartersCard(
                                starters: viewModel.starters,
                                isLoading: viewModel.isLoadingStarters,
                                onSelect: { text in
                                    viewModel.draft = text
                                }
                            )
                            .padding(.bottom, BoopSpacing.sm)
                        }

                        // Cursor-based pagination trigger
                        if viewModel.hasMoreMessages {
                            ProgressView()
                                .tint(BoopColors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BoopSpacing.sm)
                                .onAppear {
                                    Task { await viewModel.loadOlderMessages() }
                                }
                        }

                        ForEach(filteredMessages) { message in
                            ChatMessageBubble(
                                message: message,
                                isCurrentUser: message.senderId.id == AuthManager.shared.currentUser?.id,
                                deliveryState: viewModel.deliveryState(for: message),
                                audioPlayer: audioPlayer,
                                onReact: { emoji in
                                    Task { await viewModel.toggleReaction(for: message, emoji: emoji) }
                                },
                                onRetry: {
                                    Task { await viewModel.retryFailedMessage(message) }
                                },
                                onReply: {
                                    viewModel.replyingTo = message
                                },
                                onImageTap: { url in
                                    expandedImageURL = url
                                }
                            )
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.md)
                }
                .background(Color.clear)
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if remoteTypingUserId != nil {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("\(conversation.otherUser.firstName ?? "Someone") is typing")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.bottom, BoopSpacing.xs)
            }

            fogNudgeChips

            composer
        }
    }

    private func blockOtherUser() async {
        let userId = conversation.otherUser.userId
        do {
            try await APIClient.shared.requestVoid(.blockUser(userId: userId))
            Haptics.success()
            NotificationCenter.default.post(name: .init("boop.blockedUser"), object: nil)
            dismiss()
        } catch {
            showBlockError = true
        }
    }

    private var filteredMessages: [ChatMessage] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return viewModel.messages }

        return viewModel.messages.filter { message in
            let text = [
                message.content.text,
                message.type == "voice" ? "voice note" : nil,
                message.type == "image" ? "image" : nil,
                message.type == "game_invite" ? "game invite" : nil,
            ]
            .compactMap { $0 }
            .joined(separator: " ")

            return text.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var composer: some View {
        VStack(spacing: BoopSpacing.xs) {
            // Reply-to preview bar
            if let replyMsg = viewModel.replyingTo {
                HStack(spacing: BoopSpacing.sm) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BoopColors.secondary)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyMsg.senderId.firstName ?? "Someone")
                            .font(BoopTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(BoopColors.secondary)
                        Text(replyMsg.content.text ?? (replyMsg.type == "voice" ? "Voice note" : replyMsg.type == "image" ? "Photo" : "Message"))
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        viewModel.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.xs)
                .background(BoopColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: BoopSpacing.sm) {
                PhotosPicker(selection: $selectedMediaItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(BoopColors.surface)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Send photo")

                TextField("Write a message", text: $viewModel.draft, axis: .vertical)
                    .font(BoopTypography.body)
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.sm)
                    .background(BoopColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                    .onChange(of: viewModel.draft) { _, newValue in
                        let hasText = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        if hasText, !hasSentTyping {
                            hasSentTyping = true
                            RealtimeService.shared.emitTypingStart(conversationId: conversation.conversationId)
                        } else if !hasText, hasSentTyping {
                            hasSentTyping = false
                            RealtimeService.shared.emitTypingStop(conversationId: conversation.conversationId)
                        }
                    }

                Button {
                    isVoiceSheetPresented = true
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(BoopColors.surface)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Record voice note")

                Button {
                    Haptics.light()
                    hasSentTyping = false
                    RealtimeService.shared.emitTypingStop(conversationId: conversation.conversationId)
                    Task { await viewModel.sendDraft() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(BoopColors.primaryGradient)
                        .clipShape(Circle())
                }
                .disabled(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .accessibilityLabel("Send message")
            }
        }
        .padding(.horizontal, BoopSpacing.md)
        .padding(.top, BoopSpacing.sm)
        .padding(.bottom, BoopSpacing.md)
        .background(BoopColors.surface.shadow(color: .black.opacity(0.05), radius: 12, y: -4))
    }
}

// MARK: - Chat Message Bubble

private struct ChatMessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let deliveryState: ChatMessageDeliveryState
    let audioPlayer: RemoteAudioPlayer
    let onReact: (String) -> Void
    let onRetry: () -> Void
    let onReply: () -> Void
    let onImageTap: (String) -> Void

    private let allReactions = ["❤️", "😊", "😂", "😍", "👍", "🔥", "😮", "😢"]
    private let quickReactions = ["❤️", "😊", "🔥"]

    var body: some View {
        // System messages render centered with no bubble
        if message.type == "system" {
            HStack {
                Spacer()
                Text(message.content.text ?? "")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, BoopSpacing.xs)
                Spacer()
            }
        } else {
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: BoopSpacing.xxs) {
                HStack {
                    if isCurrentUser { Spacer() }

                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        // Reply-to quoted block
                        if let reply = message.replyTo, let replyContent = reply.content {
                            HStack(spacing: BoopSpacing.xs) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(BoopColors.secondary)
                                    .frame(width: 3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reply.senderId?.firstName ?? "Someone")
                                        .font(BoopTypography.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(BoopColors.secondary)
                                    Text(replyContent.text ?? (reply.type == "voice" ? "Voice note" : reply.type == "image" ? "Photo" : "Message"))
                                        .font(BoopTypography.caption)
                                        .foregroundStyle(isCurrentUser ? Color.white.opacity(0.7) : BoopColors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(BoopSpacing.xs)
                            .background(isCurrentUser ? Color.white.opacity(0.1) : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sm, style: .continuous))
                        }

                        content

                        if !message.reactions.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(Array(Dictionary(grouping: message.reactions, by: \.emoji).keys.sorted()), id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, BoopSpacing.xs)
                                        .padding(.vertical, 3)
                                        .background(BoopColors.overlayLight)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(bubbleBackground)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    // Subtle shadow so white received bubbles stay visible on bright fog in light mode.
                    .shadow(color: isCurrentUser ? .clear : Color.black.opacity(0.06), radius: 4, x: 0, y: 1)
                    .contextMenu {
                        // Full 8-emoji reaction picker
                        Section("React") {
                            ForEach(allReactions, id: \.self) { emoji in
                                Button {
                                    onReact(emoji)
                                } label: {
                                    Text(emoji)
                                }
                            }
                        }

                        Button {
                            onReply()
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left")
                        }
                    }

                    if !isCurrentUser { Spacer() }
                }

                HStack(spacing: 6) {
                    ForEach(quickReactions, id: \.self) { emoji in
                        Button(emoji) { onReact(emoji) }
                            .font(.system(size: 13))
                    }

                    if isCurrentUser {
                        Text(deliveryLabel)
                            .font(BoopTypography.caption)
                            .foregroundStyle(deliveryColor)

                        if deliveryState == .failed && message.type == "text" {
                            Button("Retry") { onRetry() }
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.primary)
                        }
                    }
                }
                .padding(.horizontal, isCurrentUser ? 0 : BoopSpacing.sm)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.type {
        case "image":
            if let mediaURL = message.content.mediaUrl {
                Button {
                    onImageTap(mediaURL)
                } label: {
                    AsyncImage(url: URL(string: mediaURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(BoopColors.overlayLight)
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        case "voice":
            Button {
                audioPlayer.togglePlayback(urlString: message.content.mediaUrl)
            } label: {
                HStack(spacing: BoopSpacing.sm) {
                    Image(systemName: audioPlayer.currentURL == message.content.mediaUrl && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    Text(message.content.mediaDuration.map { "\($0, specifier: "%.0f")s voice note" } ?? "Voice note")
                }
                .font(BoopTypography.callout)
                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
            }
        case "game_invite":
            if let gameSessionId = message.content.gameSessionId {
                NavigationLink {
                    GameSessionView(gameId: gameSessionId)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundStyle(isCurrentUser ? Color.white.opacity(0.8) : BoopColors.secondary)
                            Text(message.content.text ?? "Game invite")
                                .font(BoopTypography.body)
                                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
                        }
                        Text("Tap to join")
                            .font(BoopTypography.caption)
                            .foregroundStyle(isCurrentUser ? Color.white.opacity(0.8) : BoopColors.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        default:
            Text(message.content.text ?? "")
                .font(BoopTypography.body)
                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
        }
    }

    private var bubbleBackground: some ShapeStyle {
        if isCurrentUser {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [BoopColors.primary, Color(hex: "FF8C8C")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(BoopColors.chatBubbleReceived)
    }

    private var deliveryLabel: String {
        switch deliveryState {
        case .sending: return "Sending"
        case .sent: return "Sent"
        case .seen: return "Seen"
        case .failed: return "Failed"
        }
    }

    private var deliveryColor: Color {
        switch deliveryState {
        case .sending, .sent: return BoopColors.textMuted
        case .seen: return BoopColors.secondary
        case .failed: return BoopColors.error
        }
    }
}

// MARK: - Match Conversation Loader

struct MatchConversationLoaderView: View {
    let matchId: String
    @State private var viewModel = ChatInboxViewModel()

    var body: some View {
        Group {
            if let conversation = viewModel.conversation(for: matchId) {
                ChatConversationView(conversation: conversation)
            } else if viewModel.isLoading {
                ProgressView()
                    .tint(BoopColors.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .boopBackground()
            } else {
                VStack(spacing: BoopSpacing.md) {
                    Text("Conversation unavailable")
                        .font(BoopTypography.headline)
                    Text("This match does not have an active conversation yet.")
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .padding()
                .boopBackground()
            }
        }
        .task {
            await viewModel.loadInbox()
        }
    }
}
