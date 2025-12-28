import Foundation

struct Track: Equatable, Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let albumTitle: String
    let duration: TimeInterval

    init(id: UUID = UUID(), title: String, artist: String, albumTitle: String, duration: TimeInterval) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.duration = duration
    }
}
