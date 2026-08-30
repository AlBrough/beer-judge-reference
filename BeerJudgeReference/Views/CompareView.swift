import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var store: GuidelineStore
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
        .navigationTitle("Compare")
    }

    private func stylePicker(_ title: String, selection: Binding<String>) -> some View {
        Picker(title, selection: selection) {
            Text("Choose…").tag("")
            ForEach(store.styles) { style in Text("\(style.number) \(style.name)").tag(style.id) }
        }
        .pickerStyle(.navigationLink)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
            Text(title.uppercased()).font(.caption.bold()).tracking(1).foregroundStyle(Color.amberAccent)
            HStack(alignment: .top, spacing: 12) {
                Text(left).frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Text(right).frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(prominent ? .headline : .caption)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

