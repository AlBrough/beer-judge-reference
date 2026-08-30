import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: GuidelineStore

    var body: some View {
        Group {
            if let dataset = store.dataset {
                List {
                    Section {
                        editionHeader(dataset)
                    }
                    if !store.recents.isEmpty {
                        Section("Recently opened") {
                            ForEach(store.recents.prefix(4)) { StyleRow(style: $0) }
                        }
                    }
                    Section("Categories") {
                        ForEach(store.categories, id: \.self) { category in
                            NavigationLink {
                                StyleListView(title: category, styles: store.styles.filter { $0.category == category })
                            } label: {
                                HStack {
                                    Text(category)
                                    Spacer()
                                    Text("\(store.styles.filter { $0.category == category }.count)")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.judgeSurface)
                        }
                    }
                }
                .listSectionSpacing(18)
                .judgeScrollBackground()
            } else {
                ContentUnavailableView("Opening guidelines", systemImage: "book.pages", description: Text("Preparing the offline reference."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.judgeBackground)
            }
        }
        .navigationTitle("Beer Judge")
    }

    private func editionHeader(_ dataset: GuidelineDataset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Ready offline", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.judgeAccent)
            Text(dataset.title).font(.title2.bold())
            Text("\(dataset.styles.count) styles · tap any category or search across sensory descriptions and vital statistics.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.judgeSurface)
    }
}

struct StyleListView: View {
    let title: String
    let styles: [BeerStyle]
    @State private var query = ""

    private var filtered: [BeerStyle] {
        guard !query.isEmpty else { return styles }
        let term = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        return styles.filter { $0.searchableText.contains(term) }
    }

    var body: some View {
        List(filtered) { StyleRow(style: $0) }
            .judgeScrollBackground()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Filter this category")
    }
}

struct StyleRow: View {
    let style: BeerStyle

    var body: some View {
        NavigationLink {
            StyleDetailView(style: style)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                if !style.displayCode.isEmpty {
                    Text(style.displayCode)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(Color.judgeAccent)
                        .frame(minWidth: 32, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(style.name).font(.body.weight(.semibold))
                    Text(style.category).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.judgeSurface)
    }
}
