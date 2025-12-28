import XCTest
@testable import Playtr

final class AudioPlayerSpy: AudioPlayerPort {
    private(set) var status: AudioPlayerStatus = .idle
    private(set) var playedTracks: [Track] = []
    private(set) var pauseCallCount = 0
    private(set) var stopCallCount = 0
    private(set) var seekPositions: [TimeInterval] = []
    private(set) var volumeValues: [Float] = []

    func play(_ track: Track) {
        status = .playing
        playedTracks.append(track)
    }

    func pause() {
        status = .paused
        pauseCallCount += 1
    }

    func stop() {
        status = .stopped
        stopCallCount += 1
    }

    func seek(to position: TimeInterval) {
        seekPositions.append(position)
    }

    func setVolume(_ volume: Float) {
        volumeValues.append(volume)
    }
}

final class PlaybackEventSpy: PlaybackEventSink {
    private(set) var loadedQueues: [[Track]] = []
    private(set) var startedTracks: [Track] = []
    private(set) var pausedTracks: [Track] = []
    private(set) var stoppedTracks: [Track] = []
    private(set) var queueEndedCount = 0
    private(set) var positionChanges: [TimeInterval] = []
    private(set) var volumeChanges: [Float] = []

    func queueLoaded(_ tracks: [Track]) {
        loadedQueues.append(tracks)
    }

    func trackStarted(_ track: Track) {
        startedTracks.append(track)
    }

    func trackPaused(_ track: Track) {
        pausedTracks.append(track)
    }

    func trackStopped(_ track: Track) {
        stoppedTracks.append(track)
    }

    func queueDidEnd() {
        queueEndedCount += 1
    }

    func positionChanged(_ position: TimeInterval) {
        positionChanges.append(position)
    }

    func volumeChanged(_ volume: Float) {
        volumeChanges.append(volume)
    }
}

@MainActor
final class PlaybackUseCaseTests: XCTestCase {
    func testPlayUseCaseStartsFirstTrackAndEmitsEvent() {
        let tracks = [
            Track(title: "One", artist: "Artist", albumTitle: "Album", duration: 100),
            Track(title: "Two", artist: "Artist", albumTitle: "Album", duration: 120)
        ]
        let session = PlaybackSession()
        let audio = AudioPlayerSpy()
        let events = PlaybackEventSpy()

        LoadQueueUseCase(session: session, events: events).execute(tracks: tracks)
        PlayUseCase(session: session, audio: audio, events: events).execute()

        XCTAssertEqual(audio.playedTracks, [tracks[0]])
        XCTAssertEqual(events.startedTracks, [tracks[0]])
    }

    func testPauseUseCaseDoesNothingWhenIdle() {
        let session = PlaybackSession()
        let audio = AudioPlayerSpy()
        let events = PlaybackEventSpy()

        PauseUseCase(session: session, audio: audio, events: events).execute()

        XCTAssertEqual(audio.pauseCallCount, 0)
        XCTAssertTrue(events.pausedTracks.isEmpty)
    }

    func testNextUseCaseEmitsQueueEndedAndStopsWhenAtEnd() {
        let tracks = [Track(title: "Solo", artist: "Artist", albumTitle: "Album", duration: 220)]
        let session = PlaybackSession()
        let audio = AudioPlayerSpy()
        let events = PlaybackEventSpy()

        LoadQueueUseCase(session: session).execute(tracks: tracks)
        PlayUseCase(session: session, audio: audio).execute()

        NextUseCase(session: session, audio: audio, events: events).execute()

        XCTAssertEqual(audio.stopCallCount, 1)
        XCTAssertEqual(events.queueEndedCount, 1)
    }

    func testPreviousUseCaseAtStartRestartsTrack() {
        let tracks = [
            Track(title: "One", artist: "Artist", albumTitle: "Album", duration: 100),
            Track(title: "Two", artist: "Artist", albumTitle: "Album", duration: 120)
        ]
        let session = PlaybackSession()
        let audio = AudioPlayerSpy()
        let events = PlaybackEventSpy()

        LoadQueueUseCase(session: session).execute(tracks: tracks)
        PlayUseCase(session: session, audio: audio).execute()

        PreviousUseCase(session: session, audio: audio, events: events).execute()

        XCTAssertEqual(audio.playedTracks.last, tracks[0])
        XCTAssertEqual(events.startedTracks.last, tracks[0])
    }

    func testSeekUseCaseIgnoresWhenNoTrack() {
        let session = PlaybackSession()
        let audio = AudioPlayerSpy()
        let events = PlaybackEventSpy()

        SeekUseCase(session: session, audio: audio, events: events).execute(position: 30)

        XCTAssertTrue(audio.seekPositions.isEmpty)
        XCTAssertTrue(events.positionChanges.isEmpty)
    }
}
