import Foundation

struct PlaytArchiveCartridge: Identifiable, Hashable {
    let cartridgeID: String
    let title: String
    let artist: String
    let year: Int?
    let tracks: [PlaytArchiveTrack]
    let source: ArchiveSource

    var id: String { cartridgeID }

    var subtitle: String {
        if let year {
            return "\(artist) • \(year)"
        }
        return artist
    }
}

struct PlaytArchiveTrack: Identifiable, Hashable, Codable {
    let number: Int
    let title: String
    let path: String

    var id: String { "\(number)-\(title)" }
}
