import SwiftUI
import PhotosUI

struct ChatMediaGalleryView: View {
    let conversationId: String
    let otherUserName: String

    @State private var viewModel: ChatMediaGalleryViewModel
    @State private var selectedTab = 0
    @State private var selectedImageURL: String?
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var selectedMediaItem: PhotosPickerItem?
    @State private var pendingImage: UIImage?
    @State private var showImageConfirm = false
    @State private var isVoiceSheetPresented = false
    @State private var voiceRecorderState = VoiceRecorderState()

    init(conversationId: String, otherUserName: String) {
        self.conversationId = conversationId
        self.otherUserName = otherUserName
        _viewModel = State(initialValue: ChatMediaGalleryViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Picker("Media Type", selection: $selectedTab) {
                Text("Photos").tag(0)
                Text("Voice Notes").tag(1)
            }
            .pickerStyle(.segmented)
            .tint(BoopColors.accentColor)
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.bottom, BoopSpacing.md)

            if viewModel.isLoading && viewModel.photos.isEmpty && viewModel.voiceNotes.isEmpty {
                Spacer()
                ProgressView()
                    .tint(BoopColors.textMuted)
                Spacer()
            } else if selectedTab == 0 {
                photosGrid
            } else {
                voiceList
            }
        }
        .boopBackground()
        .navigationTitle("Shared Media")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPhotos()
            await viewModel.loadVoiceNotes()
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 0 && viewModel.photos.isEmpty {
                Task { await viewModel.loadPhotos() }
            } else if newTab == 1 && viewModel.voiceNotes.isEmpty {
                Task { await viewModel.loadVoiceNotes() }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedImageURL != nil },
            set: { if !$0 { selectedImageURL = nil } }
        )) {
            if let urlString = selectedImageURL {
                ImageViewerView(imageURL: urlString, onClose: { selectedImageURL = nil })
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if selectedTab == 0 {
                    PhotosPicker(selection: $selectedMediaItem, matching: .images) {
                        Image(systemName: "photo.badge.plus")
                            .foregroundStyle(BoopColors.accentColor)
                    }
                } else {
                    Button {
                        voiceRecorderState.minDuration = 1
                        voiceRecorderState.maxDuration = 120
                        isVoiceSheetPresented = true
                    } label: {
                        Image(systemName: "mic.badge.plus")
                            .foregroundStyle(BoopColors.accentColor)
                    }
                }
            }
        }
        .onChange(of: selectedMediaItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pendingImage = image
                    showImageConfirm = true
                }
                selectedMediaItem = nil
            }
        }
        .sheet(isPresented: $showImageConfirm) {
            VStack(spacing: BoopSpacing.lg) {
                Text("Send this photo?")
                    .font(BoopTypography.cineHeadline)
                    .foregroundStyle(BoopColors.textPrimary)
                    .padding(.top, BoopSpacing.xl)
                if let img = pendingImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 440)
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
                        .padding(.horizontal, BoopSpacing.xl)
                }
                Spacer()
                HStack(spacing: BoopSpacing.md) {
                    BoopButton(title: "Cancel", variant: .ghost, fullWidth: true) {
                        showImageConfirm = false
                        pendingImage = nil
                    }
                    BoopButton(title: "Send", variant: .primary, fullWidth: true) {
                        let img = pendingImage
                        showImageConfirm = false
                        pendingImage = nil
                        if let img { Task { await viewModel.sendImage(img) } }
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.bottom, BoopSpacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .boopBackground()
            .presentationDetents([.large])
        }
        .sheet(isPresented: $isVoiceSheetPresented) {
            NavigationStack {
                VStack(spacing: BoopSpacing.lg) {
                    BoopVoiceRecorder(state: voiceRecorderState)
                    if let data = voiceRecorderState.getRecordingData() {
                        BoopButton(
                            title: "Send voice note",
                            isLoading: viewModel.isLoading,
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            EyebrowLabel(text: "Shared with \(otherUserName)")
            Text("Media")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.top, BoopSpacing.sm)
        .padding(.bottom, BoopSpacing.md)
    }

    private var photosGrid: some View {
        Group {
            if viewModel.photos.isEmpty {
                emptyState(text: "No photos shared yet")
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                    ], spacing: 2) {
                        ForEach(viewModel.photos) { message in
                            if let mediaUrl = message.content.mediaUrl {
                                Button {
                                    selectedImageURL = mediaUrl
                                } label: {
                                    AsyncImage(url: URL(string: mediaUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(BoopColors.surface)
                                            .overlay(
                                                ProgressView().tint(BoopColors.textMuted)
                                            )
                                    }
                                    .frame(minHeight: 120)
                                    .clipped()
                                    .overlay(
                                        Rectangle()
                                            .stroke(BoopColors.hairline, lineWidth: 1)
                                    )
                                }
                            }
                        }

                        if viewModel.hasMorePhotos {
                            ProgressView()
                                .tint(BoopColors.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .onAppear {
                                    Task { await viewModel.loadMorePhotos() }
                                }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.bottom, BoopSpacing.lg)
                }
            }
        }
    }

    private var voiceList: some View {
        Group {
            if viewModel.voiceNotes.isEmpty {
                emptyState(text: "No voice notes shared yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.voiceNotes) { message in
                            voiceNoteRow(message: message)
                        }

                        if viewModel.hasMoreVoice {
                            ProgressView()
                                .tint(BoopColors.textMuted)
                                .padding(BoopSpacing.lg)
                                .onAppear {
                                    Task { await viewModel.loadMoreVoice() }
                                }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.bottom, BoopSpacing.lg)
                }
            }
        }
    }

    private func voiceNoteRow(message: ChatMessage) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)

            HStack(spacing: BoopSpacing.md) {
                Button {
                    audioPlayer.togglePlayback(urlString: message.content.mediaUrl)
                } label: {
                    Image(systemName: audioPlayer.currentURL == message.content.mediaUrl && audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(BoopColors.textPrimary.opacity(0.5), lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(message.senderId.firstName ?? "Someone")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)

                    HStack(spacing: BoopSpacing.sm) {
                        if let duration = message.content.mediaDuration {
                            Text("\(Int(duration))s")
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }

                        if let date = message.createdAt {
                            Text(date.chatTimestamp)
                                .font(BoopTypography.cineCaption)
                                .foregroundStyle(BoopColors.textMuted)
                        }
                    }
                }

                Spacer()
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private func emptyState(text: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            AccentRule()
            Text(text)
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)
            Text("Photos and voice notes you exchange will collect here.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
