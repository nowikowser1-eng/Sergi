import XCTest

final class SergiUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app launches and shows onboarding or main screen
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-state"]
        app.launch()

        // The onboarding welcome screen should appear
        let startButton = app.buttons["Начать"]
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
        }
    }
}
