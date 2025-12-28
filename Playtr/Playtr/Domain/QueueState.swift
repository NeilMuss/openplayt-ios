import Foundation

struct QueueState: Equatable {
    private(set) var tracks: [Track]
    private(set) var currentIndex: Int?

    init(tracks: [Track] = [], currentIndex: Int? = nil) {
        self.tracks = tracks
        self.currentIndex = currentIndex
    }

    var currentTrack: Track? {
        guard let currentIndex, tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    var isAtStart: Bool {
        currentIndex == 0
    }

    var isAtEnd: Bool {
        guard let currentIndex else { return false }
        return currentIndex == tracks.count - 1
    }

    mutating func reset(with tracks: [Track]) {
        self.tracks = tracks
        currentIndex = tracks.isEmpty ? nil : 0
    }

    mutating func advance() -> Bool {
        guard let currentIndex else { return false }
        let nextIndex = currentIndex + 1
        guard tracks.indices.contains(nextIndex) else { return false }
        self.currentIndex = nextIndex
        return true
    }

    mutating func retreat() -> Bool {
        guard let currentIndex else { return false }
        let previousIndex = currentIndex - 1
        guard tracks.indices.contains(previousIndex) else { return false }
        self.currentIndex = previousIndex
        return true
    }
}
