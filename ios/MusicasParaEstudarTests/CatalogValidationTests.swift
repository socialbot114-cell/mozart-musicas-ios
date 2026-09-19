import XCTest
@testable import MusicasParaEstudar

final class CatalogValidationTests: XCTestCase {
    func testPreviewCatalogHasNoPlayableTracks() throws {
        let catalog = try PreviewCatalogRepository().load()
        XCTAssertTrue(catalog.tracks.isEmpty)
        XCTAssertEqual(catalog.product.appStoreId, "6813681353")
        XCTAssertEqual(catalog.product.bundleId, "br.com.musicaspara.estudar")
    }

    func testCatalogResourceIsPackagedAtExpectedPath() throws {
        let catalog = try BundleCatalogRepository().load()
        XCTAssertEqual(catalog.schemaVersion, 1)
        XCTAssertFalse(catalog.tracks.isEmpty)
        for track in catalog.tracks {
            let value = try XCTUnwrap(track.audioPath)
            let path = try XCTUnwrap(BundleResourcePath(value))
            XCTAssertNotNil(path.url(in: .main), "Missing bundled resource: \(value)")
        }
    }

    func testAudioPathMapsToPreservedBundleDirectory() throws {
        let path = try XCTUnwrap(BundleResourcePath("Audio/example.recording.mp3"))
        XCTAssertEqual(path.name, "example.recording")
        XCTAssertEqual(path.fileExtension, "mp3")
        XCTAssertEqual(path.subdirectory, "Audio")
        XCTAssertNil(BundleResourcePath("../Audio/example.mp3"))
    }

    func testUnapprovedTrackCannotBePlayed() async {
        let service = await PlaybackService()
        let track = Track(id: "unverified", composer: "Wolfgang Amadeus Mozart", work: "Unknown", recording: "Unknown", rightsStatus: "unverified", audioPath: "Audio/missing.mp3", sourceUrl: nil, sha256: nil, license: nil, blockedReason: "unverified")
        await service.play(track)
        let playing = await service.isPlaying
        XCTAssertFalse(playing)
    }
}
