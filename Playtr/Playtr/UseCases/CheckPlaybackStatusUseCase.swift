import Foundation

final class CheckPlaybackStatusUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute() {
        guard audio.status == .idle else { return }
        let result = session.machine.next()
        switch result {
        case .advanced(let track):
            audio.play(track)
            events.trackStarted(track)
        case .queueEnded:
            events.queueDidEnd()
        case .restarted, .noTrack:
            break
        }
    }
}
