import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AuthSession.self) private var authSession
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        content
            .background(Color(.systemBackground))
            .navigationTitle("mainTab.profileTab.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        "profile.header.signOutAccessibilityLabel",
                        systemImage: "rectangle.portrait.and.arrow.forward"
                    ) {
                        viewModel.showsSignOutConfirmation = true
                    }
                    .disabled(viewModel.isSigningOut)
                }
            }
            .alert("profile.signOutConfirmation.title", isPresented: $viewModel.showsSignOutConfirmation) {
                Button("profile.signOutConfirmation.confirmButton.title", role: .destructive) {
                    Task { await viewModel.signOut(using: authSession, coordinator: coordinator) }
                }
                Button("profile.signOutConfirmation.cancelButton.title", role: .cancel) {}
            } message: {
                Text("profile.signOutConfirmation.message")
            }
            .alert("profile.signOutAlert.title", isPresented: $viewModel.signOutFailed) {
                Button("profile.signOutAlert.dismissButton.title", role: .cancel) {
                    viewModel.signOutFailed = false
                }
            }
            // Restarts when a pushed place detail is popped, so a check-in made there shows up here.
            .task(id: coordinator.path.isEmpty) {
                guard coordinator.path.isEmpty else { return }
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let profile = viewModel.profile {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeaderView(name: profile.summary.name)

                    VStack(alignment: .leading, spacing: 32) {
                        ProfileStatsView(summary: profile.summary)
                        ProfileRecentCheckInsSection(checkIns: profile.recentCheckIns, mediaPolicy: mediaPolicy)
                    }
                }
                .padding(16)
            }
            .refreshable { await viewModel.load() }
        } else if let errorMessage = viewModel.errorMessage {
            ContentUnavailableView {
                Label("profile.errorState.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("profile.errorState.retryButton.title") {
                    Task { await viewModel.load() }
                }
                .disabled(viewModel.isLoading)
            }
        } else {
            ProgressView("profile.loadingIndicator.title")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthSession())
    .environment(AppCoordinator())
}
