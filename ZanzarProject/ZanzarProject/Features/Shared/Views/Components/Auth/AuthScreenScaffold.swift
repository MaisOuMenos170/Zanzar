import SwiftUI

/// Shared layout for the login and sign-up screens: blue background, rounded title and form, then the actions.
/// Everything lives in one scroll view that is at least as tall as the screen, so the actions rest at the bottom.
/// When the keyboard opens they stay where they are, below the form and under the keyboard, instead of riding up over
/// the fields; the keyboard's return key moves through the fields and submits on the last one.
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
