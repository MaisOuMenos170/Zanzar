import AuthenticationServices
import SwiftUI

struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    @State private var appleSignIn = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(\.authorizationController) private var authorizationController
    @FocusState private var isUsernameFocused: Bool
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    private var isBusy: Bool {
        viewModel.isLoading || appleSignIn.isLoading
    }

    var body: some View {
        AuthScreenScaffold(titleKey: "signUp.header.title") {
            form
        } actions: {
            actions
        }
        .toast(for: viewModel.submitError)
        .toast(for: appleSignIn.submitError)
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
            AuthFormField(
                labelKey: "signUp.usernameField.label",
                placeholderKey: "signUp.usernameField.placeholder",
                text: $viewModel.username,
                errorMessageKey: viewModel.usernameError,
                textContentType: .username,
                isFocused: $isUsernameFocused
            )

            AuthFormField(
                labelKey: "signUp.emailField.label",
                placeholderKey: "signUp.emailField.placeholder",
                text: $viewModel.email,
                errorMessageKey: viewModel.emailError,
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                isFocused: $isEmailFocused
            )

            AuthFormField(
                labelKey: "signUp.passwordField.label",
                placeholderKey: "signUp.passwordField.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .go,
                isFocused: $isPasswordFocused
            )

            Toggle(isOn: $viewModel.acceptsTerms) {
                Text("signUp.terms.label")
                    .typography(.body2)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .toggleStyle(CheckboxToggleStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .motion(
            Motion.suave,
            value: [viewModel.usernameError, viewModel.emailError, viewModel.passwordError]
        )
        .onSubmit {
            if isUsernameFocused {
                isEmailFocused = true
            } else if isEmailFocused {
                isPasswordFocused = true
            } else {
                isPasswordFocused = false
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
        Button {
            Task { await submit() }
        } label: {
            Text("signUp.submitButton.title")
                .opacity(viewModel.isLoading ? 0 : 1)
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(isBusy || !viewModel.canSubmit)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .transition(.opacity)
            }
        }
        .motion(Motion.suave, value: viewModel.isLoading)
    }

    private func dismissKeyboard() {
        isUsernameFocused = false
        isEmailFocused = false
        isPasswordFocused = false
    }

    private func submit() async {
        // The button path leaves the keyboard up, covering the result and the error banner.
        dismissKeyboard()
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
        dismissKeyboard()
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
            .environment(ToastManager())
    }
}
