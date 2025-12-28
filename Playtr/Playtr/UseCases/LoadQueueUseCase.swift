import Foundation

final class LoadQueueUseCase {
    private let session: PlaybackSession
    private let events: PlaybackEventSink

    init(session: PlaybackSession, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.events = events
    }

    func execute(tracks: [Track]) {
        session.machine.loadQueue(tracks)
        events.queueLoaded(tracks)
    }
}
