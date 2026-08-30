import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: GuidelineStore
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue
    @AppStorage("keepAwakeWhileJudging") private var keepAwake = true

    var body: some View {
        Form {
            Section("Guidelines") {
                ForEach(store.descriptors) { descriptor in
                    Button {
                        store.select(descriptor)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(descriptor.providerName).foregroundStyle(.primary)
                                Text(descriptor.edition).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.selectedDescriptor?.id == descriptor.id { Image(systemName: "checkmark").foregroundStyle(Color.judgeAccent) }
                        }
                    }
                }
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label(store.isRefreshing ? "Checking…" : "Check for updates", systemImage: "arrow.clockwise")
                }
                .disabled(store.isRefreshing)
                if let updateMessage = store.updateMessage { Text(updateMessage).font(.caption).foregroundStyle(.secondary) }
            }
            .listRowBackground(Color.judgeSurface)

            Section("Judging") {
                Toggle("Keep screen awake while viewing a style", isOn: $keepAwake)
                Picker("Appearance", selection: $appearancePreference) {
                    ForEach(AppearancePreference.allCases) { Text($0.label).tag($0.rawValue) }
                }
            }
            .listRowBackground(Color.judgeSurface)

            if let descriptor = store.selectedDescriptor {
                Section("Source and attribution") {
                    Text(descriptor.attribution).font(.footnote)
                    Link("Open official source", destination: descriptor.sourceURL)
                    Text("This independent reference is not affiliated with or endorsed by BJCP or the Brewers Association. Guideline text remains the property of its respective owner.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .listRowBackground(Color.judgeSurface)
            }
        }
        .judgeScrollBackground()
        .navigationTitle("Settings")
    }
}
