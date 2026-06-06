//
//  LoginUITest.swift
//  ActifitUITests
//
//  Drives the login screen with credentials supplied via the test runner's
//  environment (ACTIFIT_USER / ACTIFIT_KEY, injected from GitHub secrets as
//  TEST_RUNNER_ACTIFIT_*). Captures a screenshot of the resulting screen.
//

import XCTest

final class LoginUITest: XCTestCase {

    func testLoginFlow() {
        continueAfterFailure = true

        let app = XCUIApplication()
        app.launch()

        // The app asks for Photo Library access at launch — dismiss it.
        dismissSpringboardAlert()

        let username = ProcessInfo.processInfo.environment["ACTIFIT_USER"] ?? ""
        let postingKey = ProcessInfo.processInfo.environment["ACTIFIT_KEY"] ?? ""
        XCTAssertFalse(username.isEmpty, "ACTIFIT_USER was not provided to the test runner")
        XCTAssertFalse(postingKey.isEmpty, "ACTIFIT_KEY was not provided to the test runner")

        // Username — the first (non-secure) text field on the login screen.
        let userField = app.textFields.firstMatch
        XCTAssertTrue(userField.waitForExistence(timeout: 30), "Username field not found")
        userField.tap()
        userField.typeText(username)

        // Posting key — a secure field (it has a show/hide toggle).
        let keyField = app.secureTextFields.firstMatch.exists
            ? app.secureTextFields.firstMatch
            : app.textFields.element(boundBy: 1)
        XCTAssertTrue(keyField.waitForExistence(timeout: 5), "Posting key field not found")
        keyField.tap()
        keyField.typeText(postingKey)

        // Capture the filled-in login screen (key field is masked, so safe).
        attachScreenshot(named: "01-login-filled")

        // Tap PROCEED (fall back to a fuzzy match if the label differs).
        let proceed = app.buttons["PROCEED"]
        if proceed.waitForExistence(timeout: 5) {
            proceed.tap()
        } else {
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'proceed'")).firstMatch.tap()
        }

        // A second permission prompt (e.g. notifications) may follow login.
        dismissSpringboardAlert()

        // Allow the backend login call + UI transition to settle.
        sleep(15)
        dismissSpringboardAlert()

        // Resulting screen: dashboard on success, or an error alert on failure.
        attachScreenshot(named: "02-after-login")
    }

    // MARK: - Helpers

    private func dismissSpringboardAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        guard springboard.alerts.firstMatch.waitForExistence(timeout: 8) else { return }
        let preferred = ["Allow Full Access", "Allow While Using App", "Allow",
                         "OK", "Don’t Allow", "Don't Allow"]
        for label in preferred where springboard.alerts.buttons[label].exists {
            springboard.alerts.buttons[label].tap()
            return
        }
        springboard.alerts.buttons.firstMatch.tap()
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
