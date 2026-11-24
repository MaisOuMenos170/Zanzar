import SwiftUI

private struct SheetCloseButtonModifier: ViewModifier {
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
    func sheetCloseButton(
        hugsContent: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        modifier(SheetCloseButtonModifier(hugsContent: hugsContent, isDisabled: isDisabled, action: action))
    }
}
