import SwiftUI

@main
struct BeerJudgeReferenceApp: App {
    @StateObject private var store = GuidelineStore()
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue

    var body: some Scene {
        WindowGroup {
            appRoot
                .environmentObject(store)
                .preferredColorScheme(colorScheme)
                .task { await store.start() }
        }
    }

    @ViewBuilder
    private var appRoot: some View {
#if DEBUG
        if let styleID = ProcessInfo.processInfo.environment["STYLE_DETAIL_PREVIEW_ID"] {
            StyleDetailLaunchPreview(styleID: styleID)
        } else {
            RootView()
        }
#else
        RootView()
#endif
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
    let styleID: String

    var body: some View {
        NavigationStack {
            if let style = store.styles.first(where: { $0.id == styleID }) {
                StyleDetailView(style: style)
            } else {
                ProgressView("Opening style")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.judgeBackground)
            }
        }
    }
}
#endif
