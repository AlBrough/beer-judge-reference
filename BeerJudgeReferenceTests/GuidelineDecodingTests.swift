import XCTest
@testable import BeerJudgeReference

final class GuidelineDecodingTests: XCTestCase {
    func testBundledManifestDeclaresBothProviders() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "guidelines-manifest", withExtension: "json"))
        let manifest = try JSONDecoder().decode(GuidelineManifest.self, from: Data(contentsOf: url))
        XCTAssertEqual(Set(manifest.datasets.map(\.providerID)), Set(["bjcp", "ba"]))
    }

    func testBundledDatasetsHaveUniqueStylesAndUsefulContent() throws {
        let manifestURL = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "guidelines-manifest", withExtension: "json"))
        let manifest = try JSONDecoder().decode(GuidelineManifest.self, from: Data(contentsOf: manifestURL))
        for descriptor in manifest.datasets {
            let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: descriptor.localResource, withExtension: "json"))
            let dataset = try JSONDecoder().decode(GuidelineDataset.self, from: Data(contentsOf: url))
            XCTAssertGreaterThan(dataset.styles.count, 100)
            XCTAssertEqual(Set(dataset.styles.map(\.id)).count, dataset.styles.count)
            XCTAssertTrue(dataset.styles.allSatisfy { !$0.name.isEmpty && !$0.category.isEmpty })
        }
    }

    func testBJCPBrowseOrderFollowsCategoryAndSubcategoryCodes() throws {
        let dataset = try bundledDataset(named: "bjcp-2021")
        let categories = GuidelineOrdering.categories(from: dataset.styles)

        XCTAssertEqual(Array(categories.prefix(5).map(\.number)), ["1", "2", "3", "4", "5"])
        XCTAssertEqual(categories.first?.name, "Standard American Beer")
        XCTAssertEqual(categories.first?.styles.map(\.number), ["1A", "1B", "1C", "1D"])
        XCTAssertEqual(categories.last?.number, "X")
    }

    func testBABrowseOrderPreservesPublishedTopLevelSequence() throws {
        let dataset = try bundledDataset(named: "ba-2026")
        let categories = GuidelineOrdering.categories(from: dataset.styles)

        XCTAssertEqual(
            categories.map(\.number),
            ["Ale Styles", "Lager Styles", "Hybrid/Mixed Lagers or Ale"]
        )
    }

    private func bundledDataset(named resource: String) throws -> GuidelineDataset {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: resource, withExtension: "json"))
        return try JSONDecoder().decode(GuidelineDataset.self, from: Data(contentsOf: url))
    }
}
