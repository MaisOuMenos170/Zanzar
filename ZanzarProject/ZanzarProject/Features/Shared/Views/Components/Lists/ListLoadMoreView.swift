import SwiftUI

struct ListLoadMoreView: View {
    let failed: Bool
    let onLoadMore: () async -> Void
    let onRetry: () async -> Void

    var body: some View {
        Group {
            if failed {
                VStack(spacing: 8) {
                    Text("list.loadMore.errorMessage")
                        .typography(.body2)
                        .foregroundStyle(Color.brandNeutral600)
                    Button("list.loadMore.retryButton") {
                        Task { await onRetry() }
                    }
                    .typography(.subtitle2)
                    .foregroundStyle(Color.brandPurple500)
                }
            } else {
                SkeletonBlock(height: 88)
                    .shimmering()
                    .padding(.vertical, 8)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("list.loading.accessibilityLabel"))
                    .task { await onLoadMore() }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}
