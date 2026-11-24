import SwiftUI

struct SelectionBadge: View {
    @ScaledMetric(relativeTo: .caption) private var size: CGFloat = 24

    var body: some View {
        Image(systemName: "checkmark")
            .font(.caption2.weight(.heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.selectionGreen, in: .circle)
            .overlay {
                Circle().strokeBorder(.white, lineWidth: 1.7)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    SelectionBadge()
        .padding()
}
