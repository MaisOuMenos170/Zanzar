import AuthenticationServices
import SwiftUI

struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    @State private var appleSignIn = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(\.authorizationController) private var authorizationController
    @FocusState private var focusedField: Field?

    private enum Field {
        case username, email, password
    }

    private var isBusy: Bool {
        viewModel.isLoading || appleSignIn.isLoading
    }

    var body: some View {
        AuthScreenScaffold(titleKey: "signUp.header.title") {
            form
        } actions: {
            actions
        }
        .onChange(of: viewModel.username) {
            viewModel.refreshShownFieldErrors()
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
            if let submitError = viewModel.submitError ?? appleSignIn.submitError {
                ErrorBanner(message: submitError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthFormField(
                labelKey: "signUp.usernameField.label",
                placeholderKey: "signUp.usernameField.placeholder",
                text: $viewModel.username,
                errorMessageKey: viewModel.usernameError,
                textContentType: .username
            )
            .focused($focusedField, equals: .username)

            AuthFormField(
                labelKey: "signUp.emailField.label",
                placeholderKey: "signUp.emailField.placeholder",
                text: $viewModel.email,
                errorMessageKey: viewModel.emailError,
                textContentType: .emailAddress,
                keyboardType: .emailAddress
            )
            .focused($focusedField, equals: .email)

            AuthFormField(
                labelKey: "signUp.passwordField.label",
                placeholderKey: "signUp.passwordField.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .go
            )
            .focused($focusedField, equals: .password)

            Toggle(isOn: $viewModel.acceptsTerms) {
                Text("signUp.terms.label")
                    .font(.subheadline)
                    .tracking(0.25)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .toggleStyle(CheckboxToggleStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onSubmit {
            switch focusedField {
            case .username: focusedField = .email
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
            .disabled(isBusy)

            AuthSwitchLink(
                promptKey: "auth.switch.haveAccount.prompt",
                actionKey: "auth.switch.haveAccount.action"
            ) {
                coordinator.pop()
                coordinator.push(.login)
            }
        }
    }

    private var submitButton: some View {
        Button("signUp.submitButton.title") {
            Task { await submit() }
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(isBusy)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func submit() async {
        // The session flips to authenticated inside `submit`, so the gate must already hold the auth stack.
        onboarding.begin()
        if await viewModel.submit(using: authSession) {
            onboarding.username = viewModel.createdUsername
            coordinator.startOnboarding()
            return
        }
        onboarding.finish()
        if viewModel.shouldNavigateToLogin {
            coordinator.pop()
            coordinator.push(.login)
        }
    }

    private func signInWithApple() async {
        onboarding.begin()
        guard await appleSignIn.signInWithApple(
            using: authSession,
            requestCredential: { try await authorizationController.appleIDCredential(for: $0) }
        ) else {
            onboarding.finish()
            return
        }
        if await onboarding.resolveAfterSignIn() {
            coordinator.startOnboarding()
        } else {
            coordinator.finishAuthFlow()
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        SignUpView()
            .environment(AppCoordinator())
            .environment(AuthSession())
            .environment(OnboardingGate())
            .environment(ToastPresenter())
    }
}
