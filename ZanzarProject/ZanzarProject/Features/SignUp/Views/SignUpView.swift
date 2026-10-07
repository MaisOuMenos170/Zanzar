import SwiftUI

struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(ToastPresenter.self) private var toasts

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                AuthFormField(
                    labelKey: "signUp.usernameField.label",
                    placeholderKey: "signUp.usernameField.placeholder",
                    text: $viewModel.username,
                    errorMessageKey: viewModel.usernameError,
                    textContentType: .username
                )

                AuthFormField(
                    labelKey: "signUp.emailField.label",
                    placeholderKey: "signUp.emailField.placeholder",
                    text: $viewModel.email,
                    errorMessageKey: viewModel.emailError,
                    textContentType: .emailAddress,
                    keyboardType: .emailAddress
                )

                AuthFormField(
                    labelKey: "signUp.passwordField.label",
                    placeholderKey: "signUp.passwordField.placeholder",
                    text: $viewModel.password,
                    errorMessageKey: viewModel.passwordError,
                    isSecure: true,
                    textContentType: .newPassword
                )
            }
            .padding(.horizontal, 19)
            .padding(.top, 16)

            Spacer()

            Button("signUp.submitButton.title") {
                Task {
                    if await viewModel.submit(using: authSession) {
                        coordinator.finishAuthFlow()
                    } else if viewModel.shouldNavigateToLogin {
                        coordinator.pop()
                        coordinator.push(.login)
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
            .padding(.horizontal, 19)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .navigationTitle("signUp.header.title")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: viewModel.submitError) { _, error in
            if let error {
                toasts.show(error)
            } else {
                toasts.dismiss()
            }
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        SignUpView()
            .environment(AppCoordinator())
            .environment(AuthSession())
            .environment(ToastPresenter())
    }
}
