import SwiftUI

struct NewPasswordView: View {
    @State private var viewModel: NewPasswordViewModel
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmationFocused: Bool

    private let onFinished: () -> Void

    init(resetToken: String, onFinished: @escaping () -> Void) {
        _viewModel = State(initialValue: NewPasswordViewModel(resetToken: resetToken))
        self.onFinished = onFinished
    }

    var body: some View {
        AuthScreenScaffold(titleKey: "passwordReset.newPassword.title") {
            form
        } actions: {
            submitButton
        }
        .toast(for: viewModel.submitError)
        .onChange(of: viewModel.password) {
            viewModel.refreshShownFieldErrors()
        }
        .onChange(of: viewModel.confirmation) {
            viewModel.refreshShownFieldErrors()
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("passwordReset.newPassword.message")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            AuthFormField(
                labelKey: "passwordReset.newPassword.field.label",
                placeholderKey: "passwordReset.newPassword.field.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .newPassword,
                isFocused: $isPasswordFocused
            )

            AuthFormField(
                labelKey: "passwordReset.confirmPassword.field.label",
                placeholderKey: "passwordReset.confirmPassword.field.placeholder",
                text: $viewModel.confirmation,
                errorMessageKey: viewModel.confirmationError,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .done,
                isFocused: $isConfirmationFocused
            )
        }
        .onSubmit {
            if isPasswordFocused {
                isConfirmationFocused = true
            } else {
                isConfirmationFocused = false
                Task { await submit() }
            }
        }
    }

    private var submitButton: some View {
        Button("passwordReset.newPassword.submitButton.title") {
            Task { await submit() }
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(viewModel.isLoading || !viewModel.canSubmit)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func submit() async {
        guard await viewModel.submit() else { return }
        onFinished()
    }
}

#Preview {
    NavigationStack {
        NewPasswordView(resetToken: "preview-token") {}
            .environment(ToastManager())
    }
}
