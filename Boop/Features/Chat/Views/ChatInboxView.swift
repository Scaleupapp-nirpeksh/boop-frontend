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
                        VStack(alignment: .leading, spacing: 4) {
                            EyebrowLabel(text: "Chat")
                            Text("Inbox")
                                .font(BoopTypography.cineDisplay)
                                .foregroundStyle(BoopColors.textPrimary)
                        }

                        RealtimeStatusBanner()

                        Picker("Inbox Filter", selection: $filter) {
                            ForEach(InboxFilter.allCases, id: \.self) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(BoopColors.accentColor)

                        if filteredConversations.isEmpty {
                            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                                AccentRule()
                                Text(searchText.isEmpty ? "No conversations yet" : "No results")
                                    .font(BoopTypography.cineHeadline)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Text(searchText.isEmpty ? "New chats appear here after a mutual match." : "Try a different name or filter.")
                                    .font(BoopTypography.cineBodyLight)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(BoopSpacing.xl)
                            .boopCard(radius: BoopRadius.sharp, shadow: false)
                        } else {
                            LazyVStack(spacing: 0) {
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
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)

            HStack(spacing: BoopSpacing.md) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.otherUser.firstName ?? "Conversation")
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)

                        Spacer()

                        if let sentAt = conversation.lastMessage?.sentAt {
                            Text(sentAt.chatTimestamp)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }

                    Text(conversation.lastMessage?.text ?? "Start the conversation")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                        .lineLimit(1)

                    HStack(spacing: BoopSpacing.sm) {
                        stageChip

                        if conversation.unreadCount > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(BoopColors.accentColor)
                                    .frame(width: 6, height: 6)
                                Text("\(conversation.unreadCount) new")
                                    .font(BoopTypography.cineCaption)
                                    .foregroundStyle(BoopColors.accentColor)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            BlurredPortrait(
                urlString: conversation.otherUser.photo,
                blurRadius: 0,
                shape: .circle,
                scrim: false
            )
            .frame(width: 52, height: 52)

            if conversation.otherUser.isOnline == true {
                Circle()
                    .fill(BoopColors.accentColor)
                    .frame(width: 11, height: 11)
                    .overlay(Circle().stroke(BoopColors.ground, lineWidth: 2))
            }
        }
    }

    private var stageChip: some View {
        Text((conversation.matchStage ?? "mutual").replacingOccurrences(of: "_", with: " ").uppercased())
            .font(BoopTypography.cineLabel)
            .tracking(1.5)
            .foregroundStyle(BoopColors.textSecondary)
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
                .overlay(BoopColors.ground.opacity(scrimOpacity))
                .ignoresSafeArea()
        } else {
            BoopColors.ground.ignoresSafeArea()
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
                nudgeChip(icon: "mic", label: "Voice note") {
                    isVoiceSheetPresented = true
                }
                nudgeChip(icon: "gamecontroller", label: "Play a game") {
                    showGames = true
                }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.top, BoopSpacing.xs)
        }
    }

    private func nudgeChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11, weight: .thin))
                Text(label).font(BoopTypography.cineCaption)
            }
            .foregroundStyle(BoopColors.textPrimary)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .fill(BoopColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(BoopColors.hairline, lineWidth: 1)
            )
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
                        BlurredPortrait(
                            urlString: conversation.otherUser.photo,
                            blurRadius: 0,
                            shape: .circle,
                            scrim: false
                        )
                        .frame(width: 34, height: 34)

                        if conversation.otherUser.isOnline == true {
                            Circle()
                                .fill(BoopColors.accentColor)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(BoopColors.ground, lineWidth: 1.5))
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.otherUser.firstName ?? "Chat")
                            .font(BoopTypography.cineHeadline)
                            .foregroundStyle(BoopColors.textPrimary)

                        HStack(spacing: 4) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5, weight: .thin))
                            Text(conversation.otherUser.isOnline == true ? "ONLINE" : "OFFLINE")
                                .font(BoopTypography.cineCaption)
                                .tracking(1.5)
                        }
                        .foregroundStyle(conversation.otherUser.isOnline == true ? BoopColors.accentColor : BoopColors.textMuted)

                        if let comfort = viewModel.comfortScore,
                           conversation.matchId != nil,
                           conversation.matchStage != "revealed",
                           conversation.matchStage != "dating" {
                            Button { showComfortDetail = true } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    AccentRule(width: 18)
                                    Text("THE FOG IS LIFTING · \(comfort)/70")
                                        .font(BoopTypography.cineLabel)
                                        .tracking(1.5)
                                        .foregroundStyle(BoopColors.accentColor)
                                }
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
                        .font(.system(size: 15, weight: .thin))
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
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .thin))
                        .foregroundStyle(BoopColors.textSecondary)
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
                    Text("\(filteredMessages.count) RESULT\(filteredMessages.count == 1 ? "" : "S")")
                        .font(BoopTypography.cineLabel)
                        .tracking(1.5)
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
                        .tint(BoopColors.textMuted)
                    Text("\(conversation.otherUser.firstName ?? "Someone") is typing")
                        .font(BoopTypography.cineCaption)
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
                    Rectangle()
                        .fill(BoopColors.accentColor)
                        .frame(width: 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyMsg.senderId.firstName ?? "Someone")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.accentColor)
                        Text(replyMsg.content.text ?? (replyMsg.type == "voice" ? "Voice note" : replyMsg.type == "image" ? "Photo" : "Message"))
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        viewModel.replyingTo = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .thin))
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .fill(BoopColors.surfaceSecondary)
                )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .bottom, spacing: BoopSpacing.sm) {
                PhotosPicker(selection: $selectedMediaItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 16, weight: .thin))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                .fill(BoopColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                .stroke(BoopColors.hairline, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Send photo")

                TextField("Write a message", text: $viewModel.draft, axis: .vertical)
                    .font(BoopTypography.cineBody)
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .fill(BoopColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .stroke(BoopColors.hairline, lineWidth: 1)
                    )
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
                    Image(systemName: "mic")
                        .font(.system(size: 16, weight: .thin))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                .fill(BoopColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                .stroke(BoopColors.hairline, lineWidth: 1)
                        )
                }
                .accessibilityLabel("Record voice note")

                Button {
                    Haptics.light()
                    hasSentTyping = false
                    RealtimeService.shared.emitTypingStop(conversationId: conversation.conversationId)
                    Task { await viewModel.sendDraft() }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                .fill(BoopColors.accentColor)
                        )
                }
                .disabled(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(viewModel.isSending || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                .accessibilityLabel("Send message")
            }
        }
        .padding(.horizontal, BoopSpacing.md)
        .padding(.top, BoopSpacing.sm)
        .padding(.bottom, BoopSpacing.md)
        .background(
            BoopColors.surface
                .overlay(alignment: .top) {
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        )
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
                    .font(BoopTypography.cineCaption)
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
                                Rectangle()
                                    .fill(isCurrentUser ? Color.white.opacity(0.7) : BoopColors.accentColor)
                                    .frame(width: 2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reply.senderId?.firstName ?? "Someone")
                                        .font(BoopTypography.cineCaption)
                                        .foregroundStyle(isCurrentUser ? Color.white.opacity(0.85) : BoopColors.accentColor)
                                    Text(replyContent.text ?? (reply.type == "voice" ? "Voice note" : reply.type == "image" ? "Photo" : "Message"))
                                        .font(BoopTypography.cineCaption)
                                        .foregroundStyle(isCurrentUser ? Color.white.opacity(0.7) : BoopColors.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(BoopSpacing.xs)
                            .background(isCurrentUser ? Color.white.opacity(0.12) : BoopColors.overlayLight)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
                        }

                        content

                        if !message.reactions.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(Array(Dictionary(grouping: message.reactions, by: \.emoji).keys.sorted()), id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 13))
                                        .padding(.horizontal, BoopSpacing.xs)
                                        .padding(.vertical, 3)
                                        .background(
                                            RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                                                .fill(isCurrentUser ? Color.white.opacity(0.18) : BoopColors.overlayLight)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.vertical, BoopSpacing.sm)
                    .background {
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .fill(bubbleBackground)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
                    // Subtle shadow so received bubbles stay legible over bright fog in light mode.
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
                        Text(deliveryLabel.uppercased())
                            .font(BoopTypography.cineCaption)
                            .tracking(1)
                            .foregroundStyle(deliveryColor)

                        if deliveryState == .failed && message.type == "text" {
                            Button("RETRY") { onRetry() }
                                .font(BoopTypography.cineCaption)
                                .tracking(1)
                                .foregroundStyle(BoopColors.accentColor)
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
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .fill(BoopColors.overlayLight)
                    }
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
                }
            }
        case "voice":
            Button {
                audioPlayer.togglePlayback(urlString: message.content.mediaUrl)
            } label: {
                HStack(spacing: BoopSpacing.sm) {
                    Image(systemName: audioPlayer.currentURL == message.content.mediaUrl && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .regular))
                    Text(message.content.mediaDuration.map { "\($0, specifier: "%.0f")s voice note" } ?? "Voice note")
                        .font(BoopTypography.cineBody)
                }
                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
            }
        case "game_invite":
            if let gameSessionId = message.content.gameSessionId {
                NavigationLink {
                    GameSessionView(gameId: gameSessionId)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "gamecontroller")
                                .font(.system(size: 13, weight: .thin))
                                .foregroundStyle(isCurrentUser ? Color.white.opacity(0.85) : BoopColors.accentColor)
                            Text(message.content.text ?? "Game invite")
                                .font(BoopTypography.cineBody)
                                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
                        }
                        Text("TAP TO JOIN")
                            .font(BoopTypography.cineLabel)
                            .tracking(1.5)
                            .foregroundStyle(isCurrentUser ? Color.white.opacity(0.85) : BoopColors.accentColor)
                    }
                }
                .buttonStyle(.plain)
            }
        default:
            Text(message.content.text ?? "")
                .font(BoopTypography.cineBody)
                .foregroundStyle(isCurrentUser ? .white : BoopColors.textPrimary)
        }
    }

    private var bubbleBackground: some ShapeStyle {
        if isCurrentUser {
            return AnyShapeStyle(BoopColors.accentColor)
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
                    .tint(BoopColors.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .boopBackground()
            } else {
                VStack(spacing: BoopSpacing.sm) {
                    Text("Conversation unavailable")
                        .font(BoopTypography.cineHeadline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("This match does not have an active conversation yet.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .multilineTextAlignment(.center)
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
