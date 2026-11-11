import SwiftUI

/// Last step of the reset: the new password is saved and the next stop is the login screen.
struct PasswordResetSuccessView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "checkmark")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 98, height: 98)
                    .background(Color.brandBlue500, in: .circle)
                    .accessibilityHidden(true)

                Text("passwordReset.success.title")
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.rounded)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 8)

                Text("passwordReset.success.message")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("passwordReset.success.button.title") {
                    coordinator.returnToLogin()
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 48)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.brandBlue50.ignoresSafeArea())
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        // Going back would land on the new-password form with a reset token that was already used.
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    NavigationStack {
        PasswordResetSuccessView()
            .environment(AppCoordinator())
    }
}
