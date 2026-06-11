import SwiftUI

struct MyAnswersView: View {
    @State private var viewModel = MyAnswersViewModel()
    @State private var audioPlayer = RemoteAudioPlayer()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.error)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if viewModel.history.isEmpty {
                    emptyState
                } else {
                    summary

                    ForEach(viewModel.groupedByDimension, id: \.key) { group in
                        dimensionSection(key: group.key, items: group.items)
                    }
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("My Answers")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    // MARK: - Summary (eyebrow + headline count)

    private var summary: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Answered", color: BoopColors.accentColor)
                Spacer()
                Text("\(viewModel.groupedByDimension.count) dimensions")
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.textMuted)
            }

            AccentRule()

            Text("\(viewModel.history.count) answers")
                .font(BoopTypography.cineDisplay)
                .foregroundStyle(BoopColors.textPrimary)

            Text("Everything you've shared, gathered by the dimension it speaks to.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
    }

    // MARK: - Dimension section (eyebrow tag + hairline rows)

    private func dimensionSection(key: String, items: [AnswerHistoryItem]) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack {
                EyebrowLabel(text: key.replacingOccurrences(of: "_", with: " "))
                Spacer()
                Text("\(items.count)")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textMuted)
            }

            VStack(spacing: 0) {
                ForEach(items) { item in
                    answerRow(item)
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    private func answerRow(_ item: AnswerHistoryItem) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Text(item.questionText)
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)

                answerContent(item)

                if let date = item.submittedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(BoopTypography.cineCaption)
                        .tracking(1)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    @ViewBuilder
    private func answerContent(_ item: AnswerHistoryItem) -> some View {
        if item.isVoice == true || item.voiceAnswerUrl != nil {
            voiceAnswer(item)
        } else if let text = item.textAnswer, !text.isEmpty {
            Text(text)
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        } else if let option = item.selectedOption {
            answerValue(option)
        } else if let options = item.selectedOptions, !options.isEmpty {
            answerValue(options.joined(separator: ", "))
        }
    }

    @ViewBuilder
    private func voiceAnswer(_ item: AnswerHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            if let url = item.voiceAnswerUrl {
                let isActive = audioPlayer.currentURL == url && audioPlayer.isPlaying
                VoiceLine(
                    duration: "Listen",
                    isPlaying: isActive,
                    progress: audioPlayer.currentURL == url ? audioPlayer.progress : 0,
                    elapsedText: isActive ? "\(formatPlaybackTime(audioPlayer.elapsed)) / \(formatPlaybackTime(audioPlayer.duration))" : nil
                ) {
                    audioPlayer.togglePlayback(urlString: url)
                }
            }

            if let transcript = item.voiceAnswerTranscript, !transcript.isEmpty {
                Text(transcript)
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
            } else {
                Text("Voice answer")
                    .font(BoopTypography.cineCaption)
                    .tracking(1)
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
    }

    private func answerValue(_ text: String) -> some View {
        HStack(alignment: .top, spacing: BoopSpacing.xs) {
            Rectangle()
                .fill(BoopColors.accentColor)
                .frame(width: 2)
            Text(text)
                .font(BoopTypography.cineBody)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "No answers yet")
            AccentRule()
            Text("Answer questions to build your personality profile.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
    }
}
