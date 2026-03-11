import SwiftUI
import AVFoundation

@Observable
class VoiceRecorderState {
    var isRecording = false
    var isPlaying = false
    var recordedURL: URL?
    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var error: String?

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    var minDuration: TimeInterval = 10
    var maxDuration: TimeInterval = 60

    var hasRecording: Bool { recordedURL != nil }
    var formattedDuration: String { formatTime(duration) }
    var formattedCurrentTime: String { formatTime(currentTime) }
    var minDurationMet: Bool { duration >= minDuration }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            self.error = "Failed to set up audio session"
            return
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice_intro_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            recordedURL = url
            isRecording = true
            duration = 0
            startTimer()
        } catch {
            self.error = "Failed to start recording"
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
    }

    func play() {
        guard let url = recordedURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            isPlaying = true
            currentTime = 0
            startPlaybackTimer()
        } catch {
            self.error = "Failed to play recording"
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        currentTime = 0
        stopTimer()
    }

    func deleteRecording() {
        stopPlayback()
        if let url = recordedURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordedURL = nil
        duration = 0
        currentTime = 0
    }

    func getRecordingData() -> Data? {
        guard let url = recordedURL else { return nil }
        return try? Data(contentsOf: url)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.duration += 0.1
                if self.duration >= self.maxDuration {
                    self.stopRecording()
                }
            }
        }
    }

    private func startPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if let player = self.audioPlayer, player.isPlaying {
                    self.currentTime = player.currentTime
                } else {
                    self.isPlaying = false
                    self.currentTime = 0
                    self.stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time) % 60
        let minutes = Int(time) / 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct BoopVoiceRecorder: View {
    @Bindable var state: VoiceRecorderState

    var body: some View {
        VStack(spacing: BoopSpacing.lg) {
            if state.hasRecording && !state.isRecording {
                // Playback mode
                playbackView
            } else {
                // Recording mode
                recordingView
            }
        }
    }

    private var recordingView: some View {
        VStack(spacing: BoopSpacing.md) {
            // Timer
            Text(state.formattedDuration)
                .font(BoopTypography.largeTitle)
                .foregroundStyle(state.isRecording ? BoopColors.primary : BoopColors.textMuted)
                .monospacedDigit()

            // Duration guidance
            if !state.isRecording {
                Text("\(Int(state.minDuration))-\(Int(state.maxDuration)) seconds")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
            } else {
                Text(state.minDurationMet ? "Looking good!" : "Keep going... \(Int(state.minDuration) - Int(state.duration))s minimum")
                    .font(BoopTypography.caption)
                    .foregroundStyle(state.minDurationMet ? BoopColors.success : BoopColors.textSecondary)
            }

            // Record button
            Button {
                if state.isRecording {
                    state.stopRecording()
                } else {
                    state.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(BoopColors.primary.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .scaleEffect(state.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: state.isRecording)

                    Circle()
                        .fill(BoopColors.primaryGradient)
                        .frame(width: 72, height: 72)

                    Image(systemName: state.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }

            Text(state.isRecording ? "Tap to stop" : "Tap to record")
                .font(BoopTypography.footnote)
                .foregroundStyle(BoopColors.textMuted)
        }
    }

    private var playbackView: some View {
        VStack(spacing: BoopSpacing.md) {
            // Duration display
            HStack {
                Text(state.formattedCurrentTime)
                Spacer()
                Text(state.formattedDuration)
            }
            .font(BoopTypography.caption)
            .foregroundStyle(BoopColors.textMuted)
            .monospacedDigit()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(BoopColors.border)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(BoopColors.primaryGradient)
                        .frame(width: geometry.size.width * playbackProgress)
                }
            }
            .frame(height: 6)

            // Controls
            HStack(spacing: BoopSpacing.xxl) {
                Button {
                    state.deleteRecording()
                } label: {
                    Label("Re-record", systemImage: "arrow.counterclockwise")
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textSecondary)
                }

                Button {
                    if state.isPlaying {
                        state.stopPlayback()
                    } else {
                        state.play()
                    }
                } label: {
                    Circle()
                        .fill(BoopColors.secondaryGradient)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                                .offset(x: state.isPlaying ? 0 : 2)
                        )
                }
            }
        }
    }

    private var playbackProgress: CGFloat {
        guard state.duration > 0 else { return 0 }
        return state.currentTime / state.duration
    }
}
