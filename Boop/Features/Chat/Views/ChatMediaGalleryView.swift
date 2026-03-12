import SwiftUI

struct ChatMediaGalleryView: View {
    let conversationId: String
    let otherUserName: String

    @State private var viewModel: ChatMediaGalleryViewModel
    @State private var selectedTab = 0
    @State private var selectedImageURL: String?
    @State private var audioPlayer = RemoteAudioPlayer()

    init(conversationId: String, otherUserName: String) {
        self.conversationId = conversationId
        self.otherUserName = otherUserName
        _viewModel = State(initialValue: ChatMediaGalleryViewModel(conversationId: conversationId))
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Media Type", selection: $selectedTab) {
                Text("Photos").tag(0)
                Text("Voice Notes").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.md)

            if viewModel.isLoading && viewModel.photos.isEmpty && viewModel.voiceNotes.isEmpty {
                Spacer()
                ProgressView()
                    .tint(BoopColors.primary)
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
                ImageViewerView(imageURL: urlString)
            }
        }
    }

    private var photosGrid: some View {
        Group {
            if viewModel.photos.isEmpty {
                emptyState(icon: "photo.on.rectangle", text: "No photos shared yet")
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 3),
                        GridItem(.flexible(), spacing: 3),
                        GridItem(.flexible(), spacing: 3),
                    ], spacing: 3) {
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
                                            .fill(BoopColors.surfaceSecondary)
                                            .overlay(
                                                ProgressView().tint(BoopColors.secondary)
                                            )
                                    }
                                    .frame(minHeight: 120)
                                    .clipped()
                                }
                            }
                        }

                        if viewModel.hasMorePhotos {
                            ProgressView()
                                .tint(BoopColors.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .onAppear {
                                    Task { await viewModel.loadMorePhotos() }
                                }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private var voiceList: some View {
        Group {
            if viewModel.voiceNotes.isEmpty {
                emptyState(icon: "waveform", text: "No voice notes shared yet")
            } else {
                ScrollView {
                    LazyVStack(spacing: BoopSpacing.sm) {
                        ForEach(viewModel.voiceNotes) { message in
                            voiceNoteRow(message: message)
                        }

                        if viewModel.hasMoreVoice {
                            ProgressView()
                                .tint(BoopColors.secondary)
                                .onAppear {
                                    Task { await viewModel.loadMoreVoice() }
                                }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.xl)
                    .padding(.vertical, BoopSpacing.md)
                }
            }
        }
    }

    private func voiceNoteRow(message: ChatMessage) -> some View {
        HStack(spacing: BoopSpacing.md) {
            Button {
                audioPlayer.togglePlayback(urlString: message.content.mediaUrl)
            } label: {
                Image(systemName: audioPlayer.currentURL == message.content.mediaUrl && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(BoopColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.senderId.firstName ?? "Someone")
                    .font(BoopTypography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(BoopColors.textPrimary)

                HStack(spacing: BoopSpacing.sm) {
                    if let duration = message.content.mediaDuration {
                        Text("\(Int(duration))s")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }

                    if let date = message.createdAt {
                        Text(date.chatTimestamp)
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            }

            Spacer()
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.xl)
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: BoopSpacing.md) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(BoopColors.textMuted)
            Text(text)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
