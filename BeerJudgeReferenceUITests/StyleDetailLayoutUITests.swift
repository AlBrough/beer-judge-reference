import XCTest

final class StyleDetailLayoutUITests: XCTestCase {
    @MainActor
    func testAllSaisonMetricsAreVisibleWithoutScrolling() {
        let app = XCUIApplication()
        app.launchEnvironment["STYLE_DETAIL_PREVIEW_ID"] = "bjcp-25B"
        app.launch()

        let expectedText = [
            "IBU", "20–35",
            "Original gravity", "1.048–1.065",
            "Final gravity", "1.002–1.008",
            "ABV", "3.5–9.5%",
            "SRM", "5–22"
        ]

        for text in expectedText {
            let metricText = app.staticTexts[text]
            XCTAssertTrue(metricText.waitForExistence(timeout: 8), "Missing metric text: \(text)")
            XCTAssertTrue(metricText.isHittable, "Metric text is outside the visible area: \(text)")
        }
    }
}
