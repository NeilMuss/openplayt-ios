import Foundation

enum QueueAdvanceResult: Equatable {
    case advanced(Track)
    case restarted(Track)
    case queueEnded
    case noTrack
}

struct PlaybackStateMachine: Equatable {
    private(set) var queue: QueueState
    private(set) var state: PlaybackState

    init(queue: QueueState = QueueState(), state: PlaybackState = PlaybackState()) {
        self.queue = queue
        self.state = state
    }

    mutating func loadQueue(_ tracks: [Track]) {
        queue.reset(with: tracks)
        state = PlaybackState()
    }

    @discardableResult
    mutating func play() -> Track? {
        if state.currentTrack == nil {
            state.currentTrack = queue.currentTrack
        }
        guard let currentTrack = state.currentTrack else { return nil }
        state.status = .playing
        return currentTrack
    }

    @discardableResult
    mutating func pause() -> Track? {
        guard state.status == .playing, let currentTrack = state.currentTrack else { return nil }
        state.status = .paused
        return currentTrack
    }

    @discardableResult
    mutating func stop() -> Track? {
        guard state.status != .idle, let currentTrack = state.currentTrack else { return nil }
        state.status = .stopped
        return currentTrack
    }

    mutating func seek(to position: TimeInterval) {
        guard state.currentTrack != nil else { return }
        state.position = max(0, position)
    }

    mutating func next() -> QueueAdvanceResult {
        if queue.advance(), let track = queue.currentTrack {
            state.currentTrack = track
            state.status = .playing
            state.position = 0
            return .advanced(track)
        }

        state = PlaybackState(status: .stopped, currentTrack: nil, position: 0)
        return .queueEnded
    }

    mutating func previous() -> QueueAdvanceResult {
        guard let track = queue.currentTrack else { return .noTrack }

        if queue.isAtStart {
            state.currentTrack = track
            state.status = .playing
            state.position = 0
            return .restarted(track)
        }

        _ = queue.retreat()
        guard let previousTrack = queue.currentTrack else { return .noTrack }
        state.currentTrack = previousTrack
        state.status = .playing
        state.position = 0
        return .advanced(previousTrack)
    }
}
