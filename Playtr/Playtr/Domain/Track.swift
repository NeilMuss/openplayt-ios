import Foundation

struct Track: Equatable, Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let albumTitle: String
    let duration: TimeInterval
    let trackNumber: Int?
    let relativePath: String?
    let cartridgeID: String?
    let archiveSource: ArchiveSource?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        albumTitle: String,
        duration: TimeInterval,
        trackNumber: Int? = nil,
        relativePath: String? = nil,
        cartridgeID: String? = nil,
        archiveSource: ArchiveSource? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.duration = duration
        self.trackNumber = trackNumber
        self.relativePath = relativePath
        self.cartridgeID = cartridgeID
        self.archiveSource = archiveSource
    }
}
