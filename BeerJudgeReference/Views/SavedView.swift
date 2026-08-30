import SwiftUI

struct SavedView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme

    var body: some View {
        Group {
            if store.favourites.isEmpty {
                ContentUnavailableView("No saved styles", systemImage: "bookmark", description: Text("Bookmark styles you expect on your judging flight for one-tap access."))
            } else {
                List(store.favourites) { StyleRow(style: $0) }
                    .judgeScrollBackground()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
        .navigationTitle("Saved")
    }
}
