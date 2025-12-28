import Foundation

final class PauseUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute() {
        guard let track = session.machine.pause() else { return }
        audio.pause()
        events.trackPaused(track)
    }
}
