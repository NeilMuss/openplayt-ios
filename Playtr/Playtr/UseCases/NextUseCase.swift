import Foundation

final class NextUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute() {
        let result = session.machine.next()
        switch result {
        case .advanced(let track):
            audio.play(track)
            events.trackStarted(track)
        case .queueEnded:
            audio.stop()
            events.queueDidEnd()
        case .restarted, .noTrack:
            break
        }
    }
}
