import SwiftUI
import UIKit

struct StyleDetailView: View {
    @EnvironmentObject private var store: GuidelineStore
    @Environment(\.judgeColourTheme) private var theme
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
                            .foregroundStyle(theme.accent)
                        Text(section.displayBody)
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
        .background(theme.background)
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
            if !style.number.isEmpty { Text(style.number).font(.headline.monospaced()).foregroundStyle(theme.accent) }
            Text(style.displayName).font(.largeTitle.bold()).minimumScaleFactor(0.75)
            Text(style.displayCategory).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
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
                    Text(metric.displayValue)
                        .font(.subheadline.monospaced().weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(theme.raisedSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
    }
}
