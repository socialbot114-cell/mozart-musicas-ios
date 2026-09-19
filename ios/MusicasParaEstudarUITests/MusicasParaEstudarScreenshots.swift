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

    private func openExplore(_ app: XCUIApplication) {
        openSection(app, "Explorar")
        _ = app.buttons["chip.Todos"].waitForExistence(timeout: 3)
    }

    private func openHome(_ app: XCUIApplication) {
        openSection(app, "Início")
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
