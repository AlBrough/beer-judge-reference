import CryptoKit
import Foundation

@MainActor
final class GuidelineStore: ObservableObject {
    @Published private(set) var manifest: GuidelineManifest?
    @Published private(set) var dataset: GuidelineDataset?
    @Published private(set) var isRefreshing = false
    @Published private(set) var updateMessage: String?
    @Published var query = ""

    @Published private(set) var favouriteIDs: Set<String> = [] {
        didSet { persist(favouriteIDs, key: "favouriteStyleIDs") }
    }
    @Published private(set) var recentIDs: [String] = [] {
        didSet { persist(recentIDs, key: "recentStyleIDs") }
    }

    private let decoder = JSONDecoder()
    private let remoteManifestURL = URL(string: "https://raw.githubusercontent.com/AlBrough/beer-judge-reference/main/Resources/guidelines-manifest.json")!
    private let defaults = UserDefaults.standard

    var descriptors: [DatasetDescriptor] { manifest?.datasets ?? [] }
    var selectedDescriptor: DatasetDescriptor? {
        guard let dataset else { return nil }
        return descriptors.first { $0.providerID == dataset.providerID && $0.edition == dataset.edition }
    }
    var styles: [BeerStyle] { dataset?.styles ?? [] }
    var browseCategories: [StyleCategory] { GuidelineOrdering.categories(from: styles) }
    var orderedStyles: [BeerStyle] { browseCategories.flatMap(\.styles) }
    var filteredStyles: [BeerStyle] {
        let terms = query.normalizedTerms
        guard !terms.isEmpty else { return orderedStyles }
        return orderedStyles.filter { style in terms.allSatisfy(style.searchableText.contains) }
    }
    var favourites: [BeerStyle] { orderedStyles.filter { favouriteIDs.contains($0.id) } }
    var recents: [BeerStyle] { recentIDs.compactMap { id in styles.first { $0.id == id } } }

    init() {
        favouriteIDs = Set(defaults.stringArray(forKey: "favouriteStyleIDs") ?? [])
        recentIDs = defaults.stringArray(forKey: "recentStyleIDs") ?? []
    }

    func start() async {
        guard dataset == nil else { return }
        do {
            let bundledManifest: GuidelineManifest = try decodeBundle("guidelines-manifest")
            manifest = bundledManifest
            let preferredID = defaults.string(forKey: "selectedDatasetID") ?? "bjcp-2021"
            let descriptor = bundledManifest.datasets.first { $0.id == preferredID } ?? bundledManifest.datasets[0]
            dataset = try loadBestAvailable(descriptor)
            await refreshIfNeeded()
        } catch {
            updateMessage = "The bundled guidelines could not be opened."
        }
    }

    func select(_ descriptor: DatasetDescriptor) {
        do {
            dataset = try loadBestAvailable(descriptor)
            defaults.set(descriptor.id, forKey: "selectedDatasetID")
            query = ""
            updateMessage = nil
        } catch {
            updateMessage = "That guideline edition could not be opened."
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let (manifestData, response) = try await URLSession.shared.data(from: remoteManifestURL)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let remote = try decoder.decode(GuidelineManifest.self, from: manifestData)
            guard remote.schemaVersion == 1, !remote.datasets.isEmpty else { throw DataError.unsupportedSchema }
            manifest = remote

            for descriptor in remote.datasets {
                try await cache(descriptor)
            }
            defaults.set(Date().timeIntervalSince1970, forKey: "lastRefresh")
            if let currentID = selectedDescriptor?.id,
               let current = remote.datasets.first(where: { $0.id == currentID }) {
                dataset = try loadBestAvailable(current)
            }
            updateMessage = "Guidelines are up to date."
        } catch {
            updateMessage = "Offline — using the latest guidelines saved on this device."
        }
    }

    func toggleFavourite(_ style: BeerStyle) {
        if favouriteIDs.contains(style.id) { favouriteIDs.remove(style.id) }
        else { favouriteIDs.insert(style.id) }
    }

    func recordOpened(_ style: BeerStyle) {
        recentIDs.removeAll { $0 == style.id }
        recentIDs.insert(style.id, at: 0)
        recentIDs = Array(recentIDs.prefix(12))
    }

    func isFavourite(_ style: BeerStyle) -> Bool { favouriteIDs.contains(style.id) }

    private func refreshIfNeeded() async {
        let lastRefresh = defaults.double(forKey: "lastRefresh")
        guard Date().timeIntervalSince1970 - lastRefresh > 86_400 else { return }
        await refresh()
    }

    private func cache(_ descriptor: DatasetDescriptor) async throws {
        let (data, response) = try await URLSession.shared.data(from: descriptor.remoteURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        guard data.sha256 == descriptor.sha256 else { throw DataError.checksumMismatch }
        _ = try decoder.decode(GuidelineDataset.self, from: data)
        try data.write(to: cacheURL(descriptor), options: .atomic)
    }

    private func loadBestAvailable(_ descriptor: DatasetDescriptor) throws -> GuidelineDataset {
        let cached = cacheURL(descriptor)
        if let data = try? Data(contentsOf: cached), data.sha256 == descriptor.sha256,
           let decoded = try? decoder.decode(GuidelineDataset.self, from: data) { return decoded }
        return try decodeBundle(descriptor.localResource)
    }

    private func decodeBundle<T: Decodable>(_ resource: String) throws -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else { throw DataError.missingBundleResource }
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }

    private func cacheURL(_ descriptor: DatasetDescriptor) -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Guidelines", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("\(descriptor.id).json")
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
        if let array = value as? [String] { defaults.set(array, forKey: key) }
        if let set = value as? Set<String> { defaults.set(Array(set), forKey: key) }
    }
}

private enum DataError: Error { case missingBundleResource, unsupportedSchema, checksumMismatch }

private extension Data {
    var sha256: String { SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined() }
}

private extension String {
    var normalizedTerms: [String] {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }
}
