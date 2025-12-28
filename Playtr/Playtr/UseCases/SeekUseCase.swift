import Foundation

final class SeekUseCase {
    private let session: PlaybackSession
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(session: PlaybackSession, audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.session = session
        self.audio = audio
        self.events = events
    }

    func execute(position: TimeInterval) {
        guard session.machine.state.currentTrack != nil else { return }
        session.machine.seek(to: position)
        audio.seek(to: session.machine.state.position)
        events.positionChanged(session.machine.state.position)
    }
}
