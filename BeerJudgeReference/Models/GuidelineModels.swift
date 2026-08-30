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

struct StyleCategory: Identifiable, Hashable {
    let number: String
    let name: String
    let styles: [BeerStyle]

    var id: String { "\(number)|\(name)" }
    var navigationTitle: String {
        number.isEmpty || Int(number) == nil ? name : "\(number) \(name)"
    }
}

enum GuidelineOrdering {
    static func categories(from styles: [BeerStyle]) -> [StyleCategory] {
        struct Group {
            let firstIndex: Int
            var styles: [BeerStyle]
        }

        var groups: [String: Group] = [:]
        for (index, style) in styles.enumerated() {
            let key = "\(style.categoryNumber)|\(style.category)"
            if groups[key] == nil {
                groups[key] = Group(firstIndex: index, styles: [])
            }
            groups[key]?.styles.append(style)
        }

        return groups.values
            .map { group in
                let first = group.styles[0]
                return (
                    category: StyleCategory(
                        number: first.categoryNumber,
                        name: first.category,
                        styles: orderedStyles(group.styles)
                    ),
                    firstIndex: group.firstIndex
                )
            }
            .sorted { left, right in
                categoryPrecedes(
                    left.category,
                    firstIndex: left.firstIndex,
                    right.category,
                    firstIndex: right.firstIndex
                )
            }
            .map { $0.category }
    }

    static func orderedStyles(_ styles: [BeerStyle]) -> [BeerStyle] {
        styles.enumerated()
            .sorted { left, right in
                let codeOrder = left.element.displayCode.localizedStandardCompare(right.element.displayCode)
                if codeOrder != .orderedSame { return codeOrder == .orderedAscending }
                return left.offset < right.offset
            }
            .map { $0.element }
    }

    private static func categoryPrecedes(
        _ left: StyleCategory,
        firstIndex leftIndex: Int,
        _ right: StyleCategory,
        firstIndex rightIndex: Int
    ) -> Bool {
        switch (Int(left.number), Int(right.number)) {
        case let (leftNumber?, rightNumber?):
            if leftNumber != rightNumber { return leftNumber < rightNumber }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            if left.number != right.number { return leftIndex < rightIndex }
            let leftCode = left.styles.first?.displayCode ?? left.number
            let rightCode = right.styles.first?.displayCode ?? right.number
            let codeOrder = leftCode.localizedStandardCompare(rightCode)
            if codeOrder != .orderedSame { return codeOrder == .orderedAscending }
        }

        return leftIndex < rightIndex
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
