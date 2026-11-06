import SwiftUI

/// Shared layout for the login and sign-up screens: blue background, rounded title and form anchored above
/// the actions pinned to the bottom. At accessibility Dynamic Type sizes the actions move into the scroll content.
struct AuthScreenScaffold<Content: View, Actions: View>: View {
    let titleKey: LocalizedStringKey
    @ViewBuilder let content: Content
    @ViewBuilder let actions: Actions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(titleKey)
                    .font(.largeTitle.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)

                content

                if dynamicTypeSize.isAccessibilitySize {
                    actions
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .defaultScrollAnchor(.bottom, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                actions
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
        }
        .background(Color.brandBlue50.ignoresSafeArea())
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
    }
}
