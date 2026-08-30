import XCTest

final class StyleDetailLayoutUITests: XCTestCase {
    func testAllSaisonMetricsAreVisibleWithoutScrolling() {
        let app = XCUIApplication()
        app.launchEnvironment["STYLE_DETAIL_PREVIEW_ID"] = "bjcp-25B"
        app.launch()

        for label in ["IBU", "Original gravity", "Final gravity", "ABV", "SRM"] {
            let metric = app.staticTexts[label]
            XCTAssertTrue(metric.waitForExistence(timeout: 8), "Missing \(label) metric")
            XCTAssertTrue(metric.isHittable, "\(label) is outside the visible metric area")
        }
    }
}
