import SwiftUI

/// The glass card of the custom alerts. It scrolls when its content is taller than the screen.
struct AlertOverlayCard<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(14)
        .frame(maxWidth: maxWidth)
        .glassEffect(.regular, in: .rect(cornerRadius: 34))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var maxWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 420 : 300
    }
}

#Preview("Default") {
    AlertOverlayCard {
        VStack(spacing: 24) {
            Text("Title").font(.headline)
            Text("A message that explains what happened and what the user can do next.")
            Button("Accept") {}
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Accessibility 5") {
    AlertOverlayCard {
        VStack(spacing: 24) {
            Text("Title").font(.headline)
            Text("A message that explains what happened and what the user can do next.")
            Button("Accept") {}
                .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity)
    }
    .dynamicTypeSize(.accessibility5)
}
