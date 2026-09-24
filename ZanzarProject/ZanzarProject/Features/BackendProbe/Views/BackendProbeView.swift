import SwiftUI

struct BackendProbeView: View {
    @State private var viewModel = BackendProbeViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        List {
            Section {
                BackendProbeResultRow(
                    titleKey: "backendProbe.baseURL.label",
                    value: viewModel.baseURLDescription
                )
            } header: {
                Text("backendProbe.configuration.header")
            } footer: {
                Text("backendProbe.configuration.footer")
            }

            Section {
                Button("backendProbe.healthButton.title", systemImage: "heart.text.square") {
                    Task { await viewModel.checkHealth() }
                }
                .disabled(viewModel.isCheckingHealth)

                if viewModel.isCheckingHealth {
                    ProgressView("backendProbe.health.loading")
                } else if let healthCheck = viewModel.healthCheck {
                    BackendProbeResultRow(
                        titleKey: "backendProbe.health.statusLabel",
                        value: healthCheck.status
                    )
                }
            } header: {
                Text("backendProbe.health.header")
            }

            Section {
                Button("backendProbe.createUserButton.title", systemImage: "person.badge.plus") {
                    Task { await viewModel.createTestUser() }
                }
                .disabled(viewModel.isCreatingUser)

                if viewModel.isCreatingUser {
                    ProgressView("backendProbe.createUser.loading")
                } else if let createdUser = viewModel.createdUser {
                    userDetails(for: createdUser)
                }

                Button("backendProbe.fetchUserButton.title", systemImage: "person.crop.circle.badge.checkmark") {
                    Task { await viewModel.fetchCreatedUser() }
                }
                .disabled(viewModel.createdUser == nil || viewModel.isFetchingUser)

                if viewModel.isFetchingUser {
                    ProgressView("backendProbe.fetchUser.loading")
                } else if let fetchedUser = viewModel.fetchedUser {
                    userDetails(for: fetchedUser)
                }
            } header: {
                Text("backendProbe.user.header")
            } footer: {
                Text("backendProbe.user.footer")
            }
        }
        .navigationTitle("backendProbe.navigation.title")
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                BackendProbeErrorBanner(message: errorMessage)
                    .padding()
            }
        }
    }

    @ViewBuilder
    private func userDetails(for user: BackendUser) -> some View {
        BackendProbeResultRow(titleKey: "backendProbe.user.idLabel", value: user.id)
        BackendProbeResultRow(titleKey: "backendProbe.user.emailLabel", value: user.email)
        BackendProbeResultRow(titleKey: "backendProbe.user.nameLabel", value: user.name)
        BackendProbeResultRow(titleKey: "backendProbe.user.roleLabel", value: user.role.rawValue)
    }
}

#Preview {
    NavigationStack {
        BackendProbeView()
    }
    .environment(AppCoordinator())
}
