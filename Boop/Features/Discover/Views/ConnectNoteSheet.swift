import SwiftUI

struct ConnectNoteSheet: View {
    @Bindable var viewModel: DiscoverViewModel
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    // Header
                    if let candidate = viewModel.connectCandidate {
                        HStack(spacing: BoopSpacing.md) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [BoopColors.primary.opacity(0.15), BoopColors.secondary.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text(String(candidate.firstName.prefix(1)))
                                        .font(.nunito(.bold, size: 20))
                                        .foregroundStyle(BoopColors.primary)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Connect with \(candidate.firstName)")
                                    .font(BoopTypography.headline)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Text("Add a personal note to stand out")
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                        }
                    }

                    // Note input
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        Text("Your note")
                            .font(BoopTypography.callout)
                            .fontWeight(.medium)
                            .foregroundStyle(BoopColors.textPrimary)

                        TextField("Write something personal...", text: $viewModel.noteDraft, axis: .vertical)
                            .font(BoopTypography.body)
                            .lineLimit(3...6)
                            .focused($isNoteFocused)
                            .padding(BoopSpacing.md)
                            .background(BoopColors.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))

                        HStack {
                            Spacer()
                            Text("\(viewModel.noteDraft.count)/500")
                                .font(BoopTypography.caption)
                                .foregroundStyle(viewModel.noteDraft.count > 500 ? BoopColors.error : BoopColors.textMuted)
                        }
                    }

                    // AI Suggestions
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(BoopColors.secondary)
                            Text("AI suggestions")
                                .font(BoopTypography.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(BoopColors.textPrimary)
                        }

                        if viewModel.isLoadingSuggestions {
                            HStack(spacing: BoopSpacing.sm) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(BoopColors.secondary)
                                Text("Analyzing your compatibility...")
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(BoopSpacing.md)
                        } else if viewModel.noteSuggestions.isEmpty {
                            Text("No suggestions available right now.")
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textMuted)
                                .padding(BoopSpacing.md)
                        } else {
                            VStack(spacing: BoopSpacing.xs) {
                                ForEach(viewModel.noteSuggestions) { suggestion in
                                    Button {
                                        viewModel.noteDraft = suggestion.text
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suggestion.text)
                                                .font(BoopTypography.callout)
                                                .foregroundStyle(BoopColors.textPrimary)
                                                .multilineTextAlignment(.leading)
                                            Text(suggestion.reason)
                                                .font(BoopTypography.caption)
                                                .foregroundStyle(BoopColors.textMuted)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(BoopSpacing.md)
                                        .background(BoopColors.surfaceSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                                                .stroke(
                                                    viewModel.noteDraft == suggestion.text
                                                        ? BoopColors.secondary
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Action buttons
                    VStack(spacing: BoopSpacing.sm) {
                        Button {
                            Haptics.success()
                            Task { await viewModel.sendConnect(withNote: true) }
                        } label: {
                            HStack(spacing: BoopSpacing.xs) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                                Text("Connect with Note")
                                    .font(BoopTypography.callout)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, BoopSpacing.md)
                            .foregroundStyle(.white)
                            .background(BoopColors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                        }
                        .disabled(viewModel.isSendingLike || viewModel.noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.noteDraft.count > 500)
                        .opacity(viewModel.noteDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                        Button {
                            Task { await viewModel.sendConnect(withNote: false) }
                        } label: {
                            Text("Connect without note")
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BoopSpacing.sm)
                        }
                        .disabled(viewModel.isSendingLike)
                    }
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
                }
            }
        }
        .presentationDetents([.large])
    }
}
