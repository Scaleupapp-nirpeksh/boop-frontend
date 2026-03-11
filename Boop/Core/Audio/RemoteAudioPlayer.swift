import AVFoundation
import Foundation

@Observable
final class RemoteAudioPlayer {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private(set) var currentURL: String?
    private(set) var isPlaying = false

    func togglePlayback(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return }

        if currentURL == urlString, isPlaying {
            stop()
            return
        }

        stop()
        currentURL = urlString

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        player = AVPlayer(url: url)
        observePlaybackEnd()
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        isPlaying = false
        currentURL = nil
    }

    private func observePlaybackEnd() {
        guard let item = player?.currentItem else { return }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }
    }
}
