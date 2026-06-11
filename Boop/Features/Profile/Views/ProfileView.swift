import PhotosUI
import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var audioPlayer = RemoteAudioPlayer()
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var draggedPhotoId: String?
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var isDeleting = false
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                heroSection
                statsSection
                photosSection
                voiceSection
                meSection
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.bottom, BoopSpacing.xl)
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

    // MARK: - Hero

    private var heroSection: some View {
        CinematicHeader(
            urlString: viewModel.user?.photos?.profilePhoto?.url,
            blurRadius: 0,
            height: 280
        ) {
            AccentRule()
            Text(displayName)
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text(heroSubtitle)
                .font(BoopTypography.cineCaption)
                .tracking(1.5)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .overlay(alignment: .topTrailing) {
            NavigationLink {
                ProfileEditView(viewModel: viewModel)
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .thin))
                    .foregroundStyle(BoopColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(BoopColors.hairline, lineWidth: 1))
                    .background(Circle().fill(BoopColors.ground.opacity(0.4)))
            }
            .padding(.top, BoopSpacing.md)
        }
        .padding(.horizontal, -BoopSpacing.xl)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: BoopSpacing.lg) {
            statColumn(
                value: "\(viewModel.user?.questionsAnswered ?? 0)",
                label: "Answers"
            )
            Rectangle()
                .fill(BoopColors.hairline)
                .frame(width: 1, height: 44)
            statColumn(
                value: "\(viewModel.user?.badges?.count ?? 0)",
                label: "Badges"
            )
            Spacer(minLength: 0)
        }
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: label)
            Text(value)
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Your Photos")

            if let items = viewModel.user?.photos?.items, !items.isEmpty {
                Text("Your main photo leads everywhere. Reorder or swap it any time.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)

                addPhotosControl(remaining: max(0, 6 - items.count), disabled: viewModel.isUploadingPhotos || items.count >= 6)

                LazyVGrid(columns: photoColumns, spacing: BoopSpacing.sm) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        photoCell(item: item, index: index, total: items.count, items: items)
                    }
                }

                if viewModel.isReorderingPhotos {
                    HStack(spacing: BoopSpacing.xs) {
                        ProgressView().tint(BoopColors.accentColor).scaleEffect(0.8)
                        Text("Saving photo order")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            } else {
                Text("Your uploaded photos will show here.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)

                addPhotosControl(remaining: 6, disabled: viewModel.isUploadingPhotos)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }

    private func addPhotosControl(remaining: Int, disabled: Bool) -> some View {
        PhotosPicker(
            selection: $selectedPhotoItems,
            maxSelectionCount: remaining,
            matching: .images
        ) {
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .regular))
                Text(viewModel.isUploadingPhotos ? "UPLOADING" : "ADD PHOTOS")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
            }
            .foregroundStyle(disabled ? BoopColors.textMuted : BoopColors.accentColor)
            .padding(.vertical, BoopSpacing.sm)
            .padding(.horizontal, BoopSpacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(disabled ? BoopColors.hairline : BoopColors.accentColor.opacity(0.5), lineWidth: 1)
            )
        }
        .disabled(disabled)
    }

    @ViewBuilder
    private func photoCell(item: UserPhotos.PhotoItem, index: Int, total: Int, items: [UserPhotos.PhotoItem]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            ZStack(alignment: .topTrailing) {
                BoopRemoteImage(urlString: item.url) {
                    Rectangle().fill(BoopColors.surfaceSecondary)
                }
                .frame(height: 150)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))

                Button {
                    Task { await viewModel.deletePhoto(at: index) }
                } label: {
                    if viewModel.deletingPhotoIndex == index {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 28, height: 28)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                    }
                }
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
                .padding(BoopSpacing.xs)

                if index == 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Text("MAIN")
                                .font(BoopTypography.cineLabel)
                                .tracking(2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, BoopSpacing.xs)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.5))
                            Spacer()
                        }
                        .padding(BoopSpacing.xs)
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(draggedPhotoId == item.id ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
            }
            .draggable(item.id) {
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .fill(BoopColors.surface)
                    .overlay(
                        Text("MOVE")
                            .font(BoopTypography.cineLabel)
                            .tracking(2)
                            .foregroundStyle(BoopColors.textPrimary)
                    )
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

            HStack(spacing: BoopSpacing.xs) {
                Text("REORDER")
                    .font(BoopTypography.cineCaption)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
                    .accessibilityHidden(true)

                photoOrderButton(
                    systemName: "arrow.left",
                    isDisabled: index == 0 || viewModel.isReorderingPhotos,
                    accessibilityLabel: "Move earlier"
                ) {
                    Task { await viewModel.movePhoto(from: index, by: -1) }
                }

                photoOrderButton(
                    systemName: "arrow.right",
                    isDisabled: index == total - 1 || viewModel.isReorderingPhotos,
                    accessibilityLabel: "Move later"
                ) {
                    Task { await viewModel.movePhoto(from: index, by: 1) }
                }

                Spacer(minLength: 0)

                Button(index == 0 ? "MAIN" : "SET MAIN") {
                    Task { await viewModel.setMainPhoto(photoId: item.id) }
                }
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(index == 0 ? BoopColors.textMuted : BoopColors.accentColor)
                .disabled(index == 0 || viewModel.isReorderingPhotos)
            }
        }
    }

    @ViewBuilder
    private func photoOrderButton(systemName: String, isDisabled: Bool, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(isDisabled ? BoopColors.textMuted : BoopColors.textPrimary)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(BoopColors.hairline, lineWidth: 1))
        }
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Voice intro

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Voice Intro")

            if let audioURL = viewModel.user?.voiceIntro?.audioUrl {
                VoiceLine(
                    duration: voiceDurationText,
                    isPlaying: audioPlayer.currentURL == audioURL && audioPlayer.isPlaying,
                    progress: audioPlayer.currentURL == audioURL ? audioPlayer.progress : 0
                ) {
                    audioPlayer.togglePlayback(urlString: audioURL)
                }

                NavigationLink {
                    VoiceReRecordView(viewModel: viewModel)
                } label: {
                    Text("RE-RECORD INTRO")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
            } else {
                Text("Record a short intro to make your profile feel more human.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)

                NavigationLink {
                    VoiceReRecordView(viewModel: viewModel)
                } label: {
                    Text("RECORD VOICE INTRO")
                        .font(BoopTypography.cineLabel)
                        .tracking(2)
                        .foregroundStyle(BoopColors.accentColor)
                }
            }
        }
    }

    // MARK: - Me / settings

    private var meSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            EyebrowLabel(text: "Me")
                .padding(.bottom, BoopSpacing.xs)

            NavigationLink {
                PersonalityReportView()
            } label: {
                HairlineRow("Personality insights", showChevron: true)
            }

            NavigationLink {
                MyAnswersView()
            } label: {
                HairlineRow("My answers", showChevron: true)
            }

            NavigationLink {
                BadgesView()
            } label: {
                HairlineRow("Badges", showChevron: true) {
                    if let count = viewModel.user?.badges?.count, count > 0 {
                        Text("\(count)")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
            }

            NavigationLink {
                QuestionsProgressView()
            } label: {
                HairlineRow("Question progress", showChevron: true)
            }

            NavigationLink {
                NotificationSettingsView()
            } label: {
                HairlineRow("Notifications", showChevron: true)
            }

            NavigationLink {
                ProfileEditView(viewModel: viewModel)
            } label: {
                HairlineRow("Edit profile", showChevron: true)
            }

            appearanceRow

            Button {
                AuthManager.shared.logout()
            } label: {
                HairlineRow("Log out")
            }

            Button {
                showDeleteConfirm = true
            } label: {
                HairlineRow(isDeleting ? "Deleting…" : "Delete account", titleColor: BoopColors.error) {
                    if isDeleting {
                        ProgressView().tint(BoopColors.error).scaleEffect(0.8)
                    }
                }
            }
            .disabled(isDeleting)
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This permanently deletes your profile, photos, voice intro, answers, matches, and conversations. This cannot be undone.")
            }
            .alert("Couldn't delete your account", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again.")
            }
        }
    }

    private var appearanceRow: some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.md) {
                Text("Appearance")
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)
                Spacer(minLength: BoopSpacing.md)
                Picker("Appearance", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .tint(BoopColors.accentColor)
                .fixedSize()
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        do {
            try await APIClient.shared.requestVoid(.deleteAccount)
            AuthManager.shared.logout()
        } catch {
            showDeleteError = true
        }
        isDeleting = false
    }

    // MARK: - Derived copy

    private var displayName: String {
        let name = viewModel.user?.firstName ?? "You"
        if let birthDate = viewModel.user?.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            return "\(name), \(age)"
        }
        return name
    }

    private var heroSubtitle: String {
        var parts: [String] = []
        if let birthDate = viewModel.user?.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            if age > 0 { parts.append("\(age)") }
        }
        if let city = viewModel.user?.location?.city, !city.isEmpty {
            parts.append(city)
        }
        parts.append(viewModel.user?.voiceIntro?.audioUrl == nil ? profileStatusText : "Voice verified")
        return parts.joined(separator: "  ·  ").uppercased()
    }

    private var voiceDurationText: String {
        if let duration = viewModel.user?.voiceIntro?.duration {
            return "\(Int(duration))s"
        }
        return "Voice intro"
    }

    private var profileStatusText: String {
        switch viewModel.user?.profileStage {
        case .ready:
            return "Profile ready"
        case .preview:
            return "Preview"
        case .questionsPending:
            return "Questions pending"
        case .voicePending:
            return "Voice pending"
        case .incomplete, nil:
            return "In progress"
        }
    }

    private var photoColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: BoopSpacing.sm),
            GridItem(.flexible(), spacing: BoopSpacing.sm)
        ]
    }
}

struct ProfileEditView: View {
    @Bindable var viewModel: ProfileViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                header

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
                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        EyebrowLabel(text: "Date of birth")
                        DatePicker(
                            "",
                            selection: $viewModel.dateOfBirth,
                            in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(BoopColors.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, BoopSpacing.xs)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(BoopColors.hairline).frame(height: 1)
                        }
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
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
                } else if let message = viewModel.successMessage {
                    Text(message)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.success)
                }

                BoopButton(title: "Save changes", isLoading: viewModel.isSaving) {
                    Task { await viewModel.saveProfile() }
                }
                .padding(.top, BoopSpacing.xs)
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Profile", color: BoopColors.accentColor)
            AccentRule()
            Text("Edit profile")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)
            Text("Tighten the essentials.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    private func lockedField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: label)
            VStack(spacing: 0) {
                HStack {
                    Text(value)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textMuted)
                    Spacer()
                    Image(systemName: "lock")
                        .font(.system(size: 12, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
                .padding(.vertical, BoopSpacing.sm)
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
            Text("Set during onboarding and cannot be changed.")
                .font(BoopTypography.cineCaption)
                .foregroundStyle(BoopColors.textMuted)
        }
    }
}
