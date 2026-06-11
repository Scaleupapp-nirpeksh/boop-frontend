import SwiftUI

struct ConnectNoteSheet: View {
    @Bindable var viewModel: DiscoverViewModel
    @FocusState private var isNoteFocused: Bool

    private var trimmedNote: String {
        viewModel.noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isNoteValid: Bool {
        !trimmedNote.isEmpty && viewModel.noteDraft.count <= 500
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BoopSpacing.xl) {
                    header
                    noteInput
                    suggestions
                    actions
                }
                .padding(BoopSpacing.xl)
            }
            .boopBackground()
            .navigationTitle("Send Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showConnectSheet = false
                    }
                    .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        if let candidate = viewModel.connectCandidate {
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                EyebrowLabel(text: "Connect with \(candidate.firstName)", color: BoopColors.accentColor)
                AccentRule()
                Text("Add a note to stand out")
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)
            }
        }
    }

    // MARK: - Note input (hairline)

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Your note", color: BoopColors.textMuted)

            TextField("Write something personal…", text: $viewModel.noteDraft, axis: .vertical)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textPrimary)
                .tint(BoopColors.accentColor)
                .lineLimit(3...6)
                .focused($isNoteFocused)
                .padding(BoopSpacing.md)
                .background(BoopColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .stroke(isNoteFocused ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))

            HStack {
                Spacer()
                Text("\(viewModel.noteDraft.count)/500")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(viewModel.noteDraft.count > 500 ? BoopColors.error : BoopColors.textMuted)
            }
        }
    }

    // MARK: - AI suggestions (hairline rows)

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Suggested openers", color: BoopColors.textMuted)

            if viewModel.isLoadingSuggestions {
                HStack(spacing: BoopSpacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(BoopColors.accentColor)
                    Text("Analyzing your compatibility…")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, BoopSpacing.md)
            } else if viewModel.noteSuggestions.isEmpty {
                Text("No suggestions available right now.")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
                    .padding(.vertical, BoopSpacing.sm)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.noteSuggestions) { suggestion in
                        suggestionRow(suggestion)
                    }
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                }
            }
        }
    }

    private func suggestionRow(_ suggestion: NoteSuggestion) -> some View {
        let isSelected = viewModel.noteDraft == suggestion.text
        return Button {
            Haptics.light()
            viewModel.noteDraft = suggestion.text
        } label: {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
                HStack(alignment: .top, spacing: BoopSpacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.text)
                            .font(BoopTypography.cineBody)
                            .foregroundStyle(BoopColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(suggestion.reason)
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: BoopSpacing.sm)
                    Image(systemName: isSelected ? "checkmark" : "plus")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textMuted)
                        .padding(.top, 2)
                }
                .padding(.vertical, BoopSpacing.md)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: BoopSpacing.sm) {
            // Connect with note — flat coral bar sharp
            Button {
                Haptics.success()
                Task { await viewModel.sendConnect(withNote: true) }
            } label: {
                HStack(spacing: BoopSpacing.xs) {
                    if viewModel.isSendingLike {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    }
                    Text("Connect with Note")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(0.5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(BoopColors.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous))
            }
            .disabled(viewModel.isSendingLike || !isNoteValid)
            .opacity(isNoteValid ? 1 : 0.5)

            // Connect without note — quiet ghost
            Button {
                Task { await viewModel.sendConnect(withNote: false) }
            } label: {
                Text("Connect without note")
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, BoopSpacing.sm)
            }
            .disabled(viewModel.isSendingLike)
        }
    }
}
