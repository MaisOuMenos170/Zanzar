import SwiftUI

struct WelcomeView: View {
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            WelcomeLayout(illustrationHeight: 280, reservesFlexibleSpace: true)
                .frame(minHeight: viewportHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newHeight in
            viewportHeight = newHeight
        }
        .background(Color(.systemBackground))
    }
}

private struct WelcomeLayout: View {
    @Environment(AppCoordinator.self) private var coordinator

    var illustrationHeight: CGFloat
    var reservesFlexibleSpace: Bool

    var body: some View {
        VStack(spacing: 0) {
            if reservesFlexibleSpace {
                Spacer(minLength: 16)
            }

            WelcomeIllustration(height: illustrationHeight)

            if reservesFlexibleSpace {
                Spacer(minLength: 16)
            } else {
                Spacer().frame(height: 24)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("welcome.header.title")
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("welcome.header.subtitle")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(minHeight: 32)

            WelcomeActionButtons(
                onCreateAccount: { coordinator.push(.signUp) },
                onLogin: { coordinator.push(.login) }
            )
        }
        .padding(.horizontal, 19)
        .padding(.bottom, 24)
    }
}

#Preview {
    WelcomeView()
        .environment(AppCoordinator())
}
