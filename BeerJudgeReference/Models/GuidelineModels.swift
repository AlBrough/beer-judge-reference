import Foundation

struct GuidelineManifest: Codable {
    let schemaVersion: Int
    let publishedAt: String
    let datasets: [DatasetDescriptor]
}

struct DatasetDescriptor: Codable, Identifiable, Hashable {
    let id: String
    let providerID: String
    let providerName: String
    let edition: String
    let title: String
    let localResource: String
    let remoteURL: URL
    let sha256: String
    let attribution: String
    let sourceURL: URL
}

struct GuidelineDataset: Codable {
    let schemaVersion: Int
    let providerID: String
    let providerName: String
    let edition: String
    let title: String
    let sourceURL: URL
    let attribution: String
    let styles: [BeerStyle]
}

struct BeerStyle: Codable, Identifiable, Hashable {
    let id: String
    let number: String
    let name: String
    let category: String
    let categoryNumber: String
    let sections: [StyleSection]
    let metrics: [StyleMetric]
    let tags: [String]

    var displayCode: String { number.isEmpty ? categoryNumber : number }

    var searchableText: String {
        ([number, name, category, categoryNumber] + tags + sections.flatMap { [$0.title, $0.body] })
            .joined(separator: " ")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

struct StyleSection: Codable, Hashable, Identifiable {
    let title: String
    let body: String
    var id: String { title }
}

struct StyleMetric: Codable, Hashable, Identifiable {
    let label: String
    let value: String
    var id: String { label }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

