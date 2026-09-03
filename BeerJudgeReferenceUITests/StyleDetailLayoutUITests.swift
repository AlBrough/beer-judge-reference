import XCTest

final class StyleDetailLayoutUITests: XCTestCase {
    @MainActor
    func testIPACategoryIsUppercase() {
        let app = XCUIApplication()
        app.launchEnvironment["STYLE_DETAIL_PREVIEW_ID"] = "bjcp-21A"
        app.launch()

        XCTAssertTrue(app.staticTexts["IPA"].waitForExistence(timeout: 8), "IPA category was not uppercase")
        XCTAssertFalse(app.staticTexts["Ipa"].exists, "Sentence-cased IPA category was displayed")
    }

    @MainActor
    func testAllSaisonMetricsAreVisibleWithoutScrolling() {
        let app = XCUIApplication()
        app.launchEnvironment["STYLE_DETAIL_PREVIEW_ID"] = "bjcp-25B"
        app.launch()

        let expectedText = [
            "IBU", "20 - 35",
            "Original gravity", "1.048 - 1.065",
            "Final gravity", "1.002 - 1.008",
            "ABV", "3.5 - 9.5%",
            "SRM", "5 - 22"
        ]

        for text in expectedText {
            let metricText = app.staticTexts[text]
            XCTAssertTrue(metricText.waitForExistence(timeout: 8), "Missing metric text: \(text)")
            XCTAssertTrue(metricText.isHittable, "Metric text is outside the visible area: \(text)")
        }
    }

    @MainActor
    func testComparePickerSearchFindsSaison() {
        let app = XCUIApplication()
        app.launchEnvironment["APP_PREVIEW_ROUTE"] = "compare-picker"
        app.launch()

        let search = app.searchFields["Search by code or style"]
        XCTAssertTrue(search.waitForExistence(timeout: 8), "Compare style search is unavailable")
        search.tap()
        search.typeText("Saison")

        XCTAssertTrue(app.staticTexts["Saison"].waitForExistence(timeout: 3), "Saison was not found")
        XCTAssertFalse(app.staticTexts["Altbier"].exists, "Compare search did not filter unrelated styles")
    }

    @MainActor
    func testSettingsThemeCanChangeToOcean() {
        let app = XCUIApplication()
        app.launchEnvironment["APP_PREVIEW_ROUTE"] = "settings"
        app.launch()

        let themeMenu = app.buttons["colour-theme-menu"]
        XCTAssertTrue(themeMenu.waitForExistence(timeout: 8), "Colour theme menu is unavailable")
        themeMenu.tap()
        app.buttons["Ocean"].tap()

        XCTAssertTrue(themeMenu.label.contains("Ocean"), "Ocean was not shown as the selected theme")
    }
}
