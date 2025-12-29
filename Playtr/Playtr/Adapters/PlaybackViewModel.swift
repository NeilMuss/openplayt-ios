import Combine
import Foundation
import SwiftUI

@MainActor
final class PlaybackViewModel: ObservableObject, PlaybackEventSink {
    @Published private(set) var status: PlaybackStatus = .idle
    @Published private(set) var nowPlayingTitle = "No Track"
    @Published private(set) var nowPlayingArtist = ""
    @Published private(set) var position: TimeInterval = 0
    @Published private(set) var volume: Float = 1.0
    @Published private(set) var isQueueEnded = false
    @Published var playbackError: String?

    private let session: PlaybackSession
    private let audio: AudioPlayerPort

    private lazy var loadQueueUseCase = LoadQueueUseCase(session: session, events: self)
    private lazy var playUseCase = PlayUseCase(session: session, audio: audio, events: self)
    private lazy var pauseUseCase = PauseUseCase(session: session, audio: audio, events: self)
    private lazy var stopUseCase = StopUseCase(session: session, audio: audio, events: self)
    private lazy var nextUseCase = NextUseCase(session: session, audio: audio, events: self)
    private lazy var previousUseCase = PreviousUseCase(session: session, audio: audio, events: self)
    private lazy var seekUseCase = SeekUseCase(session: session, audio: audio, events: self)
    private lazy var setVolumeUseCase = SetVolumeUseCase(audio: audio, events: self)

    init(session: PlaybackSession, audio: AudioPlayerPort) {
        self.session = session
        self.audio = audio
        if let localAudio = audio as? LocalAudioPlayer {
            localAudio.errorHandler = { [weak self] message in
                Task { @MainActor in
                    self?.playbackError = message
                }
            }
            localAudio.positionHandler = { [weak self] position in
                Task { @MainActor in
                    self?.position = position
                }
            }
            localAudio.completionHandler = { [weak self] in
                Task { @MainActor in
                    self?.next()
                }
            }
        }
        loadSampleQueue()
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    convenience init() {
        self.init(session: PlaybackSession(), audio: LocalAudioPlayer())
    }

    var isPlaying: Bool {
        status == .playing
    }

    func togglePlayPause() {
        if status == .playing {
            pauseUseCase.execute()
        } else {
            playUseCase.execute()
        }
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    func next() {
        nextUseCase.execute()
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    func previous() {
        previousUseCase.execute()
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    func stop() {
        stopUseCase.execute()
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    func seek(to newPosition: TimeInterval) {
        seekUseCase.execute(position: newPosition)
        refreshFromSession(fallbackTrack: session.machine.queue.currentTrack)
    }

    func setVolume(_ newVolume: Float) {
        setVolumeUseCase.execute(volume: newVolume)
    }

    func loadSampleQueue() {
        let tracks = [
            Track(title: "Open", artist: "Playt", albumTitle: "Demo", duration: 210),
            Track(title: "Loop", artist: "Playt", albumTitle: "Demo", duration: 185),
            Track(title: "Close", artist: "Playt", albumTitle: "Demo", duration: 200)
        ]
        loadQueueUseCase.execute(tracks: tracks)
        refreshFromSession(fallbackTrack: tracks.first)
    }

    func loadArchiveQueue(from cartridge: PlaytArchiveCartridge) {
        playbackError = nil
        let tracks = cartridge.tracks.map { track in
            Track(
                title: track.title,
                artist: cartridge.artist,
                albumTitle: cartridge.title,
                duration: 0,
                trackNumber: track.number,
                relativePath: track.path,
                cartridgeID: cartridge.cartridgeID,
                archiveSource: cartridge.source
            )
        }
        loadQueueUseCase.execute(tracks: tracks)
        refreshFromSession(fallbackTrack: tracks.first)
    }

    private func refreshFromSession(fallbackTrack: Track?) {
        status = session.machine.state.status
        let newPosition = session.machine.state.position
        if newPosition > 0 || position == 0 || status == .idle || status == .stopped {
            position = newPosition
        }
        volume = min(max(volume, 0), 1)

        if let track = session.machine.state.currentTrack ?? fallbackTrack {
            nowPlayingTitle = track.title
            nowPlayingArtist = "\(track.artist) • \(track.albumTitle)"
        } else {
            nowPlayingTitle = "No Track"
            nowPlayingArtist = ""
        }
    }

    func queueLoaded(_ tracks: [Track]) {
        isQueueEnded = false
        refreshFromSession(fallbackTrack: tracks.first)
    }

    func trackStarted(_ track: Track) {
        isQueueEnded = false
        let wasPaused = status == .paused
        status = .playing
        if !wasPaused {
            position = 0
        }
        playbackError = nil
        nowPlayingTitle = track.title
        nowPlayingArtist = "\(track.artist) • \(track.albumTitle)"
    }

    func trackPaused(_ track: Track) {
        status = .paused
        nowPlayingTitle = track.title
        nowPlayingArtist = "\(track.artist) • \(track.albumTitle)"
    }

    func trackStopped(_ track: Track) {
        status = .stopped
        nowPlayingTitle = track.title
        nowPlayingArtist = "\(track.artist) • \(track.albumTitle)"
    }

    func queueDidEnd() {
        isQueueEnded = true
        status = .stopped
    }

    func positionChanged(_ position: TimeInterval) {
        self.position = position
    }

    func volumeChanged(_ volume: Float) {
        self.volume = min(max(volume, 0), 1)
    }
}
