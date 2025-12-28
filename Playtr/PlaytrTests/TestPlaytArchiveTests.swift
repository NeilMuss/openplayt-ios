import XCTest
@testable import Playtr

final class TestPlaytArchiveTests: XCTestCase {
    func testBundledArchiveHasPlayableCartridges() throws {
        let rootURL = TestPlaytArchive.bundledArchiveRootURL()
        let cartridgeIDs = try TestPlaytArchive.listCartridgeIDs()
        XCTAssertFalse(cartridgeIDs.isEmpty, "No cartridges found in TestPlaytArchive.")

        let fileManager = FileManager.default
        for cartridgeID in cartridgeIDs {
            let cartridgeURL = rootURL
                .appendingPathComponent("cartridges", isDirectory: true)
                .appendingPathComponent(cartridgeID, isDirectory: true)
            let playtURL = cartridgeURL.appendingPathComponent("playt.json")
            XCTAssertTrue(fileManager.fileExists(atPath: playtURL.path), "Missing playt.json for \(cartridgeID).")

            let audioURL = cartridgeURL.appendingPathComponent("audio", isDirectory: true)
            let audioFiles = try fileManager.contentsOfDirectory(
                at: audioURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { ["m4a", "mp3"].contains($0.pathExtension.lowercased()) }

            XCTAssertFalse(audioFiles.isEmpty, "No audio tracks found for \(cartridgeID).")
            print("TestPlaytArchive cartridge \(cartridgeID): \(audioFiles.count) track(s)")
        }
    }
}
