import XCTest

final class MusicasParaEstudarScreenshots: XCTestCase {
    func testCaptureStoreScreens() {
        let app = XCUIApplication()
        app.launch()

        capture(app, name: "musicas-para-estudar-home")

        let hero = app.buttons["hero.play"]
        if hero.waitForExistence(timeout: 4) {
            hero.tap()
            if app.buttons["player.toggle"].waitForExistence(timeout: 4) {
                capture(app, name: "musicas-para-estudar-player")
                let dismiss = app.buttons["player.dismiss"]
                if dismiss.exists {
                    dismiss.tap()
                }
            }
        }

        openExplore(app)
        capture(app, name: "musicas-para-estudar-explorar")
    }

    private func openExplore(_ app: XCUIApplication) {
        let tabBarButton = app.tabBars.buttons["Explorar"]
        if tabBarButton.waitForExistence(timeout: 3) {
            tabBarButton.tap()
            return
        }
        let sidebarButton = app.buttons["Explorar"].firstMatch
        if sidebarButton.waitForExistence(timeout: 3) {
            sidebarButton.tap()
        }
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
