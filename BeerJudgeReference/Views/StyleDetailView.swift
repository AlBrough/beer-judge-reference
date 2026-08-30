import SwiftUI
import UIKit

struct StyleDetailView: View {
    @EnvironmentObject private var store: GuidelineStore
    @AppStorage("keepAwakeWhileJudging") private var keepAwake = true
    let style: BeerStyle

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                if !style.metrics.isEmpty { metrics }
                ForEach(style.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title.uppercased())
                            .font(.caption.weight(.bold))
                            .tracking(1.1)
                            .foregroundStyle(Color.amberAccent)
                        Text(section.body)
                            .font(.body)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(style.number.isEmpty ? "Style" : style.number)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                store.toggleFavourite(style)
            } label: {
                Image(systemName: store.isFavourite(style) ? "bookmark.fill" : "bookmark")
            }
            .accessibilityLabel(store.isFavourite(style) ? "Remove bookmark" : "Bookmark style")
        }
        .onAppear {
            store.recordOpened(style)
            if keepAwake { UIApplication.shared.isIdleTimerDisabled = true }
        }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !style.number.isEmpty { Text(style.number).font(.headline.monospaced()).foregroundStyle(Color.amberAccent) }
            Text(style.name).font(.largeTitle.bold()).minimumScaleFactor(0.75)
            Text(style.category).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(style.metrics) { metric in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.label).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                        Text(metric.value).font(.subheadline.monospaced().weight(.bold))
                    }
                    .padding(.horizontal, 13).padding(.vertical, 10)
                    .background(Color.amberAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                }
            }
        }
    }
}

