import SwiftUI

struct NewPasswordView: View {
    @State private var viewModel: NewPasswordViewModel
    @FocusState private var focusedField: Field?

    private let onFinished: () -> Void

    private enum Field {
        case password, confirmation
    }

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

            if let submitError = viewModel.submitError {
                ErrorBanner(message: submitError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthFormField(
                labelKey: "passwordReset.newPassword.field.label",
                placeholderKey: "passwordReset.newPassword.field.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .newPassword
            )
            .focused($focusedField, equals: .password)

            AuthFormField(
                labelKey: "passwordReset.confirmPassword.field.label",
                placeholderKey: "passwordReset.confirmPassword.field.placeholder",
                text: $viewModel.confirmation,
                errorMessageKey: viewModel.confirmationError,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .done
            )
            .focused($focusedField, equals: .confirmation)
        }
        .onSubmit {
            switch focusedField {
            case .password: focusedField = .confirmation
            case .confirmation, nil:
                focusedField = nil
                Task { await submit() }
            }
        }
    }

    private var submitButton: some View {
        Button("passwordReset.newPassword.submitButton.title") {
            Task { await submit() }
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(viewModel.isLoading)
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
    }
}
