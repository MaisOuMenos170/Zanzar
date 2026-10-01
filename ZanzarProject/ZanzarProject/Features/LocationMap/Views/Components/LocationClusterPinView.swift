import SwiftUI

/// Compact cluster badge shown when several places overlap at the current zoom level.
struct LocationClusterPinView: View {
    let count: Int

    private var diameter: CGFloat {
        switch count {
        case ..<10:
            34
        case ..<100:
            38
        default:
            42
        }
    }

    private var countLabel: String {
        count > 99 ? "99+" : count.formatted()
    }

    var body: some View {
        Text(countLabel)
            .font(.caption.bold())
            .monospacedDigit()
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(Color("LocationPinPrimary"), in: .circle)
            .overlay {
                Circle()
                    .strokeBorder(.white, lineWidth: 2.5)
            }
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        LocationClusterPinView(count: 3)
        LocationClusterPinView(count: 16)
        LocationClusterPinView(count: 24)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
