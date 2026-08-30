import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme
    @State private var leftID = ""
    @State private var rightID = ""

    private var left: BeerStyle? { store.styles.first { $0.id == leftID } }
    private var right: BeerStyle? { store.styles.first { $0.id == rightID } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                stylePicker("First style", selection: $leftID)
                stylePicker("Second style", selection: $rightID)
                if let left, let right {
                    comparison(left, right)
                } else {
                    ContentUnavailableView("Compare styles", systemImage: "rectangle.split.2x1", description: Text("Choose two styles to line up their vital statistics and sensory descriptions."))
                        .padding(.top, 32)
                }
            }
            .padding()
        }
        .background(theme.background)
        .navigationTitle("Compare")
    }

    private func stylePicker(_ title: String, selection: Binding<String>) -> some View {
        let selectedStyle = store.styles.first { $0.id == selection.wrappedValue }

        return NavigationLink {
            CompareStyleSelectionView(title: title, selection: selection)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if let selectedStyle {
                        Text("\(selectedStyle.displayCode) \(selectedStyle.name)")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Choose a style")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
                Spacer()
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.accent)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .judgeCard(cornerRadius: 16)
        .accessibilityIdentifier(title == "First style" ? "compare-first-style" : "compare-second-style")
    }

    private func comparison(_ left: BeerStyle, _ right: BeerStyle) -> some View {
        VStack(spacing: 14) {
            comparisonRow("Style", left.name, right.name, prominent: true)
            ForEach(Array(Set((left.metrics + right.metrics).map(\.label))).sorted(), id: \.self) { label in
                comparisonRow(label, left.metrics.first { $0.label == label }?.value ?? "—", right.metrics.first { $0.label == label }?.value ?? "—")
            }
            ForEach(["Overall impression", "Aroma", "Appearance", "Flavor", "Mouthfeel"], id: \.self) { title in
                if left.sections.contains(where: { $0.title == title }) || right.sections.contains(where: { $0.title == title }) {
                    comparisonRow(title, left.sections.first { $0.title == title }?.body ?? "—", right.sections.first { $0.title == title }?.body ?? "—")
                }
            }
        }
    }

    private func comparisonRow(_ title: String, _ left: String, _ right: String, prominent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.caption.bold()).tracking(1).foregroundStyle(theme.accent)
            HStack(alignment: .top, spacing: 12) {
                Text(left).frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text(right).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(prominent ? .headline : .caption)
        }
        .padding()
        .judgeCard(cornerRadius: 16)
    }
}

struct CompareStyleSelectionView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.judgeColourTheme) private var theme
    let title: String
    @Binding var selection: String
    @State private var query = ""

    private var filteredStyles: [BeerStyle] {
        let terms = query
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard !terms.isEmpty else { return store.orderedStyles }
        return store.orderedStyles.filter { style in
            terms.allSatisfy(style.searchableText.contains)
        }
    }

    var body: some View {
        Group {
            if filteredStyles.isEmpty {
                ContentUnavailableView.search(text: query)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredStyles) { style in
                    Button {
                        selection = style.id
                        dismiss()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(style.displayCode)
                                .font(.caption.monospaced().weight(.bold))
                                .foregroundStyle(theme.accent)
                                .frame(minWidth: 38, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(style.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(style.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selection == style.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.accent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(theme.surface)
                }
                .judgeScrollBackground()
            }
        }
        .background(theme.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by code or style")
    }
}
