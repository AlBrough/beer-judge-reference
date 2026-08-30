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
}
