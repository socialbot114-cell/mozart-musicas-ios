import XCTest

final class MusicasParaEstudarScreenshots: XCTestCase {
    func testCaptureStoreScreens() {
        let app = XCUIApplication()
        app.launch()

        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "musicas-para-estudar-home"
        home.lifetime = .keepAlways
        add(home)

        if app.tabBars.buttons["Explorar"].waitForExistence(timeout: 3) {
            app.tabBars.buttons["Explorar"].tap()
            let explore = XCTAttachment(screenshot: app.screenshot())
            explore.name = "musicas-para-estudar-explorar"
            explore.lifetime = .keepAlways
            add(explore)
        }
    }
}
