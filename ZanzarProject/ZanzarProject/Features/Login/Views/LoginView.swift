import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
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
                Text("login.header.title")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)

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
            }
            .padding(.horizontal, 19)
            .padding(.top, 32)

            Spacer()

            Button("login.submitButton.title") {
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
        LoginView()
            .environment(AppCoordinator())
    }
}

