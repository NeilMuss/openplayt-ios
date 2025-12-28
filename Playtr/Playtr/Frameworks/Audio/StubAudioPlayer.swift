import Foundation

final class StubAudioPlayer: AudioPlayerPort {
    private(set) var status: AudioPlayerStatus = .idle
    private(set) var currentTrack: Track?
    private(set) var lastSeekPosition: TimeInterval = 0
    private(set) var volume: Float = 1.0

    func play(_ track: Track) {
        currentTrack = track
        status = .playing
        lastSeekPosition = 0
    }

    func pause() {
        guard status == .playing else { return }
        status = .paused
    }

    func stop() {
        guard status != .idle else { return }
        status = .stopped
        currentTrack = nil
        lastSeekPosition = 0
    }

    func seek(to position: TimeInterval) {
        guard currentTrack != nil else { return }
        lastSeekPosition = max(0, position)
    }

    func setVolume(_ volume: Float) {
        self.volume = volume
    }
}
