import Foundation

struct PlaytArchiveCartridge: Identifiable, Hashable, Codable {
    let cartridgeID: String
    let title: String
    let artist: String
    let year: Int?
    let tracks: [PlaytArchiveTrack]

    var id: String { cartridgeID }

    var subtitle: String {
        if let year {
            return "\(artist) • \(year)"
        }
        return artist
    }

    enum CodingKeys: String, CodingKey {
        case cartridgeID = "cartridge_id"
        case title
        case artist
        case year
        case tracks
    }
}

struct PlaytArchiveTrack: Identifiable, Hashable, Codable {
    let number: Int
    let title: String
    let path: String

    var id: String { "\(number)-\(title)" }
}
