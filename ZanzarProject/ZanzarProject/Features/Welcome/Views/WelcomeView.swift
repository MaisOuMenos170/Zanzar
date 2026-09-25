import SwiftUI

struct WelcomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            WelcomeIllustration()

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("welcome.header.title")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("welcome.header.subtitle")
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 19)

            Spacer()
                .frame(height: 32)

            WelcomeActionButtons(
                onCreateAccount: { coordinator.push(.signUp) },
                onLogin: { coordinator.push(.login) }
            )
            .padding(.horizontal, 19)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
