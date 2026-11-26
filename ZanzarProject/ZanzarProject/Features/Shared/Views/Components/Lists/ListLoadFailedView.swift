import SwiftUI

/// A list that could not load. That is not the same as an empty list, so the user gets the reason and a way
/// to try again, like the other lists (the retry button is `profile.errorState.retryButton.title`).
struct ListLoadFailedView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("list.loadFailed.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("profile.errorState.retryButton.title") {
                Task { await retry() }
            }
        }
    }
}

#Preview {
    ListLoadFailedView(message: "Não foi possível carregar agora.") {}
        .background(Color.profileBackground)
}
