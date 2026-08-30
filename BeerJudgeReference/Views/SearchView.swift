import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme

    var body: some View {
        Group {
            if store.query.isEmpty {
                ContentUnavailableView("Find a style fast", systemImage: "magnifyingglass", description: Text("Search by number, name, category, aroma, flavour, ingredient, tag or commercial example."))
            } else if store.filteredStyles.isEmpty {
                ContentUnavailableView.search(text: store.query)
            } else {
                List(store.filteredStyles) { StyleRow(style: $0) }
                    .judgeScrollBackground()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .navigationTitle("Search")
        .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "e.g. 21A, saison, diacetyl")
    }
}
