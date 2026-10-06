import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(AuthSession.self) private var authSession
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ProfileHeaderView(name: viewModel.summary.name)

                VStack(alignment: .leading, spacing: 32) {
                    ProfileStatsView(summary: viewModel.summary)
                    ProfileRecentCheckInsSection(checkIns: viewModel.recentCheckIns)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    "profile.header.signOutAccessibilityLabel",
                    systemImage: "rectangle.portrait.and.arrow.forward"
                ) {
                    viewModel.showsSignOutConfirmation = true
                }
            }
        }
        .alert("profile.signOutConfirmation.title", isPresented: $viewModel.showsSignOutConfirmation) {
            Button("profile.signOutConfirmation.confirmButton.title", role: .destructive) {
                viewModel.signOut(using: authSession, coordinator: coordinator)
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
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AuthSession())
    .environment(AppCoordinator())
}
