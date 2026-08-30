import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var store: GuidelineStore

    var body: some View {
        Group {
            if store.favourites.isEmpty {
                ContentUnavailableView("No saved styles", systemImage: "bookmark", description: Text("Bookmark styles you expect on your judging flight for one-tap access."))
            } else {
                List(store.favourites) { StyleRow(style: $0) }
            }
        }
        .navigationTitle("Saved")
    }
}

