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
        let tabBarButton = app.tabBars.buttons["Explorar"]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
        } else {
            app.buttons["Explorar"].firstMatch.tap()
        }
        _ = app.buttons["chip.Todos"].waitForExistence(timeout: 3)
    }

    private func openHome(_ app: XCUIApplication) {
        let tabBarButton = app.tabBars.buttons["Início"]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
        } else {
            app.buttons["Início"].firstMatch.tap()
        }
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
