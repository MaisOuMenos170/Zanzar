import SwiftUI

/// Green check with a white ring, laid over the corner of the chosen option.
struct SelectionBadge: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 10, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
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
