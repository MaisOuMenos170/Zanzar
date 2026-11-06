import SwiftUI

/// Layout of the login and sign-up screens. The actions sit at the bottom of the scroll content, so the keyboard
/// covers them instead of pushing them over the fields.
struct AuthScreenScaffold<Content: View, Actions: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions

    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 0)

                Text(titleKey)
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                content

                actions
                    .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(minHeight: viewportHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { newHeight in
            viewportHeight = newHeight
        }
        .background(Color.brandBlue50.ignoresSafeArea())
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }
}
