import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel = ForgotPasswordViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        AuthScreenScaffold(titleKey: "passwordReset.forgot.title") {
            form
        } actions: {
            submitButton
        }
        .toast(for: viewModel.submitError)
        .onChange(of: viewModel.email) {
            viewModel.refreshShownFieldErrors()
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("passwordReset.forgot.message")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            AuthFormField(
                labelKey: "login.emailField.label",
                placeholderKey: "login.emailField.placeholder",
                text: $viewModel.email,
                errorMessageKey: viewModel.emailError,
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                submitLabel: .send
            )
            .onSubmit {
                Task { await submit() }
            }
        }
    }

    private var submitButton: some View {
        Button("passwordReset.forgot.submitButton.title") {
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
        guard let email = await viewModel.submit() else { return }
        coordinator.push(.resetCode(email: email))
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environment(AppCoordinator())
            .environment(ToastManager())
    }
}
