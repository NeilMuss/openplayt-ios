import Foundation

final class PreviousUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute() {
        let result = session.machine.previous()
        switch result {
        case .advanced(let track), .restarted(let track):
            audio.play(track)
            events.trackStarted(track)
        case .queueEnded, .noTrack:
            break
        }
    }
}
