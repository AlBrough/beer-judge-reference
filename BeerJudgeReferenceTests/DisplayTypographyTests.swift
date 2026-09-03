import XCTest
@testable import BeerJudgeReference

final class DisplayTypographyTests: XCTestCase {
    func testIPAIsAlwaysUppercase() {
        XCTAssertEqual(DisplayTypography.uppercaseInitialisms(in: "Ipa"), "IPA")
        XCTAssertEqual(DisplayTypography.uppercaseInitialisms(in: "Specialty ipa"), "Specialty IPA")
        XCTAssertEqual(DisplayTypography.uppercaseInitialisms(in: "American IPA"), "American IPA")
    }

    func testMetricRangesUseSpacedASCIIHyphen() {
        XCTAssertEqual(DisplayTypography.spacedRange("15-20"), "15 - 20")
        XCTAssertEqual(DisplayTypography.spacedRange("15\u{2013}20"), "15 - 20")
        XCTAssertEqual(DisplayTypography.spacedRange("15 \u{2014} 20"), "15 - 20")
    }

    func testGuidelineProseUsesSpacedASCIIHyphen() {
        XCTAssertEqual(
            DisplayTypography.asciiDashes(in: "fruity\u{2013}spicy and dry \u{2014} very dry"),
            "fruity - spicy and dry - very dry"
        )
    }
}
