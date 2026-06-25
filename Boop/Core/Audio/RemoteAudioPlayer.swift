import AVFoundation
import Foundation

@Observable
@MainActor
final class RemoteAudioPlayer {
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private(set) var currentURL: String?
    private(set) var isPlaying = false

    private(set) var elapsed: Double = 0
    private(set) var duration: Double = 0
    var progress: Double { duration > 0 ? min(1, elapsed / duration) : 0 }

    func togglePlayback(urlString: String?) {
        guard let urlString, let url = URL(string: urlString) else { return }

        if currentURL == urlString, isPlaying {
            stop()
            return
        }

        stop()
        currentURL = urlString

        // Route to the speaker. A prior recording session may have left the
        // route on .playAndRecord (earpiece) — force .playback so the note is audible.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true, options: [])
        } catch {
            // Non-fatal: still attempt playback on the current route.
        }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player

        // Play as soon as the item is ready; surface load failures instead of
        // silently doing nothing (the "voice note won't play" symptom).
        statusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self, self.player?.currentItem === item else { return }
                switch item.status {
                case .readyToPlay: self.player?.play()
                case .failed: self.stop()
                default: break
                }
            }
        }

        observePlaybackEnd()
        observePlaybackTime()
        player.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        statusObserver?.invalidate()
        statusObserver = nil
        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        player = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        isPlaying = false
        currentURL = nil
        elapsed = 0
        duration = 0
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
            Task { @MainActor in self?.stop() }
        }
    }

    private func observePlaybackTime() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            if seconds.isFinite, !seconds.isNaN {
                self.elapsed = seconds
            }
            if self.duration == 0,
               let itemDuration = self.player?.currentItem?.duration.seconds,
               itemDuration.isFinite, !itemDuration.isNaN, itemDuration > 0 {
                self.duration = itemDuration
            }
        }
    }
}
