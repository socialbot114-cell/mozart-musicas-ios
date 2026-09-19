import AVFoundation
import Combine
import MediaPlayer

@MainActor
final class PlaybackService: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentTrack: Track?
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0

    private let player = AVPlayer()
    private var timeObserver: Any?

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        configureNowPlaying()
        installTimeObserver()
    }

    deinit {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
    }

    func play(_ track: Track) {
        guard track.rightsStatus == "approved" else { return }
        currentTrack = track
        if let url = Self.url(for: track) {
            player.replaceCurrentItem(with: AVPlayerItem(url: url))
            player.play()
            isPlaying = true
            duration = track.durationSeconds ?? 0
        } else {
            currentTime = 0
            duration = track.durationSeconds ?? 0
            isPlaying = false
        }
        updateNowPlaying(for: track)
    }

    func toggle() {
        if isPlaying {
            pause()
        } else if currentTrack != nil {
            resume()
        }
    }

    func resume() {
        guard currentTrack != nil else { return }
        player.play()
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func seek(to seconds: Double) {
        let upper = duration > 0 ? duration : seconds
        let clamped = max(0, min(seconds, upper))
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        currentTime = clamped
    }

    private static func url(for track: Track) -> URL? {
        guard let value = track.audioPath, let path = BundleResourcePath(value) else { return nil }
        return path.url(in: .main)
    }

    private func installTimeObserver() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            if let item = self.player.currentItem {
                let d = item.duration.seconds
                if d.isFinite, d > 0 {
                    self.duration = d
                    if time.seconds >= d {
                        self.isPlaying = false
                    }
                }
            }
        }
    }

    private func updateNowPlaying(for track: Track) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.work,
            MPMediaItemPropertyArtist: track.composer,
        ]
        if let d = track.durationSeconds, d > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = d
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func configureNowPlaying() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in self?.resume(); return .success }
        commands.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
    }
}
