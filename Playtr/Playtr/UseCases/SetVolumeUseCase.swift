import Foundation

final class SetVolumeUseCase {
    private let audio: AudioPlayerPort
    private let events: PlaybackEventSink

    init(audio: AudioPlayerPort, events: PlaybackEventSink = NullPlaybackEventSink()) {
        self.audio = audio
        self.events = events
    }

    func execute(volume: Float) {
        audio.setVolume(volume)
        events.volumeChanged(volume)
    }
}
