import Foundation

enum TestPlaytArchive {
    private final class BundleToken {}

    static func bundledArchiveRootURL() -> URL {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(
            forResource: "TestPlaytArchive",
            withExtension: nil,
            subdirectory: "TestAssets"
        ) else {
            preconditionFailure("TestPlaytArchive not found in bundle resources.")
        }
        return url
    }

    static func listCartridgeIDs() throws -> [String] {
        let rootURL = bundledArchiveRootURL()
        let cartridgesURL = rootURL.appendingPathComponent("cartridges", isDirectory: true)
        let contents = try FileManager.default.contentsOfDirectory(
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

    static func loadPlaytJSON(cartridgeID: String) throws -> Data {
        let rootURL = bundledArchiveRootURL()
        let playtURL = rootURL
            .appendingPathComponent("cartridges", isDirectory: true)
            .appendingPathComponent(cartridgeID, isDirectory: true)
            .appendingPathComponent("playt.json", isDirectory: false)
        return try Data(contentsOf: playtURL)
    }
}
