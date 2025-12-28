import Foundation

protocol PlaybackEventSink {
    func queueLoaded(_ tracks: [Track])
    func trackStarted(_ track: Track)
    func trackPaused(_ track: Track)
    func trackStopped(_ track: Track)
    func queueDidEnd()
    func positionChanged(_ position: TimeInterval)
    func volumeChanged(_ volume: Float)
}

struct NullPlaybackEventSink: PlaybackEventSink {
    func queueLoaded(_ tracks: [Track]) {}
    func trackStarted(_ track: Track) {}
    func trackPaused(_ track: Track) {}
    func trackStopped(_ track: Track) {}
    func queueDidEnd() {}
    func positionChanged(_ position: TimeInterval) {}
    func volumeChanged(_ volume: Float) {}
}
