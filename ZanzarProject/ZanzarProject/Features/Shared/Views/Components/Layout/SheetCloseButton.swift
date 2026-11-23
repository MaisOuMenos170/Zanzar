import SwiftUI

/// The system's close button (the round glass "x") in the top corner of a sheet, in place of one drawn by hand.
///
/// The button needs a navigation bar to live in, so this wraps the content in a navigation stack and lets the content
/// run under the bar, as in the Figma sheets: the bar only floats the button over the corner.
private struct SheetCloseButtonModifier: ViewModifier {
    /// Whether the sheet is only as tall as its content (a card) or fills what it is given (a full sheet). A
    /// navigation stack takes all the height it is offered, so a card has to be measured and held to its content.
    let hugsContent: Bool
    let isDisabled: Bool
    let action: () -> Void

    @State private var contentHeight: CGFloat?

    func body(content: Content) -> some View {
        NavigationStack {
            content
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
                .ignoresSafeArea(.container, edges: .top)
                // The card behind has its own rounded top; the stack's own background would square it off.
                .containerBackground(.clear, for: .navigation)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close, action: action)
                            .disabled(isDisabled)
                    }
                }
        }
        .frame(maxHeight: hugsContent ? (contentHeight ?? .infinity) : .infinity)
        // Until the height is measured the stack would take all the screen for a frame and then shrink.
        .opacity(hugsContent && contentHeight == nil ? 0 : 1)
    }
}

extension View {
    /// Adds the system close button to a sheet. `hugsContent` is for a card that is only as tall as what is in it.
    func sheetCloseButton(
        hugsContent: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SheetCloseButtonModifier(hugsContent: hugsContent, isDisabled: isDisabled, action: action))
    }
}
