import SwiftUI

@main
struct BeerJudgeReferenceApp: App {
    @StateObject private var store = GuidelineStore()
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue
    @AppStorage("colourTheme") private var colourTheme = JudgeColourTheme.forest.rawValue

    var body: some Scene {
        WindowGroup {
            appRoot
                .environmentObject(store)
                .environment(\.judgeColourTheme, selectedColourTheme)
                .preferredColorScheme(colorScheme)
                .task { await store.start() }
        }
    }

    @ViewBuilder
    private var appRoot: some View {
#if DEBUG
        if let styleID = ProcessInfo.processInfo.environment["STYLE_DETAIL_PREVIEW_ID"] {
            StyleDetailLaunchPreview(styleID: styleID)
        } else if ProcessInfo.processInfo.environment["APP_PREVIEW_ROUTE"] == "compare-picker" {
            NavigationStack {
                CompareStyleSelectionView(title: "First style", selection: .constant(""))
            }
        } else if ProcessInfo.processInfo.environment["APP_PREVIEW_ROUTE"] == "settings" {
            NavigationStack {
                SettingsView()
            }
        } else {
            RootView()
        }
#else
        RootView()
#endif
    }

    private var selectedColourTheme: JudgeColourTheme {
#if DEBUG
        if let preview = ProcessInfo.processInfo.environment["COLOUR_THEME_PREVIEW"],
           let theme = JudgeColourTheme(rawValue: preview) {
            return theme
        }
#endif
        return JudgeColourTheme(rawValue: colourTheme) ?? .forest
    }

    private var colorScheme: ColorScheme? {
        switch AppearancePreference(rawValue: appearancePreference) ?? .system {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

#if DEBUG
private struct StyleDetailLaunchPreview: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme
    let styleID: String

    var body: some View {
        NavigationStack {
            if let style = store.styles.first(where: { $0.id == styleID }) {
                StyleDetailView(style: style)
            } else {
                ProgressView("Opening style")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.background)
            }
        }
    }
}
#endif
