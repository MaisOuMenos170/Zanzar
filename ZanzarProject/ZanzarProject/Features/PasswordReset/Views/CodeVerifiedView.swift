import SwiftUI

/// Shown after the code is accepted, before the user picks the new password.
struct CodeVerifiedView: View {
    @Environment(AppCoordinator.self) private var coordinator

    let resetToken: String

    var body: some View {
        AuthScreenScaffold(titleKey: "passwordReset.verified.title") {
            Text("passwordReset.verified.message")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } actions: {
            Button("passwordReset.verified.button.title") {
                coordinator.push(.newPassword(resetToken: resetToken))
            }
            .buttonStyle(AuthPrimaryButtonStyle())
        }
    }
}

#Preview {
    NavigationStack {
        CodeVerifiedView(resetToken: "preview-token")
            .environment(AppCoordinator())
    }
}
