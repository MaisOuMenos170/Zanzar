import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
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

                if dynamicTypeSize.isAccessibilitySize {
                    actionButtons
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                actionButtons
                    .padding(.horizontal, 19)
                    .padding(.vertical, 16)
                    .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle("login.header.title")
        .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: viewModel.email) {
            viewModel.refreshShownFieldErrors()
        }
        .onChange(of: viewModel.password) {
            viewModel.refreshShownFieldErrors()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            submitButton
            appleSignInButton
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            viewModel.configureAppleRequest(request)
        } onCompletion: { result in
            Task {
                if await viewModel.completeAppleSignIn(result, using: authSession) {
                    coordinator.finishAuthFlow()
                }
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(.capsule)
        .disabled(viewModel.isLoading)
    }

    private var submitButton: some View {
        Button("login.submitButton.title") {
            Task {
                if await viewModel.submit(using: authSession) {
                    coordinator.finishAuthFlow()
                }
            }
        }
        .buttonStyle(AuthPrimaryButtonStyle())
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        LoginView()
            .environment(AppCoordinator())
            .environment(AuthSession())
            .environment(ToastPresenter())
    }
}
