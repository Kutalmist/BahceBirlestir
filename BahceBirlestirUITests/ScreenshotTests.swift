import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.kutican.bahcebirlestir")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-demoMode"]
        app.launch()
    }

    func testScreenshots() {
        snapshot("01-AnaSayfa")

        let seedButton = app.buttons.matching(identifier: "Tohum Kes").firstMatch
        if seedButton.waitForExistence(timeout: 2) {
            seedButton.tap()
            sleep(1)
        }
        snapshot("02-OyunTahtasi")

        let cartButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'cart'")).firstMatch
        if cartButton.waitForExistence(timeout: 2) {
            cartButton.tap()
            sleep(1)
            snapshot("03-Magaza")
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'Kapat' OR label CONTAINS 'Close'")).firstMatch.tap()
            sleep(1)
        }

        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'gear'")).firstMatch
        if settingsButton.waitForExistence(timeout: 2) {
            settingsButton.tap()
            sleep(1)
            snapshot("04-Ayarlar")
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'Kapat' OR label CONTAINS 'Close'")).firstMatch.tap()
            sleep(1)
        }

        snapshot("05-Siparisler")
    }
}
