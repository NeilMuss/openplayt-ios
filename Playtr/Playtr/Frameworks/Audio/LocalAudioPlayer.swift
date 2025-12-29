import AVFoundation
import Foundation

final class LocalAudioPlayer: NSObject, AudioPlayerPort, AVAudioPlayerDelegate {
    private(set) var status: AudioPlayerStatus = .idle
    private var player: AVAudioPlayer?
    private var currentVolume: Float = 1.0
    private let library: PlaytLibrary
    var errorHandler: ((String) -> Void)?
    var positionHandler: ((TimeInterval) -> Void)?
    var completionHandler: (() -> Void)?
    private var positionTimer: Timer?
    private var currentTrackID: UUID?

    init(library: PlaytLibrary = .shared, errorHandler: ((String) -> Void)? = nil) {
        self.library = library
        self.errorHandler = errorHandler
    }

    func play(_ track: Track) {
        if status == .paused, currentTrackID == track.id, let player {
            player.play()
            status = .playing
            startPositionTimer()
            return
        }
        if status == .playing, currentTrackID == track.id {
            return
        }

        guard
            let cartridgeID = track.cartridgeID,
            let source = track.archiveSource,
            let relativePath = track.relativePath
        else {
            status = .idle
            reportError("Missing archive metadata for playback.")
            return
        }

        do {
            let url = try library.resolveMediaURL(
                source: source,
                cartridgeID: cartridgeID,
                relativePath: relativePath
            )
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: [])

            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = currentVolume
            player?.prepareToPlay()
            player?.play()
            status = .playing
            currentTrackID = track.id
            startPositionTimer()
        } catch {
            status = .idle
            reportError(error.localizedDescription)
        }
    }

    func pause() {
        guard status == .playing else { return }
        player?.pause()
        if let currentTime = player?.currentTime {
            positionHandler?(currentTime)
        }
        status = .paused
        stopPositionTimer()
    }

    func stop() {
        guard status != .idle else { return }
        player?.stop()
        player = nil
        status = .stopped
        currentTrackID = nil
        stopPositionTimer()
    }

    func seek(to position: TimeInterval) {
        guard player != nil else { return }
        player?.currentTime = max(0, position)
    }

    func setVolume(_ volume: Float) {
        currentVolume = volume
        player?.volume = volume
    }

    private func reportError(_ message: String) {
        errorHandler?(message)
    }

    private func startPositionTimer() {
        stopPositionTimer()
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            self.positionHandler?(player.currentTime)
        }
    }

    private func stopPositionTimer() {
        positionTimer?.invalidate()
        positionTimer = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        status = .stopped
        stopPositionTimer()
        completionHandler?()
    }
}
