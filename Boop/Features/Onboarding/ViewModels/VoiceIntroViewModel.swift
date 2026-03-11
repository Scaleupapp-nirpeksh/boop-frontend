import SwiftUI
import AVFoundation

@Observable
class VoiceIntroViewModel {
    var recorderState = VoiceRecorderState()
    var isUploading = false
    var errorMessage: String?

    var canSubmit: Bool {
        recorderState.hasRecording && recorderState.minDurationMet && !recorderState.isRecording
    }

    @MainActor
    func requestMicPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    @MainActor
    func uploadVoiceIntro() async -> User? {
        guard let data = recorderState.getRecordingData() else {
            errorMessage = "No recording found"
            return nil
        }

        isUploading = true
        errorMessage = nil

        do {
            let user = try await APIClient.shared.uploadVoiceIntro(
                data: data,
                duration: Int(recorderState.duration)
            )
            return user
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Upload failed. Please try again."
        }

        isUploading = false
        return nil
    }
}
