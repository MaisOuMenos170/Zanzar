import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(OnboardingGate.self) private var onboarding

    var body: some View {
        AuthScreenScaffold(titleKey: "login.header.title") {
            form
        } actions: {
            actions
        }
        .onChange(of: viewModel.email) {
            viewModel.refreshShownFieldErrors()
        }
        .onChange(of: viewModel.password) {
            viewModel.refreshShownFieldErrors()
        }
    }

    private var form: some View {
        VStack(spacing: 16) {
            if let submitError = viewModel.submitError {
                ErrorBanner(message: submitError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthFormField(
                labelKey: "login.emailField.label",
                placeholderKey: "login.emailField.placeholder",
                text: $viewModel.email,
                errorMessageKey: viewModel.emailError,
                textContentType: .emailAddress,
                keyboardType: .emailAddress
            )

            AuthFormField(
                labelKey: "login.passwordField.label",
                placeholderKey: "login.passwordField.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .password
            )
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            submitButton

            AuthOrDivider()

            AuthAppleButton { request in
                viewModel.configureAppleRequest(request)
            } onCompletion: { result in
                Task { await completeAppleSignIn(result) }
            }
            .disabled(viewModel.isLoading)

            AuthSwitchLink(
                promptKey: "auth.switch.noAccount.prompt",
                actionKey: "auth.switch.noAccount.action"
            ) {
                coordinator.pop()
                coordinator.push(.signUp)
            }
        }
    }

    private var submitButton: some View {
        Button("login.submitButton.title") {
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
        // A user whose avatar was never created goes to the editor, so the gate holds the auth stack until known.
        onboarding.begin()
        guard await viewModel.submit(using: authSession) else {
            onboarding.finish()
            return
        }
        await routeAfterSignIn()
    }

    private func routeAfterSignIn() async {
        if await onboarding.resolveAfterSignIn() {
            coordinator.startOnboarding()
        } else {
            coordinator.finishAuthFlow()
        }
    }

    private func completeAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        onboarding.begin()
        guard await viewModel.completeAppleSignIn(result, using: authSession) else {
            onboarding.finish()
            return
        }
        await routeAfterSignIn()
    }
}

#Preview("Empty") {
    NavigationStack {
        LoginView()
            .environment(AppCoordinator())
            .environment(AuthSession())
            .environment(OnboardingGate())
            .environment(ToastPresenter())
    }
}
