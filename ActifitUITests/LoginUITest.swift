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

        // ---- Main tab sections ----
        let tabs = ["History", "Social", "Leaderboard", "Settings", "Dashboard"]
        for (i, tab) in tabs.enumerated() {
            guard tapByLabel(tab) else {
                NSLog("ACTIFIT_WALK: tab '\(tab)' not found")
                continue
            }
            sleep(3)
            screenshot(String(format: "2%d-tab-%@", i, tab.lowercased()))
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

        // Top dashboard icons (no labels) — target by coordinate, as fractions of
        // the screen read from the 393x852 dashboard screenshot.
        let coordIcons: [(name: String, x: Double, y: Double)] = [
            ("40-profile",        0.076, 0.088),
            ("41-notifications",  0.737, 0.095),
            ("42-wallet",         0.895, 0.095),
            ("43-tracking-gauge", 0.737, 0.144),
        ]
        for icon in coordIcons {
            returnToDashboard()
            tapAt(icon.x, icon.y)
            sleep(3)
            dismissSpringboardAlert()
            screenshot(icon.name)
        }

        // Icon shortcuts that now carry accessibility identifiers (set in the app).
        let idWidgets: [(name: String, id: String)] = [
            ("44-waves",     "waves"),
            ("45-store",     "store"),
            ("46-gift",      "gift"),
            ("47-referrals", "referrals"),
            ("48-stats",     "stats"),
        ]
        for widget in idWidgets {
            returnToDashboard()
            let btn = app.buttons[widget.id]
            if btn.waitForExistence(timeout: 5), btn.isHittable {
                btn.tap()
                sleep(3)
                dismissSpringboardAlert()
                screenshot(widget.name)
            } else {
                NSLog("ACTIFIT_WALK: widget '\(widget.id)' not found/hittable")
                screenshot(widget.name + "-missing")
            }
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

    /// Reliable recovery to the Dashboard from any pushed screen, modal or popup.
    private func returnToDashboard() {
        for _ in 0..<5 {
            if onDashboard() { break }
            dismissModalIfPresent()                 // labelled close buttons (CLOSE/Done/...)
            tapAt(0.865, 0.155)                     // top-right red "X" on custom popups
            if !onDashboard() { tapAt(0.07, 0.088) } // top-left "<" back on pushed screens
            sleep(1)
        }
        _ = tapByLabel("Dashboard")                 // in case the tab bar is visible
        sleep(1)
    }

    /// True only when the Dashboard is actually interactive (POST & EARN hittable).
    /// Using isHittable (not exists) means a modal covering the dashboard counts
    /// as "not on dashboard", so recovery proceeds to dismiss it.
    private func onDashboard() -> Bool {
        app.buttons["POST & EARN"].isHittable
    }

    /// Tap a labelled close button if one is present (cheap direct queries — no
    /// full-hierarchy enumeration, which stalls on this never-idle app).
    private func dismissModalIfPresent() {
        for label in ["CLOSE", "Close", "Done", "OK", "Cancel", "GOT IT!", "Got it", "Dismiss"] {
            let b = app.buttons[label]
            if b.exists && b.isHittable { b.tap(); return }
        }
    }

    private func dismissSpringboardAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        guard springboard.alerts.firstMatch.waitForExistence(timeout: 3) else { return }
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
}
