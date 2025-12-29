import Foundation

final class PlaytLibrary {
    static let shared = PlaytLibrary()

    private let fileManager: FileManager
    private let bundle: Bundle

    init(fileManager: FileManager = .default, bundle: Bundle = .main) {
        self.fileManager = fileManager
        self.bundle = bundle
    }

    func archiveRootURL(for source: ArchiveSource) throws -> URL {
        switch source {
        case .bundledTestArchive:
            guard let url = bundle.url(
                forResource: "TestPlaytArchive",
                withExtension: nil,
                subdirectory: "TestAssets"
            ) else {
                throw PlaytLibraryError.missingBundledArchive
            }
            return url
        case .localArchive:
            guard let baseURL = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                throw PlaytLibraryError.missingLocalArchiveRoot
            }
            let rootURL = baseURL.appendingPathComponent("PlaytArchive", isDirectory: true)
            try ensureDirectory(rootURL)
            return rootURL
        }
    }

    func listCartridgeIDs(source: ArchiveSource) throws -> [String] {
        let cartridgesURL = try cartridgesFolderURL(source: source)
        let contents = try fileManager.contentsOfDirectory(
            at: cartridgesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        let ids = contents.compactMap { url -> String? in
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else {
                return nil
            }
            return url.lastPathComponent
        }
        return ids.sorted()
    }

    func cartridgeFolderURL(source: ArchiveSource, cartridgeID: String) throws -> URL {
        return try cartridgesFolderURL(source: source)
            .appendingPathComponent(cartridgeID, isDirectory: true)
    }

    func playtJSONURL(source: ArchiveSource, cartridgeID: String) throws -> URL {
        return try cartridgeFolderURL(source: source, cartridgeID: cartridgeID)
            .appendingPathComponent("playt.json", isDirectory: false)
    }

    func resolveMediaURL(
        source: ArchiveSource,
        cartridgeID: String,
        relativePath: String
    ) throws -> URL {
        let trimmed = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw PlaytLibraryError.invalidRelativePath(relativePath)
        }
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            throw PlaytLibraryError.invalidRelativePath(relativePath)
        }
        let components = trimmed.split(separator: "/")
        if components.contains("..") {
            throw PlaytLibraryError.invalidRelativePath(relativePath)
        }

        let baseURL = try cartridgeFolderURL(source: source, cartridgeID: cartridgeID)
        let mediaURL = baseURL.appendingPathComponent(trimmed)
        let standardizedBase = baseURL.standardizedFileURL
        let standardizedMedia = mediaURL.standardizedFileURL
        guard standardizedMedia.path.hasPrefix(standardizedBase.path) else {
            throw PlaytLibraryError.invalidRelativePath(relativePath)
        }
        guard fileManager.fileExists(atPath: standardizedMedia.path) else {
            throw PlaytLibraryError.missingMediaFile(standardizedMedia)
        }
        return standardizedMedia
    }

    func loadCartridge(source: ArchiveSource, cartridgeID: String) throws -> PlaytArchiveCartridge {
        let url = try playtJSONURL(source: source, cartridgeID: cartridgeID)
        guard fileManager.fileExists(atPath: url.path) else {
            throw PlaytLibraryError.missingPlaytJSON(url)
        }
        let data = try Data(contentsOf: url)
        let payload = try JSONDecoder().decode(PlaytArchiveCartridgePayload.self, from: data)
        return PlaytArchiveCartridge(
            cartridgeID: payload.cartridgeID,
            title: payload.title,
            artist: payload.artist,
            year: payload.year,
            tracks: payload.tracks,
            source: source
        )
    }

    func installBundledCartridgeToLocal(cartridgeID: String) throws {
        let sourceURL = try cartridgeFolderURL(source: .bundledTestArchive, cartridgeID: cartridgeID)
        let targetURL = try cartridgeFolderURL(source: .localArchive, cartridgeID: cartridgeID)
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try ensureDirectory(targetURL.deletingLastPathComponent())
        try fileManager.copyItem(at: sourceURL, to: targetURL)
    }

    private func cartridgesFolderURL(source: ArchiveSource) throws -> URL {
        let rootURL = try archiveRootURL(for: source)
        let cartridgesURL = rootURL.appendingPathComponent("cartridges", isDirectory: true)
        if source == .localArchive {
            try ensureDirectory(cartridgesURL)
        }
        return cartridgesURL
    }

    private func ensureDirectory(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            return
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

struct PlaytArchiveCartridgePayload: Codable {
    let cartridgeID: String
    let title: String
    let artist: String
    let year: Int?
    let tracks: [PlaytArchiveTrack]

    enum CodingKeys: String, CodingKey {
        case cartridgeID = "cartridge_id"
        case title
        case artist
        case year
        case tracks
    }
}

enum PlaytLibraryError: LocalizedError {
    case missingBundledArchive
    case missingLocalArchiveRoot
    case missingPlaytJSON(URL)
    case invalidRelativePath(String)
    case missingMediaFile(URL)

    var errorDescription: String? {
        switch self {
        case .missingBundledArchive:
            return "Bundled TestPlaytArchive is missing."
        case .missingLocalArchiveRoot:
            return "Local PlaytArchive root could not be created."
        case .missingPlaytJSON(let url):
            return "Missing playt.json at \(url.path)."
        case .invalidRelativePath(let path):
            return "Invalid media path: \(path)"
        case .missingMediaFile(let url):
            return "Missing media file at \(url.path)."
        }
    }
}
