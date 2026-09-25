import SwiftUI

struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                AuthBackButton { coordinator.pop() }
                Spacer()
            }
            .padding(.horizontal, 19)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 24) {
                Text("signUp.header.title")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)

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
            }
            .padding(.horizontal, 19)
            .padding(.top, 32)

            Spacer()

            Button("signUp.submitButton.title") {
                if viewModel.submitTapped() {
                    coordinator.completeAuth()
                }
            }
            .buttonStyle(AuthPrimaryButtonStyle())
            .padding(.horizontal, 19)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
        .navigationBarBackButtonHidden()
    }
}

#Preview("Empty") {
    NavigationStack {
        SignUpView()
            .environment(AppCoordinator())
    }
}

