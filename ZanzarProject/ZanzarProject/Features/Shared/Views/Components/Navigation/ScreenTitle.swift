import SwiftUI

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
