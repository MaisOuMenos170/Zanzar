import SwiftUI

/// A row that becomes a column at accessibility text sizes.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var horizontalAlignment: HorizontalAlignment
    var verticalAlignment: VerticalAlignment
    var spacing: CGFloat?
    private let content: Content

    init(
        horizontalAlignment: HorizontalAlignment = .leading,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        layout {
            content
        }
    }

    private var layout: AnyLayout {
        if dynamicTypeSize.isAccessibilitySize {
            AnyLayout(VStackLayout(alignment: horizontalAlignment, spacing: spacing))
        } else {
            AnyLayout(HStackLayout(alignment: verticalAlignment, spacing: spacing))
        }
    }
}

#Preview("Default") {
    AdaptiveStack(spacing: 8) {
        Text("Label")
        Text("Value").bold()
    }
    .padding()
}

#Preview("Accessibility 3") {
    AdaptiveStack(spacing: 8) {
        Text("Label")
        Text("Value").bold()
    }
    .padding()
    .dynamicTypeSize(.accessibility3)
}
