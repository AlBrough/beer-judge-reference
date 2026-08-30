import SwiftUI

@main
struct BeerJudgeReferenceApp: App {
    @StateObject private var store = GuidelineStore()
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
                .task { await store.start() }
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppearancePreference(rawValue: appearancePreference) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

