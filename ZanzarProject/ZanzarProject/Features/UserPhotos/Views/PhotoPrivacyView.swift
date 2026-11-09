import SwiftUI

/// "Photos and privacy": how photos are handled, who the user blocked, and how to reach the developer.
struct PhotoPrivacyView: View {
    @State private var viewModel = PhotoPrivacyViewModel()

    var body: some View {
        List {
            Section("userPhotos.privacy.howItWorks.title") {
                PhotoTermsContent()
                    .padding(.vertical, 8)
            }

            Section {
                if viewModel.blockedUsers.isEmpty {
                    Text("userPhotos.privacy.blocked.empty")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.blockedUsers) { user in
                        HStack {
                            Text(user.username ?? L10n.string("userPhotos.privacy.blocked.deletedAccount"))
                            Spacer()
                            Button("userPhotos.privacy.blocked.unblockButton.title") {
                                Task { await viewModel.unblock(user) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            } header: {
                Text("userPhotos.privacy.blocked.title")
            } footer: {
                Text("userPhotos.privacy.blocked.footer")
            }

            Section {
                if let email = viewModel.supportEmail, let url = SupportContact.mailURL {
                    Link(destination: url) {
                        Label(email, systemImage: "envelope")
                    }
                } else {
                    Text("userPhotos.privacy.contact.unavailable")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("userPhotos.privacy.contact.title")
            } footer: {
                Text("userPhotos.privacy.contact.footer")
            }
        }
        .navigationTitle("userPhotos.privacy.title")
        .task { await viewModel.load() }
        .alert("userPhotos.myPhotos.errorAlert.title", isPresented: errorIsPresented) {
            Button("userPhotos.myPhotos.errorAlert.dismissButton.title", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage { Text(message) }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}
