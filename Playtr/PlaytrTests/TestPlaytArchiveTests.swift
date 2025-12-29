import XCTest
@testable import Playtr

final class TestPlaytArchiveTests: XCTestCase {
    func testBundledArchiveHasPlayableCartridges() throws {
        let library = PlaytLibrary()
        let cartridgeIDs = try library.listCartridgeIDs(source: .bundledTestArchive)
        XCTAssertFalse(cartridgeIDs.isEmpty, "No cartridges found in bundled archive.")

        for cartridgeID in cartridgeIDs {
            let cartridge = try library.loadCartridge(source: .bundledTestArchive, cartridgeID: cartridgeID)
            XCTAssertFalse(cartridge.tracks.isEmpty, "No tracks found for \(cartridgeID).")
            let firstTrack = try XCTUnwrap(cartridge.tracks.first)
            let url = try library.resolveMediaURL(
                source: .bundledTestArchive,
                cartridgeID: cartridgeID,
                relativePath: firstTrack.path
            )
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }

    func testInstallFromBundledToLocalArchive() throws {
        let library = PlaytLibrary()
        let bundledIDs = try library.listCartridgeIDs(source: .bundledTestArchive)
        let cartridgeID = try XCTUnwrap(bundledIDs.first)

        try library.installBundledCartridgeToLocal(cartridgeID: cartridgeID)

        let localIDs = try library.listCartridgeIDs(source: .localArchive)
        XCTAssertTrue(localIDs.contains(cartridgeID))

        let cartridge = try library.loadCartridge(source: .localArchive, cartridgeID: cartridgeID)
        let firstTrack = try XCTUnwrap(cartridge.tracks.first)
        let url = try library.resolveMediaURL(
            source: .localArchive,
            cartridgeID: cartridgeID,
            relativePath: firstTrack.path
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
