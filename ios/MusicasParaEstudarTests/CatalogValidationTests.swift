import XCTest
@testable import MusicasParaEstudar

final class CatalogValidationTests: XCTestCase {
    func testPreviewCatalogHasNoPlayableTracks() throws {
        let catalog = try PreviewCatalogRepository().load()
        XCTAssertTrue(catalog.tracks.isEmpty)
        XCTAssertEqual(catalog.product.appStoreId, "6813681353")
        XCTAssertEqual(catalog.product.bundleId, "br.com.musicaspara.estudar")
    }

    func testUnapprovedTrackCannotBePlayed() async {
        let service = await PlaybackService()
        let track = Track(id: "blocked", composer: "Wolfgang Amadeus Mozart", work: "Unknown", recording: "Unknown", rightsStatus: "blocked", audioPath: "missing.mp3", sourceUrl: nil, sha256: nil, license: nil, blockedReason: "unverified")
        await service.play(track)
        let playing = await service.isPlaying
        XCTAssertFalse(playing)
    }
}
