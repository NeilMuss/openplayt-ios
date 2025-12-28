import Foundation

enum PlaybackStatus: Equatable {
    case idle
    case playing
    case paused
    case stopped
}

struct PlaybackState: Equatable {
    var status: PlaybackStatus
    var currentTrack: Track?
    var position: TimeInterval

    init(status: PlaybackStatus = .idle, currentTrack: Track? = nil, position: TimeInterval = 0) {
        self.status = status
        self.currentTrack = currentTrack
        self.position = position
    }
}
