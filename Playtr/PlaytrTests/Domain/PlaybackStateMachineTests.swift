import XCTest
@testable import Playtr

@MainActor
final class PlaybackStateMachineTests: XCTestCase {
    func testLoadQueueResetsIndexAndClearsCurrentTrack() {
        let initialTracks = [
            Track(title: "Intro", artist: "A", albumTitle: "Alpha", duration: 120),
            Track(title: "Main", artist: "A", albumTitle: "Alpha", duration: 180)
        ]
        let newTracks = [
            Track(title: "Next", artist: "B", albumTitle: "Beta", duration: 200)
        ]

        var machine = PlaybackStateMachine()
        machine.loadQueue(initialTracks)
        _ = machine.play()
        XCTAssertEqual(machine.state.currentTrack, initialTracks[0])

        machine.loadQueue(newTracks)

        XCTAssertEqual(machine.queue.currentIndex, 0)
        XCTAssertNil(machine.state.currentTrack)
        XCTAssertEqual(machine.state.status, .idle)
    }

    func testPlayStartsFirstTrackWhenNoneActive() {
        let tracks = [
            Track(title: "One", artist: "Artist", albumTitle: "Album", duration: 100),
            Track(title: "Two", artist: "Artist", albumTitle: "Album", duration: 140)
        ]

        var machine = PlaybackStateMachine()
        machine.loadQueue(tracks)

        let started = machine.play()

        XCTAssertEqual(started, tracks[0])
        XCTAssertEqual(machine.state.currentTrack, tracks[0])
        XCTAssertEqual(machine.state.status, .playing)
    }

    func testPauseOnlyWhenPlaying() {
        let tracks = [Track(title: "One", artist: "Artist", albumTitle: "Album", duration: 100)]

        var machine = PlaybackStateMachine()
        machine.loadQueue(tracks)

        let pausedWhileIdle = machine.pause()
        XCTAssertNil(pausedWhileIdle)
        XCTAssertEqual(machine.state.status, .idle)

        _ = machine.play()
        let paused = machine.pause()

        XCTAssertEqual(paused, tracks[0])
        XCTAssertEqual(machine.state.status, .paused)
    }

    func testNextAtEndStopsPlaybackAndClearsCurrentTrack() {
        let tracks = [Track(title: "Solo", artist: "Artist", albumTitle: "Album", duration: 220)]

        var machine = PlaybackStateMachine()
        machine.loadQueue(tracks)
        _ = machine.play()

        let result = machine.next()

        XCTAssertEqual(result, .queueEnded)
        XCTAssertEqual(machine.state.status, .stopped)
        XCTAssertNil(machine.state.currentTrack)
    }

    func testPreviousAtStartRestartsCurrentTrack() {
        let tracks = [
            Track(title: "One", artist: "Artist", albumTitle: "Album", duration: 100),
            Track(title: "Two", artist: "Artist", albumTitle: "Album", duration: 140)
        ]

        var machine = PlaybackStateMachine()
        machine.loadQueue(tracks)
        _ = machine.play()
        machine.seek(to: 42)

        let result = machine.previous()

        XCTAssertEqual(result, .restarted(tracks[0]))
        XCTAssertEqual(machine.state.currentTrack, tracks[0])
        XCTAssertEqual(machine.state.status, .playing)
        XCTAssertEqual(machine.state.position, 0)
    }
}
