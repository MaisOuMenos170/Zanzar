import SwiftUI

/// The map loaded fine and has no pins to show (Figma "D4 · Nada por perto"): says so, and offers to take the
/// filter off when that is what is hiding the places.
struct MapEmptyCard: View {
    let filterIsOn: Bool
    let onClearFilter: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            MascotView(.sleepy)
            VStack(spacing: 4) {
                Text("locationMap.empty.title")
                    .typography(.subtitle1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.brandNeutral950)
                    .accessibilityAddTraits(.isHeader)
                Text(filterIsOn ? "locationMap.empty.messageFiltered" : "locationMap.empty.message")
                    .typography(.body2)
                    .foregroundStyle(Color.brandNeutral600)
            }
            .multilineTextAlignment(.center)

            if filterIsOn {
                Button("locationMap.empty.clearFilterButton", action: onClearFilter)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandPurple500)
                    .frame(minHeight: 44)
            }
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    MapEmptyCard(filterIsOn: true) {}
        .padding()
}
