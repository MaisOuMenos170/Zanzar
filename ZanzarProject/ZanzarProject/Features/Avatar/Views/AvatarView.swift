import SwiftUI

struct AvatarView: View {
    @State private var viewModel = AvatarViewModel()

    var body: some View {
        content
            .background(Color(.systemBackground))
            .navigationTitle("avatar.navigationTitle.title")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
            .alert("avatar.createErrorAlert.title", isPresented: $viewModel.createFailed) {
                Button("avatar.createErrorAlert.dismissButton.title", role: .cancel) {}
            }
    }

    @ViewBuilder
    private var content: some View {
        if let avatar = viewModel.avatar {
            AvatarPortraitView(avatar: avatar)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.hasNoAvatar {
            ContentUnavailableView {
                Label("avatar.emptyState.title", systemImage: "face.smiling")
            } description: {
                Text("avatar.emptyState.message")
            } actions: {
                Button("avatar.emptyState.createButton.title") {
                    Task { await viewModel.createPlaceholderAvatar() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isCreating)
            }
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("avatar.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("avatar.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
                .disabled(viewModel.isLoading)
            }
        } else {
            ProgressView("avatar.loadingIndicator.title")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        AvatarView()
    }
}
