import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue
    @AppStorage("colourTheme") private var colourTheme = JudgeColourTheme.forest.rawValue
    @AppStorage("keepAwakeWhileJudging") private var keepAwake = true

    private var selectedAppearance: AppearancePreference {
        AppearancePreference(rawValue: appearancePreference) ?? .system
    }

    private var selectedTheme: JudgeColourTheme {
        JudgeColourTheme(rawValue: colourTheme) ?? .forest
    }

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
                            if store.selectedDescriptor?.id == descriptor.id { Image(systemName: "checkmark").foregroundStyle(theme.accent) }
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
            .listRowBackground(theme.surface)

            Section("Judging") {
                Toggle("Keep screen awake while viewing a style", isOn: $keepAwake)
                Menu {
                    ForEach(AppearancePreference.allCases) { option in
                        Button {
                            appearancePreference = option.rawValue
                        } label: {
                            if selectedAppearance == option {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Text(option.label)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Appearance")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedAppearance.label)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("appearance-menu")
            }
            .listRowBackground(theme.surface)

            Section {
                Menu {
                    ForEach(JudgeColourTheme.allCases) { option in
                        Button {
                            colourTheme = option.rawValue
                        } label: {
                            if selectedTheme == option {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Label(option.label, systemImage: option.symbol)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Colour theme")
                            .foregroundStyle(.primary)
                        Spacer()
                        Label(selectedTheme.label, systemImage: selectedTheme.symbol)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("colour-theme-menu")
            } header: {
                Text("Colour")
            } footer: {
                Text("Choose Forest, Ocean, Amber, or a high-contrast neutral theme. Your light and dark appearance setting still applies.")
            }
            .listRowBackground(theme.surface)

            if let descriptor = store.selectedDescriptor {
                Section("Source and attribution") {
                    Text(descriptor.attribution).font(.footnote)
                    Link("Open official source", destination: descriptor.sourceURL)
                    Text("This independent reference is not affiliated with or endorsed by BJCP or the Brewers Association. Guideline text remains the property of its respective owner.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .listRowBackground(theme.surface)
            }
        }
        .judgeScrollBackground()
        .navigationTitle("Settings")
    }
}
