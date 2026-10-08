import SwiftUI

struct ItineraryCompletedAlertView: View {
    let onAccept: () -> Void

    @AccessibilityFocusState private var isAcceptFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(.rect)
                .accessibilityHidden(true)

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("placeDetail.itineraryCompletedAlert.title")
                        .font(.headline)

                    Text("placeDetail.itineraryCompletedAlert.message")
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ItineraryStampView(state: .earned, size: 120)

                Button("placeDetail.sealEarnedAlert.acceptButton.title", action: onAccept)
                    .buttonStyle(.glassProminent)
                    .tint(Color("RatingPromptPrimary"))
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity)
                    .accessibilityFocused($isAcceptFocused)
            }
            .padding(14)
            .frame(width: 300)
            .glassEffect(.regular, in: .rect(cornerRadius: 34))
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            isAcceptFocused = true
        }
    }
}

#Preview {
    ItineraryCompletedAlertView(onAccept: {})
}
