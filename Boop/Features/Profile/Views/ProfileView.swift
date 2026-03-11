import PhotosUI
import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var draggedPhotoId: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                heroCard
                statsCard
                aboutCard
                photosCard
                voiceCard
                actionsCard
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Me")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
        .refreshable {
            await viewModel.loadProfile()
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                var images: [UIImage] = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
                await viewModel.uploadPhotos(images)
                selectedPhotoItems = []
            }
        }
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [BoopColors.cardDarkProfile, BoopColors.cardDarkDeepBlue, Color(hex: "356D70")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 240)

            if let photoURL = viewModel.user?.photos?.profilePhoto?.url {
                BoopRemoteImage(urlString: photoURL) {
                    Rectangle().fill(Color.white.opacity(0.08))
                }
                .frame(height: 240)
                .clipped()
                .opacity(0.34)
            }

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                Text(profileStatusText.uppercased())
                    .font(BoopTypography.caption)
                    .fontWeight(.bold)
                    .kerning(1.1)
                    .foregroundStyle(Color.white.opacity(0.7))

                Text(displayName)
                    .font(BoopTypography.title1)
                    .foregroundStyle(.white)

                Text(viewModel.user?.location?.city ?? "Location pending")
                    .font(BoopTypography.callout)
                    .foregroundStyle(Color.white.opacity(0.76))

                HStack(spacing: BoopSpacing.xs) {
                    profileChip(label: voiceStatusText, tint: BoopColors.secondary)
                    profileChip(label: "\(viewModel.user?.photos?.totalPhotos ?? 0) photos", tint: BoopColors.primary)
                    profileChip(label: "\(viewModel.user?.questionsAnswered ?? 0) answers", tint: BoopColors.accent)
                }
            }
            .padding(BoopSpacing.lg)
        }
        .overlay(alignment: .topTrailing) {
            NavigationLink {
                ProfileEditView(viewModel: viewModel)
            } label: {
                Text("Edit")
                    .font(BoopTypography.footnote)
                    .foregroundStyle(.white)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, BoopSpacing.xs)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule())
            }
            .padding(BoopSpacing.md)
        }
    }

    private var statsCard: some View {
        HStack(spacing: BoopSpacing.sm) {
            statBlock(value: "\(viewModel.user?.questionsAnswered ?? 0)", label: "Answered", tint: BoopColors.accent)
            statBlock(value: "\(viewModel.user?.photos?.totalPhotos ?? 0)", label: "Photos", tint: BoopColors.primary)
            statBlock(value: revealReadinessText, label: "Stage", tint: stageColor)
        }
    }

    private var aboutCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Profile")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    NavigationLink("Edit") {
                        ProfileEditView(viewModel: viewModel)
                    }
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.primary)
                }

                profileRow(title: "Looking for", value: viewModel.user?.interestedIn?.displayName ?? "Not set")
                profileRow(title: "Gender", value: viewModel.user?.gender?.displayName ?? "Not set")
                profileRow(title: "Bio", value: viewModel.user?.bio?.text?.isEmpty == false ? viewModel.user?.bio?.text ?? "" : "Add a short bio")

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }
            }
        }
    }

    private var photosCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Photos")
                    .font(BoopTypography.headline)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Choose a strong main photo and tune the order others will see.")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)

                if let items = viewModel.user?.photos?.items, !items.isEmpty {
                    if let mainPhoto = items.first {
                        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                            Text("Main photo preview")
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textMuted)

                            ZStack(alignment: .bottomLeading) {
                                BoopRemoteImage(urlString: mainPhoto.url) {
                                    RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                                        .fill(BoopColors.surfaceSecondary)
                                }
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))

                                Text("Shown first across the app")
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, BoopSpacing.sm)
                                    .padding(.vertical, BoopSpacing.xs)
                                    .background(Color.black.opacity(0.28))
                                    .clipShape(Capsule())
                                    .padding(BoopSpacing.sm)
                            }
                        }
                    }

                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: max(0, 6 - items.count),
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(viewModel.isUploadingPhotos ? "Uploading..." : "Add photos")
                        }
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.primary)
                    }
                    .disabled(viewModel.isUploadingPhotos || items.count >= 6)

                    LazyVGrid(columns: photoColumns, spacing: BoopSpacing.sm) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                                ZStack(alignment: .topTrailing) {
                                    BoopRemoteImage(urlString: item.url) {
                                        RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                                            .fill(BoopColors.surfaceSecondary)
                                    }
                                    .frame(height: 128)
                                    .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))

                                    Button {
                                        Task { await viewModel.deletePhoto(at: index) }
                                    } label: {
                                        if viewModel.deletingPhotoIndex == index {
                                            ProgressView()
                                                .tint(.white)
                                                .frame(width: 26, height: 26)
                                        } else {
                                            Image(systemName: "trash.fill")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.white)
                                                .frame(width: 26, height: 26)
                                        }
                                    }
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(Circle())
                                    .padding(BoopSpacing.xs)

                                    if index == 0 {
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Text("Main")
                                                    .font(BoopTypography.caption)
                                                    .foregroundStyle(.white)
                                                    .padding(.horizontal, BoopSpacing.xs)
                                                    .padding(.vertical, 4)
                                                    .background(BoopColors.primary.opacity(0.9))
                                                    .clipShape(Capsule())
                                                Spacer()
                                            }
                                            .padding(BoopSpacing.xs)
                                        }
                                    }
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                                        .stroke(draggedPhotoId == item.id ? BoopColors.primary : .clear, lineWidth: 2)
                                }
                                .draggable(item.id) {
                                    RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                                        .fill(Color.white)
                                        .overlay(Text("Move").font(BoopTypography.caption))
                                        .frame(width: 72, height: 72)
                                        .onAppear { draggedPhotoId = item.id }
                                }
                                .dropDestination(for: String.self) { itemsToDrop, _ in
                                    guard let sourceId = itemsToDrop.first,
                                          sourceId != item.id,
                                          let sourceIndex = items.firstIndex(where: { $0.id == sourceId }),
                                          let destinationIndex = items.firstIndex(where: { $0.id == item.id }) else {
                                        draggedPhotoId = nil
                                        return false
                                    }

                                    var ids = items.map(\.id)
                                    let moved = ids.remove(at: sourceIndex)
                                    ids.insert(moved, at: destinationIndex)
                                    draggedPhotoId = nil
                                    Task { await viewModel.reorderPhotos(ids: ids) }
                                    return true
                                }

                                HStack(spacing: 6) {
                                    photoOrderButton(
                                        systemName: "arrow.left",
                                        isDisabled: index == 0 || viewModel.isReorderingPhotos
                                    ) {
                                        Task { await viewModel.movePhoto(from: index, by: -1) }
                                    }

                                    photoOrderButton(
                                        systemName: "arrow.right",
                                        isDisabled: index == items.count - 1 || viewModel.isReorderingPhotos
                                    ) {
                                        Task { await viewModel.movePhoto(from: index, by: 1) }
                                    }

                                    Button(index == 0 ? "Main photo" : "Set main") {
                                        Task { await viewModel.setMainPhoto(photoId: item.id) }
                                    }
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(index == 0 ? BoopColors.textMuted : BoopColors.primary)
                                    .disabled(index == 0 || viewModel.isReorderingPhotos)
                                }
                            }
                        }
                    }

                    if viewModel.isReorderingPhotos {
                        ProgressView("Saving photo order...")
                            .font(BoopTypography.caption)
                            .tint(BoopColors.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        Text("Your uploaded photos will show here.")
                            .font(BoopTypography.body)
                            .foregroundStyle(BoopColors.textSecondary)

                        PhotosPicker(
                            selection: $selectedPhotoItems,
                            maxSelectionCount: 6,
                            matching: .images
                        ) {
                            Text(viewModel.isUploadingPhotos ? "Uploading..." : "Add photos")
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.primary)
                        }
                        .disabled(viewModel.isUploadingPhotos)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func photoOrderButton(systemName: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isDisabled ? BoopColors.textMuted : BoopColors.textPrimary)
                .frame(width: 28, height: 28)
                .background(BoopColors.surfaceSecondary)
                .clipShape(Circle())
        }
        .disabled(isDisabled)
    }

    private var voiceCard: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Voice intro")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Text(voiceStatusText)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.secondary)
                        .padding(.horizontal, BoopSpacing.xs)
                        .padding(.vertical, 4)
                        .background(BoopColors.secondary.opacity(0.12))
                        .clipShape(Capsule())
                }

                if let audioURL = viewModel.user?.voiceIntro?.audioUrl {
                    Button {
                        audioPlayer.togglePlayback(urlString: audioURL)
                    } label: {
                        HStack(spacing: BoopSpacing.sm) {
                            Image(systemName: audioPlayer.currentURL == audioURL && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(BoopColors.secondary)
                            Text(audioPlayer.currentURL == audioURL && audioPlayer.isPlaying ? "Pause intro" : "Play intro")
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.textPrimary)
                            Spacer()
                            if let duration = viewModel.user?.voiceIntro?.duration {
                                Text("\(Int(duration))s")
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textMuted)
                            }
                        }
                        .padding(BoopSpacing.md)
                        .background(BoopColors.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                    }

                    NavigationLink {
                        VoiceReRecordView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 14))
                            Text("Re-record intro")
                                .font(BoopTypography.footnote)
                        }
                        .foregroundStyle(BoopColors.primary)
                    }
                } else {
                    Text("Record a short intro to make your profile feel more human.")
                        .font(BoopTypography.body)
                        .foregroundStyle(BoopColors.textSecondary)

                    NavigationLink {
                        VoiceReRecordView(viewModel: viewModel)
                    } label: {
                        HStack(spacing: BoopSpacing.xs) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 14))
                            Text("Record voice intro")
                                .font(BoopTypography.footnote)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(BoopColors.primary)
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        VStack(spacing: BoopSpacing.sm) {
            NavigationLink {
                ProfileEditView(viewModel: viewModel)
            } label: {
                HStack {
                    Text("Edit profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textPrimary)
                .padding(BoopSpacing.md)
                .boopCard(radius: BoopRadius.xl)
            }

            NavigationLink {
                QuestionsProgressView()
            } label: {
                HStack {
                    Text("Question progress")
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                }
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textPrimary)
                .padding(BoopSpacing.md)
                .boopCard(radius: BoopRadius.xl)
            }

            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack {
                    Text("Notifications")
                    Spacer()
                    Image(systemName: "bell.badge.fill")
                }
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textPrimary)
                .padding(BoopSpacing.md)
                .boopCard(radius: BoopRadius.xl)
            }

            BoopButton(title: "Log Out", variant: .outline) {
                AuthManager.shared.logout()
            }
        }
    }

    private var displayName: String {
        let name = viewModel.user?.firstName ?? "You"
        if let birthDate = viewModel.user?.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            return "\(name), \(age)"
        }
        return name
    }

    private var voiceStatusText: String {
        viewModel.user?.voiceIntro?.audioUrl == nil ? "Missing" : "Ready"
    }

    private var revealReadinessText: String {
        switch viewModel.user?.profileStage {
        case .ready:
            return "Ready"
        case .questionsPending:
            return "Questions"
        case .voicePending:
            return "Voice"
        case .incomplete, nil:
            return "Start"
        }
    }

    private var profileStatusText: String {
        switch viewModel.user?.profileStage {
        case .ready:
            return "Profile Ready"
        case .questionsPending:
            return "Questions Pending"
        case .voicePending:
            return "Voice Pending"
        case .incomplete, nil:
            return "In Progress"
        }
    }

    private var stageColor: Color {
        switch viewModel.user?.profileStage {
        case .ready:
            return BoopColors.success
        case .questionsPending:
            return BoopColors.accent
        case .voicePending:
            return BoopColors.secondary
        case .incomplete, nil:
            return BoopColors.primary
        }
    }

    private var photoColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: BoopSpacing.sm),
            GridItem(.flexible(), spacing: BoopSpacing.sm)
        ]
    }

    private func statBlock(value: String, label: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(BoopTypography.title3)
                .foregroundStyle(tint)
            Text(label)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.xl)
    }

    private func profileRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
            Text(value)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.textPrimary)
        }
    }

    private func profileChip(label: String, tint: Color) -> some View {
        Text(label)
            .font(BoopTypography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, BoopSpacing.xs)
            .padding(.vertical, 4)
            .background(tint.opacity(0.3))
            .clipShape(Capsule())
    }
}

struct ProfileEditView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                BoopSectionIntro(
                    title: "Edit profile",
                    subtitle: "Tighten the essentials.",
                    eyebrow: "Profile"
                )

                BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                    VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                        BoopTextField(
                            label: "First name",
                            text: $viewModel.firstName,
                            placeholder: "Your first name"
                        )

                        if viewModel.isProfileComplete {
                            lockedField(label: "Date of birth", value: viewModel.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                            lockedField(label: "Gender", value: viewModel.gender?.displayName ?? "Not set")
                            lockedField(label: "Interested in", value: viewModel.interestedIn?.displayName ?? "Not set")
                        } else {
                            VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                                Text("Date of birth")
                                    .font(BoopTypography.subheadline)
                                    .foregroundStyle(BoopColors.textSecondary)
                                DatePicker(
                                    "",
                                    selection: $viewModel.dateOfBirth,
                                    in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding(.horizontal, BoopSpacing.md)
                                .padding(.vertical, BoopSpacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                                        .fill(BoopColors.surfaceElevated)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                                        .stroke(BoopColors.border, lineWidth: 1)
                                )
                            }

                            BoopSegmentedPicker(
                                label: "Gender",
                                options: Gender.allCases.map { ($0, $0.displayName) },
                                selected: $viewModel.gender
                            )

                            BoopSegmentedPicker(
                                label: "Interested in",
                                options: InterestedIn.allCases.map { ($0, $0.displayName) },
                                selected: $viewModel.interestedIn
                            )
                        }

                        BoopTextField(
                            label: "City",
                            text: $viewModel.city,
                            placeholder: "City"
                        )

                        BoopTextField(
                            label: "Bio",
                            text: $viewModel.bio,
                            placeholder: "A few lines about you",
                            isMultiline: true,
                            maxLength: 180
                        )

                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.error)
                        } else if let message = viewModel.successMessage {
                            Text(message)
                                .font(BoopTypography.footnote)
                                .foregroundStyle(BoopColors.success)
                        }

                        BoopButton(title: "Save changes", isLoading: viewModel.isSaving) {
                            Task { await viewModel.saveProfile() }
                        }
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func lockedField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
            Text(label)
                .font(BoopTypography.subheadline)
                .foregroundStyle(BoopColors.textSecondary)
            HStack {
                Text(value)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(BoopColors.textMuted)
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .fill(BoopColors.surfaceSecondary)
            )
            Text("Set during onboarding and cannot be changed.")
                .font(BoopTypography.caption)
                .foregroundStyle(BoopColors.textMuted)
        }
    }
}
