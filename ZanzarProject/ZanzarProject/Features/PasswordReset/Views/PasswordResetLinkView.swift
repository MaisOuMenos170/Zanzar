import SwiftUI

/// Sheet opened by the email link: checks the link, then asks for the new password.
struct PasswordResetLinkView: View {
    @State private var viewModel: PasswordResetLinkViewModel
    @Environment(\.dismiss) private var dismiss

    private let onFinished: () -> Void
    /// `nil` hides the "ask for a new code" action (the code flow only exists while signed out).
    private let onRequestNewCode: (() -> Void)?

    init(
        link: PasswordResetLink,
        onFinished: @escaping () -> Void,
        onRequestNewCode: (() -> Void)?
    ) {
        _viewModel = State(initialValue: PasswordResetLinkViewModel(link: link))
        self.onFinished = onFinished
        self.onRequestNewCode = onRequestNewCode
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
        .task {
            await viewModel.verify()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .verifying:
            ProgressView("passwordReset.link.verifying")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.brandBlue50.ignoresSafeArea())
        case .ready(let resetToken):
            NewPasswordView(resetToken: resetToken, onFinished: onFinished)
        case .failed(let message):
            ContentUnavailableView {
                Label("passwordReset.link.failed.title", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                if let onRequestNewCode {
                    Button(action: onRequestNewCode) {
                        // The style fills the width it gets; ContentUnavailableView only gives the label's.
                        Text("passwordReset.link.requestNewCode")
                            .padding(.horizontal, 24)
                    }
                    .buttonStyle(AuthPrimaryButtonStyle())
                }
            }
            .background(Color.brandBlue50.ignoresSafeArea())
        }
    }
}
