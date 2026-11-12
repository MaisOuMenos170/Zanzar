import SwiftUI

/// Presents "Sugerir um lugar" like the Figma sheet: full width, flush with the bottom edge, 38pt top corners,
/// a grabber, and the screen dimmed behind it (black at 30%). The system draws partial sheets inset from the sides
/// on iOS 26, which the design does not have, so the card is laid over the screen instead of using `.sheet`.
struct PlaceSuggestionSheetCard<Content: View>: View {
    let onClose: () -> Void
    @ViewBuilder let content: Content

    @State private var dragOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static var closeDistance: CGFloat { 120 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
                .accessibilityHidden(true)
                .transition(.opacity)

            card
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            // Figma "Grabber": 36×5, 6pt from the top edge.
            Capsule()
                .fill(Color.brandSheetGrabber)
                .frame(width: 36, height: 5)
                .padding(.top, 6)
                .padding(.bottom, 15)
                .accessibilityHidden(true)

            content
        }
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 38, topTrailingRadius: 38)
                .fill(Color.brandNeutral50)
                .shadow(color: .black.opacity(0.18), radius: 18.75, y: 15)
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .offset(y: max(dragOffset, 0))
        .gesture(dragToClose)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
        .transition(.move(edge: .bottom))
    }

    private var dragToClose: some Gesture {
        DragGesture()
            .onChanged { dragOffset = $0.translation.height }
            .onEnded { value in
                if value.translation.height > Self.closeDistance || value.predictedEndTranslation.height > 300 {
                    onClose()
                } else if reduceMotion {
                    dragOffset = 0
                } else {
                    withAnimation(.smooth(duration: 0.25)) { dragOffset = 0 }
                }
            }
    }
}

#Preview {
    PlaceSuggestionSheetCard(onClose: {}, content: {
        Text("Conteúdo").frame(height: 300)
    })
}
