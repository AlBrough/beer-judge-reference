import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { LibraryView() }.tabItem { Label("Browse", systemImage: "books.vertical.fill") }
            NavigationStack { SearchView() }.tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { CompareView() }.tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
            NavigationStack { SavedView() }.tabItem { Label("Saved", systemImage: "bookmark.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(.amberAccent)
    }
}

extension Color {
    static let amberAccent = Color(red: 0.78, green: 0.43, blue: 0.10)
}
