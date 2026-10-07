import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AuthSession.self) private var authSession
    @Environment(ToastPresenter.self) private var toasts

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
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
            .padding(.horizontal, 19)
            .padding(.top, 16)

            Spacer()

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
            .padding(.horizontal, 19)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .navigationTitle("login.header.title")
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
        LoginView()
            .environment(AppCoordinator())
            .environment(AuthSession())
            .environment(ToastPresenter())
    }
}
