//
//  LoginUITest.swift
//  ActifitUITests
//
//  Logs in with credentials from the test runner environment
//  (ACTIFIT_USER / ACTIFIT_KEY, injected from GitHub secrets as TEST_RUNNER_*)
//  then walks every main section of the app, capturing a screenshot of each
//  and dumping the accessibility hierarchy to the test log for reference.
//

import XCTest

final class LoginUITest: XCTestCase {

    let app = XCUIApplication()

    func testFullWalkthrough() {
        continueAfterFailure = true

        app.launch()
        dismissSpringboardAlert()

        // ---- Login ----
        let username = env("ACTIFIT_USER")
        let postingKey = env("ACTIFIT_KEY")
        XCTAssertFalse(username.isEmpty, "ACTIFIT_USER not provided to the test runner")
        XCTAssertFalse(postingKey.isEmpty, "ACTIFIT_KEY not provided to the test runner")

        let userField = app.textFields.firstMatch
        XCTAssertTrue(userField.waitForExistence(timeout: 30), "Username field not found")
        userField.tap()
        userField.typeText(username)

        let keyField = app.secureTextFields.firstMatch.exists
            ? app.secureTextFields.firstMatch
            : app.textFields.element(boundBy: 1)
        XCTAssertTrue(keyField.waitForExistence(timeout: 5), "Posting key field not found")
        keyField.tap()
        keyField.typeText(postingKey)

        screenshot("01-login-filled")   // key field is masked -> safe

        tapByLabel("PROCEED")
        dismissSpringboardAlert()
        sleep(15)                        // backend auth + dashboard load
        dismissSpringboardAlert()

        screenshot("10-dashboard")
        dumpHierarchy("dashboard")

        // ---- Main tab sections ----
        let tabs = ["History", "Social", "Leaderboard", "Settings", "Dashboard"]
        for (i, tab) in tabs.enumerated() {
            guard tapByLabel(tab) else {
                NSLog("ACTIFIT_WALK: tab '\(tab)' not found")
                continue
            }
            sleep(4)
            dismissSpringboardAlert()
            screenshot(String(format: "2%d-tab-%@", i, tab.lowercased()))
            dumpHierarchy("tab-\(tab)")
        }

        // ---- Key sub-screens ----
        // Post & Earn (from the Dashboard).
        returnToDashboard()
        if tapByLabel("POST & EARN") || tapByLabel("POST AND EARN") {
            sleep(4)
            dismissSpringboardAlert()
            screenshot("30-post-and-earn")
            goBack()
        }

        // Dashboard icon buttons have no accessibility labels, so target them by
        // coordinate. Offsets are fractions of the screen, read from 10-dashboard.png
        // (the screenshot is the device at exact 393x852 scale).
        let icons: [(name: String, x: Double, y: Double)] = [
            ("40-profile",        0.076, 0.088),
            ("41-notifications",  0.737, 0.095),
            ("42-wallet",         0.895, 0.095),
            ("43-tracking-gauge", 0.737, 0.144),
            ("44-waves",          0.924, 0.358),
            ("45-store-gadgets",  0.570, 0.512),
            ("46-referrals-gift", 0.601, 0.619),
            ("47-add-friend",     0.755, 0.619),
            ("48-stats-chart",    0.910, 0.619),
        ]
        for icon in icons {
            returnToDashboard()
            tapAt(icon.x, icon.y)
            sleep(3)
            dismissSpringboardAlert()
            screenshot(icon.name)
        }

        returnToDashboard()
    }

    // MARK: - Helpers

    private func env(_ key: String) -> String {
        ProcessInfo.processInfo.environment[key] ?? ""
    }

    /// Taps the first hittable element matching `label`, trying tab bars,
    /// buttons, then any descendant. Returns whether something was tapped.
    @discardableResult
    private func tapByLabel(_ label: String) -> Bool {
        let candidates: [XCUIElement] = [
            app.tabBars.buttons[label],
            app.buttons[label],
            app.staticTexts[label],
            app.otherElements[label],
            app.descendants(matching: .any)
                .matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
        ]
        for el in candidates where el.exists && el.isHittable {
            el.tap()
            return true
        }
        return false
    }

    private func goBack() {
        let back = app.navigationBars.buttons.firstMatch
        if back.exists && back.isHittable {
            back.tap()
        } else {
            _ = tapByLabel("Dashboard")
        }
        sleep(1)
    }

    /// Taps a point given as a fraction (0...1) of the screen.
    private func tapAt(_ nx: Double, _ ny: Double) {
        app.coordinate(withNormalizedOffset: CGVector(dx: nx, dy: ny)).tap()
    }

    /// Best-effort recovery to the Dashboard from any pushed screen or modal.
    private func returnToDashboard() {
        dismissSpringboardAlert()
        for label in ["Close", "Cancel", "Done", "SKIP", "Back", "OK", "✕", "X"] {
            let b = app.buttons[label]
            if b.exists && b.isHittable { b.tap(); break }
        }
        let back = app.navigationBars.buttons.firstMatch
        if back.exists && back.isHittable { back.tap() }
        _ = tapByLabel("Dashboard")
        sleep(2)
    }

    private func dismissSpringboardAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        guard springboard.alerts.firstMatch.waitForExistence(timeout: 6) else { return }
        let preferred = ["Allow Full Access", "Allow While Using App", "Allow",
                         "OK", "Don’t Allow", "Don't Allow"]
        for label in preferred where springboard.alerts.buttons[label].exists {
            springboard.alerts.buttons[label].tap()
            return
        }
        springboard.alerts.buttons.firstMatch.tap()
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func dumpHierarchy(_ tag: String) {
        NSLog("ACTIFIT_WALK_HIERARCHY [\(tag)] BEGIN\n\(app.debugDescription)\nACTIFIT_WALK_HIERARCHY [\(tag)] END")
    }
}
