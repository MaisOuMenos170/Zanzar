import SwiftUI

struct BlockedProfilesView: View {
    @State private var viewModel = BlockedProfilesViewModel()
    @State private var searchText = ""

    private var visibleUsers: [BlockedUser] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return viewModel.blockedUsers }
        return viewModel.blockedUsers.filter { $0.username?.localizedStandardContains(query) == true }
    }

    var body: some View {
        ListScreenScaffold(
            title: "userPhotos.privacy.blocked.title",
            searchPrompt: "userPhotos.privacy.blocked.search.prompt",
            searchText: $searchText,
            count: Text("userPhotos.privacy.blocked.count \(visibleUsers.count)")
        ) {
            content
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("userPhotos.myPhotos.errorAlert.title", isPresented: errorIsPresented) {
            Button("userPhotos.myPhotos.errorAlert.dismissButton.title", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage, viewModel.blockedUsers.isEmpty {
            ListLoadFailedView(message: message) { await viewModel.load() }
        } else if viewModel.blockedUsers.isEmpty && !viewModel.hasLoaded {
            ListLoadingView()
        } else if visibleUsers.isEmpty {
            ListNoResultsView(
                hasItems: !viewModel.blockedUsers.isEmpty,
                query: searchText,
                emptyTitle: "userPhotos.privacy.blocked.empty",
                emptyMessage: "userPhotos.privacy.blocked.footer",
                notFoundMessage: "list.noResults.blocked.message"
            )
        } else {
            ListCard {
                ForEach(visibleUsers) { user in
                    row(for: user)
                }
            }
        }
    }

    private func row(for user: BlockedUser) -> some View {
        HStack(spacing: 12) {
            Text(user.username ?? L10n.string("userPhotos.privacy.blocked.deletedAccount"))
                .typography(.subtitle2)
                .foregroundStyle(Color.brandNeutral950)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                Task { await viewModel.unblock(user) }
            } label: {
                Text("userPhotos.privacy.blocked.unblockButton.title")
                    .typography(.caption3)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(minHeight: 44)
                    .background(Color.brandPurple500, in: .rect(cornerRadius: 16))
                    .contentShape(.rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(verbatim: user.username ?? L10n.string("userPhotos.privacy.blocked.deletedAccount")))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && viewModel.hasLoaded && !viewModel.blockedUsers.isEmpty },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}
