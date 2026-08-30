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
                            .foregroundStyle(Color.judgeAccent)
                        Text(section.body)
                            .font(.body)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .judgeCard()
                }
            }
            .padding()
        }
        .background(Color.judgeBackground)
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
            if !style.number.isEmpty { Text(style.number).font(.headline.monospaced()).foregroundStyle(Color.judgeAccent) }
            Text(style.name).font(.largeTitle.bold()).minimumScaleFactor(0.75)
            Text(style.category).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metrics: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 150), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(style.metrics) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(metric.value)
                        .font(.subheadline.monospaced().weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Color.judgeRaisedSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }
}
