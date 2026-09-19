import AVFoundation
import Combine
import MediaPlayer

@MainActor
final class PlaybackService: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    private let player = AVPlayer()

    override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        configureNowPlaying()
    }

    func play(_ track: Track) {
        guard track.rightsStatus == "approved", let value = track.audioPath,
              let path = BundleResourcePath(value), let url = path.url(in: .main) else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        player.play()
        isPlaying = true
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: track.work, MPMediaItemPropertyArtist: track.composer]
    }

    func pause() { player.pause(); isPlaying = false }

    private func configureNowPlaying() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in self?.player.play(); return .success }
        commands.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
    }
}
