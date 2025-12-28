import Foundation

final class StopUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute() {
        guard let track = session.machine.stop() else { return }
        audio.stop()
        events.trackStopped(track)
    }
}
