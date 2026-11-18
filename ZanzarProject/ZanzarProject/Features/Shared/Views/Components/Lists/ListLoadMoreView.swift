import SwiftUI

/// The end of a paged list: a spinner that asks for the next page as it comes into view, or a retry when the
/// last request failed.
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
                ProgressView()
                    .task { await onLoadMore() }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}
