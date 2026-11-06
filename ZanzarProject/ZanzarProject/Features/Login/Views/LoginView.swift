import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(\.authorizationController) private var authorizationController
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

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
            .focused($focusedField, equals: .email)

            AuthFormField(
                labelKey: "login.passwordField.label",
                placeholderKey: "login.passwordField.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .password,
                submitLabel: .go
            )
            .focused($focusedField, equals: .password)
        }
        .onSubmit {
            switch focusedField {
            case .email: focusedField = .password
            case .password, nil:
                focusedField = nil
                Task { await submit() }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 16) {
            submitButton

            AuthOrDivider()

            AuthAppleButton {
                Task { await signInWithApple() }
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

    private func signInWithApple() async {
        onboarding.begin()
        guard await viewModel.signInWithApple(
            using: authSession,
            requestCredential: { try await authorizationController.appleIDCredential(for: $0) }
        ) else {
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
