import Foundation

enum AudioPlayerStatus: Equatable {
    case idle
    case playing
    case paused
    case stopped
}

protocol AudioPlayerPort {
    var status: AudioPlayerStatus { get }

    func play(_ track: Track)
    func pause()
    func stop()
    func seek(to position: TimeInterval)
    func setVolume(_ volume: Float)
}
