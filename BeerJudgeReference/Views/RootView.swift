import SwiftUI

struct RootView: View {
    @Environment(\.judgeColourTheme) private var theme

    var body: some View {
        TabView {
            NavigationStack { LibraryView() }.tabItem { Label("Browse", systemImage: "books.vertical.fill") }
            NavigationStack { SearchView() }.tabItem { Label("Search", systemImage: "magnifyingglass") }
            NavigationStack { CompareView() }.tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
            NavigationStack { SavedView() }.tabItem { Label("Saved", systemImage: "bookmark.fill") }
            NavigationStack { SettingsView() }.tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(theme.accent)
        .toolbarBackground(theme.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
