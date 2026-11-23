import SwiftUI

/// The title of a screen in the navigation bar: Subtitle 1 in Neutral/950 (Figma "checkin v2", node 1814:3204), the
/// same on every screen. It is also the title the system uses for the back button and accessibility.
private struct ScreenTitleModifier: ViewModifier {
    let title: Text

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    title
                        .typography(.subtitle1)
                        .foregroundStyle(Color.brandNeutral950)
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
            }
    }
}

extension View {
    func screenTitle(_ title: LocalizedStringKey) -> some View {
        modifier(ScreenTitleModifier(title: Text(title)))
    }

    func screenTitle(_ title: Text) -> some View {
        modifier(ScreenTitleModifier(title: title))
    }
}
