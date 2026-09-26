import XCTest
import UIKit

final class MusicasParaEstudarScreenshots: XCTestCase {
    func testCaptureStoreScreens() {
        let app = XCUIApplication()
        app.launch()

        capture(app, name: "musicas-para-estudar-home")

        openExplore(app)
        capture(app, name: "musicas-para-estudar-explorar")

        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        // XCTest routes nested horizontal taps through the split-view sidebar on iPad.
        if isPhone {
            let bachFilter = app.buttons["composer.bach"]
            XCTAssertTrue(bachFilter.waitForExistence(timeout: 4))
            bachFilter.tap()
            capture(app, name: "musicas-para-estudar-composer-bach-selected")

            XCTAssertEqual(bachFilter.value as? String, "Selecionado")
            XCTAssertTrue(app.buttons["track.barroco__j_s_bach_goldberg_variations"].waitForExistence(timeout: 4))
            XCTAssertFalse(app.buttons["track.piano_dormir__claude_debussy_clair_de_lune"].exists)

            bachFilter.tap()
            XCTAssertTrue(app.buttons["track.piano_dormir__claude_debussy_clair_de_lune"].waitForExistence(timeout: 4))

            let artworkMode = app.segmentedControls["explore.artwork.mode"]
            XCTAssertTrue(artworkMode.waitForExistence(timeout: 4))
            artworkMode.buttons["Instrumentos"].tap()
            XCTAssertTrue(app.buttons["instrument.GrandPiano"].waitForExistence(timeout: 4))
            capture(app, name: "musicas-para-estudar-instrumentos")

            openSection(app, "Foco")
            XCTAssertTrue(app.buttons["focus.object.BooksStack"].waitForExistence(timeout: 4))
            capture(app, name: "musicas-para-estudar-foco")
        }

        openSection(app, "Biblioteca")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["donation.section"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["donation.restore"].waitForExistence(timeout: 4))

        openHome(app)
        let hero = app.buttons["hero.play"]
        XCTAssertTrue(hero.waitForExistence(timeout: 4))
        hero.tap()
        let playerToggle = app.buttons["player.toggle"]
        XCTAssertTrue(playerToggle.waitForExistence(timeout: 4))
        XCTAssertEqual(playerToggle.label, "Pausar", "Player screenshot should show a bundled recording playing")
        let elapsedTime = app.staticTexts.matching(
            NSPredicate(format: "label MATCHES %@", "0:0[1-9]|0:[1-9][0-9]")
        ).firstMatch
        XCTAssertTrue(elapsedTime.waitForExistence(timeout: 8), "Wait for real playback time before capturing the player")
        capture(app, name: "musicas-para-estudar-player")
        if isPhone {
            verifyPlayerArtworkControls(app)
        }

        let closePlayer = app.buttons["player.dismiss"]
        XCTAssertTrue(closePlayer.waitForExistence(timeout: 4))
        closePlayer.tap()

        let miniPlayer = app.buttons["miniplayer.open"]
        XCTAssertTrue(miniPlayer.waitForExistence(timeout: 4))
        XCTAssertTrue(miniPlayer.isHittable)
        capture(app, name: "musicas-para-estudar-mini-player")

        if isPhone {
            for tab in ["Início", "Explorar", "Foco", "Biblioteca"] {
                XCTAssertTrue(app.tabBars.buttons[tab].isHittable, "Tab bar item overlapped: \(tab)")
            }
        }
    }

    private func openExplore(_ app: XCUIApplication) {
        openSection(app, "Explorar")
        _ = app.buttons["chip.Todos"].waitForExistence(timeout: 3)
    }

    private func openHome(_ app: XCUIApplication) {
        openSection(app, "Início")
    }

    private func verifyPlayerArtworkControls(_ app: XCUIApplication) {
        for identifier in [
            "player.shuffle", "player.previous", "player.next", "player.repeat",
            "player.volume", "player.favorite", "player.queue.add", "player.more"
        ] {
            XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 3), "Missing player control: \(identifier)")
        }

        let shuffle = app.buttons["player.shuffle"]
        shuffle.tap()
        XCTAssertEqual(shuffle.value as? String, "Ativado")
        shuffle.tap()

        let repeatControl = app.buttons["player.repeat"]
        repeatControl.tap()
        XCTAssertEqual(repeatControl.value as? String, "Ativado")
        repeatControl.tap()

        let volume = app.buttons["player.volume"]
        volume.tap()
        XCTAssertEqual(volume.value as? String, "Ativado")
        volume.tap()

        let favorite = app.buttons["player.favorite"]
        favorite.tap()
        XCTAssertEqual(favorite.value as? String, "Favorito")
        favorite.tap()

        let queue = app.buttons["player.queue.add"]
        queue.tap()
        XCTAssertEqual(queue.value as? String, "Ativado")
        queue.tap()
    }

    private func openSection(_ app: XCUIApplication, _ name: String) {
        let tabBarButton = app.tabBars.buttons[name]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
            return
        }
        let cell = app.cells.containing(.staticText, identifier: name).firstMatch
        if cell.waitForExistence(timeout: 3) {
            cell.tap()
            return
        }
        let text = app.staticTexts[name].firstMatch
        if text.waitForExistence(timeout: 3) {
            text.tap()
        }
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
