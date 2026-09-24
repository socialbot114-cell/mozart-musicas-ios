import XCTest

final class MusicasParaEstudarScreenshots: XCTestCase {
    func testCaptureStoreScreens() {
        let app = XCUIApplication()
        app.launch()

        capture(app, name: "musicas-para-estudar-home")

        openExplore(app)
        capture(app, name: "musicas-para-estudar-explorar")

        openHome(app)
        let hero = app.buttons["hero.play"]
        if hero.waitForExistence(timeout: 4) {
            hero.tap()
            if app.buttons["player.toggle"].waitForExistence(timeout: 4) {
                capture(app, name: "musicas-para-estudar-player")
            }
        }
    }

    func testComposerFilterShowsMatchingWorksAndClears() {
        let app = XCUIApplication()
        app.launch()
        openExplore(app)

        let bachFilter = app.buttons["composer.bach"]
        XCTAssertTrue(bachFilter.waitForExistence(timeout: 4))
        bachFilter.tap()
        capture(app, name: "musicas-para-estudar-composer-bach-selected")

        XCTAssertEqual(bachFilter.value as? String, "Selecionado")
        XCTAssertTrue(app.buttons["track.barroco__j_s_bach_goldberg_variations"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["track.piano_dormir__claude_debussy_clair_de_lune"].exists)

        bachFilter.tap()
        XCTAssertTrue(app.buttons["track.piano_dormir__claude_debussy_clair_de_lune"].waitForExistence(timeout: 4))
    }

    private func openExplore(_ app: XCUIApplication) {
        openSection(app, "Explorar")
        let allCategories = app.buttons["chip.Todos"]
        XCTAssertTrue(allCategories.waitForExistence(timeout: 5))
        XCTAssertTrue(allCategories.isHittable)
    }

    private func openHome(_ app: XCUIApplication) {
        openSection(app, "Início")
    }

    private func openSection(_ app: XCUIApplication, _ name: String) {
        let tabBarButton = app.tabBars.buttons[name]
        if tabBarButton.waitForExistence(timeout: 3), tabBarButton.isHittable {
            tabBarButton.tap()
            return
        }
        let cell = app.cells.containing(.staticText, identifier: name).firstMatch
        if cell.waitForExistence(timeout: 3), cell.isHittable {
            cell.tap()
            XCTAssertTrue(cell.isSelected, "The iPad sidebar should select \(name)")
            return
        }
        let text = app.staticTexts[name].firstMatch
        if text.waitForExistence(timeout: 3), text.isHittable {
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
