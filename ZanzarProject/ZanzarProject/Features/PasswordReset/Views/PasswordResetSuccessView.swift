import SwiftUI

/// Last step of the reset: the new password is saved and the next stop is the login screen.
/// Laid out like `AuthScreenScaffold`: everything sits at the bottom of the screen.
struct PasswordResetSuccessView: View {
    @Environment(AppCoordinator.self) private var coordinator

    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer(minLength: 0)

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
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(minHeight: viewportHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newHeight in
            viewportHeight = newHeight
        }
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
