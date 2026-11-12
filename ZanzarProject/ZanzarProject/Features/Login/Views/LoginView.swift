import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(\.authorizationController) private var authorizationController
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    var body: some View {
        AuthScreenScaffold(titleKey: "login.header.title") {
            form
        } actions: {
            actions
        }
        .toast(for: viewModel.submitError)
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
                labelKey: "login.emailField.label",
                placeholderKey: "login.emailField.placeholder",
                text: $viewModel.email,
                errorMessageKey: viewModel.emailError,
                textContentType: .emailAddress,
                keyboardType: .emailAddress,
                isFocused: $isEmailFocused
            )

            AuthFormField(
                labelKey: "login.passwordField.label",
                placeholderKey: "login.passwordField.placeholder",
                text: $viewModel.password,
                errorMessageKey: viewModel.passwordError,
                isSecure: true,
                textContentType: .password,
                submitLabel: .go,
                isFocused: $isPasswordFocused
            )

            Button("login.forgotPassword.button.title") {
                coordinator.push(.forgotPassword)
            }
            .typography(.subtitle2)
            .foregroundStyle(.primary)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .trailing)
            .contentShape(.rect)
        }
        .onSubmit {
            if isEmailFocused {
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
        .disabled(viewModel.isLoading || !viewModel.canSubmit)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func dismissKeyboard() {
        isEmailFocused = false
        isPasswordFocused = false
    }

    private func submit() async {
        // The button path leaves the keyboard up, covering the result and the error banner.
        dismissKeyboard()
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
        dismissKeyboard()
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
            .environment(ToastManager())
    }
}
