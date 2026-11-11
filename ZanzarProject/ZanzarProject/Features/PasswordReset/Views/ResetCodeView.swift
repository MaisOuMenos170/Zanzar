import SwiftUI

struct ResetCodeView: View {
    @State private var viewModel: ResetCodeViewModel
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ToastPresenter.self) private var toastPresenter

    init(email: String) {
        _viewModel = State(initialValue: ResetCodeViewModel(email: email))
    }

    var body: some View {
        AuthScreenScaffold(titleKey: "passwordReset.code.title") {
            form
        } actions: {
            actions
        }
        .onChange(of: viewModel.code) {
            viewModel.sanitizeCode()
            viewModel.refreshShownFieldErrors()
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("passwordReset.code.message \(viewModel.email)")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let submitError = viewModel.submitError {
                ErrorBanner(message: submitError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            OneTimeCodeField(
                labelKey: "passwordReset.code.field.label",
                text: $viewModel.code,
                length: ResetCodeViewModel.codeLength,
                errorMessageKey: viewModel.codeError
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            Button("passwordReset.code.submitButton.title") {
                Task { await submit() }
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }

            AuthSwitchLink(
                promptKey: "passwordReset.code.resend.prompt",
                actionKey: "passwordReset.code.resend.action"
            ) {
                Task { await resend() }
            }
            .disabled(viewModel.isResending || viewModel.isLoading)
        }
    }

    private func submit() async {
        guard let resetToken = await viewModel.submit() else { return }
        coordinator.push(.codeVerified(resetToken: resetToken))
    }

    private func resend() async {
        guard await viewModel.resendCode() else { return }
        toastPresenter.show(L10n.string("passwordReset.code.resend.toast"))
    }
}

#Preview {
    NavigationStack {
        ResetCodeView(email: "ana@example.com")
            .environment(AppCoordinator())
            .environment(ToastPresenter())
    }
}
